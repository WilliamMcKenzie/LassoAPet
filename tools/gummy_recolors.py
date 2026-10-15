"""Yellow and Green Gummy Bears: World 3 Candyland's recoloured Gummy Bears (QM, Oct 15: "2
recolors of gummy bear which are each 1.5x and 2x bigger respectively: yellow and green bear").

QM's Gummy Bear (designs/candyland/GummyBear.bbmodel), shapes, bones and animations untouched,
with its palette's cherry and strawberry pinks swapped for lemon or lime. Sizes (1.5x, 2x) and
rarities are in Config.

Run: python3 tools/gummy_recolors.py
Convert: python3 tools/bbmodel_to_luau.py designs/candyland/YellowGummyBear.bbmodel src/shared/Animals/YellowGummyBearModel.luau
         python3 tools/bbmodel_to_luau.py designs/candyland/GreenGummyBear.bbmodel src/shared/Animals/GreenGummyBearModel.luau
"""

import base64
import io
import json
import os

from PIL import Image

ROOT = os.path.join(os.path.dirname(__file__), "..")
DIR = os.path.join(ROOT, "designs", "candyland")
# the Gummy Bear's palette colour -> each recolour's (light, belly, body, paws)
PINKS = [(255, 150, 206), (255, 92, 150), (236, 36, 72), (168, 18, 50)]
BEARS = {
    "YellowGummyBear": [(255, 244, 168), (255, 226, 92), (250, 196, 28), (206, 142, 12)],
    "GreenGummyBear": [(196, 246, 150), (132, 224, 88), (58, 184, 58), (28, 124, 40)],
}


def build(name):
    m = json.load(open(os.path.join(DIR, "GummyBear.bbmodel")))
    swap = dict(zip(PINKS, BEARS[name]))
    for t in m["textures"]:
        head, data = t["source"].split(",", 1)
        im = Image.open(io.BytesIO(base64.b64decode(data))).convert("RGBA")
        px = im.load()
        for x in range(im.width):
            for y in range(im.height):
                r, g, b, a = px[x, y]
                if (r, g, b) in swap:
                    px[x, y] = (*swap[(r, g, b)], a)
        buf = io.BytesIO()
        im.save(buf, "PNG")
        t["source"] = head + "," + base64.b64encode(buf.getvalue()).decode()
    m["name"] = name
    return m


if __name__ == "__main__":
    for name in BEARS:
        json.dump(build(name), open(os.path.join(DIR, name + ".bbmodel"), "w"))
        print("wrote", name)
