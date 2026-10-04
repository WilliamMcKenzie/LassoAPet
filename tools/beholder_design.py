"""The Beholder (Rare, medium): a round orange-brown blob floating over the floor
with one huge eye on its front (cream rim, white, black pupil with a glint) under
a heavy brow, and six stubby tentacles hanging round its underside, curling out
at the tips like the pixel-art reference QM sent. You sit on top of the blob.

Run: python3 tools/beholder_design.py [out_dir] [--gif]

Bones: root (the blob, where you sit) -> neck (the eye and brow; the lasso loops
round the blob) ; root -> Arm1..Arm6 (each turned about Y to its direction at
rest, 30 + 60 i degrees, so the eye has a clear view between the front two) ->
T<i>a -> T<i>b -> T<i>c (segments, base to tip). Every tentacle is built along
-z before its Arm turns it, so +X on a segment lifts it.

  idle    floats up and down; the tentacles sway in a ripple; the eye looks about
  walk    a glide: leans into it, the tentacles trail and sway
  gallop  the run: the tentacles pulse together like a jellyfish stroke, the
          blob surging up on each one
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
MODEL = os.path.join(ROOT, "designs", "beholder", "Beholder.bbmodel")
TAU = 2 * math.pi

COLORS = {"body": (222, 136, 56), "dark": (160, 92, 34), "light": (246, 186, 112), "rim": (255, 232, 196),
          "white": (255, 255, 255), "black": (20, 20, 24), "brow": (120, 66, 26)}
TEX = {n: i for i, n in enumerate(COLORS)}

W = 9.0  # the blob's width
# the ball's slabs: (height of the slab's centre above or below the middle, width), middle out
LAYERS = [(0.0, 9.0, 3.2), (2.6, 7.6, 2.2), (4.1, 5.0, 1.0)]
LAYER_H = LAYERS[-1][2]
HOVER = 6.6  # the blob's centre above its own origin, before floor() drops the tentacle tips to y = 0
ARMS = 6
BASE_R = 2.2  # where the tentacles leave the underside
BASE_Y = HOVER - 3.2
EYE = 0.8
# (length, thickness) of each tentacle segment, base to tip, and its rest pitch
SEGS = [(2.6, 1.6), (2.3, 1.25), (2.0, 0.95)]
PITCH = [-76.0, 28.0, 40.0]
GAP = 2.4  # the tentacle tips float this far off the floor
OVERLAP = 0.4
SEAT_Y = HOVER + LAYERS[-1][0] + LAYER_H / 2


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
    y0 = HOVER

    # the blob: a ball of stacked octagon slabs (a square and the same square turned 45
    # degrees each), a lighter belly patch underneath, knobbly bumps on the back and sides
    root = add_group("root", (0, y0, 0), None)
    parts = []
    for n, (dy, w, h) in enumerate(LAYERS):
        for sgn in (-1, 1) if dy else (1,):
            yy, tag = y0 + sgn * dy, f"Ball{n}{'ab'[sgn > 0]}"
            parts += [c(tag, (0, yy, 0), (w, h, 0.62 * w), TEX["body"]),
                      c(tag + "X", (0, yy, 0), (0.62 * w, h, w), TEX["body"]),
                      c(tag + "C", (0, yy, 0), (0.86 * w, h, 0.86 * w), TEX["body"])]
    R = LAYERS[0][1] / 2
    parts += [c("Belly", (0, y0 - LAYERS[-1][0] - LAYER_H / 2 - 0.2, 0), (2.6, 0.4, 2.6), TEX["light"]),
              c("BumpBack", (0, y0 + 1.2, R + 0.2), (2.0, 2.0, 0.8), TEX["dark"]),
              c("BumpL", (-R - 0.2, y0 + 1.6, 1.0), (0.8, 1.5, 1.5), TEX["dark"]),
              c("BumpR", (R + 0.2, y0 + 1.6, 1.0), (0.8, 1.5, 1.5), TEX["dark"]),
              c("BumpTop", (1.6, y0 + LAYERS[-1][0] + LAYER_H / 2 + 0.3, 1.6), (1.2, 0.6, 1.2), TEX["dark"])]
    put(root, parts)

    # the eye on the front (-z), tilted up a little so the rider can see it: rim, white, pupil, glint
    neck = add_group("neck", (0, y0, -W / 2), root, (12, 0, 0))
    z = -W / 2
    ey = y0 - 0.2
    e = EYE  # the eye's size against the first draft's 6.8-stud rim

    def eye(name, dz, w, h, d, tex, x=0.0, y=0.0):
        return c(name, (x * e, ey + y * e, z + 0.3 - dz), (w * e, h * e, d), tex)

    put(neck, [eye("EyeRim", 0.3, 6.0, 6.0, 0.8, TEX["rim"]),
               eye("EyeRimY", 0.3, 5.0, 6.8, 0.8, TEX["rim"]),
               eye("EyeRimX", 0.3, 6.8, 5.0, 0.8, TEX["rim"]),
               eye("Eye", 0.6, 4.6, 4.6, 0.8, TEX["white"]),
               eye("EyeY", 0.6, 3.6, 5.4, 0.8, TEX["white"]),
               eye("EyeX", 0.6, 5.4, 3.6, 0.8, TEX["white"]),
               eye("Pupil", 0.95, 2.4, 2.4, 0.6, TEX["black"]),
               eye("PupilY", 0.95, 1.6, 3.0, 0.6, TEX["black"]),
               eye("Glint", 1.3, 0.7, 0.7, 0.2, TEX["white"], -0.6, 0.6),
               # the heavy brow over it
               c("Brow", (0, ey + 3.6 * e + 0.2, z - 0.1), (6.4 * e, 1.1, 1.4), TEX["brow"], -10)])

    # the tentacles
    for i in range(ARMS):
        yaw = 30.0 + 360.0 * i / ARMS
        arm = add_group(f"Arm{i + 1}", (0, BASE_Y, 0), root, (0, yaw, 0))
        parent, zz = arm, -BASE_R
        for j, ((L, t), p) in enumerate(zip(SEGS, PITCH)):
            name = f"T{i + 1}{'abc'[j]}"
            node = add_group(name, (0, BASE_Y, zz), parent, (p, 0, 0))
            tex = TEX["dark"] if j == len(SEGS) - 1 else TEX["body"]
            parts = [c(name, (0, BASE_Y, zz - L / 2 + OVERLAP / 2), (t, t, L + OVERLAP), tex)]
            if j == 0:  # a lighter band where it leaves the blob
                parts.append(c(name + "Band", (0, BASE_Y, zz - 0.5), (t + 0.25, t + 0.25, 0.7), TEX["light"]))
            put(node, parts)
            parent, zz = node, zz - L

    model = json.load(open(os.path.join(ROOT, "designs", "desert", "Snake.bbmodel")))
    model.update(name="Beholder", elements=elements, groups=groups, outliner=[root], animations=[],
                 textures=[S.solid_texture(n, col) for n, col in COLORS.items()])
    model.setdefault("meta", {})["format_version"] = "5.0"
    return model


def floor(model):
    """Shift everything so the lowest point floats GAP studs over y = 0; returns the shift (studs)."""
    lo = min(q[:, 1].min() for p in S.posed(model) for q in p.polys)
    d = (GAP - lo) * S.BB
    for e in model["elements"]:
        for k in ("from", "to", "origin"):
            if k in e:
                e[k][1] = round(e[k][1] + d, 4)
    for g in model["groups"]:
        g["origin"][1] = round(g["origin"][1] + d, 4)
    return GAP - lo


# ---------------------------------------------------------------- animations

def arms(L, fn, n=16):
    """fn(i, j, u) -> (x, y, z) degrees for tentacle i's segment j (j = -1: the Arm itself)."""
    out = {}
    for i in range(ARMS):
        out[f"Arm{i + 1}"] = [track(L, lambda u, i=i: fn(i, -1, u), n)]
        for j in range(len(SEGS)):
            out[f"T{i + 1}{'abc'[j]}"] = [track(L, lambda u, i=i, j=j: fn(i, j, u), n)]
    return out


def animations():
    # position keys are in Blockbench units (0.1 stud)
    L = 3.0

    def idle_arm(i, j, u):
        ph = TAU * u - TAU * i / ARMS  # the ripple runs round the blob
        if j < 0:
            return (0, 0, 0)
        return ((6, 10, 14)[j] * math.sin(ph - 0.9 * j), 0, 0)

    idle = {**arms(L, idle_arm, 24),
            "root": [track(L, lambda u: (0, 6 * math.sin(TAU * u * 2), 0), 16, "position"),
                     track(L, lambda u: (2 * math.sin(TAU * u), 0, 2 * math.sin(TAU * u + 1)), 16)],
            "neck": [track(L, lambda u: (3 * math.sin(TAU * u * 2), 14 * math.sin(TAU * u), 0), 24)]}

    Lw = 1.2

    def walk_arm(i, j, u):
        ph = TAU * u - TAU * i / ARMS
        back = math.cos(math.radians(30.0 + 360.0 * i / ARMS))  # +1 front, -1 back
        if j < 0:
            return (0, 0, 0)
        # trail: front tentacles swing back under (down), back ones stream out (up), all swaying
        return ((-10 * back, 6 * back, 4 * back)[j] + (5, 9, 12)[j] * math.sin(ph - 0.9 * j), 0, 0)

    walk = {**arms(Lw, walk_arm),
            "root": [track(Lw, lambda u: (-6 + 2 * math.sin(TAU * u), 0, 2.5 * math.sin(TAU * u)), 16),
                     track(Lw, lambda u: (0, 5 * math.sin(TAU * u * 2), 0), 16, "position")],
            "neck": [track(Lw, lambda u: (0, 5 * math.sin(TAU * u), 0), 16)]}

    Lg = 0.6

    def gallop_arm(i, j, u):
        # a jellyfish stroke: spread out and up, then snap down and in together
        s = math.sin(TAU * u)
        if j < 0:
            return (0, 0, 0)
        return ((18, -8, -12)[j] * s, 0, 0)

    gallop = {**arms(Lg, gallop_arm),
              "root": [track(Lg, lambda u: (-10 + 3 * math.sin(TAU * u), 0, 0), 16),
                       track(Lg, lambda u: (0, 9 * math.sin(TAU * u - 1.2), 0), 16, "position")],
              "neck": [track(Lg, lambda u: (-3 * math.sin(TAU * u), 0, 0), 16)]}
    return {"idle": (L, idle), "walk": (Lw, walk), "gallop": (Lg, gallop)}


# ---------------------------------------------------------------- preview

CAMS = [dict(eye=(-24, 20, -26), target=(0, 7, 0)), dict(eye=(0, 10, -30), target=(0, 7, 0)),
        dict(eye=(28, 18, 24), target=(0, 6, 0)), dict(eye=(0, 34, 18), target=(0, 6, 0))]


def previews(m, out, gif=True):
    import numpy as np
    from horse_rig import pose
    hparts = pose(A.qm_horse("A"), None, 0)
    for p in hparts:
        p.polys = [q + np.array([14, 0, -2]) for q in p.polys]
    parts = S.posed(m)
    Wd, Ht = 520, 420
    sheet = Image.new("RGB", (Wd * 2, Ht * 2))
    for i, cam in enumerate(CAMS):
        ps = parts + (hparts if i == 2 else [])
        sheet.paste(render(ps, W=Wd, H=Ht, fov=40, **cam), ((i % 2) * Wd, (i // 2) * Ht))
    sheet.save(os.path.join(out, "Beholder.png"))
    if not gif:
        return
    Wd, Ht = 400, 320
    frames = []
    for name, label, n, loops in (("idle", "idle", 24, 1), ("walk", "walk", 12, 2), ("gallop", "run", 8, 4)):
        anim = next(a for a in m["animations"] if a["name"] == name)
        for _ in range(loops):
            for k in range(n):
                ps = S.posed(m, anim, anim["length"] * k / n)
                im = Image.new("RGB", (Wd * 2, Ht))
                im.paste(render(ps, W=Wd, H=Ht, fov=40, **CAMS[0]), (0, 0))
                im.paste(render(ps, W=Wd, H=Ht, fov=40, **CAMS[2]), (Wd, 0))
                frames.append(A.label(im, [label] * 2))
    A.gif(os.path.join(out, "Beholder_anims.gif"), frames, fps=20)


def headshot(m, path):
    im = render(S.posed(m), W=900, H=900, fov=30, transparent=True, eye=(-5, 15, -32), target=(0, 8, 0))
    im = im.crop(im.getbbox())
    side = max(im.size) + 24
    sq = Image.new("RGBA", (side, side))
    sq.paste(im, ((side - im.width) // 2, (side - im.height) // 2))
    sq.resize((512, 512), Image.LANCZOS).save(path)


def main(out="/mnt/project-files/animals/beholder"):
    os.makedirs(out, exist_ok=True)
    os.makedirs(os.path.dirname(MODEL), exist_ok=True)
    m = build()
    shift = floor(m)
    groups = {g["name"]: g for g in m["groups"]}
    write_animations(m, groups, animations())
    for path in (MODEL, os.path.join(out, "Beholder.bbmodel")):
        with open(path, "w") as f:
            json.dump(m, f, separators=(",", ":"))
    print("elements", len(m["elements"]), "bones", len(m["groups"]), "shift", round(shift, 3),
          "seat y", round(SEAT_Y + shift, 3), "centre y", round(HOVER + shift, 3))
    previews(m, out, gif="--gif" in sys.argv)
    headshot(m, os.path.join(ROOT, "assets", "ui", "PetBeholder.png"))


if __name__ == "__main__":
    main(*[a for a in sys.argv[1:] if not a.startswith("--")])
