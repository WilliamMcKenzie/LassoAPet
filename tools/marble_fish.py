"""Marble Fish (QM, Oct 13): World 2 Meadow's reskin of the Fish (designs/animals/Fish.bbmodel:
shapes, bones and flop animations kept), the blues swapped for yellows, with a twisted marble
horn on its head like a unicorn's: blocks turning 45 degrees each, narrowing, white and pale
grey in turn, and a white pyramid tip.

Run: python3 tools/marble_fish.py
writes designs/world2/MarbleFish.bbmodel and renders to /mnt/project-files/animals/marble_fish/.
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
from horse_rig import pose  # noqa: E402

ROOT = os.path.join(os.path.dirname(__file__), "..")
FISH = os.path.join(ROOT, "designs", "animals", "Fish.bbmodel")
OUT = "/mnt/project-files/animals/marble_fish"

# palette.png slot (x pixel) -> colour: the Fish's slots in yellow, two new marble ones
PALETTE = {
    0: (255, 244, 196),  # belly (was pale blue)
    2: (255, 204, 36),  # body (was blue)
    4: (96, 62, 20),  # mouth (was navy)
    10: (232, 150, 16),  # fins (was dark blue)
    12: (246, 244, 238),  # marble
    14: (208, 205, 198),  # marble shade
}
MARBLE, SHADE = 12, 14

# the horn: on the head's top, over the eyes (bb units, front is -z)
HORN_Z, HORN_Y = -46.0, 48.6
SEGMENTS = [(14.0, 9.0), (11.5, 9.0), (9.0, 9.0), (6.5, 9.0)]  # (width, height) bottom up
TIP = 18.0


def palette(src):
    im = Image.open(io.BytesIO(base64.b64decode(src.split(",")[1]))).convert("RGBA")
    for x, rgb in PALETTE.items():
        for dx in (0, 1):
            for y in (0, 1):
                im.putpixel((x + dx, y), (*rgb, 255))
    buf = io.BytesIO()
    im.save(buf, "PNG")
    return "data:image/png;base64," + base64.b64encode(buf.getvalue()).decode()


def cube(name, lo, hi, slot, rot_y=0):
    c = [(a + b) / 2 for a, b in zip(lo, hi)]
    return {"name": name, "type": "cube", "uuid": str(uuid.uuid4()), "box_uv": False,
            "from": lo, "to": hi, "origin": c, "rotation": [0, rot_y, 0], "autouv": 0, "color": 0,
            "faces": {f: {"uv": [slot + 0.5, 0.5, slot + 1.5, 1.5], "texture": 0}
                      for f in ("north", "east", "south", "west", "up", "down")}}


def tip(name, w, y0, h, slot):
    a = w / 2
    V = {"v0": [-a, y0, HORN_Z - a], "v1": [a, y0, HORN_Z - a], "v2": [a, y0, HORN_Z + a], "v3": [-a, y0, HORN_Z + a],
         "v4": [0, y0 + h, HORN_Z]}
    u = [slot + 0.6, 0.6, slot + 1.4, 1.4]
    faces = {"f0": {"uv": {"v0": u[:2], "v1": [u[2], u[1]], "v2": u[2:], "v3": [u[0], u[3]]}, "texture": 0, "vertices": ["v0", "v1", "v2", "v3"]}}
    for k, (p, q) in enumerate((("v1", "v0"), ("v2", "v1"), ("v3", "v2"), ("v0", "v3"))):
        faces[f"f{k + 1}"] = {"uv": {p: [u[0], u[3]], q: [u[2], u[3]], "v4": [slot + 1, u[1]]}, "texture": 0, "vertices": ["v4", p, q]}
    return {"name": name, "type": "mesh", "uuid": str(uuid.uuid4()), "color": 0, "origin": [0, 0, 0], "rotation": [0, 0, 0],
            "vertices": V, "faces": faces}


def holder(nodes, target):
    """The outliner group whose own children hold element uuid `target`."""
    for n in nodes:
        if isinstance(n, dict):
            if target in n["children"]:
                return n
            found = holder(n["children"], target)
            if found:
                return found
    return None


def build():
    m = json.load(open(FISH))
    m["textures"][0]["source"] = palette(m["textures"][0]["source"])
    head = next(e for e in m["elements"] if e["name"] == "Head")
    group = holder(m["outliner"], head["uuid"])
    y = HORN_Y
    for i, (w, h) in enumerate(SEGMENTS):
        a = w / 2
        e = cube(f"Horn{i + 1}" if i else "Horn", [-a, y, HORN_Z - a], [a, y + h, HORN_Z + a], MARBLE if i % 2 == 0 else SHADE, 45 if i % 2 else 0)
        m["elements"].append(e)
        group["children"].append(e["uuid"])
        y += h - 0.2
    e = tip("HornTip", SEGMENTS[-1][0] * 0.8, y, TIP, MARBLE)
    m["elements"].append(e)
    group["children"].append(e["uuid"])
    m["name"] = "MarbleFish"
    return m


def main():
    os.makedirs(OUT, exist_ok=True)
    m = build()
    out = os.path.join(ROOT, "designs", "world2", "MarbleFish.bbmodel")
    json.dump(m, open(out, "w"), separators=(",", ":"))
    json.dump(m, open(os.path.join(OUT, "MarbleFish.bbmodel"), "w"), separators=(",", ":"))
    fish = json.load(open(FISH))
    cams = [dict(eye=(-16, 10, -18), target=(0, 3, -1), W=420, H=380, fov=36),
            dict(eye=(-22, 4, -1), target=(0, 3, -1), W=420, H=380, fov=34)]
    tiles = [render(pose(fish, None, 0), **cams[0]), render(pose(m, None, 0), **cams[0]), render(pose(m, None, 0), **cams[1])]
    im = Image.new("RGB", (420 * len(tiles), 380))
    for i, t in enumerate(tiles):
        im.paste(t, (420 * i, 0))
    A.label(im, ["Fish (World 1)", "Marble Fish", "Side"]).save(os.path.join(OUT, "MarbleFish.png"))
    print("MarbleFish:", len(m["elements"]), "elements")


if __name__ == "__main__":
    main()
