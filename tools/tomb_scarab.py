"""Scarab: a World 2 Ancient Tomb animal (QM, Oct 13; Uncommon), after the RotMG Tomb of the
Ancients scarab. The final biome, so it is built in far more detail than earlier animals.

A chunky sacred scarab: a domed teal shell (elytra stacked in stepped layers) split by a gold
seam, rimmed in gold with gold studs, lapis stripes along the top, a gold ankh on each wing case
and a gold-and-lapis hieroglyph band across the back. The pronotum shield carries a winged sun
disc (glowing red sun, gold stepped wings), with gold trim. The wide head has a toothed gold
shovel front, short antennae ending in gold fan clubs, black mandibles and white plate eyes with
pupils. Six legs in three blocks each (dark femur, teal tibia with gold toothed spikes, gold
feet with pyramid claws), gold bands at the knees.

Run: python3 tools/tomb_scarab.py [out_dir]

Built in Blockbench's ZYX Euler order; every bone rests at 0 (leg angles baked into the cubes;
spikes and teeth are pyramid meshes). Bones: root (body, shell, pronotum) -> head;
root -> LegL1..3, LegR1..3 (1 = front).

  idle    legs shuffle, the head nods and twitches, the body breathes
  walk    a tripod gait (front and back legs of one side with the middle of the other)
  gallop  the same, faster and longer strides, the body bouncing and leaning in
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
from hawkmoth import pyr, light_bg  # noqa: E402
import math  # noqa: E402
from horse_rig import write_animations  # noqa: E402
from snake_rig import track  # noqa: E402

TAU = 2 * math.pi

ROOT = os.path.join(os.path.dirname(__file__), "..")
NAME = "Scarab"
MODEL = os.path.join(ROOT, "designs", "tomb", NAME + ".bbmodel")

COLORS = {"teal": (31, 181, 168),       # shell
          "tealdark": (18, 120, 120),
          "lapis": (46, 91, 216),
          "gold": (242, 194, 48),
          "golddark": (196, 146, 30),
          "under": (42, 38, 52),        # underside, femurs, mandibles
          "sand": (220, 201, 152),      # #DCC998
          "red": (230, 64, 42),
          "white": (255, 255, 255), "pupil": (24, 20, 32)}
TEX = {n: i for i, n in enumerate(COLORS)}
box = AB.box
R = AB.axis_rot

Y0 = 2.4  # the underbody's centre, before floor() puts the lowest claw on y = 0


def frame(d):
    """A rotation whose local +y points along d."""
    y = np.array(d, float) / np.linalg.norm(d)
    ref = np.array([0, 0, 1.0]) if abs(y[2]) < 0.9 else np.array([1.0, 0, 0])
    x = np.cross(y, ref)
    x /= np.linalg.norm(x)
    z = np.cross(x, y)
    return np.stack([x, y, z], 1)


def seg(name, a, b, w, d, tex):
    """A block running from point a to point b (w x d across)."""
    a, b = np.array(a, float), np.array(b, float)
    v = b - a
    return box(name, (a + b) / 2, (w, np.linalg.norm(v), d), tex, frame(v))


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
    p = []
    # underbody: a dark belly under the shell, with the tail plate peeking out at the back
    p += [box("Belly", (0, y0, 0.6), (4.6, 1.6, 7.6), TEX["under"]),
          box("Tail", (0, y0 + 0.2, 4.7), (3.0, 1.4, 1.0), TEX["tealdark"]),
          box("TailBand", (0, y0 + 0.2, 4.9), (3.2, 0.4, 0.8), TEX["gold"])]
    # the domed shell: each wing case is three stepped layers, narrower and shorter going up
    sy = y0 + 0.8  # top of the belly
    layers = [(3.4, 7.8, 1.2, 0.0), (3.0, 7.0, 1.0, 0.2), (2.2, 5.8, 0.8, 0.3)]  # half width, length, height, z shift
    y = sy
    tops = []
    for k, (hw, L, h, dz) in enumerate(layers):
        zc = 0.9 + dz
        for s in (-1, 1):
            n = "LR"[s > 0]
            p.append(box(f"Shell{n}{k + 1}", (s * (hw / 2 + 0.06), y + h / 2, zc), (hw - 0.12, h, L), TEX["teal"]))
        tops.append((y + h, hw, L, zc))
        y += h
    ytop, _, Ltop, ztop = tops[-1]
    # rounded front and back of the dome: a smaller cap on top
    p += [box("ShellCapL", (-0.65, ytop + 0.25, ztop), (1.2, 0.5, 4.2), TEX["teal"]),
          box("ShellCapR", (0.65, ytop + 0.25, ztop), (1.2, 0.5, 4.2), TEX["teal"])]
    # gold seam down the middle, standing proud of every layer
    p += [box("Seam", (0, ytop + 0.3, ztop), (0.36, 0.7, 5.0), TEX["gold"]),
          box("Seam2", (0, tops[1][0] + 0.05, 0.9 + 0.2), (0.36, 0.3, 6.9), TEX["gold"]),
          box("Seam3", (0, tops[0][0] + 0.05, 0.9), (0.36, 0.3, 7.7), TEX["gold"])]
    # lapis stripes along the top of each wing case, framed in gold
    for s in (-1, 1):
        n = "LR"[s > 0]
        p += [box(f"Lapis{n}", (s * 1.05, ytop + 0.55, ztop), (0.5, 0.12, 3.6), TEX["lapis"]),
              box(f"LapisGold{n}", (s * 1.05, ytop + 0.52, ztop), (0.8, 0.08, 4.0), TEX["gold"])]
    # gold rim round the bottom layer: two sides and the back, with studs along the sides
    hw0, L0 = layers[0][0], layers[0][1]
    for s in (-1, 1):
        n = "LR"[s > 0]
        p.append(box(f"Rim{n}", (s * (hw0 + 0.05), sy + 0.35, 0.9), (0.3, 0.7, L0 + 0.2), TEX["gold"]))
        for k, z in enumerate(np.linspace(-2.2, 4.0, 5)):
            p.append(box(f"Stud{n}{k + 1}", (s * (hw0 + 0.25), sy + 0.75, z), (0.35, 0.35, 0.35), TEX["golddark"]))
        # second-layer rim: a thin gold edge where the step turns
        p.append(box(f"Rim2{n}", (s * (layers[1][0] - 0.05), tops[0][0] + 0.12, 1.1), (0.25, 0.25, layers[1][1]), TEX["gold"]))
    p.append(box("RimBack", (0, sy + 0.35, 0.9 + L0 / 2 + 0.05), (2 * hw0 + 0.4, 0.7, 0.3), TEX["gold"]))
    # hieroglyph band across the back of the dome: gold with lapis and red tiles
    zb = 3.65
    p.append(box("GlyphBand", (0, ytop + 0.06, zb), (2 * layers[2][0] + 0.1, 0.32, 0.8), TEX["gold"]))
    for k, x in enumerate((-1.75, -1.05, -0.4, 0.4, 1.05, 1.75)):
        p.append(box(f"Glyph{k + 1}", (x, ytop + 0.25, zb), (0.4, 0.12, 0.45), TEX["lapis" if k % 2 else "red"]))
    # an ankh on each wing case's outer slope: loop, crossbar and stem in gold
    for s in (-1, 1):
        n = "LR"[s > 0]
        x = s * (layers[1][0] + 0.02)
        yc, zc = tops[0][0] + 0.55, 0.2
        a = []
        for nm, dy, dzz, hh, dd in (("Top", 0.75, 0, 0.18, 0.7), ("LoopF", 0.45, -0.3, 0.6, 0.18), ("LoopB", 0.45, 0.3, 0.6, 0.18),
                                    ("Bar", 0.05, 0, 0.18, 1.3), ("Stem", -0.35, 0, 0.8, 0.22)):
            a.append(box(f"Ankh{n}{nm}", (x, yc + dy, zc + dzz), (0.14, hh, dd), TEX["gold"]))
        p += a
    put(root, p)

    # pronotum: the shield behind the head, teal with gold trim and a winged sun disc
    pz = -3.6
    q = [box("Pronotum", (0, y0 + 1.2, pz), (6.2, 2.0, 2.4), TEX["teal"]),
         box("PronotumTop", (0, y0 + 2.35, pz + 0.2), (4.8, 0.5, 2.0), TEX["teal"]),
         box("PronotumTrim", (0, y0 + 0.3, pz), (6.5, 0.4, 2.6), TEX["gold"]),
         box("PronotumTrimTop", (0, y0 + 2.62, pz + 1.05), (5.0, 0.2, 0.3), TEX["gold"])]
    for s in (-1, 1):
        n = "LR"[s > 0]
        q += [box(f"PronotumCorner{n}", (s * 3.0, y0 + 1.2, pz - 1.05), (0.6, 1.4, 0.6), TEX["gold"])]
    # winged sun disc standing on the shield like a crest (Khepri raising the sun): a red sun in a
    # gold ring on a gold post, gold stepped wings spread out along the shield's top
    st = y0 + 2.6  # top of the shield
    fz = pz - 0.3
    q += [box("SunPost", (0, st + 0.25, fz + 0.1), (0.5, 0.5, 0.5), TEX["golddark"]),
          box("SunRingA", (0, st + 1.3, fz), (2.0, 1.3, 0.35), TEX["gold"]),
          box("SunRingB", (0, st + 1.3, fz), (1.3, 2.0, 0.35), TEX["gold"]),
          box("Glow_Sun", (0, st + 1.3, fz - 0.2), (1.4, 0.9, 0.12), TEX["red"]),
          box("Glow_Sun2", (0, st + 1.3, fz - 0.2), (0.9, 1.4, 0.12), TEX["red"]),
          box("Glow_SunBack", (0, st + 1.3, fz + 0.2), (1.2, 1.2, 0.12), TEX["red"])]
    for s in (-1, 1):
        n = "LR"[s > 0]
        for k, (w, h, dy) in enumerate(((0.9, 0.7, 0.35), (0.8, 0.5, 0.25), (0.7, 0.32, 0.16))):
            q.append(box(f"SunWing{n}{k + 1}", (s * (0.85 + 0.8 * k + w / 2 - 0.05), st + dy, fz + 0.1 + 0.15 * k),
                         (w, h, 0.9 - 0.15 * k), TEX["gold"]))
            q.append(box(f"SunWingTip{n}{k + 1}", (s * (0.85 + 0.8 * k + w / 2 - 0.05), st + dy, fz + 0.62 + 0.08 * k),
                         (w - 0.1, h * 0.6, 0.2), TEX["lapis"]))
    put(root, q)

    # head: wide and low, a toothed gold shovel in front, fan antennae, mandibles, plate eyes
    hz = -5.6
    head = add_group("head", (0, y0 + 0.9, pz - 1.1), root)
    hp = [box("Head", (0, y0 + 0.9, hz), (4.2, 1.6, 2.0), TEX["tealdark"]),
          box("HeadTop", (0, y0 + 1.8, hz + 0.1), (3.0, 0.3, 1.6), TEX["teal"]),
          box("Shovel", (0, y0 + 0.35, hz - 1.2), (4.4, 0.45, 0.8), TEX["gold"])]
    for k, x in enumerate(np.linspace(-1.8, 1.8, 5)):
        hp.append(pyr(f"Tooth{k + 1}", (x, y0 + 0.35, hz - 1.55), (0, 0, -1), (1, 0, 0), 0.7, 0.32, 0.2, TEX["gold"]))
    # a little horn on the brow, like a sacred scarab's crown
    hp.append(pyr("Horn", (0, y0 + 1.95, hz - 0.2), (0, 1, -0.45), (1, 0, 0), 1.1, 0.4, 0.35, TEX["gold"]))
    for s in (-1, 1):
        n = "LR"[s > 0]
        # plate eyes on the head's sides
        hp += [box(f"Eye{n}", (s * 2.13, y0 + 1.05, hz - 0.15), (0.1, 1.2, 1.2), TEX["white"]),
               box(f"Pupil{n}", (s * 2.2, y0 + 1.0, hz - 0.35), (0.05, 0.62, 0.62), TEX["pupil"])]
        # mandibles: two black blocks curving in under the shovel
        hp += [seg(f"Mandible{n}", (s * 1.2, y0 + 0.25, hz - 0.8), (s * 0.55, y0 + 0.1, hz - 1.9), 0.4, 0.35, TEX["under"])]
        # antennae: a short stalk then a gold fan club of three leaves
        base = np.array([s * 1.6, y0 + 1.2, hz - 0.9])
        tip = base + np.array([s * 1.1, 0.6, -0.9])
        hp.append(seg(f"Antenna{n}", base, tip, 0.25, 0.25, TEX["under"]))
        for k in range(3):
            hp.append(box(f"Club{n}{k + 1}", tip + np.array([s * 0.15, 0.1 + 0.28 * (k - 1), -0.2]), (0.5, 0.14, 0.8),
                          TEX["gold" if k != 1 else "golddark"]))
    put(head, hp)

    # six legs: femur out and up from the belly, tibia down to the ground, gold foot and claws.
    # Front legs reach forward with three teeth on the tibia (a digging scarab), back legs reach back.
    for i, (zz, fwd) in enumerate(((-2.4, -0.9), (0.4, 0.0), (3.0, 0.9))):
        for s in (-1, 1):
            n = "LR"[s > 0]
            nm = f"Leg{n}{i + 1}"
            hip = np.array([s * 2.1, y0 - 0.2, zz])
            leg = add_group(nm, hip, root)
            knee = hip + np.array([s * 1.9, 0.7, fwd * 0.8])
            ankle = knee + np.array([s * 0.7, -(y0 + 0.4), fwd * 0.8])
            foot = ankle + np.array([s * 0.5, -0.05, fwd * 0.5])
            lp = [seg(nm + "Femur", hip, knee, 0.95, 0.95, TEX["under"]),
                  box(nm + "Knee", knee, (1.05, 1.05, 1.05), TEX["gold"]),
                  seg(nm + "Tibia", knee, ankle, 0.8, 0.8, TEX["teal"]),
                  box(nm + "Band", knee + (ankle - knee) * 0.55, (0.95, 0.25, 0.95), TEX["gold"],
                      frame(ankle - knee)),
                  seg(nm + "Foot", ankle, foot, 0.55, 0.55, TEX["gold"])]
            # toothed spikes on the tibia's outer edge (three on the front legs, two behind)
            out = np.array([s, 0.25, 0.0])
            for k, t in enumerate((0.3, 0.55, 0.8)[: 3 if i == 0 else 2]):
                c = knee + (ankle - knee) * t + np.array([s * 0.35, 0, 0])
                lp.append(pyr(f"{nm}Spike{k + 1}", c, out, (0, 1, 0), 0.6 if i == 0 else 0.45, 0.22, 0.2, TEX["golddark"]))
            # two claws at the foot's end
            for k, cs in enumerate((-1, 1)):
                d = np.array([s * 0.6, -0.5, fwd * 0.5 + cs * 0.6])
                lp.append(pyr(f"{nm}Claw{k + 1}", foot, d, (0, 1, 0), 0.6, 0.14, 0.14, TEX["under"]))
            put(leg, lp)

    model = json.load(open(os.path.join(ROOT, "designs", "desert", "Snake.bbmodel")))
    model.update(name=NAME, elements=elements, groups=groups, outliner=[root], animations=[],
                 textures=[S.solid_texture(n, c) for n, c in COLORS.items()])
    model.setdefault("meta", {})["format_version"] = "5.0"
    return model


def floor(model):
    """Shift so the lowest point (the claws) sits on y = 0."""
    lo = min(q[:, 1].min() for p in S.posed(model) for q in p.polys)
    d = -lo * S.BB
    for e in model["elements"]:
        for k in ("from", "to", "origin"):
            if k in e:
                e[k][1] = round(e[k][1] + d, 4)
    for g in model["groups"]:
        g["origin"][1] = round(g["origin"][1] + d, 4)
    return -lo


def animations():
    """A tripod gait: L1, R2 and L3 step together, then R1, L2 and R3. Each leg swings
    forward about Y and lifts about Z while it swings (signs per side: s * angle)."""
    def legs(L, swing, lift, n):
        tr = {}
        for i in range(3):
            for s, nm in ((-1, "L"), (1, "R")):
                ph = 0.0 if (i % 2 == 0) == (s < 0) else 0.5
                tr[f"Leg{nm}{i + 1}"] = [track(L, lambda u, s=s, ph=ph: (
                    0, s * swing * math.sin(TAU * (u + ph)), s * lift * max(0.0, math.cos(TAU * (u + ph)))), n)]
        return tr

    L = 2.4
    idle = {f"Leg{nm}{i + 1}": [track(L, lambda u, s=s, i=i: (0, s * 3 * math.sin(TAU * u + i * 1.3), 0), 16)]
            for i in range(3) for s, nm in ((-1, "L"), (1, "R"))}
    idle["root"] = [track(L, lambda u: (0, 1.2 * math.sin(TAU * u), 0), 16, "position")]
    idle["head"] = [track(L, lambda u: (5 * max(0.0, math.sin(TAU * 2 * u)) ** 2, 4 * math.sin(TAU * u), 0), 24)]
    Lw = 0.8
    walk = {**legs(Lw, 18, 14, 16),
            "root": [track(Lw, lambda u: (0, 0, 2 * math.sin(TAU * u)), 16),
                     track(Lw, lambda u: (0, 1.0 * abs(math.sin(TAU * u)), 0), 16, "position")],
            "head": [track(Lw, lambda u: (0, 4 * math.sin(TAU * u), 0), 16)]}
    Lg = 0.4
    gallop = {**legs(Lg, 26, 20, 16),
              "root": [track(Lg, lambda u: (-4, 0, 3 * math.sin(TAU * u)), 16),
                       track(Lg, lambda u: (0, 3.0 * abs(math.sin(TAU * u)), 0), 16, "position")],
              "head": [track(Lg, lambda u: (4 + 3 * math.sin(TAU * 2 * u), 0, 0), 16)]}
    return {"idle": (L, idle), "walk": (Lw, walk), "gallop": (Lg, gallop)}


def main(out="/mnt/project-files/world2/tomb"):
    renders = os.path.join(out, "renders")
    os.makedirs(renders, exist_ok=True)
    os.makedirs(os.path.dirname(MODEL), exist_ok=True)
    m = build()
    shift = floor(m)
    write_animations(m, {g["name"]: g for g in m["groups"]}, animations())
    for path in (MODEL, os.path.join(out, NAME + ".bbmodel")):
        with open(path, "w") as f:
            json.dump(m, f, separators=(",", ":"))
    parts = S.posed(m)
    P = np.concatenate([q for p in parts for q in p.polys])
    meshes = sum(e["type"] == "mesh" for e in m["elements"])
    print("elements", len(m["elements"]), "pyramids", meshes, "shift", round(shift, 3),
          "bounds", P.min(0).round(1), P.max(0).round(1))
    light_bg(render(parts, W=1100, H=900, fov=34, eye=(-20, 15, -22), target=(0, 2.4, 0), transparent=True)).save(
        os.path.join(renders, NAME + ".png"))
    from horse_rig import pose
    horse_rig.EULER = "XYZ"
    hparts = pose(A.qm_horse("A"), None, 0)
    horse_rig.EULER = "ZYX"
    for p in hparts:
        p.polys = [q + np.array([12, 0, 0]) for q in p.polys]
    cams = [dict(eye=(-26, 16, -30), target=(4, 2.5, 0)), dict(eye=(0, 6, -26), target=(0, 2.5, 0)),
            dict(eye=(0, 34, 4), target=(0, 2.5, 0.5)), dict(eye=(26, 6, 2), target=(0, 2.5, 0))]
    Wd, Ht = 640, 520
    sheet = Image.new("RGB", (Wd * 2, Ht * 2))
    for i, cam in enumerate(cams):
        sheet.paste(render(parts + (hparts if i == 0 else []), W=Wd, H=Ht, fov=40, **cam), ((i % 2) * Wd, (i // 2) * Ht))
    sheet.save(os.path.join(out, NAME + "_sheet.png"))
    if "--gif" in sys.argv:
        frames = []
        for name, n, loops in (("idle", 24, 1), ("walk", 12, 3), ("gallop", 8, 4)):
            anim = next(a for a in m["animations"] if a["name"] == name)
            for _ in range(loops):
                for k in range(n):
                    ps = S.posed(m, anim, anim["length"] * k / n)
                    im = Image.new("RGB", (880, 360))
                    im.paste(render(ps, W=440, H=360, fov=40, **cams[1]), (0, 0))
                    im.paste(render(ps, W=440, H=360, fov=40, eye=(-22, 12, -20), target=(0, 2.5, 0)), (440, 0))
                    frames.append(A.label(im, [name] * 2))
        A.gif(os.path.join(out, NAME + "_anims.gif"), frames, fps=20)


if __name__ == "__main__":
    main(*[a for a in sys.argv[1:] if not a.startswith("--")])
