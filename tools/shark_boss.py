"""Shark boss (QM Oct 10): the Ocean's boss, an angry real shark built from QM's Robo Shark
(designs/ocean/RoboShark.bbmodel: same blocks, bones and animations).

Run: python3 tools/shark_boss.py [out_dir]
Repaints the metal as a steel-blue shark with a white belly wrapped round its lower
sides, drops the gold robot marks, turns the glowing eyes into white eyes with black
pupils under dark slanted brows, whitens the teeth, and writes SharkBoss.bbmodel
plus renders and GIFs to out_dir.
"""

import base64
import io
import json
import os
import sys
import uuid

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import horse_rig  # noqa: E402

horse_rig.EULER = "ZYX"  # QM's hand-made file
import animal_designs as A  # noqa: E402
from partlib import render  # noqa: E402
from snow_rig import posed  # noqa: E402

ROOT = os.path.join(os.path.dirname(__file__), "..")
SRC = os.path.join(ROOT, "designs", "ocean", "RoboShark.bbmodel")
OUT = "/mnt/project-files/animals/bosses"

BODY, DARK, BELLY = (98, 130, 164), (78, 106, 138), (244, 244, 240)
EYE, PUPIL, BROW, TOOTH = (255, 255, 255), (24, 24, 32), (40, 52, 70), (252, 250, 242)
# texture index -> colour (RoboShark's textures: 0 eye glow, 6 eye centre, 15/16 teeth,
# 9 dorsal, 17 side fins, 10-14 tail fin, the rest metal)
TEX = {0: EYE, 6: PUPIL, 15: TOOTH, 16: TOOTH, 9: DARK, 17: DARK, 10: DARK, 11: DARK, 12: DARK, 13: DARK, 14: DARK}
BROW_SLANT = 50  # degrees, the front end (over the snout) down


def solid(color):
    buf = io.BytesIO()
    Image.new("RGBA", (16, 16), (*color, 255)).save(buf, "PNG")
    return "data:image/png;base64," + base64.b64encode(buf.getvalue()).decode()


def cube(name, lo, hi, tex, origin, rotation=(0, 0, 0)):
    faces = {f: {"uv": [0, 0, 16, 16], "texture": tex} for f in ("north", "east", "south", "west", "up", "down")}
    return {"name": name, "box_uv": False, "render_order": "default", "locked": False, "export": True, "scope": 0,
            "allow_mirror_modeling": True, "from": list(lo), "to": list(hi), "autouv": 0, "color": 0,
            "rotation": list(rotation), "origin": list(origin), "faces": faces, "type": "cube", "uuid": str(uuid.uuid4())}


def add_to_group(m, gname, el):
    m["elements"].append(el)
    g = next(g for g in m["groups"] if g["name"] == gname)

    def walk(n):
        if isinstance(n, dict):
            if n["uuid"] == g["uuid"]:
                n["children"].append(el["uuid"])
                return True
            return any(walk(c) for c in n["children"])
        return False

    for n in m["outliner"]:
        if walk(n):
            return


def shark(m):
    m = json.loads(json.dumps(m))
    m["name"] = "SharkBoss"
    for i, t in enumerate(m["textures"]):
        t["source"] = solid(TEX.get(i, BODY))
    belly_t, brow_t = len(m["textures"]), len(m["textures"]) + 1
    for name, col in (("belly", BELLY), ("brow", BROW)):
        t = dict(m["textures"][0])
        t.update(name=name, id=str(len(m["textures"])), uuid=str(uuid.uuid4()), source=solid(col))
        m["textures"].append(t)
    # no gold robot marks
    gold = {e["uuid"] for e in m["elements"] if e["name"] == "GoldBody"}
    m["elements"] = [e for e in m["elements"] if e["uuid"] not in gold]

    def strip(n):
        if isinstance(n, dict):
            n["children"] = [strip(c) for c in n["children"] if not (isinstance(c, str) and c in gold)]
        return n

    m["outliner"] = [strip(n) for n in m["outliner"]]
    # bigger eyes (white block, black pupil toward the front)
    for e in m["elements"]:
        if e["name"] == "GlowEyeHead":
            sx = 1 if e["from"][0] > 0 else -1
            if abs(e["to"][0] - e["from"][0]) > 0.5:  # the eye block
                e["from"], e["to"] = [sx * 4.6 if sx > 0 else -5.4, 11.7095, -17.8], [5.4 if sx > 0 else -4.6, 14.7095, -14.6]
            else:  # the pupil
                e["from"], e["to"] = [5.35 if sx > 0 else -5.65, 12.4095, -17.3], [5.65 if sx > 0 else -5.35, 14.0095, -15.9]
            e["name"] = "Eye" if abs(e["to"][0] - e["from"][0]) > 0.5 else "Pupil"
    # white belly: a slab wrapping the body's underside and lower sides, and the jaw's
    add_to_group(m, "root", cube("Belly", (-7.25, 4.0, -9.5), (7.25, 9.5, 9.5), belly_t, (0, 8.2095, -25)))
    add_to_group(m, "Jaw", cube("BellyJaw", (-3.2, 6.0, -19.5), (3.2, 7.6, -10.5), belly_t, (0, 10.2095, -10), (-45, 0, 0)))
    # angry brows over the eyes: in the head's frame (turned 22.5 about x round the neck), then slanted
    O = np.array((0, 10.2095, -10.0))
    R = horse_rig.rotm((22.5, 0, 0))
    for side, sx in (("L", -1), ("R", 1)):
        lo, hi = np.array((sx * 4.5, 14.9, -18.2)), np.array((sx * 5.9, 15.9, -14.2))
        lo, hi = np.minimum(lo, hi), np.maximum(lo, hi)
        c = O + R @ ((lo + hi) / 2 - O)
        half = (hi - lo) / 2
        add_to_group(m, "neck", cube("Brow" + side, c - half, c + half, brow_t, c, (22.5 - BROW_SLANT, 0, 0)))
    return m


def main(out=OUT):
    os.makedirs(out, exist_ok=True)
    m = shark(json.load(open(SRC)))
    with open(os.path.join(out, "SharkBoss.bbmodel"), "w") as f:
        json.dump(m, f, separators=(",", ":"))
    plain = ("Teeth", "Brow", "Eye", "Pupil")

    def parts(anim=None, t=0.0):
        ps = posed(m, anim, t)
        for p in ps:
            if p.name.startswith(plain):
                p.plain = True
        return ps

    T = 420
    views = [dict(eye=(-4.2, 2.6, -4.8), target=(0, 1.1, -0.2), W=T, H=T, fov=38), dict(eye=(-6.2, 1.2, -0.4), target=(0, 1.1, -0.2), W=T, H=T, fov=36),
             dict(eye=(-1.8, 1.6, -5.2), target=(0, 1.2, -1.4), W=T, H=T, fov=30)]  # studs (the model is ~3.5 long; the game sizes it)
    sheet = Image.new("RGB", (T * 3, T))
    for i, v in enumerate(views):
        sheet.paste(render(parts(), **v), (i * T, 0))
    A.label(sheet, ["Shark boss", "side", "face"], 22).save(os.path.join(out, "SharkBoss.png"))
    for name, n in (("idle", 20), ("walk", 14), ("gallop", 14)):
        anim = next(x for x in m["animations"] if x["name"] == name)
        L = anim["length"]
        A.gif(os.path.join(out, f"SharkBoss_{name}.gif"),
              [A.label(render(parts(anim, L * i / n), **views[1]), [name], 22) for i in range(n)], fps=n / L)
    print("wrote", out)


if __name__ == "__main__":
    main(*sys.argv[1:])
