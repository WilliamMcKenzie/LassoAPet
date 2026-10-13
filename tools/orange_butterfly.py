"""Orange Butterfly: a World 2 Woodland Maze animal (QM, Oct 13; Rare, flies like the Crystal
Phoenix). A chubby little butterfly, not a small Monarch: no black vein lattice. A fuzzy brown
body with a cream collar, a striped abdomen (brown and sunny yellow), big googly plate eyes,
two antennae with round orange tips, four short tucked legs, and four rounded wings of a few
big blocks each: sunny yellow by the body, bright orange in the middle and autumn orange-red
at the edges (the Woodland walls' #F26D39), a cream spot on each forewing tip and a brown eye
spot on each hindwing. Spots are blocks a little thicker than the wing, poking through both
faces (no 2D planes, no z-fighting).

Run: python3 tools/orange_butterfly.py [out_dir] [--gif]
(writes the .bbmodel with its animations, src/shared/Animals/OrangeButterflyModel.luau and renders)

Built in Blockbench's ZYX Euler order;
every bone rests at 0 (the wings' dihedral and the antennae tilts are baked into the cubes).
Bones: root (the thorax, where the rider sits) -> neck (head, eyes, antennae);
root -> WingFL, WingFR (forewings), WingBL, WingBR (hindwings): flap about Z; root -> Abdomen.

  idle    hovers, wings beating gently, bobbing, the abdomen swaying
  walk    faster beats, leaning into it
  gallop  big fast beats, nosing down into the chase
"""

import math

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
from horse_rig import write_animations  # noqa: E402
from partlib import render  # noqa: E402
from snake_rig import track  # noqa: E402
import animal_designs as A  # noqa: E402

ROOT = os.path.join(os.path.dirname(__file__), "..")
NAME = "OrangeButterfly"
MODEL = os.path.join(ROOT, "designs", "woodland", NAME + ".bbmodel")

COLORS = {"body": (107, 63, 42), "fuzz": (255, 240, 214), "stripe": (255, 200, 58), "yellow": (255, 196, 58),
          "orange": (255, 128, 26), "edge": (242, 109, 57), "rust": (214, 74, 30), "spot": (255, 244, 214),
          "eyespot": (92, 50, 30), "white": (255, 255, 255), "pupil": (24, 20, 28)}
TEX = {n: i for i, n in enumerate(COLORS)}
box = AB.box

Y0 = 5.6  # the thorax's centre
THICK = 0.5  # wing thickness
ROOT_X = 1.3  # wing roots this far out from the body's middle
DIHEDRAL = 16.0  # degrees the wings rest raised
# wing blocks, right side, studs from the wing root: (x0, x1, z0, z1, colour); z is back
FORE = [(0.0, 3.0, -2.8, 1.8, "yellow"), (3.0, 7.0, -4.8, 1.8, "orange"), (7.0, 9.6, -6.0, 0.8, "edge"),
        (9.6, 11.0, -5.6, -1.0, "rust")]
FORE_SPOT = [(9.0, -3.4, 1.6, "spot")]  # x, z, size, colour: across the edge and rust blocks
HIND = [(0.0, 3.0, 1.2, 6.2, "yellow"), (3.0, 6.6, 1.2, 7.6, "orange"), (6.6, 8.4, 1.8, 6.4, "edge")]
HIND_SPOT = [(4.6, 4.6, 1.8, "eyespot"), (4.6, 4.6, 0.8, "stripe")]  # a brown eye spot, sunny middle
K = 1.25  # the whole build scaled up after (horse-sized body)


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
    # fat fuzzy thorax with a cream collar of fluff at the front
    put(root, [box("Thorax", (0, y0, 0.2), (3.0, 2.8, 3.6), TEX["body"]),
               box("ThoraxTop", (0, y0 + 1.6, 0.4), (2.4, 0.4, 2.8), TEX["body"]),
               box("Collar", (0, y0 + 0.1, -1.7), (3.3, 2.6, 0.9), TEX["fuzz"])])
    # four short legs tucked under, angled back
    for s in (-1, 1):
        for k, zz in enumerate((-0.8, 1.0)):
            M = AB.axis_rot("z", s * 20) @ AB.axis_rot("x", -20)
            d = M @ np.array([0, -1.0, 0])
            base = np.array([s * 1.0, y0 - 1.2, zz])
            put(root, [box(f"Leg{'LR'[s > 0]}{k + 1}", base + d * 1.2, (0.45, 2.4, 0.45), TEX["body"], M)])

    # round head, big googly eyes on the front, antennae with round orange tips
    neck = add_group("neck", (0, y0, -2.0), root)
    hz = -3.3
    put(neck, [box("Head", (0, y0 + 0.4, hz), (2.8, 2.6, 2.2), TEX["body"])])
    for s in (-1, 1):
        n = "LR"[s > 0]
        put(neck, [box(f"Eye{n}", (s * 0.75, y0 + 0.7, hz - 1.125), (1.3, 1.5, 0.05), TEX["white"]),
                   box(f"Pupil{n}", (s * 0.8, y0 + 0.55, hz - 1.175), (0.65, 0.75, 0.05), TEX["pupil"])])
        M = AB.axis_rot("z", -s * 25) @ AB.axis_rot("x", 30)
        d = M @ np.array([0, 1.0, 0])
        base = np.array([s * 0.6, y0 + 1.6, hz - 0.1])
        L = 3.6
        put(neck, [box(f"Antenna{n}", base + d * L / 2, (0.3, L, 0.3), TEX["body"], M),
                   box(f"AntennaTip{n}", base + d * (L + 0.35), (0.8, 0.8, 0.8), TEX["orange"], M)])

    # abdomen: three tapering segments, brown with sunny yellow bands between
    abd = add_group("Abdomen", (0, y0, 1.9), root)
    parts, z = [], 2.0
    for k, (w, L, col) in enumerate(((2.4, 1.4, "body"), (2.3, 0.7, "stripe"), (2.0, 1.3, "body"),
                                     (1.8, 0.6, "stripe"), (1.4, 1.1, "body"))):
        parts.append(box(f"Abdomen{k + 1}", (0, y0 - 0.25 - 0.2 * k, z + L / 2), (w, w * 0.95, L), TEX[col]))
        z += L
    put(abd, parts)

    # the wings: a few big blocks each, raised in a shallow V (baked in), spots poking through
    for wname, blocks, spots, dz, dy in (("WingF", FORE, FORE_SPOT, -0.6, 0.1), ("WingB", HIND, HIND_SPOT, 0.4, -0.1)):
        for s in (-1, 1):
            n = "LR"[s > 0]
            pivot = np.array([s * ROOT_X, y0 + 0.8, dz])
            node = add_group(wname + n, pivot, root)
            M = AB.axis_rot("z", s * DIHEDRAL)
            parts = []
            for k, (x0, x1, z0, z1, col) in enumerate(blocks):
                c = pivot + M @ np.array([s * (x0 + x1) / 2, dy, (z0 + z1) / 2])
                parts.append(box(f"{wname}{n}{k + 1}", c, (x1 - x0, THICK, z1 - z0), TEX[col], M))
            for k, (sx, sz, sw, col) in enumerate(spots):  # each one poking a little further through
                parts.append(box(f"{wname}Spot{n}{k + 1}", pivot + M @ np.array([s * sx, dy, sz]), (sw, THICK + 0.1 * (k + 1), sw), TEX[col], M))
            put(node, parts)

    for e in elements:
        for key in ("from", "to", "origin"):
            e[key] = [round(v * K, 4) for v in e[key]]
    for g in groups:
        g["origin"] = [round(v * K, 4) for v in g["origin"]]
    model = json.load(open(os.path.join(ROOT, "designs", "desert", "Snake.bbmodel")))
    model.update(name=NAME, elements=elements, groups=groups, outliner=[root], animations=[],
                 textures=[S.solid_texture(n, c) for n, c in COLORS.items()])
    model.setdefault("meta", {})["format_version"] = "5.0"
    return model


TAU = 2 * math.pi


def animations():
    """Wings flap about Z (right side positive = up), the hindwings a beat behind. Kept
    under ~45 degrees up so they don't swing through the rider much."""
    def flap(L, amp, bias, beats, lag=0.6, n=24):
        out = {}
        for w, ph in (("WingF", 0.0), ("WingB", lag)):
            for s, n_ in ((1, "R"), (-1, "L")):
                out[w + n_] = [track(L, lambda u, s=s, ph=ph: (0, 0, s * (bias + amp * math.sin(TAU * beats * u - ph))), n)]
        return out

    L = 1.6
    idle = {**flap(L, 26, 4, 2),
            "root": [track(L, lambda u: (0, 0, 0), 4), track(L, lambda u: (0, 4 * math.sin(TAU * 2 * u - 0.8), 0), 16, "position")],
            "neck": [track(L, lambda u: (4 * math.sin(TAU * u), 6 * math.sin(TAU * u), 0), 16)],
            "Abdomen": [track(L, lambda u: (6 * math.sin(TAU * 2 * u - 1.2), 4 * math.sin(TAU * u), 0), 16)]}
    Lw = 0.8
    walk = {**flap(Lw, 32, 4, 2),
            "root": [track(Lw, lambda u: (-6, 0, 0), 4), track(Lw, lambda u: (0, 5 * math.sin(TAU * 2 * u - 0.8), 0), 16, "position")],
            "neck": [track(Lw, lambda u: (4, 0, 0), 4)],
            "Abdomen": [track(Lw, lambda u: (8 * math.sin(TAU * 2 * u - 1.2), 0, 0), 16)]}
    Lg = 0.4
    gallop = {**flap(Lg, 38, 4, 1, n=16),
              "root": [track(Lg, lambda u: (-12, 0, 0), 4), track(Lg, lambda u: (0, 8 * math.sin(TAU * u - 0.8), 0), 16, "position")],
              "neck": [track(Lg, lambda u: (8, 0, 0), 4)],
              "Abdomen": [track(Lg, lambda u: (10 * math.sin(TAU * u - 1.2), 0, 0), 16)]}
    return {"idle": (L, idle), "walk": (Lw, walk), "gallop": (Lg, gallop)}


BG = (242, 240, 234)


def on_light(im, pad=60):
    x0, y0, x1, y1 = im.getbbox()
    im = im.crop((x0 - pad, y0 - pad, x1 + pad, y1 + pad))
    bg = Image.new("RGBA", im.size, BG + (255,))
    bg.alpha_composite(im)
    return bg.convert("RGB")


def main(out="/mnt/project-files/world2/woodland/renders"):
    os.makedirs(out, exist_ok=True)
    os.makedirs(os.path.dirname(MODEL), exist_ok=True)
    m = build()
    write_animations(m, {g["name"]: g for g in m["groups"]}, animations())
    with open(MODEL, "w") as f:
        json.dump(m, f, separators=(",", ":"))
    import bbmodel_to_luau
    bbmodel_to_luau.ORDER = "ZYX"
    bbmodel_to_luau.main(os.path.join("designs", "woodland", NAME + ".bbmodel"),  # (run from the repo root)
                         os.path.join(ROOT, "src", "shared", "Animals", NAME + "Model.luau"))
    parts = S.posed(m)
    pts = np.vstack([q for p in parts for q in p.polys])
    lo, hi = pts.min(0), pts.max(0)
    print("elements", len(m["elements"]), "size", (hi - lo).round(1), "low", round(lo[1], 2))
    on_light(render(parts, W=1100, H=900, fov=34, eye=(-30, 30, -36), target=(0, 6, 0), transparent=True)).save(
        os.path.join(out, NAME + ".png"))
    # check sheet beside the horse: 3/4 front, top, side, back
    from horse_rig import pose
    hparts = pose(A.qm_horse("A"), None, 0)
    for p in hparts:
        p.polys = [q + np.array([20, 0, 0]) for q in p.polys]
    cams = [dict(eye=(-24, 16, -32), target=(5, 5, 0)), dict(eye=(0, 40, 6), target=(0, 5, 0)),
            dict(eye=(30, 8, 0), target=(0, 5, 0)), dict(eye=(14, 14, 24), target=(0, 5, 0))]
    W, H = 640, 480
    sheet = Image.new("RGB", (W * 2, H * 2))
    for i, cam in enumerate(cams):
        sheet.paste(render(parts + (hparts if i == 0 else []), W=W, H=H, fov=40, **cam), ((i % 2) * W, (i // 2) * H))
    sheet.save(os.path.join(os.environ.get("SHEET_DIR", out), NAME + "_sheet.png"))
    if "--gif" in sys.argv:
        frames = []
        for name, n, loops in (("idle", 24, 1), ("walk", 12, 2), ("gallop", 8, 4)):
            anim = next(a for a in m["animations"] if a["name"] == name)
            for _ in range(loops):
                for k in range(n):
                    ps = S.posed(m, anim, anim["length"] * k / n)
                    im = Image.new("RGB", (880, 360))
                    im.paste(render(ps, W=440, H=360, fov=40, eye=(0, 10, -34), target=(0, 6, 0)), (0, 0))
                    im.paste(render(ps, W=440, H=360, fov=40, eye=(-24, 18, -26), target=(0, 6, 0)), (440, 0))
                    frames.append(A.label(im, [name] * 2))
        A.gif(os.path.join(os.environ.get("SHEET_DIR", out), NAME + "_anims.gif"), frames, fps=20)


if __name__ == "__main__":
    main(*[a for a in sys.argv[1:] if not a.startswith("--")])
