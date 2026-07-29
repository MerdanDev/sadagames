# Merge Tiles

`lib/games/merge_tiles/` — the 2048 shape. Named for what it does rather than after the game,
and badged `2048` on the menu so people recognise it.

**The loop.** Swipe to slide every tile; equal tiles merge as they meet. Each move that changes
the board adds a new tile (90% a two, 10% a four). The run ends when the board is full and no
neighbours match.

## The rules that are easy to get wrong

- A tile merges **once per swipe**. `[2,2,4]` swiped left gives `[4,4]`, never `[8]`.
- The pair nearest the swiped edge merges first: `[4,4,4]` left gives `[8,4]`, not `[4,8]`.
- A swipe that changes nothing is not a turn and must not add a tile.

All three have tests. Break one and the game stops feeling like 2048.

## Record

The **score**, not the biggest tile. The menu reads `Best: 3540 points` far better than
`Best: 512 tiles`. The biggest tile is shown in the HUD during a run instead.

## Comeback

One undo from the start, plus another with every new biggest tile (`maxUndos` = 3). It restores
the board *and* the score, and works from the game over screen, so a careless swipe never ends
a good run outright.

## Worth knowing

- Tiles slide with a `MoveToEffect` and the swallowed tile drops to priority -1, so it passes
  **under** the tile it merges into. The board grid sits at -2, under both.
- A move finishes asynchronously. `_isTornDown` guards it, because a page closed mid-move used
  to come back to disposed notifiers — it showed up as a flaky test.

## When it feels wrong

| Symptom | Reach for |
|---|---|
| Slides feel sluggish or too snappy | `_slideDuration` |
| Swipes are missed or fire by accident | `_swipeThreshold` |
| Board fills too fast | the `0.1` four-spawn chance in `_spawnTile` |
