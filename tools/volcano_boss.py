"""Volcano boss (QM Oct 11): "take the snake and lets make it so the head has a webbed
headcrest. Color scheme should be red and pale beige like a typical dragon color scheme.
Be a bit creative with it."

Reads designs/desert/Snake.bbmodel (shapes, bones and animations unchanged) and
  - recolours it dragon style: red scales, dark crimson bands, pale beige belly, horns and
    back spikes, glowing gold eyes,
  - adds a webbed frill (bone Crest under Head): beige spines fanned out round the back of
    the head in a cone, with crimson webbing between them (prism meshes, not 2D plates),
  - turns the rattle into a glowing flame tail tip (Glow* parts are Neon in game).

Run from the repo root: python3 tools/volcano_boss.py [gifs]
Writes LavaWyrm.bbmodel and renders in /mnt/project-files/animals/bosses/.
"""

import base64
import io
import json
import math
import os
import sys
import uuid

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import animal_designs as A  # noqa: E402
from partlib import render  # noqa: E402
from snow_rig import posed  # noqa: E402

ROOT = os.path.join(os.path.dirname(__file__), "..")
SNAKE = os.path.join(ROOT, "designs", "desert", "Snake.bbmodel")
HORSE = os.path.join(ROOT, "designs", "animals", "Horse.bbmodel")
OUT = "/mnt/project-files/animals/bosses"
NAME = "LavaWyrm"

RED = (214, 44, 40)
CRIMSON = (138, 22, 34)
BEIGE = (246, 226, 186)
BONE = (236, 208, 160)
WEB = (176, 30, 42)
RECOLOR = {  # Snake texture name -> new colour
    "gold": RED, "cream": BEIGE, "maroon": CRIMSON, "teal": BONE,
    "pink": (120, 26, 40), "amber": (255, 204, 40), "tan": BEIGE,
}
FLAME = [(255, 110, 20), (255, 170, 30), (255, 230, 90)]

# frill: spines fanned round the back of the head, opening backwards like a cone
CREST_C = np.array([0.0, 34.0, -97.0])
CREST_PHI = np.linspace(-110, 110, 13)  # degrees from straight up, + toward +x
CREST_OPEN = 40  # degrees the cone tilts back
START = 5.0


def solid(rgb):
    im = Image.new("RGBA", (16, 16), (*rgb, 255))
    buf = io.BytesIO()
    im.save(buf, "PNG")
    return "data:image/png;base64," + base64.b64encode(buf.getvalue()).decode()


def mesh(name, verts, faces, tex):
    v = {f"v{i}": [float(c) for c in p] for i, p in enumerate(verts)}
    fs = {f"f{j}": {"uv": {f"v{k}": [0, 0] for k in f}, "vertices": [f"v{k}" for k in f], "texture": tex}
          for j, f in enumerate(faces)}
    return {"name": name, "type": "mesh", "uuid": str(uuid.uuid4()), "origin": [0, 0, 0], "rotation": [0, 0, 0],
            "color": 0, "vertices": v, "faces": fs}


def spike(name, base, d, length, w, tex):
    """Square pyramid from base along d (unit)."""
    a = np.array([0, 0, 1.0]) if abs(d[2]) < 0.9 else np.array([1.0, 0, 0])
    u = np.cross(d, a)
    u /= np.linalg.norm(u)
    v = np.cross(d, u)
    q = [base - u * w - v * w, base + u * w - v * w, base + u * w + v * w, base - u * w + v * w]
    return mesh(name, q + [base + d * length], [[3, 2, 1, 0], [4, 0, 1], [4, 1, 2], [4, 2, 3], [4, 3, 0]], tex)


def prism(name, tri, normal, t, tex):
    """Triangle tri thickened by t along normal: real depth, no 2D plate."""
    lo = [p - normal * t / 2 for p in tri]
    hi = [p + normal * t / 2 for p in tri]
    return mesh(name, lo + hi, [[0, 1, 2], [5, 4, 3], [0, 3, 4, 1], [1, 4, 5, 2], [2, 5, 3, 0]], tex)


def ray(phi):
    p = math.radians(phi)
    d0 = np.array([math.sin(p), math.cos(p), 0.0])
    o = math.radians(CREST_OPEN)
    d = math.cos(o) * d0 + math.sin(o) * np.array([0, 0, 1.0])
    return d / np.linalg.norm(d), 92 - 40 * (abs(phi) / 110) ** 2


def find(nodes, gid):
    for n in nodes:
        if isinstance(n, dict):
            if n["uuid"] == gid:
                return n
            r = find(n["children"], gid)
            if r:
                return r


def wyrm(m):
    m = json.loads(json.dumps(m))
    m["name"] = NAME
    for t in m["textures"]:
        if t["name"] in RECOLOR:
            t["source"] = solid(RECOLOR[t["name"]])
    tex = {}
    for key, rgb in (("web", WEB), ("bone", BONE)) + tuple((f"flame{i}", c) for i, c in enumerate(FLAME)):
        t = dict(m["textures"][1], name=key, uuid=str(uuid.uuid4()), id=str(len(m["textures"])), source=solid(rgb))
        tex[key] = len(m["textures"])
        m["textures"].append(t)
    for e in m["elements"]:
        if e["name"].startswith("Slit_pupil") or e["name"].startswith("Amber_iris"):
            e["name"] = "Glow" + e["name"]
    # the rattle becomes a flame: orange -> gold -> yellow, a glowing point on the end
    for i, n in enumerate(("Rattle1", "Rattle2", "Rattle3")):
        e = next(e for e in m["elements"] if e["name"] == n)
        e["name"] = f"GlowFlame{i}"
        for f in e["faces"].values():
            f["texture"] = tex[f"flame{i}"]
    r3 = next(e for e in m["elements"] if e["name"] == "GlowFlame2")
    (x0, y0, z0), (x1, y1, z1) = r3["from"], r3["to"]
    tip = mesh("GlowFlameTip", [(x0, y0, z1), (x1, y0, z1), (x1, y1, z1), (x0, y1, z1), ((x0 + x1) / 2, (y0 + y1) / 2, z1 + 16)],
               [[0, 1, 2, 3], [4, 1, 0], [4, 2, 1], [4, 3, 2], [4, 0, 3]], tex["flame2"])
    seg8 = next(g for g in m["groups"] if g["name"] == "Seg8")
    find(m["outliner"], seg8["uuid"])["children"].append(tip["uuid"])
    m["elements"].append(tip)
    # webbed frill
    els = []
    rays = [ray(p) for p in CREST_PHI]
    for i, (d, L) in enumerate(rays):
        els.append(spike(f"CrestSpine{i}", CREST_C + d * START, d, L - START, 3.4, tex["bone"]))
    for i in range(len(rays) - 1):
        (d0, L0), (d1, L1) = rays[i], rays[i + 1]
        n = np.cross(d0, d1)
        n /= np.linalg.norm(n)
        tri = [CREST_C + (d0 + d1) * 2.0, CREST_C + d0 * L0 * 0.8, CREST_C + d1 * L1 * 0.8]
        els.append(prism(f"CrestWeb{i}", tri, n, 1.6, tex["web"]))
    head = next(g for g in m["groups"] if g["name"] == "Head")
    g = dict(head, name="Crest", uuid=str(uuid.uuid4()), origin=list(CREST_C), rotation=[0, 0, 0])
    m["groups"].append(g)
    find(m["outliner"], head["uuid"])["children"].append({"uuid": g["uuid"], "isOpen": True, "children": [e["uuid"] for e in els]})
    m["elements"] += els
    return m


def parts(model, anim=None, t=0.0):
    ps = posed(model, anim, t)
    for p in ps:
        if p.name.startswith("Glow"):
            p.neon = True
        if p.name.startswith(("Eye_white", "GlowSlit", "GlowAmber")):
            p.plain = True
    return ps


def main(out=OUT):
    m = wyrm(json.load(open(SNAKE)))
    with open(os.path.join(out, NAME + ".bbmodel"), "w") as f:
        json.dump(m, f, separators=(",", ":"))
    idle = next(a for a in m["animations"] if a["name"] == "idle")
    T = 480
    views = [dict(eye=(-30, 20, -38), target=(0, 6, -4), W=T, H=T, fov=44), dict(eye=(-50, 8, -2), target=(0, 5, 2), W=T, H=T, fov=44),
             dict(eye=(-8, 14, -40), target=(0, 8, -6), W=T, H=T, fov=34), dict(eye=(18, 18, 22), target=(0, 6, -4), W=T, H=T, fov=44)]
    sheet = Image.new("RGB", (T * 4, T))
    for i, v in enumerate(views):
        sheet.paste(render(parts(m, idle, 0), **v), (i * T, 0))
    A.label(sheet, ["Lava Wyrm", "side", "face", "back"], 22).save(os.path.join(out, NAME + ".png"))
    if "gifs" in sys.argv:
        for name, n in (("idle", 20), ("walk", 16), ("gallop", 16)):
            anim = next(x for x in m["animations"] if x["name"] == name)
            L = anim["length"]
            A.gif(os.path.join(out, f"{NAME}_{name}.gif"),
                  [A.label(render(parts(m, anim, L * i / n), **views[0]), [name], 22) for i in range(n)], fps=n / L)
    print("wrote", out, len(m["elements"]), "elements")


if __name__ == "__main__":
    main()
