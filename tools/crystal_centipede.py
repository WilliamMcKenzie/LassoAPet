"""Crystal Centipede: World 2's Crystal Cavern animal. A purple centipede with a
crystal (a cube shaft + a pyramid tip, like the cavern props) growing from each
back segment, alternating cyan #00BEE7 and pink #E583FB.

Run: python3 tools/crystal_centipede.py [out_dir]

Built like the Sandworm (tools/sandworm_design.py): rest pose lies straight and flat,
bones chain from root (the front segment, where you sit) back through Seg2..Seg6
and forward to the head ("neck"). Kept to few parts (QM): one block per segment,
one leg bar under each segment poking out both sides, one crystal per segment.

This wrote the first draft. QM has since edited designs/crystal/CrystalCentipede.bbmodel in
Blockbench (Oct 13: antennae off, two crystals over the head): don't rerun this, it would
overwrite QM's edit. tools/crystal_centipede_rig.py animates QM's file.
"""

import json
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import snake_design as S  # noqa: E402
from partlib import render  # noqa: E402
import animal_designs as A  # noqa: E402

S.SIZE = 1.35  # a bit bigger than the Sandworm: a long, low ride
ROOT = os.path.join(os.path.dirname(__file__), "..")

COLORS = {"body": (124, 72, 200), "leg": (72, 44, 124), "cyan": (0, 190, 231), "pink": (229, 131, 251),
          "white": (255, 255, 255), "pupil": (24, 20, 32)}
TEX = {n: i for i, n in enumerate(COLORS)}

LIFT = 0.7    # body underside above the ground
LEG_H = 1.1   # leg bars reach from the ground into the body
# (bone, z front, z back, half width, height, crystal: (colour, shaft width, shaft height, tip, tilt x, tilt z) or None)
SEGMENTS = [("root", 0.0, 2.6, 1.5, 1.8, None),
            ("Seg2", 2.6, 5.0, 1.45, 1.75, ("cyan", 1.1, 2.3, 1.0, 12, -10)),
            ("Seg3", 5.0, 7.4, 1.4, 1.7, ("pink", 1.0, 1.9, 0.9, 10, 12)),
            ("Seg4", 7.4, 9.7, 1.3, 1.6, ("cyan", 0.95, 1.6, 0.85, 14, -12)),
            ("Seg5", 9.7, 11.8, 1.15, 1.45, ("pink", 0.85, 1.3, 0.75, 16, 10)),
            ("Seg6", 11.8, 13.6, 1.0, 1.3, ("cyan", 0.7, 1.0, 0.6, 20, -8))]
HEAD = ("neck", -2.4, 0.0, 1.6, 1.9)
OVERLAP = 0.3


def pyramid(name, origin, y0, w, h, tex, rot):
    """Square pyramid on the plane y0 (relative to origin), apex h above it."""
    k = S.BB * S.SIZE
    o = np.array(origin, float) * k
    a, y, t = w * k / 2, y0 * k, (y0 + h) * k
    verts = {"b0": [-a, y, -a], "b1": [a, y, -a], "b2": [a, y, a], "b3": [-a, y, a], "t": [0, t, 0]}
    faces = {"base": ["b0", "b1", "b2", "b3"], "s0": ["b0", "b1", "t"], "s1": ["b1", "b2", "t"],
             "s2": ["b2", "b3", "t"], "s3": ["b3", "b0", "t"]}
    return {"name": name, "type": "mesh", "uuid": S.uid(), "color": 0, "origin": [round(c, 4) for c in o],
            "rotation": list(rot), "vertices": {k: [round(c, 4) for c in v] for k, v in verts.items()},
            "faces": {k: {"texture": tex, "vertices": vs, "uv": {q: [0, 0] for q in vs}} for k, vs in faces.items()}}


def crystal(name, base, color, w, hs, ht, rx, rz):
    """Shaft and tip share one origin (the base) and one tilt, so they stay joined."""
    sink = 0.35  # the shaft starts inside the body
    o = np.array(base, float)
    shaft = S.cube(name, (o[0], o[1] - sink + (hs + sink) / 2, o[2]), (w, hs + sink, w), TEX[color])
    shaft["origin"] = [round(c * S.BB * S.SIZE, 4) for c in o]
    shaft["rotation"] = [rx, 0, rz]
    return [shaft, pyramid(name + "Tip", o, hs, w, ht, TEX[color], (rx, 0, rz))]


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

    def segment(node, name, z0, z1, hw, h, cr):
        zc = (z0 + z1) / 2
        parts = [S.cube(name, (0, LIFT + h / 2, (z0 - OVERLAP + z1) / 2), (2 * hw, h, z1 - z0 + OVERLAP), TEX["body"]),
                 S.cube(name + "Legs", (0, LEG_H / 2, zc), (2 * hw + 1.6, LEG_H, 0.55), TEX["leg"])]
        if cr:
            parts += crystal(name + "Crystal", (0, LIFT + h, zc), *cr)
        put(node, parts)

    parent = None
    for i, (bone, z0, z1, hw, h, cr) in enumerate(SEGMENTS):
        node = add_group(bone, (0, LIFT + h / 2, (z0 + z1) / 2 if i == 0 else z0), parent)
        segment(node, "Seg1" if i == 0 else bone, z0, z1, hw, h, cr)
        if i == 0:
            root = node
        parent = node
    # two tail feelers off the last segment
    z1, hw = SEGMENTS[-1][2], SEGMENTS[-1][3]
    put(parent, [S.cube(f"Feeler{s}", (sx * 0.5, LIFT + 0.9, z1 + 0.9), (0.3, 0.3, 2.0), TEX["leg"], rx=-20, ry=sx * 20)
                 for s, sx in (("L", -1), ("R", 1))])

    bone, z0, z1, hw, h = HEAD
    head = add_group(bone, (0, LIFT + h / 2, z1), root)
    put(head, [S.cube("Head", (0, LIFT + h / 2, (z0 + z1 + OVERLAP) / 2), (2 * hw, h, z1 - z0 + OVERLAP), TEX["body"])])
    # plate eyes on the head's sides, pupils set back from the front edge (QM)
    ey0, ey1, ez0, ez1 = LIFT + 0.75, LIFT + 1.65, z0 + 0.25, z0 + 1.35
    for s, sx in (("L", -1), ("R", 1)):
        put(head, [S.cube("Eye" + s, (sx * (hw + 0.025), (ey0 + ey1) / 2, (ez0 + ez1) / 2), (0.05, ey1 - ey0, ez1 - ez0), TEX["white"]),
                   S.cube("Pupil" + s, (sx * (hw + 0.055), ey0 + 0.35, ez0 + 0.025 + 0.3), (0.05, 0.6, 0.6), TEX["pupil"])])
    # crystal pincers curving in at the front, antennae sweeping up and forward
    for s, sx in (("L", -1), ("R", 1)):
        # spiked mandibles (QM): a forward point and an inward spike on each
        px, py, pz = sx * 0.95, LIFT + 0.25, z0 - 0.6
        put(head, [S.cube("Pincer" + s, (px, py, pz), (0.5, 0.5, 1.5), TEX["cyan"]),
                   pyramid("PincerTip" + s, (px, py, pz - 0.75), 0, 0.5, 0.7, TEX["cyan"], (-90, 0, 0)),
                   pyramid("PincerSpike" + s, (px - sx * 0.25, py, pz - 0.2), 0, 0.4, 0.45, TEX["cyan"], (0, 0, sx * 90)),
                   S.cube("Antenna" + s, (sx * 0.8, LIFT + h + 0.5, z0 + 0.1), (0.3, 0.3, 2.2), TEX["leg"], rx=-35)])

    model = json.load(open(os.path.join(ROOT, "designs", "desert", "Snake.bbmodel")))
    model.update(name="CrystalCentipede", elements=elements, groups=groups, outliner=[root], animations=[],
                 textures=[S.solid_texture(n, c) for n, c in COLORS.items()])
    return model


META = {"seat": (0, (LIFT + 1.8) * S.SIZE, 1.3 * S.SIZE), "neck_loop": {"center": (0, (LIFT + 0.95) * S.SIZE, -1.2 * S.SIZE), "radius": 2.0 * S.SIZE}}


def main(out="/mnt/project-files/animals/crystal_centipede"):
    os.makedirs(out, exist_ok=True)
    os.makedirs(os.path.join(ROOT, "designs", "crystal"), exist_ok=True)
    model = build()
    for path in (os.path.join(ROOT, "designs", "crystal", "CrystalCentipede.bbmodel"), os.path.join(out, "CrystalCentipede.bbmodel")):
        with open(path, "w") as f:
            json.dump(model, f, separators=(",", ":"))
    parts = S.posed(model)
    from horse_rig import pose
    hparts = pose(A.qm_horse("A"), None, 0)
    for p in hparts:
        p.polys = [q + np.array([8, 0, 5]) for q in p.polys]
    W, H = 560, 440
    cams = [dict(eye=(-22, 13, -20), target=(0, 1.8, 4)), dict(eye=(-34, 6, 6), target=(0, 2.2, 5)),
            dict(eye=(20, 14, 30), target=(0, 1.8, 6)), dict(eye=(-4, 4, -15), target=(0, 1.8, -2))]
    sheet = Image.new("RGB", (W * 2, H * 2))
    for i, cam in enumerate(cams):
        sheet.paste(render(parts + (hparts if i == 1 else []), W=W, H=H, fov=40, **cam), ((i % 2) * W, (i // 2) * H))
    sheet.save(os.path.join(out, "CrystalCentipede.png"))
    print("wrote", len(model["elements"]), "elements")


if __name__ == "__main__":
    main(*sys.argv[1:])
