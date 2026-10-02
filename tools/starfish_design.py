"""The Starfish (Common, Ocean, small): a chunky orange five-armed star with
yellow bumps down each arm, a pale underside, the tips curling up a little, and
a raised hump in the middle with the Horse's googly eyes looking forward. You
sit on the hump.

Run: python3 tools/starfish_design.py [out_dir] [--gif]

Rest pose: flat on the floor, Arm1 and Arm5 reaching forward either side of the
face, Arm3 straight back, every 72 degrees round. Bones: root (the middle, where you sit) -> neck (the hump with
the eyes; the lasso loops round it); root -> Arm1..Arm5 (each turned about Y to
its direction at rest) -> A<i>a -> A<i>b -> A<i>c (the arm's segments, base to
tip). Every arm is built along -z before its Arm turns it, so +X on a segment
lifts it.

  idle    a slow ripple runs round the arms, each tip curling up and down;
          the hump looks about
  walk    a scuttle: arms lift and paddle in turn, the body bobs and rocks
  gallop  the run: all five arms flap up together and slap down, the body
          hops on each slap
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
MODEL = os.path.join(ROOT, "designs", "ocean", "Starfish.bbmodel")
TAU = 2 * math.pi

COLORS = {"orange": (255, 128, 64), "deep": (232, 88, 52), "bump": (255, 214, 96), "belly": (255, 200, 156),
          "white": (255, 255, 255), "black": (20, 20, 24)}
TEX = {n: i for i, n in enumerate(COLORS)}

ARMS = 5
BELLY = 0.35  # the pale underside under every block
BODY = dict(w=4.4, h=1.6)  # the middle
HUMP = dict(w=3.0, h=1.3)  # the raised hump on top, with the eyes
BASE_R = 1.6  # where the arms leave the middle
# (length, width, height) of each arm segment, base to tip, and its rest pitch
SEGS = [(2.4, 2.6, 1.5), (2.2, 1.9, 1.2), (1.8, 1.2, 0.9)]
PITCH = [0.0, 4.0, 12.0]
OVERLAP = 0.4
SEAT_Y = BODY["h"] + HUMP["h"]


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

    def slab(name, center, size, tex, ry=0.0):
        """A block with the pale underside showing under it."""
        x, y, z = center
        w, h, d = size
        return [c(name, (x, y + BELLY / 2, z), (w, h - BELLY, d), tex, 0, ry),
                c(name + "Belly", (x, y - (h - BELLY) / 2, z), (w - 0.15, BELLY, d - 0.15), TEX["belly"], 0, ry)]

    # the middle: a square and the same square turned 45 degrees, so it reads round
    bw, bh = BODY["w"], BODY["h"]
    root = add_group("root", (0, bh / 2, 0), None)
    put(root, slab("Body", (0, bh / 2, 0), (bw, bh, bw), TEX["orange"]) +
        slab("Body45", (0, bh / 2, 0), (bw - 0.2, bh, bw - 0.2), TEX["orange"], 45))

    # the hump on top, the eyes on its front (the Horse's eye, facing forward)
    hw, hh = HUMP["w"], HUMP["h"]
    neck = add_group("neck", (0, bh, 0), root)
    put(neck, [c("Hump", (0, bh + hh / 2, 0), (hw, hh, hw), TEX["orange"]),
               c("HumpTop", (0, bh + hh + 0.1, 0.2), (hw - 1.0, 0.2, hw - 1.2), TEX["bump"])])
    E = 1.0
    for side, sx in (("L", -1), ("R", 1)):
        x, y, z = sx * 0.72, bh + hh / 2 + 0.05, -hw / 2 - 0.03
        put(neck, [c("Eye" + side, (x, y, z), (E, E, 0.06), TEX["white"]),
                   c("Pupil" + side, (x - sx * 0.1, y - 0.1, z - 0.03), (0.5 * E, 0.6 * E, 0.06), TEX["black"])])

    # the arms
    for i in range(ARMS):
        yaw = 36.0 + 360.0 * i / ARMS
        arm = add_group(f"Arm{i + 1}", (0, bh / 2, 0), root, (0, yaw, 0))
        parent, z = arm, -BASE_R
        for j, ((L, w, h), p) in enumerate(zip(SEGS, PITCH)):
            name = f"A{i + 1}{'abc'[j]}"
            node = add_group(name, (0, h / 2, z), parent, (p, 0, 0))
            zc = z - L / 2 + OVERLAP / 2
            parts = slab(name, (0, h / 2, zc), (w, h, L + OVERLAP), TEX["orange"])
            # a bump down the middle of the top, and a darker tip at the end
            parts.append(c(name + "Bump", (0, h + 0.1, z - L / 2), (0.55 * w, 0.2, 0.45 * L), TEX["bump"]))
            if j == len(SEGS) - 1:
                parts.append(c(name + "Tip", (0, h / 2 + 0.05, z - L - 0.2), (w * 0.7, h * 0.7, 0.4), TEX["deep"]))
            put(node, parts)
            parent, z = node, z - L

    model = json.load(open(os.path.join(ROOT, "designs", "desert", "Snake.bbmodel")))
    model.update(name="Starfish", elements=elements, groups=groups, outliner=[root], animations=[],
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

def arms(L, fn, n=16):
    """fn(i, j, u) -> (x, y, z) degrees for arm i's segment j (j = -1: the Arm itself)."""
    out = {}
    for i in range(ARMS):
        out[f"Arm{i + 1}"] = [track(L, lambda u, i=i: fn(i, -1, u), n)]
        for j in range(len(SEGS)):
            out[f"A{i + 1}{'abc'[j]}"] = [track(L, lambda u, i=i, j=j: fn(i, j, u), n)]
    return out


def animations():
    # position keys are in Blockbench units (0.1 stud)
    L = 3.0

    def idle_arm(i, j, u):
        ph = TAU * u - TAU * i / ARMS  # the ripple runs round the star
        if j < 0:
            return (0, 0, 0)
        curl = 0.5 + 0.5 * math.sin(ph - 0.8 * j)
        return ((3, 6, 12)[j] * curl, 0, 0)

    idle = {**arms(L, idle_arm, 24),
            "root": [track(L, lambda u: (0, 1.2 * max(0.0, math.sin(TAU * u * 2)), 0), 16, "position")],
            "neck": [track(L, lambda u: (2 * math.sin(TAU * u * 2), 10 * math.sin(TAU * u), 0), 24)]}

    Lw = 0.9

    def walk_arm(i, j, u):
        ph = TAU * u + TAU * i * 2 / ARMS  # every other arm round the star, like a crawl
        lift = max(0.0, math.sin(ph))
        if j < 0:  # sweep sideways while lifted
            return (0, 6 * math.cos(ph), 0)
        return ((14, 8, 10)[j] * lift, 0, 0)

    walk = {**arms(Lw, walk_arm),
            "root": [track(Lw, lambda u: (2.5 * math.sin(TAU * u), 0, 3 * math.sin(TAU * u + 1.3)), 16),
                     track(Lw, lambda u: (0, 3 * abs(math.sin(TAU * u * 2)), 0), 16, "position")],
            "neck": [track(Lw, lambda u: (0, 0, -3 * math.sin(TAU * u + 1.3)), 16)]}

    Lg = 0.5

    def gallop_arm(i, j, u):
        up = 0.5 + 0.5 * math.sin(TAU * u)  # 1: flapped up, 0: slapped down flat
        if j < 0:
            return (0, 0, 0)
        return ((20, 10, 12)[j] * up - (4, 0, 0)[j], 0, 0)

    gallop = {**arms(Lg, gallop_arm),
              "root": [track(Lg, lambda u: (-4 + 3 * math.sin(TAU * u), 0, 0), 16),
                       track(Lg, lambda u: (0, 7 * max(0.0, -math.sin(TAU * u - 0.5)), 0), 16, "position")],
              "neck": [track(Lg, lambda u: (-3 * math.sin(TAU * u), 0, 0), 16)]}
    return {"idle": (L, idle), "walk": (Lw, walk), "gallop": (Lg, gallop)}


# ---------------------------------------------------------------- preview

CAMS = [dict(eye=(-14, 13, -15), target=(0, 1.2, 0)), dict(eye=(0, 8, -17), target=(0, 1.4, 0)),
        dict(eye=(16, 12, 14), target=(0, 1.0, 0)), dict(eye=(0, 24, 6), target=(0, 0.5, 0))]


def previews(m, out, gif=True):
    import numpy as np
    from horse_rig import pose
    hparts = pose(A.qm_horse("A"), None, 0)
    for p in hparts:
        p.polys = [q + np.array([11, 0, -2]) for q in p.polys]
    parts = S.posed(m)
    W, H = 520, 420
    sheet = Image.new("RGB", (W * 2, H * 2))
    for i, cam in enumerate(CAMS):
        ps = parts + (hparts if i == 2 else [])
        sheet.paste(render(ps, W=W, H=H, fov=40, **cam), ((i % 2) * W, (i // 2) * H))
    sheet.save(os.path.join(out, "Starfish.png"))
    if not gif:
        return
    W, H = 400, 320
    frames = []
    for name, label, n, loops in (("idle", "idle", 24, 1), ("walk", "walk", 12, 3), ("gallop", "run", 8, 4)):
        anim = next(a for a in m["animations"] if a["name"] == name)
        for _ in range(loops):
            for k in range(n):
                ps = S.posed(m, anim, anim["length"] * k / n)
                im = Image.new("RGB", (W * 2, H))
                im.paste(render(ps, W=W, H=H, fov=40, **CAMS[0]), (0, 0))
                im.paste(render(ps, W=W, H=H, fov=40, **CAMS[1]), (W, 0))
                frames.append(A.label(im, [label] * 2))
    A.gif(os.path.join(out, "Starfish_anims.gif"), frames, fps=20)


def headshot(m, path):
    im = render(S.posed(m), W=900, H=900, fov=30, transparent=True, eye=(-3, 15, -24), target=(0, 1.0, 0))
    im = im.crop(im.getbbox())
    side = max(im.size) + 24
    sq = Image.new("RGBA", (side, side))
    sq.paste(im, ((side - im.width) // 2, (side - im.height) // 2))
    sq.resize((512, 512), Image.LANCZOS).save(path)


def main(out="/mnt/project-files/animals/ocean"):
    os.makedirs(out, exist_ok=True)
    m = build()
    shift = floor(m)
    groups = {g["name"]: g for g in m["groups"]}
    write_animations(m, groups, animations())
    for path in (MODEL, os.path.join(out, "Starfish.bbmodel")):
        with open(path, "w") as f:
            json.dump(m, f, separators=(",", ":"))
    print("elements", len(m["elements"]), "bones", len(m["groups"]), "shift", round(shift, 3),
          "seat y", round(SEAT_Y + shift, 3))
    previews(m, out, gif="--gif" in sys.argv)
    headshot(m, os.path.join(ROOT, "assets", "ui", "PetStarfish.png"))


if __name__ == "__main__":
    main(*[a for a in sys.argv[1:] if not a.startswith("--")])
