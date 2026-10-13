"""Living Birch: World 2's Woodland Maze Rare (QM, Oct 13), a walking autumn birch
like the woodland's prop birches (design/birches): a white trunk with dark birch marks,
a chunky crown of autumn leaves (orange, red-orange and yellow), two branch arms each
holding a little leaf clump, and two stubby root legs with brown root toes. The
standard white plate eyes with dark pupils sit on the front of the trunk over a dark
knot-hole mouth.

Run: python3 tools/living_birch.py [out_dir]

Phase 1 is the model only (no animations yet). Bones (all at 0): root (trunk), neck
(the crown, the lasso loops round it), ArmL/R, LegFL/FR (named like the Cactus's).
Faces -Z. Few parts (QM): about 40.
"""

import json
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import snake_design as S  # noqa: E402
from partlib import render  # noqa: E402

S.SIZE = 1.0
ROOT = os.path.join(os.path.dirname(__file__), "..")
# the prop birches' colours (tools/world2_prop_assets.luau)
COLORS = {"bark": (238, 234, 226), "mark": (52, 46, 44), "root": (0x79, 0x48, 0x2E),
          "orange": (242, 109, 57), "red": (214, 72, 43), "yellow": (254, 234, 92), "amber": (248, 168, 64),
          "white": (255, 255, 255), "pupil": (24, 20, 32)}
T = {n: i for i, n in enumerate(COLORS)}

TW = 2.8  # trunk width (studs)
TRUNK_Y0, TRUNK_Y1 = 2.4, 10.4
CROWN_Y = 10.0  # the crown's bottom


def build():
    elements, groups = [], []

    def add_group(gname, pivot, parent):
        g = S.group(gname, pivot)
        groups.append(g)
        node = {"uuid": g["uuid"], "isOpen": True, "children": []}
        if parent is not None:
            parent["children"].append(node)
        return node

    def put(node, parts):
        for e in parts:
            elements.append(e)
            node["children"].append(e["uuid"])

    h = TW / 2
    root = add_group("root", (0, TRUNK_Y0 + 1, 0), None)
    put(root, [S.cube("Trunk", (0, (TRUNK_Y0 + TRUNK_Y1) / 2, 0), (TW, TRUNK_Y1 - TRUNK_Y0, TW), T["bark"])])
    # birch marks: short dark dashes standing a little proud of the bark, round all four sides
    marks = [("F", -1, 0.7, 3.4, 0.9), ("F", -1, -0.6, 5.6, 0.7), ("B", 1, 0.3, 4.2, 1.0), ("B", 1, -0.5, 7.4, 0.8),
             ("L", -1, -0.4, 3.0, 0.8), ("L", -1, 0.5, 6.4, 1.0), ("R", 1, 0.4, 4.8, 0.9), ("R", 1, -0.3, 8.2, 0.7)]
    for i, (side, sgn, off, y, w) in enumerate(marks):
        if side in "FB":
            put(root, [S.cube(f"Mark{i + 1}", (off, y, sgn * (h + 0.05)), (w, 0.3, 0.1), T["mark"])])
        else:
            put(root, [S.cube(f"Mark{i + 1}", (sgn * (h + 0.05), y, off), (0.1, 0.3, w), T["mark"])])

    # face on the front of the trunk: plate eyes (pupils looking forward, set in from the
    # plate's edge: QM's z-fighting rule) over a dark knot-hole mouth
    for s, sx in (("L", -1), ("R", 1)):
        put(root, [S.cube("Eye" + s, (sx * 0.68, 8.6, -h - 0.025), (1.1, 1.4, 0.05), T["white"]),
                   S.cube("Pupil" + s, (sx * 0.62, 8.4, -h - 0.055), (0.6, 0.75, 0.05), T["pupil"])])
    put(root, [S.cube("Mouth", (0, 7.1, -h - 0.05), (1.5, 0.5, 0.1), T["mark"])])

    # root legs: a white stump, then brown root toes splaying forward and out
    for s, sx in (("L", -1), ("R", 1)):
        leg = add_group("LegF" + s, (sx * 0.75, TRUNK_Y0 + 0.2, 0), root)
        put(leg, [S.cube("LegF" + s, (sx * 0.75, 1.4, 0), (1.2, 2.0, 1.3), T["bark"]),
                  S.cube("Foot" + s, (sx * 0.8, 0.3, -0.2), (1.6, 0.6, 1.9), T["root"]),
                  S.cube("Toe" + s, (sx * 1.35, 0.25, -1.25), (0.6, 0.5, 0.8), T["root"]),
                  S.cube("ToeIn" + s, (sx * 0.35, 0.25, -1.25), (0.6, 0.5, 0.8), T["root"])])

    # branch arms: out from the trunk, then up, each with a leaf clump on the end
    for s, sx in (("L", -1), ("R", 1)):
        arm = add_group("Arm" + s, (sx * h, 6.8, 0), root)
        put(arm, [S.cube("Branch" + s, (sx * (h + 1.6), 6.8, 0), (3.2, 0.7, 0.7), T["bark"]),
                  S.cube("Twig" + s, (sx * (h + 2.9), 7.6, 0), (0.6, 1.2, 0.6), T["bark"]),
                  S.cube("BranchMark" + s, (sx * (h + 1.4), 6.8, -0.4), (0.5, 0.3, 0.1), T["mark"]),
                  S.cube("Clump" + s, (sx * (h + 2.9), 8.7, 0), (1.6, 1.4, 1.6), T["amber" if s == "L" else "yellow"], ry=45)])

    # the crown: a stack of chunky leaf blocks in autumn colours, some turned 45 degrees
    crown = add_group("neck", (0, CROWN_Y, 0), root)
    y = CROWN_Y
    put(crown, [S.cube("Leaves", (0, y + 1.3, 0), (6.4, 2.6, 6.0), T["orange"]),
                S.cube("LeavesUnder", (0, y + 0.15, 0), (4.6, 0.5, 4.4), T["red"]),
                S.cube("LeavesMid", (0, y + 3.1, 0), (5.0, 1.6, 5.0), T["orange"], ry=45),
                S.cube("LeavesTop", (0, y + 4.4, 0), (3.2, 1.2, 3.2), T["yellow"]),
                S.cube("LeafL", (-3.2, y + 1.6, -0.6), (1.8, 1.8, 1.8), T["red"], ry=45),
                S.cube("LeafR", (3.2, y + 1.9, 0.5), (1.8, 1.8, 1.8), T["yellow"], ry=45),
                S.cube("LeafF", (0.8, y + 1.0, -3.1), (2.0, 1.6, 1.4), T["amber"]),
                S.cube("LeafB", (-0.9, y + 1.8, 3.1), (2.2, 1.8, 1.4), T["red"]),
                S.cube("LeafFL", (-2.0, y + 2.9, -2.0), (1.6, 1.4, 1.6), T["yellow"]),
                S.cube("LeafBR", (2.1, y + 3.0, 1.9), (1.6, 1.4, 1.6), T["amber"]),
                S.cube("LeafTop", (0.7, y + 5.3, -0.5), (1.4, 0.8, 1.4), T["orange"], ry=45)])

    model = json.load(open(os.path.join(ROOT, "designs", "desert", "Snake.bbmodel")))
    model.update(name="LivingBirch", elements=elements, groups=groups, outliner=[root], animations=[],
                 textures=[S.solid_texture(n, c) for n, c in COLORS.items()])
    return model


def main(out="/mnt/project-files/world2/woodland/renders"):
    os.makedirs(out, exist_ok=True)
    os.makedirs(os.path.join(ROOT, "designs", "woodland"), exist_ok=True)
    model = build()
    with open(os.path.join(ROOT, "designs", "woodland", "LivingBirch.bbmodel"), "w") as f:
        json.dump(model, f, separators=(",", ":"))
    parts = S.posed(model)
    pts = np.concatenate([q for p in parts for q in p.polys])
    print("LivingBirch", len(model["elements"]), "elements; size (studs)", np.round(pts.max(0) - pts.min(0), 1))
    W, H = 900, 1000
    img = render(parts, W=W, H=H, fov=30, eye=(-18, 13, -26), target=(0, 7.6, 0), transparent=True)
    bg = Image.new("RGBA", img.size, (238, 240, 244, 255))
    bg.alpha_composite(img)
    bg.convert("RGB").save(os.path.join(out, "LivingBirch.png"))


if __name__ == "__main__":
    main(*sys.argv[1:])
