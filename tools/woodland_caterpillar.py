"""Caterpillar: World 2 Woodland Maze animal (Uncommon). A chubby bright green
caterpillar with a yellow spot on each segment, dark green stubby feet, a big round
head with the standard white plate eyes and orange-tipped antennae (the maze's
autumn orange #F26D39).

Run: python3 tools/woodland_caterpillar.py [out_dir]

Built like the Crystal Centipede (tools/crystal_centipede.py): rest pose lies straight
and flat facing -z, every cube axis-aligned; bones chain root (front segment, where
you sit) -> Seg2..Seg6 to the tail, root -> neck (the head). Few parts (QM): a body
block with a stepped-in top so it reads round, a feet bar, a back spot per segment.
"""

import json
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import snake_design as S  # noqa: E402
from partlib import render  # noqa: E402

S.SIZE = 1.2  # about the Crystal Centipede: a long, low ride
ROOT = os.path.join(os.path.dirname(__file__), "..")
NAME = "Caterpillar"

COLORS = {"green": (112, 206, 58), "lime": (156, 226, 70), "belly": (196, 232, 96), "feet": (46, 122, 44), "spot": (255, 212, 40),
          "orange": (242, 109, 57), "white": (255, 255, 255), "pupil": (24, 20, 32)}
TEX = {n: i for i, n in enumerate(COLORS)}

LIFT = 0.5    # body underside above the ground
FEET_H = 0.8  # feet bars reach from the ground into the body
CAP = 0.6     # top edges stepped in, so the body reads round
# (bone, z front, z back, half width, height)
SEGMENTS = [("root", 0.0, 2.4, 1.6, 2.6), ("Seg2", 2.4, 4.7, 1.6, 2.6), ("Seg3", 4.7, 6.9, 1.55, 2.5),
            ("Seg4", 6.9, 9.0, 1.45, 2.35), ("Seg5", 9.0, 10.9, 1.3, 2.15), ("Seg6", 10.9, 12.6, 1.1, 1.9)]
HEAD = ("neck", -3.0, 0.0, 1.9, 3.2)
OVERLAP = 0.3


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

    def segment(node, name, z0, z1, hw, h, col):
        zc, L = (z0 - OVERLAP + z1) / 2, z1 - z0 + OVERLAP
        put(node, [S.cube(name + "Belly", (0, LIFT + CAP / 2, zc), (2 * hw - 0.8, CAP, L), TEX["belly"]),
                   S.cube(name, (0, LIFT + h / 2, zc), (2 * hw, h - 2 * CAP, L), TEX[col]),
                   S.cube(name + "Top", (0, LIFT + h - CAP / 2, zc), (2 * hw - 0.8, CAP, L), TEX[col]),
                   S.cube(name + "Feet", (0, FEET_H / 2, (z0 + z1) / 2), (2 * hw + 0.6, FEET_H, 0.8), TEX["feet"]),
                   S.cube(name + "Spot", (0, LIFT + h + 0.1, (z0 + z1) / 2), (1.0, 0.4, 1.0), TEX["spot"])])

    parent = None
    for i, (bone, z0, z1, hw, h) in enumerate(SEGMENTS):
        node = add_group(bone, (0, LIFT + h / 2, (z0 + z1) / 2 if i == 0 else z0), parent)
        segment(node, "Seg1" if i == 0 else bone, z0, z1, hw, h, "lime" if i % 2 else "green")  # alternating, so the segments read
        if i == 0:
            root = node
        parent = node
    # a blunt round tail end
    z1, h = SEGMENTS[-1][2], SEGMENTS[-1][4]
    put(parent, [S.cube("TailTip", (0, LIFT + h / 2 - 0.1, z1 + 0.3), (1.4, 1.3, 0.6), TEX["green"])])

    bone, z0, z1, hw, h = HEAD
    head = add_group(bone, (0, LIFT + h / 2, z1), root)
    zc, L = (z0 + z1 + OVERLAP) / 2, z1 - z0 + OVERLAP
    put(head, [S.cube("HeadLow", (0, LIFT + CAP / 2, zc), (2 * hw - 0.8, CAP, L - 0.6), TEX["green"]),
               S.cube("Head", (0, LIFT + h / 2, zc), (2 * hw, h - 2 * CAP, L), TEX["green"]),
               S.cube("HeadTop", (0, LIFT + h - CAP / 2, zc), (2 * hw - 0.8, CAP, L - 0.6), TEX["green"]),
               S.cube("Snout", (0, LIFT + 1.1, z0 - 0.2), (2.0, 1.2, 0.4), TEX["belly"]),
               S.cube("Mouth", (0, LIFT + 1.0, z0 - 0.45), (1.0, 0.25, 0.1), TEX["pupil"])])
    # standard plate eyes on the head's sides, pupils toward the front
    ey0, ey1, ez0, ez1 = LIFT + 1.4, LIFT + 2.6, z0 + 0.3, z0 + 1.6
    for s, sx in (("L", -1), ("R", 1)):
        put(head, [S.cube("Eye" + s, (sx * (hw + 0.025), (ey0 + ey1) / 2, (ez0 + ez1) / 2), (0.05, ey1 - ey0, ez1 - ez0), TEX["white"]),
                   S.cube("Pupil" + s, (sx * (hw + 0.055), ey0 + 0.45, ez0 + 0.4), (0.05, 0.7, 0.7), TEX["pupil"]),
                   # antennae: a green stalk leaning out and forward, an orange ball on top
                   S.cube("Antenna" + s, (sx * 0.85, LIFT + h + 0.8, z0 + 1.0), (0.35, 1.8, 0.35), TEX["feet"], rx=-15),
                   S.cube("AntennaTip" + s, (sx * 0.85, LIFT + h + 1.8, z0 + 0.72), (0.75, 0.75, 0.75), TEX["orange"])])

    model = json.load(open(os.path.join(ROOT, "designs", "desert", "Snake.bbmodel")))
    model.update(name=NAME, elements=elements, groups=groups, outliner=[root], animations=[],
                 textures=[S.solid_texture(n, c) for n, c in COLORS.items()])
    return model


BG = (238, 240, 234)


def shot(parts, W=900, H=640, **cam):
    img = render(parts, W=W, H=H, fov=34, transparent=True, **cam)
    bg = Image.new("RGBA", img.size, BG + (255,))
    return Image.alpha_composite(bg, img).convert("RGB")


def main(out="/mnt/project-files/world2/woodland/renders"):
    os.makedirs(out, exist_ok=True)
    os.makedirs(os.path.join(ROOT, "designs", "woodland"), exist_ok=True)
    model = build()
    with open(os.path.join(ROOT, "designs", "woodland", NAME + ".bbmodel"), "w") as f:
        json.dump(model, f, separators=(",", ":"))
    parts = S.posed(model)
    shot(parts, eye=(-22, 12, -16), target=(0, 1.6, 3.5)).save(os.path.join(out, NAME + ".png"))
    # a check sheet beside the Horse for scale (not for QM)
    import animal_designs as A
    from horse_rig import pose
    hparts = pose(A.qm_horse("A"), None, 0)
    for p in hparts:
        p.polys = [q + np.array([8, 0, 5]) for q in p.polys]
    cams = [dict(eye=(-34, 6, 6), target=(0, 2.2, 5)), dict(eye=(20, 14, 30), target=(0, 1.8, 6))]
    sheet = Image.new("RGB", (1120, 440))
    for i, cam in enumerate(cams):
        sheet.paste(shot(parts + (hparts if i == 0 else []), W=560, H=440, **cam), (i * 560, 0))
    sheet.save(os.environ.get("CHECK", "/tmp/caterpillar_check.png"))
    print("wrote", len(model["elements"]), "elements")


if __name__ == "__main__":
    main(*sys.argv[1:])
