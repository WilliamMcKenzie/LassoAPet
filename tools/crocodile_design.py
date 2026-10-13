"""Crocodile: World 2 Meadow animal (QM, Oct 13), in our block style after QM's reference
(a low Minecraft-style croc with a long snout, splayed legs and a long tail). Green with a
pale yellow belly, a long snout held open (pink inside, pyramid teeth up and down its jaws like the dinos'), eye
bumps on top of the head with Horse googly eyes on their outsides, a row of dark scutes
down each side of the back, short legs out at the corners and a tapering three-block tail
with ridges.

Same bones and rules as every quadruped (root, neck, EarL, EarR, Tail, Leg*; its ears are
the eye bumps); walk is QM's horse walk, the gallop the shared leap.

    python3 tools/crocodile_design.py

writes designs/world2/Crocodile.bbmodel and renders to /mnt/project-files/animals/crocodile/.
"""

import json
import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import animal_designs as A  # noqa: E402
from animal_designs import Animal, quad_animations  # noqa: E402
from partlib import Part, T, Rx, render  # noqa: E402
import numpy as np
from horse_rig import pose  # noqa: E402

GREEN = (88, 158, 64)
DARK = (54, 112, 44)
BELLY = (214, 222, 140)
TOOTH = (252, 250, 240)
NOSTRIL = (40, 70, 34)
MOUTH = (236, 120, 140)
OPEN = 22  # degrees the upper jaw is held open


def crocodile():
    a = Animal("Crocodile", "Rare")
    x, y0, y1, z0, z1 = 1.8, 0.9, 2.9, -3.5, 3.5
    a.dims = dict(x=x, y0=y0, y1=y1, z0=z0, z1=z1)
    a.pivots["root"] = (0, (y0 + y1) / 2, 0)
    a.box("Belly", (-x, y0, z0), (x, 1.3, z1), BELLY, "root")
    a.box("Body", (-x, 1.3, z0), (x, y1, z1), GREEN, "root")
    # scutes: a row of dark plates down each side of the back
    for side, sx in (("L", -1), ("R", 1)):
        xa, xb = sorted((sx * 0.5, sx * 1.2))
        for i, z in enumerate((-2.6, -1.0, 0.6, 2.2)):
            a.box(f"Scute{side}{i + 1}", (xa, y1, z), (xb, y1 + 0.35, z + 0.8), DARK, "root")

    # short legs out at the corners, darker feet
    for leg in A.LEGS:
        sx = -1 if leg[1] == "L" else 1
        front = leg[0] == "F"
        xa, xb = sorted((sx * 1.6, sx * 2.5))
        za, zb = (-3.2, -2.2) if front else (2.2, 3.2)
        name = "Leg" + leg
        a.box(name, (xa, 0.35, za), (xb, 1.9, zb), GREEN, name)
        fa, fb = sorted((sx * 1.6, sx * 2.8))
        a.box("Hoof" + leg, (fa, 0, za - 0.2), (fb, 0.35, zb), DARK, name)
        a.pivots[name] = ((xa + xb) / 2, 1.875, zb - 0.05 if front else za + 0.05)

    # head: skull, then the jaws held open (as crocs rest): a flat lower jaw with a pink
    # tongue, and the upper snout tipped up OPEN degrees about its hinge at the skull's
    # front, pink underneath, nostril bumps on top. Pyramid teeth like the dinos': up off
    # the lower jaw's edges, down off the upper's.
    a.box("Head", (-1.4, 1.0, -5.5), (1.4, 2.7, -3.499), GREEN, "neck")
    a.box("Jaw", (-1.0, 0.9, -9.0), (1.0, 1.4, -5.5), GREEN, "neck")
    a.box("Tongue", (-0.7, 1.4, -8.6), (0.7, 1.5, -5.5), MOUTH, "neck")
    hinge = np.array((0, 1.5, -5.5))
    R = Rx(OPEN)

    def up(pt):
        return hinge + R[:3, :3] @ (np.array(pt, float) - hinge)

    def turned(name, lo, hi, color):
        lo, hi = np.array(lo, float), np.array(hi, float)
        p = Part(name, hi - lo, T(*hinge) @ R @ T(*((lo + hi) / 2 - hinge)), color)
        p.bone = "neck"
        a.parts.append(p)

    def pyr(name, base, apex, color):
        c = [up(v) for v in base]
        tip = up(apex)
        p = Part(name, (1, 1, 1), np.eye(4), color, "Poly")
        p.polys = [np.array(c)] + [np.array([c[i], c[(i + 1) % 4], tip]) for i in range(4)]
        p.bone = "neck"
        a.parts.append(p)

    turned("Snout", (-1.0, 1.6, -9.0), (1.0, 2.2, -5.5), GREEN)
    turned("Roof", (-0.8, 1.5, -8.8), (0.8, 1.6, -5.5), MOUTH)
    for side, sx in (("L", -1), ("R", 1)):
        xa, xb = sorted((sx * 0.25, sx * 0.75))
        turned("Nostril" + side, (xa, 2.2, -8.8), (xb, 2.45, -8.2), NOSTRIL)
        for i, z in enumerate((-8.5, -7.6, -6.7, -5.8)):
            ta, tb = sorted((sx * 0.65, sx * 0.95))
            low = [(ta, 1.4, z), (tb, 1.4, z), (tb, 1.4, z + 0.3), (ta, 1.4, z + 0.3)]
            apex = ((ta + tb) / 2, 1.4 + 0.45, z + 0.15)
            c = [np.array(v, float) for v in low]
            p = Part(f"Tooth{side}{i + 1}", (1, 1, 1), np.eye(4), TOOTH, "Poly")
            p.polys = [np.array(c)] + [np.array([c[k], c[(k + 1) % 4], np.array(apex)]) for k in range(4)]
            p.bone = "neck"
            a.parts.append(p)
            zu = z + 0.45
            pyr(f"Fang{side}{i + 1}", [(ta, 1.6, zu), (tb, 1.6, zu), (tb, 1.6, zu + 0.3), (ta, 1.6, zu + 0.3)],
                ((ta + tb) / 2, 1.15, zu + 0.15), TOOTH)
    a.pivots["neck"] = (0, 2.7, -3.5)

    # eye bumps on top of the skull (the ear bones), googly eyes on their outsides
    for side, sx in (("L", -1), ("R", 1)):
        bone = "Ear" + side
        xa, xb = sorted((sx * 0.4, sx * 1.3))
        a.box(bone, (xa, 2.7, -5.3), (xb, 3.4, -4.1), GREEN, bone)
        a.pivots[bone] = ((xa + xb) / 2, 2.7, -5.3)
    a.eyes(1.3, 2.75, 3.35, -5.2, -4.2)
    for p in a.parts:
        if p.name in ("EyeL", "PupilL"):
            p.bone = "EarL"
        elif p.name in ("EyeR", "PupilR"):
            p.bone = "EarR"

    # tail: three narrowing blocks with a ridge on each of the first two
    for i, (w, top, za, zb) in enumerate(((1.3, 2.6, 3.5, 6.0), (0.85, 2.1, 6.0, 8.5), (0.45, 1.6, 8.5, 10.5))):
        name = "Tail" if i == 0 else f"Tail{i + 1}"
        a.box(name, (-w, 0.9, za), (w, top, zb), GREEN, "Tail")
        if i < 2:
            a.box(f"TailRidge{i + 1}", (-0.3, top, za + 0.4), (0.3, top + 0.3, zb - 0.6), DARK, "Tail")
    a.pivots["Tail"] = (0, 2.6, 3.5)

    a.meta = {"seat": (0, 3.6, 0.2), "neck_loop": {"center": (0, 1.9, -6.2), "radius": 1.5}}
    a.animations = quad_animations
    return a


CAM = dict(eye=(-16, 10, -18), target=(0, 1.8, -0.5), W=420, H=420, fov=38)
SIDE = dict(eye=(-26, 3, 0.5), target=(0, 1.8, 0.5), W=420, H=420, fov=38)
FRONT = dict(eye=(-4, 6, -20), target=(0, 1.8, -2), W=420, H=420, fov=34)


def main(out=os.path.join(A.ROOT, "designs", "world2"), shots="/mnt/project-files/animals/crocodile"):
    os.makedirs(out, exist_ok=True)
    os.makedirs(shots, exist_ok=True)
    a = crocodile()
    m = A.build_animal(a, out)
    print(f"{a.name}: {len(a.parts)} parts")
    horse = json.load(open(os.path.join(A.ROOT, "designs", "animals", "Horse.bbmodel")))
    tiles = [render(pose(horse, None, 0), **CAM), render(pose(m, None, 0), **CAM),
             render(pose(m, None, 0), **FRONT), render(pose(m, None, 0), **SIDE)]
    im = Image.new("RGB", (420 * len(tiles), 420))
    for i, t in enumerate(tiles):
        im.paste(t, (420 * i, 0))
    A.label(im, ["Horse (for size)", "Crocodile", "Front", "Side"]).save(os.path.join(shots, "Crocodile.png"))
    frames = []
    for name, n in (("walk", 20), ("gallop", 16)):
        anim = A.anim_named(m, name)
        for k in range(n):
            frames.append(A.label(render(pose(m, anim, k / n * anim["length"]), **SIDE), [name]))
    A.gif(os.path.join(shots, "Crocodile_anims.gif"), frames, fps=20)
    json.dump(m, open(os.path.join(shots, "Crocodile.bbmodel"), "w"), separators=(",", ":"))


if __name__ == "__main__":
    main(*sys.argv[1:])
