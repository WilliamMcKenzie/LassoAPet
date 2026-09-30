"""Snake animations on QM's model (designs/desert/Snake.bbmodel).

Run: python3 tools/snake_rig.py [preview_dir]

All bends are bone rotations on the straight, flat rest pose:
  body   root (front segment, where you sit) -> Seg2 ... Seg8 (rattle) chain; Y turns
         each joint, so a side-to-side wave travels down the chain to slither
  neck   root -> NeckBase -> neck -> NeckTop -> Head; +X lifts the front, the head
         levels itself out again

  idle    coiled up: the body spirals round to the right, the neck rears up in an S,
          it breathes, the jaw works and the rattle shakes
  walk    slither: a wave down the body, head raised and steady
  gallop  the run: faster, wider wave, head low and forward, jaw wide
Angles in degrees.
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

ROOT = os.path.join(os.path.dirname(__file__), "..")
MODEL = os.path.join(ROOT, "designs", "desert", "Snake.bbmodel")
BODY = [f"Seg{i}" for i in range(2, 9)]


def track(L, fn, n, channel="rotation", interp="catmullrom"):
    """Keys from fn(u) -> (x, y, z) at n + 1 evenly spaced points of the loop."""
    return {"channel": channel, "interp": interp,
            "keys": [(round(L * i / n, 4), tuple(round(v, 3) for v in fn(i / n))) for i in range(n + 1)]}


def wave(L, amp, per_joint, n=16, grow=0.0, bias=None):
    """A side-to-side wave travelling down the body chain (Y at every joint).
    per_joint: phase lag in radians from one joint to the next; grow: extra
    amplitude per joint toward the tail; bias: resting turn per joint."""
    tracks = {}
    for j, bone in enumerate(BODY):
        a = amp * (1 + grow * j)
        b = bias[j] if bias else 0.0
        tracks[bone] = [track(L, lambda u, a=a, j=j, b=b: (0, b + a * math.sin(2 * math.pi * u - per_joint * (j + 1)), 0), n)]
    return tracks


def neck(L, lift, sway=0.0, bob=0.0, n=8):
    """lift: {bone: X degrees}; the head levels out (minus the sum of the neck's lift).
    sway turns the neck base side to side against the body wave (Y) so the head keeps
    its line; bob nods the whole neck up and down with the step."""
    out = {}
    names = ("NeckBase", "neck", "NeckTop")
    total = sum(lift.get(b, 0) for b in names)
    for k, b in enumerate(names):
        base = lift.get(b, 0)
        out[b] = [track(L, lambda u, base=base, k=k: (
            base + bob * math.sin(2 * math.pi * u * 2) * (1 if k == 0 else 0),
            (sway * math.sin(2 * math.pi * u + math.pi) if k == 0 else 0), 0), n)]
    out["Head"] = [track(L, lambda u: (-total - bob * math.sin(2 * math.pi * u * 2),
                                        -sway * math.sin(2 * math.pi * u + math.pi), 0), n)]
    return out


def jaw(L, keys):
    """Jaw on top of its open rest (-19 in the file): + closes it, - opens it wider."""
    return {"Jaw": [{"channel": "rotation", "interp": "catmullrom",
                     "keys": [(round(u * L, 4), (a, 0, 0)) for u, a in keys]}]}


def root_sway(L, yaw, n=8):
    return {"root": [track(L, lambda u: (0, yaw * math.sin(2 * math.pi * u + 0.6), 0), n)]}


def animations():
    # idle: coiled. The body spirals in to the right (each joint turns a little more);
    # the neck rears up; it breathes (neck), works its jaw and shakes the rattle.
    L = 2.4
    coil = [34, 38, 42, 46, 50, 56, 62]
    idle = {b: [track(L, lambda u, c=c: (0, c, 0), 2, interp="linear")] for b, c in zip(BODY[:-1], coil)}
    idle["Seg8"] = [track(L, lambda u: (0, coil[-1] + 7 * math.sin(2 * math.pi * 24 * u), 0), 96, interp="linear")]
    idle.update(neck(L, {"NeckBase": 46, "neck": 30, "NeckTop": 26}, bob=1.5))
    idle.update(jaw(L, [(0, 0), (0.35, 8), (0.55, 8), (0.8, -6), (1, 0)]))

    # walk: slither, head raised, the wave running from neck to tail
    Lw = 1.0
    walk = {**wave(Lw, 16, 0.9, grow=0.12), **neck(Lw, {"NeckBase": 18, "neck": 10, "NeckTop": 4}, sway=6, bob=1),
            **root_sway(Lw, 5), **jaw(Lw, [(0, 4), (1, 4)])}

    # run: quicker and wider, head low and pushed forward, jaw wide
    Lg = 0.6
    gallop = {**wave(Lg, 22, 0.8, grow=0.14), **neck(Lg, {"NeckBase": 8, "neck": 4, "NeckTop": 0}, sway=8, bob=1.5),
              **root_sway(Lg, 7), **jaw(Lg, [(0, -6), (0.5, -10), (1, -6)])}
    return {"idle": (L, idle), "walk": (Lw, walk), "gallop": (Lg, gallop)}


def main(out="/mnt/project-files/animals/desert"):
    m = json.load(open(MODEL))
    groups = {g["name"]: g for g in m["groups"]}
    write_animations(m, groups, animations())
    for path in (MODEL, os.path.join(out, "Snake.bbmodel")):
        with open(path, "w") as f:
            json.dump(m, f, separators=(",", ":"))
    cams = [dict(eye=(-40, 28, -30), target=(0, 3, 8)), dict(eye=(0, 80, 7), target=(0, 0, 7.5))]
    W, H = 480, 440
    frames = []
    for name, label, n, loops in (("idle", "idle (coiled)", 24, 2), ("walk", "walk (slither)", 20, 2), ("gallop", "run", 12, 3)):
        anim = next(a for a in m["animations"] if a["name"] == name)
        for _ in range(loops):
            for i in range(n):
                parts = posed(m, anim, anim["length"] * i / n)
                im = Image.new("RGB", (W * len(cams), H))
                for c, cam in enumerate(cams):
                    im.paste(render(parts, W=W, H=H, fov=40, **cam), (c * W, 0))
                frames.append(A.label(im, [label] * len(cams)))
    A.gif(os.path.join(out, "Snake_anims.gif"), frames, fps=20)
    # a still of each for a quick look
    sheet = Image.new("RGB", (W * 3, H))
    for c, name in enumerate(("idle", "walk", "gallop")):
        anim = next(a for a in m["animations"] if a["name"] == name)
        sheet.paste(render(posed(m, anim, anim["length"] * 0.25), W=W, H=H, fov=40, **cams[0]), (c * W, 0))
    A.label(sheet, ["idle (coiled)", "walk (slither)", "run"]).save(os.path.join(out, "Snake_anims.png"))
    print("wrote", out)


if __name__ == "__main__":
    main(*sys.argv[1:])
