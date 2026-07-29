# Stack Tower

`lib/games/stack_tower/` — one moving rectangle, and the whole game.

**The loop.** A slab slides across; tap to drop it. Whatever hangs over the edge is sliced off
and tumbles away, so the next slab is narrower. Miss the tower entirely and the run ends.

## How it gets harder

Trimming is one way: every sloppy drop makes every later drop harder. On top of that the slab
speeds up with height, `150 → 520` px/s.

## Comeback

A drop within `perfectTolerance` (6 px) counts as **perfect**: the slab snaps flush and hands
back `perfectBonus` (12 px) of width, never beyond the width the tower started at. Since
trimming is otherwise one way, perfect drops are the only thing keeping a long run alive. They
are counted in the HUD.

## Worth knowing

- Each new slab starts from the **opposite side**, so the run cannot be tapped through blindly
  on rhythm.
- The tower is a container that slides down by one block height per drop, which keeps the
  active row at a fixed place on screen.
- The sliced piece and the slab that misses are both `FallingCut` components: decoration only,
  spawned after the tower state has already been updated.

## When it feels wrong

| Symptom | Reach for |
|---|---|
| Perfect drops too easy or impossible | `perfectTolerance` |
| Runs die too quickly | `perfectBonus` |
| Too slow to start, or unplayable later | `_baseSpeed`, `_maxSpeed` |
| The scroll feels laggy | `_scrollDuration` |
