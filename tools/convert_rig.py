"""Animations for the converted models (tools/convert_designs.py): idle, walk, gallop.

Run: python3 tools/convert_rig.py [out_dir]            every model + preview GIFs
     python3 tools/convert_rig.py one <name> [out_dir]

Keyframes are offsets from each bone's rest rotation, as in Blockbench, so the
poses QM approved stay the base of every frame. Angles in degrees, heights in
Blockbench units (10 = 1 stud). Signs, for a bone at 0:
  +X swings a hanging leg or arm forward, lifts a head, lowers a tail
  +Y turns the front to the model's left (-x)
  +Z rolls the top toward -x
"""

import json
import math
import os
import shutil
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import animal_designs as A  # noqa: E402
import convert_designs as C  # noqa: E402
from horse_rig import write_animations  # noqa: E402
from partlib import render  # noqa: E402
from snake_design import posed  # noqa: E402

TAU = 2 * math.pi


def cyc(L, f, n=12, channel="rotation"):
    """One looping channel sampled from f(u) -> (x, y, z), u in [0, 1]."""
    keys = [(round(L * i / n, 4), tuple(float(v) for v in f(i / n))) for i in range(n + 1)]
    return {"channel": channel, "interp": "catmullrom", "keys": keys}


def sin(u, amp, phase=0.0, k=1):
    return amp * math.sin(TAU * (k * u + phase))


def lerp(u, pts):
    """Piecewise-linear (u, value) points, looping."""
    us, vs = zip(*pts)
    return float(np.interp(u % 1, us, vs))


def rx(L, f, n=12):
    return cyc(L, lambda u: (f(u), 0, 0), n)


def ry(L, f, n=12):
    return cyc(L, lambda u: (0, f(u), 0), n)


def rz(L, f, n=12):
    return cyc(L, lambda u: (0, 0, f(u)), n)


def py(L, f, n=12):
    return cyc(L, lambda u: (0, f(u), 0), n, "position")


def lift(u, phase):
    """0 while the foot is planted, a bump while it swings forward (the half of
    the stride where sin(TAU * (u + phase)) is rising through its top)."""
    return max(0.0, math.cos(TAU * (u + phase)))


# ---------------------------------------------------------------- boar

def boar():
    L = 2.4
    idle = {
        "root": [py(L, lambda u: 2.5 * (1 - math.cos(TAU * u)) / 2)],
        "neck": [rx(L, lambda u: lerp(u, [(0, 0), (0.45, 0), (0.55, -5), (0.62, -1), (0.69, -5), (0.8, 0), (1, 0)]))],
        "Tail": [rz(L, lambda u: sin(u, 18, k=3))],
        "EarL": [rz(L, lambda u: lerp(u, [(0, 0), (0.2, 0), (0.25, 20), (0.32, 0), (1, 0)]))],
        "EarR": [rz(L, lambda u: lerp(u, [(0, 0), (0.7, 0), (0.75, -20), (0.82, 0), (1, 0)]))],
    }
    Lw = 0.8
    walk = {
        "LegFL": [rx(Lw, lambda u: sin(u, 24))], "LegHR": [rx(Lw, lambda u: sin(u, 24))],
        "LegFR": [rx(Lw, lambda u: sin(u, 24, 0.5))], "LegHL": [rx(Lw, lambda u: sin(u, 24, 0.5))],
        "root": [py(Lw, lambda u: 2.5 * abs(math.sin(TAU * u))), rz(Lw, lambda u: sin(u, 2))],
        "neck": [rx(Lw, lambda u: sin(u, 3, 0.1, 2))],
        "Tail": [rz(Lw, lambda u: sin(u, 14))],
    }
    return {"idle": (L, idle), "walk": (Lw, walk), "gallop": A.leap(L=0.6, height=16, spread=45, pitch=8)}


# ---------------------------------------------------------------- white wolf

def wolf_legs(L, swing, flex, pairs):
    """Thigh swings; the shin folds while the leg swings forward, then straightens."""
    out = {}
    for leg, phase in pairs.items():
        s = -1 if leg[0] == "H" else 1  # hind shins fold the other way
        out["Leg" + leg] = [rx(L, lambda u, p=phase: sin(u, swing, p))]
        out["Shin" + leg] = [rx(L, lambda u, p=phase, s=s: s * flex * lift(u, p + 0.25))]
        out["Paw" + leg] = [rx(L, lambda u, p=phase, s=s: -s * 0.6 * flex * lift(u, p + 0.25))]
    return out


def white_wolf():
    L = 2.4
    idle = {
        "root": [py(L, lambda u: 2 * (1 - math.cos(TAU * u)) / 2)],
        "neck": [ry(L, lambda u: lerp(u, [(0, 0), (0.2, 0), (0.35, 12), (0.55, 12), (0.7, 0), (1, 0)]))],
        "Jaw": [rx(L, lambda u: -4 - sin(u, 3, k=4))],
        "Tail": [ry(L, lambda u: sin(u, 10, k=2))],
        "Tail3": [ry(L, lambda u: sin(u, 10, -0.1, 2))],
        "EarL": [rx(L, lambda u: lerp(u, [(0, 0), (0.75, 0), (0.8, 25), (0.88, 0), (1, 0)]))],
    }
    Lw = 0.9
    walk = {**wolf_legs(Lw, 20, 30, {"FL": 0, "HR": 0.05, "FR": 0.5, "HL": 0.55}),
            "root": [py(Lw, lambda u: 2 * abs(math.sin(TAU * u)))],
            "neck": [rx(Lw, lambda u: sin(u, 3, 0.1, 2))],
            "Tail": [ry(Lw, lambda u: sin(u, 8))], "Tail3": [ry(Lw, lambda u: sin(u, 10, -0.15))]}
    Lg = 0.6
    reach = lambda u: lerp(u, [(0, -15), (0.2, 0), (0.4, 38), (0.65, 38), (0.85, -15), (1, -15)])  # noqa: E731
    push = lambda u: lerp(u, [(0, 20), (0.2, 0), (0.4, -35), (0.65, -35), (0.85, 20), (1, 20)])  # noqa: E731
    gallop = {
        "LegFL": [rx(Lg, reach)], "LegFR": [rx(Lg, lambda u: reach(u - 0.04))],
        "LegHL": [rx(Lg, push)], "LegHR": [rx(Lg, lambda u: push(u - 0.04))],
        "ShinFL": [rx(Lg, lambda u: -0.5 * reach(u))], "ShinFR": [rx(Lg, lambda u: -0.5 * reach(u - 0.04))],
        "ShinHL": [rx(Lg, lambda u: -0.5 * push(u))], "ShinHR": [rx(Lg, lambda u: -0.5 * push(u - 0.04))],
        "root": [py(Lg, lambda u: lerp(u, [(0, 0), (0.2, 4), (0.5, 22), (0.8, 4), (1, 0)])),
                 rx(Lg, lambda u: lerp(u, [(0, 0), (0.2, 7), (0.5, 0), (0.8, -7), (1, 0)]))],
        "neck": [rx(Lg, lambda u: -8 + sin(u, 4))],
        "Jaw": [rx(Lg, lambda u: -14)],
        "EarL": [rx(Lg, lambda u: 30)], "EarR": [rx(Lg, lambda u: 30)],
        "Tail": [rx(Lg, lambda u: -22 + sin(u, 8, 0.25))], "Tail3": [rx(Lg, lambda u: sin(u, 10))],
    }
    return {"idle": (L, idle), "walk": (Lw, walk), "gallop": (Lg, gallop)}


# ---------------------------------------------------------------- troll

def troll():
    L = 3.0
    idle = {
        "root": [py(L, lambda u: 3 * (1 - math.cos(TAU * u)) / 2)],
        "Torso": [rx(L, lambda u: sin(u, 2))],
        "ArmL": [rx(L, lambda u: sin(u, 4, 0.1))], "ArmR": [rx(L, lambda u: sin(u, 3, 0.35))],
        "Bat": [rx(L, lambda u: lerp(u, [(0, 0), (0.55, 0), (0.62, 12), (0.7, 0), (0.77, 12), (0.85, 0), (1, 0)]))],
        "neck": [ry(L, lambda u: lerp(u, [(0, 0), (0.15, 0), (0.25, -14), (0.45, -14), (0.55, 0), (1, 0)]))],
        "Jaw": [rx(L, lambda u: sin(u, 3, k=2) - 3)],
        "Ponytail": [rx(L, lambda u: sin(u, 3, 0.2))],
    }
    Lw = 1.2
    walk = {
        "LegL": [rx(Lw, lambda u: sin(u, 26))], "LegR": [rx(Lw, lambda u: sin(u, 26, 0.5))],
        "ArmL": [rx(Lw, lambda u: sin(u, 18, 0.5))], "ArmR": [rx(Lw, lambda u: sin(u, 12))],
        "root": [py(Lw, lambda u: 4 * abs(math.sin(TAU * u))), rz(Lw, lambda u: sin(u, 4, 0.25))],
        "Torso": [ry(Lw, lambda u: sin(u, 6))],
        "neck": [ry(Lw, lambda u: sin(u, -4))],
        "Ponytail": [rz(Lw, lambda u: sin(u, 8, 0.4))],
        "Bat": [rx(Lw, lambda u: sin(u, 6, 0.2, 2))],
    }
    Lg = 0.7
    gallop = {
        "LegL": [rx(Lg, lambda u: sin(u, 42))], "LegR": [rx(Lg, lambda u: sin(u, 42, 0.5))],
        "ArmL": [rx(Lg, lambda u: 8 + sin(u, 34, 0.5))], "ArmR": [rx(Lg, lambda u: 8 + sin(u, 22))],
        "root": [py(Lg, lambda u: 9 * abs(math.sin(TAU * u))), rz(Lg, lambda u: sin(u, 5, 0.25))],
        "Torso": [rx(Lg, lambda u: -10 + sin(u, 2, k=2)), ry(Lg, lambda u: sin(u, 8))],
        "neck": [rx(Lg, lambda u: 8)],
        "Jaw": [rx(Lg, lambda u: -12 + sin(u, 4, k=2))],
        "Bat": [rx(Lg, lambda u: 16 + sin(u, 8, 0.1, 2))],
        "Ponytail": [rx(Lg, lambda u: -8 + sin(u, 4, 0, 2))],
    }
    return {"idle": (L, idle), "walk": (Lw, walk), "gallop": (Lg, gallop)}


# ---------------------------------------------------------------- spine lizard

def lizard_legs(L, swing, up):
    """Sprawled steps: a leg sweeps back on the ground (yaw), then lifts (roll)
    and swings forward. Diagonal pairs move together."""
    out = {}
    for leg, phase in (("FL", 0), ("HR", 0), ("FR", 0.5), ("HL", 0.5)):
        sx = -1 if leg[1] == "L" else 1
        out["Leg" + leg] = [cyc(L, lambda u, p=phase, sx=sx: (0, sx * sin(u, swing, p), sx * up * lift(u, p + 0.25)))]
    return out


def spine_lizard():
    L = 3.0
    idle = {
        "root": [py(L, lambda u: 1.5 * (1 - math.cos(TAU * u)) / 2)],
        "neck": [rx(L, lambda u: lerp(u, [(0, 0), (0.3, 0), (0.45, 7), (0.7, 7), (0.85, 0), (1, 0)]))],
        "Jaw": [rx(L, lambda u: lerp(u, [(0, 0), (0.45, 0), (0.52, 16), (0.64, 16), (0.72, 0), (1, 0)]))],
        "Tail": [ry(L, lambda u: sin(u, 6))], "Tail2": [ry(L, lambda u: sin(u, 8, -0.12))],
    }
    Lw = 1.0
    walk = {**lizard_legs(Lw, 24, 16),
            "root": [ry(Lw, lambda u: sin(u, 6, 0.25)), py(Lw, lambda u: 1.5 * abs(math.sin(TAU * u)))],
            "neck": [ry(Lw, lambda u: sin(u, -6, 0.25))],
            "Tail": [ry(Lw, lambda u: sin(u, -10, 0.25))], "Tail2": [ry(Lw, lambda u: sin(u, -12, 0.1))]}
    Lg = 0.55
    gallop = {**lizard_legs(Lg, 34, 24),
              "root": [ry(Lg, lambda u: sin(u, 9, 0.25)), py(Lg, lambda u: 5 + 3 * abs(math.sin(TAU * u)))],
              "neck": [rx(Lg, lambda u: 8), ry(Lg, lambda u: sin(u, -9, 0.25))],
              "Jaw": [rx(Lg, lambda u: 10)],
              "Tail": [ry(Lg, lambda u: sin(u, -16, 0.25))], "Tail2": [ry(Lg, lambda u: sin(u, -18, 0.1))]}
    return {"idle": (L, idle), "walk": (Lw, walk), "gallop": (Lg, gallop)}


# ---------------------------------------------------------------- ice golem

def ice_golem():
    L = 3.0
    idle = {
        "root": [py(L, lambda u: 2.5 * (1 - math.cos(TAU * u)) / 2)],
        "Torso": [rx(L, lambda u: sin(u, 2.5))],
        "neck": [ry(L, lambda u: lerp(u, [(0, 0), (0.3, 0), (0.4, 10), (0.6, 10), (0.7, 0), (1, 0)]))],
        "ArmL": [rx(L, lambda u: sin(u, -2.5))], "ArmR": [rx(L, lambda u: sin(u, -2.5))],
        "Brow": [rx(L, lambda u: lerp(u, [(0, 0), (0.8, 0), (0.85, -8), (0.92, 0), (1, 0)]))],
    }
    Lw = 1.4
    walk = {
        "ArmL": [rx(Lw, lambda u: sin(u, 11))], "LegR": [rx(Lw, lambda u: sin(u, 13, 0.1))],
        "ArmR": [rx(Lw, lambda u: sin(u, 11, 0.5))], "LegL": [rx(Lw, lambda u: sin(u, 13, 0.6))],
        "ForearmL": [rx(Lw, lambda u: -8 * lift(u, 0.25))], "ForearmR": [rx(Lw, lambda u: -8 * lift(u, 0.75))],
        "root": [py(Lw, lambda u: 3 * abs(math.sin(TAU * u))), rz(Lw, lambda u: sin(u, 3.5, 0.25))],
        "Torso": [ry(Lw, lambda u: sin(u, 5))],
        "neck": [ry(Lw, lambda u: sin(u, -4))],
    }
    Lg = 0.8
    arms = lambda u: lerp(u, [(0, -12), (0.3, 18), (0.55, 18), (0.8, -12), (1, -12)])  # noqa: E731
    legs = lambda u: lerp(u, [(0, 22), (0.25, 22), (0.5, -18), (0.8, -18), (1, 22)])  # noqa: E731
    gallop = {
        "ArmL": [rx(Lg, arms)], "ArmR": [rx(Lg, lambda u: arms(u - 0.04))],
        "LegL": [rx(Lg, legs)], "LegR": [rx(Lg, lambda u: legs(u - 0.04))],
        "root": [py(Lg, lambda u: lerp(u, [(0, 0), (0.25, 4), (0.45, 12), (0.65, 4), (1, 0)])),
                 rx(Lg, lambda u: lerp(u, [(0, 0), (0.3, 6), (0.55, 0), (0.8, -5), (1, 0)]))],
        "Torso": [rx(Lg, lambda u: -4 + sin(u, 3))],
        "neck": [rx(Lg, lambda u: 6)],
    }
    return {"idle": (L, idle), "walk": (Lw, walk), "gallop": (Lg, gallop)}


# ---------------------------------------------------------------- ice drake

def ice_drake():
    L = 2.8
    idle = {
        "root": [py(L, lambda u: 2 * (1 - math.cos(TAU * u)) / 2)],
        "Torso": [rx(L, lambda u: sin(u, 1.5))],
        "neck": [ry(L, lambda u: lerp(u, [(0, 0), (0.2, 0), (0.3, 14), (0.5, 14), (0.6, -8), (0.75, -8), (0.85, 0), (1, 0)]))],
        "Jaw": [rx(L, lambda u: lerp(u, [(0, 0), (0.3, 0), (0.38, -12), (0.46, 0), (1, 0)]))],
        "Tail": [ry(L, lambda u: sin(u, 7))], "Tail2": [ry(L, lambda u: sin(u, 8, -0.1))],
        "Tail3": [ry(L, lambda u: sin(u, 12, -0.2))],
    }
    Lw = 1.0
    walk = {
        "ArmL": [rx(Lw, lambda u: sin(u, 18))], "LegR": [rx(Lw, lambda u: sin(u, 16, 0.05))],
        "ArmR": [rx(Lw, lambda u: sin(u, 18, 0.5))], "LegL": [rx(Lw, lambda u: sin(u, 16, 0.55))],
        "HandL": [rx(Lw, lambda u: -16 * lift(u, 0.25))], "HandR": [rx(Lw, lambda u: -16 * lift(u, 0.75))],
        "root": [py(Lw, lambda u: 2.5 * abs(math.sin(TAU * u))), rz(Lw, lambda u: sin(u, 3, 0.25))],
        "neck": [ry(Lw, lambda u: sin(u, -5))],
        "Tail": [ry(Lw, lambda u: sin(u, 9))], "Tail2": [ry(Lw, lambda u: sin(u, 10, -0.12))],
        "Tail3": [ry(Lw, lambda u: sin(u, 12, -0.24))],
    }
    Lg = 0.6
    arms = lambda u: lerp(u, [(0, -20), (0.2, 0), (0.4, 34), (0.65, 34), (0.85, -20), (1, -20)])  # noqa: E731
    legs = lambda u: lerp(u, [(0, 20), (0.2, 0), (0.4, -28), (0.65, -28), (0.85, 20), (1, 20)])  # noqa: E731
    gallop = {
        "ArmL": [rx(Lg, arms)], "ArmR": [rx(Lg, lambda u: arms(u - 0.04))],
        "LegL": [rx(Lg, legs)], "LegR": [rx(Lg, lambda u: legs(u - 0.04))],
        "root": [py(Lg, lambda u: lerp(u, [(0, 0), (0.2, 4), (0.5, 20), (0.8, 4), (1, 0)])),
                 rx(Lg, lambda u: lerp(u, [(0, 0), (0.2, 7), (0.5, 0), (0.8, -7), (1, 0)]))],
        "neck": [rx(Lg, lambda u: 8 + sin(u, 4))],
        "Jaw": [rx(Lg, lambda u: -10)],
        "Tail": [rx(Lg, lambda u: -14 + sin(u, 6, 0.25))], "Tail3": [rx(Lg, lambda u: sin(u, 12))],
    }
    return {"idle": (L, idle), "walk": (Lw, walk), "gallop": (Lg, gallop)}


RIGS = {"Boar": boar, "WhiteWolf": white_wolf, "Troll": troll, "SpineLizard": spine_lizard,
        "IceGolem": ice_golem, "IceDrake": ice_drake}


# ---------------------------------------------------------------- build + preview

def animated(fn):
    """(animal, model with idle/walk/gallop) for one builder in convert_designs."""
    a, model, _ = C.build(fn)
    groups = {g["name"]: g for g in model["groups"]}
    write_animations(model, groups, RIGS[a.name]())
    return a, model


def frames(model, W=300):
    """Preview frames: one 3/4 view, idle once, walk twice, gallop three times."""
    rest = posed(model)
    lo, hi = C.bounds(rest)
    c = (lo + hi) / 2
    radius = np.linalg.norm(hi - lo) / 2
    fov = 36
    dist = radius / np.tan(np.radians(fov) / 2) * 1.05
    v = np.array((-19, 10, -21), float)
    eye = c + v / np.linalg.norm(v) * dist
    out = []
    for name, n, loops in (("idle", 24, 1), ("walk", 14, 2), ("gallop", 10, 3)):
        anim = next(x for x in model["animations"] if x["name"] == name)
        for _ in range(loops):
            for i in range(n):
                parts = posed(model, anim, anim["length"] * i / n)
                for p in parts:
                    if p.name.startswith(C.PLAIN):
                        p.plain = True
                out.append(A.label(render(parts, eye=eye, target=c, W=W, H=W, fov=fov), [name], 16))
    return out


def one(name, out):
    fn = next(f for f in C.CREATURES if f.__name__.replace("_", "") == name.lower().replace("_", ""))
    a, model = animated(fn)
    path = C.save_model(a, model)
    shutil.copy(path, os.path.join(out, a.name + ".bbmodel"))
    fr = frames(model)
    A.gif(os.path.join(out, f"{a.name}_anims.gif"), fr, fps=20)
    # a still strip for checking without playing the GIF: 4 frames of each
    idx = [0, 6, 12, 18, 24, 27, 31, 34, 52, 54, 57, 59]
    strip = Image.new("RGB", (fr[0].width * 6, fr[0].height * 2))
    for j, i in enumerate(idx):
        strip.paste(fr[i], ((j % 6) * fr[0].width, (j // 6) * fr[0].height))
    strip.resize((strip.width // 2, strip.height // 2)).save(os.path.join(out, f"{a.name}_frames.png"))
    print("wrote", a.name)


if __name__ == "__main__":
    args = sys.argv[1:]
    if args and args[0] == "one":
        target = args[2] if len(args) > 2 else C.OUT
        os.makedirs(target, exist_ok=True)
        one(args[1], target)
    else:
        target = args[0] if args else C.OUT
        os.makedirs(target, exist_ok=True)
        for fn in C.CREATURES:
            one(fn.__name__, target)
