"""Crystal Centipede animations on QM's model (designs/crystal/CrystalCentipede.bbmodel).

Run: python3 tools/crystal_centipede_rig.py [preview_dir]

Bones: root (front segment, where you sit) -> Seg2 ... Seg6; root -> neck (head and pincers).
Each segment carries one leg bar, so the scuttle is a roll wave down the body: each
segment rocks side to side a beat after the one in front, lifting one end of its leg bar
then the other, like legs stepping in turn. A side-to-side wave rides on top.

  idle    slow breathing ripple, the head looking side to side
  walk    the scuttle: roll and sway waves down the body, head bobbing
  gallop  the run: faster and wider, head low
Rotations are given as each segment's turn relative to the world and written relative to
its parent (the chain adds them up).
"""

import json
import math
import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import horse_rig  # noqa: E402
from horse_rig import write_animations  # noqa: E402
from partlib import render  # noqa: E402
import animal_designs as A  # noqa: E402
from snake_design import posed  # noqa: E402
from snake_rig import track  # noqa: E402

horse_rig.EULER = "ZYX"  # QM's file: preview as Blockbench shows it
ROOT = os.path.join(os.path.dirname(__file__), "..")
MODEL = os.path.join(ROOT, "designs", "crystal", "CrystalCentipede.bbmodel")
CHAIN = ["root", "Seg2", "Seg3", "Seg4", "Seg5", "Seg6"]
TAU = 2 * math.pi


def body(L, roll, sway, lag, n=16, bob=0.0):
    """Absolute roll (Z) and sway (Y) per segment, lag radians apart, written relative to the parent.
    The root keeps a third of each so the rider isn't thrown about."""
    def absolute(j, u):
        k = 0.35 if j == 0 else 1.0
        ph = TAU * u - lag * j
        return k * roll * math.sin(ph), k * sway * math.sin(ph - 0.6)

    tracks = {}
    for j, bone in enumerate(CHAIN):
        def fn(u, j=j):
            r, s = absolute(j, u)
            if j:
                pr, ps = absolute(j - 1, u)
                r, s = r - pr, s - ps
            return (0, s, r)
        tracks[bone] = [track(L, fn, n)]
    if bob:
        tracks["root"].append(track(L, lambda u: (0, bob * abs(math.sin(TAU * u)), 0), n, channel="position"))
    return tracks


def animations():
    L = 3.0
    idle = {**body(L, 2.5, 3, 0.9),
            "neck": [track(L, lambda u: (4 + 2 * math.sin(TAU * u * 2), 14 * math.sin(TAU * u), 0), 24)]}
    Lw = 0.9
    walk = {**body(Lw, 7, 7, 1.1),
            "neck": [track(Lw, lambda u: (3 * math.sin(TAU * u * 2), -6 * math.sin(TAU * u - 0.6), 0), 16)]}
    Lg = 0.45
    gallop = {**body(Lg, 9, 11, 1.0, bob=1.2),
              "neck": [track(Lg, lambda u: (-4 + 3 * math.sin(TAU * u * 2), -8 * math.sin(TAU * u - 0.6), 0), 12)]}
    return {"idle": (L, idle), "walk": (Lw, walk), "gallop": (Lg, gallop)}


def main(out="/mnt/project-files/animals/crystal_centipede"):
    m = json.load(open(MODEL))
    groups = {g["name"]: g for g in m["groups"]}
    write_animations(m, groups, animations())
    for path in (MODEL, os.path.join(out, "CrystalCentipede.bbmodel")):
        with open(path, "w") as f:
            json.dump(m, f, separators=(",", ":"))
    cams = [dict(eye=(-24, 13, -20), target=(0, 2.2, 7)), dict(eye=(-30, 16, 26), target=(0, 2, 7))]
    W, H = 420, 380
    frames = []
    for name, label, n, loops in (("idle", "idle", 30, 1), ("walk", "walk", 18, 2), ("gallop", "run", 10, 3)):
        anim = next(a for a in m["animations"] if a["name"] == name)
        for _ in range(loops):
            for i in range(n):
                parts = posed(m, anim, anim["length"] * i / n)
                im = Image.new("RGB", (W * len(cams), H))
                for c, cam in enumerate(cams):
                    im.paste(render(parts, W=W, H=H, fov=40, **cam), (c * W, 0))
                frames.append(A.label(im, [label] * len(cams)))
    A.gif(os.path.join(out, "CrystalCentipede_anims.gif"), frames, fps=20)
    still = render(posed(m), W=900, H=560, fov=36, eye=(-24, 14, -22), target=(0, 2.2, 6))
    still.save(os.path.join(out, "CrystalCentipede.png"))
    print("wrote", out)


if __name__ == "__main__":
    main(*sys.argv[1:])
