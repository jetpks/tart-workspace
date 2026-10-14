# trial running

- resized the window smaller, and the "ctrl+c interrupt/quit ..." help text didn't wrap at the new border, it just cuts off. the ascii art cuts off too, but it would look terrible wrapped. if we resize smaller than the displayed art, we should choose a smaller art unless it's smaller than our smallest art, in which case we just put the word tart and call it good
- with text in the input field, after resizing, it doesn't resize until you move the cursor, which can be a little jarring. should happen when we get the sigwinch
- major scroll lag, especially while printing.
- `/thinking` doesn't work while answer is streaming, but should -- OH NO it queued as a user message and sent to the model
- queued messages in pi are shown above the editor box with a little help text that tells you how to edit queued messages -- tart seems to be missing that.
- we're missing the background on edit tool calls
- queued message didn't fire until the assistant round ended completely -- i'm pretty sure we can slip those in around tool calls, at least, pi appears to do that. we might need to check traces.
- pasted content handling -- we need to do that thing where we inject a placeholder into the user message. also, i really like how claude-code does it where if you paste again immediately, it expands to the full text instead of the placeholder. perfect ux.
