"""Hawkmoth: a World 2 Woodland Maze animal (QM, Oct 13; Epic, flies like the Crystal Phoenix).
QM, Oct 13: "make it way more epic/badass". A death's-head hawkmoth: a dark charcoal body with a
cream skull raised on its back (black sockets and nose), black eye plates with glowing orange
pupils under angry brows, two thick antennae swept back like horns ending in points, a pair of
spikes on the shoulders, and a long abdomen ringed in autumn orange (#F26D39) and black that ends
in a stinger point. Long, sharp forewings swept back like a jet (dark brown with rust bands and a
black leading edge) ending in pyramid points, with a row of pyramid spikes along the trailing
edge; under them small fiery orange hindwings with a black band and spiked tips.

Run: python3 tools/hawkmoth.py [out_dir]

Phase 1 (model only, no animations yet). Built in Blockbench's ZYX Euler order; every bone
rests at 0 (wing sweep and dihedral baked into the cubes; spikes are pyramid meshes).
Bones: root (the thorax) -> neck (head, eyes, brows, antennae); root -> Abdomen;
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

COLORS = {"fur": (62, 48, 44),          # dark charcoal brown
          "furdark": (32, 26, 28),
          "skull": (246, 228, 182),
          "orange": (242, 109, 57),     # autumn orange #F26D39
          "black": (24, 20, 22),
          "wing": (84, 54, 40),         # dark brown forewing
          "rust": (160, 72, 38),        # forewing bands
          "eye": (20, 16, 18), "glow": (255, 150, 40)}
TEX = {n: i for i, n in enumerate(COLORS)}
box = AB.box
R = AB.axis_rot

Y0 = 3.6  # the thorax's centre: the legs reach the ground


def pyr(name, base, d, wv, L, hw, ht, tex):
    """A pyramid mesh in studs: base rectangle centred on base (half sizes hw along wv, ht across),
    apex L along d."""
    d = np.array(d, float) / np.linalg.norm(d)
    wv = np.array(wv, float)
    wv = wv - d * (wv @ d)
    wv /= np.linalg.norm(wv)
    tv = np.cross(d, wv)
    b = np.array(base, float)
    pts = [b - wv * hw - tv * ht, b + wv * hw - tv * ht, b + wv * hw + tv * ht, b - wv * hw + tv * ht, b + d * L]
    v = {f"v{i}": [round(float(x) * S.BB, 4) for x in q] for i, q in enumerate(pts)}
    faces = {"base": ["v0", "v1", "v2", "v3"], "s0": ["v0", "v1", "v4"], "s1": ["v1", "v2", "v4"],
             "s2": ["v2", "v3", "v4"], "s3": ["v3", "v0", "v4"]}
    return {"name": name, "type": "mesh", "uuid": S.uid(), "color": 0, "origin": [0, 0, 0], "rotation": [0, 0, 0],
            "vertices": v, "faces": {k: {"texture": tex, "vertices": vs, "uv": {q: [0, 0] for q in vs}}
                                     for k, vs in faces.items()}}


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
    # thorax with a raised cream skull on its back: cranium, black sockets and nose, teeth bar
    top = y0 + 1.9
    put(root, [box("Thorax", (0, y0, 0), (4.4, 3.8, 4.8), TEX["fur"]),
               box("Skull", (0, top + 0.15, -0.2), (3.0, 0.3, 2.4), TEX["skull"]),
               box("SkullJaw", (0, top + 0.15, 1.45), (1.8, 0.3, 0.9), TEX["skull"]),
               box("SkullNose", (0, top + 0.32, 0.75), (0.4, 0.1, 0.5), TEX["black"]),
               box("SkullTeeth", (0, top + 0.32, 1.55), (1.4, 0.1, 0.2), TEX["black"])])
    for s in (-1, 1):
        n = "LR"[s > 0]
        put(root, [box(f"Socket{n}", (s * 0.7, top + 0.34, -0.45), (0.8, 0.12, 0.8), TEX["black"])])
    # dark collar with a spike on each shoulder
    put(root, [box("Collar", (0, y0 + 0.1, -2.7), (4.8, 4.0, 1.0), TEX["furdark"])])
    for s in (-1, 1):
        n = "LR"[s > 0]
        put(root, [pyr(f"ShoulderSpike{n}", (s * 1.7, y0 + 2.05, -2.7), (s * 0.45, 1, 0.35), (1, 0, 0), 1.9, 0.45, 0.45,
                       TEX["black"])])

    # head: black eye plates with glowing pupils under angry brows; horn-like antennae swept back
    neck = add_group("neck", (0, y0, -3.2), root)
    hz = -4.4
    put(neck, [box("Head", (0, y0, hz), (3.4, 3.0, 2.4), TEX["fur"]),
               box("Snout", (0, y0 - 0.95, hz - 1.3), (1.6, 0.8, 0.4), TEX["furdark"])])
    for s in (-1, 1):
        n = "LR"[s > 0]
        put(neck, [box(f"Eye{n}", (s * 0.85, y0 + 0.25, hz - 1.25), (1.4, 1.4, 0.1), TEX["eye"]),
                   box(f"Glow_Pupil{n}", (s * 0.8, y0 + 0.15, hz - 1.32), (0.9, 0.9, 0.05), TEX["glow"]),
                   # brow: slants down toward the middle
                   box(f"Brow{n}", (s * 0.85, y0 + 1.15, hz - 1.35), (1.7, 0.45, 0.4), TEX["black"], R("z", s * 20))])
        M = R("z", -s * 28) @ R("x", -35)  # up, out and swept back
        dv = M @ np.array([0, 1.0, 0])
        base = np.array([s * 1.0, y0 + 1.5, hz - 0.2])
        L = 3.6
        put(neck, [box(f"Antenna{n}", base + dv * L / 2, (0.7, L, 0.7), TEX["furdark"], M),
                   pyr(f"AntennaTip{n}", base + dv * L, dv, M @ np.array([1.0, 0, 0]), 1.3, 0.35, 0.35, TEX["orange"])])

    # abdomen: tapering segments ringed orange and black, a stinger point at the end
    abd = add_group("Abdomen", (0, y0, 2.4), root)
    parts, z = [], 2.4
    for k, (w, L) in enumerate(((3.6, 2.3), (3.2, 2.2), (2.7, 2.1), (2.1, 1.9))):
        cy = y0 - 0.1 - 0.2 * k
        parts += [box(f"Abdomen{k + 1}", (0, cy, z + L / 2), (w, w * 0.92, L + 0.05), TEX["black"]),
                  box(f"Ring{k + 1}", (0, cy, z + L / 2 - 0.2), (w + 0.2, w * 0.92 + 0.2, 1.0), TEX["orange"])]
        z += L
    parts.append(pyr("Stinger", (0, y0 - 0.85, z), (0, -0.15, 1), (1, 0, 0), 2.4, 0.8, 0.75, TEX["black"]))
    put(abd, parts)

    # six thin legs splayed out to the ground
    for s in (-1, 1):
        for k, zz in enumerate((-1.4, 0.0, 1.4)):
            M = R("z", s * 30) @ R("x", -20 + 20 * k)
            d = M @ np.array([0, -1.0, 0])
            base = np.array([s * 1.6, y0 - 1.7, zz])
            put(root, [box(f"Leg{'LR'[s > 0]}{k + 1}", base + d * 1.25, (0.4, 2.5, 0.4), TEX["furdark"], M)])

    # wings: pieces (x, z, w, d, colour, thick) in the wing's own frame (x out along the span from
    # the root, z back across the chord), then pyramid spikes (x, z, dir x, dir z, length, half width)
    fore = [(3.5, 0.0, 7.0, 5.0, "wing", 0.5), (9.0, -0.8, 4.0, 3.4, "wing", 0.5),
            (12.0, -1.4, 2.0, 2.2, "rust", 0.55),
            (5.6, 0.0, 1.0, 5.0, "rust", 0.6), (9.4, -0.8, 0.9, 3.4, "rust", 0.6),
            (6.4, -2.3, 12.8, 0.6, "black", 0.62)]
    fspikes = [(13.0, -1.4, 1, 0, 3.0, 1.1), (3.0, 2.5, 0.25, 1, 2.0, 0.8), (6.5, 2.5, 0.25, 1, 2.0, 0.8),
               (10.0, 0.9, 0.35, 1, 1.6, 0.7)]
    hind = [(3.2, 0.0, 6.4, 4.2, "orange", 0.5), (6.8, 0.0, 1.0, 3.8, "black", 0.55),
            (3.2, 2.05, 6.4, 0.5, "black", 0.55)]
    hspikes = [(7.3, 0.6, 1, 0.3, 2.2, 0.9), (5.0, 2.3, 0.3, 1, 1.6, 0.7)]
    for wname, pieces, spikes, scol, pz, py, sweep, dih in (
            ("WingF", fore, fspikes, "black", -0.4, 1.2, 28, 12),
            ("WingB", hind, hspikes, "black", 1.7, 0.6, 45, 8)):
        for s in (-1, 1):
            n = "LR"[s > 0]
            pivot = np.array([s * 2.1, y0 + py, pz])
            node = add_group(wname + n, pivot, root)
            M = R("z", s * dih) @ R("y", -s * sweep)
            ps = []
            for k, (x, zz, w, dd, col, th) in enumerate(pieces):
                c = pivot + M @ np.array([s * x, 0, zz])
                ps.append(box(f"{wname}{n}{k + 1}", c, (w, th, dd), TEX[col], M))
            for k, (x, zz, dx, dz, L, hw) in enumerate(spikes):
                c = pivot + M @ np.array([s * x, 0, zz])
                dv = M @ np.array([s * dx, 0, dz])
                wv = M @ np.array([-dz * s, 0, dx])  # in the wing plane, across the spike
                ps.append(pyr(f"{wname}{n}Spike{k + 1}", c, dv, wv, L, hw, 0.25, TEX[scol]))
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
    light_bg(render(parts, W=1100, H=900, fov=36, eye=(-24, 24, -30), target=(1.5, 3.2, 3), transparent=True)).save(
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
