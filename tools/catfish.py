"""Catfish (QM, Oct 13): World 2 Temple's Uncommon, "a fish with whiskers". The World 1 Fish
(designs/animals/Fish.bbmodel: shapes, bones and flop animations kept) in olive green with a
cream belly, a wider, flatter snout and mouth, dark spots on its back, and long whiskers made of
blocks: one long barbel from each corner of the mouth that sweeps out and back, drooping a step
per block, and four short chin barbels.

Run: python3 tools/catfish.py
writes designs/temple/Catfish.bbmodel and the render /mnt/project-files/world2/temple/renders/Catfish.png.
"""

import base64
import io
import json
import math
import os
import sys
import uuid

from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
from partlib import render  # noqa: E402
from horse_rig import pose  # noqa: E402

ROOT = os.path.join(os.path.dirname(__file__), "..")
FISH = os.path.join(ROOT, "designs", "animals", "Fish.bbmodel")
OUT = "/mnt/project-files/world2/temple/renders"

# palette.png slot (x pixel) -> colour: the Fish's slots recoloured, two new ones
PALETTE = {
    0: (243, 231, 181),  # belly (was pale blue)
    2: (112, 146, 52),  # body (was blue)
    4: (58, 40, 24),  # mouth (was navy)
    10: (74, 104, 38),  # fins (was dark blue)
    12: (58, 40, 24),  # whiskers
    14: (78, 108, 36),  # spots
}
WHISKER, SPOT = 12, 14

# long barbels: start at the mouth corner, each block a step further round and lower (bb units)
BARB_START = (14.85, 19.0, -66.0)  # right side; left is mirrored
BARB = [(0, 13.5), (15, 13.5), (30, 13.5), (45, 13.5), (60, 12.0), (75, 10.8)]  # (angle back from +x, length)
BARB_T, BARB_DROP = 3.4, 2.0
# chin barbels: short blocks hanging under the snout, swept back
CHIN = [(-8.1, -66.0), (-3.4, -67.5), (3.4, -67.5), (8.1, -66.0)]
CHIN_LEN, CHIN_T = 6.75, 2.0
# dark spots on the back: (x, z, w, d) on the body/head tops
SPOTS = [(-8.1, -40.0, 6.75, 6.75), (6.75, -34.0, 5.4, 5.4), (-4.0, -8.0, 8.1, 8.1),
         (9.45, 4.0, 6.75, 6.75), (-9.45, 16.0, 5.4, 5.4), (4.0, 20.0, 6.75, 6.75)]


def palette(src):
    im = Image.open(io.BytesIO(base64.b64decode(src.split(",")[1]))).convert("RGBA")
    for x, rgb in PALETTE.items():
        for dx in (0, 1):
            for y in (0, 1):
                im.putpixel((x + dx, y), (*rgb, 255))
    buf = io.BytesIO()
    im.save(buf, "PNG")
    return "data:image/png;base64," + base64.b64encode(buf.getvalue()).decode()


def cube(name, lo, hi, slot, rot=(0, 0, 0), origin=None):
    c = origin or [(a + b) / 2 for a, b in zip(lo, hi)]
    return {"name": name, "type": "cube", "uuid": str(uuid.uuid4()), "box_uv": False,
            "from": list(lo), "to": list(hi), "origin": list(c), "rotation": list(rot), "autouv": 0, "color": 0,
            "faces": {f: {"uv": [slot + 0.5, 0.5, slot + 1.5, 1.5], "texture": 0}
                      for f in ("north", "east", "south", "west", "up", "down")}}


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


def barbel(side):
    """One long whisker as blocks, each turned about Y only (single-axis rest)."""
    s = 1 if side == "R" else -1
    x, y, z = BARB_START
    x *= s
    out = []
    for i, (ang, length) in enumerate(BARB):
        a = math.radians(ang)
        dx, dz = s * math.cos(a), math.sin(a)
        cx, cz = x + dx * length / 2, z + dz * length / 2
        h = BARB_T / 2
        # the block runs along x before turning; Blockbench +Y turns +x towards -z
        e = cube(f"Whisker{side}{i + 1}", [cx - length / 2 - h * 0.6, y - h, cz - h], [cx + length / 2 + h * 0.6, y + h, cz + h],
                 WHISKER, (0, -s * ang, 0))
        out.append(e)
        x, z = x + dx * length, z + dz * length
        y -= BARB_DROP
    return out


def build():
    m = json.load(open(FISH))
    m["textures"][0]["source"] = palette(m["textures"][0]["source"])
    el = {e["name"]: e for e in m["elements"]}
    # wider, flatter snout and mouth
    el["Snout"]["from"] = [-14.85, 6.75, -70.2]
    el["Snout"]["to"] = [14.85, 33.75, -59.4]
    el["Mouth"]["from"] = [-12.15, 16.2, -70.875]
    el["Mouth"]["to"] = [12.15, 19.575, -70.2]
    head = holder(m["outliner"], el["Head"]["uuid"])
    body = holder(m["outliner"], el["Body"]["uuid"])

    def add(e, group):
        m["elements"].append(e)
        group["children"].append(e["uuid"])

    for side in ("L", "R"):
        for e in barbel(side):
            add(e, head)
    for i, (x, z) in enumerate(CHIN):
        top = 6.75
        add(cube(f"Chin{i + 1}", [x - CHIN_T / 2, top - CHIN_LEN, z - CHIN_T / 2], [x + CHIN_T / 2, top + 0.5, z + CHIN_T / 2],
                 WHISKER, (-30, 0, 0), [x, top, z]), head)
    for i, (x, z, w, d) in enumerate(SPOTS):
        on_head = z < -27
        y = 48.6 if on_head else 54.0
        add(cube(f"Spot{i + 1}", [x - w / 2, y - 0.5, z - d / 2], [x + w / 2, y + 1.35, z + d / 2], SPOT), head if on_head else body)
    m["name"] = "Catfish"
    return m


def shot(m, eye, target, W=560, H=480, fov=34):
    im = render(pose(m, None, 0), eye=eye, target=target, W=W, H=H, fov=fov, transparent=True)
    bg = Image.new("RGBA", im.size, (240, 240, 236, 255))
    bg.alpha_composite(im.convert("RGBA"))
    return bg.convert("RGB")


def main():
    os.makedirs(OUT, exist_ok=True)
    m = build()
    os.makedirs(os.path.join(ROOT, "designs", "temple"), exist_ok=True)
    json.dump(m, open(os.path.join(ROOT, "designs", "temple", "Catfish.bbmodel"), "w"), separators=(",", ":"))
    shot(m, (-13, 9, -21), (0, 2.5, -3)).save(os.path.join(OUT, "Catfish.png"))
    parts = pose(m, None, 0)
    print("Catfish:", len(m["elements"]), "elements")
    try:
        import numpy as np
        pts = np.array([c for p in parts for c in p.corners()])
        print("size studs:", pts.max(0) - pts.min(0))
    except Exception as exc:  # size is informational only
        print("size: n/a", exc)


if __name__ == "__main__":
    main()
