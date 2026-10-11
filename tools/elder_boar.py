"""Elder Boar (QM Oct 10): the Tundra's boss, a bigger, greyish-brown, angrier Boar.

Run: python3 tools/elder_boar.py [out_dir]
Reads designs/converted/Boar.bbmodel (shapes and animations untouched), recolours
its palette, steepens its brows and scales the whole model up, and writes
ElderBoar.bbmodel plus renders and GIFs to out_dir.
"""

import base64
import io
import json
import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import animal_designs as A  # noqa: E402
from partlib import render  # noqa: E402
from snow_rig import posed  # noqa: E402

ROOT = os.path.join(os.path.dirname(__file__), "..")
BOAR = os.path.join(ROOT, "designs", "converted", "Boar.bbmodel")
OUT = "/mnt/project-files/animals/bosses"

SCALE = 1.5
BROW = 30  # degrees (the Boar's are 16)
RECOLOR = {
    (176, 108, 68): (132, 116, 104),  # coat: greyish brown
    (112, 66, 46): (82, 72, 66),  # mane, tufts, cheeks, jaw
    (236, 190, 136): (214, 208, 198),  # brows: old grey
    (86, 60, 52): (58, 54, 54),  # hooves
    (248, 150, 158): (214, 132, 138),  # nose
    (130, 50, 70): (104, 40, 52),  # nostrils
    (254, 246, 222): (244, 236, 214),  # tusks
}


def elder(m):
    m = json.loads(json.dumps(m))
    m["name"] = "ElderBoar"
    m["meta"]["format_version"] = "5.0"
    for t in m["textures"]:
        im = Image.open(io.BytesIO(base64.b64decode(t["source"].split(",", 1)[1]))).convert("RGBA")
        px = im.load()
        for y in range(im.height):
            for x in range(im.width):
                r, g, b, a = px[x, y]
                if (r, g, b) in RECOLOR:
                    px[x, y] = (*RECOLOR[(r, g, b)], a)
        buf = io.BytesIO()
        im.save(buf, "PNG")
        t["source"] = "data:image/png;base64," + base64.b64encode(buf.getvalue()).decode()
    for g in m["groups"]:
        g["origin"] = [v * SCALE for v in g["origin"]]
        if g["name"] in ("BrowL", "BrowR"):
            g["rotation"] = [0, 0, -BROW if g["name"] == "BrowL" else BROW]
    for e in m["elements"]:
        for k in ("from", "to", "origin"):
            if k in e:
                e[k] = [v * SCALE for v in e[k]]
        if "vertices" in e:
            e["vertices"] = {k: [v * SCALE for v in p] for k, p in e["vertices"].items()}
    for a in m["animations"]:
        for an in a["animators"].values():
            for k in an.get("keyframes", []):
                if k["channel"] == "position":
                    for dp in k["data_points"]:
                        for c in "xyz":
                            dp[c] = float(dp[c]) * SCALE
    return m


def main(out=OUT):
    os.makedirs(out, exist_ok=True)
    boar = json.load(open(BOAR))
    m = elder(boar)
    with open(os.path.join(out, "ElderBoar.bbmodel"), "w") as f:
        json.dump(m, f, separators=(",", ":"))
    plain = ("Eye", "Pupil", "Nostril", "Tusk", "Tuft", "Beard", "Crest", "TailTuft")

    def parts(model, anim=None, t=0.0):
        ps = posed(model, anim, t)
        for p in ps:
            if p.name.startswith(plain):
                p.plain = True
        return ps

    T = 420
    views = [dict(eye=(-26, 16, -32), target=(0, 6, -1), W=T, H=T, fov=38), dict(eye=(-40, 8, -2), target=(0, 6, -1), W=T, H=T, fov=36),
             dict(eye=(-9, 10, -30), target=(0, 7, -4), W=T, H=T, fov=30)]
    sheet = Image.new("RGB", (T * 3, T))
    for i, v in enumerate(views):
        sheet.paste(render(parts(m), **v), (i * T, 0))
    A.label(sheet, ["Elder Boar", "side", "face"], 22).save(os.path.join(out, "ElderBoar.png"))
    cam = dict(eye=(-26, 14, -32), target=(0, 6, -1), W=T, H=T, fov=38)
    pair = Image.new("RGB", (T * 2, T))
    pair.paste(render(parts(boar), **cam), (0, 0))
    pair.paste(render(parts(m), **cam), (T, 0))
    A.label(pair, ["Boar (pet)", "Elder Boar"], 22).save(os.path.join(out, "ElderBoar_vs_pet.png"))
    for name, n in (("idle", 20), ("walk", 14), ("gallop", 14)):
        anim = next(x for x in m["animations"] if x["name"] == name)
        L = anim["length"]
        A.gif(os.path.join(out, f"ElderBoar_{name}.gif"),
              [A.label(render(parts(m, anim, L * i / n), **views[1]), [name], 22) for i in range(n)], fps=n / L)
    print("wrote", out)


if __name__ == "__main__":
    main(*sys.argv[1:])
