"""The Halloween world's giga rares (QM, Oct 15): nine Legendaries in Halloween colours. The
colour swaps live in src/shared/HalloweenSkins.luau (the game recolours each base's model and
egg from them at load); this renders the same swaps from the bases' .bbmodels.

Run from the repo root:
  python3 tools/halloween_giga.py            check the swaps, lineup -> /mnt/project-files/halloween/animals/renders/Giga_lineup.png
  python3 tools/halloween_giga.py headshots  assets/ui/Pet<Kind>.png
  python3 tools/halloween_giga.py eggs       assets/ui/<Kind>EggRender.png
  python3 tools/halloween_giga.py bosses     the Halloween bosses -> renders/Bosses_lineup.png
"""

import copy
import json
import os
import re
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, os.path.dirname(__file__))
import pet_headshots as P  # noqa: E402
import horse_rig as HR  # noqa: E402
import snake_design as S  # noqa: E402
import horse_egg_takes as C  # noqa: E402
from partlib import render  # noqa: E402

ROOT = os.path.join(os.path.dirname(__file__), "..")
OUT = "/mnt/project-files/halloween/animals"
FONT = ImageFont.load_default(size=22)
SRC = open(os.path.join(ROOT, "src", "shared", "HalloweenSkins.luau")).read()
def rgb(v):
    return tuple(int(v[i:i + 2], 16) for i in (0, 2, 4))


SKINS = {name: {k: rgb(v) for k, v in re.findall(r'\["([0-9A-F]{6})"\] = "([0-9A-F]{6})"', body)}
         for name, body in re.findall(r"\n\t(\w+) = \{[^\n]*\n(.*?)\n\t\},", SRC, re.S)}
GLOW = {name: (rgb(col), re.findall(r'"(\w+)"', names))
        for name, col, names in re.findall(r'\t(\w+) = \{ color = "([0-9A-F]{6})", names = \{([^}]*)\}', SRC)}
# The Halloween bosses (Shared/Bosses): kind -> the model it's drawn from
BOSSES = {"GiantPumpkin": "halloween/GiantPumpkin", "GiantSoulHorse": "godlands/SoulHorse", "GiantGrimReaper": "halloween/GrimReaper"}
BASE = dict(re.findall(r'(Halloween\w+) = "(\w+)",', SRC))


def hexof(c):
    return "%02X%02X%02X" % tuple(int(v) for v in c)


def recolor(kind, parts):
    swap = SKINS.get(kind, {})
    col, names = GLOW.get(kind, (None, []))
    for p in parts:
        to = swap.get(hexof(p.color))
        if to:
            p.color = to
        if any(n in p.name for n in names):
            p.color, p.neon, p.plain = col, True, True
    return parts


def luau_colors(path):
    return {"%02X%02X%02X" % tuple(map(int, m)) for m in re.findall(r"fromRGB\((\d+), (\d+), (\d+)\)", open(path).read())}


def check():
    for kind, base in BASE.items():
        model = os.path.join(ROOT, "src", "shared", "Bosses" if base == "Seraph" else "Animals", base + "Model.luau")
        cols = luau_colors(model) | luau_colors(os.path.join(ROOT, "src", "shared", "Eggs", base + "EggModel.luau"))
        unused = [c for c in SKINS[kind] if c not in cols]
        assert not unused, (kind, unused)
        print(kind, "keeps", sorted(c for c in cols if c not in SKINS[kind]))


# pet_headshots draws a giga rare as its base, recoloured (and a boss as its model)
for kind, path in BOSSES.items():
    P.MODELS[kind] = path
    if path.startswith("halloween"):
        P.ZYX.add(kind)
for kind, base in BASE.items():
    P.MODELS[kind] = P.MODELS[base]
    if base in P.ZYX:
        P.ZYX.add(kind)
    if base in P.FACING:
        P.FACING[kind] = P.FACING[base]
    if base in P.ACTION_IDLE:
        P.ACTION_IDLE.add(kind)
_parts_of = P.parts_of
P.parts_of = lambda kind, model, pose=None: recolor(kind, _parts_of(kind, model, pose)) if kind in SKINS or kind in BOSSES else _parts_of(kind, model, pose)


def lineup(kinds=None, name="Giga_lineup.png", cols=5):
    kinds = kinds or list(BASE)
    tile = 420
    out = Image.new("RGB", (tile * cols, tile * -(-len(kinds) // cols)), (238, 240, 236))
    for i, kind in enumerate(kinds):
        im = P.shot(kind, "hero", size=tile - 20)
        out.paste(im, ((i % cols) * tile + 10, (i // cols) * tile + 10), im)
        ImageDraw.Draw(out).text(((i % cols) * tile + 14, (i // cols) * tile + 8), re.sub(r"(\w)([A-Z])", r"\1 \2", kind),
                                 fill=(40, 30, 50), font=FONT)
    path = os.path.join(OUT, "renders", name)
    out.save(path)
    print(path)


def eggs():
    os.makedirs(os.path.join(OUT, "eggs"), exist_ok=True)
    sheet = Image.new("RGB", (300 * len(BASE), 420), (238, 240, 236))
    for i, (kind, base) in enumerate(BASE.items()):
        HR.EULER = "XYZ"
        model = json.load(open(os.path.join(ROOT, "designs", "eggs", "c_style", base + "Egg.bbmodel")))
        parts = S.posed(model, None, 0.0)
        for p in parts:
            p.neon = p.name.startswith(P.NEON)
            p.plain = p.plain or p.neon or p.name.startswith(P.PLAIN + P.SMOOTH)
        recolor(kind, parts)
        im = render(parts, W=700, H=1100, fov=28, transparent=True, **C.VIEWS[0])
        im = im.crop(im.getbbox())
        im.save(os.path.join(ROOT, "assets", "ui", kind + "EggRender.png"))
        t = im.copy()
        t.thumbnail((280, 400))
        sheet.paste(t, (i * 300 + (300 - t.width) // 2, 10), t)
    sheet.save(os.path.join(OUT, "eggs", "Giga_eggs.png"))


if __name__ == "__main__":
    a = sys.argv[1:]
    if a and a[0] == "headshots":
        P.main(list(BASE))
    elif a and a[0] == "bosses":
        lineup(list(BOSSES), "Bosses_lineup.png", 3)
    elif a and a[0] == "eggs":
        eggs()
    else:
        check()
        lineup()
