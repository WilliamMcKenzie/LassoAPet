"""Crystal Elephant: World 2 Crystal Cavern's Legendary (QM, Oct 13): the War Elephant
(designs/godlands/WarElephant.bbmodel, QM's) in crystal armour. Same shape, bones and
animations. The plate armour turns deep crystal purple with cyan trim; the steel spikes
become crystals like the cavern props (a cube shaft and a pyramid tip, cyan #00BEE7 and
pink #E583FB): a ridge of tall crystals down the back, a crown of crystals on the head,
crystal points out of the skirts and crystal greaves on the legs. The tusks and the cyan
trim glow (named Glow*, so they're Neon in game).

Run: python3 tools/crystal_elephant.py [out_dir]
"""

import base64
import io
import json
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import horse_rig  # noqa: E402
import snake_design as S  # noqa: E402
from partlib import render  # noqa: E402
from crystal_phoenix import mesh, point, shard  # noqa: E402

horse_rig.EULER = "ZYX"  # the War Elephant is converted with --zyx
ROOT = os.path.join(os.path.dirname(__file__), "..")
SRC = os.path.join(ROOT, "designs", "godlands", "WarElephant.bbmodel")

# new palette swatches (2x2, on row 8 of the 16x16 palette, which the War Elephant leaves empty)
COLORS = {"skin": (138, 142, 182), "skin_dark": (104, 106, 150), "armor": (86, 54, 168), "armor_dark": (58, 36, 120),
          "cyan": (0, 190, 231), "pink": (229, 131, 251), "glow": (176, 246, 255), "hoof": (210, 214, 236)}
RECOLOR = {(156, 152, 166): "skin", (122, 118, 134): "skin_dark", (60, 56, 64): "skin_dark", (56, 60, 74): "armor",
           (98, 104, 122): "cyan", (226, 218, 198): "hoof", (246, 238, 214): "glow"}


def first_uv(face):
    uv = face["uv"]
    return uv[:2] if isinstance(uv, list) else next(iter(uv.values()))


def paint(e, uv):
    for f in e["faces"].values():
        if e.get("type") == "mesh":
            f["uv"] = {k: uv for k in f["uv"]}
        else:
            f["uv"] = [uv[0] - 0.5, uv[1] - 0.5, uv[0] + 0.5, uv[1] + 0.5]


def band(name, lo, hi, uv):
    """A plain box (Blockbench units) on a palette swatch."""
    return {"name": name, "type": "cube", "uuid": S.uid(), "from": list(lo), "to": list(hi), "origin": [0, 0, 0],
            "rotation": [0, 0, 0], "color": 0, "autouv": 0,
            "faces": {k: {"uv": [uv[0] - 0.5, uv[1] - 0.5, uv[0] + 0.5, uv[1] + 0.5], "texture": 0}
                      for k in ("north", "east", "south", "west", "up", "down")}}


def build():
    m = json.load(open(SRC))
    t = m["textures"][0]
    head, data = t["source"].split(",", 1)
    im = Image.open(io.BytesIO(base64.b64decode(data))).convert("RGBA")
    uv = {}
    for i, (k, c) in enumerate(COLORS.items()):
        x, y = 2 * i, 8
        for dx in (0, 1):
            for dy in (0, 1):
                im.putpixel((x + dx, y + dy), (*c, 255))
        uv[k] = [x + 1, y + 1]
    old = im.copy()
    buf = io.BytesIO()
    im.save(buf, "PNG")
    t["source"] = head + "," + base64.b64encode(buf.getvalue()).decode()
    m["name"] = "CrystalElephant"

    groups = {g["name"]: g["uuid"] for g in m["groups"]}
    drop = set()
    for e in m["elements"]:
        u, v = first_uv(next(iter(e["faces"].values())))
        c = old.getpixel((int(u), int(v)))[:3]
        if e["name"].startswith(("Spine", "SideSpike", "HeadSpike")):
            drop.add(e["uuid"])  # the steel spikes: crystals instead, below
        elif c in RECOLOR:
            paint(e, uv[RECOLOR[c]])
        if e["name"].startswith("Tusk") or e["name"] in ("BackTrim", "HeadRidge"):
            e["name"] = "Glow" + e["name"]  # glowing crystal tusks and cyan trim
    add = {"root": [], "neck": [], "LegFL": [], "LegFR": [], "LegHL": [], "LegHR": []}

    # the back: tall crystals, cyan and pink, leaning back, clear of the rider's seat (z 12):
    # one on the shoulders ahead of the rider, the tallest pair behind (Studio, Oct 13)
    for i, (z, h, c) in enumerate(((-24, 14, "cyan"), (27, 20, "pink"), (34, 24, "cyan"))):
        add["root"] += shard(f"CrystalSpine{i}", (0, 78, z), (0, 1, 0.3), 5.5 if c == "cyan" else 5, h, 11, uv[c])
    # side clusters on the back plate: smaller crystals leaning out
    for s in (-1, 1):
        for i, (z, c) in enumerate(((-20, "pink"), (-8, "cyan"), (28, "pink"))):  # none beside the seat
            add["root"] += shard(f"CrystalBack{'LR'[s > 0]}{i}", (s * 15, 78, z), (s * 0.55, 1, 0.15), 3, 6, 6, uv[c])
    # skirts: a crystal point out of each panel
    for s in (-1, 1):
        for i, z in enumerate((-19.5, 2.5, 24.5)):
            add["root"].append(point(f"CrystalSkirt{'LR'[s > 0]}{i}", (s * 24.5, 46.5, z), (s, 0.15, 0), 3.5, 10,
                                     uv["cyan" if i != 1 else "pink"]))
    # the head: a crown of crystals, a tall cyan one between two pink ones leaning out
    add["neck"] += shard("CrystalCrown", (0, 83, -58), (0, 1, 0.15), 4.5, 12, 10, uv["cyan"])
    add["neck"] += shard("CrystalCrownL", (-9, 82, -56), (-0.5, 1, 0.1), 3.5, 7, 7, uv["pink"])
    add["neck"] += shard("CrystalCrownR", (9, 82, -56), (0.5, 1, 0.1), 3.5, 7, 7, uv["pink"])
    add["neck"].append(point("CrystalBrow", (0, 74, -69.5), (0, 0.6, -1), 3, 9, uv["cyan"]))
    # greaves: a crystal band round each leg with a point at the front
    for leg in ("FL", "FR", "HL", "HR"):
        e = next(e for e in m["elements"] if e["name"] == "Leg" + leg)
        lo, hi = np.array(e["from"]), np.array(e["to"])
        add["Leg" + leg].append(band("Greave" + leg, (lo[0] - 1, 14, lo[2] - 1), (hi[0] + 1, 22, hi[2] + 1), uv["armor"]))
        add["Leg" + leg].append(point("CrystalGreave" + leg, ((lo[0] + hi[0]) / 2, 18, lo[2] - 1), (0, 0.5, -1), 3.2, 7, uv["cyan"]))

    def fix(nodes, gname):
        out = []
        for n in nodes:
            if isinstance(n, dict):
                name = next(g["name"] for g in m["groups"] if g["uuid"] == n["uuid"])
                n["children"] = fix(n["children"], name)
                out.append(n)
            elif n not in drop:
                out.append(n)
        out += [e["uuid"] for e in add.get(gname, [])]
        return out
    m["outliner"] = fix(m["outliner"], None)
    m["elements"] = [e for e in m["elements"] if e["uuid"] not in drop] + [e for v in add.values() for e in v]
    assert all(g in groups for g in add)
    return m


def main(out="/mnt/project-files/animals/crystal_elephant"):
    os.makedirs(out, exist_ok=True)
    m = build()
    for path in (os.path.join(ROOT, "designs", "crystal", "CrystalElephant.bbmodel"), os.path.join(out, "CrystalElephant.bbmodel")):
        with open(path, "w") as f:
            json.dump(m, f, separators=(",", ":"))
    parts = S.posed(m)
    for p in parts:
        if p.name.startswith("Glow"):
            p.neon = True
    war = S.posed(json.load(open(SRC)))
    W, H = 640, 480
    sheet = Image.new("RGB", (W * 2, H * 2))
    cams = [dict(eye=(-16, 10, -18), target=(0, 5, 0)), dict(eye=(0, 7, -20), target=(0, 5, 0)),
            dict(eye=(14, 12, 16), target=(0, 5, 0))]
    for i, cam in enumerate(cams):
        sheet.paste(render(parts, W=W, H=H, fov=40, **cam), ((i % 2) * W, (i // 2) * H))
    sheet.paste(render(war, W=W, H=H, fov=40, **cams[0]), (W, H))
    sheet.save(os.path.join(out, "CrystalElephant.png"))
    print("wrote", len(m["elements"]), "elements")


if __name__ == "__main__":
    main(*sys.argv[1:])
