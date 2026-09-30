"""Scorpion animations on QM's model (designs/desert/Scorpion.bbmodel).

Run: python3 tools/scorpion_rig.py [preview_dir]

Writes idle, walk and gallop into the .bbmodel and renders preview GIFs.

  legs    alternating tripods (L0 R1 L2 / R0 L1 R2): each leg sweeps back on the
          ground (yaw about Y at the hip), then lifts (Z) and swings forward
  claws   bob up about X at the shoulder (the shoulder face stays flush on the head)
  tail    sways side to side about Z; only ever curls forward (-X) so its base
          face never lifts off the body
Angles are degrees, heights Blockbench units (10 = 1 stud).
"""

import json
import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
from horse_rig import pose, write_animations  # noqa: E402
from partlib import render  # noqa: E402
import animal_designs as A  # noqa: E402

ROOT = os.path.join(os.path.dirname(__file__), "..")
MODEL = os.path.join(ROOT, "designs", "desert", "Scorpion.bbmodel")

TRIPOD_A = ("LegL0", "LegR1", "LegL2")


def rot(keys, interp="catmullrom"):
    return {"channel": "rotation", "interp": interp, "keys": [(t, v) for t, v in keys]}


def leg(name, L, swing, lift):
    """One leg's step: forward at u = 0, swept back along the ground by 0.5,
    lifted and swung forward again by 1. Tripod B runs half a step behind."""
    import numpy as np
    s = -1 if name[3] == "L" else 1  # + yaw swings a right leg forward, + Z lifts it
    shift = 0 if name in TRIPOD_A else 0.5
    us, yaws, ups = (0, 0.5, 0.75, 1), (swing, -swing, 0, swing), (0, 0, lift, 0)
    keys = []
    for i in range(9):
        u = i / 8
        v = (u + shift) % 1
        keys.append((round(u * L, 4), (0, s * float(np.interp(v, us, yaws)), s * float(np.interp(v, us, ups)))))
    return rot(keys, "linear")


def legs(L, swing, lift):
    return {f"Leg{side}{k}": [leg(f"Leg{side}{k}", L, swing, lift)] for side in "LR" for k in range(3)}


def claws(L, keys_l, keys_r):
    return {"ClawL": [rot([(round(u * L, 4), (a, 0, 0)) for u, a in keys_l])],
            "ClawR": [rot([(round(u * L, 4), (a, 0, 0)) for u, a in keys_r])]}


def tail(L, sway, curl):
    """sway: [(u, degrees about Z)], curl: [(u, degrees forward)]."""
    us = sorted({u for u, _ in sway} | {u for u, _ in curl})
    import numpy as np
    sz = lambda u: float(np.interp(u, *zip(*sway)))  # noqa: E731
    cx = lambda u: float(np.interp(u, *zip(*curl)))  # noqa: E731
    return {"Tail": [rot([(round(u * L, 4), (-cx(u), 0, sz(u))) for u in us])]}


def bob(L, height, times=2):
    keys = []
    for i in range(times):
        u = i / times
        keys += [(u, 0), (u + 0.5 / times, height)]
    keys.append((1, 0))
    return {"root": [{"channel": "position", "interp": "catmullrom",
                      "keys": [(round(u * L, 4), (0, h, 0)) for u, h in keys]}]}


def animations():
    L = 2.4
    idle = {**claws(L, [(0, 0), (0.25, 10), (0.5, 0), (1, 0)], [(0, 0), (0.5, 0), (0.75, 10), (1, 0)]),
            **tail(L, [(0, 0), (0.25, 5), (0.5, 0), (0.75, -5), (1, 0)], [(0, 0), (0.5, 6), (1, 0)]),
            **bob(L, 0.8, 1)}
    Lw = 0.8
    walk = {**legs(Lw, 15, 18),
            **claws(Lw, [(0, 4), (0.5, 8), (1, 4)], [(0, 8), (0.5, 4), (1, 8)]),
            **tail(Lw, [(0, 4), (0.5, -4), (1, 4)], [(0, 3), (1, 3)]),
            **bob(Lw, 0.8, 2)}
    Lg = 0.45
    gallop = {**legs(Lg, 24, 24),
              **claws(Lg, [(0, 14), (0.5, 20), (1, 14)], [(0, 20), (0.5, 14), (1, 20)]),
              **tail(Lg, [(0, 3), (0.5, -3), (1, 3)], [(0, 10), (0.5, 14), (1, 10)]),
              **bob(Lg, 2.0, 2)}
    return {"idle": (L, idle), "walk": (Lw, walk), "gallop": (Lg, gallop)}


def main(out="/mnt/project-files/animals/desert"):
    m = json.load(open(MODEL))
    groups = {g["name"]: g for g in m["groups"]}
    write_animations(m, groups, animations())
    with open(MODEL, "w") as f:
        json.dump(m, f, separators=(",", ":"))
    with open(os.path.join(out, "Scorpion.bbmodel"), "w") as f:
        json.dump(m, f, separators=(",", ":"))
    cams = [dict(eye=(-22, 14, -24), target=(0, 3, -1)), dict(eye=(-30, 5, -2), target=(0, 3.5, -2)),
            dict(eye=(0, 34, -6), target=(0, 0, -1.5))]
    W, H = 360, 330
    frames = []
    for name, n in (("idle", 24), ("walk", 16), ("gallop", 12)):
        anim = next(a for a in m["animations"] if a["name"] == name)
        for loop in range(2 if name == "idle" else 3):
            for i in range(n):
                parts = pose(m, anim, anim["length"] * i / n)
                im = Image.new("RGB", (W * len(cams), H))
                for c, cam in enumerate(cams):
                    im.paste(render(parts, W=W, H=H, fov=38, **cam), (c * W, 0))
                frames.append(A.label(im, [name] * len(cams)))
    A.gif(os.path.join(out, "Scorpion_anims.gif"), frames, fps=20)
    print("wrote", out)


if __name__ == "__main__":
    main(*sys.argv[1:])
