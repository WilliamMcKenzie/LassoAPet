"""Caterpillar animations (designs/woodland/Caterpillar.bbmodel, from tools/woodland_caterpillar.py).

Run: python3 tools/woodland_caterpillar_rig.py [preview_dir]

Bones: root (front segment, where you sit) -> Seg2 ... Seg6; root -> neck (the head).
A caterpillar crawls by a hump rippling from tail to head, so the crawl is a pitch
wave (X) running forward along the chain: each segment lifts a beat after the one
behind it, its feet bar leaving the ground then planting. A small side sway rides on
top. Rotations are given as each segment's turn relative to the world and written
relative to its parent (the chain adds them up).

  idle    slow breathing hump, the head looking about and the antennae bobbing with it
  walk    the crawl: hump wave front-ward, head nodding
  gallop  the run: faster, bigger humps, the body bouncing
"""

import json
import math
import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
from horse_rig import write_animations  # noqa: E402
from partlib import render  # noqa: E402
import animal_designs as A  # noqa: E402
from snake_design import posed  # noqa: E402
from snake_rig import track  # noqa: E402

ROOT = os.path.join(os.path.dirname(__file__), "..")
MODEL = os.path.join(ROOT, "designs", "woodland", "Caterpillar.bbmodel")
CHAIN = ["root", "Seg2", "Seg3", "Seg4", "Seg5", "Seg6"]
TAU = 2 * math.pi


def body(L, pitch, sway, lag, n=16, bob=0.0):
    """Absolute pitch (X) and sway (Y) per segment; the wave starts at the tail and runs
    to the head (phase leads toward the tail). The root keeps a third so the rider sits steady."""
    def absolute(j, u):
        k = 0.35 if j == 0 else 1.0
        ph = TAU * u + lag * j
        return k * pitch * math.sin(ph), k * sway * math.sin(ph - 0.8)

    tracks = {}
    for j, bone in enumerate(CHAIN):
        def fn(u, j=j):
            p, s = absolute(j, u)
            if j:
                pp, ps = absolute(j - 1, u)
                p, s = p - pp, s - ps
            return (p, s, 0)
        tracks[bone] = [track(L, fn, n)]
    if bob:
        tracks["root"].append(track(L, lambda u: (0, bob * abs(math.sin(TAU * u)), 0), n, channel="position"))
    return tracks


def animations():
    L = 3.0
    idle = {**body(L, 3, 2, 0.9),
            "neck": [track(L, lambda u: (-4 + 4 * math.sin(TAU * u * 2), 16 * math.sin(TAU * u), 0), 24)]}
    Lw = 1.0
    walk = {**body(Lw, 9, 4, 1.0),
            "neck": [track(Lw, lambda u: (-3 + 5 * math.sin(TAU * u + 0.5), -5 * math.sin(TAU * u - 0.6), 0), 16)]}
    Lg = 0.5
    gallop = {**body(Lg, 13, 6, 0.95, bob=0.8),
              "neck": [track(Lg, lambda u: (-6 + 6 * math.sin(TAU * u + 0.5), -7 * math.sin(TAU * u - 0.6), 0), 12)]}
    return {"idle": (L, idle), "walk": (Lw, walk), "gallop": (Lg, gallop)}


def main(out="/mnt/project-files/world2/woodland/caterpillar"):
    os.makedirs(out, exist_ok=True)
    m = json.load(open(MODEL))
    groups = {g["name"]: g for g in m["groups"]}
    m["animations"] = []
    write_animations(m, groups, animations())
    with open(MODEL, "w") as f:
        json.dump(m, f, separators=(",", ":"))
    cams = [dict(eye=(-24, 12, -16), target=(0, 1.8, 6)), dict(eye=(-32, 4, 7), target=(0, 1.8, 7))]
    W, H = 420, 340
    frames = []
    for name, label, n, loops in (("idle", "idle", 30, 1), ("walk", "walk", 20, 2), ("gallop", "run", 10, 3)):
        anim = next(a for a in m["animations"] if a["name"] == name)
        for _ in range(loops):
            for i in range(n):
                parts = posed(m, anim, anim["length"] * i / n)
                im = Image.new("RGB", (W * len(cams), H))
                for c, cam in enumerate(cams):
                    im.paste(render(parts, W=W, H=H, fov=40, **cam), (c * W, 0))
                frames.append(A.label(im, [label] * len(cams)))
    A.gif(os.path.join(out, "Caterpillar_anims.gif"), frames, fps=20)
    print("wrote", out)


if __name__ == "__main__":
    main(*sys.argv[1:])
