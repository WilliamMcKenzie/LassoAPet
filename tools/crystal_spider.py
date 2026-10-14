"""Crystal Spider: World 2's Crystal Cavern spider, built on the bones, pivots and
animations of the Minecraft tarantula QM sent (designs/crystal/small_tarantula_ref.bbmodel).

Run: python3 tools/crystal_spider.py [out_dir]

Kept from the reference: every bone (root, abdomen, body, mouth, the 8 three-part legs),
their pivots and rest turns, and its pose. The idle, walk and run are our own (a tetrapod gait).
Restyled for us: the hair planes and flat bits are gone (QM: no 2D planes); each leg is
three real blocks with a cyan crystal end; the body is slate blue with our plate eyes on
the head, two cyan pyramid fangs, and three crystals (cube shaft + pyramid tip, cyan and
pink like the cavern props) growing from the abdomen. Scaled up K times from Minecraft size.
"""

import copy
import json
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import horse_rig  # noqa: E402
import snake_design as S  # noqa: E402
from partlib import render  # noqa: E402
import animal_designs as A  # noqa: E402

horse_rig.EULER = "ZYX"  # the reference was made in Blockbench with multi-axis rest turns
ROOT = os.path.join(os.path.dirname(__file__), "..")
REF = os.path.join(ROOT, "designs", "crystal", "small_tarantula_ref.bbmodel")
K = 2.5
COLORS = {"body": (96, 108, 200), "dark": (66, 74, 152), "cyan": (0, 190, 231), "pink": (229, 131, 251),
          "white": (255, 255, 255), "pupil": (24, 20, 32)}
TEX = {n: i for i, n in enumerate(COLORS)}


def cube(name, lo, hi, tex, rot=None, origin=None):
    lo, hi = np.array(lo, float) * K, np.array(hi, float) * K
    o = (np.array(origin, float) * K) if origin is not None else (lo + hi) / 2
    return {"name": name, "type": "cube", "uuid": S.uid(), "box_uv": False, "autouv": 0, "color": 0,
            "from": [round(x, 4) for x in lo], "to": [round(x, 4) for x in hi], "origin": [round(x, 4) for x in o],
            "rotation": list(rot or (0, 0, 0)),
            "faces": {f: {"uv": [0, 0, 1, 1], "texture": tex} for f in ("north", "east", "south", "west", "up", "down")}}


def pyramid(name, base, w, d, h, tex, rot=(0, 0, 0)):
    """Square-ish pyramid: base centred at `base` (reference units), w x d, apex h along local +y."""
    o = np.array(base, float) * K
    a, b, t = w * K / 2, d * K / 2, h * K
    v = {"b0": [-a, 0, -b], "b1": [a, 0, -b], "b2": [a, 0, b], "b3": [-a, 0, b], "t": [0, t, 0]}
    faces = {"base": ["b0", "b1", "b2", "b3"], "s0": ["b0", "b1", "t"], "s1": ["b1", "b2", "t"],
             "s2": ["b2", "b3", "t"], "s3": ["b3", "b0", "t"]}
    return {"name": name, "type": "mesh", "uuid": S.uid(), "color": 0, "origin": [round(x, 4) for x in o], "rotation": list(rot),
            "vertices": v, "faces": {k: {"texture": tex, "vertices": vs, "uv": {q: [0, 0] for q in vs}} for k, vs in faces.items()}}


def crystal(name, base, w, hs, ht, tex, rot):
    """Cube shaft and pyramid tip sharing one origin (the base) and tilt."""
    x, y, z = base
    shaft = cube(name, (x - w / 2, y - 0.8, z - w / 2), (x + w / 2, y + hs, z + w / 2), tex, rot, origin=base)
    tip = pyramid(name + "Tip", base, w, w, ht, tex, rot)
    tip["vertices"] = {k: [v[0], v[1] + hs * K, v[2]] for k, v in tip["vertices"].items()}
    return [shaft, tip]


def euler_zyx(R):
    """Blockbench angles (degrees, R = Rz Ry Rx) of a rotation matrix."""
    import math
    ry = math.asin(max(-1.0, min(1.0, -R[2, 0])))
    rx = math.atan2(R[2, 1], R[2, 2])
    rz = math.atan2(R[1, 0], R[0, 0])
    return [round(math.degrees(a), 4) for a in (rx, ry, rz)]


def bake_rests(model):
    """Bake every bone's rest turn into its blocks, so all bones rest at 0 (Studio, Oct 13: the
    legs' rest turns didn't come through in Roblox, leaving them flat). Each block gets its bone
    chain's rest transform folded into its own position and rotation; pivots move with them."""
    gmap = {g["uuid"]: g for g in model["groups"]}
    emap = {e["uuid"]: e for e in model["elements"]}
    rot = horse_rig.rotm

    def walk(node, M):
        if isinstance(node, str):
            e = emap[node]
            R0 = rot(np.array(e.get("rotation") or (0, 0, 0), float))
            o = np.array(e["origin"], float)
            Ro, to = M[:3, :3], M[:3, 3]
            if e["type"] == "cube":
                lo, hi = np.array(e["from"], float), np.array(e["to"], float)
                c = R0 @ ((lo + hi) / 2 - o) + o  # the block's centre at rest, in its bone's frame
                c2 = Ro @ c + to
                half = (hi - lo) / 2
                e["from"], e["to"] = [round(x, 4) for x in c2 - half], [round(x, 4) for x in c2 + half]
                e["origin"] = [round(x, 4) for x in c2]
            else:
                e["origin"] = [round(x, 4) for x in Ro @ o + to]
            e["rotation"] = euler_zyx(Ro @ R0)
            return
        g = gmap[node["uuid"]]
        o = np.array(g["origin"], float)
        L = np.eye(4)
        R = rot(np.array(g.get("rotation") or (0, 0, 0), float))
        L[:3, :3] = R
        L[:3, 3] = o - R @ o
        M2 = M @ L
        g["origin"] = [round(x, 4) for x in M[:3, :3] @ o + M[:3, 3]]
        g["rotation"] = [0, 0, 0]
        for c in node["children"]:
            walk(c, M2)

    for n in model["outliner"]:
        walk(n, np.eye(4))


def build():
    ref = json.load(open(REF))
    # the reference is Blockbench 4.9: its groups live inside the outliner
    ref_groups = []

    def collect(node):
        if isinstance(node, dict):
            ref_groups.append({k: v for k, v in node.items() if k != "children"})
            for c in node["children"]:
                collect(c)
    for n in ref["outliner"]:
        collect(n)
    groups = {g["uuid"]: g for g in ref_groups}
    emap = {e["uuid"]: e for e in ref["elements"]}
    elements = []

    def rebuild(node):
        g = groups[node["uuid"]]
        name = g["name"]
        kept = []
        out = []
        for c in node["children"]:
            if isinstance(c, dict):
                rebuild(c)
                kept.append(c)
        cubes = [emap[c] for c in node["children"] if isinstance(c, str)]
        if name == "abdomen":
            out += [cube("Abdomen", (-6, 0, 3), (6, 8, 17), TEX["body"])]
            out += crystal("CrystalA", (0, 8, 9), 4.2, 7.0, 3.6, TEX["cyan"], (-15, 0, 0))
            out += crystal("CrystalB", (-3.4, 7.4, 13.5), 3.2, 5.0, 2.6, TEX["pink"], (-20, 0, 18))
            out += crystal("CrystalC", (3.4, 7.4, 13.5), 3.2, 4.0, 2.4, TEX["cyan"], (-20, 0, -18))
        elif name == "body":
            out += [cube("Body", (-5, 0, -7), (5, 5, 3), TEX["body"])]
        elif name == "mouth":
            out += [cube("Head", (-5, 0, -10), (5, 5, -7), TEX["body"])]
            # plate eyes on the head's front (a spider looks ahead), pupils set back from the edge
            for s, sx in (("L", -1), ("R", 1)):
                out += [cube("Eye" + s, (sx * 2.6 - 1.6, 1.8, -10.1), (sx * 2.6 + 1.6, 4.6, -10.0), TEX["white"]),
                        cube("Pupil" + s, (sx * 2.6 - 0.9, 2.2, -10.16), (sx * 2.6 + 0.9, 3.8, -10.06), TEX["pupil"])]
                out += [pyramid("Fang" + s, (sx * 3, 0.2, -9.0), 1.6, 1.6, 2.4, TEX["cyan"], (180, 0, 0))]
        elif name.startswith(("left_leg", "right_leg")):
            for e in cubes:
                lo, hi = np.array(e["from"], float), np.array(e["to"], float)
                if e.get("rotation") and any(e["rotation"]):
                    continue  # the hair planes
                size = hi - lo
                if "_end" in name:
                    lo[2], hi[2] = lo[2] - 1, hi[2] + 1  # the claw was a flat plane: give it depth
                    out.append(cube(name.replace("_end", "_claw"), lo, hi, TEX["cyan"]))
                elif "_mid" in name:
                    if size[0] < 5:
                        continue  # the knuckle block: dropped to keep the count down
                    out.append(cube(name, lo, hi, TEX["dark"]))
                else:
                    out.append(cube(name, lo, hi, TEX["body"]))
        for e in out:
            elements.append(e)
        for k in list(node):
            if k not in ("uuid", "children"):
                del node[k]
        node["isOpen"] = True
        node["children"] = [e["uuid"] for e in out] + kept

    outliner = copy.deepcopy(ref["outliner"])
    for n in outliner:
        rebuild(n)
    new_groups = []
    for g in ref_groups:
        g = dict(g)
        g["origin"] = [round(c * K, 4) for c in g["origin"]]
        new_groups.append(g)

    # our own idle, walk and run (a tetrapod gait); the reference's walk, played on its
    # multi-axis rest turns, flung the legs about. Small turns about each leg's pivot.
    anims = []
    by_name = {g["name"]: g for g in ref_groups}
    from horse_rig import write_animations
    from snake_rig import track
    import math
    gait = {}

    def legs(L, swing, lift, body_bob):
        tr = {}
        for side, sx in (("left", 1), ("right", -1)):
            for i in range(1, 5):
                phase = 0.0 if (i % 2 == 1) == (side == "left") else 0.5
                fn = (lambda u, ph=phase, sx=sx: (0, sx * swing * math.sin(2 * math.pi * (u + ph)),
                                                  -sx * lift * max(0.0, math.sin(2 * math.pi * (u + ph)))))
                tr[f"{side}_leg_{i}"] = [track(L, fn, 16)]
        tr["abdomen"] = [track(L, lambda u: (15 + 4 * math.sin(4 * math.pi * u), 0, 0), 16)]
        tr["root"] = [track(L, lambda u: (0, 0, 0), 4),
                      track(L, lambda u: (0, body_bob * abs(math.sin(2 * math.pi * u)), 0), 16, channel="position")]
        return tr
    gait["idle"] = (2.4, {"abdomen": [track(2.4, lambda u: (15 + 5 * math.sin(2 * math.pi * u), 0, 0), 16)],
                          "mouth": [track(2.4, lambda u: (4 * max(0.0, math.sin(4 * math.pi * u)) ** 2, 0, 0), 16)],
                          **{f"{sd}_leg_{i}": [track(2.4, lambda u, i=i, sx=sx: (0, sx * 3 * math.sin(2 * math.pi * u + i), 0), 16)]
                             for sd, sx in (("left", 1), ("right", -1)) for i in range(1, 5)}})
    gait["walk"] = (0.9, legs(0.9, 16, 10, 1.5))
    gait["gallop"] = (0.45, legs(0.45, 22, 14, 4.0))
    holder = {"animations": []}
    write_animations(holder, by_name, gait)
    anims += holder["animations"]

    model = json.load(open(os.path.join(ROOT, "designs", "desert", "Snake.bbmodel")))
    model.update(name="CrystalSpider", elements=elements, groups=new_groups, outliner=outliner, animations=anims,
                 textures=[S.solid_texture(n, c) for n, c in COLORS.items()])
    bake_rests(model)
    # stand it on the ground: lift everything so the lowest claw at rest touches y = 0
    low = min(q[:, 1].min() for p in S.posed(model) for q in p.polys)
    dy = -low * S.BB
    for e in model["elements"]:
        for key in ("from", "to", "origin"):
            if key in e:
                e[key][1] = round(e[key][1] + dy, 4)
    for g in model["groups"]:
        g["origin"][1] = round(g["origin"][1] + dy, 4)
    return model


def main(out="/mnt/project-files/animals/crystal_spider"):
    os.makedirs(out, exist_ok=True)
    model = build()
    for path in (os.path.join(ROOT, "designs", "crystal", "CrystalSpider.bbmodel"), os.path.join(out, "CrystalSpider.bbmodel")):
        with open(path, "w") as f:
            json.dump(model, f, separators=(",", ":"))
    parts = S.posed(model)
    horse_rig.EULER = "XYZ"
    from horse_rig import pose
    hparts = pose(A.qm_horse("A"), None, 0)
    horse_rig.EULER = "ZYX"
    for p in hparts:
        p.polys = [q + np.array([12, 0, 4]) for q in p.polys]
    W, H = 560, 440
    cams = [dict(eye=(-20, 14, -22), target=(0, 1.5, 0)), dict(eye=(-30, 6, 4), target=(4, 2, 2)),
            dict(eye=(16, 16, 22), target=(0, 1.5, 1)), dict(eye=(-3, 4, -16), target=(0, 1.5, 0))]
    sheet = Image.new("RGB", (W * 2, H * 2))
    for i, cam in enumerate(cams):
        sheet.paste(render(parts + (hparts if i == 1 else []), W=W, H=H, fov=40, **cam), ((i % 2) * W, (i // 2) * H))
    sheet.save(os.path.join(out, "CrystalSpider.png"))
    print("wrote", len(model["elements"]), "elements")


if __name__ == "__main__":
    main(*sys.argv[1:])
