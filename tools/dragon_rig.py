"""The Godlands dragon boss: QM's ivory_wyvern_1.bbmodel (Oct 3), an Eastern dragon
that floats with its legs hanging, scaled up 2x with floating animations.

Run: python3 tools/dragon_rig.py [qm.bbmodel] [preview_dir]
Writes designs/godlands/Dragon.bbmodel (idle, walk, gallop) and preview GIFs.

QM's two block-shaped meshes in the head become plain cubes (bbmodel_to_luau only
takes wedge and pyramid meshes). Every animation is the body snaking through the air:
a wave runs head to tail (pitch, plus a smaller side-to-side yaw), the whole body
bobs, the arms and legs dangle behind the wave, and the head and jaw add the rest.
QM's rotations are Blockbench's (ZYX): convert with bbmodel_to_luau.py --zyx.
"""

import json
import math
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import animal_designs as A  # noqa: E402
import horse_rig as HR  # noqa: E402
from convert_rig import cyc, sin  # noqa: E402
from horse_rig import write_animations  # noqa: E402
from partlib import render  # noqa: E402
from snake_design import posed  # noqa: E402

ROOT = os.path.join(os.path.dirname(__file__), "..")
SRC = os.path.join(ROOT, "designs", "godlands", "Dragon_QM.bbmodel")  # QM's ivory_wyvern_1, as sent
OUT = os.path.join(ROOT, "designs", "godlands", "Dragon.bbmodel")
PREVIEW = "/mnt/project-files/animals/godlands"
K = 2  # QM: 2x, about the Large size tier
FLOAT = 3.0  # studs between the lowest dangling claw and the ground in the previews

LIMBS = {"left_arm": 0.0, "right_arm": 0.5, "left_leg": 0.25, "right_leg": 0.75}


def scale(m, k):
    for e in m["elements"]:
        for key in ("from", "to", "origin"):
            if key in e:
                e[key] = [v * k for v in e[key]]
        if e.get("type") == "mesh":
            e["vertices"] = {n: [v * k for v in p] for n, p in e["vertices"].items()}
    for g in m["groups"]:
        g["origin"] = [v * k for v in g["origin"]]
    if "visible_box" in m:
        m["visible_box"] = [v * k for v in m["visible_box"]]


def boxes_to_cubes(m):
    """8-vertex box meshes -> cubes with the same origin, rotation and colour."""
    for e in m["elements"]:
        if e.get("type") != "mesh" or len(e["vertices"]) != 8:
            continue
        V = np.array(list(e["vertices"].values()), float)
        o = np.array(e["origin"], float)
        lo, hi = V.min(0), V.max(0)
        assert len({tuple(np.round(v, 3)) for v in V}) == 8 and all(
            any(np.isclose(v[i], (lo[i], hi[i])).any() for i in range(3)) for v in V), e["name"] + " isn't a box"
        f = next(iter(e["faces"].values()))
        us, vs = zip(*f["uv"].values())
        uv = [min(us), min(vs), max(us), max(vs)]
        e.update({"type": "cube", "from": list(o + lo), "to": list(o + hi), "autouv": 0, "box_uv": False,
                  "faces": {s: {"uv": uv, "texture": f["texture"]} for s in ("north", "east", "south", "west", "up", "down")}})
        del e["vertices"]


BODY = ["hi_head", "neck_joint", "neck", "torso", "root", "tail", "tail_joint1", "tail_joint_2"]  # head to tail
PARENT = {"hi_head": "neck_joint", "neck_joint": "neck", "neck": "torso", "tail": "root",
          "tail_joint1": "tail", "tail_joint_2": "tail_joint1"}
BODY_LEN = 420  # Blockbench units, head to tail tip at 2x


def float_anim(L, amp, yaw, waves=1.0, limb=14, jaw=None):
    """One looping float: a sine wave travelling head -> tail along the body.

    Each segment's slope (head to tail) is amp * sin(2 pi (u - waves * i / 8)) degrees,
    i its place along BODY; a bone's keyframe is its slope minus its parent's (the two
    top-level bones, torso and root, take it whole). `yaw` does the same side to side.
    The waist rides the wave's height there, so the whole body bobs with it."""
    T = {}

    def theta(i, u, a, ph=0.0):
        return sin(u, a, ph - waves * i / len(BODY))

    for i, name in enumerate(BODY):
        par = BODY.index(PARENT[name]) if name in PARENT else None

        def f(u, i=i, par=par):
            x = theta(i, u, amp) - (theta(par, u, amp) if par is not None else 0)
            y = theta(i, u, yaw) - (theta(par, u, yaw) if par is not None else 0)
            return (-x, y, 0)  # +X lifts a head-pointing bone and lowers a tail-pointing one: both slope down

        T[name] = [cyc(L, f, 24)]
    # height of the wave at the waist (between torso and root): the integral of the slope
    h = BODY_LEN / (2 * math.pi * waves) * math.radians(amp)
    for name in ("torso", "root"):
        T[name].append(cyc(L, lambda u: (0, sin(u, h, 0.25 - waves * 3.5 / len(BODY)), 0), 24, "position"))
    for name, ph in LIMBS.items():
        T[name] = [cyc(L, lambda u, ph=ph: (sin(u, limb, ph - 0.3), 0, sin(u, limb * 0.3, ph)), 24)]
    for name in ("left_calve", "right_calve", "left_forearm", "right_forearm"):
        ph = LIMBS[name.replace("calve", "leg").replace("forearm", "arm")]
        T[name] = [cyc(L, lambda u, ph=ph: (sin(u, limb * 0.6, ph - 0.45), 0, 0), 24)]
    if jaw:
        T["jaw"] = [cyc(L, jaw, 24)]
    return L, T


def animations():
    return {
        # hovering in place: a slow, lazy ripple, the mouth opening a little to breathe
        "idle": float_anim(3.2, 10, 3, limb=8, jaw=lambda u: (-max(0, sin(u, 14, 0.1)), 0, 0)),
        # cruising: a bigger wave
        "walk": float_anim(1.8, 16, 4, limb=14),
        # chasing: a fast, deep wave, legs streaming, jaws wide
        "gallop": float_anim(1.0, 22, 5, limb=22,
                             jaw=lambda u: (-18 - sin(u, 8, 0.0, 2), 0, 0)),
    }


def lifted(parts, dy):
    for p in parts:
        p.polys = [q + np.array([0, dy, 0]) for q in p.polys]
    return parts


def horse(x):
    HR.EULER = "XYZ"
    m = json.load(open(os.path.join(ROOT, "designs", "horses", "Horse9_Leap.bbmodel")))
    parts = HR.pose(m, None, 0) if "groups" in m else []
    for p in parts:
        p.polys = [q + np.array([x, 0, 0]) for q in p.polys]
    return parts


def main(src=SRC, out=PREVIEW):
    m = json.load(open(src))
    scale(m, K)
    boxes_to_cubes(m)
    write_animations(m, {g["name"]: g for g in m["groups"]}, animations())
    m["name"] = "Dragon"
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w") as f:
        json.dump(m, f, separators=(",", ":"))
    HR.EULER = "ZYX"
    rest = posed(m)
    dy = FLOAT - min(q[:, 1].min() for p in rest for q in p.polys)  # the same lift every frame, so the bob shows
    rest = lifted(rest, dy)
    pts = np.concatenate([q for p in rest for q in p.polys])
    lo, hi = pts.min(0), pts.max(0)
    c = (lo + hi) / 2
    r = np.linalg.norm(hi - lo) / 2
    fov = 30
    views = {"3/4": (35, 14), "side": (90, 6)}

    def eye(view):
        y, p = (math.radians(a) for a in views[view])
        d = np.array([-math.sin(y) * math.cos(p), math.sin(p), -math.cos(y) * math.cos(p)])
        return c + d * r / math.tan(math.radians(fov) / 2) * 1.1

    # a still with a Horse beside it for scale
    HR.EULER = "XYZ"
    hparts = horse(-r * 0.9)
    HR.EULER = "ZYX"
    still = Image.new("RGB", (1280, 640))
    for i, v in enumerate(views):
        still.paste(render(rest + hparts, eye=eye(v), target=c, W=640, H=640, fov=fov), (i * 640, 0))
    still.save(os.path.join(out, "Dragon_2x.png"))
    frames = []
    for anim in m["animations"]:
        n = round(anim["length"] * 12)
        for loop in range(1 if anim["length"] > 2 else 2):
            for i in range(n):
                parts = lifted(posed(m, anim, anim["length"] * i / n), dy)
                f = Image.new("RGB", (800, 400))
                for j, v in enumerate(views):
                    f.paste(render(parts, eye=eye(v), target=c, W=400, H=400, fov=fov), (j * 400, 0))
                frames.append(A.label(f, [anim["name"]], 18))
    A.gif(os.path.join(out, "Dragon_anims.gif"), frames, fps=12)
    print("wrote", OUT, len(frames), "frames")


if __name__ == "__main__":
    main(*sys.argv[1:])
