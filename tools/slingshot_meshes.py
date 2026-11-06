"""Giant slingshot (QM, Nov 6), in the pirate props' style (tools/pirate_meshes.py:
faceted convex pieces, flat shaded, studded; each piece its own MeshPart in its own
colour). It flings the player and their pet: no pouch (QM), they stand against the band
itself, which rests pulled back to the ground (easy to step onto), draws back a touch
more, then snaps forward past the fork and lets them go.

Two items, so the band can stretch:

  Slingshot        the frame: stone base, forked wooden trunk, iron bands, rope wraps at
                   the tips (origin: middle of its base, y = 0; it flings toward -z)
  SlingshotBand    a piece of rubber band, 1 stud long along z (centred): the band is three
                   of them, tip -> rider's left, across the rider's back, rider's right -> tip,
                   each stretched with Size.Z = its length

The rider's frame ("the pull") faces -z with the band across its back at BAND_SIDE; it is
CFrame.lookAt(pull, the tips' middle with its height scaled by TILT).
Poses (frame space): TIPS, LOAD (resting), DRAW, NEUTRAL, OVER.

Run: python3 tools/slingshot_meshes.py
Writes design/slingshot/<Name>.obj, design/slingshot/pieces/<Name>_<i>.obj (colours in
pieces/colours.txt), design/slingshot/slingshot.png and slingshot_launch.gif.
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
from rock_meshes import hull_tris, write_obj  # noqa: E402
from plant_meshes import blob, prism, parts_of  # noqa: E402
from crimson_meshes import slab  # noqa: E402

OUT = os.path.join(HERE, "..", "design", "slingshot")
STONE = [(170, 167, 180), (145, 152, 154)]  # the meadow rock shades (design/portal)
BARK = [(186, 134, 80), (158, 108, 62)]     # the palm trunk's
IRON = (86, 88, 98)                         # the barrel hoops'
ROPE = (232, 204, 150)
BAND = (226, 58, 52)

TIPS = [(-7.6, 14.6, 0.0), (7.6, 14.6, 0.0)]   # where the bands tie on
BAND_SIDE = [(-2.0, 0.9, 0.3), (2.0, 0.9, 0.3)]  # where the band wraps the rider, in the pull's space
NEUTRAL = (0.0, 13.0, 3.6)   # the pull when the band is slack
LOAD = (0.0, 1.6, 17.0)      # resting, pulled back to the ground (step on here)
DRAW = (0.0, 1.6, 20.0)      # drawn back before the shot
OVER = (0.0, 22.0, -7.0)     # the furthest it snaps forward


def beam(p, q, w, h=None):
    """A box beam from p to q (w across, h tall; the w side stays level)."""
    h = h or w
    p, q = np.array(p, float), np.array(q, float)
    d = q - p
    d /= np.linalg.norm(d)
    side = np.cross((0, 1, 0), d) if abs(d[1]) < 0.95 else np.array((1.0, 0, 0))
    side /= np.linalg.norm(side)
    up = np.cross(d, side)
    return np.array([a + side * s * w / 2 + up * t * h / 2 for a in (p, q) for s in (-1, 1) for t in (-1, 1)])


def frame(rng):
    stone = [[], []]
    bark = [[], []]
    iron, rope = [], []
    # a two-step stone base
    stone[0] += [slab(rng, -6.4, -0.4, -4.6, -0.1, 1.5, 4.6, 0.35, 0.1), slab(rng, 0.1, -0.4, -4.4, 6.4, 1.5, 4.6, 0.35, 0.1)]
    stone[1] += [slab(rng, -4.2, 1.3, -3.2, 4.2, 2.8, 3.2, 0.35, 0.08)]
    # trunk, the fork's arms (two shades, segment by segment) and knobbly joints
    segs = [((0, 2.4, 0), (0, 7.4, 0), 1.9, 1.7)]
    for s in (-1, 1):
        segs += [((s * 0.6, 6.6, 0), (s * 5.6, 10.0, 0), 1.6, 1.4),
                 ((s * 5.6, 9.6, 0), (s * 7.6, 15.6, 0), 1.35, 1.1)]
    for i, (a, b, r0, r1) in enumerate(segs):
        bark[i % 2].append(prism(rng, a, b, r0, r1, 9, 0.04))
    bark[1].append(blob(rng, (0, 7.6, 0), 2.1, 14, jitter=0.06))
    for s in (-1, 1):
        bark[0].append(blob(rng, (s * 5.6, 9.9, 0), 1.55, 12, jitter=0.06))
        bark[1].append(blob(rng, (s * 7.6, 15.6, 0), 1.15, 12, squash=(1, 0.8, 1), jitter=0.05))
    # iron bands round the trunk's foot and under the fork
    for y0, y1 in ((2.6, 3.4), (6.0, 6.7)):
        iron.append(prism(rng, (0, y0, 0), (0, y1, 0), 2.0, 1.95, 12, 0.0))
    # rope wraps at the tips, where the bands tie on
    for s in (-1, 1):
        d = np.array((2.0, 6.0, 0)) * (s, 1, 1)
        d /= np.linalg.norm(d)
        for k in range(3):
            c = np.array((s * 7.6, 14.6, 0)) + d * (k - 1) * 0.55
            rope.append(prism(rng, c - d * 0.24, c + d * 0.24, 1.35, 1.35, 10, 0.03))
    return [("Stone", STONE[0], stone[0]), ("Stone", STONE[1], stone[1]), ("Bark", BARK[0], bark[0]),
            ("Bark", BARK[1], bark[1]), ("Iron", IRON, iron), ("Rope", ROPE, rope)]


def band(rng):
    return [("Band", BAND, [slab(rng, -0.6, -0.4, -0.5, 0.6, 0.4, 0.5, 0.12, 0.0)])]


ITEMS = [("Slingshot", frame, 1), ("SlingshotBand", band, 3)]


# ---------------------------------------------------------------- the launch

def smooth(u):
    u = min(max(u, 0.0), 1.0)
    return u * u * (3 - 2 * u)


FIRE = 0.24  # s from DRAW to OVER


def pull_at(t):
    """The pull (the band's middle) at time t (s): resting at LOAD, drawn back (0.6 s), a beat,
    snapped forward (ease-in) to OVER, a damped wobble about NEUTRAL, then wound back
    down to LOAD (1.4 s)."""
    L, D, N, O = (np.array(v) for v in (LOAD, DRAW, NEUTRAL, OVER))
    if t < 0.6:
        return L + (D - L) * smooth(t / 0.6)
    t -= 0.6
    if t < 0.2:
        return D
    t -= 0.2
    if t < FIRE:
        u = t / FIRE
        return D + (O - D) * u * u
    t -= FIRE
    if t < 0.9:
        return N + (O - N) * math.cos(2 * math.pi * 1.8 * t) * math.exp(-4.5 * t)
    t -= 0.9
    return N + (L - N) * smooth(t / 1.4)


DURATION = 0.6 + 0.2 + FIRE + 0.9 + 1.4
RELEASE = 0.6 + 0.2 + FIRE * 0.8  # s: the rider lets go as the band passes the tips
TILT = 0.35         # how much of the band's pitch the rider takes
FLING_SPEED = 60.0  # studs/s (preview; the game sets its own)
GRAVITY = 60.0      # studs/s^2 (preview)


def look_at(pos, target):
    f = np.array(target, float) - pos
    f /= np.linalg.norm(f)
    r = np.cross(f, (0, 1, 0))
    r /= np.linalg.norm(r)
    u = np.cross(r, f)
    return np.stack([r, u, -f], 1)  # columns: right, up, back (Roblox's)


def pull_cf(t):
    p = pull_at(t)
    mid = (np.array(TIPS[0]) + TIPS[1]) / 2
    mid[1] = p[1] + (mid[1] - p[1]) * TILT  # keep the rider fairly upright
    return look_at(p, mid), p


def moved(pieces, R, t):
    return [(label, col, [[tri @ R.T + t for tri in hull] for hull in hulls]) for label, col, hulls in pieces]


def rider():
    """A pet stand-in (a blocky pony) with the scale figure on it, in the pull's space."""
    k = TA.Kit()
    pet, dark = (236, 170, 96), (196, 128, 64)
    y = -1.45
    for x in (-1.0, 0.4):
        for z in (-3.6, -0.9):
            k.box("Leg", (x, y, z), (x + 0.6, y + 1.6, z + 0.6), dark)
    k.box("Body", (-1.3, y + 1.6, -4.0), (1.3, y + 3.6, -0.2), pet)
    k.box("Head", (-0.9, y + 3.0, -5.6), (0.9, y + 4.8, -3.6), pet)
    k.box("Ear", (-0.8, y + 4.8, -4.4), (-0.3, y + 5.4, -4.0), dark)
    k.box("Ear", (0.3, y + 4.8, -4.4), (0.8, y + 5.4, -4.0), dark)
    f = TA.Kit()
    TA.figure(f, 0)
    seat = partlib.T(0, y + 3.6 - 1.2, -2.0)  # the figure straddles the pony's back
    return k.parts + [Part(p.name, p.size, seat @ p.cf, p.color) for p in f.parts]


def M(R, t):
    m = np.eye(4)
    m[:3, :3] = R
    m[:3, 3] = t
    return m


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
    rider_parts = rider()

    def scene(t, carried=True, flying=None):
        """carried: the rider on the band; flying: the rider's 4x4 pose in the air."""
        R, p = pull_cf(t)
        ps = parts_of(built["Slingshot"])
        ends = [R @ np.array(side) + p for side in BAND_SIDE]
        for a, b in ((TIPS[0], ends[0]), (ends[0], ends[1]), (ends[1], TIPS[1])):
            ps += parts_of([("Band", BAND, [hull_tris(beam(a, b, 1.2, 0.8))])])
        m = M(R, p) if carried else flying
        if m is not None:
            ps += [Part(q.name, q.size, m @ q.cf, q.color) for q in rider_parts]
        return ps

    # still: loaded, from two sides
    a = render(scene(0), eye=(-34, 20, -30), target=(0, 7, 4), W=900, H=900, fov=45, fog=False, outline=False)
    b = render(scene(0), eye=(30, 16, 40), target=(0, 7, 4), W=900, H=900, fov=45, fog=False, outline=False)
    out = Image.new("RGB", (1800, 900))
    out.paste(a, (0, 0))
    out.paste(b, (900, 0))
    out.save(os.path.join(OUT, "slingshot.png"))
    if os.environ.get("STILL"):  # STILL=1: skip the GIF
        return

    # the launch: 30 fps, side on; the rider flies off toward -z
    fps = 30
    R0, p0 = pull_cf(RELEASE)
    _, p1 = pull_cf(RELEASE + 1 / 240)
    vel = (p1 - p0) / np.linalg.norm(p1 - p0) * FLING_SPEED
    frames = []
    for i in range(int(fps * (DURATION + 0.5))):
        t = max(i / fps - 0.3, 0)
        carried, fly = t < RELEASE, None
        if not carried:
            s = t - RELEASE
            pos = p0 + vel * s + np.array((0, -0.5 * GRAVITY * s * s, 0))
            if pos[1] > -10:
                fly = M(R0 @ partlib.Rx(-300 * s)[:3, :3], pos)
        img = render(scene(t, carried, fly), eye=(-44, 14, -10), target=(0, 13, -10),
                     W=640, H=460, fov=55, fog=False, outline=False)
        frames.append(img.convert("P", palette=Image.ADAPTIVE, colors=128))
    frames[0].save(os.path.join(OUT, "slingshot_launch.gif"), save_all=True, append_images=frames[1:],
                   duration=int(1000 / fps), loop=0, optimize=False)


if __name__ == "__main__":
    main()
