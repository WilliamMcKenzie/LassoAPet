"""Horse variants: QM's horse (Horse9_Leap.bbmodel) repainted, plus a few flat
patches, so every variant keeps the horse's exact shape, bones and animations.

    python3 tools/horse_variants.py

writes designs/horses/<Name>.bbmodel for each variant below. Then convert it:

    python3 tools/bbmodel_to_luau.py designs/horses/Pinto.bbmodel src/shared/Animals/PintoModel.luau

Units are Blockbench's (0.1 stud). Patches are 0.5 thick plates laid on a face.
"""

import base64
import copy
import io
import json
import os
import uuid

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)
BASE = os.path.join(REPO, "designs", "horses", "Horse9_Leap.bbmodel")

WHITE = (248, 248, 244)
BROWN = (150, 84, 46)
DARK = (70, 42, 30)
HOOF = (60, 60, 72)

VARIANTS = {
    # White coat with big brown patches, a brown head and neck, a white muzzle
    # with a blaze up the forehead, dark mane and tail.
    "Pinto": {
        "colors": {
            "Body": WHITE, "LegFL": WHITE, "LegFR": WHITE, "LegHL": WHITE, "LegHR": WHITE,
            "Snout": WHITE, "Bridge": WHITE,
            "Neck": BROWN, "Head": BROWN, "EarLA": BROWN, "EarLB": BROWN, "EarRA": BROWN, "EarRB": BROWN,
            "Mane": DARK, "Cap": DARK, "Stripe": DARK, "Tail": DARK, "TailTip": DARK,
            "HoofFL": HOOF, "HoofFR": HOOF, "HoofHL": HOOF, "HoofHR": HOOF,
        },
        # name, bone, from, to, color
        "patches": [
            ("SpotL1", "root", (-16.5, 45, -27), (-16, 65, -7), BROWN),
            ("SpotL2", "root", (-16.5, 35, 8), (-16, 55, 33), BROWN),
            ("SpotR1", "root", (16, 40, -17), (16.5, 65, 8), BROWN),
            ("SpotR2", "root", (16, 50, 20), (16.5, 65, 33), BROWN),
            ("SpotT1", "root", (-16, 65, 13), (-4, 65.5, 33), BROWN),
            ("SpotT2", "root", (4, 65, -27), (16, 65.5, -2), BROWN),
            ("Blaze", "neck", (-3.5, 105, -39), (3.5, 105.5, -23), WHITE),
        ],
    },
}


def load_palette(model):
    src = model["textures"][0]["source"].split(",", 1)[1]
    return Image.open(io.BytesIO(base64.b64decode(src))).convert("RGB")


def element_color(e, pal):
    face = next(iter(e["faces"].values()))
    uv = face["uv"]
    u, v = (uv[0], uv[1]) if isinstance(uv, list) else next(iter(uv.values()))
    return pal.getpixel((int(u), int(v)))


def paint(e, cell):
    """Point every face of e at palette cell `cell` (2x2 pixels, 8 to a row)."""
    u, v = cell % 8 * 2, cell // 8 * 2
    for face in e["faces"].values():
        if isinstance(face["uv"], list):
            face["uv"] = [u + 0.5, v + 0.5, u + 1.5, v + 1.5]
        else:
            face["uv"] = {k: [u + 1, v + 1] for k in face["uv"]}


def find_group(outliner, name, groups):
    for node in outliner:
        if isinstance(node, dict):
            if groups[node["uuid"]]["name"] == name:
                return node
            found = find_group(node["children"], name, groups)
            if found:
                return found
    return None


def make(name, spec):
    model = json.load(open(BASE))
    pal = load_palette(model)
    groups = {g["uuid"]: g for g in model["groups"]}
    template = next(e for e in model["elements"] if e["type"] == "cube")

    new = []
    for pname, bone, lo, hi, color in spec["patches"]:
        e = copy.deepcopy(template)
        e.update(name=pname, uuid=str(uuid.uuid4()), **{"from": list(lo), "to": list(hi)},
                 origin=[(a + b) / 2 for a, b in zip(lo, hi)], rotation=[0, 0, 0])
        model["elements"].append(e)
        find_group(model["outliner"], bone, groups)["children"].append(e["uuid"])
        new.append((e, color))

    colors = []
    wanted = []
    for e in model["elements"]:
        c = spec["colors"].get(e["name"]) or element_color(e, pal)
        wanted.append((e, c))
    wanted += new
    for e, c in wanted:
        if c not in colors:
            colors.append(c)
        paint(e, colors.index(c))
    assert len(colors) <= 64, "the 16x16 palette holds 64 colours"

    img = Image.new("RGB", (16, 16), (0, 0, 0))
    for i, c in enumerate(colors):
        for x in (i % 8 * 2, i % 8 * 2 + 1):
            for y in (i // 8 * 2, i // 8 * 2 + 1):
                img.putpixel((x, y), c)
    buf = io.BytesIO()
    img.save(buf, "PNG")
    model["textures"][0]["source"] = "data:image/png;base64," + base64.b64encode(buf.getvalue()).decode()
    model["textures"][0]["uuid"] = str(uuid.uuid4())
    model["name"] = name

    out = os.path.join(REPO, "designs", "horses", name + ".bbmodel")
    json.dump(model, open(out, "w"), indent=1)
    print("wrote", out, len(colors), "colours")


if __name__ == "__main__":
    for name, spec in VARIANTS.items():
        make(name, spec)
