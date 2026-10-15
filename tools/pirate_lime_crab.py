"""Lime Crab: World 3 Pirate Cove's rarer crab (QM, Oct 15: "a recolored crab which is 2x bigger
and 3x rarer, a slightly more yellow tinged green crab").

QM's Green Crab (designs/world3/pirate/GreenCrab.bbmodel), shapes, bones, meshes and animations
untouched, with its greens recoloured toward yellow. Its size (2x) and rarity (1/3 the Green
Crab's spawns) are in Config.

Run: python3 tools/pirate_lime_crab.py
Convert: python3 tools/bbmodel_to_luau.py --zyx --meshes assets/meshes/LimeCrab designs/world3/pirate/LimeCrab.bbmodel src/shared/Animals/LimeCrabModel.luau
(its meshes are the Green Crab's shapes: tools/animal_meshes.luau gives them the same ids)
"""

import base64
import io
import json
import os

from PIL import Image

ROOT = os.path.join(os.path.dirname(__file__), "..")
NAME = "LimeCrab"
# texture name -> its new colour (the Green Crab's: 19,139,58 / 10,105,74 / 1,56,53)
RECOLOR = {"red": (86, 168, 40), "reddark": (58, 128, 34), "tip": (34, 70, 20)}


def build():
    m = json.load(open(os.path.join(ROOT, "designs", "world3", "pirate", "GreenCrab.bbmodel")))
    for t in m["textures"]:
        if t["name"] in RECOLOR:
            head, data = t["source"].split(",", 1)
            im = Image.open(io.BytesIO(base64.b64decode(data))).convert("RGBA")
            im = Image.new("RGBA", im.size, (*RECOLOR[t["name"]], 255))
            buf = io.BytesIO()
            im.save(buf, "PNG")
            t["source"] = head + "," + base64.b64encode(buf.getvalue()).decode()
    m["name"] = NAME
    return m


if __name__ == "__main__":
    json.dump(build(), open(os.path.join(ROOT, "designs", "world3", "pirate", NAME + ".bbmodel"), "w"))
    print("wrote", NAME)
