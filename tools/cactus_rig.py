"""The Cactus, rigged and animated (QM approved the look of desert_designs.cactus()).

Run: python3 tools/cactus_rig.py [preview_dir]

Writes designs/desert/Cactus.bbmodel and preview GIFs. Same shapes as the draft,
but every detail has real depth (QM: no 2D planes, eye plates are fine), and the
rest pose is straight with axis-aligned blocks: all motion is bone rotation.

Bones: root (body) -> neck (top cap and spines), ArmL, ArmR, LegFL, LegFR.
The legs are named like the horse's front legs so the gallop kicks up dust.
Legs and arms reach into the body, so swinging them never opens a gap.

  idle    a slow bob, arms waving a little, top cap nodding
  walk    stiff little steps, arms pumping opposite the legs, a side-to-side waddle
  gallop  Cactuar's run: leaning forward, big strides with a hop, arms pumping
Angles are degrees (+X swings a hanging leg forward), heights Blockbench units.
"""

import json
import math
import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
from horse_rig import pose, write_animations  # noqa: E402
from partlib import render, write_bbmodel  # noqa: E402
import animal_designs as A  # noqa: E402
from animal_designs import Animal  # noqa: E402

ROOT = os.path.join(os.path.dirname(__file__), "..")
MODEL = os.path.join(ROOT, "designs", "desert", "Cactus.bbmodel")
TAU = 2 * math.pi

GREEN, RIB, SPINE, FACE = (118, 204, 64), (72, 150, 44), (214, 176, 96), (54, 34, 24)
SEAT = (0, 11.7, 0.2)
NECK_LOOP = {"center": (0, 9.5, 0), "radius": 2.2}


def cactus():
    a = Animal("Cactus", "Uncommon")
    a.bone_order = [("root", None), ("neck", "root"), ("ArmL", "root"), ("ArmR", "root"),
                    ("LegFL", "root"), ("LegFR", "root")]
    a.pivots = {"root": (0, 7.0, 0), "neck": (0, 11.0, 0)}
    # two chunky legs, reaching up into the body
    for side, sx in (("L", -1), ("R", 1)):
        xa, xb = sorted((sx * 0.3, sx * 1.35))
        a.box("Leg" + side, (xa, 0, -0.55), (xb, 3.8, 0.55), GREEN, "LegF" + side)
        a.pivots["LegF" + side] = (sx * 0.825, 3.4, 0)
    a.box("Body", (-1.6, 3.2, -1.3), (1.6, 11.0, 1.3), GREEN, "root")
    a.box("Top", (-1.2, 11.0, -0.9), (1.2, 11.6, 0.9), GREEN, "neck")
    # ribs: raised dark ridges down the front, back and sides
    d = 0.15
    for i, x in enumerate((-1.0, 1.0)):
        a.box(f"RibF{i}", (x - 0.12, 3.4, -1.3 - d), (x + 0.12, 10.8, -1.3), RIB, "root")
        a.box(f"RibB{i}", (x - 0.12, 3.4, 1.3), (x + 0.12, 10.8, 1.3 + d), RIB, "root")
    for side, sx in (("L", -1), ("R", 1)):
        xa, xb = sorted((sx * 1.6, sx * (1.6 + d)))
        a.box("RibS" + side, (xa, 3.4, -0.12), (xb, 10.8, 0.12), RIB, "root")
    # face: two dark eye plates and an O mouth with a little depth
    for side, sx in (("L", -1), ("R", 1)):
        xa, xb = sorted((sx * 0.25, sx * 0.8))
        a.box("Eye" + side, (xa, 9.2, -1.3 - A.PLATE), (xb, 9.9, -1.3), FACE, "root")
    a.box("Mouth", (-0.25, 7.6, -1.3 - 0.12), (0.25, 8.8, -1.3), FACE, "root")
    # arms: out to the side, the left bends up, the right bends down
    a.box("ArmL", (-3.4, 7.3, -0.45), (-1.3, 8.2, 0.45), GREEN, "ArmL")
    a.box("ForearmL", (-3.4, 8.2, -0.45), (-2.5, 10.1, 0.45), GREEN, "ArmL")
    a.box("ArmR", (1.3, 6.9, -0.45), (3.4, 7.8, 0.45), GREEN, "ArmR")
    a.box("ForearmR", (2.5, 5.0, -0.45), (3.4, 6.9, 0.45), GREEN, "ArmR")
    a.pivots["ArmL"] = (-1.6, 7.75, 0)
    a.pivots["ArmR"] = (1.6, 7.35, 0)
    # three spines on top
    for i, (x, h) in enumerate(((-0.5, 1.0), (0, 1.35), (0.5, 1.0))):
        a.box(f"Spine{i}", (x - 0.1, 11.6, -0.1), (x + 0.1, 11.6 + h, 0.1), SPINE, "neck")
    a.meta = {"seat": SEAT, "neck_loop": NECK_LOOP}
    return a


def track(L, fn, n, channel="rotation", interp="catmullrom"):
    """fn(u) -> (x, y, z) for u in [0, 1], sampled at n + 1 evenly spaced keys."""
    return {"channel": channel, "interp": interp,
            "keys": [(round(L * i / n, 4), tuple(round(v, 3) for v in fn(i / n))) for i in range(n + 1)]}


def animations():
    s = math.sin
    L = 2.4
    idle = {
        "root": [track(L, lambda u: (0, 1.5 * (1 - math.cos(TAU * u)) / 2, 0), 12, "position")],
        "neck": [track(L, lambda u: (-4 * s(TAU * u), 0, 3 * s(TAU * u * 2)), 12)],
        "ArmL": [track(L, lambda u: (12 * s(TAU * u), 0, -6 * s(TAU * u)), 12)],
        "ArmR": [track(L, lambda u: (-12 * s(TAU * u), 0, 6 * s(TAU * u)), 12)],
    }

    Lw = 0.7
    swing = 28
    walk = {
        "root": [track(Lw, lambda u: (0, 3 * abs(s(TAU * u)), 0), 16, "position"),
                 track(Lw, lambda u: (0, 5 * s(TAU * u), 6 * s(TAU * u)), 16)],
        "LegFL": [track(Lw, lambda u: (swing * s(TAU * u), 0, 0), 16)],
        "LegFR": [track(Lw, lambda u: (-swing * s(TAU * u), 0, 0), 16)],
        "ArmL": [track(Lw, lambda u: (-35 * s(TAU * u), 0, 0), 16)],
        "ArmR": [track(Lw, lambda u: (35 * s(TAU * u), 0, 0), 16)],
        "neck": [track(Lw, lambda u: (0, 0, -4 * s(TAU * u)), 16)],
    }

    # gallop: two strides a loop. The left foot reaches forward at u = 0, lands at
    # u = 0.2 (its rotation back at 0: dust), pushes back to u = 0.6, reaches again.
    Lg = 0.6
    left = [(0, 45), (0.2, 0), (0.6, -45), (1, 45)]
    right = [(u, -v) for u, v in left]

    def keys(pts):
        return {"channel": "rotation", "interp": "linear", "keys": [(round(u * Lg, 4), (v, 0, 0)) for u, v in pts]}

    gallop = {
        "root": [track(Lg, lambda u: (0, 10 * abs(s(TAU * u + 0.9)), 0), 16, "position"),
                 track(Lg, lambda u: (-14 + 3 * s(2 * TAU * u), 4 * s(TAU * u), 5 * s(TAU * u)), 16)],
        "LegFL": [keys(left)],
        "LegFR": [keys(right)],
        "ArmL": [track(Lg, lambda u: (-60 * s(TAU * u + 1.2), 0, -20), 16)],
        "ArmR": [track(Lg, lambda u: (60 * s(TAU * u + 1.2), 0, 20), 16)],
        "neck": [track(Lg, lambda u: (8 * s(2 * TAU * u), 0, 0), 16)],
    }
    return {"idle": (L, idle), "walk": (Lw, walk), "gallop": (Lg, gallop)}


def main(out="/mnt/project-files/animals/desert"):
    a = cactus()
    m, groups = write_bbmodel(a.parts, a.name, None, bones=a.bones())
    write_animations(m, groups, animations())
    for path in (MODEL, os.path.join(out, "Cactus.bbmodel")):
        with open(path, "w") as f:
            json.dump(m, f, separators=(",", ":"))
    cams = [dict(eye=(-22, 16, -24), target=(0, 6, -0.5)), dict(eye=(-32, 7, -1), target=(0, 6, -1)),
            dict(eye=(14, 12, 26), target=(0, 6, 0.5))]
    W, H = 330, 380
    frames = []
    for name, n, loops in (("idle", 48, 1), ("walk", 14, 3), ("gallop", 12, 4)):
        anim = next(x for x in m["animations"] if x["name"] == name)
        for _ in range(loops):
            for i in range(n):
                parts = pose(m, anim, anim["length"] * i / n)
                im = Image.new("RGB", (W * len(cams), H))
                for c, cam in enumerate(cams):
                    im.paste(render(parts, W=W, H=H, fov=40, **cam), (c * W, 0))
                frames.append(A.label(im, [name] * len(cams)))
    A.gif(os.path.join(out, "Cactus_anims.gif"), frames, fps=20)
    rest = Image.new("RGB", (W * len(cams), H))
    for c, cam in enumerate(cams):
        rest.paste(render(pose(m, None, 0), W=W, H=H, fov=40, **cam), (c * W, 0))
    rest.save(os.path.join(out, "Cactus_rest.png"))
    print("wrote", out)


if __name__ == "__main__":
    main(*sys.argv[1:])
