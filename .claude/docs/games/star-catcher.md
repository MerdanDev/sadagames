# Star Catcher

`lib/games/star_catcher/` — the first game in the collection, and the template for the rest.

**The loop.** Drag or tap to move the basket; catch falling stars. Three misses and the run
ends.

## How it gets harder

Two things at once, both tied to the score:

- stars fall faster, `110 → 420` px/s
- stars **shrink**, 32 px down to 18 px

## Comeback

Hearts drop in, but only once the player is warmed up: from `heartUnlockScore` (5) and only
while a life is missing. Catching one restores a life, capped at `maxLives`. A missed heart
costs nothing.

## Worth knowing

- The basket renders at priority 1, above the falling pieces, so a caught star slides **behind**
  it rather than flashing across the front for a frame.
- Lives are heart *shapes*, filled versus outlined, so the meaning does not rest on colour.
- The catch pitch walks up the scale with the streak, so a good run rises.

## When it feels wrong

| Symptom | Reach for |
|---|---|
| Too frantic or too sleepy | `_spawnInterval`, `_baseSpeed`, `_maxSpeed` |
| Stars get unhittable | `_minStarDiameter`, and the `score * 0.4` shrink rate |
| Hearts too rare | `_heartChance`, `heartUnlockScore` |
