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
  gallop  the run, a real squid's swim (QM, Oct 2): it lifts off and glides, the
          tentacles bundled and streaming behind, flaring out and snapping shut
          to jet it forward (glide)
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

    return {"idle": (L, idle), "walk": (Lw, walk), "gallop": glide(model)}


def glide(m):
    """The run (QM, Oct 2): a squid's jet-propelled glide. It lifts off the floor and leans
    in, the tentacles hang together in a bundle streaming back behind it, and every
    1.2 s they flare out and snap shut to kick it forward. Positions in Blockbench units."""
    L = 1.2
    rest = {g["name"]: (g.get("rotation") or (0, 0, 0))[0] for g in m["groups"]}

    def stroke(u):
        """0 bundled and streaming, 1 flared out: opens slowly, snaps shut fast."""
        if u < 0.35:
            return math.sin(math.pi / 2 * u / 0.35) ** 2
        if u < 0.5:
            return math.cos(math.pi / 2 * (u - 0.35) / 0.15) ** 2
        return 0.0

    def surge(u):
        """The jet's kick, peaking just after the tentacles snap shut, easing off in the glide."""
        d = (u - 0.45) % 1.0
        return math.exp(-d * 5) * min(1.0, d / 0.06)

    def arm(i, yaw, j, u):
        f = stroke(u)
        if j < 0:  # the arms keep their turn; only the segments move
            return (0, 0, 0)
        name = f"T{i + 1}{'abcd'[j]}"
        r = rest[name]
        straight = (-90 - r) if j == 0 else -r  # each tentacle hanging straight down from the funnel
        ripple = (0, 3, 6, 9)[j] * math.sin(TAU * u * 2 - 1.1 * j) * (1 - f)
        flare = ((-90 - r) * 0.25, -r * 0.6, -r * 0.4, 6.0)[j]  # flared: well out from the bundle, tips curling
        return (straight * (1 - f) + flare * f + ripple, 0, 0)

    anim = {**arms(m, L, arm, 24),
            "root": [track(L, lambda u: (-16 - 6 * surge(u) + 4 * stroke(u), 0, 0), 24),
                     track(L, lambda u: (0, 95 + 14 * surge(u) - 10 * stroke(u), -12 * surge(u)), 24, "position")],
            "neck": [track(L, lambda u: (-34 + 16 * stroke(u), 0, 0), 24)]}
    return L, anim


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
