"""Rolling Log: World 2 Woodland Maze's Rare (QM, Oct 13), a living log that rolls.

A fat log lying across the path (its length runs left-right, so it rolls forward),
warm bark with raised darker bark strips, pale cut ends with growth rings, and two rings
of steel spikes near its ends pointing up, down, forward and back (QM, Oct 13: like the
Clash Royale log, no face). It stands on its bottom pair; the rider sits between the top
pair.

The round log is stepped from three axis-aligned blocks per slice (a wide one, a tall
one and a square one), so every part stays a plain cube.

Bones: root (stays upright: the rider sits on top like log rolling), neck (empty, on the
log's axis: the lasso loop holds still while the log turns) and Log (everything else,
pivots on the axis so the roll spins it in place). Idle rocks, walk rocks harder, the
gallop rolls.

    python3 tools/rolling_log.py

writes designs/woodland/RollingLog.bbmodel, src/shared/Animals/RollingLogModel.luau and
previews in /mnt/project-files/world2/woodland/renders. Egg: tools/rolling_log_egg.py.
"""

import json
import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import animal_designs as A  # noqa: E402
from animal_designs import Animal  # noqa: E402
from partlib import render  # noqa: E402
from horse_rig import pose  # noqa: E402
from snow_designs import pyramid  # noqa: E402
import numpy as np  # noqa: E402

BARK = (170, 100, 52)
BARK_DARK = (118, 66, 36)
WOOD = (242, 206, 148)
RING = (206, 148, 88)
CORE = (228, 180, 116)
STEEL = (176, 182, 196)
STEEL_DARK = (96, 100, 116)

HALF_L = 4.0  # half the log's length (x)
R = 2.5  # log radius
SPIKE = 1.6  # how far the spikes stand off the bark
CY = R + SPIKE  # axis height: standing on its bottom spikes


def round_slice(a, name, x0, x1, r, color, bone="Log"):
    """A round-ish log slice from three blocks: wide, tall and a square for the corners."""
    s = 0.62 * r
    q = 0.86 * r
    a.box(name + "W", (x0, CY - s, -r), (x1, CY + s, r), color, bone)
    a.box(name + "T", (x0, CY - r, -s), (x1, CY + r, s), color, bone)
    a.box(name + "Q", (x0, CY - q, -q), (x1, CY + q, q), color, bone)


def rolling_log():
    a = Animal("RollingLog", "Rare")
    a.bone_order = [("root", None), ("neck", "root"), ("Log", "root")]
    a.pivots = {"root": (0, CY, 0), "neck": (0, CY, 0), "Log": (0, CY, 0)}

    round_slice(a, "Bark", -HALF_L, HALF_L, R, BARK)
    # cut ends: pale wood, a darker growth ring, a warm core, each standing a plate off the last
    for side, sx in (("L", -1), ("R", 1)):
        for i, (r, c) in enumerate(((R * 0.84, WOOD), (R * 0.56, RING), (R * 0.4, WOOD), (R * 0.2, CORE))):
            x0, x1 = sorted((sx * (HALF_L + i * A.PLATE), sx * (HALF_L + (i + 1) * A.PLATE)))
            round_slice(a, f"End{side}{i + 1}", x0, x1, r, c)

    # raised bark strips running along the log, on the top, back and underside steps
    t = 0.18
    s = 0.62 * R
    for name, lo, hi in (("StripTop", (-3.0, CY + R, -0.6), (0.6, CY + R + t, 0.2)),
                         ("StripTop2", (1.4, CY + R, 0.4), (3.4, CY + R + t, 1.1)),
                         ("StripBack", (-2.2, CY - 0.4, R), (1.8, CY + 0.5, R + t)),
                         ("StripBack2", (2.2, CY + 0.9, R), (3.6, CY + s - 0.1, R + t)),
                         ("StripUnder", (-1.0, CY - R - t, -0.5), (2.6, CY - R, 0.3)),
                         ("StripFront", (-3.6, CY - 1.4, -R - t), (-2.0, CY - 0.6, -R))):
        a.box(name, lo, hi, BARK_DARK, "Log")

    # two rings of steel spikes near the ends (QM: like the Clash Royale log), pointing up,
    # down, forward and back; it stands on its bottom pair. A collar block, then a pyramid.
    c, h, k = 0.65, 0.25, SPIKE - 0.25  # collar half-width, collar height, point length
    for ring, x in (("L", -2.5), ("R", 2.5)):
        for d, axis, sgn in (("Up", 1, 1), ("Down", 1, -1), ("Front", 2, -1), ("Back", 2, 1)):
            base = np.array([x, CY, 0.0])
            base[axis] += sgn * R
            lo, hi = base.copy(), base.copy()
            for i in (0, 1, 2):
                if i != axis:
                    lo[i] -= c
                    hi[i] += c
            hi[axis] = base[axis] + sgn * h
            a.box(f"Collar{ring}{d}", tuple(np.minimum(lo, hi)), tuple(np.maximum(lo, hi)), STEEL_DARK, "Log")
            tip = hi.copy()
            lo2, hi2 = lo.copy(), hi.copy()
            lo2[axis] = hi2[axis] = base[axis] + sgn * h
            lo2 = lo2 + np.where(np.arange(3) == axis, 0, 0.1)
            hi2 = hi2 - np.where(np.arange(3) == axis, 0, 0.1)
            pyramid(a, f"Spike{ring}{d}", tuple(lo2), tuple(hi2), ("+" if sgn > 0 else "-") + "xyz"[axis], k, STEEL, "Log")

    # rider sits on top of the log (on root, so it stays upright while the log rolls)
    a.meta = {"seat": (0, CY + R + 0.3, 0), "neck_loop": {"center": (0, CY, 0), "radius": R + 0.4}}
    a.animations = animations
    return a


def animations():
    """Only the Log bone moves (negative X = rolling forward, the front going down).
    idle: a lazy rock. walk: rocks forward and back, about to roll. gallop: full forward
    rolls, one per loop (it ends where it started, so the loop wraps without a jump)."""
    rock = lambda L, keys: (L, {"Log": [A.rot_x(A.at(L, keys), "catmullrom")]})  # noqa: E731
    gallop = 0.5
    return {
        "idle": rock(2.4, [(0, 0), (0.25, -4), (0.5, 0), (0.75, 3), (1, 0)]),
        "walk": rock(1.0, [(0, 0), (0.25, -32), (0.5, 0), (0.75, 22), (1, 0)]),
        "gallop": (gallop, {"Log": [A.rot_x([(gallop * i / 4, -90 * i) for i in range(5)])]}),
    }


CAM = dict(eye=(-17, 10, -20), target=(0, 2.6, 0), W=640, H=520, fov=34)


def main(out=os.path.join(A.ROOT, "designs", "woodland"), shots="/mnt/project-files/world2/woodland/renders"):
    os.makedirs(out, exist_ok=True)
    os.makedirs(shots, exist_ok=True)
    a = rolling_log()
    m = A.build_animal(a, out)
    print(f"{a.name}: {len(a.parts)} parts")
    shot = render(pose(m, None, 0), transparent=True, **CAM)
    bg = Image.new("RGBA", shot.size, (240, 240, 236, 255))
    Image.alpha_composite(bg, shot).convert("RGB").save(os.path.join(shots, "RollingLog.png"))
    horse = json.load(open(os.path.join(A.ROOT, "designs", "animals", "Horse.bbmodel")))
    side = dict(CAM, W=420, H=420)
    im = Image.new("RGB", (840, 420))
    im.paste(render(pose(horse, None, 0), **side), (0, 0))
    im.paste(render(pose(m, None, 0), **side), (420, 0))
    A.label(im, ["Horse (for size)", "Rolling Log · Rare"]).save(os.path.join(shots, "RollingLog_vs_horse.png"))
    frames = []
    for name, n in (("idle", 16), ("walk", 20), ("gallop", 16)):
        anim = A.anim_named(m, name)
        for k in range(n):
            frames.append(A.label(render(pose(m, anim, k / n * anim["length"]), **side), [name]))
    A.gif(os.path.join(shots, "RollingLog_anims.gif"), frames, fps=16)
    import bbmodel_to_luau
    bbmodel_to_luau.main(os.path.join("designs", "woodland", "RollingLog.bbmodel"),
                         os.path.join(A.ROOT, "src", "shared", "Animals", "RollingLogModel.luau"))


if __name__ == "__main__":
    main(*sys.argv[1:])
