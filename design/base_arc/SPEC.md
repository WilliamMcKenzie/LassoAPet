# Arc home base (QM approved Oct 9)

Renders: `arc_overhead.png`, `arc_from_home_line.png`. Every number below, plus every
dirt tile and prop, is in `arc_layout.json`. `arc_base.py` makes the renders and the JSON.
Studs, Roblox axes: the course runs to -z from the home line at z = 0, and the base is z > 0.

## Base
- Inside the walls: x -176..176, z 0..264 (352 x 264, was 288 x 144). Same 48-high checker
  walls in the meadow wall colours. The front wall leaves the 112-wide course corridor
  (x -56..56) open. Config.HomeHalfWidth = 176, HomeDepth = 264; tools/home_base.py LAYOUT
  takes the new W/D.
- Floor: the meadow's 4-stud grass checker. Dirt tiles use the meadow dirt colours
  (Config Meadow.Patches.Dirt, the wall colours) and sit 1 stud lower, exactly like the
  meadow (tools/meadow_ground.py). `dirt_rects` in the JSON are the dirt tiles merged
  into 154 rectangles [x0, z0, x1, z1]. Everything else is grass. Ground.heightAt should
  cover the base too, so pets and eggs stand on the sunk dirt.
- What the dirt is: one natural yard in the middle with ragged edges and two grass islands,
  a lane from the yard to the home line, an apron at each gate, and small patches out
  in the grass. Pens stand on grass. No dirt within 8 studs (two tiles) of any wall, front wall stubs included, so the sunk dirt never opens a hole under a wall (QM).

## Pens: five on one arc
- The arc's centre is (0, 90), the middle of the yard. Pen centres sit 130 from it, at
  angles 90, 140, 40, 190, -10 degrees (measured from +x toward +z), in claim order:

| Pen | Centre (x, z) | Gate middle (x, z) |
|---|---|---|
| 1 | 0, 220 | 0, 186 |
| 2 | -99.6, 173.6 | -73.5, 151.7 |
| 3 | 99.6, 173.6 | 73.5, 151.7 |
| 4 | -128.0, 67.4 | -94.5, 73.3 |
| 5 | 128.0, 67.4 | 94.5, 73.3 |

- Each pen is turned to face the yard: CFrame.lookAt(penCentre, Vector3.new(0, 0, 90)),
  with the 10-stud gate gap in the side that faces the yard. Same fence as now (dark posts,
  orange rails, X braces).
- These are the pens at their biggest (68 x 68). A pen grows OUTWARD, away from the yard:
  the gate side stays put on the arc and the back moves toward the wall. tools/pens.py
  needs an arbitrary yaw per pen instead of its three FACING frames.
- Rotated pens no longer line up with the floor checker, so a per-level pen floor colour
  needs its own floor (4-stud checker) inside the fence, turned with the pen, a hair above
  the grass.
- Spawn, Sign and Slots stay as they are now in each pen's own frame. Rides start at the
  gate and cross the dirt yard straight to the corridor; the old corner-pen exitX lane
  goes.

## Mechanical bull spot (one per pen)
- A pad 18 across, in the yard beside each gate, 18 along the arc and 13 out from the fence,
  facing the yard centre. Placeholder in the render: a red mat with a bull on a post.

| Pen | Pad (x, z) |
|---|---|
| 1 | -18.0, 173.0 |
| 2 | -75.2, 129.6 |
| 3 | 52.0, 157.1 |
| 4 | -78.6, 57.9 |
| 5 | 84.9, 93.3 |

## Meadow props and big rocks (QM Oct 9: rocks yes, no flowers)
- Three giant rocks in the meadow Stone/Boulder style (grey tilted chunks, lit caps, mossy
  tops with a bush), as models: `CornerCrag.rbxmx` (about 42 x 42, 30 high), `WallShelf.rbxmx`
  (about 50 x 20, 20 high). Anchored, CanCollide on.
- Each model is authored in its own local frame: the wall face is the z = 0 plane and the rock
  sits in +z (the crag also backs onto a second wall, the x = 0 plane, and sits in +x).
  Ground is y = 0. To place one: insert it as it is, set its WorldPivot to CFrame.new(0, 0, 0)
  (so the pivot is that local origin), then
  PivotTo(CFrame.new(x, 0, z) * CFrame.Angles(0, math.rad(yaw), 0)).
- Placements are in `arc_layout.json` under `big_rocks` (6 of them; QM removed every Tor, the triple stack):

| Rock | x, z | yaw |
|---|---|---|
| CornerCrag | -176, 264 | 90 (back-left corner) |
| CornerCrag | 176, 264 | 180 (back-right corner) |
| WallShelf | -76, 264 | 180 (back wall) |
| WallShelf | 76, 264 | 180 (back wall) |
| WallShelf | -176, 140 | 90 (left wall) |
| WallShelf | 176, 140 | -90 (right wall) |

- None of them touch a pen at full size, Carl or the podium (checked).
- The big rocks replace the small Stone/Bush/Boulder knots near them: `props` now keeps only
  the 14 small ones more than 30 studs from any big rock (it was 43). Remove the others.
- Everything goes in World.BaseDecor, not World.Obstacles, so the ride doesn't treat it as
  course obstacles. No flowers.

## Carl and the podium
- Carl's stall moves to (-104, 20), and the podium to (104, 20), in the front corners
  either side of the corridor.
