"""The Leviathan: a sea serpent built like the Snake and Sandworm (a chain of body
segments behind a head) with a head of its own after QM's pixel-art reference: a
pale aqua axolotl-like head with a white chin, gold eyes, dark red cheek marks and
a little mouth, and three red feathery gill stalks fanning out each side. The body
is aqua over a white belly with a pale ridge down the back, tapering to a yellow
tail tip.

Run: python3 tools/leviathan_design.py [out_dir] [--gif]  (previews QM's file; --rebuild overwrites it)

Rest pose (every bone at 0): straight and flat on its belly, facing -z, every cube
axis-aligned. Bones: root (the front segment, where you sit) -> Seg2 ... Seg7 (the
tail); root -> neck (the head) -> GillL, GillR (the gill fans), Jaw (the lower jaw;
-X opens it).

  idle    head raised, looking about, the gills fanning slowly, the tail curling
  walk    a side-to-side wave down the body, the head bobbing, the gills rippling
  gallop  the run: a faster, wider wave, head low and forward, the gills swept back
"""

import json
import math
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import snake_design as S  # noqa: E402
from horse_rig import write_animations  # noqa: E402
from partlib import render  # noqa: E402
from snake_rig import track  # noqa: E402
import animal_designs as A  # noqa: E402
import sandworm_design as W  # noqa: E402  (its tooth(): a square pyramid)

S.SIZE = 1.0
ROOT = os.path.join(os.path.dirname(__file__), "..")
MODEL = os.path.join(ROOT, "designs", "leviathan", "Leviathan.bbmodel")
TAU = 2 * math.pi

COLORS = {"aqua": (140, 226, 214), "deep": (92, 190, 182), "pale": (198, 246, 238), "belly": (246, 250, 250),
          "gill": (186, 52, 40), "gilldark": (130, 30, 30), "gold": (232, 184, 48), "black": (20, 20, 24),
          "mark": (120, 24, 30), "tip": (255, 236, 130), "ivory": (252, 250, 240), "mouth": (110, 20, 34)}
TEX = {n: i for i, n in enumerate(COLORS)}

# (bone, z front, z back, half width, height): the body from the front to the tail
HEAD = (-4.0, 0.0, 2.7, 5.6)  # z front, z back, half width, height (the head block, behind the snout)
SNOUT = 2.6  # how far the jaws reach out in front of it
GAPE = 0.9  # studs between the jaws at rest: the teeth show, crossing
SEGMENTS = [("root", 0.0, 3.4, 2.4, 4.2), ("Seg2", 3.4, 6.6, 2.25, 3.9), ("Seg3", 6.6, 9.6, 2.05, 3.5),
            ("Seg4", 9.6, 12.4, 1.8, 3.1), ("Seg5", 12.4, 15.0, 1.5, 2.6), ("Seg6", 15.0, 17.2, 1.2, 2.1),
            ("Seg7", 17.2, 19.0, 0.9, 1.6)]
BODY = [s[0] for s in SEGMENTS[1:]]
OVERLAP = 0.5  # each block reaches this far past its joint, so bending opens no gaps
BELLY = 0.32
SEAT_Y = SEGMENTS[0][4] + 0.3


def segment(name, z0, z1, hw, h, ridge=True):
    """Aqua over a white belly, a pale ridge block down the middle of the back."""
    L = z1 - z0
    zc = (z0 + z1) / 2
    belly = h * BELLY
    parts = [S.cube(name + "Belly", (0, belly / 2, zc), (2 * hw - 0.2, belly, L), TEX["belly"]),
             S.cube(name, (0, belly + (h - belly) / 2, zc), (2 * hw, h - belly, L), TEX["aqua"])]
    if ridge:
        parts.append(S.cube(name + "Ridge", (0, h + 0.2, zc + 0.2), (0.8 * hw, 0.4, L * 0.6), TEX["pale"]))
    return parts


def build():
    elements, groups = [], []

    def add_group(name, pivot, parent, rot=(0, 0, 0)):
        g = S.group(name, pivot)
        g["rotation"] = list(rot)
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

    # body: root is the front segment, the rest chain back to the tail
    name, z0, z1, hw, h = SEGMENTS[0]
    root = add_group("root", (0, h / 2, (z0 + z1) / 2), None)
    put(root, segment("Seg1", z0 - OVERLAP, z1, hw, h, ridge=False))
    parent = root
    for name, z0, z1, hw, h in SEGMENTS[1:]:
        node = add_group(name, (0, h / 2, z0), parent)
        put(node, segment(name, z0 - OVERLAP, z1, hw, h))
        parent = node
    # the yellow tail tip, curling up at the end (the reference's crescent)
    put(parent, [c("TailTip", (0, 0.7, z1 + 0.7), (1.2, 1.4, 1.4), TEX["tip"]),
                 c("TailCurl", (0, 1.9, z1 + 1.1), (0.9, 1.4, 0.8), TEX["tip"])])

    # the head ("neck" to the game: the lasso loops round it), pivot at its back joint
    z0, z1, hw, h = HEAD
    head = add_group("neck", (0, h / 2, z1), root)
    belly = h * 0.36
    put(head, [c("Head", (0, belly + (h - belly) / 2, (z0 + z1) / 2 + 0.25), (2 * hw, h - belly, z1 - z0 + 0.5), TEX["aqua"]),
               c("Crown", (0, h + 0.3, (z0 + z1) / 2 + 0.6), (2 * hw - 1.4, 0.6, z1 - z0 - 1.4), TEX["aqua"])])
    # the gold eyes on the front, over the snout
    zf = z0 - 0.03
    for side, sx in (("L", -1), ("R", 1)):
        put(head, [c("Eye" + side, (sx * 1.15, h - 0.85, zf), (1.0, 1.0, 0.06), TEX["gold"]),
                   c("Pupil" + side, (sx * 1.05, h - 0.95, zf - 0.03), (0.4, 0.55, 0.06), TEX["black"])])
    # the upper jaw: a long snout out front with the reference's dark red marks on top as
    # nostrils, dark gums under it and a row of razor teeth hanging over the lower jaw
    sw, sl = 2 * hw - 0.8, SNOUT  # snout width, length
    y0s, y1s = belly + GAPE, belly + GAPE + 1.6  # the mouth is modelled open by GAPE studs
    zs = z0 - sl
    put(head, [c("Snout", (0, (y0s + y1s) / 2 + 0.15, z0 - sl / 2), (sw, y1s - y0s - 0.3, sl), TEX["aqua"]),
               c("Gums", (0, y0s + 0.08, z0 - sl / 2 + 0.1), (sw - 0.4, 0.16, sl - 0.2), TEX["mouth"]),
               c("Throat", (0, belly + GAPE / 2, z0 + 0.2), (sw - 0.4, GAPE + 0.1, 0.4), TEX["mouth"])])
    for side, sx in (("L", -1), ("R", 1)):
        put(head, [c("Nostril" + side, (sx * 0.8, y1s + 0.03, zs + 0.6), (0.5, 0.06, 0.5), TEX["mark"])])
    ty = y0s + 0.02
    teeth = [(x, zs + 0.25) for x in (-1.6, -0.8, 0.0, 0.8, 1.6)]
    teeth += [(sx * (sw / 2 - 0.25), zs + 0.25 + 0.75 * k) for sx in (-1, 1) for k in range(1, int(sl / 0.75) + 2)]
    for k, (x, z) in enumerate(teeth):
        fang = abs(x) > 1.2 and k < 5  # the outer front pair are fangs
        put(head, [W.tooth(f"ToothTop{k}", (x, ty, z), 0.55 if fang else 0.42, 1.25 if fang else 0.85, (0, -1, 0), TEX["ivory"])])

    # the lower jaw on its own bone, hinged at the back: a pale jaw, a touch longer than
    # the snout (an underbite), its own teeth jutting up in front of the upper ones
    jaw = add_group("Jaw", (0, belly / 2, z1 - 1.0), head)
    jw = sw - 0.5
    jz0, jz1 = zs - 0.3, z1 + 0.5
    put(jaw, [c("Jaw", (0, belly / 2, (jz0 + jz1) / 2), (2 * hw - 0.3, belly, jz1 - jz0), TEX["belly"]),
              c("Tongue", (0, belly + 0.04, (jz0 + z0) / 2 + 0.2), (jw - 0.6, 0.08, z0 - jz0 - 0.6), TEX["mouth"])])
    jteeth = [(x, jz0 + 0.25) for x in (-1.2, -0.4, 0.4, 1.2)]
    jteeth += [(sx * (jw / 2 - 0.1), jz0 + 0.65 + 0.75 * k) for sx in (-1, 1) for k in range(int(sl / 0.75))]
    for k, (x, z) in enumerate(jteeth):
        put(jaw, [W.tooth(f"ToothBottom{k}", (x, belly - 0.02, z), 0.42, 0.8, (0, 1, 0), TEX["ivory"])])

    # the gills: three red stalks fanning out from each side of the back of the head,
    # each with a darker tip and a row of feathery nubs along its top
    for side, sx in (("L", -1), ("R", 1)):
        x0 = sx * hw
        g = add_group("Gill" + side, (x0, h - 0.9, -1.2), head)
        for k, (dy, yaw, L) in enumerate(((0.9, 30, 3.0), (0.0, 0, 3.4), (-0.9, -30, 2.8))):
            y = h - 0.9 + dy
            stalk = add_group(f"Gill{side}{k}", (x0, y, -1.2), g, (0, -sx * yaw, sx * (24 - 12 * k)))
            xm = x0 + sx * L / 2
            parts = [c(f"Stalk{side}{k}", (xm, y, -1.2), (L, 0.55, 0.55), TEX["gill"]),
                     c(f"StalkTip{side}{k}", (x0 + sx * (L + 0.25), y, -1.2), (0.6, 0.7, 0.7), TEX["gilldark"])]
            for n in range(3):
                xn = x0 + sx * (0.7 + 0.8 * n)
                parts.append(c(f"Nub{side}{k}{n}", (xn, y + 0.42, -1.2), (0.3, 0.35, 0.3), TEX["gilldark"]))
            put(stalk, parts)

    model = json.load(open(os.path.join(ROOT, "designs", "desert", "Snake.bbmodel")))
    model.update(name="Leviathan", elements=elements, groups=groups, outliner=[root], animations=[],
                 textures=[S.solid_texture(n, col) for n, col in COLORS.items()])
    model.setdefault("meta", {})["format_version"] = "5.0"
    return model


# ---------------------------------------------------------------- animations

def wave(L, amp, lag, grow, n=16):
    return {b: [track(L, lambda u, j=j: (0, amp * (1 + grow * j) * math.sin(TAU * u - lag * (j + 1)), 0), n)]
            for j, b in enumerate(BODY)}


def gills(L, fn, n=16):
    """fn(u) -> (spread, sweep) degrees: spread fans them up/out, sweep swings them back."""
    out = {}
    for side, sx in (("L", -1), ("R", 1)):
        out["Gill" + side] = [track(L, lambda u, sx=sx: (0, sx * fn(u)[1], -sx * fn(u)[0]), n)]
    return out


def animations():
    L = 3.0
    idle = {"neck": [track(L, lambda u: (14 + 3 * math.sin(TAU * u * 2), 16 * math.sin(TAU * u), 0), 24)],
            "root": [track(L, lambda u: (0, -4 * math.sin(TAU * u), 0), 12)],
            **gills(L, lambda u: (8 * math.sin(TAU * u * 2), 0), 24),
            "Jaw": [track(L, lambda u: (-34 * max(0.0, math.sin(TAU * u * 2 - 1)) ** 4, 0, 0), 32)],  # a snap now and then
            **{b: [track(L, lambda u, j=j: (0, (5 + 3 * j) + (10 if j == len(BODY) - 1 else 2) * math.sin(TAU * u * (2 if j == len(BODY) - 1 else 1)), 0), 24)]
               for j, b in enumerate(BODY)}}

    Lw = 1.1
    walk = {**wave(Lw, 11, 0.95, 0.15),
            "neck": [track(Lw, lambda u: (6 + 3 * math.sin(TAU * u * 2), -8 * math.sin(TAU * u + 0.4), 0), 16)],
            "root": [track(Lw, lambda u: (0, 4 * math.sin(TAU * u + 0.4), 0), 12)],
            **gills(Lw, lambda u: (10 * math.sin(TAU * u * 2), 8)),
            "Jaw": [track(Lw, lambda u: (-10 - 8 * math.sin(TAU * u), 0, 0), 16)]}

    Lg = 0.6
    gallop = {**wave(Lg, 17, 0.9, 0.15),
              "neck": [track(Lg, lambda u: (2 + 3 * math.sin(TAU * u * 2), -10 * math.sin(TAU * u + 0.4), 0), 12)],
              "root": [track(Lg, lambda u: (0, 6 * math.sin(TAU * u + 0.4), 0), 12)],
              **gills(Lg, lambda u: (6 * math.sin(TAU * u * 2), 30)),
              "Jaw": [track(Lg, lambda u: (-18 - 16 * math.sin(TAU * u * 2), 0, 0), 16)]}  # snapping
    return {"idle": (L, idle), "walk": (Lw, walk), "gallop": (Lg, gallop)}


# ---------------------------------------------------------------- preview

CAMS = [dict(eye=(-26, 17, -24), target=(0, 2.5, 5)), dict(eye=(-4, 6, -20), target=(0, 3, -2)),
        dict(eye=(-40, 7, 8), target=(0, 3, 7)), dict(eye=(3, 46, 16), target=(0, 0, 6))]


def previews(m, out, gif=True):
    from horse_rig import pose
    hparts = pose(A.qm_horse("A"), None, 0)
    for p in hparts:
        p.polys = [q + np.array([9, 0, 6]) for q in p.polys]
    parts = S.posed(m)
    W, H = 520, 420
    sheet = Image.new("RGB", (W * 2, H * 2))
    for i, cam in enumerate(CAMS):
        ps = parts + (hparts if i == 2 else [])
        sheet.paste(render(ps, W=W, H=H, fov=40, **cam), ((i % 2) * W, (i // 2) * H))
    sheet.save(os.path.join(out, "Leviathan.png"))
    if not gif:
        return
    W, H = 420, 340
    frames = []
    for name, label, n, loops in (("idle", "idle", 30, 1), ("walk", "walk", 22, 2), ("gallop", "run", 12, 3)):
        anim = next(a for a in m["animations"] if a["name"] == name)
        for _ in range(loops):
            for k in range(n):
                ps = S.posed(m, anim, anim["length"] * k / n)
                im = Image.new("RGB", (W * 2, H))
                im.paste(render(ps, W=W, H=H, fov=40, **CAMS[0]), (0, 0))
                im.paste(render(ps, W=W, H=H, fov=40, **CAMS[3]), (W, 0))
                frames.append(A.label(im, [label] * 2))
    A.gif(os.path.join(out, "Leviathan_anims.gif"), frames, fps=20)


def main(out="/mnt/project-files/animals/leviathan"):
    os.makedirs(out, exist_ok=True)
    if "--rebuild" not in sys.argv:
        # QM edited the model in Blockbench (Oct 4: crown and tail tip gone):
        # designs/leviathan/Leviathan.bbmodel is QM's file now, so only preview it
        m = json.load(open(MODEL))
        print("previewing QM's", MODEL, "(--rebuild would overwrite it from build())")
        previews(m, out, gif="--gif" in sys.argv)
        return
    m = build()
    groups = {g["name"]: g for g in m["groups"]}
    write_animations(m, groups, animations())
    for path in (MODEL, os.path.join(out, "Leviathan.bbmodel")):
        with open(path, "w") as f:
            json.dump(m, f, separators=(",", ":"))
    print("elements", len(m["elements"]), "bones", len(m["groups"]), "seat y", SEAT_Y)
    previews(m, out, gif="--gif" in sys.argv)


if __name__ == "__main__":
    main(*[a for a in sys.argv[1:] if not a.startswith("--")])
