"""Animates the Robo Shark: QM's own file (designs/ocean/RoboShark.bbmodel, QM's edit of
tools/robo_shark.py's 1:1 statue conversion; QM's untouched copy is RoboShark_QM.bbmodel).

Run: python3 tools/robo_shark_rig.py [out_dir]   writes the animations into the file, renders a GIF
then: python3 tools/bbmodel_to_luau.py --zyx designs/ocean/RoboShark.bbmodel src/shared/Animals/RoboSharkModel.luau

Bones: root (body) -> neck (head) -> Jaw; root -> FinL / FinR; root -> Tail -> TailFin.
The rest pose is QM's statue: jaw hanging wide open, tail bent to the right. In
motion the tail swings side to side about a straighter line (BIAS), and the jaw
(+X closes it) snaps.

  idle    floats and bobs; the tail sways slowly, the fins paddle, the jaw works
  walk    swims: the tail sweeps, the body and head counter-swing
  gallop  the dash: big tail beats, the jaw snapping shut on every beat
"""

import json
import math
import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import horse_rig as HR  # noqa: E402
import animal_designs as A  # noqa: E402
import snake_design as S  # noqa: E402
from horse_rig import write_animations  # noqa: E402
from partlib import render  # noqa: E402
from snake_rig import track  # noqa: E402

HR.EULER = "ZYX"
ROOT = os.path.join(os.path.dirname(__file__), "..")
MODEL = os.path.join(ROOT, "designs", "ocean", "RoboShark.bbmodel")
TAU = 2 * math.pi
BIAS = -11  # degrees: the swim centres the tail halfway back from its bend


def swim(L, tail, fin, lag, body, bob, fins, n=16):
    s = lambda u, ph=0.0: math.sin(TAU * u - ph)  # noqa: E731
    return {
        "root": [track(L, lambda u: (0, body * s(u, math.pi), 0), n),
                 track(L, lambda u: (0, bob * s(u, 1.0), 0), n, "position")],
        "neck": [track(L, lambda u: (0, -0.6 * body * s(u, math.pi), 0), n)],
        "Tail": [track(L, lambda u: (0, BIAS + tail * s(u), 0), n)],
        "TailFin": [track(L, lambda u: (0, fin * s(u, lag), 0), n)],
        "FinL": [track(L, lambda u: (0, 0, fins * s(u, 0.5)), n)],
        "FinR": [track(L, lambda u: (0, 0, -fins * s(u, 0.5)), n)],
    }


def snap(u, at=0.0, width=0.18):
    """0 -> 1 -> 0 around phase `at`: the jaw closing and springing back open."""
    d = (u - at) % 1.0
    return math.sin(math.pi * d / width) if d < width else 0.0


def animations():
    L = 2.4
    idle = swim(L, 7, 10, 0.9, 2, 1.2, 8, 24)
    idle["Jaw"] = [track(L, lambda u: (8 * (0.5 - 0.5 * math.cos(TAU * u)), 0, 0), 24)]
    Lw = 1.2
    walk = swim(Lw, 16, 24, 0.9, 4, 1.6, 12)
    walk["Jaw"] = [track(Lw, lambda u: (14 * (0.5 - 0.5 * math.cos(TAU * u)), 0, 0), 16)]
    Lg = 0.6
    gallop = swim(Lg, 26, 36, 1.0, 6, 2.0, 18, 16)
    gallop["Jaw"] = [track(Lg, lambda u: (55 * snap(u, 0.1, 0.4), 0, 0), 16)]
    gallop["neck"] = [track(Lg, lambda u: (-6 * snap(u, 0.1, 0.4), -3.6 * math.sin(TAU * u - math.pi), 0), 16)]
    return {"idle": (L, idle), "walk": (Lw, walk), "gallop": (Lg, gallop)}


def posed(m, anim=None, t=0.0):
    ps = S.posed(m, anim, t)
    for p in ps:
        p.neon = p.name.startswith("Glow")
        p.plain = p.plain or p.neon
    return ps


def main(out="/mnt/project-files/animals/robo_shark"):
    m = json.load(open(MODEL))
    groups = {g["name"]: g for g in m["groups"]}
    write_animations(m, groups, animations())
    for path in (MODEL, os.path.join(out, "RoboShark.bbmodel")):
        with open(path, "w") as f:
            json.dump(m, f, separators=(",", ":"))
    cams = [dict(eye=(-7.5, 5, -8.5), target=(0, 1.2, 0.3)), dict(eye=(0, 10, 3), target=(0, 1, 0.8))]
    W, H = 400, 400
    frames = []
    for name, label, n, loops in (("idle", "idle", 32, 1), ("walk", "walk", 16, 2), ("gallop", "run", 12, 3)):
        anim = next(a for a in m["animations"] if a["name"] == name)
        for _ in range(loops):
            for k in range(n):
                parts = posed(m, anim, anim["length"] * k / n)
                im = Image.new("RGB", (W * len(cams), H))
                for c, cam in enumerate(cams):
                    im.paste(render(parts, W=W, H=H, fov=26, **cam), (c * W, 0))
                frames.append(A.label(im, [label] * len(cams)))
    A.gif(os.path.join(out, "RoboShark_anims.gif"), frames, fps=20)
    print("wrote", out)


if __name__ == "__main__":
    main(*sys.argv[1:])
