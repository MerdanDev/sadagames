# Tile Tap

`lib/games/tile_tap/` — the Magic Tiles shape, and the game the synthesised audio exists for.

**The loop.** Four columns scroll down, one dark tile per row. Tap the column holding the tile
the player owes. A wrong column, or a row slipping past untapped, ends the run.

**Each column is a note.** Column index maps straight to a scale degree, so a good run plays a
phrase rather than a rattle. This is why the audio work was worth doing.

## How it gets harder

The track speeds up with every tile hit, `260 → 720` px/s.

## Comeback

A **skip** is earned every 15 tiles (`tilesPerSkip`, capped at `maxSkips` = 2) and covers
exactly one mistake, of either kind. Skips start at zero: they are earned, never given.

## Two things that were wrong at first, and must stay right

- **The track keeps untapped rows queued above the screen** (`_queuedRows` = 3). Topping up by
  position alone let a quick player clear everything on screen, leaving `targetRow` null and
  taps doing nothing.
- **A run starts with clear space under the first tile** (`_startLead` = 3 rows). Starting flush
  at the bottom edge meant the first row left in under a second, before the player could find
  it.

## When it feels wrong

| Symptom | Reach for |
|---|---|
| The opening feels rushed | `_startLead` |
| Too slow to start, or unplayable later | `_baseSpeed`, `_maxSpeed` |
| Skips too rare or too generous | `tilesPerSkip`, `maxSkips` |
| Only a few rows visible | `_rowsOnScreen` |
