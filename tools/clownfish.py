"""Clownfish (QM, Oct 11): the original Fish (designs/animals/Fish.bbmodel: shapes, bones and
flop animations kept) in clownfish orange, with three white bands edged in black wrapping
right round it: behind the eyes, mid-body and at the tail.

Run: python3 tools/clownfish.py [out_dir]
writes Clownfish.bbmodel, Clownfish.png and Clownfish_vs_fish.png.
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

ROOT = os.path.join(os.path.dirname(__file__), "..")
FISH = os.path.join(ROOT, "designs", "animals", "Fish.bbmodel")
OUT = "/mnt/project-files/animals/clownfish"

# palette.png slot (x pixel) -> colour; the Fish's slots recoloured, and two new ones
PALETTE = {
    0: (255, 150, 60),  # belly
    2: (255, 112, 16),  # body
    4: (30, 30, 45),  # mouth
    6: (255, 255, 255),  # eye
    8: (30, 30, 45),  # pupil
    10: (255, 112, 16),  # fins
    12: (255, 255, 255),  # bands
    14: (24, 24, 30),  # band edges
}
BAND, EDGE = 12, 14
EDGE_W = 1.6
# white bands (bb z, front is -z), each edged in black on both sides
BANDS = ((-38.5, -30.5), (-6.0, 6.0), (37.0, 45.0))
# the pieces the bands cut through
BODY = ("Belly", "Body", "HeadBelly", "Head", "TailBelly", "Tail")


def palette():
    im = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    for x, rgb in PALETTE.items():
        for dx in (0, 1):
            for y in (0, 1):
                im.putpixel((x + dx, y), (*rgb, 255))
    buf = io.BytesIO()
    im.save(buf, "PNG")
    return "data:image/png;base64," + base64.b64encode(buf.getvalue()).decode()


def stripes():
    """(z0, z1, slot) runs along the body: orange, then edge, band, edge, ..."""
    cuts = []
    for z0, z1 in BANDS:
        cuts += [(z0 - EDGE_W, z0, EDGE), (z0, z1, BAND), (z1, z1 + EDGE_W, EDGE)]
    return cuts


def paint(e, slot):
    for f in e["faces"].values():
        f["uv"] = [slot + 0.5, 0.5, slot + 1.5, 1.5]


def split(e):
    """Cuts a body cube along z wherever a band crosses it: [(z0, z1, slot or None)]."""
    lo, hi = e["from"][2], e["to"][2]
    pieces, z = [], lo
    for z0, z1, slot in stripes():
        a, b = max(z0, lo), min(z1, hi)
        if a >= b:
            continue
        if a > z:
            pieces.append((z, a, None))
        pieces.append((a, b, slot))
        z = b
    if z < hi:
        pieces.append((z, hi, None))
    return pieces


def clownfish(m):
    m = json.loads(json.dumps(m))
    m["name"] = "Clownfish"
    m["textures"][0]["source"] = palette()
    swap = {}  # element uuid -> its pieces' uuids
    keep = []
    for e in m["elements"]:
        if e["name"] not in BODY or len(split(e)) == 1 and split(e)[0][2] is None:
            keep.append(e)
            continue
        ids = []
        for n, (z0, z1, slot) in enumerate(split(e)):
            p = json.loads(json.dumps(e))
            p["uuid"] = str(uuid.uuid4())
            p["name"] = e["name"] if slot is None else f"{e['name']}{'Band' if slot == BAND else 'Edge'}{n}"
            if slot is None and n:
                p["name"] = f"{e['name']}{n}"
            p["from"][2], p["to"][2] = z0, z1
            p["origin"][2] = (z0 + z1) / 2
            if slot is not None:
                paint(p, slot)
            keep.append(p)
            ids.append(p["uuid"])
        swap[e["uuid"]] = ids
    m["elements"] = keep

    def walk(node):
        if isinstance(node, str):
            return swap.get(node, [node])
        node["children"] = [c for k in node["children"] for c in walk(k)]
        return [node]

    m["outliner"] = [n for r in m["outliner"] for n in walk(r)]
    # black tips on the side fins
    for e in list(m["elements"]):
        if e["name"] in ("FinL", "FinR"):
            sx = -1 if e["name"] == "FinL" else 1
            tip = json.loads(json.dumps(e))
            tip["uuid"], tip["name"] = str(uuid.uuid4()), e["name"] + "Tip"
            outer = e["from"][0] if sx < 0 else e["to"][0]
            if sx < 0:
                e["from"][0] = outer + 3
                tip["to"][0] = outer + 3
            else:
                e["to"][0] = outer - 3
                tip["from"][0] = outer - 3
            paint(tip, EDGE)
            m["elements"].append(tip)

            def attach(node):
                if isinstance(node, str):
                    return False
                if e["uuid"] in node["children"]:
                    node["children"].append(tip["uuid"])
                    return True
                return any(attach(c) for c in node["children"])

            for r in m["outliner"]:
                attach(r)
    return m


def parts(model, anim=None, t=0.0):
    ps = posed(model, anim, t)
    for p in ps:
        if p.name.startswith(("Eye", "Pupil")):
            p.plain = True
    return ps


def main(out=OUT):
    os.makedirs(out, exist_ok=True)
    fish = json.load(open(FISH))
    m = clownfish(fish)
    with open(os.path.join(out, "Clownfish.bbmodel"), "w") as f:
        json.dump(m, f, separators=(",", ":"))
    T = 480
    views = [dict(eye=(-18, 10, -19), target=(0, 3, 0.5), W=T, H=T, fov=36), dict(eye=(-22, 3.5, 0), target=(0, 3, 0), W=T, H=T, fov=34),
             dict(eye=(14, 10, 17), target=(0, 3, 1), W=T, H=T, fov=36)]
    sheet = Image.new("RGB", (T * 3, T))
    for i, v in enumerate(views):
        sheet.paste(render(parts(m), **v), (i * T, 0))
    A.label(sheet, ["Clownfish", "side", "back"], 22).save(os.path.join(out, "Clownfish.png"))
    pair = Image.new("RGB", (T * 2, T))
    pair.paste(render(parts(fish), **views[0]), (0, 0))
    pair.paste(render(parts(m), **views[0]), (T, 0))
    A.label(pair, ["Fish", "Clownfish"], 22).save(os.path.join(out, "Clownfish_vs_fish.png"))
    print("wrote", out, len(m["elements"]), "elements")


if __name__ == "__main__":
    main(*sys.argv[1:])
