"""Hawkmoth: a World 2 Woodland Maze animal (QM, Oct 13; Epic, flies like the Crystal Phoenix).
A chunky, fuzzy hawkmoth: a torpedo body (brown fur, a pale fluffy collar behind the head,
two dark stripes down the back), an abdomen ringed in autumn orange and black that tapers to a
fanned tail tuft, big white googly plate eyes, a curled proboscis under the chin, two thick
hooked antennae and six thin legs it stands on. Long, narrow forewings swept back like a jet
(tan with dark diagonal bands, a cream leading edge, dark tips) over small autumn-orange
hindwings with a black border.

Run: python3 tools/hawkmoth.py [out_dir]

Phase 1 (model only, no animations yet). Built in Blockbench's ZYX Euler order; every bone
rests at 0 (wing sweep and dihedral baked into the cubes).
Bones: root (the thorax) -> neck (head, eyes, antennae, proboscis); root -> Abdomen;
root -> WingFL, WingFR (forewings), WingBL, WingBR (hindwings).
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
NAME = "Hawkmoth"
MODEL = os.path.join(ROOT, "designs", "woodland", NAME + ".bbmodel")

COLORS = {"fur": (151, 89, 57),         # woodland floor brown #975939
          "furdark": (98, 58, 38),
          "collar": (236, 206, 160),    # pale fluffy collar
          "orange": (242, 109, 57),     # autumn orange #F26D39
          "black": (30, 24, 26),
          "wing": (196, 150, 98),       # tan forewing
          "band": (110, 64, 40),        # dark wing bands and tips
          "cream": (250, 234, 196),
          "white": (255, 255, 255), "pupil": (16, 16, 20)}
TEX = {n: i for i, n in enumerate(COLORS)}
box = AB.box
R = AB.axis_rot

Y0 = 3.4  # the thorax's centre: the legs reach the ground


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
    # thorax: a fat furry block, a tuft on top, two dark stripes down the back
    put(root, [box("Thorax", (0, y0, 0), (4.2, 3.6, 4.6), TEX["fur"]),
               box("ThoraxTop", (0, y0 + 1.95, 0.3), (3.2, 0.5, 3.6), TEX["fur"])])
    for s in (-1, 1):
        put(root, [box(f"Stripe{'LR'[s > 0]}", (s * 0.85, y0 + 2.25, 0.3), (0.5, 0.2, 3.2), TEX["furdark"])])
    # fluffy pale collar between head and thorax
    put(root, [box("Collar", (0, y0 + 0.15, -2.65), (4.5, 3.8, 1.0), TEX["collar"])])

    # head: googly eyes on the front corners, hooked antennae, a curled proboscis
    neck = add_group("neck", (0, y0, -3.1), root)
    hz = -4.35
    put(neck, [box("Head", (0, y0 + 0.1, hz), (3.4, 3.1, 2.4), TEX["fur"])])
    for s in (-1, 1):
        n = "LR"[s > 0]
        put(neck, [box(f"Eye{n}", (s * 0.85, y0 + 0.4, hz - 1.25), (1.5, 1.7, 0.1), TEX["white"]),
                   box(f"Pupil{n}", (s * 0.9, y0 + 0.25, hz - 1.32), (0.75, 0.85, 0.05), TEX["pupil"])])
        # antenna: up, forward and splayed; a short tip hooked outward
        M = R("z", -s * 30) @ R("x", 40)
        d = M @ np.array([0, 1.0, 0])
        base = np.array([s * 0.9, y0 + 1.6, hz - 0.3])
        L = 3.0
        Mt = R("z", -s * 80) @ R("x", 40)
        dt = Mt @ np.array([0, 1.0, 0])
        put(neck, [box(f"Antenna{n}", base + d * L / 2, (0.7, L, 0.7), TEX["cream"], M),
                   box(f"AntennaHook{n}", base + d * (L - 0.2) + dt * 0.6, (0.6, 1.4, 0.6), TEX["band"], Mt)])
    # proboscis curled into a loop under the chin
    pz = hz - 0.7
    put(neck, [box("Proboscis1", (0, y0 - 1.75, pz - 0.3), (0.4, 1.2, 0.4), TEX["orange"]),
               box("Proboscis2", (0, y0 - 2.45, pz + 0.2), (0.4, 0.4, 1.4), TEX["orange"]),
               box("Proboscis3", (0, y0 - 2.05, pz + 0.75), (0.4, 0.8, 0.4), TEX["orange"])])

    # abdomen: long tapering segments, each with an orange ring and a black ring, a fanned tail tuft
    abd = add_group("Abdomen", (0, y0, 2.2), root)
    parts, z = [], 2.2
    for k, (w, L) in enumerate(((3.2, 2.2), (2.9, 2.1), (2.5, 2.0), (2.0, 1.8))):
        cy = y0 - 0.15 - 0.2 * k
        parts += [box(f"Abdomen{k + 1}", (0, cy, z + L / 2), (w, w * 0.92, L + 0.05), TEX["fur"]),
                  box(f"Ring{k + 1}", (0, cy, z + L - 0.55), (w + 0.2, w * 0.92 + 0.2, 0.5), TEX["orange"]),
                  box(f"BlackRing{k + 1}", (0, cy, z + L - 0.15), (w + 0.16, w * 0.92 + 0.16, 0.3), TEX["black"])]
        z += L
    cy = y0 - 0.95
    parts += [box("Tuft", (0, cy, z + 0.6), (2.4, 1.2, 1.2), TEX["furdark"]),
              box("TuftTip", (0, cy, z + 1.4), (3.0, 0.9, 0.6), TEX["orange"])]
    put(abd, parts)

    # six thin legs splayed out to the ground
    for s in (-1, 1):
        for k, zz in enumerate((-1.4, 0.0, 1.4)):
            M = R("z", s * 30) @ R("x", -20 + 20 * k)
            d = M @ np.array([0, -1.0, 0])
            base = np.array([s * 1.5, y0 - 1.6, zz])
            put(root, [box(f"Leg{'LR'[s > 0]}{k + 1}", base + d * 1.25, (0.35, 2.5, 0.35), TEX["furdark"], M)])

    # wings: (name, pivot z, y, sweep deg, dihedral deg, pieces as (x, z, w, d, colour, thick) in the
    # wing's own frame: x out along the span from the root, z back across the chord)
    fore = [(3.5, 0.0, 7.0, 5.0, "wing", 0.5), (8.8, -0.7, 3.8, 3.6, "wing", 0.5),
            (11.4, -1.2, 1.4, 2.6, "band", 0.6),
            (5.4, 0.0, 1.0, 5.0, "band", 0.65), (9.2, -0.7, 0.9, 3.6, "band", 0.65),
            (6.0, -2.3, 11.6, 0.6, "cream", 0.62)]
    hind = [(3.2, 0.0, 6.4, 4.2, "orange", 0.5), (6.8, 0.0, 1.0, 3.8, "black", 0.55),
            (3.2, 2.05, 6.4, 0.5, "black", 0.55)]
    for wname, pieces, pz, py, sweep, dih in (("WingF", fore, -0.4, 1.1, 22, 12),
                                               ("WingB", hind, 1.6, 0.6, 45, 8)):
        for s in (-1, 1):
            n = "LR"[s > 0]
            pivot = np.array([s * 1.9, y0 + py, pz])
            node = add_group(wname + n, pivot, root)
            M = R("z", s * dih) @ R("y", -s * sweep)
            ps = []
            for k, (x, zz, w, dd, col, th) in enumerate(pieces):
                c = pivot + M @ np.array([s * x, 0, zz])
                ps.append(box(f"{wname}{n}{k + 1}", c, (w, th, dd), TEX[col], M))
            put(node, ps)

    model = json.load(open(os.path.join(ROOT, "designs", "desert", "Snake.bbmodel")))
    model.update(name=NAME, elements=elements, groups=groups, outliner=[root], animations=[],
                 textures=[S.solid_texture(n, c) for n, c in COLORS.items()])
    model.setdefault("meta", {})["format_version"] = "5.0"
    return model


def floor(model):
    """Shift so the lowest point (the feet) sits on y = 0."""
    lo = min(q[:, 1].min() for p in S.posed(model) for q in p.polys)
    d = -lo * S.BB
    for e in model["elements"]:
        for k in ("from", "to", "origin"):
            if k in e:
                e[k][1] = round(e[k][1] + d, 4)
    for g in model["groups"]:
        g["origin"][1] = round(g["origin"][1] + d, 4)
    return -lo


def light_bg(im, bg=(238, 240, 236)):
    out = Image.new("RGB", im.size, bg)
    out.paste(im, (0, 0), im)
    return out


def main(out="/mnt/project-files/world2/woodland"):
    renders = os.path.join(out, "renders")
    os.makedirs(renders, exist_ok=True)
    os.makedirs(os.path.dirname(MODEL), exist_ok=True)
    m = build()
    shift = floor(m)
    for path in (MODEL, os.path.join(out, NAME + ".bbmodel")):
        with open(path, "w") as f:
            json.dump(m, f, separators=(",", ":"))
    parts = S.posed(m)
    P = np.concatenate([q for p in parts for q in p.polys])
    print("elements", len(m["elements"]), "shift", round(shift, 3), "bounds", P.min(0).round(1), P.max(0).round(1))
    # the 3/4 front view on a plain light background
    light_bg(render(parts, W=1100, H=900, fov=32, eye=(-24, 24, -30), target=(0.5, 3.2, 2.5), transparent=True)).save(
        os.path.join(renders, NAME + ".png"))
    # a check sheet: next to the Horse, front, top, side
    from horse_rig import pose
    hparts = pose(A.qm_horse("A"), None, 0)
    for p in hparts:
        p.polys = [q + np.array([18, 0, -6]) for q in p.polys]
    cams = [dict(eye=(-30, 20, -36), target=(4, 3, 0)), dict(eye=(0, 8, -40), target=(0, 3, 0)),
            dict(eye=(0, 46, 8), target=(0, 3, 0)), dict(eye=(36, 8, 2), target=(0, 3, 0))]
    Wd, Ht = 640, 520
    sheet = Image.new("RGB", (Wd * 2, Ht * 2))
    for i, cam in enumerate(cams):
        sheet.paste(render(parts + (hparts if i == 0 else []), W=Wd, H=Ht, fov=40, **cam), ((i % 2) * Wd, (i // 2) * Ht))
    sheet.save(os.path.join(out, NAME + "_sheet.png"))


if __name__ == "__main__":
    main(*sys.argv[1:])
