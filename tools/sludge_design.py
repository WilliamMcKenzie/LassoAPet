"""The Sludge (medium): a stepped olive mound of goo, like the pixel art QM sent (Oct 4).
Four tiers stacked like a ziggurat with a brown nub on top, a wide black mouth with a
yellow lip low on the front, three black eyes with yellow under them, and two brown
twig-arms poking out of each side. It sludges along the ground: no legs, the tiers
slide over each other in a wave from the base up.

Run: python3 tools/sludge_design.py [out_dir] [--gif]

Bones: root (the puddle at the bottom) -> Tier2 -> Tier3 -> neck (the top tier, the
nub and the top eye; you sit on the nub). Arms ArmL1/ArmR1 hang off Tier2, ArmL2/ArmR2
off Tier3, each -> Twig (the bit that points up).

  idle    breathes: the tiers settle and swell in turn, the twigs wave
  walk    the ooze: each tier slides forward a beat after the one under it
  gallop  the run: the same, faster and bigger, the whole mound surging
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
MODEL = os.path.join(ROOT, "designs", "sludge", "Sludge.bbmodel")
TAU = 2 * math.pi

COLORS = {"body": (126, 112, 38), "light": (150, 134, 52), "brown": (112, 58, 26), "dark": (78, 38, 20),
          "yellow": (226, 196, 104), "black": (22, 18, 14)}
TEX = {n: i for i, n in enumerate(COLORS)}

# (width, height, depth, colour) of each tier, bottom up; each sinks SINK into the one below
TIERS = [(11.0, 1.6, 10.0, "body"), (9.0, 2.4, 8.4, "body"), (7.0, 2.4, 6.6, "light"), (5.0, 2.2, 4.8, "body")]
NUB = (3.0, 1.4, 3.0)
SINK = 0.3
EYE = 0.9


def tier_y():
    """Bottom y of each tier and of the nub."""
    ys, y = [], 0.0
    for _, h, _, _ in TIERS:
        ys.append(y)
        y += h - SINK
    return ys, y


YS, NUB_Y = tier_y()
SEAT_Y = NUB_Y + NUB[1]


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
    nodes = []
    for i, ((w, h, d, col), y) in enumerate(zip(TIERS, YS)):
        name = ("root", "Tier2", "Tier3", "neck")[i]
        node = add_group(name, (0, y, 0), nodes[-1] if nodes else None)
        put(node, [c(f"Tier{i + 1}", (0, y + h / 2, 0), (w, h, d), TEX[col])])
        nodes.append(node)
    root, t2, t3, top = nodes

    # the nub on top, where you sit
    put(top, [c("Nub", (0, NUB_Y + NUB[1] / 2, 0), NUB, TEX["brown"])])

    def eye(node, name, x, y, z):
        put(node, [c(name, (x, y, z - 0.15), (EYE, EYE, 0.5), TEX["black"]),
                   c(name + "Glint", (x, y - EYE / 2 - 0.25, z - 0.1), (EYE, 0.5, 0.4), TEX["yellow"])])

    # eyes: one on the top tier, two on the third
    w4, h4, d4, _ = TIERS[3]
    eye(top, "EyeTop", 0, YS[3] + h4 * 0.62, -d4 / 2)
    w3, h3, d3, _ = TIERS[2]
    for sx in (-1, 1):
        eye(t3, "Eye" + ("L" if sx < 0 else "R"), sx * 2.1, YS[2] + h3 * 0.6, -d3 / 2)

    # the mouth: a wide black gape low on the front with a yellow lower lip and a brown brow
    w2, h2, d2, _ = TIERS[1]
    z2 = -d2 / 2
    my = YS[1] + h2 * 0.55
    put(t2, [c("Mouth", (0, my, z2 - 0.1), (5.0, 1.6, 0.4), TEX["black"]),
             c("Lip", (0, my - 0.55, z2 - 0.2), (3.4, 0.5, 0.4), TEX["yellow"]),
             c("Brow", (0, my + 1.0, z2 - 0.15), (5.8, 0.6, 0.5), TEX["brown"])])

    # twig arms: out of the side, then up at the tip
    for node, (w, h, d, _), y, k in ((t2, TIERS[1], YS[1], 1), (t3, TIERS[2], YS[2], 2)):
        ay = y + h * 0.55
        for sx in (-1, 1):
            side = "L" if sx < 0 else "R"
            x0 = sx * w / 2
            arm = add_group(f"Arm{side}{k}", (x0, ay, 0), node)
            L = 1.8
            put(arm, [c(f"Arm{side}{k}", (x0 + sx * (L / 2 - 0.2), ay, 0), (L + 0.4, 0.7, 0.7), TEX["brown"])])
            tip = x0 + sx * (L - 0.1)
            twig = add_group(f"Twig{side}{k}", (tip, ay, 0), arm)
            put(twig, [c(f"Twig{side}{k}", (tip, ay + 0.75, 0), (0.7, 1.5, 0.7), TEX["dark"])])

    model = json.load(open(os.path.join(ROOT, "designs", "desert", "Snake.bbmodel")))
    model.update(name="Sludge", elements=elements, groups=groups, outliner=[root], animations=[],
                 textures=[S.solid_texture(n, col) for n, col in COLORS.items()])
    model.setdefault("meta", {})["format_version"] = "5.0"
    return model


# ---------------------------------------------------------------- animations

TIER_BONES = ["root", "Tier2", "Tier3", "neck"]
ARMS = [f"Arm{s}{k}" for k in (1, 2) for s in "LR"]


def animations():
    # position keys are in Blockbench units (0.1 stud), relative to the parent bone
    def ooze(L, slide, squish, lag, wave, n=16):
        out = {}
        for j, b in enumerate(TIER_BONES):
            # each tier slides forward (-z) a beat after the one below and dips as it catches up
            amp = slide if j else slide * 0.6
            out[b] = [track(L, lambda u, j=j, amp=amp: (0, squish * math.sin(TAU * u - lag * j + 1.2),
                                                        -amp * math.sin(TAU * u - lag * j)), n, "position")]
        for k, a in enumerate(ARMS):
            sx = -1 if "L" in a else 1
            out[a] = [track(L, lambda u, k=k, sx=sx: (0, 0, sx * wave * math.sin(TAU * u - 0.7 * k)), n)]
            out["Twig" + a[3:]] = [track(L, lambda u, k=k, sx=sx: (0, 0, sx * wave * 1.2 * math.sin(TAU * u - 0.7 * k - 0.8)), n)]
        return out

    L = 3.0
    idle = ooze(L, 1.5, 2.5, 0.9, 12, 24)
    Lw = 1.4
    walk = ooze(Lw, 6.0, 3.0, 1.1, 18)
    walk["root"].append(track(Lw, lambda u: (0, 3 * math.sin(TAU * u), 0), 16))
    Lg = 0.7
    gallop = ooze(Lg, 10.0, 5.0, 1.2, 26)
    gallop["root"].append(track(Lg, lambda u: (-3 + 3 * math.sin(TAU * u), 0, 0), 16))
    return {"idle": (L, idle), "walk": (Lw, walk), "gallop": (Lg, gallop)}


# ---------------------------------------------------------------- preview

CAMS = [dict(eye=(-24, 18, -26), target=(0, 4.5, 0)), dict(eye=(0, 7, -30), target=(0, 4.5, 0)),
        dict(eye=(28, 16, 24), target=(0, 4, 0)), dict(eye=(0, 34, 18), target=(0, 4, 0))]


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
    sheet.save(os.path.join(out, "Sludge.png"))
    if not gif:
        return
    Wd, Ht = 400, 320
    frames = []
    for name, label, n, loops in (("idle", "idle", 24, 1), ("walk", "walk", 14, 2), ("gallop", "run", 8, 4)):
        anim = next(a for a in m["animations"] if a["name"] == name)
        for _ in range(loops):
            for k in range(n):
                ps = S.posed(m, anim, anim["length"] * k / n)
                im = Image.new("RGB", (Wd * 2, Ht))
                im.paste(render(ps, W=Wd, H=Ht, fov=40, **CAMS[0]), (0, 0))
                im.paste(render(ps, W=Wd, H=Ht, fov=40, **dict(eye=(30, 8, 0), target=(0, 4.5, 0))), (Wd, 0))
                frames.append(A.label(im, [label] * 2))
    A.gif(os.path.join(out, "Sludge_anims.gif"), frames, fps=20)


def main(out="/mnt/project-files/animals/sludge"):
    os.makedirs(out, exist_ok=True)
    os.makedirs(os.path.dirname(MODEL), exist_ok=True)
    m = build()
    groups = {g["name"]: g for g in m["groups"]}
    write_animations(m, groups, animations())
    for path in (MODEL, os.path.join(out, "Sludge.bbmodel")):
        with open(path, "w") as f:
            json.dump(m, f, separators=(",", ":"))
    print("elements", len(m["elements"]), "bones", len(m["groups"]), "seat y", round(SEAT_Y, 3))
    previews(m, out, gif="--gif" in sys.argv)


if __name__ == "__main__":
    main(*[a for a in sys.argv[1:] if not a.startswith("--")])
