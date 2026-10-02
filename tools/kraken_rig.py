"""Kraken animations on QM's model (designs/ocean/Kraken.bbmodel, Oct 2: a tall
tilted mantle with fins, one big eye under two brows, eight tentacles).

Run: python3 tools/kraken_rig.py [preview_dir]

Bones: root (head and mantle, where you sit) -> neck (the funnel) -> Arm1..Arm8
(each turned about Y to its direction at rest, Arm1 front-left round to Arm8
front-right) -> T<i>a..T<i>d (segments, pitched at rest to drop to the floor and
curl up). +X on a segment lifts it; +Y on an Arm turns it anticlockwise seen
from above (toward the back for the left arms, Arm1..4).

  idle    a slow ripple runs round the ring of tentacles, curling each tip up and
          letting it down; the body breathes and rocks gently
  walk    a crawl: tentacles reach forward in turn round the ring and pull back
          along the floor; the body bobs and rolls with the steps
  gallop  the run, a squid's jet: every tentacle sweeps back and trails behind
          as the body surges up and leans in, then they all fan out again
"""

import json
import math
import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
from horse_rig import write_animations  # noqa: E402
from partlib import render  # noqa: E402
from snake_design import posed  # noqa: E402
from snake_rig import track  # noqa: E402
import animal_designs as A  # noqa: E402

ROOT = os.path.join(os.path.dirname(__file__), "..")
MODEL = os.path.join(ROOT, "designs", "ocean", "Kraken.bbmodel")
TAU = 2 * math.pi
ARMS = 8
SEGS = "abcd"


def arm_yaw(model, i):
    g = next(g for g in model["groups"] if g["name"] == f"Arm{i + 1}")
    return (g.get("rotation") or (0, 0, 0))[1]


def arms(model, L, fn, n=16):
    """fn(i, yaw, j, u) -> (x, y, z) degrees: j = -1 for the Arm (its turn), 0..3 for segments."""
    out = {}
    for i in range(ARMS):
        yaw = arm_yaw(model, i)
        out[f"Arm{i + 1}"] = [track(L, lambda u, i=i, yaw=yaw: fn(i, yaw, -1, u), n)]
        for j, s in enumerate(SEGS):
            out[f"T{i + 1}{s}"] = [track(L, lambda u, i=i, yaw=yaw, j=j: fn(i, yaw, j, u), n)]
    return out


def back(yaw):
    """+1 if turning the arm by +Y swings it toward the back, -1 if -Y does."""
    return 1 if (yaw % 360) < 180 else -1


def forwardness(yaw):
    """1 for an arm reaching straight ahead, -1 straight back."""
    return math.cos(math.radians(yaw))


def animations(model):
    # position keys are in Blockbench units (0.1 stud)
    L = 4.0

    def idle_arm(i, yaw, j, u):
        ph = TAU * u - TAU * i / ARMS  # the ripple runs round the ring
        if j < 0:
            return (0, 4 * math.sin(ph + 1.0), 0)
        curl = 0.5 + 0.5 * math.sin(ph - 0.7 * j)
        return ((2, 4, 8, 12)[j] * curl - (1, 1, 2, 2)[j], 0, 0)

    idle = {**arms(model, L, idle_arm, 24),
            "root": [track(L, lambda u: (1.5 * math.sin(TAU * u), 0, 1.5 * math.sin(TAU * u + 1.2)), 16),
                     track(L, lambda u: (0, 2.5 * math.sin(TAU * u * 2), 0), 16, "position")],
            "neck": [track(L, lambda u: (-1.5 * math.sin(TAU * u), 0, -1.5 * math.sin(TAU * u + 1.2)), 16)]}

    Lw = 1.2

    def walk_arm(i, yaw, j, u):
        # two waves of four (alternate arms), each arm reaching while lifted
        ph = TAU * u + (math.pi if i % 2 else 0) + 0.4 * i
        lift = max(0.0, math.sin(ph))
        if j < 0:  # swing toward the front while lifted, push back along the floor
            return (0, -back(yaw) * 12 * math.cos(ph), 0)
        return ((18, -6, -8, 12)[j] * lift, 0, 0)

    walk = {**arms(model, Lw, walk_arm),
            "root": [track(Lw, lambda u: (-2 + 2 * math.sin(TAU * u * 2), 0, 3 * math.sin(TAU * u)), 16),
                     track(Lw, lambda u: (0, 4 * abs(math.sin(TAU * u)), 0), 16, "position")],
            "neck": [track(Lw, lambda u: (0, 0, -2 * math.sin(TAU * u)), 16)]}

    Lg = 0.7

    def gallop_arm(i, yaw, j, u):
        # 1: swept back and trailing, 0: fanned out on the floor
        s = 0.5 - 0.5 * math.cos(TAU * u)
        if j < 0:
            reach = 10 + 22 * max(0.0, forwardness(yaw))  # the front arms swing furthest
            return (0, back(yaw) * reach * s, 0)
        return ((22, -10, -12, 16)[j] * s, 0, 0)

    gallop = {**arms(model, Lg, gallop_arm, 16),
              "root": [track(Lg, lambda u: (-8 * (0.5 - 0.5 * math.cos(TAU * u)), 0, 0), 16),
                       track(Lg, lambda u: (0, 12 * max(0.0, math.sin(TAU * u - 0.6)), 0), 16, "position")],
              "neck": [track(Lg, lambda u: (4 * (0.5 - 0.5 * math.cos(TAU * u)), 0, 0), 16)]}
    return {"idle": (L, idle), "walk": (Lw, walk), "gallop": (Lg, gallop)}


def main(out="/mnt/project-files/animals/ocean"):
    m = json.load(open(MODEL))
    groups = {g["name"]: g for g in m["groups"]}
    write_animations(m, groups, animations(m))
    for path in (MODEL, os.path.join(out, "Kraken.bbmodel")):
        with open(path, "w") as f:
            json.dump(m, f, separators=(",", ":"))
    cams = [dict(eye=(-32, 24, -30), target=(0, 9, 0)), dict(eye=(-44, 10, 2), target=(0, 10, 2))]
    W, H = 400, 400
    frames = []
    for name, label, n, loops in (("idle", "idle", 32, 1), ("walk", "walk", 16, 2), ("gallop", "run", 12, 3)):
        anim = next(a for a in m["animations"] if a["name"] == name)
        for _ in range(loops):
            for k in range(n):
                parts = posed(m, anim, anim["length"] * k / n)
                im = Image.new("RGB", (W * len(cams), H))
                for c, cam in enumerate(cams):
                    im.paste(render(parts, W=W, H=H, fov=40, **cam), (c * W, 0))
                frames.append(A.label(im, [label] * len(cams)))
    A.gif(os.path.join(out, "Kraken_anims.gif"), frames, fps=20)
    print("wrote", out)


if __name__ == "__main__":
    main(*sys.argv[1:])
