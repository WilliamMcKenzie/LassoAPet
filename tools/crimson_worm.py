"""Eyeworm (World 2, Crimson Lands, Uncommon): a crimson worm with one big yellow eye.

Run: python3 tools/crimson_worm.py [out_dir]

Built like the Sandworm (tools/sandworm_design.py): rest pose lies straight and flat
on its belly facing -z, every cube axis-aligned; bones chain root (front segment,
where you sit) -> Seg2..Seg6 to the tail, root -> neck (the head). Worm, not snake:
blunt round-ended segments of even width with a purple ring at each joint, no
spikes. One eye on the front of the head, black pupil on yellow, a purple brow
and mouth. Same slither as the Sandworm (idle, walk, gallop = run).
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

S.SIZE = 0.9  # an Uncommon: a bit smaller than the Sandworm
ROOT = os.path.join(os.path.dirname(__file__), "..")
NAME = "Eyeworm"
OUT = "/mnt/project-files/animals/crimson_worm"

COLORS = {"crimson": (170, 22, 48), "belly": (214, 70, 92), "purple": (122, 44, 168),
          "yellow": (255, 214, 40), "black": (20, 16, 24)}
TEX = {n: i for i, n in enumerate(COLORS)}

HEAD = ("neck", -4.6, 0.0, 2.6, 4.9)
SEGMENTS = [("root", 0.0, 3.0, 2.1, 4.0), ("Seg2", 3.0, 5.8, 2.0, 3.8), ("Seg3", 5.8, 8.4, 1.9, 3.6),
            ("Seg4", 8.4, 10.8, 1.75, 3.3), ("Seg5", 10.8, 13.0, 1.55, 2.9), ("Seg6", 13.0, 15.0, 1.3, 2.5)]
OVERLAP = 0.5
BELLY = 0.25
BODY = [s[0] for s in SEGMENTS[1:]]
TAU = 2 * math.pi


def segment(name, z0, z1, hw, h, ring=True):
    """Crimson core with a pink belly, its top edges stepped in so it reads round, and a
    purple ring just behind its front joint."""
    L = z1 - z0
    zc = (z0 + z1) / 2
    belly = h * BELLY
    cap = 0.7  # top and bottom edges stepped in, so the worm reads round
    parts = [S.cube(name + "Belly", (0, cap / 2, zc), (2 * hw - 1.0, cap, L), TEX["belly"]),
             S.cube(name, (0, h / 2, zc), (2 * hw, h - 2 * cap, L), TEX["crimson"]),
             S.cube(name + "Top", (0, h - cap / 2, zc), (2 * hw - 1.0, cap, L), TEX["crimson"])]
    if ring:
        parts += [S.cube(name + "Ring", (0, h / 2, z0 + OVERLAP + 0.45), (2 * hw + 0.3, h - 2 * cap + 0.3, 0.9), TEX["purple"]),
                  S.cube(name + "RingTop", (0, h - cap / 2 + 0.15, z0 + OVERLAP + 0.45), (2 * hw - 0.7, cap + 0.3, 0.9), TEX["purple"])]
    return parts


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

    name, z0, z1, hw, h = SEGMENTS[0]
    root = add_group("root", (0, h / 2, (z0 + z1) / 2), None)
    put(root, segment("Seg1", z0 - OVERLAP, z1, hw, h, ring=False))
    parent = root
    for name, z0, z1, hw, h in SEGMENTS[1:]:
        node = add_group(name, (0, h / 2, z0), parent)
        put(node, segment(name, z0 - OVERLAP, z1, hw, h))
        parent = node
    # a blunt purple tail tip
    put(parent, [S.cube("TailTip", (0, 0.9, z1 + 0.4), (1.6, 1.6, 0.8), TEX["purple"])])

    bone, z0, z1, hw, h = HEAD
    head = add_group(bone, (0, h / 2, z1), root)
    put(head, segment("Head", z0, z1 + OVERLAP, hw, h, ring=False))
    put(head, [S.cube("HeadRing", (0, h / 2, z1 - 0.45), (2 * hw + 0.3, h - 1.4 + 0.3, 0.9), TEX["purple"])])
    # the one eye: a yellow block standing proud of the face, black pupil on it
    ey = 2.85
    put(head, [S.cube("Eye", (0, ey, z0 - 0.2), (3.4, 3.0, 0.4), TEX["yellow"]),
               S.cube("Pupil", (0, ey - 0.1, z0 - 0.45), (1.3, 1.8, 0.1), TEX["black"]),
               S.cube("Brow", (0, ey + 1.65, z0 - 0.15), (3.8, 0.5, 0.5), TEX["purple"]),
               S.cube("Mouth", (0, 0.75, z0 - 0.1), (1.8, 0.35, 0.2), TEX["purple"])])

    model = json.load(open(os.path.join(ROOT, "designs", "desert", "Snake.bbmodel")))
    model.update(name=NAME, elements=elements, groups=groups, outliner=[root], animations=[],
                 textures=[S.solid_texture(n, c) for n, c in COLORS.items()])
    return model


def wave(L, amp, lag, grow, n=16):
    return {b: [track(L, lambda u, j=j: (0, amp * (1 + grow * j) * math.sin(TAU * u - lag * (j + 1)), 0), n)]
            for j, b in enumerate(BODY)}


def animations():
    """The Sandworm's slither, without the mandibles."""
    L = 3.0
    idle = {"neck": [track(L, lambda u: (14 + 3 * math.sin(TAU * u * 2), 16 * math.sin(TAU * u), 0), 24)],
            "root": [track(L, lambda u: (0, -4 * math.sin(TAU * u), 0), 12)],
            **{b: [track(L, lambda u, j=j: (0, (6 + 4 * j) + (8 if j == 4 else 2) * math.sin(TAU * u * (3 if j == 4 else 1)), 0), 24)]
               for j, b in enumerate(BODY)}}
    Lw = 1.1
    walk = {**wave(Lw, 12, 1.0, 0.15),
            "neck": [track(Lw, lambda u: (6 + 3 * math.sin(TAU * u * 2), -8 * math.sin(TAU * u + 0.4), 0), 16)],
            "root": [track(Lw, lambda u: (0, 4 * math.sin(TAU * u + 0.4), 0), 12)]}
    Lg = 0.6
    gallop = {**wave(Lg, 18, 0.9, 0.15),
              "neck": [track(Lg, lambda u: (2 + 3 * math.sin(TAU * u * 2), -10 * math.sin(TAU * u + 0.4), 0), 12)],
              "root": [track(Lg, lambda u: (0, 6 * math.sin(TAU * u + 0.4), 0), 12)]}
    return {"idle": (L, idle), "walk": (Lw, walk), "gallop": (Lg, gallop)}


def main(out=OUT):
    os.makedirs(out, exist_ok=True)
    m = build()
    groups = {g["name"]: g for g in m["groups"]}
    write_animations(m, groups, animations())
    for path in (os.path.join(ROOT, "designs", "crimson", NAME + ".bbmodel"), os.path.join(out, NAME + ".bbmodel")):
        with open(path, "w") as f:
            json.dump(m, f, separators=(",", ":"))
    parts = S.posed(m)
    W, H = 560, 440
    cams = [dict(eye=(-22, 13, -22), target=(0, 2.2, 4)), dict(eye=(-36, 5, 5), target=(0, 2.2, 5)),
            dict(eye=(20, 14, 30), target=(0, 2.2, 6)), dict(eye=(-3, 3.5, -16), target=(0, 2.4, -3))]
    sheet = Image.new("RGB", (W * 2, H * 2))
    for i, cam in enumerate(cams):
        sheet.paste(render(parts, W=W, H=H, fov=40, **cam), ((i % 2) * W, (i // 2) * H))
    sheet.save(os.path.join(out, NAME + ".png"))
    frames = []
    for name, n, loops in (("idle", 30, 1), ("walk", 22, 2), ("gallop", 12, 3)):
        anim = next(a for a in m["animations"] if a["name"] == name)
        for _ in range(loops):
            for i in range(n):
                frames.append(A.label(render(S.posed(m, anim, anim["length"] * i / n), W=W, H=H, fov=40, **cams[0]),
                                      ["run" if name == "gallop" else name]))
    A.gif(os.path.join(out, NAME + "_anims.gif"), frames, fps=20)
    print("wrote", len(m["elements"]), "elements")


if __name__ == "__main__":
    main(*sys.argv[1:])
