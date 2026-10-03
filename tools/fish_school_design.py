"""The School of Fish (Ocean, medium): a swarm of small blocky fish packed into a
rough ball, all facing forward. You ride on top of the swarm. The lead fish at
the front, a little bigger than the rest, is the face (the lasso loops round it).

Run: python3 tools/fish_school_design.py [palette, default B] [--gif]
     python3 tools/fish_school_design.py options    colour options sheet

Bones: root (the middle of the swarm) -> F0 (the lead fish, named neck) and
F1..F<n> (one per fish) -> T0..T<n> (each fish's tail, wagging about Y).
Every fish is built facing -z with its tail behind, so a fish bone's position
keys move it within the swarm and its Y rotation turns it.

  idle    the fish mill about in place, each bobbing and drifting on its own
          beat, tails flicking
  walk    the swarm swims along: tails wag, a gentle wave runs front to back
  gallop  the run: tails beat fast, the fish dart forward and back in a wave
          that runs down the swarm, which surges and bobs as one
"""

import json
import math
import os
import random
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import snake_design as S  # noqa: E402
from horse_rig import write_animations  # noqa: E402
from partlib import render  # noqa: E402
from snake_rig import track  # noqa: E402
import animal_designs as A  # noqa: E402

S.SIZE = 1.0
ROOT = os.path.join(os.path.dirname(__file__), "..")
MODEL = os.path.join(ROOT, "designs", "ocean", "FishSchool.bbmodel")
OUT = "/mnt/project-files/animals/ocean/fish_school"
TAU = 2 * math.pi

# Colour options: body, back (darker top stripe), belly, fins and tail.
PALETTES = {
    "A": dict(label="A  sardines: silver blue", body=(150, 196, 236), back=(52, 104, 196), belly=(240, 248, 255),
              fin=(84, 140, 220)),
    "B": dict(label="B  yellow tangs", body=(255, 214, 40), back=(255, 186, 20), belly=(255, 240, 150),
              fin=(255, 150, 20)),
    "C": dict(label="C  mixed reef: blue, yellow, orange", body=None),
}
MIX = [dict(body=(48, 118, 240), back=(28, 60, 160), belly=(120, 190, 255), fin=(255, 214, 40)),
       dict(body=(255, 214, 40), back=(255, 176, 20), belly=(255, 240, 150), fin=(255, 150, 20)),
       dict(body=(255, 128, 40), back=(230, 90, 20), belly=(255, 255, 255), fin=(255, 255, 255))]

# One fish (studs, before scaling): body length, width, height
FISH = dict(L=2.4, w=1.0, h=1.4)
def swarm():
    """(x, y, z, scale) for each fish: the lead fish first, then three staggered layers
    filling a rough egg shape (wider at the front, tapering back), a little jitter so
    it reads as a swarm, not a grid. y is the middle of the fish's body."""
    rng = random.Random(3)
    out = [(0.0, 2.5, -4.6, 1.0)]
    layers = [(1.2, 2.4, 3.4), (2.6, 3.4, 4.4), (4.0, 2.4, 3.4)]  # (y, half width, half length)
    for li, (y, rx, rz) in enumerate(layers):
        for zi, z in enumerate(np.arange(-rz + 0.9, rz + 0.01, 2.4)):
            off = 0.9 if (zi + li) % 2 else 0.0
            for x in np.arange(-rx + off, rx + 0.01, 1.8):
                if (x / rx) ** 2 + (z / rz) ** 2 > 1.05 or (abs(x) < 0.9 and z < -3.2):
                    continue
                out.append((x + rng.uniform(-0.2, 0.2), y + rng.uniform(-0.25, 0.25),
                            z + rng.uniform(-0.3, 0.3), rng.uniform(0.78, 0.9)))
    return out


SWARM = swarm()

CENTER = (0.0, 2.5, 0.0)
SEAT_Y = 4.0 + 0.85 * FISH["h"] / 2 + 0.05  # on the backs of the top fish
SEAT_Z = 0.4


def build(palette="A"):
    pal = PALETTES[palette]
    if pal["body"] is None:
        cols = {f"{k}{i}": v for i, m in enumerate(MIX) for k, v in m.items()}
    else:
        cols = {k: pal[k] for k in ("body", "back", "belly", "fin")}
    cols.update(white=(255, 255, 255), black=(20, 20, 24))
    tex = {n: i for i, n in enumerate(cols)}
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

    c = S.cube
    root = add_group("root", CENTER, None)
    for i, (x, y, z, s) in enumerate(SWARM):
        if pal["body"] is None:
            k = (i * 7 + i // 3) % 3 if i else 0
            t = {n: tex[f"{n}{k}"] for n in ("body", "back", "belly", "fin")}
        else:
            t = {n: tex[n] for n in ("body", "back", "belly", "fin")}
        L, w, h = FISH["L"] * s, FISH["w"] * s, FISH["h"] * s
        name = "neck" if i == 0 else f"F{i}"
        fish = add_group(name, (x, y, z), root)
        # five blocks a fish, to keep the swarm about as many parts as one big animal:
        # the body, a darker back, a tail fin, and a googly eye on the side you can see
        # (both sides on the lead fish)
        put(fish, [
            c(f"Fish{i}", (x, y - 0.08 * s, z), (w, h * 0.8, L), t["body"]),
            c(f"Fish{i}Back", (x, y + h * 0.4, z + 0.15 * s), (w * 0.8, h * 0.24, L * 0.8), t["back"]),
        ])
        E = 0.55 * s
        for side, sx in (("L", -1), ("R", 1)):
            if i and sx * x < -0.1:
                continue
            ex, ey, ez = x + sx * (w / 2 + 0.03), y + 0.12 * s, z - L / 2 + 0.45 * s
            put(fish, [c(f"Eye{side}{i}", (ex, ey, ez), (0.06, E, E), tex["white"]),
                       c(f"Pupil{side}{i}", (ex + sx * 0.03, ey - 0.05 * s, ez - 0.05 * s),
                         (0.06, 0.6 * E, 0.5 * E), tex["black"])])
        tail = add_group(f"T{i}", (x, y, z + L / 2), fish)
        put(tail, [c(f"Fish{i}Tail", (x, y, z + L / 2 + 0.45 * s), (0.3 * s, h * 0.95, 0.9 * s), t["fin"])])

    model = json.load(open(os.path.join(ROOT, "designs", "desert", "Snake.bbmodel")))
    model.update(name="FishSchool", elements=elements, groups=groups, outliner=[root], animations=[],
                 textures=[S.solid_texture(n, col) for n, col in cols.items()])
    model.setdefault("meta", {})["format_version"] = "5.0"
    return model


# ---------------------------------------------------------------- animations

def phases(seed=7):
    rng = random.Random(seed)
    return [rng.random() * TAU for _ in SWARM]


def animations():
    """Position keys are in Blockbench units (0.1 stud)."""
    ph = phases()

    def per_fish(L, fn, n=16):
        out = {}
        for i in range(len(SWARM)):
            bone = "neck" if i == 0 else f"F{i}"
            rot, pos, tail = fn(i)
            out[bone] = [track(L, rot, n), track(L, pos, n, "position")]
            out[f"T{i}"] = [track(L, tail, n)]
        return out

    # idle: each fish on its own beat, drifting in a small loop, tail flicking
    L = 3.0

    def idle(i):
        p = ph[i]
        return (lambda u: (4 * math.sin(TAU * u + p), 8 * math.sin(TAU * u + p + 1.0), 0),
                lambda u: (3 * math.cos(TAU * u + p), 4 * math.sin(TAU * 2 * u + p), 3 * math.sin(TAU * u + p)),
                lambda u: (0, 18 * math.sin(TAU * 4 * u + p), 0))

    # walk: tails wag, a gentle bob runs from the front of the swarm to the back
    Lw = 1.0

    def walk(i):
        p = ph[i]
        lag = (SWARM[i][2] + 5) * 0.35
        return (lambda u: (0, 6 * math.sin(TAU * u + p), 0),
                lambda u: (0, 4 * math.sin(TAU * u - lag), 3 * math.sin(TAU * u - lag + 1)),
                lambda u: (0, 26 * math.sin(TAU * 2 * u + p), 0))

    # gallop: tails beat fast, each fish darts forward and drops back in a wave down the swarm
    Lg = 0.6

    def gallop(i):
        p = ph[i]
        lag = (SWARM[i][2] + 5) * 0.5
        return (lambda u: (-6 + 4 * math.sin(TAU * u - lag), 5 * math.sin(TAU * 2 * u + p), 0),
                lambda u: (0, 5 * math.sin(TAU * u - lag), -8 * math.sin(TAU * u - lag)),
                lambda u: (0, 35 * math.sin(TAU * 3 * u + p), 0))

    idle_t = {**per_fish(L, idle, 48)}
    walk_t = {**per_fish(Lw, walk),
              "root": [track(Lw, lambda u: (0, 4 * math.sin(TAU * u), 0), 16, "position")]}
    gallop_t = {**per_fish(Lg, gallop),
                "root": [track(Lg, lambda u: (-3, 0, 0), 4),
                         track(Lg, lambda u: (0, 8 + 6 * math.sin(TAU * u), 0), 16, "position")]}
    return {"idle": (L, idle_t), "walk": (Lw, walk_t), "gallop": (Lg, gallop_t)}


# ---------------------------------------------------------------- previews

def scale(model):
    """How much Horse.variant will grow this model: tier 2 is 10.4 x 1.6 studs, where
    size is the square root of the two biggest sides of the model's box."""
    pts = np.concatenate([q for p in S.posed(model) for q in p.polys])
    sides = sorted(pts.max(0) - pts.min(0))
    return 10.4 * 1.6 / math.sqrt(sides[1] * sides[2])


def rider(k):
    """A plain blocky Roblox player (5 studs tall at real size), sitting, shrunk by 1/k
    to the model's scale, on the seat."""
    blocks = [("Torso", (0, 1.0 + 1.0, 0.2), (2, 2, 1), (40, 120, 220)),
              ("Head", (0, 3.0 + 0.6, 0.2), (1.2, 1.2, 1.2), (255, 205, 60)),
              ("ArmL", (-1.5, 2.0, -0.3), (1, 2, 1), (255, 205, 60)),
              ("ArmR", (1.5, 2.0, -0.3), (1, 2, 1), (255, 205, 60)),
              ("LegL", (-0.5, 0.5, -0.6), (1, 1, 2), (60, 160, 80)),
              ("LegR", (0.5, 0.5, -0.6), (1, 1, 2), (60, 160, 80)),
              ("ShinL", (-0.5, -0.3, -1.3), (1, 1.4, 1), (60, 160, 80)),
              ("ShinR", (0.5, -0.3, -1.3), (1, 1.4, 1), (60, 160, 80))]
    m = {"elements": [], "groups": [], "outliner": [], "textures": []}
    root = S.group("root", (0, 0, 0))
    m["groups"].append(root)
    node = {"uuid": root["uuid"], "isOpen": True, "children": []}
    m["outliner"].append(node)
    for i, (name, cen, size, col) in enumerate(blocks):
        cen = np.array(cen) / k + np.array([0, SEAT_Y, SEAT_Z])
        e = S.cube(name, cen, np.array(size) / k, i)
        m["elements"].append(e)
        node["children"].append(e["uuid"])
        m["textures"].append(S.solid_texture(name, col))
    return S.posed(m)


def tag(parts):
    from bbmodel_to_luau import NEON, PLAIN
    for p in parts:
        p.neon = p.name.startswith(NEON)
        p.plain = p.plain or p.neon or p.name.startswith(PLAIN) or "In" in p.name
    return parts


CAMS = [dict(eye=(-12, 9, -16), target=(0, 2.6, 0)), dict(eye=(0, 5, -17), target=(0, 2.6, 0)),
        dict(eye=(17, 7, 4), target=(0, 2.6, 0.5)), dict(eye=(-8, 13, 13), target=(0, 2.8, 0))]


def sheet(m, k, path, riding=True):
    parts = tag(S.posed(m)) + (rider(k) if riding else [])
    W, H = 520, 420
    im = Image.new("RGB", (W * 2, H * 2))
    for i, cam in enumerate(CAMS):
        im.paste(render(parts, W=W, H=H, fov=40, **cam), ((i % 2) * W, (i // 2) * H))
    im.save(path)


def options():
    tile = 520
    out = Image.new("RGB", (tile * 3, tile + 40), (255, 255, 255))
    from PIL import ImageDraw
    d = ImageDraw.Draw(out)
    for j, key in enumerate(PALETTES):
        m = build(key)
        k = scale(m)
        parts = tag(S.posed(m)) + rider(k)
        out.paste(render(parts, W=tile, H=tile, fov=40, **CAMS[0]), (j * tile, 40))
        d.text((j * tile + 10, 12), PALETTES[key]["label"], fill=(20, 20, 20))
    os.makedirs(OUT, exist_ok=True)
    out.save(os.path.join(OUT, "fish_school_options.png"))
    print("wrote", os.path.join(OUT, "fish_school_options.png"))


def gif(m, k, path):
    W, H = 400, 340
    frames = []
    rp = rider(k)
    for name, label, n, loops in (("idle", "idle", 30, 1), ("walk", "walk", 12, 3), ("gallop", "run", 10, 4)):
        anim = next(a for a in m["animations"] if a["name"] == name)
        for _ in range(loops):
            for f in range(n):
                ps = tag(S.posed(m, anim, anim["length"] * f / n))
                im = Image.new("RGB", (W * 2, H))
                im.paste(render(ps + rp, W=W, H=H, fov=40, **CAMS[0]), (0, 0))
                im.paste(render(ps, W=W, H=H, fov=40, **CAMS[2]), (W, 0))
                frames.append(A.label(im, [label] * 2))
    A.gif(path, frames, fps=20)


def main(palette="B"):  # QM picked B, yellow tangs (Oct 3)
    os.makedirs(OUT, exist_ok=True)
    m = build(palette)
    groups = {g["name"]: g for g in m["groups"]}
    write_animations(m, groups, animations())
    k = scale(m)
    for path in (MODEL, os.path.join(OUT, "FishSchool.bbmodel")):
        with open(path, "w") as f:
            json.dump(m, f, separators=(",", ":"))
    print("elements", len(m["elements"]), "bones", len(m["groups"]), "game scale", round(k, 3),
          "seat", (0, round(SEAT_Y, 3), SEAT_Z))
    sheet(m, k, os.path.join(OUT, "FishSchool.png"))
    if "--gif" in sys.argv:
        gif(m, k, os.path.join(OUT, "FishSchool_anims.gif"))


if __name__ == "__main__":
    a = [x for x in sys.argv[1:] if not x.startswith("--")]
    if a and a[0] == "options":
        options()
    else:
        main(*a)
