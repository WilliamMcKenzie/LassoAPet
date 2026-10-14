"""Living Mushroom animations, the same for all three (designs/crystal/{Purple,Brown,Red}Mushroom.bbmodel).

Run: python3 tools/living_mushroom_rig.py [preview_dir]

Bones: root (body) -> neck (cap and eyes), ArmL, ArmR, LegFL, LegFR.

  idle    a slow squash-breath: the body bobs, the cap nods, arms sway
  walk    a fat waddle: short steps, the body rocking side to side, arms swinging opposite
  gallop  the run: bouncy hops, legs kicking, arms flapping out, the cap bouncing a beat late
Positions are Blockbench units (each model's own: 10 x its size per stud).
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
from living_mushroom import KINDS  # noqa: E402

ROOT = os.path.join(os.path.dirname(__file__), "..")
TAU = 2 * math.pi


def animations(size):
    u_ = 10 * size  # Blockbench units per stud

    L = 2.4
    idle = {"root": [track(L, lambda u: (0, 0, 0), 4),
                     track(L, lambda u: (0, 0.08 * u_ * (0.5 - 0.5 * math.cos(TAU * u)), 0), 16, channel="position")],
            "neck": [track(L, lambda u: (3 * math.sin(TAU * u - 0.6), 0, 2 * math.sin(TAU * u * 0.5)), 16)],
            "ArmL": [track(L, lambda u: (6 * math.sin(TAU * u), 0, -6 - 4 * math.sin(TAU * u)), 16)],
            "ArmR": [track(L, lambda u: (-6 * math.sin(TAU * u), 0, 6 + 4 * math.sin(TAU * u)), 16)]}

    Lw = 0.8
    walk = {"root": [track(Lw, lambda u: (0, 4 * math.sin(TAU * u), 7 * math.sin(TAU * u)), 16),
                     track(Lw, lambda u: (0, 0.12 * u_ * abs(math.sin(TAU * u)), 0), 16, channel="position")],
            "neck": [track(Lw, lambda u: (3 * math.sin(TAU * u * 2), 0, -4 * math.sin(TAU * u - 0.5)), 16)],
            "LegFL": [track(Lw, lambda u: (28 * math.sin(TAU * u), 0, 0), 16)],
            "LegFR": [track(Lw, lambda u: (-28 * math.sin(TAU * u), 0, 0), 16)],
            "ArmL": [track(Lw, lambda u: (-30 * math.sin(TAU * u), 0, -8), 16)],
            "ArmR": [track(Lw, lambda u: (30 * math.sin(TAU * u), 0, 8), 16)]}

    Lg = 0.5
    hop = lambda u: max(0.0, math.sin(TAU * u))  # noqa: E731  in the air for half the loop
    gallop = {"root": [track(Lg, lambda u: (-8 - 6 * hop(u), 0, 5 * math.sin(TAU * u * 0.5)), 16),
                       track(Lg, lambda u: (0, 0.9 * u_ * hop(u), 0), 16, channel="position")],
              "neck": [track(Lg, lambda u: (6 * math.sin(TAU * u - 1.2), 0, 0), 16)],
              "LegFL": [track(Lg, lambda u: (40 * math.sin(TAU * u), 0, 0), 16)],
              "LegFR": [track(Lg, lambda u: (-40 * math.sin(TAU * u + 0.6), 0, 0), 16)],
              "ArmL": [track(Lg, lambda u: (-20, 0, -20 - 35 * hop(u)), 16)],
              "ArmR": [track(Lg, lambda u: (-20, 0, 20 + 35 * hop(u)), 16)]}
    return {"idle": (L, idle), "walk": (Lw, walk), "gallop": (Lg, gallop)}


def main(out="/mnt/project-files/animals/living_mushroom"):
    W, H = 380, 360
    frames = []
    models = {}
    for name, (size, *_rest) in KINDS.items():
        path = os.path.join(ROOT, "designs", "crystal", f"{name}.bbmodel")
        m = json.load(open(path))
        write_animations(m, {g["name"]: g for g in m["groups"]}, animations(size))
        for p in (path, os.path.join(out, f"{name}.bbmodel")):
            with open(p, "w") as f:
                json.dump(m, f, separators=(",", ":"))
        models[name] = (m, size)
    for anim, label, n, loops in (("idle", "idle", 24, 1), ("walk", "walk", 16, 2), ("gallop", "run", 10, 3)):
        for _ in range(loops):
            for i in range(n):
                im = Image.new("RGB", (W * 3, H))
                for c, (name, (m, k)) in enumerate(models.items()):
                    a = next(x for x in m["animations"] if x["name"] == anim)
                    im.paste(render(posed(m, a, a["length"] * i / n), W=W, H=H, fov=34,
                                    eye=(-15 * k, 8 * k, -17 * k), target=(0, 3.4 * k, 0)), (c * W, 0))
                frames.append(A.label(im, [label] * 3))
    A.gif(os.path.join(out, "LivingMushrooms_anims.gif"), frames, fps=20)
    print("wrote", out)


if __name__ == "__main__":
    main(*sys.argv[1:])
