"""The Whale (Ocean), from QM's reference (Oct 2): a sperm whale with a huge
square head, a pale ridged underside, swirl glyphs on its sides and a long
tapering tail. QM: blue/cyan instead of the reference's purple and gold.

Run: python3 tools/whale_design.py [out_dir]

Superseded (Oct 2): designs/ocean/Whale.bbmodel is now QM's own edit of this draft
(no jaw, fewer glyphs; QM's animations). Don't rerun this script: it would overwrite
QM's file.

Rest pose (every bone at 0): level, belly down, facing -z, every cube
axis-aligned. Bones: root (the body, where you sit) -> neck (the head; the
lasso loops round it) -> Jaw; root -> FinL / FinR; root -> Tail1 -> Tail2 ->
Flukes. The tail swims up and down (X rotations).

  idle    floats, bobbing gently; the tail sways slowly
  walk    an easy swim: a wave runs down the tail, the fins paddle
  gallop  the dash: big tail beats, the body surges and pitches
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
MODEL = os.path.join(ROOT, "designs", "ocean", "Whale.bbmodel")
TAU = 2 * math.pi

COLORS = {"blue": (40, 116, 206), "deep": (26, 78, 158), "speck": (84, 170, 232), "cyan": (96, 226, 246),
          "belly": (214, 244, 250), "groove": (150, 210, 232), "white": (255, 255, 255), "black": (20, 20, 24)}
TEX = {n: i for i, n in enumerate(COLORS)}

# (bone, z front, z back, width, height, bottom y)
HEAD = ("neck", -11.0, -2.0, 7.0, 6.8, 1.0)
BODY = ("root", -2.4, 5.0, 6.0, 5.6, 1.0)
TAIL = [("Tail1", 5.0, 9.4, 4.4, 4.0, 1.8), ("Tail2", 9.4, 13.0, 3.0, 2.8, 2.4)]
OVERLAP = 0.5
BELLY_H = 2.2  # the pale ridged underside on the head and body
SEAT_Y = BODY[5] + BODY[4]

# a square spiral glyph, like the reference's: 1 = raised cyan pixel (row 0 at the top)
GLYPH = ["1111111",
         "1000001",
         "1011101",
         "1010101",
         "1010001",
         "1011111"]


def build():
    elements, groups = [], []

    def add_group(name, pivot, parent, rot=(0, 0, 0)):
        g = S.group(name, pivot)
        g["rotation"] = [round(r, 3) for r in rot]
        groups.append(g)
        node = {"uuid": g["uuid"], "isOpen": True, "children": []}
        if parent is not None:
            parent["children"].append(node)
        return node

    def put(node, parts):
        for e in parts:
            elements.append(e)
            node["children"].append(e["uuid"])

    c = S.cube

    def hull(node, name, z0, z1, w, h, y0, belly=0.0, grooves=False):
        """A body block, dark blue on top; the bottom `belly` studs pale, ridged with
        raised grooves down the sides like the reference's underside."""
        L = z1 - z0
        zc = (z0 + z1) / 2
        parts = [c(name, (0, y0 + belly + (h - belly) / 2, zc), (w, h - belly, L), TEX["blue"])]
        if belly:
            parts.append(c(name + "Belly", (0, y0 + belly / 2, zc), (w - 0.2, belly, L - 0.1), TEX["belly"]))
            if grooves:
                n = int(L / 0.9)
                for k in range(n):
                    z = z0 + 0.45 + k * L / n
                    hk = belly * (0.55 + 0.35 * ((k * 7) % 3) / 2)  # ragged tops, like the reference
                    for sx in (-1, 1):
                        parts.append(c(f"{name}Groove{k}{'LR'[sx > 0]}", (sx * (w / 2 - 0.05), y0 + hk / 2, z),
                                       (0.2, hk, 0.4), TEX["groove"]))
                    parts.append(c(f"{name}GrooveU{k}", (0, y0 - 0.05, z), (w - 0.8, 0.2, 0.4), TEX["groove"]))
        put(node, parts)

    def glyph(node, name, sx, y_top, z_front, px=0.42):
        """The spiral glyph raised off one side (sx = -1 left, 1 right)."""
        x = sx * 0.0  # placeholder, set by caller through offset
        return x

    def glyph_at(node, name, x_face, sx, y_top, z_front, px=0.42):
        parts = []
        for r, row in enumerate(GLYPH):
            k = 0
            while k < len(row):
                if row[k] == "1":
                    e = k
                    while e < len(row) and row[e] == "1":
                        e += 1
                    # runs along z; the glyph reads front to back
                    z = z_front + (k + e) / 2 * px
                    parts.append(c(f"{name}{r}{k}", (x_face + sx * 0.08, y_top - (r + 0.5) * px, z),
                                   (0.16, px, (e - k) * px), TEX["cyan"]))
                    k = e
                else:
                    k += 1
        put(node, parts)

    # body (root): where you sit
    _, z0, z1, w, h, y0 = BODY
    root = add_group("root", (0, y0 + h / 2, 0), None)
    hull(root, "Body", z0, z1, w, h, y0, BELLY_H, grooves=False)
    # specks and a line of dashes along the back
    for i, (x, y, z) in enumerate([(-1, 4.6, -1.2), (1, 3.4, 1.4), (-1, 3.0, 3.2), (1, 5.0, 3.8), (-1, 5.2, 0.6)]):
        put(root, [c(f"Speck{i + 1}", (x * (w / 2 + 0.06), y0 + y - 1.0, z), (0.14, 0.5, 0.5), TEX["speck"])])
    for i, z in enumerate((-1.6, -0.2, 1.2, 2.6, 4.0)):
        put(root, [c(f"Dash{i + 1}", (0, y0 + h + 0.08, z), (0.9, 0.16, 0.5), TEX["cyan"])])
    for sx in (-1, 1):
        glyph_at(root, "BodyGlyph" + "LR"[sx > 0], sx * w / 2, sx, y0 + h - 0.7, z0 + 0.6, px=0.34)

    # head (neck): the big square sperm-whale head, ridged pale underneath
    _, hz0, hz1, hw, hh, hy0 = HEAD
    neck = add_group("neck", (0, hy0 + hh / 2, hz1), root)
    hull(neck, "Head", hz0, hz1 + OVERLAP, hw, hh, hy0, BELLY_H, grooves=True)
    # a raised brow block across the top front, so the head reads as one huge forehead
    put(neck, [c("Brow", (0, hy0 + hh + 0.3, hz0 + 2.4), (hw - 1.0, 0.6, 4.0), TEX["deep"])])
    for sx in (-1, 1):
        glyph_at(neck, "HeadGlyph" + "LR"[sx > 0], sx * hw / 2, sx, hy0 + hh - 0.5, hz0 + 0.6)
    # googly eyes low on the head's sides toward the back, just above the pale (the Horse's eye)
    E = 1.4
    for side, sx in (("L", -1), ("R", 1)):
        x = sx * (hw / 2 + 0.03)
        ey, ez = hy0 + BELLY_H + E / 2 + 0.2, hz1 - 2.0
        put(neck, [c("Eye" + side, (x, ey, ez), (0.06, E, E), TEX["white"]),
                   c("Pupil" + side, (x + sx * 0.03, ey - E / 2 + 0.4 * E, ez - E / 2 + 0.275 * E),
                     (0.06, 0.6 * E, 0.5 * E), TEX["black"])])
    # the narrow lower jaw under the front of the head, on its own bone (it opens)
    jaw = add_group("Jaw", (0, hy0 + 0.2, hz1 - 2.6), neck)
    put(jaw, [c("Jaw", (0, hy0 - 0.4, (hz0 + 1.0 + hz1 - 2.6) / 2), (2.2, 0.8, hz1 - 2.6 - hz0 - 1.0), TEX["belly"]),
              c("JawTip", (0, hy0 - 0.4, hz0 + 0.8), (1.6, 0.7, 0.6), TEX["groove"])])
    for k in range(4):  # little teeth along the jaw's top
        for sx in (-1, 1):
            put(jaw, [c(f"Tooth{k}{'LR'[sx > 0]}", (sx * 0.7, hy0 + 0.15, hz0 + 1.6 + k * 1.3), (0.35, 0.4, 0.35), TEX["white"])])

    # side fins, angled back and down
    for side, sx in (("L", -1), ("R", 1)):
        fin = add_group("Fin" + side, (sx * w / 2, y0 + 1.2, z0 + 1.6), root, (0, 0, 0))
        put(fin, [c("Fin" + side, (sx * (w / 2 + 1.4), y0 + 0.7, z0 + 2.4), (3.0, 0.6, 1.8), TEX["deep"], 0, sx * -25),
                  c("FinTip" + side, (sx * (w / 2 + 2.9), y0 + 0.45, z0 + 3.4), (1.4, 0.5, 1.2), TEX["blue"], 0, sx * -25)])

    # the tail, tapering back to wide flukes
    parent = root
    for i, (name, tz0, tz1, tw, th, ty0) in enumerate(TAIL):
        node = add_group(name, (0, ty0 + th / 2, tz0), parent)
        put(node, [c(name, (0, ty0 + th / 2, (tz0 - OVERLAP + tz1) / 2), (tw, th, tz1 - tz0 + OVERLAP), TEX["blue"]),
                   c(name + "Belly", (0, ty0 + 0.35, (tz0 - OVERLAP + tz1) / 2), (tw - 0.2, 0.7, tz1 - tz0 + OVERLAP - 0.1), TEX["belly"]),
                   c(name + "Ridge", (0, ty0 + th + 0.2, (tz0 + tz1) / 2), (0.7, 0.4, (tz1 - tz0) * 0.6), TEX["deep"])])
        parent = node
    fz = TAIL[-1][2]
    fy = TAIL[-1][5] + TAIL[-1][4] / 2
    flukes = add_group("Flukes", (0, fy, fz), parent)
    put(flukes, [c("FlukeRoot", (0, fy, fz + 0.6), (2.4, 1.4, 1.8), TEX["blue"])])
    for side, sx in (("L", -1), ("R", 1)):
        put(flukes, [c("Fluke" + side, (sx * 2.4, fy, fz + 1.6), (4.0, 0.7, 2.2), TEX["blue"], 0, sx * 22),
                     c("FlukeTip" + side, (sx * 4.6, fy, fz + 2.8), (2.0, 0.6, 1.4), TEX["deep"], 0, sx * 34)])

    model = json.load(open(os.path.join(ROOT, "designs", "desert", "Snake.bbmodel")))
    model.update(name="Whale", elements=elements, groups=groups, outliner=[root], animations=[],
                 textures=[S.solid_texture(n, col) for n, col in COLORS.items()])
    model.setdefault("meta", {})["format_version"] = "5.0"
    return model


def floor(model):
    """Shift everything so the lowest point sits on y = 0; returns the shift (studs)."""
    lo = min(q[:, 1].min() for p in S.posed(model) for q in p.polys)
    d = -lo * S.BB
    for e in model["elements"]:
        for k in ("from", "to", "origin"):
            if k in e:
                e[k][1] = round(e[k][1] + d, 4)
    for g in model["groups"]:
        g["origin"][1] = round(g["origin"][1] + d, 4)
    return -lo


# ---------------------------------------------------------------- animations

def tail(L, amp, lag, n=16, bias=0.0):
    """An up-and-down wave down Tail1 -> Tail2 -> Flukes."""
    return {b: [track(L, lambda u, j=j: (bias + amp[j] * math.sin(TAU * u - lag * (j + 1)), 0, 0), n)]
            for j, b in enumerate(("Tail1", "Tail2", "Flukes"))}


def animations():
    L = 3.0
    idle = {**tail(L, (4, 6, 10), 0.8),
            "root": [track(L, lambda u: (1.2 * math.sin(TAU * u), 0, 0), 16),
                     track(L, lambda u: (0, 3 * math.sin(TAU * u), 0), 16, "position")],
            "neck": [track(L, lambda u: (-1.0 * math.sin(TAU * u), 0, 0), 16)],
            "Jaw": [track(L, lambda u: (4 * max(0.0, math.sin(TAU * u)), 0, 0), 16)],
            "FinL": [track(L, lambda u: (0, 0, 8 * math.sin(TAU * u)), 16)],
            "FinR": [track(L, lambda u: (0, 0, -8 * math.sin(TAU * u)), 16)]}
    Lw = 1.4
    walk = {**tail(Lw, (10, 16, 24), 0.9),
            "root": [track(Lw, lambda u: (2.5 * math.sin(TAU * u + 1.2), 0, 0), 16),
                     track(Lw, lambda u: (0, 4 * math.sin(TAU * u), 0), 16, "position")],
            "neck": [track(Lw, lambda u: (-2 * math.sin(TAU * u + 1.2), 0, 0), 16)],
            "FinL": [track(Lw, lambda u: (0, 10 * math.sin(TAU * u), 14 * math.sin(TAU * u)), 16)],
            "FinR": [track(Lw, lambda u: (0, -10 * math.sin(TAU * u), -14 * math.sin(TAU * u)), 16)]}
    Lg = 0.75
    gallop = {**tail(Lg, (18, 26, 36), 1.0),
              "root": [track(Lg, lambda u: (5 * math.sin(TAU * u + 1.4), 0, 0), 16),
                       track(Lg, lambda u: (0, 9 * max(0.0, math.sin(TAU * u + 0.4)), 0), 16, "position")],
              "neck": [track(Lg, lambda u: (-3 * math.sin(TAU * u + 1.4), 0, 0), 16)],
              "Jaw": [track(Lg, lambda u: (6, 0, 0), 2)],
              "FinL": [track(Lg, lambda u: (0, 18, 10 + 10 * math.sin(TAU * u)), 16)],
              "FinR": [track(Lg, lambda u: (0, -18, -10 - 10 * math.sin(TAU * u)), 16)]}
    return {"idle": (L, idle), "walk": (Lw, walk), "gallop": (Lg, gallop)}


# ---------------------------------------------------------------- preview

def previews(m, out, gif=True):
    import numpy as np
    from horse_rig import pose
    hparts = pose(A.qm_horse("A"), None, 0)
    for p in hparts:
        p.polys = [q + np.array([13, 0, -4]) for q in p.polys]
    parts = S.posed(m)
    W, H = 560, 440
    cams = [dict(eye=(-30, 18, -30), target=(0, 4, 0)), dict(eye=(-44, 8, 2), target=(0, 4, 1)),
            dict(eye=(30, 20, 30), target=(0, 4, 1)), dict(eye=(0, 46, 22), target=(0, 3, 1))]
    sheet = Image.new("RGB", (W * 2, H * 2))
    for i, cam in enumerate(cams):
        ps = parts + (hparts if i == 1 else [])
        sheet.paste(render(ps, W=W, H=H, fov=40, **cam), ((i % 2) * W, (i // 2) * H))
    sheet.save(os.path.join(out, "Whale.png"))
    if not gif:
        return
    W, H = 420, 340
    frames = []
    for name, label, n, loops in (("idle", "idle", 24, 1), ("walk", "walk", 16, 2), ("gallop", "run", 10, 3)):
        anim = next(a for a in m["animations"] if a["name"] == name)
        for _ in range(loops):
            for k in range(n):
                ps = S.posed(m, anim, anim["length"] * k / n)
                im = Image.new("RGB", (W * 2, H))
                im.paste(render(ps, W=W, H=H, fov=40, **cams[0]), (0, 0))
                im.paste(render(ps, W=W, H=H, fov=40, **cams[1]), (W, 0))
                frames.append(A.label(im, [label] * 2))
    A.gif(os.path.join(out, "Whale_anims.gif"), frames, fps=20)


def main(out="/mnt/project-files/animals/ocean"):
    os.makedirs(out, exist_ok=True)
    os.makedirs(os.path.dirname(MODEL), exist_ok=True)
    m = build()
    shift = floor(m)
    groups = {g["name"]: g for g in m["groups"]}
    write_animations(m, groups, animations())
    for path in (MODEL, os.path.join(out, "Whale.bbmodel")):
        with open(path, "w") as f:
            json.dump(m, f, separators=(",", ":"))
    print("elements", len(m["elements"]), "bones", len(m["groups"]), "shift", round(shift, 3),
          "seat y", round(SEAT_Y + shift, 3))
    previews(m, out, gif="--gif" in sys.argv)


if __name__ == "__main__":
    main(*[a for a in sys.argv[1:] if not a.startswith("--")])
