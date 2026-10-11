"""Tyrant Rex: the Jurassic's boss (QM Oct 11): "a burgundee recolor of TRex with blackeyes red
pupils". QM's animated T-Rex (designs/jurassic/TRex.bbmodel) with its palette texture
repainted: burgundy body, dark wine stripes, a dusty rose belly, black eyes with red pupils.

Run from the repo root: python3 tools/rex_boss.py
Writes designs/bosses/TyrantRex.bbmodel and previews in /mnt/project-files/animals/bosses/.
Then: python3 tools/bbmodel_to_luau.py --zyx designs/bosses/TyrantRex.bbmodel src/shared/Bosses/TyrantRexModel.luau
"""

import base64
import io
import json
import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import animal_designs as A  # noqa: E402

ROOT = os.path.join(os.path.dirname(__file__), "..")
SRC = os.path.join(ROOT, "designs", "jurassic", "TRex.bbmodel")
DST = os.path.join(ROOT, "designs", "bosses", "TyrantRex.bbmodel")
OUT = "/mnt/project-files/animals/bosses"

RECOLOR = {
    (240, 140, 52): (128, 20, 44),  # body: burgundy
    (168, 82, 32): (70, 8, 24),  # stripes, brow: dark wine
    (252, 218, 166): (206, 120, 124),  # belly, jaw: dusty rose
    (90, 44, 20): (40, 4, 12),  # nostrils
    (255, 206, 40): (16, 12, 18),  # eyes: black
    (30, 30, 45): (255, 34, 34),  # pupils: red
}


def main():
    m = json.load(open(SRC))
    m["name"] = "TyrantRex"
    t = m["textures"][0]
    im = Image.open(io.BytesIO(base64.b64decode(t["source"].split(",", 1)[1]))).convert("RGBA")
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if (r, g, b) in RECOLOR:
                px[x, y] = (*RECOLOR[(r, g, b)], a)
    buf = io.BytesIO()
    im.save(buf, "PNG")
    t["source"] = "data:image/png;base64," + base64.b64encode(buf.getvalue()).decode()
    with open(DST, "w") as f:
        json.dump(m, f, separators=(",", ":"))
    previews(m)
    print("wrote", DST)


def previews(m):
    import horse_rig
    from partlib import render
    from snow_rig import posed
    horse_rig.EULER = "ZYX"
    os.makedirs(OUT, exist_ok=True)
    T = 480
    sheet = Image.new("RGB", (T * 3, T))
    cams = [dict(eye=(-26, 13, -30), target=(0, 7, -1), W=T, H=T, fov=40), dict(eye=(-36, 7, 0), target=(0, 7, 0), W=T, H=T, fov=38),
            dict(eye=(-9, 12, -20), target=(0, 10, -8), W=T, H=T, fov=34)]
    roar = next(a for a in m["animations"] if a["name"] == "idle")
    for i, cam in enumerate(cams):
        ps = posed(m, roar if i == 2 else None, 3.3 if i == 2 else 0)
        for p in ps:
            if p.name.startswith(("Eye", "Pupil", "Tooth", "Claw", "ArmClaw", "Nostril")):
                p.plain = True
        sheet.paste(render(ps, **cam), (i * T, 0))
    A.label(sheet, ["Tyrant Rex (Jurassic boss)", "side", "face"], 22).save(os.path.join(OUT, "TyrantRex.png"))


if __name__ == "__main__":
    main()
