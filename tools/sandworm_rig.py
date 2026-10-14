"""Sandworm animations on QM's model (designs/desert/Sandworm.bbmodel).

Run: python3 tools/sandworm_rig.py [preview_dir]

Bones: root (front segment, where you sit) -> Seg2 ... Seg6 (tail spike);
root -> neck (the head) -> MandTL, MandTR, MandBL, MandBR (the mandibles).
All motion is bone rotation on the straight, flat rest pose.

  idle    head raised, slowly looking side to side; mandibles clack now and then;
          the tail curls a little and flicks
  walk    a side-to-side wave down the body with a gentle rise and fall at the head;
          mandibles open and close with the stride
  gallop  the run: a faster, wider wave, head low and forward, mandibles snapping
Mandibles open outward (L +Y, R -Y) and apart (top +X, bottom -X).
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
MODEL = os.path.join(ROOT, "designs", "desert", "Sandworm.bbmodel")
BODY = [f"Seg{i}" for i in range(2, 7)]
TAU = 2 * math.pi


def mandibles(L, opening, n=16):
    """opening(u) -> 0 (shut) .. 1 (wide), in degrees scaled per mandible."""
    out = {}
    for name, ry, rx in (("MandTL", 1, 1), ("MandTR", -1, 1), ("MandBL", 1, -1), ("MandBR", -1, -1)):
        out[name] = [track(L, lambda u, ry=ry, rx=rx: (rx * 14 * opening(u), ry * 22 * opening(u), 0), n)]
    return out


def wave(L, amp, lag, grow, n=16):
    return {b: [track(L, lambda u, j=j: (0, amp * (1 + grow * j) * math.sin(TAU * u - lag * (j + 1)), 0), n)]
            for j, b in enumerate(BODY)}


def animations():
    L = 3.0
    idle = {"neck": [track(L, lambda u: (14 + 3 * math.sin(TAU * u * 2), 16 * math.sin(TAU * u), 0), 24)],
            "root": [track(L, lambda u: (0, -4 * math.sin(TAU * u), 0), 12)],
            **mandibles(L, lambda u: max(0.0, math.sin(TAU * u * 3)) ** 3, 36),
            **{b: [track(L, lambda u, j=j: (0, (6 + 4 * j) + (8 if j == 4 else 2) * math.sin(TAU * u * (3 if j == 4 else 1)), 0), 24)]
               for j, b in enumerate(BODY)}}

    Lw = 1.1
    walk = {**wave(Lw, 12, 1.0, 0.15),
            "neck": [track(Lw, lambda u: (6 + 3 * math.sin(TAU * u * 2), -8 * math.sin(TAU * u + 0.4), 0), 16)],
            "root": [track(Lw, lambda u: (0, 4 * math.sin(TAU * u + 0.4), 0), 12)],
            **mandibles(Lw, lambda u: 0.5 + 0.5 * math.sin(TAU * u))}

    Lg = 0.6
    gallop = {**wave(Lg, 18, 0.9, 0.15),
              "neck": [track(Lg, lambda u: (2 + 3 * math.sin(TAU * u * 2), -10 * math.sin(TAU * u + 0.4), 0), 12)],
              "root": [track(Lg, lambda u: (0, 6 * math.sin(TAU * u + 0.4), 0), 12)],
              **mandibles(Lg, lambda u: 0.55 + 0.45 * math.sin(TAU * u * 2))}
    return {"idle": (L, idle), "walk": (Lw, walk), "gallop": (Lg, gallop)}


def main(out="/mnt/project-files/animals/desert"):
    m = json.load(open(MODEL))
    groups = {g["name"]: g for g in m["groups"]}
    write_animations(m, groups, animations())
    for path in (MODEL, os.path.join(out, "Sandworm.bbmodel")):
        with open(path, "w") as f:
            json.dump(m, f, separators=(",", ":"))
    cams = [dict(eye=(-26, 16, -24), target=(0, 2.5, 4)), dict(eye=(0, 55, 5), target=(0, 0, 5.5))]
    W, H = 420, 380
    frames = []
    for name, label, n, loops in (("idle", "idle", 30, 1), ("walk", "walk", 22, 2), ("gallop", "run", 12, 3)):
        anim = next(a for a in m["animations"] if a["name"] == name)
        for _ in range(loops):
            for i in range(n):
                parts = posed(m, anim, anim["length"] * i / n)
                im = Image.new("RGB", (W * len(cams), H))
                for c, cam in enumerate(cams):
                    im.paste(render(parts, W=W, H=H, fov=40, **cam), (c * W, 0))
                frames.append(A.label(im, [label] * len(cams)))
    A.gif(os.path.join(out, "Sandworm_anims.gif"), frames, fps=20)
    sheet = Image.new("RGB", (W * 3, H))
    for c, name in enumerate(("idle", "walk", "gallop")):
        anim = next(a for a in m["animations"] if a["name"] == name)
        sheet.paste(render(posed(m, anim, anim["length"] * 0.25), W=W, H=H, fov=40, **cams[0]), (c * W, 0))
    A.label(sheet, ["idle", "walk", "run"]).save(os.path.join(out, "Sandworm_anims.png"))
    print("wrote", out)


if __name__ == "__main__":
    main(*sys.argv[1:])
