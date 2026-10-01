"""Refined animals (the animal refinement thread): redraws of in-game animals in the
converted pets' style (tools/convert_designs.py): chunky tiered blocks, real-depth details,
bone rest rotations for the pose, bold colours, and eyes that read against the coat.

Run: python3 tools/refine_designs.py <Name> [out_dir]
writes the model to designs/<biome>/<Name>.bbmodel and a static preview <Name>.png.
Animate after QM approves the look (tools/snow_rig.py for the Penguin).
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
from partlib import Part, render  # noqa: E402

ROOT = os.path.join(os.path.dirname(__file__), "..")
OUT = "/mnt/project-files/animals/refine"


def prism_x(a, name, pts, x0, x1, color, bone):
    """Triangle (z, y) extruded along x: a side-profile wedge, like a beak."""
    k = a.k
    pts = [(z * k, y * k) for z, y in pts]
    x0, x1 = x0 * k, x1 * k
    faces = [[(x0, y, z) for z, y in pts], [(x1, y, z) for z, y in pts[::-1]]]
    for i, j in ((0, 1), (1, 2), (2, 0)):
        (za, ya), (zb, yb) = pts[i], pts[j]
        faces.append([(x0, ya, za), (x1, ya, za), (x1, yb, zb), (x0, yb, zb)])
    p = Part(name, (1, 1, 1), np.eye(4), color, "Poly")
    p.polys = [np.array(f, float) for f in faces]
    p.bone = bone
    a.parts.append(p)
    return p


# ---------------------------------------------------------------- penguin

def penguin():
    """An emperor-style penguin: a pear-shaped black body, a tiered white belly
    warming to gold at the chest, gold cheek patches, eyes on the black head so
    they read, a pointed two-part beak, flippers held out, big orange feet."""
    c = dict(black=(40, 46, 64), white=(250, 250, 250), gold=(255, 200, 60), cheek=(255, 170, 40),
             beak=(255, 140, 30), beak_lo=(230, 100, 30), foot=(255, 150, 30))
    a = Conv("Penguin", "Uncommon", 1.0)
    a.pivots["root"] = (0, 3.6, 0.2)
    # feet: wide orange paddles with three toes poking forward
    for side, sx in SIDES:
        leg = a.bone("Leg" + side, "root", (sx * 1.0, 0.7, -0.4))
        x0, x1 = X(sx, 0.25, 1.85)
        a.b("Foot" + side, (x0, 0, -1.9), (x1, 0.7, 0.4), c["foot"], leg)
        for i, (t0, t1) in enumerate(((0.25, 0.65), (0.85, 1.25), (1.45, 1.85))):
            x0, x1 = X(sx, t0, t1)
            a.b(f"Toe{side}{i}", (x0, 0, -2.5), (x1, 0.45, -1.9), c["foot"], leg)
    # body: wide at the bottom, narrower shoulders
    a.b("Body", (-2.3, 0.7, -1.6), (2.3, 4.5, 2.0), c["black"], "root")
    a.b("Chest", (-1.9, 4.5, -1.4), (1.9, 6.9, 1.7), c["black"], "root")
    # belly: tiers standing proud of the front, gold at the top
    a.b("Belly", (-1.8, 1.0, -2.2), (1.8, 4.5, -1.6), c["white"], "root")
    a.b("Tummy", (-1.4, 1.4, -2.6), (1.4, 3.8, -2.2), c["white"], "root")
    a.b("Bib", (-1.5, 4.5, -2.0), (1.5, 5.8, -1.4), c["white"], "root")
    a.b("BibGold", (-1.5, 5.8, -2.0), (1.5, 6.6, -1.4), c["gold"], "root")
    # tail: a short black wedge out the back
    tail = a.bone("Tail", "root", (0, 1.6, 2.0), (-20, 0, 0))
    prism_x(a, "Tail", [(2.0, 0.9), (2.0, 1.9), (3.1, 0.9)], -0.8, 0.8, c["black"], tail)
    # flippers: held a little out from the shoulders, tapering to the tip
    for side, sx in SIDES:
        wing = a.bone("Wing" + side, "root", (sx * 1.9, 6.4, 0.1), (0, 0, sx * 12))
        x0, x1 = X(sx, 1.9, 2.5)
        a.b("Flipper" + side, (x0, 3.9, -0.9), (x1, 6.5, 1.1), c["black"], wing)
        a.b("FlipperTip" + side, (x0, 2.2, -0.6), (x1, 3.9, 0.8), c["black"], wing)
    # head: black, chin up a touch, gold cheek patches standing out of the sides
    head = a.bone("neck", "root", (0, 6.9, 0), (8, 0, 0))
    a.b("Head", (-1.7, 6.7, -1.8), (1.7, 9.3, 1.4), c["black"], head)
    a.b("Crown", (-1.35, 9.3, -1.5), (1.35, 9.9, 1.1), c["black"], head)
    for side, sx in SIDES:
        x0, x1 = X(sx, 1.7, 1.95)
        a.b("Cheek" + side, (x0, 6.9, -0.7), (x1, 8.1, 0.7), c["cheek"], head)
        # eye: a big white plate, a smaller pupil low and toward the beak
        x0, x1 = X(sx, 0.3, 1.4)
        a.box("Eye" + side, (x0, 7.9, -1.8 - A.PLATE), (x1, 9.15, -1.8), A.EYE_WHITE, head)
        x0, x1 = X(sx, 0.45, 0.95)
        a.box("Pupil" + side, (x0, 8.05, -1.8 - A.PLATE - 0.03), (x1, 8.75, -1.8 - A.PLATE), A.PUPIL, head)
    # beak: a pointed upper wedge over a shorter, darker lower one
    prism_x(a, "Beak", [(-1.8, 7.35), (-1.8, 7.95), (-3.5, 7.35)], -0.55, 0.55, c["beak"], head)
    prism_x(a, "BeakLow", [(-1.8, 7.35), (-1.8, 6.95), (-2.9, 7.35)], -0.45, 0.45, c["beak_lo"], head)
    a.meta = {"seat": (0, 9.9, -0.2), "neck_loop": {"center": (0, 7.9, -0.2), "radius": 2.2}}
    return a


BIOME = {"Penguin": "snow"}
BUILDERS = {"Penguin": penguin}


def preview(name, out, old=None):
    """3/4 front and side views of the new model, beside the old one when given."""
    a, model, parts = C.build(BUILDERS[name])
    path = os.path.join(ROOT, "designs", BIOME[name], name + ".bbmodel")
    with open(path, "w") as f:
        json.dump(model, f, separators=(",", ":"))
    sets = [("new", parts)]
    if old:
        from snow_rig import posed
        op = posed(json.load(open(old)))
        for p in op:
            if p.name.startswith(C.PLAIN):
                p.plain = True
        sets.insert(0, ("old", op))
    W = 320
    ims = []
    lo, hi = C.bounds(parts)
    c = (lo + hi) / 2
    r = np.linalg.norm(hi - lo) / 2
    for label, ps in sets:
        for v in ((-19, 9, -21), (-30, 4, 0)):
            v = np.array(v, float)
            eye = c + v / np.linalg.norm(v) * r / np.tan(np.radians(17)) * 1.05
            ims.append(A.label(render(ps, eye=eye, target=c, W=W, H=W, fov=34), [f"{name} {label}"], 15))
    sheet = Image.new("RGB", (W * len(ims), ims[0].height))
    for i, im in enumerate(ims):
        sheet.paste(im, (i * W, 0))
    os.makedirs(out, exist_ok=True)
    sheet.save(os.path.join(out, name + ".png"))
    print("wrote", path, len(parts), "parts")
    return a


if __name__ == "__main__":
    preview(sys.argv[1], sys.argv[2] if len(sys.argv) > 2 else OUT,
            old=sys.argv[3] if len(sys.argv) > 3 else None)
