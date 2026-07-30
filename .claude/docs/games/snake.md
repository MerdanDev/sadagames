# Snake

`lib/games/snake/` — the arcade classic. The snake never stops; the player only chooses corners.

**The loop.** Swipe to steer. Eat the apple, grow a segment, and the next step comes sooner. The
run ends on a wall or on yourself. Walls kill rather than wrap, which is why the board is drawn
with a solid frame instead of a faint one.

**The snake waits for the first swipe.** Not a start screen — the board is live and the swipe
that starts the snake is the same swipe that steers it, so the first interaction still teaches
the rule. Without it a player who opens the game and looks at the board for three seconds comes
back to a run that ended on 0 apples without them, which is exactly the first impression the
engagement bar exists to prevent. `restart` puts it back to waiting for the same reason.

The board is **15 × 23, not square**: a square board on a phone leaves half the screen doing
nothing, and Snake wants room more than any other game here.

## The rules that are easy to get wrong

- **A turn is judged against the turn before it, not the direction the snake is travelling.**
  Two flicks inside one tick (right → up → down) would otherwise both be legal and fold the
  snake into its own neck. Turns queue, up to two.
- **Moving into the cell the tail is leaving is legal.** The tail vacates on the same tick the
  head arrives, so chasing your own tail is fine — unless that step is also the one that eats,
  because then the tail stays put and the cell is still occupied.
- A fruit never spawns under the snake.

All three have tests. The first two are what separate a snake that feels fair from one that
feels like it cheats.

## Record

**Apples eaten**, not length — the same reasoning as Merge Tiles. Length is the number the
comeback has to be allowed to take away, so it cannot also be the number the player is chasing.
Length is shown in the HUD during a run instead.

## Comeback

A gold **trim fruit**, worth one apple like any other, that hands back four segments. It only
spawns once the snake is at `trimUnlockLength` (12) and then only one time in five, so it turns
up when the board has got tight and never as a gift there was nothing to fix. It never trims
below `startingLength`.

It is a diamond, not a gold circle: colour alone must not be the difference.

## Difficulty

`tickInterval` starts at 0.24s and loses 0.006s per apple down to a floor of 0.085s — roughly
three times the starting speed at 25 apples. Length climbing at the same time is the other half
of the curve, and the trim fruit is what stops the two compounding into a dead end.

## Worth knowing

- The snake is a `List<int>` of cell indices, head first. Everything — collisions, spawning,
  the comeback — is index arithmetic on that one list; the components only draw it.
- Head and tail are drawn part way between cells from `tickProgress`, so the snake glides
  instead of jumping a whole cell per tick. The segments between them are already touching, so
  only the two ends need it. `grewLastStep` tells the tail to stay put on a tick that ate.
- Steering happens on drag *update*, not drag end, and the origin resets after each turn, so a
  player can draw a whole path with one finger. A flick too short to have steered on the way is
  still picked up when the drag ends.

## When it feels wrong

| Symptom | Reach for |
|---|---|
| Too slow to start, or unplayable by twenty apples | `_startInterval`, `_intervalStep`, `_minInterval` |
| Board feels cramped or empty | `columns`, `rows` |
| Turns get missed, or fire on a stray thumb | `_swipeThreshold`, `_flickThreshold` |
| Runs die of length rather than of speed | `trimUnlockLength`, `trimChance`, `trimAmount` |
