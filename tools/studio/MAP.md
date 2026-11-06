# Editing World 1's map (QM, Nov 6)

**The map editor** (tools/mapeditor/README.md): `python3 tools/mapeditor/serve.py`, then
http://localhost:3001. It paints the course's floor and wall tiles (any wall height), its
colours, objects and biome borders, and Save builds them into the open Studio place.

The map is the parts in `Workspace.World` of the live place (126872244121414), saved in the
place like Fight to Steal an Egg's `workspace.Map`. Edit it in Studio (Edit mode) and
publish; the place is the source of truth. `src/world/World.rbxmx` is an old snapshot, so
don't push it over the place. Code loads (`.claude/studio-tools/load.py`) only touch scripts.

## Biome borders

`Workspace.World.Borders` has one part where each biome starts (Desert, Snow, Ocean,
Volcano, Jurassic) and `End` at the finish line. Drag them along the course: only their Z
counts. Config reads them when the game starts (`Shared/Borders`), so biome lengths, the
herds, nests, colours, sky, quests and the finish line all follow. They're invisible in Play.
The Meadow always starts at the start line. The floor is cut at `End`, so moving `End`
further out than the built floor leaves a gap.

## The Lasso Map plugin

`tools/studio/LassoMap.lua`, installed in `~/Documents/Roblox/Plugins` (restart Studio to
pick up a new copy). Toolbar "Lasso Map":

- moving a border repaints the ground and walls with each biome's colours (as Play does)
  and prints the biome lengths in the Output
- **Make borders** adds any missing border where Config's Lengths put it
- **Repaint** repaints by hand

Publish the place to keep any of it.
