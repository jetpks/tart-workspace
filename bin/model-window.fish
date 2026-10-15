#!/opt/homebrew/bin/fish
# model-window.fish — route the loop's models off z.ai direct during its peak
# pricing window. Owner directive 2026-10-14: z.ai doubles token cost Mon–Fri
# 14:00–18:00 Asia/Shanghai; during that window the loop's roles run via
# openrouter (openrouter/z-ai/glm-5.3 + glm-5.3-flash), outside it they run
# zai direct. The window is derived from the Asia/Shanghai clock — under MDT
# it equals Mon–Fri 00:00–04:00 America/Denver; deriving from the schedule
# (not the local clock) keeps it exact across DST drift.
#
# What it rewrites: the model ids in architect.yaml + .pi/agents/architect-*.md.
# The yaml drives fresh sessions (extension resolveConfig at session_start) and
# the architect CLI (Routing.for_space per command); the agent files drive the
# RUNNING coordinator's spawns, whose process never re-resolves the yaml.
# Transitions commit to the space (architect.yaml + .pi/agents only — never
# architecture/). In-flight sessions keep their spawn-time provider; that's
# accepted tail cost, not a bug.
#
# Modes:
#   fish bin/model-window.fish                    apply the window (launchd tick)
#   fish bin/model-window.fish --check            print desired vs current, no writes
#   fish bin/model-window.fish --force zai|openrouter   manual override (testing)
#
# Installed: ~/Library/LaunchAgents/com.jetpks.pi-port.model-window.plist
# (RunAtLoad + 5-minute tick; the script is idempotent, so a tick missed to
# sleep self-heals on the next). Log: tmp/model-window.log.

set -l root (realpath (dirname (status filename))/..)

argparse check force= -- $argv; or exit 2

# --- desired provider, from the z.ai peak schedule (Asia/Shanghai clock) ---
set -l sh_dow (TZ=Asia/Shanghai date +%u)
set -l sh_hour (TZ=Asia/Shanghai date +%H)
set -l desired zai
if test "$sh_dow" -ge 1; and test "$sh_dow" -le 5; and test "$sh_hour" -ge 14; and test "$sh_hour" -le 17
    set desired openrouter
end
if set -q _flag_force
    switch $_flag_force
        case zai openrouter
            set desired $_flag_force
        case '*'
            echo "force: expected zai|openrouter, got '$_flag_force'" >&2
            exit 2
    end
end

# --- id pair + rewrites. The z-ai hyphen makes both directions unambiguous,
# and the -flash suffix rides outside the match, so one pattern per direction
# covers both models. A file holding mixed ids (crashed flip) heals to one.
set -l probe_old 'zai/glm-5\.3'
set -l probe_new 'openrouter/z-ai/glm-5\.3'
set -l fwd 's#zai/glm-5\.3#openrouter/z-ai/glm-5.3#g'
set -l bwd 's#openrouter/z-ai/glm-5\.3#zai/glm-5.3#g'

set -l targets $root/architect.yaml $root/.pi/agents/architect-*.md

if set -q _flag_check
    echo "now (Asia/Shanghai): dow=$sh_dow hour=$sh_hour -> desired=$desired"
    for f in $targets
        test -f "$f"; or continue
        set -l cur neither
        grep -Eq "$probe_new" "$f"; and set cur openrouter
        grep -Eq "$probe_old" "$f"; and set cur zai
        echo "  "(string replace "$root/" "" -- $f)": $cur"
    end
    exit 0
end

set -l touched 0
for f in $targets
    test -f "$f"; or continue
    switch $desired
        case openrouter
            if grep -Eq "$probe_old" "$f"
                sed -E -i '' "$fwd" "$f"
                set touched (math $touched + 1)
            end
        case zai
            if grep -Eq "$probe_new" "$f"
                sed -E -i '' "$bwd" "$f"
                set touched (math $touched + 1)
            end
    end
end

mkdir -p $root/tmp
if test $touched -gt 0
    set -l stamp (date -u +"%Y-%m-%dT%H:%M:%SZ")
    echo "$stamp transition -> $desired ($touched files rewritten)" >>$root/tmp/model-window.log
end

# Commit any pending transition (also retries a commit that lost an index-lock
# race — the tick is the retry loop). Paths are pinned so nothing else rides.
cd $root
if not git diff --quiet -- architect.yaml .pi/agents; or not git diff --cached --quiet -- architect.yaml .pi/agents
    git add architect.yaml .pi/agents
    and git commit -q -m "model-window: route loop models via $desired (z.ai peak schedule; owner 2026-10-14)"
    and echo (date -u +"%Y-%m-%dT%H:%M:%SZ")" committed -> $desired" >>$root/tmp/model-window.log
    or echo (date -u +"%Y-%m-%dT%H:%M:%SZ")" COMMIT FAILED (index lock?) — next tick retries" >>$root/tmp/model-window.log
end
