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

# The body, head to tail. torso (chest, neck, arms) and root (hips, tail, legs) are
# siblings pivoting at the waist, so opposite bends there make the S-curve.
FRONT = ["hi_head", "neck_joint", "neck", "torso"]
BACK = ["root", "tail", "tail_joint1", "tail_joint_2"]
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


def float_anim(L, amp, yaw, bob, lag=0.11, limb=14, head=0.6, jaw=None):
    """One looping float: a wave head -> tail of `amp` degrees pitch (and `yaw` side
    to side), the whole body bobbing `bob` units, limbs dangling behind."""
    T = {}
    chain = FRONT[::-1] + BACK  # torso outward to the head, root outward to the tail

    def bend(i, front):
        # each joint's phase lags the one before it along the body, so the wave runs
        # from the head down to the tail tip
        ph = -lag * (FRONT.index(chain[i]) if front else len(FRONT) + BACK.index(chain[i]))
        a = amp * (head if chain[i] == "hi_head" else 1)
        y = yaw * (head if chain[i] == "hi_head" else 1)
        sign = -1 if front else 1  # +X lifts a front bone and lowers a back one
        return lambda u: (sign * sin(u, a, ph), sin(u, y, ph + 0.25), 0)

    for i, name in enumerate(chain):
        T[name] = [cyc(L, bend(i, name in FRONT), 24)]
    for name in ("torso", "root"):  # both top-level: bob together so the waist stays joined
        T[name].append(cyc(L, lambda u: (0, sin(u, bob, -0.15), 0), 24, "position"))
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
        "idle": float_anim(3.2, 4, 2, 16, limb=8, jaw=lambda u: (-max(0, sin(u, 14, 0.1)), 0, 0)),
        # cruising: a longer wave, more side to side
        "walk": float_anim(1.8, 7, 5, 22, limb=14),
        # chasing: a fast, deep wave, legs streaming, jaws wide
        "gallop": float_anim(1.0, 10, 7, 28, lag=0.13, limb=22, head=0.4,
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
