"""Rockworm (QM Oct 11): the Sandworm reskinned in the Rock Hog's basalt colours, with its
fins, horn and tail spike glowing lava orange (Glow* = Neon in game). QM will give it
cooler mouth fangs.

Run: python3 tools/rockworm.py [out_dir]
Reads designs/desert/Sandworm.bbmodel (QM's file: shapes and animations untouched) and
writes Rockworm.bbmodel, Rockworm.png, Rockworm_vs_horse.png and idle/walk/gallop GIFs.
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
from rock_hog import SCHEMES  # noqa: E402
from snow_rig import posed  # noqa: E402

ROOT = os.path.join(os.path.dirname(__file__), "..")
SANDWORM = os.path.join(ROOT, "designs", "desert", "Sandworm.bbmodel")
HORSE = os.path.join(ROOT, "designs", "animals", "Horse.bbmodel")
OUT = "/mnt/project-files/animals/rockworm"

S = SCHEMES["Basalt"]
COLORS = {  # texture name -> colour
    "sand": S["coat"],
    "plate": S["mane"],
    "belly": (120, 130, 162),
    "dark": S["hooves"],
    "lava": S["lava"],
}
GLOW = ("Fin", "Horn", "TailSpike")  # these move onto the lava texture


def solid(rgb):
    buf = io.BytesIO()
    Image.new("RGBA", (16, 16), (*rgb, 255)).save(buf, "PNG")
    return "data:image/png;base64," + base64.b64encode(buf.getvalue()).decode()


def rockworm(m):
    m = json.loads(json.dumps(m))
    m["name"] = "Rockworm"
    lava = dict(m["textures"][0], name="lava", id=str(len(m["textures"])), uuid="7a1c5e0b-1f00-4c2a-9d6e-50c0a7a00001")
    m["textures"].append(lava)
    for t in m["textures"]:
        if t["name"] in COLORS:
            t["source"] = solid(COLORS[t["name"]])
    li = len(m["textures"]) - 1
    for e in m["elements"]:
        base = e["name"].rstrip("0123456789")
        if base.endswith(GLOW) or base in GLOW:
            e["name"] = "Glow" + e["name"]
            for f in e["faces"].values():
                if f.get("texture") is not None:
                    f["texture"] = li
    return m


def parts(model, anim=None, t=0.0):
    ps = posed(model, anim, t)
    for p in ps:
        if p.name.startswith(("Maw", "Eye")):
            p.plain = True
        if p.name.startswith("Glow"):
            p.neon = True
    return ps


def main(out=OUT):
    os.makedirs(out, exist_ok=True)
    m = rockworm(json.load(open(SANDWORM)))
    with open(os.path.join(out, "Rockworm.bbmodel"), "w") as f:
        json.dump(m, f, separators=(",", ":"))
    T = 420
    views = [dict(eye=(-22, 12, -24), target=(0, 3, 0), W=T, H=T, fov=38), dict(eye=(-34, 5, 0), target=(0, 3, 0), W=T, H=T, fov=36),
             dict(eye=(-6, 6, -26), target=(0, 3, -4), W=T, H=T, fov=32)]
    sheet = Image.new("RGB", (T * 3, T))
    for i, v in enumerate(views):
        sheet.paste(render(parts(m), **v), (i * T, 0))
    A.label(sheet, ["Rockworm", "side", "face"], 22).save(os.path.join(out, "Rockworm.png"))
    cam = dict(eye=(-30, 12, -30), target=(0, 6, 0), W=T, H=T, fov=36)
    pair = Image.new("RGB", (T * 2, T))
    pair.paste(render(parts(json.load(open(HORSE))), **cam), (0, 0))
    pair.paste(render(parts(m), **cam), (T, 0))
    A.label(pair, ["Horse", "Rockworm"], 22).save(os.path.join(out, "Rockworm_vs_horse.png"))
    for name, n in (("idle", 20), ("walk", 14), ("gallop", 14)):
        anim = next((x for x in m["animations"] if x["name"] == name), None)
        if anim:
            L = anim["length"]
            A.gif(os.path.join(out, f"Rockworm_{name}.gif"),
                  [A.label(render(parts(m, anim, L * i / n), **views[1]), [name], 22) for i in range(n)], fps=n / L)
    print("wrote", out)


if __name__ == "__main__":
    main(*sys.argv[1:])
