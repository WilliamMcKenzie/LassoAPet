"""The Squid (Epic, Ocean, medium): QM's Kraken model (designs/ocean/Kraken.bbmodel)
with its animations (the run is a squid's glide, kraken_rig.glide), recoloured pink
and orange. Only the colour textures change.

Run: python3 tools/squid_design.py [out_dir]
Rerunning copies the Kraken as it is now: since Oct 3 its head faces back toward the
rider, which the Squid (built before) doesn't.
Writes designs/ocean/Squid.bbmodel, a preview and the Pets headshot assets/ui/PetSquid.png.
"""

import copy
import json
import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import snake_design as S  # noqa: E402
from partlib import render  # noqa: E402

ROOT = os.path.join(os.path.dirname(__file__), "..")
SRC = os.path.join(ROOT, "designs", "ocean", "Kraken.bbmodel")
MODEL = os.path.join(ROOT, "designs", "ocean", "Squid.bbmodel")

# the Kraken's textures by name -> the Squid's colours (eye white and pupil stay)
COLORS = {"navy": (255, 150, 160), "band": (236, 112, 132), "cap": (255, 138, 72),
          "capdark": (226, 100, 50), "pink": (255, 214, 120)}


def build():
    m = copy.deepcopy(json.load(open(SRC)))
    m["name"] = "Squid"
    for t in m["textures"]:
        if t["name"] in COLORS:
            new = S.solid_texture(t["name"], COLORS[t["name"]])
            t["source"] = new["source"]
    return m


def main(out="/mnt/project-files/animals/ocean"):
    m = build()
    for path in (MODEL, os.path.join(out, "Squid.bbmodel")):
        with open(path, "w") as f:
            json.dump(m, f, separators=(",", ":"))
    parts = S.posed(m)
    W, H = 480, 440
    cams = [dict(eye=(0, 12, -42), target=(0, 10, 0)), dict(eye=(-32, 26, -30), target=(0, 10, 0))]
    sheet = Image.new("RGB", (W * 2, H))
    for i, cam in enumerate(cams):
        sheet.paste(render(parts, W=W, H=H, fov=44, **cam), (i * W, 0))
    sheet.save(os.path.join(out, "Squid.png"))
    import refine_designs as R
    R.HEAD_KEYS = R.HEAD_KEYS + ("cap",)
    R.headshot("Squid", MODEL)
    path = os.path.join(ROOT, "assets", "ui", "PetSquid.png")
    im = Image.open(path)
    im = im.crop(im.getbbox())
    s = max(im.size) + 24
    pad = Image.new("RGBA", (s, s))
    pad.paste(im, ((s - im.width) // 2, (s - im.height) // 2))
    pad.resize((512, 512), Image.LANCZOS).save(path)


if __name__ == "__main__":
    main(*sys.argv[1:])
