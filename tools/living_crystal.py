"""Living Crystal: World 2's Crystal Cavern take on the Cactus (QM, Oct 13). A single
crystal guy, a tall shaft with a pyramid tip like the cavern props, running on the
Cactus's legs with its bent arms and its face (two dark eyes and a tall mouth). Two
colours: blue (cyan #00BEE7) and pink (#E583FB).

Run: python3 tools/living_crystal.py [out_dir]

Same bones, pivots and animations as the Cactus (designs/desert/Cactus.bbmodel): root,
neck (the tip), ArmL, ArmR, LegFL, LegFR. Units are Blockbench's (0.1 stud), the
Cactus's size.
"""

import copy
import json
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import snake_design as S  # noqa: E402
from partlib import render  # noqa: E402
import animal_designs as A  # noqa: E402

S.SIZE = 1.0
ROOT = os.path.join(os.path.dirname(__file__), "..")
CACTUS = os.path.join(ROOT, "designs", "desert", "Cactus.bbmodel")
FACE = (54, 34, 24)  # the Cactus's eyes and mouth

# name: (main, lighter facet, darker legs)
KINDS = {"BlueCrystal": ((0x00, 0xBE, 0xE7), (90, 220, 245), (0, 150, 190)),
         "PinkCrystal": ((0xE5, 0x83, 0xFB), (242, 170, 253), (190, 100, 214))}


def box(name, lo, hi, tex):
    """A cube from Blockbench-unit corners."""
    lo, hi = np.array(lo, float) / 10, np.array(hi, float) / 10
    return S.cube(name, (lo + hi) / 2, hi - lo, tex)


def pyramid(name, base_y, hw, hd, h, tex):
    """A pyramid on the plane base_y (Blockbench units), hw x hd half-sizes, apex h above."""
    v = {"b0": [-hw, 0, -hd], "b1": [hw, 0, -hd], "b2": [hw, 0, hd], "b3": [-hw, 0, hd], "t": [0, h, 0]}
    faces = {"base": ["b0", "b1", "b2", "b3"], "s0": ["b0", "b1", "t"], "s1": ["b1", "b2", "t"],
             "s2": ["b2", "b3", "t"], "s3": ["b3", "b0", "t"]}
    return {"name": name, "type": "mesh", "uuid": S.uid(), "color": 0, "origin": [0, base_y, 0], "rotation": [0, 0, 0],
            "vertices": v, "faces": {k: {"texture": tex, "vertices": vs, "uv": {q: [0, 0] for q in vs}} for k, vs in faces.items()}}


def build(name):
    main, light, dark = KINDS[name]
    colors = {"main": main, "light": light, "dark": dark, "face": FACE}
    T = {n: i for i, n in enumerate(colors)}
    cactus = json.load(open(CACTUS))
    groups = {g["name"]: g for g in cactus["groups"]}
    elements, new_groups = [], []

    def add_group(gname, parent):
        g = S.group(gname, (0, 0, 0))
        g["origin"] = list(groups[gname]["origin"])
        new_groups.append(g)
        node = {"uuid": g["uuid"], "isOpen": True, "children": []}
        if parent is not None:
            parent["children"].append(node)
        return node

    def put(node, parts):
        for e in parts:
            elements.append(e)
            node["children"].append(e["uuid"])

    root = add_group("root", None)
    # the shaft: the Cactus's body, with a lighter facet down the front-left edge for sparkle
    put(root, [box("Body", (-16, 32, -13), (16, 110, 13), T["main"]),
               box("Facet", (-17, 36, -14), (-9, 106, -12), T["light"]),
               box("EyeL", (-8, 92, -13.5), (-2.5, 99, -13), T["face"]),
               box("EyeR", (2.5, 92, -13.5), (8, 99, -13), T["face"]),
               box("Mouth", (-2.5, 76, -14.2), (2.5, 88, -13), T["face"])])
    neck = add_group("neck", root)
    put(neck, [pyramid("Tip", 110, 16, 13, 34, T["main"])])
    for s in ("L", "R"):
        arm = add_group("Arm" + s, root)
        src = [e for e in cactus["elements"] if e["name"] in ("Arm" + s, "Forearm" + s)]
        put(arm, [box(e["name"], e["from"], e["to"], T["main"]) for e in src])
        leg = add_group("LegF" + s, root)
        e = next(e for e in cactus["elements"] if e["name"] == "Leg" + s)
        put(leg, [box("Leg" + s, e["from"], e["to"], T["dark"])])

    # the Cactus's animations, re-keyed to these bones by name
    by_name = {g["name"]: g["uuid"] for g in new_groups}
    old = {g["uuid"]: g["name"] for g in cactus["groups"]}
    anims = []
    for a in copy.deepcopy(cactus.get("animations", [])):
        a["animators"] = {by_name[old[u]]: v for u, v in a["animators"].items() if old.get(u) in by_name}
        anims.append(a)

    model = json.load(open(os.path.join(ROOT, "designs", "desert", "Snake.bbmodel")))
    model.update(name=name, elements=elements, groups=new_groups, outliner=[root], animations=anims,
                 textures=[S.solid_texture(n, c) for n, c in colors.items()])
    return model


def main(out="/mnt/project-files/animals/living_crystal"):
    os.makedirs(out, exist_ok=True)
    parts = []
    for i, name in enumerate(KINDS):
        model = build(name)
        for path in (os.path.join(ROOT, "designs", "crystal", f"{name}.bbmodel"), os.path.join(out, f"{name}.bbmodel")):
            with open(path, "w") as f:
                json.dump(model, f, separators=(",", ":"))
        ps = S.posed(model)
        for p in ps:
            p.polys = [q + np.array([-4 + 8 * i, 0, 0]) for q in ps and p.polys]
        parts += ps
        print(name, len(model["elements"]), "elements,", len(model["animations"]), "animations")
    cactus = S.posed(json.load(open(CACTUS)))
    for p in cactus:
        p.polys = [q + np.array([-12, 0, 0]) for q in p.polys]
    W, H = 1000, 560
    sheet = Image.new("RGB", (W, H * 2))
    sheet.paste(render(parts + cactus, W=W, H=H, fov=34, eye=(-10, 12, -32), target=(-3, 6, 0)), (0, 0))
    sheet.paste(render(parts + cactus, W=W, H=H, fov=34, eye=(14, 10, 30), target=(-3, 6, 0)), (0, H))
    sheet.save(os.path.join(out, "LivingCrystal.png"))


if __name__ == "__main__":
    main(*sys.argv[1:])
