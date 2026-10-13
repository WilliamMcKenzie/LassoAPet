"""Ivory Spider (World 2, Crimson Lands, Epic), built from QM's base model
(/mnt/project-files/animals/ivory_spider/small_tarantula_QM.bbmodel, a Blockbench 4.9
tarantula with three-joint legs and a walk).

Run: python3 tools/ivory_spider.py [base.bbmodel]

What it changes:
- 4.9 -> 5.0 file (groups list; rotation keys negated in x and y, which Blockbench 5
  does when it opens a 4.x file), scaled up SCALE times to game size
- the painted texture -> solid colours: ivory body and legs, bone-grey joints and feet
- flat zero-thickness parts (leg tufts, abdomen side and top plates) removed; leg
  tips, fangs and spinnerets given real thickness (QM: no 2D planes)
- four red eyes on the face, no pupils
- bone "mouth" renamed "neck" (the game's lasso loop)
- idle loops; gallop = the walk sped up; attack_1 dropped
Hand-made multi-axis rests: preview and convert with ZYX (--zyx).
"""

import base64
import copy
import io
import json
import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import horse_rig as HR  # noqa: E402
import snake_design as S  # noqa: E402
from bb_scale import scale  # noqa: E402
from partlib import render  # noqa: E402
import animal_designs as A  # noqa: E402

ROOT = os.path.join(os.path.dirname(__file__), "..")
NAME = "IvorySpider"
OUT = "/mnt/project-files/animals/ivory_spider"
BASE = os.path.join(OUT, "small_tarantula_QM.bbmodel")
SCALE = 2.5
GALLOP = 0.55  # seconds per run loop (the walk is 1.33)

COLORS = {"ivory": (246, 240, 226), "bone": (200, 190, 174), "tip": (150, 138, 126), "red": (220, 24, 40)}
TEX = {n: i for i, n in enumerate(COLORS)}


def flat_axes(e):
    return [i for i in range(3) if abs(e["to"][i] - e["from"][i]) < 1e-6]


def to_v5(m):
    """Move 4.x outliner groups into a groups list (5.0 keeps them apart)."""
    groups = []

    def walk(nodes):
        out = []
        for n in nodes:
            if isinstance(n, dict):
                g = {k: v for k, v in n.items() if k != "children"}
                g.setdefault("rotation", [0, 0, 0])
                groups.append(g)
                out.append({"uuid": n["uuid"], "isOpen": True, "children": walk(n["children"])})
            else:
                out.append(n)
        return out

    m["outliner"] = walk(m["outliner"])
    m["groups"] = groups
    m["meta"]["format_version"] = "5.0"
    for a in m.get("animations", []):
        for an in a["animators"].values():
            for kf in an.get("keyframes", []):
                if kf["channel"] == "rotation":
                    for dp in kf["data_points"]:
                        dp["x"] = -S.num(dp["x"])
                        dp["y"] = -S.num(dp["y"])


def build(base=BASE):
    m = json.load(open(base))
    to_v5(m)
    gname = {}
    for g in m["groups"]:
        if g["name"] == "mouth":
            g["name"] = "neck"
    parent_of = {}

    def walk(nodes, parent):
        for n in nodes:
            if isinstance(n, dict):
                walk(n["children"], n)
            else:
                parent_of[n] = parent
    walk(m["outliner"], None)
    gname = {g["uuid"]: g["name"] for g in m["groups"]}

    keep = []
    for e in m["elements"]:
        bone = gname[parent_of[e["uuid"]]["uuid"]]
        flat = flat_axes(e)
        rotated = any(abs(r) > 1e-6 for r in (e.get("rotation") or [0, 0, 0]))
        if flat and (rotated or bone == "abdomen" and e["to"][2] - e["from"][2] < 12 and e["to"][0] - e["from"][0] < 1):
            # tufts and side/top plates: drop (spinnerets are flat in x too: thicken those)
            if bone == "abdomen" and e["from"][2] >= 17:
                pass
            else:
                continue
        for i in flat:  # leg tips, fangs, spinnerets: give them 2 units of depth
            e["from"][i] -= 1
            e["to"][i] += 1
        if "end" in bone:
            col = "tip"
        elif "leg_mid" in bone and e["to"][0] - e["from"][0] == 3:
            col = "bone"  # the knee knob
        elif bone == "neck" and e["from"][1] < 0:
            col = "tip"  # fangs: half as long, so they don't poke through the ground
            e["from"][1] = -1
        elif bone == "abdomen" and e["from"][2] >= 17:
            col = "bone"  # spinnerets
        else:
            col = "ivory"
        for f in e["faces"].values():
            f["texture"] = TEX[col]
            f["uv"] = [0, 0, 16, 16]
        keep.append(e)
    m["elements"] = keep
    alive = {e["uuid"] for e in keep}
    for n in iter_nodes(m["outliner"]):
        n["children"] = [c for c in n["children"] if isinstance(c, dict) or c in alive]

    # four red eyes on the face (the mouth block's front at z = -10): two big, two small
    neck = next(n for n in iter_nodes(m["outliner"]) if gname[n["uuid"]] == "neck")
    for name, lo, hi in (("EyeL", (-2.6, 2.6, -10.3), (-0.6, 4.4, -10)), ("EyeR", (0.6, 2.6, -10.3), (2.6, 4.4, -10)),
                         ("EyeOuterL", (-4.4, 3.6, -10.3), (-3.2, 4.8, -10)), ("EyeOuterR", (3.2, 3.6, -10.3), (4.4, 4.8, -10))):
        e = copy.deepcopy(keep[0])
        e.update(name=name, uuid=S.uid(), rotation=[0, 0, 0], **{"from": list(lo), "to": list(hi)},
                 origin=[(a + b) / 2 for a, b in zip(lo, hi)])
        for f in e["faces"].values():
            f["texture"] = TEX["red"]
        m["elements"].append(e)
        neck["children"].append(e["uuid"])

    m["textures"] = [S.solid_texture(n, c) for n, c in COLORS.items()]
    m["name"] = NAME
    scale(m, SCALE)

    anims = {a["name"]: a for a in m["animations"]}
    idle, walk_a = anims["idle"], anims["walk"]
    idle["loop"] = "loop"
    gallop = copy.deepcopy(walk_a)
    k = GALLOP / walk_a["length"]
    gallop.update(name="gallop", uuid=S.uid(), length=GALLOP)
    for an in gallop["animators"].values():
        for kf in an.get("keyframes", []):
            kf["time"] = round(kf["time"] * k, 4)
            kf["uuid"] = S.uid()
    m["animations"] = [idle, walk_a, gallop]
    return m


def iter_nodes(nodes):
    for n in nodes:
        if isinstance(n, dict):
            yield n
            yield from iter_nodes(n["children"])


def main(base=BASE, out=OUT):
    HR.EULER = "ZYX"
    m = build(base)
    for path in (os.path.join(ROOT, "designs", "crimson", NAME + ".bbmodel"), os.path.join(out, NAME + ".bbmodel")):
        with open(path, "w") as f:
            json.dump(m, f, separators=(",", ":"))
    W, H = 560, 440
    cams = [dict(eye=(-18, 11, -20), target=(0, 1.5, 0)), dict(eye=(-26, 4, 0), target=(0, 1.5, 0)),
            dict(eye=(14, 14, 22), target=(0, 1.5, 0)), dict(eye=(-2, 4, -16), target=(0, 1.5, -1))]
    sheet = Image.new("RGB", (W * 2, H * 2))
    parts = S.posed(m)
    for i, cam in enumerate(cams):
        sheet.paste(render(parts, W=W, H=H, fov=40, **cam), ((i % 2) * W, (i // 2) * H))
    sheet.save(os.path.join(out, NAME + ".png"))
    frames = []
    for name, n, loops in (("idle", 20, 2), ("walk", 24, 2), ("gallop", 11, 4)):
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
    main(*sys.argv[1:])
