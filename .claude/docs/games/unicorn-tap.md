# Unicorn Tap

`lib/game/` — note the path: this is the Very Good flame template's own demo, left in place
rather than rewritten, so it does not live under `lib/games/`.

**The loop.** Tap the unicorn, a counter climbs. That is all it does.

## Why it is still here

It is the only game with a sprite, and it is a working reference for Flame animation and
`flame_behaviors`. Keep it until there are enough real games to replace it — that is a recorded
decision in `CLAUDE.md`.

## Worth knowing

- It keeps **no record**, so its menu tile shows no personal best. The catalog supports that:
  `recordMetric` is null.
- Its counter is drawn *inside* Flame, not as a Flutter HUD like every other game, so it needs
  the safe area passed in by hand: `Sadagames.safeArea`. Guard that setter with `hasLayout` —
  the view hands the insets down before the game has a size.
- It does not meet the engagement bar in `../game-engagement.md`. It is grandfathered in, not
  an example to copy.
