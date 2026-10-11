"""Lava Whale (QM Oct 11): the Whale (designs/ocean/Whale.bbmodel: shapes, bones and
animations kept) in the Volcano's warm rock, after QM's reference (a cloud whale covered
in square spiral glyphs, a spout pillar on its head), lava instead of cloud: the head's
glyphs, the back dashes and the specks become glowing lava (Glow* = Neon in game), more
glyphs run down the body and tail, and a lava spout erupts from its blowhole.

Run: python3 tools/lava_whale.py [out_dir]
writes LavaWhale.bbmodel, LavaWhale.png, LavaWhale_vs_whale.png and idle/walk/gallop GIFs.
"""

import base64
import io
import json
import os
import sys
import uuid

from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import animal_designs as A  # noqa: E402
from partlib import render  # noqa: E402
from snow_rig import posed  # noqa: E402
from whale_design import GLYPH  # noqa: E402

ROOT = os.path.join(os.path.dirname(__file__), "..")
WHALE = os.path.join(ROOT, "designs", "ocean", "Whale.bbmodel")
OUT = "/mnt/project-files/animals/lavawhale"

COLORS = {  # the Whale's texture name -> lava colour
    "blue": (182, 100, 62),  # warm baked rock
    "deep": (136, 74, 50),  # brow
    "speck": (255, 140, 30),  # embers (glow)
    "cyan": (255, 140, 30),  # glyphs and dashes (glow)
    "belly": (246, 196, 140),  # ash underside
    "groove": (216, 156, 104),
}
GLOW_TEX = ("speck", "cyan")
ROCK = "deep"


def solid(rgb):
    buf = io.BytesIO()
    Image.new("RGBA", (16, 16), (*rgb, 255)).save(buf, "PNG")
    return "data:image/png;base64," + base64.b64encode(buf.getvalue()).decode()


def cube(name, lo, hi, tex):
    face = {"uv": [0, 0, 1, 1], "texture": tex}
    return {"name": name, "box_uv": False, "rescale": False, "locked": False, "render_order": "default",
            "allow_mirror_modeling": True, "from": list(lo), "to": list(hi), "autouv": 0, "color": 0,
            "origin": [(a + b) / 2 for a, b in zip(lo, hi)],
            "faces": {k: dict(face) for k in ("north", "east", "south", "west", "up", "down")},
            "type": "cube", "uuid": str(uuid.uuid4())}


def glyph(name, x_face, sx, y_top, z_front, px, tex):
    """The Whale's square spiral glyph raised off one side (sx = -1 left, 1 right), in bb units."""
    out = []
    x0, x1 = sorted((x_face, x_face + sx * 1.6))
    for r, row in enumerate(GLYPH):
        k = 0
        while k < len(row):
            if row[k] == "1":
                e = k
                while e < len(row) and row[e] == "1":
                    e += 1
                out.append(cube(f"{name}{r}{k}", (x0, y_top - (r + 1) * px, z_front + k * px),
                                (x1, y_top - r * px, z_front + e * px), tex))
                k = e
            else:
                k += 1
    return out


def lava_whale(m):
    m = json.loads(json.dumps(m))
    m["name"] = "LavaWhale"
    tex = {t["name"]: i for i, t in enumerate(m["textures"])}
    for t in m["textures"]:
        if t["name"] in COLORS:
            t["source"] = solid(COLORS[t["name"]])
    glow = {tex[n] for n in GLOW_TEX}
    for e in m["elements"]:
        f = next(iter(e["faces"].values()))
        if f.get("texture") in glow and not e["name"].startswith("Glow"):
            e["name"] = "Glow" + e["name"]
    groups = {g["name"]: g for g in m["groups"]}

    def add(bone, els):
        m["elements"].extend(els)

        def walk(node):
            if isinstance(node, str):
                return False
            if node["uuid"] == groups[bone]["uuid"]:
                node["children"].extend(e["uuid"] for e in els)
                return True
            return any(walk(c) for c in node["children"])

        for r in m["outliner"]:
            if walk(r):
                return

    lava = tex["cyan"]
    # glyphs down the body's sides (two each) and the first tail piece's sides
    for side, sx in (("L", -1), ("R", 1)):
        add("root", glyph(f"GlowBodyGlyph{side}A", sx * 30, sx, 60, -20, 3.4, lava)
            + glyph(f"GlowBodyGlyph{side}B", sx * 30, sx, 54, 22, 3.4, lava))
        add("Tail1", glyph(f"GlowTailGlyph{side}", sx * 22, sx, 52, 55, 3.0, lava))
    # a lava spout erupting from a rock blowhole on top of the head, curling forward
    rock = tex[ROCK]
    add("neck", [cube("Blowhole", (-9, 76, -42), (9, 81, -24), rock),
                 cube("GlowSpout", (-5.5, 81, -38.5), (5.5, 116, -27.5), lava),
                 cube("GlowSpoutCurl", (-5.5, 110, -56), (5.5, 121, -38.5), lava),
                 cube("GlowSpoutCurl2", (-5.5, 98, -64), (5.5, 116, -53), lava),
                 cube("GlowSpoutDrip", (-4, 92, -62), (4, 98, -55), lava)])
    return m


def parts(model, anim=None, t=0.0):
    ps = posed(model, anim, t)
    for p in ps:
        if p.name.startswith(("Eye", "Pupil")):
            p.plain = True
        if p.name.startswith("Glow"):
            p.neon = True
    return ps


def main(out=OUT):
    os.makedirs(out, exist_ok=True)
    whale = json.load(open(WHALE))
    m = lava_whale(whale)
    with open(os.path.join(out, "LavaWhale.bbmodel"), "w") as f:
        json.dump(m, f, separators=(",", ":"))
    T = 480
    views = [dict(eye=(-40, 22, -44), target=(0, 5, -1), W=T, H=T, fov=36), dict(eye=(-60, 8, 0), target=(0, 5, -1), W=T, H=T, fov=34),
             dict(eye=(36, 24, 44), target=(0, 5, 0), W=T, H=T, fov=36)]
    sheet = Image.new("RGB", (T * 3, T))
    for i, v in enumerate(views):
        sheet.paste(render(parts(m), **v), (i * T, 0))
    A.label(sheet, ["Lava Whale", "side", "back"], 22).save(os.path.join(out, "LavaWhale.png"))
    pair = Image.new("RGB", (T * 2, T))
    pair.paste(render(parts(whale), **views[0]), (0, 0))
    pair.paste(render(parts(m), **views[0]), (T, 0))
    A.label(pair, ["Whale", "Lava Whale"], 22).save(os.path.join(out, "LavaWhale_vs_whale.png"))
    print("wrote", out, len(m["elements"]), "elements")


if __name__ == "__main__":
    main(*sys.argv[1:])
