"""Pink Butterfly: a World 2 Woodland Maze animal (QM, Oct 13), a flier like the Crystal Phoenix.
A plump plum body (head, thorax, a three-segment abdomen with pink stripes), big googly plate
eyes on the face, two antennae with bubblegum-pink ball tips, six short legs tucked under, and
four chunky stepped wings in a pink gradient: pale pink by the body, bubblegum in the middle,
hot pink at the edges, a raised white spot on each wing. Few blocks (QM's World 2 rule), no
black veins, so it reads apart from the Monarch boss and the Orange Butterfly.

Run: python3 tools/pink_butterfly.py [out_dir]

Built in Blockbench's ZYX Euler order; every bone rests at 0 (the wings' shallow V is baked
into the cubes). Bones (the Monarch's names): root (the thorax) -> neck (head, eyes,
antennae); root -> WingFL, WingFR, WingBL, WingBR (flap about Z); root -> Abdomen.
"""

import json
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import horse_rig  # noqa: E402

horse_rig.EULER = "ZYX"
import snake_design as S  # noqa: E402
import angel_boss as AB  # noqa: E402  (box, axis_rot)
from partlib import render  # noqa: E402
import animal_designs as A  # noqa: E402

ROOT = os.path.join(os.path.dirname(__file__), "..")
NAME = "PinkButterfly"
MODEL = os.path.join(ROOT, "designs", "woodland", NAME + ".bbmodel")

COLORS = {"body": (110, 44, 112), "stripe": (255, 110, 190), "pale": (255, 200, 232), "pink": (255, 126, 200),
          "hot": (255, 52, 156), "white": (255, 255, 255), "pupil": (24, 20, 32)}
TEX = {n: i for i, n in enumerate(COLORS)}
box = AB.box

Y0 = 7.0  # the thorax's centre: it hovers
THICK = 0.5  # wing thickness
DIHEDRAL = 22.0
ROOT_X = 1.4
# wing panels on the right side, (x0, x1, z0, z1, colour) in studs from the wing root
# (x out from the body, z back); stepped so each wing reads rounded from above
FORE = [(0.0, 3.0, -3.0, 1.5, "pale"), (3.0, 7.0, -5.0, 1.0, "pink"), (7.0, 9.5, -5.0, -0.5, "pink"),
        (9.5, 11.0, -4.5, -1.5, "hot"), (3.0, 9.5, -6.0, -5.0, "hot")]
HIND = [(0.0, 3.0, 1.0, 5.5, "pale"), (3.0, 6.5, 1.0, 6.5, "pink"), (6.5, 8.0, 1.5, 5.5, "hot"),
        (3.0, 6.5, 6.5, 7.5, "hot")]
SPOTS = {"WingF": (6.0, -2.6, 1.4), "WingB": (4.8, 3.8, 1.2)}  # (x, z, size) of the white spot


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

    y0 = Y0
    root = add_group("root", (0, y0, 0), None)
    put(root, [box("Thorax", (0, y0, 0), (3.0, 3.0, 3.6), TEX["body"])])

    # head: a round-ish block with two big googly plates on the face and clubbed antennae
    neck = add_group("neck", (0, y0, -1.8), root)
    hz = -3.0
    put(neck, [box("Head", (0, y0 + 0.3, hz), (3.0, 2.8, 2.4), TEX["body"])])
    for s in (-1, 1):
        n = "LR"[s > 0]
        put(neck, [box(f"Eye{n}", (s * 0.75, y0 + 0.55, hz - 1.225), (1.3, 1.5, 0.05), TEX["white"]),
                   box(f"Pupil{n}", (s * 0.75, y0 + 0.35, hz - 1.275), (0.65, 0.75, 0.05), TEX["pupil"])])
        M = AB.axis_rot("z", -s * 24) @ AB.axis_rot("x", 30)
        d = M @ np.array([0, 1.0, 0])
        base = np.array([s * 0.7, y0 + 1.6, hz + 0.3])
        L = 3.6
        put(neck, [box(f"Antenna{n}", base + d * L / 2, (0.25, L, 0.25), TEX["body"], M),
                   box(f"AntennaTip{n}", base + d * (L + 0.35), (0.8, 0.8, 0.8), TEX["stripe"], M)])

    # abdomen: three tapering segments, a pink stripe ring between each
    abd = add_group("Abdomen", (0, y0, 1.8), root)
    parts, z = [], 1.8
    for k, (w, L) in enumerate(((2.6, 1.8), (2.2, 1.6), (1.7, 1.4))):
        parts.append(box(f"Abdomen{k + 1}", (0, y0 - 0.15 - 0.2 * k, z + L / 2), (w, w, L), TEX["body"]))
        if k < 2:
            parts.append(box(f"Stripe{k + 1}", (0, y0 - 0.15 - 0.2 * k, z + L - 0.2), (w + 0.1, w + 0.1, 0.35), TEX["stripe"]))
        z += L
    put(abd, parts)

    # six short legs tucked under
    for s in (-1, 1):
        for k, zz in enumerate((-1.0, 0.0, 1.0)):
            M = AB.axis_rot("z", s * 25) @ AB.axis_rot("x", -20 + 15 * k)
            d = M @ np.array([0, -1.0, 0])
            base = np.array([s * 1.0, y0 - 1.3, zz])
            put(root, [box(f"Leg{'LR'[s > 0]}{k + 1}", base + d * 0.9, (0.25, 1.8, 0.25), TEX["body"], M)])

    # wings: stepped pink panels in a shallow V, a raised white spot on each
    for wname, panels, dz, dy in (("WingF", FORE, -0.4, 0.12), ("WingB", HIND, 0.4, -0.12)):
        for s in (-1, 1):
            n = "LR"[s > 0]
            pivot = np.array([s * ROOT_X, y0 + 0.5, dz])
            node = add_group(wname + n, pivot, root)
            M = AB.axis_rot("z", s * DIHEDRAL)
            parts = []
            for k, (x0, x1, z0, z1, col) in enumerate(panels):
                c = pivot + M @ np.array([s * (x0 + x1) / 2, dy, (z0 + z1) / 2])
                parts.append(box(f"{wname}{n}{k + 1}", c, (x1 - x0, THICK, z1 - z0), TEX[col], M))
            sx, sz, w = SPOTS[wname]
            c = pivot + M @ np.array([s * sx, dy, sz])
            parts.append(box(f"{wname}{n}Spot", c, (w, THICK + 0.2, w), TEX["white"], M))
            put(node, parts)

    model = json.load(open(os.path.join(ROOT, "designs", "desert", "Snake.bbmodel")))
    model.update(name=NAME, elements=elements, groups=groups, outliner=[root], animations=[],
                 textures=[S.solid_texture(n, c) for n, c in COLORS.items()])
    model.setdefault("meta", {})["format_version"] = "5.0"
    return model


def extent(parts):
    pts = np.concatenate([q for p in parts for q in p.polys])
    return pts.min(0), pts.max(0)


def main(out="/mnt/project-files/world2/woodland/renders"):
    os.makedirs(out, exist_ok=True)
    os.makedirs(os.path.dirname(MODEL), exist_ok=True)
    m = build()
    with open(MODEL, "w") as f:
        json.dump(m, f, separators=(",", ":"))
    parts = S.posed(m)
    lo, hi = extent(parts)
    print("elements", len(m["elements"]), "size", np.round(hi - lo, 1), "lowest", round(lo[1], 2))
    # 3/4 front view on a plain light background
    im = render(parts, W=1400, H=1100, fov=36, eye=(-18, 26, -32), target=(0, 6.5, 0), transparent=True)
    im = im.crop(im.getbbox())
    bg = Image.new("RGBA", (im.width + 160, im.height + 160), (240, 241, 245, 255))
    bg.alpha_composite(im, (80, 80))
    bg.convert("RGB").save(os.path.join(out, NAME + ".png"))
    # size check next to the Horse (scratch sheet, not delivered)
    from horse_rig import pose
    hparts = pose(A.qm_horse("A"), None, 0)
    for p in hparts:
        p.polys = [q + np.array([16, 0, 0]) for q in p.polys]
    sheet = Image.new("RGB", (1280, 520))
    sheet.paste(render(parts + hparts, W=640, H=520, fov=40, eye=(-14, 22, -40), target=(6, 4, 0)), (0, 0))
    sheet.paste(render(parts, W=640, H=520, fov=40, eye=(0, 34, 6), target=(0, 5, 1)), (640, 0))
    sheet.save(os.path.join(os.environ.get("SHEET_DIR", "/tmp"), NAME + "_sheet.png"))


if __name__ == "__main__":
    main(*sys.argv[1:])
