## Scoreboard notifications

Scoreboard used to be called Pressbox. `programs.birdland.pressbox.*` still
works, with a warning to rename it to `programs.birdland.scoreboard.*`.

Scoreboard is the session's notification server, so it replaces mako, dunst or
swaync; run only one of them. Popups appear in a corner of the focused monitor,
newest first, below the bar. Click one for the app's default action (or to close
it), use its buttons for the others, or the cross to dismiss it. A popup stays
while the pointer is over it, and critical ones (a low battery) stay until
dismissed. There is no history: notifications are gone once closed.

Do not disturb drops all but critical notifications:

```sh
birdland-scoreboard ipc call scoreboard toggleDnd    # prints the new state
birdland-scoreboard ipc call scoreboard setDnd true
birdland-scoreboard ipc call scoreboard dismissAll
```
