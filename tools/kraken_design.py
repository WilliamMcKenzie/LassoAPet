"""The Kraken (Legendary, Ocean), from QM's reference: a squid-like head under a
maroon cap, a tapering funnel, and eight banded tentacles splayed out on the
sea floor with their tips curling up. You ride on top of its cap.

Run: python3 tools/kraken_design.py [out_dir]

Bones: root (head and cap, where you sit) -> neck (the funnel; the lasso loops
round it) -> Arm1..Arm8 (each turned about Y to its direction at rest) ->
T<i>a..T<i>d (the tentacle's segments, each pitched about X at rest so the
tentacle drops to the floor, runs along it and curls up). Every tentacle is
built along -Z (outward) before its Arm turns it, so +X on a segment lifts it.

  idle    tentacles ripple slowly, each a little out of step; the body breathes
  walk    a crawl: alternate tentacles lift and reach, the body bobs
  gallop  the run: every tentacle pulls in and kicks out together, the body
          surges up on each kick
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
MODEL = os.path.join(ROOT, "designs", "ocean", "Kraken.bbmodel")
TAU = 2 * math.pi

COLORS = {"navy": (58, 76, 128), "band": (40, 52, 94), "cap": (146, 46, 60), "capdark": (104, 30, 46),
          "pink": (238, 122, 152), "white": (255, 255, 255), "black": (20, 20, 24)}
TEX = {n: i for i, n in enumerate(COLORS)}

ARMS = 8
YAW0 = 22.5  # the two front tentacles reach forward either side of the face, as in the reference
BASE_Y = 4.9  # where the tentacles leave the funnel
BASE_R = 1.1  # how far out from the centre they start
# (length, width) of each segment, base to tip, and its rest pitch relative to the one before
SEGS = [(4.0, 2.2), (3.8, 1.8), (3.4, 1.45), (3.0, 1.1)]
PITCH = [-38.0, 18.0, 26.0, 34.0]
OVERLAP = 0.45

HEAD = dict(w=5.4, h=3.8, y0=8.0)  # navy mantle block
CAP = dict(w=6.4, h=4.6, y0=11.8)  # maroon cap over the top of it
SEAT_Y = CAP["y0"] + CAP["h"]


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
    # head and cap
    hw, hh, hy = HEAD["w"], HEAD["h"], HEAD["y0"]
    cw, ch, cy = CAP["w"], CAP["h"], CAP["y0"]
    root = add_group("root", (0, hy + hh / 2, 0), None)
    put(root, [c("Head", (0, hy + hh / 2, 0), (hw, hh, hw), TEX["navy"]),
               c("Cap", (0, cy + ch / 2 + 0.3, 0), (cw, ch - 0.6, cw), TEX["cap"]),
               c("CapRim", (0, cy + 0.3, 0), (cw - 0.2, 0.6, cw - 0.2), TEX["capdark"]),
               c("CapTop", (0, cy + ch + 0.25, 0.3), (cw - 1.6, 0.5, cw - 2.0), TEX["cap"])])
    # a few darker raised patches on the cap, for the reference's mottled top
    for i, (x, y, z, sx, sy, sz) in enumerate([(-1.6, 1.4, -cw / 2, 1.6, 1.2, 0.3), (1.4, 2.6, -cw / 2, 1.4, 1.0, 0.3),
                                               (-cw / 2, 2.2, 1.0, 0.3, 1.2, 1.8), (cw / 2, 1.6, -0.8, 0.3, 1.0, 1.6),
                                               (cw / 2, 3.0, 1.6, 0.3, 0.8, 1.2), (-cw / 2, 3.2, -1.4, 0.3, 0.8, 1.2),
                                               (0.6, ch + 0.5, -0.6, 1.4, 0.3, 1.2), (1.6, 3.3, cw / 2, 1.2, 0.9, 0.3),
                                               (-1.2, 1.9, cw / 2, 1.6, 1.0, 0.3)]):
        put(root, [c(f"CapSpot{i + 1}", (x, cy + y, z), (sx, sy, sz), TEX["capdark"])])
    # googly eyes on the head's sides, toward the front (the Horse's eye, scaled to the head)
    E = 1.5
    for side, sx in (("L", -1), ("R", 1)):
        x = sx * (hw / 2 + 0.03)
        ey, ez = hy + hh * 0.55, -hw / 2 + 0.25 + E / 2
        put(root, [c("Eye" + side, (x, ey, ez), (0.06, E, E), TEX["white"]),
                   c("Pupil" + side, (x + sx * 0.03, ey - E / 2 + 0.1 * E + 0.3 * E, -hw / 2 + 0.25 + 0.025 * E + 0.25 * E),
                     (0.06, 0.6 * E, 0.5 * E), TEX["black"])])

    # the funnel under the head, tapering to where the tentacles leave it
    neck = add_group("neck", (0, hy, 0), root)
    put(neck, [c("Funnel1", (0, hy - 0.6, 0), (4.4, 1.2, 4.4), TEX["band"]),
               c("Funnel2", (0, hy - 1.8, 0), (3.6, 1.4, 3.6), TEX["navy"]),
               c("Funnel3", (0, BASE_Y, 0), (4.0, 1.8, 4.0), TEX["band"])])

    # the tentacles
    for i in range(ARMS):
        yaw = YAW0 + 360.0 * i / ARMS
        arm = add_group(f"Arm{i + 1}", (0, BASE_Y, 0), neck, (0, yaw, 0))
        parent, z = arm, -BASE_R
        for j, ((L, w), p) in enumerate(zip(SEGS, PITCH)):
            name = f"T{i + 1}{'abcd'[j]}"
            node = add_group(name, (0, BASE_Y, z), parent, (p, 0, 0))
            h = w * 0.9
            tex = TEX["navy"] if j % 2 == 0 else TEX["band"]
            parts = [c(name, (0, BASE_Y, z - L / 2 + OVERLAP / 2), (w, h, L + OVERLAP), tex),
                     # a darker ring round the segment's outer end, for the reference's banding
                     c(name + "Ring", (0, BASE_Y, z - L + 0.35), (w + 0.1, h + 0.1, 0.5), TEX["band"] if j % 2 == 0 else TEX["navy"])]
            if j == len(SEGS) - 1:
                parts.append(c(name + "Tip", (0, BASE_Y - 0.05, z - L - 0.15), (w * 0.8, h * 0.75, 0.4), TEX["pink"]))
            else:  # pink suckers along the underside
                parts.append(c(name + "Sucker", (0, BASE_Y - h / 2 - 0.08, z - L / 2), (w * 0.5, 0.16, w * 0.5), TEX["pink"]))
            put(node, parts)
            parent, z = node, z - L

    model = json.load(open(os.path.join(ROOT, "designs", "desert", "Snake.bbmodel")))
    model.update(name="Kraken", elements=elements, groups=groups, outliner=[root], animations=[],
                 textures=[S.solid_texture(n, col) for n, col in COLORS.items()])
    model.setdefault("meta", {})["format_version"] = "5.0"
    return model


def floor(model):
    """Lift or drop everything so the lowest point sits on y = 0; returns the shift (studs)."""
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

def arms(L, fn, n=16):
    """fn(i, j, u) -> (x, y, z) degrees for tentacle i's segment j (j = -1: the Arm's yaw)."""
    out = {}
    for i in range(ARMS):
        out[f"Arm{i + 1}"] = [track(L, lambda u, i=i: fn(i, -1, u), n)]
        for j in range(len(SEGS)):
            out[f"T{i + 1}{'abcd'[j]}"] = [track(L, lambda u, i=i, j=j: fn(i, j, u), n)]
    return out


def animations():
    # position keys are in Blockbench units (0.1 stud)
    L = 3.0

    def idle_arm(i, j, u):
        if j < 0:
            return (0, 3 * math.sin(TAU * u + i), 0)
        return (5 * (0.6 + 0.4 * j) * math.sin(TAU * u - 0.9 * j + i * 1.7), 0, 0)

    idle = {**arms(L, idle_arm, 24),
            "root": [track(L, lambda u: (0, 0, 0), 2), track(L, lambda u: (0, 1.5 * math.sin(TAU * u * 2), 0), 16, "position")],
            "neck": [track(L, lambda u: (2 * math.sin(TAU * u), 0, 2 * math.sin(TAU * u + 1)), 16)]}

    Lw = 1.2

    def walk_arm(i, j, u):
        ph = TAU * u + (math.pi if i % 2 else 0)
        lift = max(0.0, math.sin(ph))
        if j < 0:  # reach forward while lifted, push back on the floor
            side = 1 if math.sin(math.radians(YAW0 + 360.0 * i / ARMS)) > 0 else -1
            return (0, 9 * side * math.cos(ph), 0)
        return ((16, -6, -8, 10)[j] * lift, 0, 0)

    walk = {**arms(Lw, walk_arm),
            "root": [track(Lw, lambda u: (2 * math.sin(TAU * u * 2), 0, 0), 16),
                     track(Lw, lambda u: (0, 2.5 * abs(math.sin(TAU * u)), 0), 16, "position")],
            "neck": [track(Lw, lambda u: (0, 0, 3 * math.sin(TAU * u)), 16)]}

    Lg = 0.7

    def gallop_arm(i, j, u):
        pull = 0.5 + 0.5 * math.sin(TAU * u)  # 1: pulled in under the body, 0: kicked out flat
        if j < 0:
            return (0, 0, 0)
        return ((24, -18, -16, 18)[j] * pull, 0, 0)

    gallop = {**arms(Lg, gallop_arm),
              "root": [track(Lg, lambda u: (-4 * math.sin(TAU * u + 0.6), 0, 0), 16),
                       track(Lg, lambda u: (0, 9 * max(0.0, math.sin(TAU * u + 1.4)), 0), 16, "position")],
              "neck": [track(Lg, lambda u: (3 * math.sin(TAU * u), 0, 0), 16)]}
    return {"idle": (L, idle), "walk": (Lw, walk), "gallop": (Lg, gallop)}


# ---------------------------------------------------------------- preview

def previews(m, out):
    horse = A.qm_horse("A")
    from horse_rig import pose
    import numpy as np
    hparts = pose(horse, None, 0)
    for p in hparts:
        p.polys = [q + np.array([13, 0, 4]) for q in p.polys]
    parts = S.posed(m)
    W, H = 560, 440
    cams = [dict(eye=(0, 9, -34), target=(0, 5, 0)), dict(eye=(-26, 20, -22), target=(0, 4, 0)),
            dict(eye=(-38, 8, 10), target=(4, 5, 2)), dict(eye=(0, 30, 26), target=(0, 5, 0))]
    sheet = Image.new("RGB", (W * 2, H * 2))
    for i, cam in enumerate(cams):
        ps = parts + (hparts if i == 2 else [])
        sheet.paste(render(ps, W=W, H=H, fov=40, **cam), ((i % 2) * W, (i // 2) * H))
    sheet.save(os.path.join(out, "Kraken.png"))
    W, H = 420, 380
    frames = []
    for name, label, n, loops in (("idle", "idle", 30, 1), ("walk", "walk", 20, 2), ("gallop", "run", 12, 3)):
        anim = next(a for a in m["animations"] if a["name"] == name)
        for _ in range(loops):
            for k in range(n):
                ps = S.posed(m, anim, anim["length"] * k / n)
                im = Image.new("RGB", (W * 2, H))
                im.paste(render(ps, W=W, H=H, fov=40, **cams[1]), (0, 0))
                im.paste(render(ps, W=W, H=H, fov=40, **cams[3]), (W, 0))
                frames.append(A.label(im, [label] * 2))
    A.gif(os.path.join(out, "Kraken_anims.gif"), frames, fps=20)


def main(out="/mnt/project-files/animals/ocean"):
    os.makedirs(out, exist_ok=True)
    os.makedirs(os.path.dirname(MODEL), exist_ok=True)
    m = build()
    shift = floor(m)
    groups = {g["name"]: g for g in m["groups"]}
    write_animations(m, groups, animations())
    for path in (MODEL, os.path.join(out, "Kraken.bbmodel")):
        with open(path, "w") as f:
            json.dump(m, f, separators=(",", ":"))
    print("elements", len(m["elements"]), "bones", len(m["groups"]), "shift", round(shift, 3),
          "seat y", round(SEAT_Y + shift, 3), "neck y", round(HEAD["y0"] - 1.2 + shift, 3))
    previews(m, out)


if __name__ == "__main__":
    main(*sys.argv[1:])
