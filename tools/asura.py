"""Asura (World 2, Crimson Lands, Legendary), from QM's model
(/mnt/project-files/animals/asura/Asura_QM.bbmodel: a Blockbench 4.9 slate warrior with a
horned helm, cyan hair, a cape and a big sword, posed mid-stride; left arm and leg only).

Run: python3 tools/asura.py [base.bbmodel]

What it changes, keeping QM's shapes and pose:
- 4.9 -> 5.0 file (groups list), scaled up SCALE times, feet put on the ground
- the painted texture -> solid colours, each part the average of its own texture
  snapped to a small palette (slate, light slate, cyan, black)
- flat zero-thickness parts (cape, mask, blade edges, side panels) get 1 unit of depth
- a black visor with two red glowing eyes on the face (the texture's red eyes)
- the right leg and right arm, mirrored from the left; the right arm hangs (no sword)
- bones renamed for the game: head -> neck, left_leg/right_leg -> LegFL/LegFR (dust)
- idle, walk and gallop (run) written on top of QM's pose
Multi-axis rests: preview and convert with ZYX (--zyx).
"""

import base64
import copy
import io
import json
import math
import os
import sys
import uuid

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import horse_rig as HR  # noqa: E402
import snake_design as S  # noqa: E402
from bb_scale import scale  # noqa: E402
from horse_rig import write_animations  # noqa: E402
from ivory_spider import iter_nodes, to_v5  # noqa: E402
from partlib import render  # noqa: E402
from snake_rig import track  # noqa: E402
import animal_designs as A  # noqa: E402

ROOT = os.path.join(os.path.dirname(__file__), "..")
NAME = "Asura"
OUT = "/mnt/project-files/animals/asura"
BASE = os.path.join(OUT, "Asura_QM.bbmodel")
SCALE = 1.6

PALETTE = {"slate": (72, 84, 85), "light": (100, 110, 111), "cyan": (121, 191, 202), "black": (23, 18, 19),
           "red": (255, 40, 40)}
TEX = {n: i for i, n in enumerate(PALETTE)}
RENAME = {"head": "neck", "left_leg": "LegFL"}


def texture_colors(m):
    tex = Image.open(io.BytesIO(base64.b64decode(m["textures"][0]["source"].split(",", 1)[1]))).convert("RGBA")
    out = {}
    for e in m["elements"]:
        px = []
        for f in e["faces"].values():
            if f.get("texture") is None or "uv" not in f:
                continue
            u0, v0, u1, v1 = f["uv"]
            a, b = sorted((u0, u1))
            c, d = sorted((v0, v1))
            arr = np.array(tex.crop((int(a), int(c), max(int(b), int(a) + 1), max(int(d), int(c) + 1)))).reshape(-1, 4)
            arr = arr[arr[:, 3] > 0][:, :3]
            if len(arr):
                px.append(arr.mean(0))
        rgb = np.mean(px, 0) if px else np.array(PALETTE["slate"])
        out[e["uuid"]] = min(("slate", "light", "cyan", "black"), key=lambda n: np.sum((np.array(PALETTE[n]) - rgb) ** 2))
    return out


def paint(e, col):
    for f in e["faces"].values():
        f["texture"] = TEX[col]
        f["uv"] = [0, 0, 16, 16]


def mirror_rot(r):
    return [r[0], -r[1], -r[2]]


def mirror_chain(node, groups, elements, rename):
    """Copy a group subtree to the other side: x negated, y/z rotations negated."""
    g = groups[node["uuid"]]
    ng = copy.deepcopy(g)
    ng.update(uuid=str(uuid.uuid4()), name=rename(g["name"]), origin=[-g["origin"][0], g["origin"][1], g["origin"][2]],
              rotation=mirror_rot(g.get("rotation") or [0, 0, 0]))
    new_groups = [ng]
    out = {"uuid": ng["uuid"], "isOpen": True, "children": []}
    for c in node["children"]:
        if isinstance(c, dict):
            if groups[c["uuid"]]["name"] == "sword":
                continue
            sub, gs = mirror_chain(c, groups, elements, rename)
            out["children"].append(sub)
            new_groups += gs
        else:
            e = copy.deepcopy(elements[c])
            f, t = e["from"], e["to"]
            e.update(uuid=str(uuid.uuid4()), **{"from": [-t[0], f[1], f[2]], "to": [-f[0], t[1], t[2]]},
                     origin=[-e["origin"][0], e["origin"][1], e["origin"][2]], rotation=mirror_rot(e.get("rotation") or [0, 0, 0]))
            elements[e["uuid"]] = e
            out["children"].append(e["uuid"])
    return out, new_groups


def build(base=BASE):
    m = json.load(open(base))
    to_v5(m)
    cols = texture_colors(m)
    for e in m["elements"]:
        for i in range(3):  # no 2D planes: give flat parts depth
            if abs(e["to"][i] - e["from"][i]) < 1e-6:
                e["from"][i] -= 0.5
                e["to"][i] += 0.5
        paint(e, cols[e["uuid"]])
    groups = {g["uuid"]: g for g in m["groups"]}
    elements = {e["uuid"]: e for e in m["elements"]}
    byname = {groups[n["uuid"]]["name"]: n for n in iter_nodes(m["outliner"])}

    # the right leg and arm, mirrored from the left
    leg, gs = mirror_chain(byname["left_leg"], groups, elements, lambda n: n.replace("left", "right"))
    byname["pelvis"]["children"].append(leg)
    m["groups"] += gs
    arm, gs = mirror_chain(byname["left_shoulder"], groups, elements, lambda n: n.replace("left", "right"))
    byname["body"]["children"].append(arm)
    m["groups"] += gs
    for g in gs:  # the empty hand hangs: the shoulder pad keeps its tilt, the arm and forearm come down
        if g["name"] == "right_arm":
            g["rotation"] = [0, 0, 0]
        elif g["name"] == "right_forearm":
            g["rotation"] = [-20, 0, 0]
        elif g["name"] == "right_shoulder":
            g["rotation"] = [0, 0, 10]
    m["elements"] = list(elements.values())

    # visor and red eyes on the face, under the helm
    neck = byname["head"]
    for name, lo, hi, col in (("Visor", (-3, 54.5, -1.6), (3, 57, -1), "black"),
                              ("GlowEyeL", (-2.3, 55.3, -1.9), (-0.8, 56.3, -1.5), "red"),
                              ("GlowEyeR", (0.8, 55.3, -1.9), (2.3, 56.3, -1.5), "red")):
        e = copy.deepcopy(m["elements"][0])
        e.update(name=name, uuid=str(uuid.uuid4()), rotation=[0, 0, 0], **{"from": list(lo), "to": list(hi)},
                 origin=[(a + b) / 2 for a, b in zip(lo, hi)])
        paint(e, col)
        m["elements"].append(e)
        neck["children"].append(e["uuid"])

    for g in m["groups"]:
        g["name"] = {"head": "neck", "left_leg": "LegFL", "right_leg": "LegFR"}.get(g["name"], g["name"])
    m["textures"] = [S.solid_texture(n, c) for n, c in PALETTE.items()]
    m["name"] = NAME
    m["animations"] = []
    scale(m, SCALE)

    # feet on the ground
    HR.EULER = "ZYX"
    low = min(np.vstack(p.polys)[:, 1].min() for p in S.posed(m)) * S.BB
    for e in m["elements"]:
        e["from"][1] -= low
        e["to"][1] -= low
        e["origin"][1] -= low
    for g in m["groups"]:
        g["origin"][1] -= low
    return m


TAU = 2 * math.pi


def animations():
    L = 3.0
    idle = {"body": [track(L, lambda u: (1.5 * math.sin(TAU * u), 0, 0), 12)],
            "neck": [track(L, lambda u: (0, 10 * math.sin(TAU * u), 0), 12)],
            "cape": [track(L, lambda u: (4 + 4 * math.sin(TAU * u * 2), 0, 0), 12)],
            "left_forearm": [track(L, lambda u: (3 * math.sin(TAU * u), 0, 0), 12)],
            "root": [track(L, lambda u: (0, 0, 0), 4), track(L, lambda u: (0, 1.5 * math.sin(TAU * u * 2) - 1.5, 0), 12, channel="position")]}

    def stride(Lc, amp, knee, lean, bob, cape, n=16):
        return {"LegFL": [track(Lc, lambda u: (amp * math.sin(TAU * u), 0, 0), n)],
                "LegFR": [track(Lc, lambda u: (-amp * math.sin(TAU * u), 0, 0), n)],
                "left_calve": [track(Lc, lambda u: (-knee * max(0.0, math.sin(TAU * u + 1.6)), 0, 0), n)],
                "right_calve": [track(Lc, lambda u: (-knee * max(0.0, math.sin(TAU * u + 1.6 + math.pi)), 0, 0), n)],
                "body": [track(Lc, lambda u: (-lean, 4 * math.sin(TAU * u), 0), n)],
                "right_arm": [track(Lc, lambda u: (amp * 0.8 * math.sin(TAU * u), 0, 0), n)],
                "neck": [track(Lc, lambda u: (lean * 0.5, 0, 0), n)],
                "cape": [track(Lc, lambda u: (cape + 6 * math.sin(TAU * u * 2), 0, 0), n)],
                "root": [track(Lc, lambda u: (0, 0, 0), 4),
                         track(Lc, lambda u: (0, bob * abs(math.sin(TAU * u)), 0), n, channel="position")]}

    walk = stride(1.0, 22, 30, 4, 4, 12)
    gallop = stride(0.6, 38, 55, 14, 10, 40)
    return {"idle": (L, idle), "walk": (1.0, walk), "gallop": (0.6, gallop)}


def main(base=BASE, out=OUT):
    m = build(base)
    groups = {g["name"]: g for g in m["groups"]}
    write_animations(m, groups, animations())
    os.makedirs(out, exist_ok=True)
    for path in (os.path.join(ROOT, "designs", "crimson", NAME + ".bbmodel"), os.path.join(out, NAME + ".bbmodel")):
        with open(path, "w") as f:
            json.dump(m, f, separators=(",", ":"))
    HR.EULER = "ZYX"
    W, H = 560, 560
    cams = [dict(eye=(-12, 9, -18), target=(0, 5.5, 0)), dict(eye=(-22, 6, 0), target=(0, 5.5, 0)),
            dict(eye=(12, 10, 18), target=(0, 5.5, 0)), dict(eye=(0, 7, -20), target=(0, 6, 0))]
    sheet = Image.new("RGB", (W * 2, H * 2))
    parts = S.posed(m)
    for p in parts:
        p.neon = p.name.startswith("Glow")
    for i, cam in enumerate(cams):
        sheet.paste(render(parts, W=W, H=H, fov=40, **cam), ((i % 2) * W, (i // 2) * H))
    sheet.save(os.path.join(out, NAME + ".png"))
    if "--still" in sys.argv:
        return
    frames = []
    for name, n, loops in (("idle", 24, 1), ("walk", 20, 2), ("gallop", 12, 3)):
        anim = next(a for a in m["animations"] if a["name"] == name)
        for _ in range(loops):
            for i in range(n):
                ps = S.posed(m, anim, anim["length"] * i / n)
                im = Image.new("RGB", (W * 2, H))
                for c in (0, 1):
                    im.paste(render(ps, W=W, H=H, fov=40, **cams[c]), (c * W, 0))
                frames.append(A.label(im, ["run" if name == "gallop" else name] * 2))
    A.gif(os.path.join(out, NAME + "_anims.gif"), frames, fps=20)
    print("wrote", len(m["elements"]), "elements")


if __name__ == "__main__":
    main(*[a for a in sys.argv[1:] if not a.startswith("--")])
