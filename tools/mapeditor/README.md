# Map editor (World 1)

Fight to Steal an Egg's map editor, for Lasso a Pet's World 1 course (QM, Nov 6). It edits
`maps/world1.map`: the course south of the start line, a 4-stud cell at a time. The base
(north of the start line), World.Barriers and the far scenery (World.Cliffs.Far) aren't in it.

On this Mac:

    python3 tools/mapeditor/serve.py

then open http://localhost:3001. **Save to game** writes `maps/world1.map` and builds it into
World 1's open Studio place (Edit mode; stop Play first). Publish the place in Studio to keep it.

- **Floor** and **Walls** tabs: tiles to paint with. Paint (B), rectangle (U), bucket (G: fills
  the patch of one tile you click, floors and walls alike), pick (I or Alt+click).
- A wall tile has its own height: **+ New tile** on the Walls tab adds one 4 studs higher (set
  any height on the right), so walls of mixed heights sit side by side. Sides and Cap pick the
  names whose colours they take.
- **Colours**: each biome's colours, as the game paints them (Shared/WorldColors). A tile's name
  (Ground, Dirt, Wall, Cliff...) takes that name's colours in whichever biome it's in. Changed
  colours go on World as attributes; Reset goes back to Config's.
- **Objects**: the obstacles, decor and nests. Select (V) to drag, Q/E turn, [ ] scale,
  Ctrl+D duplicate, Delete. Place (P) adds one of the kind picked in the tray.
- **Biome borders**: the dashed lines. Drag one with Select to stretch or shrink the biomes
  either side (World.Borders, Shared/Borders); the red one is the finish line.

If the place was changed by hand in Studio, `python3 tools/mapeditor/export.py` reads it back
into `maps/world1.map` (and the palette); `export.py palette` just refreshes Config's colours.

Files: `editor.html` (the page), `build.py` (bakes it into MapEditor.html), `serve.py`,
`export.py` + `studio/export.luau` (place to .map), `studio/build.luau` (.map to place),
`mapfile.py` (the format), `studio.py` (talks to Studio).
