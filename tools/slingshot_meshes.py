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
BAND = (196, 170, 128)  # a tan band (in game: Config.Slingshot.BandColors by pen level)

TIPS = [(-7.6, 14.6, 0.0), (7.6, 14.6, 0.0)]   # where the bands tie on
BAND_SIDE = [(-2.0, 0.9, 0.3), (2.0, 0.9, 0.3)]  # where the band wraps the rider, in the pull's space
SLACK = (0.0, 10.4, 0.0)     # resting: the band hangs slack between the tips (QM, Nov 7)
NEUTRAL = SLACK              # what it wobbles about after the shot
LOAD = (0.0, 1.6, 11.0)      # pulled back to the ground, the rider on it
DRAW = (0.0, 1.6, 13.5)      # drawn back before the shot
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


def chamfer(corners, c):
    """A box's 8 corners (index bits: x, y, z as in slab), each cut back c toward its 3 neighbours."""
    pts = []
    for i, p in enumerate(corners):
        for k in range(3):
            q = corners[i ^ (1 << (2 - k))]
            pts.append(p + (q - p) / np.linalg.norm(q - p) * c)
    return np.array(pts)


def block(p, q, w, h=None, c=0.18):
    """A chamfered box beam from p to q, w across and h deep (Lego-block chunky)."""
    h = h or w
    p, q = np.array(p, float), np.array(q, float)
    d = q - p
    d /= np.linalg.norm(d)
    side = np.array((1.0, 0, 0)) if abs(d[0]) < 0.95 else np.array((0, 0, 1.0))
    side = side - d * side.dot(d)
    side /= np.linalg.norm(side)
    up = np.cross(d, side)
    corners = np.array([a + side * sx * w / 2 + up * sz * h / 2 for a in (p, q) for sx in (-1, 1) for sz in (-1, 1)])
    return chamfer(corners, c)


WOOD = (222, 124, 62)       # (QM, Nov 7: a plain orange wooden Y)
KNOT = (150, 76, 38)
WRAP = (240, 228, 196)


def curve(a, c, b, n):
    """n+1 points along the quadratic curve a -> b bent toward c."""
    a, c, b = (np.array(v, float) for v in (a, c, b))
    return [(1 - u) ** 2 * a + 2 * (1 - u) * u * c + u * u * b for u in np.linspace(0, 1, n + 1)]


def frame(rng):
    """QM, Nov 7 (a simple cartoon slingshot): one forked branch stuck in the ground, its
    trunk splitting into two arms that curve out and up to the tips, cream cloth wrapped
    round each tip where the band ties on, a few dark knots. Three pieces (wood, wraps,
    knots); round, faceted segments, studded in game."""
    wood, wrap, knot = [], [], []
    wood.append(prism(rng, (0, -0.6, 0), (0, 5.4, 0), 1.45, 1.3, 12, 0.0))
    wood.append(blob(rng, (0, 5.4, 0), 1.55, 18, squash=(1.25, 1.0, 1.0), jitter=0.0))
    for sgn in (-1, 1):
        pts = curve((sgn * 0.5, 5.0, 0), (sgn * 6.4, 6.6, 0), (sgn * 7.6, 15.4, 0), 6)
        for k in range(len(pts) - 1):
            r0 = 1.2 - 0.25 * k / 6
            r1 = 1.2 - 0.25 * (k + 1) / 6
            wood.append(prism(rng, pts[k], pts[k + 1] + (pts[k + 1] - pts[k]) * 0.12, r0, r1, 12, 0.0))
        wood.append(blob(rng, pts[-1], 0.98, 14, squash=(1, 0.5, 1), jitter=0.0))  # (the rounded end)
        # the cloth wrap round the tip (the band ties on here: TIPS)
        d = pts[-1] - pts[-2]
        d /= np.linalg.norm(d)
        c = np.array(TIPS[0 if sgn < 0 else 1])
        wrap.append(prism(rng, c - d * 0.75, c + d * 0.75, 1.2, 1.18, 12, 0.0))
        # knots
        mid = pts[3]
        knot.append(blob(rng, mid + np.array((0, 0, -1.0)), 0.3, 8, squash=(1, 1, 0.5), jitter=0.0))
    knot.append(blob(rng, (0.35, 2.4, -1.35), 0.32, 8, squash=(1, 1, 0.5), jitter=0.0))
    knot.append(blob(rng, (-0.4, 3.6, 1.25), 0.26, 8, squash=(1, 1, 0.5), jitter=0.0))
    return [("Wood", WOOD, wood), ("Wrap", WRAP, wrap), ("Knot", KNOT, knot)]


def band(rng):
    return [("Band", BAND, [slab(rng, -0.6, -0.4, -0.5, 0.6, 0.4, 0.5, 0.12, 0.0)])]


ITEMS = [("Slingshot", frame, 1), ("SlingshotBand", band, 3)]


# ---------------------------------------------------------------- the launch

def smooth(u):
    u = min(max(u, 0.0), 1.0)
    return u * u * (3 - 2 * u)


FIRE = 0.24  # s from DRAW to OVER


GRAB = 0.5  # s: the slack band stretched back to the rider


def pull_at(t):
    """The pull (the band's middle) at time t (s): hanging slack, stretched back to the rider
    at LOAD (GRAB), drawn back (0.6 s), a beat, snapped forward (ease-in) to OVER, a damped
    wobble about NEUTRAL (slack), then settling slack (0.4 s)."""
    L, D, N, O, S = (np.array(v) for v in (LOAD, DRAW, NEUTRAL, OVER, SLACK))
    if t < GRAB:
        return S + (L - S) * smooth(t / GRAB)
    t -= GRAB
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
    return N


DURATION = GRAB + 0.6 + 0.2 + FIRE + 0.9 + 0.4
RELEASE = GRAB + 0.6 + 0.2 + FIRE * 0.8  # s: the rider lets go as the band passes the tips
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
    mid[2] = p[2] - max(p[2] - mid[2], 1.0)  # (never straight up: hanging slack, it faces -z too)
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
        Rr, pr = pull_cf(max(t, GRAB))  # (the rider waits at LOAD while the band comes back to them)
        m = M(Rr, pr) if carried else flying
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
