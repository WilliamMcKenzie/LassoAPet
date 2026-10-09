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
  in the grass. Pens stand on grass, and the wall columns stay grass.

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
- A pad 18 across, in the yard just right of each gate (from inside the pen looking out),
  facing the yard centre. Placeholder in the render: a red mat with a bull on a post.

| Pen | Pad (x, z) |
|---|---|
| 1 | -18.0, 173.0 |
| 2 | -75.2, 129.6 |
| 3 | 52.0, 157.1 |
| 4 | -78.6, 57.9 |
| 5 | 84.9, 93.3 |

## Meadow props
- 43 copies of the meadow's own Stone, Bush, Boulder and BoulderSplit models (the ones in
  World.Obstacles), listed in `props` with position and yaw. They cluster against the
  walls and in the corners like the meadow's wall clusters, with a few bushes and stones
  between the gates at the yard's edge. The yard itself stays clear.
- Put them in their own folder (e.g. World.BaseDecor), not World.Obstacles, so the ride
  doesn't treat them as course obstacles.

## Carl and the podium
- Carl's stall moves to (-104, 20), and the podium to (104, 20), in the front corners
  either side of the corridor.
