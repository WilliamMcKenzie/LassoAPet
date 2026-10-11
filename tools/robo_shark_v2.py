"""Robo Shark revamp (QM Oct 11): after QM's reference picture, a toy submarine shark: a
segmented hull, blue on top and white underneath, joined by black bellows, round
portholes down its sides, a brass collar behind a shark head with an open red mouth
full of teeth and a glowing porthole eye, a light blue dorsal fin on a brass post,
a propeller and split tail fin at the back, and two jet pods for pectoral fins.
Static draft, no animations.

Run: python3 tools/robo_shark_v2.py [out_dir]
writes RoboShark_v2.bbmodel, RoboShark_v2.png (three views) and RoboShark_v2_vs_old.png.

Built in Blockbench units (k = 0.1 stud) at about the old model's size, with its bones:
root -> neck -> Jaw; root -> FinL / FinR (the jets); root -> Tail -> TailFin -> Prop.
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
OUT = "/mnt/project-files/animals/robo_shark"

BLUE = (54, 132, 222)
BLUE_LIGHT = (140, 196, 246)  # dorsal and tail fins, jet bands
WHITE = (226, 230, 238)
STEEL = (160, 168, 184)  # porthole rims, struts
BLACK = (40, 42, 52)  # bellows, nozzles
BRASS = (196, 152, 92)
RED = (214, 52, 52)  # inside the mouth
TOOTH = (250, 250, 248)
GLASS = (44, 72, 120)
GLOW = (110, 220, 255)  # eye and jet flames


def XL(sx, a0, a1):
    return list(X(sx, a0, a1))


def hull(a, name, hw, y0, y1, z0, z1, ports=True):
    """A hull segment: white below, blue on top, a porthole on each side."""
    ym = y0 + (y1 - y0) * 0.55
    a.b(name, (-hw, y0, z0), (hw, ym, z1), WHITE, "root")
    a.b(name + "Top", (-hw, ym, z0), (hw, y1, z1), BLUE, "root")
    if not ports:
        return
    zc, yc, r = (z0 + z1) / 2, ym, min(2.4, (z1 - z0) / 2 - 0.6)
    for side, sx in SIDES:
        a.b(f"Port{name}{side}", XL(sx, hw, hw + 0.6)[:1] + [yc - r, zc - r], XL(sx, hw, hw + 0.6)[1:] + [yc + r, zc + r], STEEL, "root")
        g = r * 0.55
        a.b(f"Glass{name}{side}", XL(sx, hw + 0.6, hw + 0.9)[:1] + [yc - g, zc - g], XL(sx, hw + 0.6, hw + 0.9)[1:] + [yc + g, zc + g], GLASS, "root")


def bellows(a, name, hw, y0, y1, z0, z1):
    """Black rubber joint: two ridges with a groove between."""
    d = (z1 - z0) / 3
    a.b(name + "A", (-hw, y0, z0), (hw, y1, z0 + d), BLACK, "root")
    a.b(name + "B", (-hw + 0.5, y0 + 0.5, z0 + d), (hw - 0.5, y1 - 0.5, z1 - d), BLACK, "root")
    a.b(name + "C", (-hw, y0, z1 - d), (hw, y1, z1), BLACK, "root")


def robo_shark():
    a = Conv("RoboShark", "Legendary", 0.1)
    a.pivots["root"] = np.array((0, 12, 0)) * a.k
    # the hull, front to back, narrowing toward the tail
    a.b("Collar", (-7.4, 3.6, -11), (7.4, 20.4, -10), BRASS, "root")
    a.b("Neck", (-6, 5, -12), (6, 19, -11), BLACK, "root")
    hull(a, "Hull1", 7, 4, 20, -10, -1)
    bellows(a, "Bellows1", 6.6, 4.4, 19.6, -1, 2)
    hull(a, "Hull2", 6, 5, 18.5, 2, 9)
    bellows(a, "Bellows2", 5.4, 5.6, 17.6, 9, 11)
    hull(a, "Hull3", 4.6, 6.4, 16.4, 11, 17)
    # dorsal fin on a brass post, leaning back
    a.b("FinPost", (-1, 20, -5), (1, 23, -2), BRASS, "root")
    a.b("Dorsal", (-0.8, 23, -8), (0.8, 27, 0), BLUE_LIGHT, "root")
    a.b("Dorsal2", (-0.8, 27, -5), (0.8, 30, 2), BLUE_LIGHT, "root")
    # head: flat blue top, white sides, an open red mouth with teeth, a porthole eye
    head = a.bone("neck", "root", (0, 10.5, -12))
    a.b("Head", (-6.6, 11, -24), (6.6, 15.5, -12), WHITE, head)
    a.b("HeadTop", (-6.6, 15.5, -24), (6.6, 19.6, -12), BLUE, head)
    a.b("Snout", (-5.2, 12.4, -29), (5.2, 15.5, -24), WHITE, head)
    a.b("SnoutTop", (-5.2, 15.5, -29), (5.2, 18.2, -24), BLUE, head)
    a.b("Mouth", (-5.6, 9.2, -26), (5.6, 11, -13), RED, head)
    for side, sx in SIDES:
        a.b("EyeRim" + side, XL(sx, 6.6, 7.2)[:1] + [14.2, -21], XL(sx, 6.6, 7.2)[1:] + [18.2, -17], STEEL, head)
        a.b("GlowEye" + side, XL(sx, 7.2, 7.5)[:1] + [15.2, -20], XL(sx, 7.2, 7.5)[1:] + [17.2, -18], GLOW, head)
        a.b("Grin" + side, XL(sx, 6.6, 6.9)[:1] + [11.6, -24], XL(sx, 6.6, 6.9)[1:] + [12.6, -16], RED, head)
    # top teeth along the upper lip, pointing down
    for i, z in enumerate((-27.6, -24.5, -21.5, -18.5, -15.5)):
        for side, sx in SIDES:
            x = sx * (4.4 if i == 0 else 5.4)
            a.pyr(f"Tooth{side}{i}", (x - 0.9, 12.4 if i == 0 else 11, z - 0.9), (x + 0.9, 12.4 if i == 0 else 11, z + 0.9), "-y", 2.2, TOOTH, head)
    a.pyr("ToothFront", (-0.9, 12.4, -28.6), (0.9, 12.4, -26.8), "-y", 2.4, TOOTH, head)
    # the lower jaw, hinged at the back of the mouth, teeth pointing up
    jaw = a.bone("Jaw", head, (0, 9.2, -13))
    a.b("Jaw", (-5.6, 5, -27), (5.6, 9.2, -13), WHITE, jaw)
    for i, z in enumerate((-25.5, -22.5, -19.5, -16.5)):
        for side, sx in SIDES:
            x = sx * 4.6
            a.pyr(f"ToothLow{side}{i}", (x - 0.8, 9.2, z - 0.8), (x + 0.8, 9.2, z + 0.8), "+y", 1.8, TOOTH, jaw)
    # jet pods for pectoral fins: a strut out to a white pod with a blue band, a black
    # nozzle at the back with a glowing flame
    for side, sx in SIDES:
        fin = a.bone("Fin" + side, "root", (sx * 7, 7, -3))
        a.b("Strut" + side, XL(sx, 6, 9)[:1] + [6, -4], XL(sx, 6, 9)[1:] + [8, 0], STEEL, fin)
        a.b("Jet" + side, XL(sx, 9, 15)[:1] + [3, -9], XL(sx, 9, 15)[1:] + [9, 5], WHITE, fin)
        a.b("JetNose" + side, XL(sx, 9.8, 14.2)[:1] + [3.8, -11], XL(sx, 9.8, 14.2)[1:] + [8.2, -9], WHITE, fin)
        a.b("JetBand" + side, XL(sx, 8.8, 15.2)[:1] + [2.8, 1], XL(sx, 8.8, 15.2)[1:] + [9.2, 3.5], BLUE, fin)
        a.b("Nozzle" + side, XL(sx, 9.6, 14.4)[:1] + [3.6, 5], XL(sx, 9.6, 14.4)[1:] + [8.4, 6.5], BLACK, fin)
        a.b("GlowJet" + side, XL(sx, 10.6, 13.4)[:1] + [4.6, 6.5], XL(sx, 10.6, 13.4)[1:] + [7.4, 7.5], GLOW, fin)
    # tail: a cone out the back, a split blue fin, a brass propeller on the end
    tail = a.bone("Tail", "root", (0, 11.4, 17))
    a.b("TailCone", (-3.4, 8, 17), (3.4, 14.8, 22), WHITE, tail)
    a.b("TailConeTop", (-3.4, 11.8, 17), (3.4, 14.8, 22), BLUE, tail)
    tailfin = a.bone("TailFin", tail, (0, 11.4, 22))
    a.b("TailFin", (-0.8, 3, 22), (0.8, 21, 25), BLUE_LIGHT, tailfin)
    a.b("TailHub", (-2, 9.4, 22), (2, 13.4, 25), BLACK, tailfin)
    prop = a.bone("Prop", tailfin, (0, 11.4, 25))
    a.b("PropHub", (-1.2, 10.2, 25), (1.2, 12.6, 27.5), BRASS, prop)
    a.b("PropBladeL", (-5, 10.8, 26), (-1.2, 12, 27), BRASS, prop)
    a.b("PropBladeR", (1.2, 10.8, 26), (5, 12, 27), BRASS, prop)
    a.b("PropBladeUp", (-0.6, 12.6, 26), (0.6, 16.4, 27), BRASS, prop)
    a.b("PropBladeDown", (-0.6, 6.4, 26), (0.6, 10.2, 27), BRASS, prop)
    a.pyr("PropCap", (-1.2, 10.2, 27.5), (1.2, 12.6, 27.5), "+z", 1.4, BRASS, prop)
    a.meta = {"seat": (0, 2.05, 0.5), "neck_loop": {"center": (0, 1.5, -1.8), "radius": 0.9}}
    return a


def main(out=OUT):
    os.makedirs(out, exist_ok=True)
    a, model, parts = C.build(robo_shark)
    model["meta"]["format_version"] = "5.0"
    path = os.path.join(out, "RoboShark_v2.bbmodel")
    with open(path, "w") as f:
        json.dump(model, f, separators=(",", ":"))
    for p in parts:
        if p.name.startswith("Glow"):
            p.neon = True
    lo, hi = C.bounds(parts)
    c = (lo + hi) / 2
    r = np.linalg.norm(hi - lo) / 2
    T = 480
    sheet = Image.new("RGB", (T * 3, T))
    for i, v in enumerate(((-19, 10, -21), (-30, 3, 0), (19, 12, 21))):
        v = np.array(v, float)
        eye = c + v / np.linalg.norm(v) * r / np.tan(np.radians(17)) * 1.05
        sheet.paste(render(parts, eye=eye, target=c, W=T, H=T, fov=34), (i * T, 0))
    A.label(sheet, ["Robo Shark (new)", "side", "back"], 22).save(os.path.join(out, "RoboShark_v2.png"))
    # beside the old one, same camera
    import horse_rig
    horse_rig.EULER = "ZYX"
    old = json.load(open(os.path.join(ROOT, "designs", "ocean", "RoboShark.bbmodel")))
    cam = dict(eye=(-6.5, 3.2, -6.5), target=(0, 1.1, 0), W=T, H=T, fov=40)
    pair = Image.new("RGB", (T * 2, T))
    from robo_shark_rig import posed
    pair.paste(render(posed(old), **cam), (0, 0))
    pair.paste(render(parts, **cam), (T, 0))
    A.label(pair, ["Robo Shark now", "new"], 22).save(os.path.join(out, "RoboShark_v2_vs_old.png"))
    print("wrote", path, len(parts), "parts")


if __name__ == "__main__":
    main(*sys.argv[1:])
