"""Living Birch: World 2's Woodland Maze Rare (QM, Oct 13), a walking autumn birch built
on Palm Guy's body plan (tools/palm_guy.py; QM: "more like palm guy"): a stout trunk of
four stacked blocks narrowing upward, the Cactus's arms (left bent up, right bent down)
with a leaf tuft on each hand, two stubby legs, and (QM: birch foliage, not the palm's
fronds) a chunky round canopy of leaf blocks like the prop birches'. Birch colours from the woodland's prop birches (tools/world2_prop_assets.luau):
white bark with dark birch marks, autumn leaves in orange, red-orange, amber and yellow.
The face is Palm Guy's (the Cactus's): two dark eyes on the top block over a tall open
mouth on the one below.

Run: python3 tools/living_birch.py [out_dir]
writes designs/woodland/LivingBirch.bbmodel and <out_dir>/LivingBirch.png (3/4 front).

Bones, as Palm Guy's (so his idle, walk and gallop fit), all at rest 0: root, LegL/LegR,
ArmL/ArmR, neck (the crown).
"""

import json
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import convert_designs as C  # noqa: E402
from convert_designs import Conv, SIDES, X  # noqa: E402
from partlib import render  # noqa: E402

OUT = "/mnt/project-files/world2/woodland/renders"
ROOT = os.path.join(os.path.dirname(__file__), "..")

BARK = [(238, 234, 226), (226, 221, 211)]  # the prop birches' trunk, and a touch darker
MARK = (52, 46, 44)  # birch marks
LEAF = [(242, 109, 57), (214, 72, 43), (248, 168, 64), (254, 234, 92)]  # the prop birches' leaves
HEART = (196, 58, 36)
MOUTH = (54, 34, 24)  # the Cactus's eyes and mouth
CROWN_Y = 11.0


def living_birch():
    a = Conv("LivingBirch", "Rare", 1.0)
    a.pivots["root"] = (0, 6.0, 0)

    # ---- two stubby legs
    for side, sx in SIDES:
        leg = a.bone("Leg" + side, "root", (sx * 0.9, 2.4, 0))
        x0, x1 = X(sx, 0.3, 1.5)
        a.b("Leg" + side, (x0, 0.0, -0.6), (x1, 2.6, 0.6), BARK[1], leg)

    # ---- the trunk: four stacked blocks, a little narrower going up, a thin dark birch band
    # at each joint and short dark marks on the faces
    y = 2.2
    for i in range(4):
        h, w = 2.2, 3.6 - 0.2 * i
        a.b(f"Trunk{i}", (-w / 2, y, -w / 2), (w / 2, y + h, w / 2), BARK[i % 2], "root")
        if i:
            r = w / 2 + 0.08
            a.b(f"Band{i}", (-r, y - 0.1, -r), (r, y + 0.1, r), MARK, "root")
        y += h
    r0, r1 = 3.6 / 2 + 0.06, 3.0 / 2 + 0.06
    for i, (x0, x1, yy, z) in enumerate([(0.4, 1.3, 3.2, -r0), (-1.4, -0.5, 4.0, r0), (0.3, 1.2, 5.6, r1)]):
        a.b(f"Mark{i}", (x0, yy, z - 0.06), (x1, yy + 0.3, z + 0.06), MARK, "root")
    for i, (sx, z0, z1, yy) in enumerate([(-1, -0.9, 0.0, 3.5), (1, 0.2, 1.1, 5.0), (-1, 0.1, 0.9, 7.6)]):
        rr = (3.6 - 0.2 * int((yy - 2.2) // 2.2)) / 2 + 0.06
        a.b(f"MarkS{i}", (sx * rr - 0.06, yy, z0), (sx * rr + 0.06, yy + 0.3, z1), MARK, "root")

    # Palm Guy's face: plate eyes on the top block's front, the tall mouth on the one below
    ze, zm = -(3.6 - 0.2 * 3) / 2, -(3.6 - 0.2 * 2) / 2
    for side, sx in SIDES:
        x0, x1 = X(sx, 0.2, 0.75)
        a.b("Eye" + side, (x0, 9.3, ze - 0.08), (x1, 10.1, ze + 0.02), MOUTH, "root")
    a.b("Mouth", (-0.3, 7.2, zm - 0.08), (0.3, 8.6, zm + 0.02), MOUTH, "root")

    # ---- arms like the Cactus's: out to the side then bent, the left up and the right down,
    # an autumn leaf tuft on each hand
    for side, sx, up in (("L", -1, 1), ("R", 1, -1)):
        arm = a.bone("Arm" + side, "root", (sx * 1.6, 6.4, 0))
        x0, x1 = X(sx, 1.5, 3.3)
        a.b("Arm" + side, (x0, 6.0, -0.45), (x1, 6.9, 0.45), BARK[0], arm)
        x0, x1 = X(sx, 2.4, 3.3)
        y0, y1 = (6.9, 8.6) if up > 0 else (4.3, 6.0)
        a.b("Forearm" + side, (x0, y0, -0.45), (x1, y1, 0.45), BARK[0], arm)
        yt = y1 if up > 0 else y0 - 0.9
        a.b("Tuft" + side, (x0 - 0.3, yt, -0.75), (x1 + 0.3, yt + 0.9, 0.75), LEAF[3 if up > 0 else 2], arm)

    # ---- the crown: a chunky round canopy of leaf blocks like the woodland's prop birches,
    # in their autumn colours, a dark red heart underneath
    head = a.bone("neck", "root", (0, CROWN_Y, 0))
    c = CROWN_Y
    for name, lo, hi, col in [
            ("Under", (-1.8, c - 0.3, -1.8), (1.8, c + 0.4, 1.8), HEART),
            ("LeavesLow", (-2.4, c + 0.3, -2.3), (2.4, c + 1.6, 2.3), LEAF[1]),
            ("Leaves", (-3.0, c + 1.4, -2.8), (3.0, c + 3.7, 2.8), LEAF[0]),
            ("LeavesMid", (-2.4, c + 3.5, -2.3), (2.4, c + 4.9, 2.3), LEAF[0]),
            ("LeavesTop", (-1.4, c + 4.8, -1.3), (1.2, c + 5.7, 1.3), LEAF[3]),
            ("ClumpFL", (-3.5, c + 2.3, -3.3), (-1.3, c + 4.3, -1.3), LEAF[3]),
            ("ClumpFR", (1.0, c + 1.0, -3.4), (3.2, c + 2.8, -1.4), LEAF[1]),
            ("ClumpBL", (-3.3, c + 1.0, 1.2), (-1.1, c + 3.0, 3.3), LEAF[2]),
            ("ClumpBR", (1.4, c + 2.5, 1.1), (3.5, c + 4.5, 3.3), LEAF[2]),
            ("ClumpL", (-3.6, c + 3.5, -0.6), (-2.0, c + 4.9, 1.0), LEAF[1]),
            ("ClumpR", (2.0, c + 3.7, -1.2), (3.4, c + 5.0, 0.4), LEAF[3]),
            ("ClumpTop", (0.2, c + 5.4, -0.4), (1.6, c + 6.3, 1.0), LEAF[1]),
            ("ClumpTopB", (-1.6, c + 5.3, 0.2), (-0.4, c + 6.0, 1.4), LEAF[2])]:
        a.b(name, lo, hi, col, head)
    a.meta = {"seat": (0, CROWN_Y + 5.7, 0), "neck_loop": {"center": (0, 9.6, 0), "radius": 2.0}}
    return a


PLAIN = ("Eye", "Mouth", "Mark", "Band")


def main(out=OUT):
    os.makedirs(out, exist_ok=True)
    os.makedirs(os.path.join(ROOT, "designs", "woodland"), exist_ok=True)
    a, model, parts = C.build(living_birch)
    model["meta"]["format_version"] = "5.0"
    with open(os.path.join(ROOT, "designs", "woodland", "LivingBirch.bbmodel"), "w") as f:
        json.dump(model, f, separators=(",", ":"))
    for p in parts:
        if p.name.startswith(PLAIN):
            p.plain = True
    lo, hi = C.bounds(parts)
    print("LivingBirch", len(model["elements"]), "elements; size (studs)", np.round(hi - lo, 1))
    c = (lo + hi) / 2
    r = np.linalg.norm(hi - lo) / 2
    v = np.array((-14, 8, -24), float)
    eye = c + v / np.linalg.norm(v) * r / np.tan(np.radians(15)) * 1.0
    img = render(parts, eye=eye, target=c, W=900, H=900, fov=30, transparent=True)
    bg = Image.new("RGBA", img.size, (238, 240, 244, 255))
    bg.alpha_composite(img)
    bg.convert("RGB").save(os.path.join(out, "LivingBirch.png"))


def animations(m):
    """Palm Guy's (tools/palm_guy.py): the Cactus's bouncy two-legged run, arms pumping, the
    crown bobbing as he bounces; the idle sways like a tree in the breeze with a little wave."""
    import math
    from snake_rig import track
    from snow_rig import bump, grounded
    s, TAU = math.sin, 2 * math.pi
    feet = {"LegL", "LegR"}

    def run(L, swing, arms, lean, roll, hop, n=16):
        tr = {
            "root": [track(L, lambda u: (lean, 4 * s(TAU * u), roll * s(TAU * u)), n)],
            "LegL": [track(L, lambda u: (-lean + swing * s(TAU * u), 0, 0), n)],
            "LegR": [track(L, lambda u: (-lean - swing * s(TAU * u), 0, 0), n)],
            "ArmL": [track(L, lambda u: (-arms * s(TAU * u), 0, 0), n)],
            "ArmR": [track(L, lambda u: (arms * s(TAU * u), 0, 0), n)],
            "neck": [track(L, lambda u: (-lean * 0.5 + 3 * s(2 * TAU * u), 0, -roll * 0.6 * s(TAU * u)), n)],
        }
        tr["root"] = grounded(m, L, tr, feet, n, extra=lambda u: hop * abs(s(TAU * u)))
        return L, tr

    L = 4.0
    out = {"idle": (L, {
        "root": [track(L, lambda u: (0, 0, 3 * s(TAU * u)), 32)],
        "neck": [track(L, lambda u: (2 * s(2 * TAU * u), 6 * s(TAU * u), 4 * s(TAU * u + 0.6)), 32)],
        "ArmL": [track(L, lambda u: (0, 0, 25 * bump(u, 0.65, 0.12) * (0.6 + 0.4 * s(8 * TAU * u))), 64)],
        "ArmR": [track(L, lambda u: (4 * s(TAU * u), 0, 0), 32)],
    })}
    out["walk"] = run(0.6, swing=30, arms=30, lean=0, roll=5, hop=0.6)
    out["gallop"] = run(0.36, swing=50, arms=55, lean=12, roll=4, hop=1.6)
    return out


def animate(out=OUT):
    """Adds idle, walk and gallop to designs/woodland/LivingBirch.bbmodel and writes GIFs."""
    from horse_rig import write_animations
    from snow_rig import group_ids, posed
    import animal_designs as A
    path = os.path.join(ROOT, "designs", "woodland", "LivingBirch.bbmodel")
    m = json.load(open(path))
    m["animations"] = []
    write_animations(m, group_ids(m), animations(m))
    with open(path, "w") as f:
        json.dump(m, f, separators=(",", ":"))
    W = 420
    cams = [dict(eye=(-16, 11, -28), target=(0, 8, 0), W=W, H=W, fov=40), dict(eye=(-32, 9, 0), target=(0, 8, 0), W=W, H=W, fov=40)]

    def frame(name, t):
        anim = next(x for x in m["animations"] if x["name"] == name)
        ps = posed(m, anim, t)
        for p in ps:
            if p.name.startswith(PLAIN):
                p.plain = True
        im = Image.new("RGB", (W * 2, W))
        for i, c in enumerate(cams):
            im.paste(render(ps, **c), (i * W, 0))
        return A.label(im, [name, ""], 22)

    for name, n in (("idle", 32), ("walk", 14), ("gallop", 12)):
        L = next(x for x in m["animations"] if x["name"] == name)["length"]
        A.gif(os.path.join(out, f"LivingBirch_{name}.gif"), [frame(name, L * i / n) for i in range(n)], fps=n / L)
    print("animated", path)


if __name__ == "__main__":
    if sys.argv[1:2] == ["animate"]:
        animate(*sys.argv[2:])
    else:
        main(*sys.argv[1:])
