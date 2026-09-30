"""The Sandworm (Epic), rebuilt with the Snake's approach (tools/snake_design.py).

Run: python3 tools/sandworm_design.py [out_dir]

Rest pose (every bone at 0): lying straight and flat on its belly, facing -z,
every cube axis-aligned; bends come from bone rotations only. Bones chain from
the root (the front body segment, where you sit) forward to the head ("neck")
and back through the segments to the tail spike.

Look: a big armoured head with a dark round maw ringed by ivory teeth and a
glowing red eye at its centre, four black mandibles hooking in round the maw
(each on its own bone, for chomping), three horns on the crown; plated sand
segments with a brown armour plate and a dark fin on each, tapering to a
dark spike.
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

S.SIZE = 1.0  # the Epic: the Snake's style, not its size
ROOT = os.path.join(os.path.dirname(__file__), "..")

COLORS = {"sand": (228, 178, 104), "plate": (156, 98, 56), "belly": (248, 224, 172), "dark": (54, 40, 50),
          "maw": (104, 28, 40), "ivory": (250, 246, 232), "eye": (255, 48, 40)}
TEX = {n: i for i, n in enumerate(COLORS)}

# (bone, z front, z back, half width, height): head first, then the body to the tail
HEAD = ("neck", -5.5, 0.0, 2.4, 4.6)
SEGMENTS = [("root", 0.0, 3.2, 2.2, 4.2), ("Seg2", 3.2, 6.2, 2.0, 3.8), ("Seg3", 6.2, 9.0, 1.8, 3.4),
            ("Seg4", 9.0, 11.6, 1.55, 2.9), ("Seg5", 11.6, 13.8, 1.3, 2.4), ("Seg6", 13.8, 15.6, 1.0, 1.9)]
OVERLAP = 0.5  # each block reaches this far past its joint, so bending opens no gaps
BELLY = 0.25


def tooth(name, base, width, length, direction, tex):
    """A square pyramid: base centred at `base` (studs), apex `length` along direction (unit axis)."""
    c = np.array(base, float) * S.BB * S.SIZE
    w = width * S.BB * S.SIZE / 2
    d = np.array(direction, float)
    # two axes across the base
    u = np.array([1.0, 0, 0]) if abs(d[0]) < 0.5 else np.array([0, 1.0, 0])
    v = np.cross(d, u)
    corners = [(u * a + v * b) * w for a, b in ((-1, -1), (1, -1), (1, 1), (-1, 1))]
    verts = {f"b{i}": [round(x, 4) for x in p] for i, p in enumerate(corners)}
    verts["t"] = [round(x, 4) for x in d * length * S.BB * S.SIZE]
    faces = {"base": ["b0", "b1", "b2", "b3"], "s0": ["b0", "b1", "t"], "s1": ["b1", "b2", "t"],
             "s2": ["b2", "b3", "t"], "s3": ["b3", "b0", "t"]}
    return {"name": name, "type": "mesh", "uuid": S.uid(), "color": 0, "origin": [round(x, 4) for x in c],
            "rotation": [0, 0, 0], "vertices": verts,
            "faces": {k: {"texture": tex, "vertices": vs, "uv": {q: [0, 0] for q in vs}} for k, vs in faces.items()}}


def segment(name, z0, z1, hw, h, fin=True, plate=True):
    """Sand core with a cream belly, a brown armour plate over the front of its back, a dark fin."""
    L = z1 - z0
    zc = (z0 + z1) / 2
    belly = h * BELLY
    parts = [S.cube(name + "Belly", (0, belly / 2, zc), (2 * hw, belly, L), TEX["belly"]),
             S.cube(name, (0, belly + (h - belly) / 2, zc), (2 * hw, h - belly, L), TEX["sand"])]
    # the plate: over the top and down the sides, the front 70% of the segment
    pl = L * 0.7
    pz = z0 + pl / 2
    if plate:
        parts.append(S.cube(name + "Plate", (0, h * 0.62 + 0.125, pz), (2 * hw + 0.3, h * 0.76 + 0.25, pl), TEX["plate"]))
    if fin:
        parts.append(S.spike(name + "Fin", (0, h + 0.25, pz + 0.1), min(1.3, pl * 0.6), 0.5 + 0.3 * hw, 0.5, TEX["dark"]))
    return parts


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

    # body: root is the front segment, the rest chain back to the tail
    name, z0, z1, hw, h = SEGMENTS[0]
    root = add_group("root", (0, h / 2, (z0 + z1) / 2), None)
    put(root, segment("Seg1", z0 - OVERLAP, z1, hw, h, fin=False))
    parent = root
    for name, z0, z1, hw, h in SEGMENTS[1:]:
        node = add_group(name, (0, h / 2, z0), parent)
        put(node, segment(name, z0 - OVERLAP, z1, hw, h))
        parent = node
    put(parent, [S.spike("TailSpike", (0, 0.2, z1 + 0.6), 1.6, 1.3, 1.4, TEX["dark"])])
    parent["children"][-1] = parent["children"][-1]
    # the spike lies flat pointing back: tall end against the last segment
    tail = elements[-1]
    tail["vertices"] = {k: [v[0], v[1], -v[2]] for k, v in tail["vertices"].items()}
    tail["faces"] = {k: dict(f, vertices=list(reversed(f["vertices"]))) for k, f in tail["faces"].items()}

    # head ("neck" to the game: the lasso loops round it), pivot at its back joint
    bone, z0, z1, hw, h = HEAD
    head = add_group(bone, (0, h / 2, z1), root)
    put(head, segment("Head", z0, z1 + OVERLAP, hw, h, fin=False, plate=False))
    # an armoured brow over the front of the head, and a plate band behind it
    put(head, [S.cube("Brow", (0, h - 0.1, z0 + 1.3), (2 * hw + 0.3, 0.7, 2.6), TEX["plate"]),
               S.cube("HeadPlate", (0, h * 0.62 + 0.125, -1.2), (2 * hw + 0.3, h * 0.76 + 0.25, 1.6), TEX["plate"])])
    # three horns on the crown
    for i, x in enumerate((-1.3, 0.0, 1.3)):
        put(head, [S.spike(f"Horn{i + 1}", (x, h + 0.25, -2.6), 1.6, 1.5 if x == 0 else 1.1, 0.55, TEX["dark"])])
    # the maw: a dark round-ish mouth block, the glowing eye at its centre, a ring of teeth
    put(head, [S.cube("Maw", (0, 2.3, z0 - 0.15), (3.2, 2.6, 0.3), TEX["maw"]),
               S.cube("MawTop", (0, 3.75, z0 - 0.15), (2.2, 0.3, 0.3), TEX["maw"]),
               S.cube("MawBottom", (0, 0.85, z0 - 0.15), (2.2, 0.3, 0.3), TEX["maw"]),
               S.cube("EyeGlow", (0, 2.3, z0 - 0.4), (0.8, 0.8, 0.3), TEX["eye"])])
    zt = z0 - 0.3
    k = 0
    for x in (-1.05, -0.35, 0.35, 1.05):
        put(head, [tooth(f"ToothTop{k}", (x, 3.55, zt), 0.45, 0.7, (0, -1, 0), TEX["ivory"]),
                   tooth(f"ToothBottom{k}", (x, 1.05, zt), 0.45, 0.7, (0, 1, 0), TEX["ivory"])])
        k += 1
    for side, sx in (("L", -1), ("R", 1)):
        put(head, [tooth(f"ToothSide{side}", (sx * 1.45, 2.3, zt), 0.45, 0.6, (-sx, 0, 0), TEX["ivory"])])
    # four mandibles off the face's corners, each on its own bone: out and forward,
    # then hooking in toward the maw with an ivory point
    for vy, yc in (("T", 4.15), ("B", 0.55)):
        for vx, sx in (("L", -1), ("R", 1)):
            b = add_group(f"Mand{vy}{vx}", (sx * 2.1, yc, z0), head)
            t = 0.65
            put(b, [S.cube(f"Mand{vy}{vx}", (sx * 2.1, yc, z0 - 1.3), (t, t, 2.6), TEX["dark"]),
                    S.cube(f"Hook{vy}{vx}", (sx * 1.55, yc, z0 - 2.3), (0.9, t, t), TEX["dark"]),
                    tooth(f"HookTip{vy}{vx}", (sx * 1.1, yc, z0 - 2.3), 0.5, 0.55, (-sx, 0, 0), TEX["ivory"])])

    model = json.load(open(os.path.join(ROOT, "designs", "desert", "Snake.bbmodel")))
    model.update(name="Sandworm", elements=elements, groups=groups, outliner=[root], animations=[],
                 textures=[S.solid_texture(n, c) for n, c in COLORS.items()])
    return model


META = {"seat": (0, 4.45 * S.SIZE, 1.6 * S.SIZE), "neck_loop": {"center": (0, 2.3 * S.SIZE, -2.5 * S.SIZE), "radius": 2.9 * S.SIZE}}


def main(out="/mnt/project-files/animals/desert"):
    model = build()
    for path in (os.path.join(ROOT, "designs", "desert", "Sandworm.bbmodel"), os.path.join(out, "Sandworm.bbmodel")):
        with open(path, "w") as f:
            json.dump(model, f, separators=(",", ":"))
    parts = S.posed(model)
    horse = A.qm_horse("A")
    from horse_rig import pose
    hparts = pose(horse, None, 0)
    for p in hparts:
        p.polys = [q + np.array([9, 0, 6]) for q in p.polys]
    W, H = 560, 440
    cams = [dict(eye=(-26, 16, -24), target=(0, 2.5, 4)), dict(eye=(-40, 6, 6), target=(0, 3, 6)),
            dict(eye=(22, 16, 34), target=(0, 2.5, 6)), dict(eye=(-5, 5, -19), target=(0, 2.8, -4))]
    sheet = Image.new("RGB", (W * 2, H * 2))
    for i, cam in enumerate(cams):
        ps = parts + (hparts if i == 1 else [])
        sheet.paste(render(ps, W=W, H=H, fov=40, **cam), ((i % 2) * W, (i // 2) * H))
    sheet.save(os.path.join(out, "Sandworm.png"))
    print("wrote", len(model["elements"]), "elements")


if __name__ == "__main__":
    main(*sys.argv[1:])
