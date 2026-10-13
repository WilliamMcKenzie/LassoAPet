"""Crystal Phoenix: the Phoenix (designs/volcano/Phoenix.bbmodel, QM's) with crystals instead of
fire, for World 2's Crystal Cavern (QM, Oct 13). Same shape, bones and animations; the palette
goes from fire to the cavern's crystals: purple body, violet head and wing bands, pink and
cyan feathers (the props' #E583FB and #00BEE7), and the glowing flame tips become pale
glowing crystal (still named Glow*, so they stay Neon in game).

Run: python3 tools/crystal_phoenix.py [out_dir]
"""

import base64
import io
import json
import os
import re
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import horse_rig  # noqa: E402
import snake_design as S  # noqa: E402
from partlib import render  # noqa: E402

horse_rig.EULER = "ZYX"  # the Phoenix is converted with --zyx
ROOT = os.path.join(os.path.dirname(__file__), "..")
SRC = os.path.join(ROOT, "designs", "volcano", "Phoenix.bbmodel")

SWAP = {(206, 34, 40): (104, 58, 184),    # crimson body, wing arms, tail -> deep purple
        (240, 72, 32): (146, 96, 226),    # red head, neck, wing bands -> violet
        (255, 132, 24): (229, 131, 251),  # orange feathers -> pink #E583FB
        (255, 188, 36): (0, 190, 231),    # gold feathers, beak -> cyan #00BEE7
        (255, 232, 84): (176, 246, 255),  # glowing flame tips -> glowing pale crystal
        (255, 236, 120): (255, 255, 255)}  # eyes -> white


def swatch(im, rgb):
    """uv of the palette swatch holding rgb (the palette is 2x2 swatches)."""
    for x in range(im.width):
        for y in range(im.height):
            if im.getpixel((x, y))[:3] == rgb:
                return [x + 1, y + 1]
    raise ValueError(rgb)


def mesh(name, verts, faces, uv):
    """A mesh from absolute vertices (Blockbench units), every face one palette swatch."""
    v = {f"v{i}": list(map(float, p)) for i, p in enumerate(verts)}
    return {"name": name, "type": "mesh", "uuid": S.uid(), "color": 0, "origin": [0, 0, 0], "rotation": [0, 0, 0],
            "vertices": v, "faces": {f"f{i}": {"texture": 0, "vertices": [f"v{k}" for k in f],
                                               "uv": {f"v{k}": uv for k in f}} for i, f in enumerate(faces)}}


def axes(d):
    d = np.array(d, float) / np.linalg.norm(d)
    a = np.cross(d, [0, 1, 0] if abs(d[1]) < 0.9 else [1, 0, 0])
    a /= np.linalg.norm(a)
    return d, a, np.cross(d, a)


def point(name, base, d, hw, h, uv):
    """A pyramid: a square base (half-size hw) at base, apex h along d."""
    d, a, b = axes(d)
    base = np.array(base, float)
    q = [base + (sa * a + sb * b) * hw for sa, sb in ((-1, -1), (1, -1), (1, 1), (-1, 1))]
    return mesh(name, q + [base + d * h], [(0, 1, 2, 3), (0, 1, 4), (1, 2, 4), (2, 3, 4), (3, 0, 4)], uv)


def shard(name, base, d, hw, shaft, tip, uv):
    """A crystal like the cavern props: a square shaft and a pyramid tip, leaning along d."""
    d, a, b = axes(d)
    base = np.array(base, float)
    ring = lambda c: [c + (sa * a + sb * b) * hw for sa, sb in ((-1, -1), (1, -1), (1, 1), (-1, 1))]
    lo, hi = ring(base), ring(base + d * shaft)
    box = mesh(name, lo + hi, [(0, 1, 2, 3), (4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)], uv)
    return [box, point(name + "Tip", base + d * shaft, d, hw, tip, uv)]


def center(e):
    return (np.array(e["from"], float) + np.array(e["to"], float)) / 2


def build():
    m = json.load(open(SRC))
    t = m["textures"][0]
    head, data = t["source"].split(",", 1)
    im = Image.open(io.BytesIO(base64.b64decode(data))).convert("RGBA")
    px = im.load()
    for x in range(im.width):
        for y in range(im.height):
            r, g, b, a = px[x, y]
            if (r, g, b) in SWAP:
                px[x, y] = (*SWAP[(r, g, b)], a)
    buf = io.BytesIO()
    im.save(buf, "PNG")
    t["source"] = head + "," + base64.b64encode(buf.getvalue()).decode()
    m["name"] = "CrystalPhoenix"
    glow, cyan, pink = swatch(im, (176, 246, 255)), swatch(im, (0, 190, 231)), swatch(im, (229, 131, 251))

    # the glowing flame ends of the wing tips and the tail become glowing crystal points,
    # each carrying on from the feather before it
    els = {e["name"]: e for e in m["elements"]}
    swap = {}
    for g in [n for n in els if re.fullmatch(r"Glow(Tip[LR]\d_4|Tail\d_6)", n)]:
        e, prev = els[g], els[re.sub(r"_(\d)$", lambda k: f"_{int(k[1]) - 1}", g[4:])]
        d = center(e) - center(prev)
        size = np.array(e["to"]) - np.array(e["from"])
        hw = min(size[i] for i in range(3) if abs(d[i]) < 0.6 * np.linalg.norm(d)) / 2
        start = center(prev) + d / 2
        swap[e["uuid"]] = [point(g, start, d, hw + 0.4, np.linalg.norm(d) * 1.7, glow)]
    # each head plume ends in a crystal instead of a flame curl
    for top, ends in (("PlumeR2", ("GlowPlumeR3", "GlowPlumeR4")), ("PlumeR3", ("GlowPlumeR5", "GlowPlumeR4"))):
        e = next(e for e in m["elements"] if e["name"] == top and (e["from"][0] > 0) == (top == "PlumeR2"))
        c = center(e)
        olds = [x for x in m["elements"] if x["name"] in ends and (x["from"][0] > 0) == (c[0] > 0)]
        swap[olds[0]["uuid"]] = [point("GlowPlume" + ("R" if c[0] > 0 else "L"), (c[0], e["to"][1], c[2]), (0, 1, 0), 3.2, 12, glow)]
        swap[olds[1]["uuid"]] = []
    # crystals growing from the back: a big cyan one leaning back, pink ones leaning out
    back = (shard("CrystalBack", (0, 43, 8), (0, 1, 0.45), 5.5, 16, 11, cyan)
            + shard("CrystalBackL", (-8, 43, 14), (-0.6, 1, 0.5), 4, 10, 8, pink)
            + shard("CrystalBackR", (8, 43, 14), (0.6, 1, 0.5), 4, 10, 8, pink))

    def fix(nodes):
        out = []
        for n in nodes:
            if isinstance(n, dict):
                n["children"] = fix(n["children"])
                out.append(n)
            elif n in swap:
                out += [x["uuid"] for x in swap[n]]
            else:
                out.append(n)
        return out
    m["outliner"] = fix(m["outliner"])
    root = m["outliner"][0]
    root["children"] += [x["uuid"] for x in back]
    new = []
    for e in m["elements"]:
        new += swap.get(e["uuid"], [e])
    m["elements"] = new + back
    return m


def main(out="/mnt/project-files/animals/crystal_phoenix"):
    os.makedirs(out, exist_ok=True)
    os.makedirs(os.path.join(ROOT, "designs", "crystal"), exist_ok=True)
    m = build()
    for path in (os.path.join(ROOT, "designs", "crystal", "CrystalPhoenix.bbmodel"), os.path.join(out, "CrystalPhoenix.bbmodel")):
        with open(path, "w") as f:
            json.dump(m, f, separators=(",", ":"))
    parts = S.posed(m)
    phoenix = S.posed(json.load(open(SRC)))
    W, H = 640, 480
    sheet = Image.new("RGB", (W * 2, H * 2))
    cams = [dict(eye=(-22, 14, -24), target=(0, 4, 0)), dict(eye=(0, 8, -28), target=(0, 5, 0)),
            dict(eye=(18, 18, 22), target=(0, 4, 0))]
    for i, cam in enumerate(cams):
        sheet.paste(render(parts, W=W, H=H, fov=44, **cam), ((i % 2) * W, (i // 2) * H))
    sheet.paste(render(phoenix, W=W, H=H, fov=44, **cams[0]), (W, H))
    sheet.save(os.path.join(out, "CrystalPhoenix.png"))
    print("wrote", len(m["elements"]), "elements")


if __name__ == "__main__":
    main(*sys.argv[1:])
