"""Cactus boss (QM Oct 10): the Desert's boss, based on the Cactus pet but wider,
with a flower on its head and long pointed spikes (square pyramids, like the
Snake's teeth and the Ice Golem's crystals) so it looks lethal.

Run: python3 tools/cactus_boss.py [out_dir]
writes designs/bosses/CactusBoss.bbmodel (rest pose, no animations yet) and
a preview CactusBoss.png.
     python3 tools/cactus_boss.py animate <QM's file> <out file>   its idle, walk and gallop, plus GIFs
Same bones as the Cactus (root, neck, ArmL, ArmR,
LegFL, LegFR) so its rig can be reused.
"""

import json
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import animal_designs as A  # noqa: E402
import convert_designs as C  # noqa: E402
from convert_designs import Conv, SIDES, X  # noqa: E402
from horse_rig import pose  # noqa: E402
from partlib import render  # noqa: E402

ROOT = os.path.join(os.path.dirname(__file__), "..")
OUT = "/mnt/project-files/animals/bosses"

GREEN, RIB, DARK = (104, 190, 56), (64, 136, 40), (40, 30, 26)
SPIKE = (250, 238, 206)
PETAL, PETAL_IN, BUD = (255, 90, 150), (255, 150, 190), (255, 210, 50)
FACE = (54, 34, 24)  # the Cactus's eyes and mouth

W, D = 2.6, 2.1  # body half width and half depth
Y0, Y1 = 2.6, 10.0  # body bottom and top


def spikes_out(a, name, face, pts, size=0.5, length=1.4, bone="root"):
    """Pyramids standing out of one face of the body. face: F (-z), B (+z), L (-x), R (+x);
    pts are (u, y) with u along the face (x for F/B, z for L/R)."""
    h = size / 2
    for i, (u, y) in enumerate(pts):
        if face in "FB":
            z = -D if face == "F" else D
            a.pyr(f"Spike{name}{i}", (u - h, y - h, z), (u + h, y + h, z), "-z" if face == "F" else "+z", length, SPIKE, bone)
        else:
            x = -W if face == "L" else W
            a.pyr(f"Spike{name}{i}", (x, y - h, u - h), (x, y + h, u + h), "-x" if face == "L" else "+x", length, SPIKE, bone)


def cactus_boss():
    a = Conv("CactusBoss", "Legendary", 1.0)
    a.pivots["root"] = (0, 6.0, 0)
    # stubby thick legs
    for side, sx in SIDES:
        leg = a.bone("LegF" + side, "root", (sx * 1.2, Y0 + 0.2, 0))
        x0, x1 = X(sx, 0.35, 2.1)
        a.b("Leg" + side, (x0, 0, -1.2), (x1, Y0, 1.2), GREEN, leg)
    # wide body with raised ribs (real depth) down every face
    a.b("Body", (-W, Y0, -D), (W, Y1, D), GREEN, "root")
    for i, x in enumerate((-1.75, -0.6, 0.6, 1.75)):
        if abs(x) > 1.5:  # the front's middle ribs would cross the face
            a.b(f"RibF{i}", (x - 0.14, Y0 + 0.2, -D - 0.15), (x + 0.14, Y1 - 0.2, -D), RIB, "root")
        a.b(f"RibB{i}", (x - 0.14, Y0 + 0.2, D), (x + 0.14, Y1 - 0.2, D + 0.15), RIB, "root")
    for side, sx in SIDES:
        x0, x1 = X(sx, W, W + 0.15)
        a.b("RibS" + side, (x0, Y0 + 0.2, -0.14), (x1, Y1 - 0.2, 0.14), RIB, "root")
    # head cap and the flower on top (both on the neck)
    head = a.bone("neck", "root", (0, Y1, 0))
    a.b("Top", (-W + 0.5, Y1, -D + 0.4), (W - 0.5, Y1 + 0.6, D - 0.4), GREEN, head)
    fy = Y1 + 0.6
    a.b("Stem", (-0.25, fy, -0.25), (0.25, fy + 0.5, 0.25), RIB, head)
    py = fy + 0.5
    for i, (x0, z0, x1, z1) in enumerate(((-2.3, -0.7, -0.6, 0.7), (0.6, -0.7, 2.3, 0.7), (-0.7, -2.3, 0.7, -0.6), (-0.7, 0.6, 0.7, 2.3))):
        a.b(f"Petal{i}", (x0, py, z0), (x1, py + 0.6, z1), PETAL, head)
    for i, (x0, z0) in enumerate(((-1.5, -1.5), (0.6, -1.5), (-1.5, 0.6), (0.6, 0.6))):
        a.b(f"PetalIn{i}", (x0, py + 0.1, z0), (x0 + 0.9, py + 0.8, z0 + 0.9), PETAL_IN, head)
    a.b("Bud", (-0.6, py, -0.6), (0.6, py + 1.1, 0.6), BUD, head)
    # face: the Cactus's own, scaled to the wider body: two dark eyes and an O mouth
    for side, sx in SIDES:
        x0, x1 = X(sx, 0.4, 1.3)
        a.b("Eye" + side, (x0, 8.2, -D - 0.06), (x1, 9.3, -D), FACE, "root")
    a.b("Mouth", (-0.4, 5.6, -D - 0.12), (0.4, 7.5, -D), FACE, "root")
    # arms raised up like it's about to grab you, spiked
    for side, sx in SIDES:
        arm = a.bone("Arm" + side, "root", (sx * W, 6.8, 0))
        x0, x1 = X(sx, W, W + 2.0)
        a.b("Arm" + side, (x0, 6.2, -0.7), (x1, 7.5, 0.7), GREEN, arm)
        x0, x1 = X(sx, W + 0.7, W + 2.0)
        a.b("Forearm" + side, (x0, 7.5, -0.7), (x1, 10.6, 0.7), GREEN, arm)
        xo = sx * (W + 2.0)
        for i, y in enumerate((8.2, 9.6)):
            a.pyr(f"SpikeArm{side}{i}", (xo, y - 0.25, -0.25), (xo, y + 0.25, 0.25), "-x" if sx < 0 else "+x", 1.1, SPIKE, arm)
        xc = sx * (W + 1.35)
        a.pyr(f"SpikeArmTop{side}", (xc - 0.3, 10.6, -0.3), (xc + 0.3, 10.6, 0.3), "+y", 1.2, SPIKE, arm)
        a.pyr(f"SpikeArmUnder{side}", (xc - 0.25, 6.2, -0.25), (xc + 0.25, 6.2, 0.25), "-y", 0.9, SPIKE, arm)
    # spikes all over the body, between the ribs
    spikes_out(a, "F", "F", [(-2.2, 4.0), (2.2, 4.0), (0, 3.6)], length=1.2)
    spikes_out(a, "B", "B", [(x, y) for x in (-2.2, -1.2, 0.0, 1.2, 2.2) for y in ((3.8, 6.4, 9.0) if x in (-1.2, 1.2) else (5.1, 7.7))], length=1.6)
    for side, f in (("L", "L"), ("R", "R")):
        spikes_out(a, "S" + side, f, [(-1.3, 3.6), (1.3, 4.9), (0.0, 3.4), (-1.3, 9.2), (1.3, 9.0)], length=1.4)
    for i, (x, z) in enumerate(((-2.0, -1.4), (2.0, -1.4), (-2.0, 1.4), (2.0, 1.4))):
        a.pyr(f"SpikeTop{i}", (x - 0.25, Y1, z - 0.25), (x + 0.25, Y1, z + 0.25), "+y", 1.0, SPIKE, "root")
    a.meta = {"seat": (0, Y1 + 0.6, 0), "neck_loop": {"center": (0, 8, 0), "radius": 3.2}}
    return a


def main(out=OUT):
    os.makedirs(out, exist_ok=True)
    a, model, parts = C.build(cactus_boss)
    model["meta"]["format_version"] = "5.0"
    path = os.path.join(ROOT, "designs", "bosses", "CactusBoss.bbmodel")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    for p in (path, os.path.join(out, "CactusBoss.bbmodel")):
        with open(p, "w") as f:
            json.dump(model, f, separators=(",", ":"))
    for p in parts:
        if p.name.startswith(("Eye", "Mouth", "Spike")):
            p.plain = True
    lo, hi = C.bounds(parts)
    c = (lo + hi) / 2
    r = np.linalg.norm(hi - lo) / 2
    T = 420
    ims = []
    for v in ((-19, 9, -21), (-30, 4, 0), (19, 12, 21)):
        v = np.array(v, float)
        eye = c + v / np.linalg.norm(v) * r / np.tan(np.radians(17)) * 1.05
        ims.append(render(parts, eye=eye, target=c, W=T, H=T, fov=34))
    sheet = Image.new("RGB", (T * 3, T))
    for i, im in enumerate(ims):
        sheet.paste(im, (i * T, 0))
    A.label(sheet, ["Cactus boss", "side", "back"], 22).save(os.path.join(out, "CactusBoss.png"))
    # beside the Cactus pet for size
    cactus = json.load(open(os.path.join(ROOT, "designs", "desert", "Cactus.bbmodel")))
    cam = dict(eye=(-22, 12, -26), target=(0, 6, 0), W=T, H=T, fov=36)
    pair = Image.new("RGB", (T * 2, T))
    pair.paste(render(pose(cactus, None, 0), **cam), (0, 0))
    pair.paste(render(parts, **cam), (T, 0))
    A.label(pair, ["Cactus (pet)", "Cactus boss"], 22).save(os.path.join(out, "CactusBoss_vs_pet.png"))
    print("wrote", path, len(parts), "parts")




# ---------------------------------------------------------------- animations (on QM's file)

def animations(m):
    """The boss's loops, on the Cactus pet's bones. A heavy, lumbering version of the
    Cactus's moves: idle breathes and flexes its raised arms, walk stomps, gallop
    leans in and charges with big hops and arms swinging. +X leans forward."""
    import math
    from snake_rig import track
    from snow_rig import grounded
    s, TAU = math.sin, 2 * math.pi
    feet = {"LegL", "LegR"}

    L = 3.0
    idle = {
        "root": [track(L, lambda u: (0, 0, 0), 4), track(L, lambda u: (0, 2 * (1 - math.cos(TAU * u)) / 2, 0), 12, "position")],
        "neck": [track(L, lambda u: (-3 * s(TAU * u), 0, 4 * s(TAU * u)), 12)],
        "ArmL": [track(L, lambda u: (0, 0, -10 * (1 - math.cos(TAU * u)) / 2), 12)],
        "ArmR": [track(L, lambda u: (0, 0, 10 * (1 - math.cos(TAU * u)) / 2), 12)],
    }

    Lw = 0.9
    walk = {
        "root": [track(Lw, lambda u: (4, 0, 7 * s(TAU * u)), 16)],
        "LegFL": [track(Lw, lambda u: (24 * s(TAU * u), 0, 0), 16)],
        "LegFR": [track(Lw, lambda u: (-24 * s(TAU * u), 0, 0), 16)],
        "ArmL": [track(Lw, lambda u: (-25 * s(TAU * u), 0, -8), 16)],
        "ArmR": [track(Lw, lambda u: (25 * s(TAU * u), 0, 8), 16)],
        "neck": [track(Lw, lambda u: (0, 0, -5 * s(TAU * u)), 16)],
    }
    walk["root"] = grounded(m, Lw, walk, feet, 16, extra=lambda u: 2 * abs(s(TAU * u)))

    Lg = 0.6
    gallop = {
        "root": [track(Lg, lambda u: (12 + 3 * s(2 * TAU * u), 5 * s(TAU * u), 6 * s(TAU * u)), 16)],
        "LegFL": [track(Lg, lambda u: (-12 + 45 * s(TAU * u), 0, 0), 16)],
        "LegFR": [track(Lg, lambda u: (-12 - 45 * s(TAU * u), 0, 0), 16)],
        "ArmL": [track(Lg, lambda u: (-50 * s(TAU * u), 0, -25), 16)],
        "ArmR": [track(Lg, lambda u: (50 * s(TAU * u), 0, 25), 16)],
        "neck": [track(Lg, lambda u: (-8 + 6 * s(2 * TAU * u), 0, 0), 16)],
    }
    gallop["root"] = grounded(m, Lg, gallop, feet, 16, extra=lambda u: 8 * abs(s(TAU * u)))
    return {"idle": (L, idle), "walk": (Lw, walk), "gallop": (Lg, gallop)}


def animate(src, dst, out=OUT):
    """Write the loops into QM's file (src) as dst, with preview GIFs."""
    import horse_rig
    horse_rig.EULER = "ZYX"  # QM's hand-made file
    from horse_rig import write_animations
    from snow_rig import group_ids, posed
    m = json.load(open(src))
    write_animations(m, group_ids(m), animations(m))
    with open(dst, "w") as f:
        json.dump(m, f, separators=(",", ":"))
    T = 420
    cams = [dict(eye=(-26, 13, -30), target=(0, 6, 0), W=T, H=T, fov=36), dict(eye=(-38, 7, -1), target=(0, 6, 0), W=T, H=T, fov=34)]

    def frame(name, t):
        anim = next(x for x in m["animations"] if x["name"] == name)
        ps = posed(m, anim, t)
        for p in ps:
            if p.name.startswith(("Eye", "Mouth", "Spike")):
                p.plain = True
        im = Image.new("RGB", (T * 2, T))
        for i, c in enumerate(cams):
            im.paste(render(ps, **c), (i * T, 0))
        return A.label(im, [name, ""], 22)

    for name, n in (("idle", 24), ("walk", 16), ("gallop", 16)):
        L = next(x for x in m["animations"] if x["name"] == name)["length"]
        A.gif(os.path.join(out, f"CactusBoss_{name}.gif"), [frame(name, L * i / n) for i in range(n)], fps=n / L)


if __name__ == "__main__":
    if sys.argv[1:2] == ["animate"]:
        animate(*sys.argv[2:])
    else:
        main(*sys.argv[1:])
