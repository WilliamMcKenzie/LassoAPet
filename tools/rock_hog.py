"""Rock Hog (QM Oct 11): a Volcano Boar with red fiery horns.

Run: python3 tools/rock_hog.py [out_dir]
Reads designs/converted/Boar.bbmodel (shapes and animations untouched), recolours it
in the Volcano biome's palette (warm rock coat, dark crust mane, lava-orange spikes),
makes the tusks fiery, and adds a pair of stepped horns on the head that run dark red to a yellow tip.
Spikes and horns are named Glow* so they are Neon in game. Writes RockHog.bbmodel,
RockHog.png, RockHog_vs_horse.png and idle/walk/gallop GIFs to out_dir.
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
BOAR = os.path.join(ROOT, "designs", "converted", "Boar.bbmodel")
HORSE = os.path.join(ROOT, "designs", "animals", "Horse.bbmodel")
OUT = "/mnt/project-files/animals/rockhog"

BOAR_COLS = ("coat", "mane", "brows", "hooves", "nose", "nostrils", "tusks")
BOAR_RGB = [(176, 108, 68), (112, 66, 46), (236, 190, 136), (86, 60, 52), (248, 150, 158), (130, 50, 70), (254, 246, 222)]
# colour takes: the Boar's palette, then the lava spikes and the horn base -> tip
SCHEMES = {
    "Rock": dict(coat=(148, 104, 88), mane=(98, 66, 56), brows=(200, 186, 176), hooves=(54, 42, 42), nose=(240, 134, 104),
                 nostrils=(130, 40, 30), tusks=(242, 230, 204), lava=(255, 116, 24),
                 horn=[(176, 24, 22), (224, 44, 24), (255, 96, 24), (255, 200, 70)]),
    "Basalt": dict(coat=(88, 98, 128), mane=(54, 58, 82), brows=(255, 170, 40), hooves=(36, 38, 52), nose=(255, 120, 60),
                   nostrils=(150, 40, 20), tusks=(255, 226, 120), lava=(255, 120, 20),
                   horn=[(190, 20, 30), (240, 50, 24), (255, 120, 20), (255, 220, 80)]),
    "Magma": dict(coat=(214, 70, 38), mane=(58, 48, 52), brows=(255, 210, 60), hooves=(40, 34, 36), nose=(255, 150, 80),
                  nostrils=(120, 24, 20), tusks=(70, 60, 64), lava=(255, 200, 40),
                  horn=[(60, 50, 54), (150, 30, 24), (240, 70, 20), (255, 210, 60)]),
    "Obsidian": dict(coat=(116, 80, 158), mane=(70, 46, 104), brows=(255, 140, 40), hooves=(42, 30, 60), nose=(255, 120, 150),
                     nostrils=(120, 30, 70), tusks=(250, 236, 214), lava=(255, 100, 40),
                     horn=[(200, 20, 50), (250, 50, 40), (255, 130, 30), (255, 220, 90)]),
}
SCHEME = "Basalt"
CELLS = [(2, 2), (4, 2), (6, 2), (8, 2), (10, 2)]  # new 2x2 palette cells: lava, horn base..tip
LAVA = (CELLS[0], None)
HORN = [(c, None) for c in CELLS[1:]]
LAVA_SPIKES = ("Tuft0", "Tuft1", "Tuft2", "Tuft3", "Crest0", "Crest1")


def uv(cell):
    x, y = cell
    return [x + 0.5, y + 0.5, x + 1.5, y + 1.5]


def cube(name, lo, hi, cell):
    return {"name": name, "type": "cube", "uuid": str(uuid.uuid4()), "box_uv": False, "from": list(lo), "to": list(hi),
            "origin": [(a + b) / 2 for a, b in zip(lo, hi)], "rotation": [0, 0, 0], "autouv": 0, "color": 0,
            "faces": {f: {"uv": uv(cell), "texture": 0} for f in ("north", "east", "south", "west", "up", "down")}}


def spike(name, lo, hi, apex, cell):
    """Square-based pyramid on top of the box lo..hi (only x/z of lo, hi and y of hi used)."""
    (x0, _, z0), (x1, y, z1) = lo, hi
    v = {"v0": [x0, y, z0], "v1": [x1, y, z0], "v2": [x1, y, z1], "v3": [x0, y, z1], "v4": list(apex)}
    c = [cell[0] + 1.0, cell[1] + 1.0]
    faces = {"f0": ["v0", "v1", "v2", "v3"], "f1": ["v4", "v1", "v0"], "f2": ["v4", "v2", "v1"],
             "f3": ["v4", "v3", "v2"], "f4": ["v4", "v0", "v3"]}
    return {"name": name, "type": "mesh", "uuid": str(uuid.uuid4()), "origin": [0, 0, 0], "rotation": [0, 0, 0], "color": 0,
            "vertices": v, "faces": {k: {"uv": {p: c for p in vs}, "vertices": vs, "texture": 0} for k, vs in faces.items()}}


def horn(side, s):
    """Stepped horn rising off the head's top, stepping out then up (s = -1 left, +1 right)."""
    X = lambda a, b: (min(s * a, s * b), max(s * a, s * b))  # noqa: E731
    z = (-68.0, -57.0)
    segs = [  # (inner x, outer x, y0, y1, z inset)
        (8.0, 19.0, 70.3, 77.0, 0.0),
        (11.0, 21.0, 77.0, 84.0, 1.0),
        (14.0, 22.5, 84.0, 91.0, 2.0),
    ]
    els = []
    for i, (a, b, y0, y1, d) in enumerate(segs):
        x0, x1 = X(a, b)
        els.append(cube(f"GlowHorn{side}{i}", (x0, y0, z[0] + d), (x1, y1, z[1] - d), HORN[i][0]))
    a, b, _, y1, d = segs[-1]
    x0, x1 = X(a, b)
    els.append(spike(f"GlowHornTip{side}", (x0, 0, z[0] + d), (x1, y1, z[1] - d), (s * 20.5, 103.0, (z[0] + z[1]) / 2), HORN[3][0]))
    return els


def rock_hog(m, scheme=SCHEME):
    sc = SCHEMES[scheme]
    recolor = {o: sc[k] for o, k in zip(BOAR_RGB, BOAR_COLS)}
    m = json.loads(json.dumps(m))
    m["name"] = "RockHog"
    m["meta"]["format_version"] = "5.0"
    t = m["textures"][0]
    im = Image.open(io.BytesIO(base64.b64decode(t["source"].split(",", 1)[1]))).convert("RGBA")
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if (r, g, b) in recolor:
                px[x, y] = (*recolor[(r, g, b)], a)
    for (cx, cy), col in zip(CELLS, [sc["lava"]] + sc["horn"]):
        for dx in (0, 1):
            for dy in (0, 1):
                px[cx + dx, cy + dy] = (*col, 255)
    buf = io.BytesIO()
    im.save(buf, "PNG")
    t["source"] = "data:image/png;base64," + base64.b64encode(buf.getvalue()).decode()
    # back spikes and head crest: lava
    c = [LAVA[0][0] + 1.0, LAVA[0][1] + 1.0]
    for e in m["elements"]:
        if e["name"] in LAVA_SPIKES:
            e["name"] = "Glow" + e["name"]
            for f in e["faces"].values():
                f["uv"] = {k: c for k in f["uv"]}
    # tusks: fiery like the horns, red at the jaw to a yellow tip
    for e in m["elements"]:
        if e["name"].startswith("Tusk"):
            cell = HORN[{"TuskL": 1, "TuskR": 1, "TuskUpL": 2, "TuskUpR": 2}.get(e["name"], 3)][0]
            e["name"] = "Glow" + e["name"]
            for f in e["faces"].values():
                f["uv"] = uv(cell) if e["type"] == "cube" else {k: [cell[0] + 1.0, cell[1] + 1.0] for k in f["uv"]}
    # horns: one bone each, parented to the neck
    neck = next(g for g in m["groups"] if g["name"] == "neck")
    template = next(g for g in m["groups"] if g["name"] == "TuskL")

    def find(nodes, gid):
        for n in nodes:
            if isinstance(n, dict):
                if n["uuid"] == gid:
                    return n
                r = find(n["children"], gid)
                if r:
                    return r

    neck_node = find(m["outliner"], neck["uuid"])
    for side, s in (("L", -1), ("R", 1)):
        els = horn(side, s)
        m["elements"] += els
        g = dict(template, name=f"Horn{side}", uuid=str(uuid.uuid4()), origin=[s * 13.5, 70.3, -62.5], rotation=[0, 0, 0])
        m["groups"].append(g)
        neck_node["children"].append({"uuid": g["uuid"], "isOpen": True, "children": [e["uuid"] for e in els]})
    return m


PLAIN = ("Eye", "Pupil", "Nostril", "Tusk", "CheekTuft", "Beard", "TailTuft")


def parts(model, anim=None, t=0.0):
    ps = posed(model, anim, t)
    for p in ps:
        if p.name.startswith(PLAIN):
            p.plain = True
        if p.name.startswith("Glow"):
            p.neon = True
    return ps


def main(out=OUT):
    os.makedirs(out, exist_ok=True)
    m = rock_hog(json.load(open(BOAR)))
    with open(os.path.join(out, "RockHog.bbmodel"), "w") as f:
        json.dump(m, f, separators=(",", ":"))
    previews(m, out)


def previews(m, out=OUT):
    T = 420
    views = [dict(eye=(-20, 12, -26), target=(0, 5, -1), W=T, H=T, fov=38), dict(eye=(-32, 6, -2), target=(0, 5, -1), W=T, H=T, fov=36),
             dict(eye=(-7, 8, -26), target=(0, 6, -4), W=T, H=T, fov=30)]
    sheet = Image.new("RGB", (T * 3, T))
    for i, v in enumerate(views):
        sheet.paste(render(parts(m), **v), (i * T, 0))
    A.label(sheet, ["Rock Hog", "side", "face"], 22).save(os.path.join(out, "RockHog.png"))
    cam = dict(eye=(-30, 12, -30), target=(0, 6, 0), W=T, H=T, fov=36)
    pair = Image.new("RGB", (T * 2, T))
    pair.paste(render(parts(json.load(open(HORSE))), **cam), (0, 0))
    pair.paste(render(parts(m), **cam), (T, 0))
    A.label(pair, ["Horse", "Rock Hog"], 22).save(os.path.join(out, "RockHog_vs_horse.png"))
    for name, n in (("idle", 20), ("walk", 14), ("gallop", 14)):
        anim = next(x for x in m["animations"] if x["name"] == name)
        L = anim["length"]
        A.gif(os.path.join(out, f"RockHog_{name}.gif"),
              [A.label(render(parts(m, anim, L * i / n), **views[1]), [name], 22) for i in range(n)], fps=n / L)
    print("wrote", out)


# ---------------------------------------------------------------- back spikes (on QM's file)
# Horn-style spikes fanned out of the back like the Ice Golem's crystals: each one is its own
# bone tilted backwards (X) and outwards (Z), built straight up from the bone's origin.
SPIKES = [  # (name, origin on the body's top, rotation, scale)
    ("SpikeC", (0.0, 70.0, -21.0), (30, 0, 0), 1.45),
    ("SpikeL", (-20.0, 70.0, -19.0), (26, 0, 22), 1.25),
    ("SpikeR", (20.0, 70.0, -19.0), (26, 0, -22), 1.25),
    ("SpikeBL", (-11.0, 60.5, 24.0), (44, 0, 18), 1.0),
    ("SpikeBR", (11.0, 60.5, 24.0), (44, 0, -18), 1.0),
]


def spike_els(name, o, k):
    ox, oy, oz = o
    els = []
    y = oy
    for i, (w, h) in enumerate(((6.0, 8.0), (5.0, 7.0), (4.0, 7.0))):
        w, h = w * k, h * k
        els.append(cube(f"Glow{name}{i}", (ox - w, y, oz - w), (ox + w, y + h, oz + w), HORN[i][0]))
        y += h
    w = 4.0 * k
    els.append(spike(f"Glow{name}Tip", (ox - w, 0, oz - w), (ox + w, y, oz + w), (ox, y + 12 * k, oz), HORN[3][0]))
    return els


def back_spikes(src, dst="RockHog_spikes", out=OUT):
    """Add the back spikes to QM's file (src); write dst.bbmodel and previews."""
    import horse_rig
    horse_rig.EULER = "ZYX"  # QM's hand-edited file
    m = json.load(open(src))
    root = next(g for g in m["groups"] if g["name"] == "root")
    template = next(g for g in m["groups"] if g["name"] == "HornL")

    def find(nodes, gid):
        for n in nodes:
            if isinstance(n, dict):
                if n["uuid"] == gid:
                    return n
                r = find(n["children"], gid)
                if r:
                    return r

    node = find(m["outliner"], root["uuid"])
    names = {s[0] for s in SPIKES}
    m["groups"] = [g for g in m["groups"] if g["name"] not in names]
    for name, o, rot, k in SPIKES:
        els = spike_els(name, o, k)
        m["elements"] += els
        g = dict(template, name=name, uuid=str(uuid.uuid4()), origin=list(o), rotation=list(rot))
        m["groups"].append(g)
        node["children"].append({"uuid": g["uuid"], "isOpen": True, "children": [e["uuid"] for e in els]})
    with open(os.path.join(out, dst + ".bbmodel"), "w") as f:
        json.dump(m, f, separators=(",", ":"))
    previews(m, out)


def takes(out=OUT):
    """All colour takes side by side, front three-quarter view."""
    boar = json.load(open(BOAR))
    T = 420
    cam = dict(eye=(-20, 12, -26), target=(0, 5, -1), W=T, H=T, fov=38)
    sheet = Image.new("RGB", (T * len(SCHEMES), T))
    for i, k in enumerate(SCHEMES):
        sheet.paste(render(parts(rock_hog(boar, k)), **cam), (i * T, 0))
    A.label(sheet, list(SCHEMES), 22).save(os.path.join(out, "RockHog_takes.png"))


if __name__ == "__main__":
    if sys.argv[1:2] == ["spikes"]:
        back_spikes(*sys.argv[2:])
    elif sys.argv[1:2] == ["takes"]:
        takes(*sys.argv[2:])
    else:
        main(*sys.argv[1:])
