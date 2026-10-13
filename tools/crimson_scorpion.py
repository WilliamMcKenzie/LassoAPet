"""Crimson Scorpion (World 2, Crimson Lands, Uncommon; QM Oct 13: "based on the OG scorpion").

QM's Scorpion (designs/desert/Scorpion.bbmodel), shapes, bones and animations untouched,
with its palette recoloured: crimson body, dark crimson bands, purple joints, a near-black
purple stinger. Eyes stay white with dark pupils.

Run: python3 tools/crimson_scorpion.py
Writes designs/crimson/CrimsonScorpion.bbmodel and a preview in /mnt/project-files/animals/crimson_scorpion/.
"""

import base64
import io
import json
import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import snake_design as S  # noqa: E402
from partlib import render  # noqa: E402

ROOT = os.path.join(os.path.dirname(__file__), "..")
NAME = "CrimsonScorpion"
OUT = "/mnt/project-files/animals/crimson_scorpion"

RECOLOR = {
    (230, 160, 74): (186, 26, 52),  # body, head, hands, tail: crimson (the Eyeworm's family)
    (184, 110, 50): (132, 16, 40),  # every other band, pincer fingers, shins: dark crimson
    (160, 70, 60): (122, 44, 168),  # shoulders, arms, thighs: purple
    (70, 44, 40): (44, 16, 48),  # stinger: near-black purple
}


def build():
    m = json.load(open(os.path.join(ROOT, "designs", "desert", "Scorpion.bbmodel")))
    t = m["textures"][0]
    head, data = t["source"].split(",", 1)
    im = Image.open(io.BytesIO(base64.b64decode(data))).convert("RGBA")
    px = im.load()
    for x in range(im.width):
        for y in range(im.height):
            r, g, b, a = px[x, y]
            if a and (r, g, b) in RECOLOR:
                px[x, y] = (*RECOLOR[(r, g, b)], a)
    buf = io.BytesIO()
    im.save(buf, "PNG")
    t["source"] = head + "," + base64.b64encode(buf.getvalue()).decode()
    m["name"] = NAME
    return m


def main():
    m = build()
    with open(os.path.join(ROOT, "designs", "crimson", NAME + ".bbmodel"), "w") as f:
        json.dump(m, f, separators=(",", ":"))
    os.makedirs(OUT, exist_ok=True)
    W = H = 560
    cams = [dict(eye=(-22, 14, -26), target=(0, 3, 0)), dict(eye=(26, 16, 20), target=(0, 3, 0))]
    sheet = Image.new("RGB", (W * 2, H))
    parts = S.posed(m)
    for i, cam in enumerate(cams):
        sheet.paste(render(parts, W=W, H=H, fov=40, **cam), (i * W, 0))
    sheet.save(os.path.join(OUT, NAME + ".png"))


if __name__ == "__main__":
    main()
