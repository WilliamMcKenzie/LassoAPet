"""Rolling Log: World 2 Woodland Maze's Rare (QM, Oct 13), a living log that rolls.

A fat log lying across the path (its length runs left-right, so it rolls forward),
warm bark with raised darker bark strips, pale cut ends with growth rings, brows
and a big grin on the front of the bark (no eyes: QM, Oct 13),
and a twig of autumn leaves (the Woodland walls' orange) sprouting off the top.

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

BARK = (170, 100, 52)
BARK_DARK = (118, 66, 36)
WOOD = (242, 206, 148)
RING = (206, 148, 88)
CORE = (228, 180, 116)
MOUTH = (70, 34, 26)
LEAF = (0xF2, 0x6D, 0x39)
LEAF_GOLD = (255, 190, 54)

HALF_L = 4.0  # half the log's length (x)
R = 2.5  # log radius
CY = R  # axis height: resting on the ground


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

    # face on the front of the bark: brows and a big grin, no eyes (QM, Oct 13)
    z = -R
    for side, sx in (("L", -1), ("R", 1)):
        ba, bb = sorted((sx * 0.3, sx * 1.7))
        a.box("Brow" + side, (ba, CY + 1.6, z - 0.2), (bb, CY + 1.85, z), BARK_DARK, "Log")
    a.box("Mouth", (-0.9, CY - 0.75, z - A.PLATE), (0.9, CY - 0.4, z), MOUTH, "Log")
    for side, sx in (("L", -1), ("R", 1)):
        ma, mb = sorted((sx * 0.9, sx * 1.25))
        a.box("MouthEnd" + side, (ma, CY - 0.5, z - A.PLATE), (mb, CY - 0.15, z), MOUTH, "Log")

    # a twig off the top towards one end with a tuft of autumn leaves, and a broken stub
    tx, tz = 2.6, 0.3
    a.box("Twig", (tx - 0.25, CY + R, tz - 0.25), (tx + 0.25, CY + R + 1.3, tz + 0.25), BARK_DARK, "Log")
    a.box("TwigSide", (tx + 0.25, CY + R + 0.8, tz - 0.2), (tx + 0.9, CY + R + 1.2, tz + 0.2), BARK_DARK, "Log")
    a.box("Leaf1", (tx - 0.8, CY + R + 1.3, tz - 0.8), (tx + 0.8, CY + R + 2.1, tz + 0.8), LEAF, "Log")
    a.box("Leaf2", (tx - 0.4, CY + R + 2.1, tz - 0.4), (tx + 0.4, CY + R + 2.6, tz + 0.4), LEAF_GOLD, "Log")
    a.box("Leaf3", (tx + 0.9, CY + R + 0.7, tz - 0.45), (tx + 1.7, CY + R + 1.4, tz + 0.45), LEAF_GOLD, "Log")
    a.box("Stub", (-2.6, CY + 0.6, R), (-1.8, CY + 1.4, R + 0.8), BARK_DARK, "Log")
    a.box("StubTop", (-2.45, CY + 0.75, R + 0.8), (-1.95, CY + 1.25, R + 0.85), WOOD, "Log")

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
