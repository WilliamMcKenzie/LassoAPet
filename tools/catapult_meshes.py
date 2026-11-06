"""Catapult (QM, Nov 6), in the pirate props' style (tools/pirate_meshes.py: faceted
convex pieces, flat shaded, studded; each piece its own MeshPart in its own colour).

A wooden siege catapult on four wheels: two side beams with cross beams, a front A-frame
with a padded stop bar, rope-bound axle in the middle, and a throwing arm with a bucket
that holds a rock. Three items, so the arm can swing and the rock can fly:

  Catapult       the frame (origin: middle of its base, y = 0; it throws toward -z)
  CatapultArm    the arm and bucket, origin AT THE AXLE (rotate about its x axis);
                 built lying back along +z (the fired pose is ARM_FIRED degrees forward)
  CatapultRock   the rock, origin at its centre

Place CatapultArm at ARM_PIVOT in the Catapult's space, turned up by ARM_COCKED degrees
(about x); the rock sits at ROCK_AT in the arm's space.

Run: python3 tools/catapult_meshes.py
Writes design/catapult/<Name>.obj, design/catapult/pieces/<Name>_<i>.obj (colours in
pieces/colours.txt), design/catapult/catapult.png and catapult_launch.gif.
"""

import math
import os
import sys

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import partlib  # noqa: E402
from partlib import Part, render  # noqa: E402
import terrain_assets as TA  # noqa: E402
from rock_meshes import hull_tris, write_obj, ROCK  # noqa: E402
from plant_meshes import blob, prism, parts_of  # noqa: E402
from crimson_meshes import slab  # noqa: E402
from tomb_meshes import frustum  # noqa: E402

OUT = os.path.join(HERE, "..", "design", "catapult")
WOOD = (210, 160, 100)       # beams (the pirate deck's)
WOOD_DARK = (156, 104, 56)   # arm, posts (the crate frame's)
WHEEL = (188, 118, 62)       # (the barrel's)
IRON = (86, 88, 98)          # bands, hubs, axles (the barrel hoops')
ROPE = (232, 204, 150)
CUP = (104, 60, 32)          # the bucket's hollow (the ship rail's)

ARM_PIVOT = (0.0, 4.2, 1.6)  # the axle, in the frame's space
ARM_COCKED = 14.0            # degrees the arm is raised off the +z horizontal, resting
ARM_FIRED = 104.0            # degrees at the stop bar (past upright, leaning forward)
ARM_LEN = 9.4
ROCK_R = 1.15
ROCK_AT = (0.0, 1.55 + ROCK_R * 0.8, ARM_LEN)  # in the arm's space


def beam(p, q, w, h=None):
    """A square-ish beam from p to q (w across, h tall; the w side stays level)."""
    h = h or w
    p, q = np.array(p, float), np.array(q, float)
    d = q - p
    d /= np.linalg.norm(d)
    side = np.cross((0, 1, 0), d) if abs(d[1]) < 0.95 else np.array((1.0, 0, 0))
    side /= np.linalg.norm(side)
    up = np.cross(d, side)
    pts = []
    for a in (p, q):
        for s in (-1, 1):
            for t in (-1, 1):
                pts.append(a + side * s * w / 2 + up * t * h / 2)
    return np.array(pts)


def rod(rng, p, q, r, sides=8):
    return prism(rng, p, q, r, r, sides, 0.0)


def wheel(rng, x, z, r=1.9, t=0.8):
    """A spoked-look wheel: a thick wooden disc, an iron tyre and an iron hub (axle along x)."""
    s = 1 if x > 0 else -1
    disc = rod(rng, (x - s * t / 2, r, z), (x + s * t / 2, r, z), r * 0.9, 12)
    tyre = rod(rng, (x - s * t * 0.45, r, z), (x + s * t * 0.45, r, z), r, 12)
    hub = rod(rng, (x + s * t * 0.3, r, z), (x + s * (t / 2 + 0.35), r, z), 0.55, 8)
    return disc, tyre, hub


def frame(rng):
    wood, dark, wheels, iron, rope = [], [], [], [], []
    by = (1.9, 2.9)  # side beams sit on the wheel axles
    # side beams and cross beams
    for x in (-2.6, 2.6):
        wood.append(slab(rng, x - 0.45, by[0], -6.4, x + 0.45, by[1], 8.4, 0.15, 0.04))
    for z in (-5.8, 0.2, 7.8):
        wood.append(slab(rng, -3.05, by[1] - 0.05, z - 0.45, 3.05, by[1] + 0.75, z + 0.45, 0.15, 0.04))
    # wheels, with iron axles under the beams
    for z in (-4.4, 6.0):
        iron.append(rod(rng, (-3.6, 1.9, z), (3.6, 1.9, z), 0.3))
        for x in (-3.55, 3.55):
            d, t, h = wheel(rng, x, z)
            wheels.append(d)
            iron += [t, h]
    # the front A-frame: two posts up to the stop bar, braced back and forward
    stop_y, stop_z = 10.1, -1.0
    for x in (-2.6, 2.6):
        dark.append(beam((x, by[1] - 0.2, stop_z), (x, stop_y + 0.6, stop_z), 0.8))
        dark.append(beam((x, by[1], -5.6), (x, stop_y - 1.6, stop_z - 0.2), 0.6))   # front brace
        dark.append(beam((x, by[1], 4.6), (x, stop_y - 2.4, stop_z + 0.3), 0.6))    # back brace
        iron.append(slab(rng, x - 0.5, stop_y - 2.0, stop_z - 0.5, x + 0.5, stop_y - 1.5, stop_z + 0.5, 0.05, 0.0))
    dark.append(slab(rng, -3.1, stop_y - 0.4, stop_z - 0.5, 3.1, stop_y + 0.5, stop_z + 0.5, 0.12, 0.03))
    rope.append(slab(rng, -1.0, stop_y - 0.55, stop_z - 0.7, 1.0, stop_y + 0.65, stop_z + 0.6, 0.25, 0.04))
    # the rear rest the cocked arm lies on
    for x in (-1.5, 1.5):
        dark.append(beam((x, by[1] + 0.6, 7.8), (x, 5.0, 7.8), 0.55))
    dark.append(slab(rng, -1.9, 4.75, 7.4, 1.9, 5.3, 8.2, 0.1, 0.02))
    # axle blocks and the rope-bound axle (the arm sits in the gap in the middle)
    px, py, pz = ARM_PIVOT
    for x in (-2.6, 2.6):
        dark.append(slab(rng, x - 0.5, by[1], pz - 0.7, x + 0.5, py + 0.8, pz + 0.7, 0.12, 0.03))
    iron.append(rod(rng, (-3.3, py, pz), (3.3, py, pz), 0.28))
    for x0, x1 in ((-2.05, -0.6), (0.6, 2.05)):
        for i in range(3):
            a, b = x0 + (x1 - x0) * i / 3 + 0.03, x0 + (x1 - x0) * (i + 1) / 3 - 0.03
            rope.append(rod(rng, (a, py, pz), (b, py, pz), 0.8 + 0.06 * (i % 2), 10))
    # iron bands where the posts meet the beams
    for x in (-2.6, 2.6):
        for z in (stop_z, -5.8, 7.8):
            iron.append(slab(rng, x - 0.52, by[1] - 0.25, z - 0.55, x + 0.52, by[1] + 0.1, z + 0.55, 0.05, 0.0))
    return [("Beams", WOOD, wood), ("Posts", WOOD_DARK, dark), ("Wheels", WHEEL, wheels),
            ("Iron", IRON, iron), ("Rope", ROPE, rope)]


def arm(rng):
    """The arm in its own space: the axle at the origin, the arm along +z, the bucket at
    ARM_LEN opening up (+y)."""
    dark, iron, bucket, cup = [], [], [], []
    dark.append(beam((0, 0, -1.3), (0, 0.15, ARM_LEN - 0.6), 0.85, 0.85))
    for z in (-0.9, 0.9, 4.2):
        iron.append(beam((0, 0, z - 0.22), (0, 0.02 * z, z + 0.22), 1.0, 1.0))
    # the bucket: a wooden cup on the arm's end, an inset dark hollow on top, an iron rim
    cy, cz = 0.35, ARM_LEN
    bucket.append(frustum(10, 0.95, cy, 1.75, cy + 1.25, c=(0.0, cz)))
    cup.append(frustum(10, 1.35, cy + 1.2, 1.45, cy + 1.32, c=(0.0, cz)))
    ring = []
    for i in range(10):
        a = 2 * math.pi * i / 10
        for r, y in ((1.78, cy + 1.05), (1.84, cy + 1.3), (1.5, cy + 1.3)):
            ring.append((math.cos(a) * r, y, cz + math.sin(a) * r))
    iron.append(np.array(ring))
    return [("Arm", WOOD_DARK, dark), ("Bucket", WHEEL, bucket), ("Hollow", CUP, cup), ("Iron", IRON, iron)]


def rock(rng):
    return [("Rock", ROCK, [blob(rng, (0, 0, 0), ROCK_R, 14, squash=(1.05, 0.9, 1.0), jitter=0.16)])]


ITEMS = [("Catapult", frame, 1), ("CatapultArm", arm, 2), ("CatapultRock", rock, 3)]


# ---------------------------------------------------------------- posing (previews)

def rx(deg):
    """Rotation about x that lifts +z toward +y by deg."""
    a = math.radians(deg)
    c, s = math.cos(a), math.sin(a)
    return np.array([[1, 0, 0], [0, c, -s], [0, s, c]]).T


def moved(pieces, R, t):
    return [(label, col, [[tri @ R.T + t for tri in hull] for hull in hulls]) for label, col, hulls in pieces]


def arm_pose(deg):
    return rx(deg), np.array(ARM_PIVOT)


def rock_at(deg):
    R, t = arm_pose(deg)
    return R @ np.array(ROCK_AT) + t


def launch_curve(time):
    """The arm's angle at time (s) of the launch: snaps forward to the stop bar
    (ease-in, 0.28 s), a small bounce, a pause, then winds back down (1.1 s)."""
    if time < 0.28:
        u = time / 0.28
        return ARM_COCKED + (ARM_FIRED - ARM_COCKED) * u * u * u
    time -= 0.28
    if time < 0.3:
        return ARM_FIRED - 9 * math.sin(math.pi * time / 0.3) * math.exp(-time * 6)
    time -= 0.3
    if time < 0.35:
        return ARM_FIRED
    time -= 0.35
    if time < 1.1:
        u = time / 1.1
        u = u * u * (3 - 2 * u)
        return ARM_FIRED + (ARM_COCKED - ARM_FIRED) * u
    return ARM_COCKED


RELEASE = 0.26  # s: the rock leaves the bucket just before the arm hits the stop bar
ROCK_SPEED = 55.0    # studs/s the rock leaves at, along the bucket's path
ROCK_GRAVITY = 35.0  # studs/s^2 (a floaty, readable arc)


def main():
    os.makedirs(os.path.join(OUT, "pieces"), exist_ok=True)
    for f in os.listdir(os.path.join(OUT, "pieces")):
        os.remove(os.path.join(OUT, "pieces", f))
    built = {}
    colours = ["# piece: label, RGB"]
    for name, builder, seed in ITEMS:
        raw = builder(np.random.default_rng(seed))
        pieces = [(label, col, [hull_tris(np.asarray(p, float)) for p in pts]) for label, col, pts in raw]
        built[name] = pieces
        allh = [x for _, _, hs in pieces for x in hs]
        nt = write_obj(name, allh, os.path.join(OUT, name + ".obj"))
        for i, (label, col, hs) in enumerate(pieces):
            write_obj(f"{name}_{i + 1}", hs, os.path.join(OUT, "pieces", f"{name}_{i + 1}.obj"))
            colours.append(f"{name}_{i + 1}: {label}, {col[0]}, {col[1]}, {col[2]}")
        pts = np.concatenate([np.concatenate(h) for h in allh])
        size = pts.max(0) - pts.min(0)
        print(f"{name}: {len(pieces)} pieces, {nt} tris, {size[0]:.1f} x {size[1]:.1f} x {size[2]:.1f}, "
              f"min y {pts.min(0)[1]:.2f}")
    with open(os.path.join(OUT, "pieces", "colours.txt"), "w") as f:
        f.write("\n".join(colours) + "\n")

    partlib.GROUND = np.array((105, 255, 74), float)
    partlib.GROUND2 = np.array((77, 196, 63), float)
    k = TA.Kit()
    TA.figure(k, 0)
    fig = [Part(p.name, p.size, partlib.T(6.2, 0, -7.5) @ p.cf, p.color) for p in k.parts]

    def scene(deg, rock_pos):
        R, t = arm_pose(deg)
        ps = parts_of(built["Catapult"]) + parts_of(moved(built["CatapultArm"], R, t))
        if rock_pos is not None:
            ps += parts_of(moved(built["CatapultRock"], np.eye(3), np.array(rock_pos)))
        return ps

    # still: cocked and loaded, from two sides
    a = render(scene(ARM_COCKED, rock_at(ARM_COCKED)) + fig, eye=(-26, 15, -24), target=(0, 5, 1.5),
               W=900, H=900, fov=42, fog=False, outline=False)
    b = render(scene(ARM_COCKED, rock_at(ARM_COCKED)) + fig, eye=(28, 12, 22), target=(0, 5, 1.5),
               W=900, H=900, fov=42, fog=False, outline=False)
    out = Image.new("RGB", (1800, 900))
    out.paste(a, (0, 0))
    out.paste(b, (900, 0))
    out.save(os.path.join(OUT, "catapult.png"))

    # the launch: 30 fps, side-on 3/4 view, the rock flies off toward -z
    fps, dur = 30, 2.8
    p0 = rock_at(launch_curve(RELEASE))
    dt = 1 / 120
    p1 = rock_at(launch_curve(RELEASE + dt))
    vel = (p1 - p0) / dt
    vel = vel / np.linalg.norm(vel) * ROCK_SPEED
    g = np.array((0, -ROCK_GRAVITY, 0))
    frames = []
    for i in range(int(fps * dur)):
        time = i / fps - 0.3  # hold cocked a moment first
        deg = launch_curve(max(time, 0))
        if time < RELEASE:
            rp = rock_at(deg)
        else:
            s = time - RELEASE
            rp = p0 + vel * s + 0.5 * g * s * s
            if rp[1] < -5:
                rp = None
        img = render(scene(deg, rp) + fig, eye=(-44, 11, -12), target=(0, 8, -12),
                     W=640, H=440, fov=50, fog=False, outline=False)
        frames.append(img.convert("P", palette=Image.ADAPTIVE, colors=128))
    frames[0].save(os.path.join(OUT, "catapult_launch.gif"), save_all=True, append_images=frames[1:],
                   duration=int(1000 / fps), loop=0, optimize=False)


if __name__ == "__main__":
    main()
