"""The Maw (World 2, Crimson Lands): a wide toothy mouth on three tentacles, no eyes.

Run: python3 tools/crimson_maw.py [out_dir]

Rest pose (every bone at 0): the mouth faces -z, shut, standing on three straight
tentacles. Bones: root (the skull, where you sit on top) -> neck (the lower jaw,
which opens by turning -X at its back hinge) and TentFL/TentFR/TentB, each a chain
of three (A at the body, B, C the purple tip). Teeth are WedgeParts, two per tooth.

  idle    bobbing, tentacles swaying, the jaw opening now and then
  walk    a tripod shuffle: each tentacle steps a third of the loop apart
  gallop  floats up off the ground, tentacles trailing back and rippling, jaw chomping
Kept simple (QM: no ~100-cube builds).
"""

import json
import math
import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import snake_design as S  # noqa: E402
from horse_rig import write_animations  # noqa: E402
from partlib import render  # noqa: E402
from snake_rig import track  # noqa: E402
import animal_designs as A  # noqa: E402

S.SIZE = 1.0
ROOT = os.path.join(os.path.dirname(__file__), "..")
NAME = "Maw"
OUT = "/mnt/project-files/animals/crimson_maw"

COLORS = {"crimson": (170, 22, 48), "purple": (122, 44, 168), "mouth": (64, 8, 24),
          "tongue": (236, 96, 140), "ivory": (250, 244, 226)}
TEX = {n: i for i, n in enumerate(COLORS)}

Y0 = 4.5  # tentacle length: the mouth's underside sits this high
HW = 4.0  # half width of the head
ZF, ZB = -3.2, 2.8  # head front and back
TENTACLES = {"FL": (-2.2, -1.3), "FR": (2.2, -1.3), "B": (0.0, 1.6)}
TENT = [("A", 1.2, "crimson"), ("B", 0.95, "crimson"), ("C", 0.7, "purple")]  # base to tip
TAU = 2 * math.pi


def box(name, lo, hi, tex):
    c = [(a + b) / 2 for a, b in zip(lo, hi)]
    return S.cube(name, c, [b - a for a, b in zip(lo, hi)], tex)


def half_fang(name, x_flat, x_wide, y_base, y_tip, z0, depth, tex):
    """A right-triangle prism (one WedgePart): flat side at x_flat from y_base to y_tip,
    base from x_flat to x_wide at y_base, extruded from z0 back by depth."""
    B = S.BB
    v = {"a": [x_flat, y_base, z0], "b": [x_wide, y_base, z0], "c": [x_flat, y_tip, z0],
         "d": [x_flat, y_base, z0 + depth], "e": [x_wide, y_base, z0 + depth], "f": [x_flat, y_tip, z0 + depth]}
    v = {k: [round(q * B, 4) for q in p] for k, p in v.items()}
    faces = {"front": ["a", "b", "c"], "back": ["d", "f", "e"], "base": ["a", "d", "e", "b"],
             "flat": ["a", "c", "f", "d"], "slope": ["b", "e", "f", "c"]}
    return {"name": name, "type": "mesh", "uuid": S.uid(), "color": 0, "origin": [0, 0, 0], "rotation": [0, 0, 0],
            "vertices": v, "faces": {k: {"texture": tex, "vertices": vs, "uv": {q: [0, 0] for q in vs}} for k, vs in faces.items()}}


def fang(name, x, w, y_base, y_tip, z0, depth=0.5):
    """A pointed tooth from two half fangs back to back."""
    return [half_fang(name + "L", x, x - w / 2, y_base, y_tip, z0, depth, TEX["ivory"]),
            half_fang(name + "R", x, x + w / 2, y_base, y_tip, z0, depth, TEX["ivory"])]


def build():
    elements, groups = [], []

    def add_group(name, pivot, parent):
        g = S.group(name, pivot)
        groups.append(g)
        node = {"uuid": g["uuid"], "isOpen": True, "children": []}
        if parent is not None:
            parent["children"].append(node)
        return node

    def put(node, parts):
        for e in parts:
            elements.append(e)
            node["children"].append(e["uuid"])

    y = Y0
    # skull: the upper jaw, a purple lip round its bottom edge, the dark mouth inside
    root = add_group("root", (0, y + 4, 0), None)
    put(root, [box("Skull", (-HW, y + 4.2, ZF), (HW, y + 6.4, ZB), TEX["crimson"]),
               box("UpperLip", (-HW - 0.1, y + 4.0, ZF - 0.1), (HW + 0.1, y + 4.4, ZB + 0.1), TEX["purple"]),
               box("Mouth", (-HW + 0.3, y + 1.6, ZF + 0.2), (HW - 0.3, y + 4.2, ZB - 0.4), TEX["mouth"])])
    for i, x in enumerate((-3.3, -2.2, -1.1, 0.0, 1.1, 2.2, 3.3)):
        put(root, fang(f"TopFang{i}", x, 1.1, y + 4.0, y + 2.9, ZF - 0.05))

    # lower jaw on the neck bone, hinged at the back
    jaw = add_group("neck", (0, y + 1.6, ZB), root)
    put(jaw, [box("Jaw", (-HW, y, ZF), (HW, y + 1.4, ZB), TEX["crimson"]),
              box("LowerLip", (-HW - 0.1, y + 1.2, ZF - 0.1), (HW + 0.1, y + 1.6, ZB + 0.1), TEX["purple"]),
              box("Tongue", (-1.8, y + 1.6, ZF + 0.8), (1.5, y + 1.9, ZB - 1.0), TEX["tongue"])])
    for i, x in enumerate((-2.75, -1.65, -0.55, 0.55, 1.65, 2.75)):
        put(jaw, fang(f"BottomFang{i}", x, 1.1, y + 1.6, y + 2.6, ZF - 0.05))

    # three tentacles under the jaw, hanging straight down
    for side, (x, z) in TENTACLES.items():
        parent, top = root, y + 0.4
        seg = (y + 0.4) / len(TENT)
        for part, w, col in TENT:
            node = add_group(f"Tent{side}{part}", (x, top, z), parent)
            bottom = max(0.0, top - seg - (0.3 if part != "C" else 0))
            put(node, [box(f"Tent{side}{part}", (x - w / 2, bottom, z - w / 2), (x + w / 2, top, z + w / 2), TEX[col])])
            parent, top = node, top - seg

    model = json.load(open(os.path.join(ROOT, "designs", "desert", "Snake.bbmodel")))
    model.update(name=NAME, elements=elements, groups=groups, outliner=[root], animations=[],
                 textures=[S.solid_texture(n, c) for n, c in COLORS.items()])
    return model


SIDES = {"FL": 0.0, "FR": 1 / 3, "B": 2 / 3}  # tripod phase
ROLL = {"FL": -1, "FR": 1, "B": 0}


def tentacles(L, fn, n=16):
    """fn(u, side, j) -> (x, y, z) degrees for segment j (0 = A) of a tentacle."""
    return {f"Tent{s}{p}": [track(L, lambda u, s=s, j=j: fn(u, s, j), n)]
            for s in TENTACLES for j, (p, _, _) in enumerate(TENT)}


def animations():
    L = 3.0
    idle = {"root": [track(L, lambda u: (0, 0, 0), 4),
                     track(L, lambda u: (0, 2.5 * math.sin(TAU * u * 2), 0), 24, channel="position")],
            "neck": [track(L, lambda u: (-14 * max(0.0, math.sin(TAU * u * 2 - 1)) ** 4, 0, 0), 36)],
            **tentacles(L, lambda u, s, j: (6 * math.sin(TAU * (u + SIDES[s]) - 0.8 * j),
                                            0, (6 + 4 * j) * ROLL[s] * (0.6 + 0.4 * math.sin(TAU * u + j)) if ROLL[s] else 5 * math.sin(TAU * u - j)), 24)}

    Lw = 1.0
    walk = {"root": [track(Lw, lambda u: (3 * math.sin(TAU * u * 3), 0, 0), 18),
                     track(Lw, lambda u: (0, 3 * abs(math.sin(TAU * u * 1.5)), 0), 18, channel="position")],
            "neck": [track(Lw, lambda u: (-4 - 4 * math.sin(TAU * u * 3), 0, 0), 18)],
            **tentacles(Lw, lambda u, s, j: ((26, 14, 10)[j] * math.sin(TAU * (u + SIDES[s]) - 0.9 * j), 0, 0), 18)}

    Lg = 0.8
    gallop = {"root": [track(Lg, lambda u: (-6 + 3 * math.sin(TAU * u), 0, 0), 16),
                       track(Lg, lambda u: (0, 30 + 4 * math.sin(TAU * u), 0), 16, channel="position")],
              "neck": [track(Lg, lambda u: (-8 - 8 * math.sin(TAU * u * 2), 0, 0), 16)],
              **tentacles(Lg, lambda u, s, j: ((-55, -15, -12)[j] + (6, 22, 26)[j] * math.sin(TAU * (u + SIDES[s] / 2) - 1.2 * j),
                                               0, 0), 16)}
    return {"idle": (L, idle), "walk": (Lw, walk), "gallop": (Lg, gallop)}


def main(out=OUT):
    os.makedirs(out, exist_ok=True)
    m = build()
    groups = {g["name"]: g for g in m["groups"]}
    write_animations(m, groups, animations())
    for path in (os.path.join(ROOT, "designs", "crimson", NAME + ".bbmodel"), os.path.join(out, NAME + ".bbmodel")):
        with open(path, "w") as f:
            json.dump(m, f, separators=(",", ":"))
    W, H = 560, 440
    cams = [dict(eye=(-20, 12, -22), target=(0, 5.5, 0)), dict(eye=(-30, 6, 0), target=(0, 5.5, 0)),
            dict(eye=(16, 14, 24), target=(0, 5.5, 0)), dict(eye=(-3, 7, -20), target=(0, 6, 0))]
    sheet = Image.new("RGB", (W * 2, H * 2))
    parts = S.posed(m)
    for i, cam in enumerate(cams):
        sheet.paste(render(parts, W=W, H=H, fov=40, **cam), ((i % 2) * W, (i // 2) * H))
    sheet.save(os.path.join(out, NAME + ".png"))
    frames = []
    for name, n, loops in (("idle", 30, 1), ("walk", 20, 2), ("gallop", 16, 3)):
        anim = next(a for a in m["animations"] if a["name"] == name)
        for _ in range(loops):
            for i in range(n):
                ps = S.posed(m, anim, anim["length"] * i / n)
                im = Image.new("RGB", (W * 2, H))
                for c in range(2):
                    im.paste(render(ps, W=W, H=H, fov=40, **cams[c]), (c * W, 0))
                frames.append(A.label(im, ["run" if name == "gallop" else name] * 2))
    A.gif(os.path.join(out, NAME + "_anims.gif"), frames, fps=20)
    print("wrote", len(m["elements"]), "elements")


if __name__ == "__main__":
    main(*sys.argv[1:])
