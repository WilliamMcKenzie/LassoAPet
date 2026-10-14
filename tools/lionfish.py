"""Lionfish (QM Oct 11: "use original fish to make a new lionfish with spikes similar to how we
did boar spikes (like via mesh)"). Design only, not in the game.

Copies designs/animals/Fish.bbmodel (shapes, bones and animations unchanged) and
  - recolours it: cream base with red-orange stripes (Body, Head and Tail cut into z slices),
    pale peach belly, maroon fins; the old Dorsal fin goes,
  - adds banded spines like the Rock Hog's back spikes (stepped cubes + a pyramid mesh tip, red
    and cream bands): a tall dorsal crest on root raked back, two short ones on the tail, a little
    pair over the eyes on neck, and a fan of five on each pectoral fin (FinL/FinR).
Each spine is its own bone, built straight up from its origin and tilted (X back, Z out), so
preview with ZYX like QM's files.

Run from the repo root: python3 tools/lionfish.py
Writes Lionfish.bbmodel, Lionfish.png, Lionfish_vs_horse.png and GIFs in /mnt/project-files/animals/lionfish/.
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
import horse_rig  # noqa: E402
from partlib import render  # noqa: E402
from rock_hog import cube, spike  # noqa: E402
from snow_rig import posed  # noqa: E402

ROOT = os.path.join(os.path.dirname(__file__), "..")
FISH = os.path.join(ROOT, "designs", "animals", "Fish.bbmodel")
HORSE = os.path.join(ROOT, "designs", "animals", "Horse.bbmodel")
OUT = "/mnt/project-files/animals/lionfish"

CREAM = (255, 240, 214)
STRIPE = (232, 72, 40)
PEACH = (255, 214, 186)
MAROON = (150, 36, 52)
MOUTH = (96, 24, 36)
RECOLOR = {(60, 132, 232): CREAM, (222, 240, 255): PEACH, (36, 88, 184): MAROON, (28, 40, 84): MOUTH}
STRIPE_CELL = (0, 4)
BANDS = [(2, 4), (4, 4), (6, 4), (8, 4)]  # spine bands, root to tip
BAND_RGB = [STRIPE, CREAM, STRIPE, CREAM]
STRIPED = {"Body": 6.75, "Head": 6.48, "Tail": 6.48}  # slice length; slices alternate cream/stripe

SPINES = [  # (bone, parent, origin, rotation, scale)
    ("Spine0", "root", (0, 54.0, -22.0), (22, 0, 0), 1.35),
    ("Spine1", "root", (0, 54.0, -15.0), (28, 0, 0), 1.45),
    ("Spine2", "root", (0, 54.0, -8.0), (33, 0, 0), 1.4),
    ("Spine3", "root", (0, 54.0, -1.0), (38, 0, 0), 1.3),
    ("Spine4", "root", (0, 54.0, 6.0), (43, 0, 0), 1.15),
    ("Spine5", "root", (0, 54.0, 13.0), (48, 0, 0), 1.0),
    ("Spine6", "root", (0, 54.0, 20.0), (53, 0, 0), 0.85),
    ("SpineT0", "Tail", (0, 45.9, 33.0), (55, 0, 0), 0.7),
    ("SpineT1", "Tail", (0, 45.9, 42.0), (60, 0, 0), 0.6),
    ("BrowL", "neck", (-9.0, 48.6, -50.0), (-15, 0, 25), 0.45),
    ("BrowR", "neck", (9.0, 48.6, -50.0), (-15, 0, -25), 0.45),
]
for i, rx in enumerate((-25, 0, 25, 50, 75)):  # pectoral fans: out sideways, spread front to back
    k = 1.0 - 0.08 * abs(i - 1)
    SPINES.append((f"FanL{i}", "FinL", (-24.0, 15.5, -14.85), (rx, 0, 58), k))
    SPINES.append((f"FanR{i}", "FinR", (24.0, 15.5, -14.85), (rx, 0, -58), k))


def spine_els(name, o, k):
    """Thin banded spine: three stepped cubes and a pyramid tip, straight up from o."""
    ox, oy, oz = o
    els, y = [], oy
    for i, (w, h) in enumerate(((2.6, 11.0), (2.2, 10.0), (1.8, 10.0))):
        h *= k
        els.append(cube(f"{name}{i}", (ox - w, y, oz - w), (ox + w, y + h, oz + w), BANDS[i]))
        y += h
    w = 1.8
    els.append(spike(f"{name}Tip", (ox - w, 0, oz - w), (ox + w, y, oz + w), (ox, y + 14 * k, oz), BANDS[3]))
    return els


def find(nodes, gid):
    for n in nodes:
        if isinstance(n, dict):
            if n["uuid"] == gid:
                return n
            r = find(n["children"], gid)
            if r:
                return r


def lionfish(m):
    m = json.loads(json.dumps(m))
    m["name"] = "Lionfish"
    t = m["textures"][0]
    im = Image.open(io.BytesIO(base64.b64decode(t["source"].split(",", 1)[1]))).convert("RGBA")
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if (r, g, b) in RECOLOR:
                px[x, y] = (*RECOLOR[(r, g, b)], a)
    for (cx, cy), col in zip([STRIPE_CELL] + BANDS, [STRIPE] + BAND_RGB):
        for dx in (0, 1):
            for dy in (0, 1):
                px[cx + dx, cy + dy] = (*col, 255)
    buf = io.BytesIO()
    im.save(buf, "PNG")
    t["source"] = "data:image/png;base64," + base64.b64encode(buf.getvalue()).decode()

    groups = {g["name"]: g for g in m["groups"]}
    nodes = {n: find(m["outliner"], g["uuid"]) for n, g in groups.items()}

    def swap(old, new):
        m["elements"] = [e for e in m["elements"] if e["uuid"] != old["uuid"]] + new
        for node in nodes.values():
            if old["uuid"] in node["children"]:
                i = node["children"].index(old["uuid"])
                node["children"][i:i + 1] = [e["uuid"] for e in new]

    els = {e["name"]: e for e in m["elements"]}
    swap(els["Dorsal"], [])
    for name, step in STRIPED.items():  # stripes: cut into z slices, every other one red
        e = els[name]
        (x0, y0, z0), (x1, y1, z1) = e["from"], e["to"]
        cell = [int(v) for v in e["faces"]["north"]["uv"][:2]]
        n = round((z1 - z0) / step)
        new = []
        for i in range(n):
            a, b = z0 + (z1 - z0) * i / n, z0 + (z1 - z0) * (i + 1) / n
            new.append(cube(f"{name}{i}", (x0, y0, a), (x1, y1, b), STRIPE_CELL if i % 2 else tuple(cell)))
        swap(e, new)
    template = groups["FinL"]
    for name, parent, o, rot, k in SPINES:
        es = spine_els(name, o, k)
        m["elements"] += es
        g = dict(template, name=name, uuid=str(uuid.uuid4()), origin=list(o), rotation=list(rot))
        m["groups"].append(g)
        nodes[parent]["children"].append({"uuid": g["uuid"], "isOpen": True, "children": [e["uuid"] for e in es]})
    return m


def parts(model, anim=None, t=0.0):
    ps = posed(model, anim, t)
    for p in ps:
        if p.name.startswith(("Eye", "Pupil")):
            p.plain = True
    return ps


def main(out=OUT):
    horse_rig.EULER = "ZYX"
    os.makedirs(out, exist_ok=True)
    m = lionfish(json.load(open(FISH)))
    with open(os.path.join(out, "Lionfish.bbmodel"), "w") as f:
        json.dump(m, f, separators=(",", ":"))
    T = 440
    views = [dict(eye=(-24, 13, -30), target=(0, 4, -1), W=T, H=T, fov=38), dict(eye=(-36, 5, -1), target=(0, 4, -1), W=T, H=T, fov=36),
             dict(eye=(-9, 8, -30), target=(0, 4, -3), W=T, H=T, fov=34), dict(eye=(-14, 30, 10), target=(0, 3, 0), W=T, H=T, fov=38)]
    sheet = Image.new("RGB", (T * 4, T))
    for i, v in enumerate(views):
        sheet.paste(render(parts(m), **v), (i * T, 0))
    A.label(sheet, ["Lionfish", "side", "face", "top"], 22).save(os.path.join(out, "Lionfish.png"))
    cam = dict(eye=(-30, 12, -30), target=(0, 6, 0), W=T, H=T, fov=36)
    pair = Image.new("RGB", (T * 2, T))
    pair.paste(render(parts(json.load(open(HORSE))), **cam), (0, 0))
    pair.paste(render(parts(m), **cam), (T, 0))
    A.label(pair, ["Horse", "Lionfish"], 22).save(os.path.join(out, "Lionfish_vs_horse.png"))
    if "gifs" in sys.argv:
        for name, n in (("idle", 20), ("walk", 14), ("gallop", 14)):
            anim = next(x for x in m["animations"] if x["name"] == name)
            L = anim["length"]
            A.gif(os.path.join(out, f"Lionfish_{name}.gif"),
                  [A.label(render(parts(m, anim, L * i / n), **views[0]), [name], 22) for i in range(n)], fps=n / L)
    print("wrote", out, len(m["elements"]), "elements")


if __name__ == "__main__":
    main()
