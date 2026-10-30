# frozen_string_literal: true

# I87 forensics: reduced-context reproduction of class (a) — the escape
# interrupt's undelivered cancellation. Same wiring as
# test/chat_test.rb#chat_with_server + the escape test scenario, run in a
# tight loop under external CPU steal. Reports per-iteration outcome and
# the Async cancel-branch tally.
#
# Usage: ruby repro_a.rb <iterations>
require "minitest/autorun"
require "json"
require_relative "../wt/test/test_helper"
require_relative "../wt/test/support/mock_llm_server"

ITERATIONS = (ARGV[0] || 50).to_i

module I87Probe
  LOCK = Mutex.new
  TALLY = Hash.new(0)
  FIRINGS = []
  RING = []
  ITER = [0]

  module Wait
    def wait_until(&blk)
      super
    rescue RuntimeError => e
      raise unless e.message == "work condition never satisfied"
      I87Probe::LOCK.synchronize do
        FIRINGS << {iter: ITER[0]}
        File.write("/tmp/i87-cycles/repro-firing.json", JSON.pretty_generate(iter: ITER[0], ring: RING))
      end
      raise
    end
  end

  module Cancel
    def cancel(later = false, cause: $!)
      fiber = instance_variable_get(:@fiber)
      pre = {fiber_alive: fiber&.alive?, cancelled: self.cancelled?, current: self.current?, task_oid: object_id}
      super
    rescue FiberError => e
      I87Probe::LOCK.synchronize do
        TALLY["FiberError->Later"] += 1
        RING << {iter: ITER[0], branch: "FiberError", **pre}
      end
      raise
    else
      post = instance_variable_get(:@fiber)
      I87Probe::LOCK.synchronize do
        TALLY["returned(fiber_alive=#{pre[:fiber_alive].inspect})"] += 1
        RING << {iter: ITER[0], branch: "returned", fiber_after: post&.alive?, cancelled_after: self.cancelled?, **pre}
      end
    end
  end

  module Kernel
    def interrupt_work!
      tasks = instance_variable_get(:@tasks)
      I87Probe::LOCK.synchronize { RING << {iter: ITER[0], kind: :interrupt_work, tasks_alive: tasks.map(&:alive?)} }
      super
    end
  end

  # The delivery seam: io-event's Selector#raise calls Fiber#raise directly;
  # async rescues FiberError internally and defers via a Cancel::Later push.
  module Selector
    def raise(fiber, *arguments, **options)
      super
    rescue FiberError => e
      I87Probe::LOCK.synchronize do
        RING << {iter: ITER[0], kind: :selector_raise_fibererror, err: e.message,
                 target_alive: (fiber.respond_to?(:alive?) ? fiber.alive? : nil), target: fiber.class.name}
      end
      raise
    else
      I87Probe::LOCK.synchronize { RING << {iter: ITER[0], kind: :selector_raise_ok, target: fiber.class.name} }
    end

    def push(fiber)
      I87Probe::LOCK.synchronize do
        RING << {iter: ITER[0], kind: :selector_push, target: fiber.class.name}
      end
      super
    end
  end

  # Delivery discriminator: WHO finalizes the task — the agent fiber's own
  # ensure (delivery) or the interrupter's fiber (direct cancel! path).
  module Finalize
    def finish!
      I87Probe::LOCK.synchronize do
        RING << {iter: ITER[0], kind: :finish!, task_oid: object_id,
                 on_fiber: Fiber.current.object_id, fiber_alive: instance_variable_get(:@fiber)&.alive?}
      end
      super
    end

    def cancel!(cause = nil)
      I87Probe::LOCK.synchronize do
        RING << {iter: ITER[0], kind: :cancel!, task_oid: object_id,
                 on_fiber: Fiber.current.object_id}
      end
      super
    end
  end
  # The delivery seam one level up: Async::Scheduler#raise -> @selector.raise.
  module SchedulerProbe
    def raise(fiber, *arguments, **options)
      I87Probe::LOCK.synchronize { RING << {iter: ITER[0], kind: :scheduler_raise, target: fiber.class.name} }
      super
    end

    def push(fiber)
      I87Probe::LOCK.synchronize { RING << {iter: ITER[0], kind: :scheduler_push, target: fiber.class.name} }
      super
    end
  end
end

Tart::Test.prepend(I87Probe::Wait)
Async::Task.prepend(I87Probe::Cancel)
Tart::Core::Loop.prepend(I87Probe::Kernel)
Async::Scheduler.prepend(I87Probe::SchedulerProbe)
Async::Task.prepend(I87Probe::Finalize)
# The concrete selector backend is a C-ext subclass (KQueue on darwin).
sel_class = ObjectSpace.each_object(Class).find { |k| k.name.to_s.start_with?("IO::Event::Selector::") && k != IO::Event::Selector } || IO::Event::Selector
I87Probe::LOCK.synchronize { I87Probe::RING << {iter: -1, kind: :wrapped_selector, klass: sel_class.name} }
sel_class.prepend(I87Probe::Selector)

# Exactly the escape-test body (chat_with_server + scenario), one shot.
class ReproA < Tart::Test
  def run_scenario_once(i)
    @captured_acc = []
    server = MockLLMServer.new.start
    server.script([{type: :slow_stream, content: "x" * 40}])
    session = Tart::Test::ScriptedSession.new(width: 80, height: 24)
    kernel = Tart::Core::Loop.new(session:)
    chat = Tart::Render::Chat.new(session:, kernel:, branch_reader: nil, autocomplete: nil, motd: false, identity: Tart::Identity::DEFAULT)
    chat.agent = Tart::Agent::Loop.new(
      chat: Tart::Test::TestChat.build(server, tools: [], system_prompt: "test"),
      tools: [], on_event: ->(event) { chat.on_agent_event(event) }
    )
    kernel.renderer = chat.renderer
    kernel.on_event = ->(event, source) { chat.on_event(event, source) }

    scenario = Thread.new do
      begin
        text = "long stream"
        text.chars.each { |char| session.push_event(Tart::TUI.key_event(char)) }
        session.push_event(Tart::TUI.key_event("enter"))
        wait_until { chat.busy? }
        session.push_event(Tart::TUI.key_event("esc"))
        wait_until { !chat.busy? }
        wait_until { chat.transcript_lines.join.include?("interrupted") }
      ensure
        kernel.stop!
      end
    end
    kernel.run
    scenario.join

    raise "iteration #{i}: interrupt not seen" unless chat.agent.interrupted?
  ensure
    server&.stop
  end

  def test_repro_loop
    @i = 0
    begin
      ITERATIONS.times do |i|
        @i = i
        I87Probe::LOCK.synchronize { I87Probe::ITER[0] = i }
        run_scenario_once(i)
        print "."
        $stdout.flush
      end
      puts
    rescue Minitest::Assertion, RuntimeError => e
      puts "\nFIRING at iteration #{@i}: #{e.class}: #{e.message}"
      puts "CANCEL TALLY: #{I87Probe::TALLY.map { |k, v| "#{k}=#{v}" }.join(" ")}"
      raise
    ensure
      puts "CANCEL TALLY: #{I87Probe::TALLY.map { |k, v| "#{k}=#{v}" }.join(" ")} firings=#{I87Probe::FIRINGS.size}"
    end
  end
end
