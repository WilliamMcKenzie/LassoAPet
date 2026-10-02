"""Eggs for the ocean pets, in take C's style (tools/snow_eggs.py): the octo shell,
a coloured base, bold markings and each animal's own feature.

  Kraken  Legendary  navy with a dark band, the maroon cap over the top with darker
                     spots, eight banded tentacles splayed round the base, pink tips
                     curling up
  Squid   Epic       the Kraken's egg in the Squid's pink and orange
  Whale   Rare       blue over a pale ridged base, a cyan spiral glyph on the front,
                     cyan dashes down the top, little flukes at the back
  KingCrab Epic      red over a pale underside, gold spikes, a big claw and a small one, little legs

Run from the repo root: python3 tools/ocean_eggs.py [Kind ...]
Writes designs/eggs/c_style/<Kind>Egg.bbmodel, src/shared/Eggs/<Kind>EggModel.luau,
assets/ui/<Kind>EggRender.png (cropped, for the reveal card) and previews in
/mnt/project-files/eggs/c_style/ocean/.
"""

import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import egg_designs as E  # noqa: E402
import horse_egg_takes as C  # noqa: E402
from horse_egg_takes import LH, WIDTHS, shell  # noqa: E402
from partlib import Part, T, Ry, render  # noqa: E402
import bbmodel_to_luau  # noqa: E402

ROOT = os.path.join(os.path.dirname(__file__), "..")


KRAKEN = ((58, 76, 128), (40, 52, 94), (146, 46, 60), (104, 30, 46), (238, 122, 152))
SQUID = ((255, 150, 160), (236, 112, 132), (255, 138, 72), (226, 100, 50), (255, 214, 120))  # tools/squid_design.py


def kraken_egg(colors=KRAKEN):
    navy, band, cap, capdark, pink = colors
    egg = shell([navy, band, navy, band, cap, cap, cap])
    # darker spots standing out of the cap, front, sides and back
    for i, (layer, x, w) in enumerate(((4, -0.45, 0.5), (5, 0.3, 0.4), (4, 0.55, 0.36))):
        z = WIDTHS[layer] / 2
        y = layer * LH + 0.08
        egg.block(f"SpotF{i}", (x - w / 2, y, -z - 0.06), (x + w / 2, y + LH - 0.16, -z + 0.05), capdark)
        egg.block(f"SpotB{i}", (-x - w / 2, y, z - 0.05), (-x + w / 2, y + LH - 0.16, z + 0.06), capdark)
        egg.block(f"SpotS{i}", (z - 0.05 if i % 2 else -z - 0.06, y, x - w / 2), (z + 0.06 if i % 2 else -z + 0.05, y + LH - 0.16, x + w / 2), capdark)
    egg.block("CapTop", (-0.3, 7 * LH - 0.02, -0.3), (0.3, 7 * LH + 0.12, 0.3), cap)
    # eight tentacles round the base: out along the floor, then curling up to a pink tip
    for k in range(8):
        frame = Ry(22.5 + 45 * k)
        r0, r1, w = WIDTHS[0] / 2 - 0.15, WIDTHS[1] / 2 + 0.45, 0.34
        for name, lo, hi, col in ((f"Tentacle{k}", (-w / 2, 0, -r1), (w / 2, 0.3, -r0), navy if k % 2 else band),
                                  (f"Curl{k}", (-w / 2 + 0.03, 0, -r1 - 0.28), (w / 2 - 0.03, 0.5, -r1 + 0.02), band if k % 2 else navy),
                                  (f"Tip{k}", (-w / 2 + 0.06, 0.5, -r1 - 0.25), (w / 2 - 0.06, 0.64, -r1 - 0.01), pink)):
            mid = [(a + b) / 2 for a, b in zip(lo, hi)]
            p = Part(name, [b - a for a, b in zip(lo, hi)], frame @ T(*mid), col)
            p.bone = "bottom"
            p.yaw = 22.5 + 45 * k
            egg.parts.append(p)
    return egg


def king_crab_egg():
    """Red over a pale underside, gold spikes down the back, a big claw on the right and a
    small one on the left (as on QM's crab), two little legs each side at the base."""
    from desert_eggs import fin
    shell_red, under, gold, dark, leg = (226, 58, 48), (252, 196, 150), (255, 196, 64), (160, 32, 40), (232, 70, 52)
    egg = shell([under, under, shell_red, shell_red, shell_red, shell_red, shell_red])
    for i in (2, 3, 4, 5):
        fin(egg, f"Spike{i}", i * LH + 0.05, (i + 1) * LH + 0.05, 0.36 if i % 2 else 0.24, 0.12, gold)
    for side, sx, big in (("L", -1, 0.8), ("R", 1, 1.0)):
        a = WIDTHS[2] / 2
        y = 2 * LH
        X = lambda a0, a1, sx=sx: sorted((sx * a0, sx * a1))
        x0, x1 = X(a - 0.05, a + 0.25)
        egg.block("Arm" + side, (x0, y + 0.05, -0.35), (x1, y + 0.35, -0.05), leg)
        h = 0.55 * big
        x0, x1 = X(a + 0.1, a + 0.1 + 0.5 * big)
        egg.block("Claw" + side, (x0, y - 0.05, -0.35 - 0.6 * big), (x1, y - 0.05 + h, -0.35), shell_red)
        x0, x1 = X(a + 0.14, a + 0.1 + 0.5 * big - 0.04)
        egg.block("PincerTop" + side, (x0, y + h * 0.5, -0.35 - 0.6 * big - 0.35 * big), (x1, y - 0.05 + h, -0.35 - 0.6 * big), dark)
        egg.block("PincerBottom" + side, (x0, y - 0.05, -0.35 - 0.6 * big - 0.25 * big), (x1, y + h * 0.3, -0.35 - 0.6 * big), dark)
        for k, z in enumerate((-0.05, 0.4)):
            x0, x1 = X(WIDTHS[1] / 2 - 0.1, WIDTHS[1] / 2 + 0.25)
            egg.block(f"Leg{side}{k}", (x0, 0.3, z - 0.12), (x1, 0.52, z + 0.12), leg)
            x0, x1 = X(WIDTHS[1] / 2 + 0.1, WIDTHS[1] / 2 + 0.3)
            egg.block(f"Foot{side}{k}", (x0, 0, z - 0.1), (x1, 0.3, z + 0.1), dark)
    return egg


def build(egg, name, out):
    """C.build, but blocks turned about Y (p.yaw) go in as cubes with a Blockbench
    rotation: the converter only takes axis-aligned boxes or wedge meshes."""
    import json
    turned = [p for p in egg.parts if getattr(p, "yaw", None) is not None]
    keep = {id(p): p.cf for p in turned}
    for p in turned:
        p.cf = T(*p.cf[:3, 3])
    C.build(egg, name, E.SPLIT, out)
    for p in turned:
        p.cf = keep[id(p)]
    path = os.path.join(out, name + ".bbmodel")
    m = json.load(open(path))
    yaw = {p.name: p.yaw for p in turned}
    for e in m["elements"]:
        if e["name"] in yaw:
            e["rotation"] = [0, yaw[e["name"]], 0]
    with open(path, "w") as f:
        json.dump(m, f, separators=(",", ":"))


def whale_egg():
    blue, deep, cyan, belly, groove = (40, 116, 206), (26, 78, 158), (96, 226, 246), (214, 244, 250), (150, 210, 232)
    egg = shell([belly, belly, blue, blue, blue, blue, deep])  # tools/whale_design.py colours
    # grooves up the pale base, all the way round
    for k in range(4):
        for i, (layer, x) in enumerate((l, x) for l in (0, 1) for x in (-0.45, 0.0, 0.45)):
            z = WIDTHS[layer] / 2
            lo, hi = (x - 0.08, layer * LH + 0.08, -z - 0.06), (x + 0.08, (layer + 1) * LH - 0.08, -z + 0.04)
            p = Part(f"Groove{k}{i}", [b - a for a, b in zip(lo, hi)], Ry(90 * k) @ T(*[(a + b) / 2 for a, b in zip(lo, hi)]), groove)
            p.bone = "bottom"
            p.yaw = 90 * k
            egg.parts.append(p)
    # the spiral glyph on the front, a square spiral in raised cyan blocks
    z = WIDTHS[3] / 2
    y0 = 2 * LH + 0.15
    px = 0.14
    for r, row in enumerate(("11111", "10001", "10101", "10111")):
        for c, on in enumerate(row):
            if on == "1":
                x = (c - 2) * px
                y = y0 + (3 - r) * px
                egg.block(f"Glyph{r}{c}", (x - px / 2, y, -z - 0.06), (x + px / 2, y + px, -z + 0.04), cyan)
    # cyan dashes down the top, front to back
    top = 7 * LH
    for i, zz in enumerate((-0.32, 0.0, 0.32)):
        egg.block(f"Dash{i}", (-0.12, top - 0.02, zz - 0.08), (0.12, top + 0.1, zz + 0.08), cyan)
    # little flukes sticking out of the back, low down
    zb = WIDTHS[2] / 2
    egg.block("FlukeRoot", (-0.18, 2 * LH + 0.1, zb - 0.05), (0.18, 2 * LH + 0.4, zb + 0.3), blue)
    for sx in (-1, 1):
        egg.block(f"Fluke{'LR'[sx > 0]}", (min(sx * 0.15, sx * 0.62), 2 * LH + 0.18, zb + 0.18),
                  (max(sx * 0.15, sx * 0.62), 2 * LH + 0.34, zb + 0.46), deep)
    return egg


EGGS = [("Kraken", kraken_egg), ("Squid", lambda: kraken_egg(SQUID)), ("Whale", whale_egg),
        ("KingCrab", king_crab_egg)]


def main(*kinds, preview="/mnt/project-files/eggs/c_style/ocean"):
    os.makedirs(os.path.join(preview, "renders"), exist_ok=True)
    bb_dir = os.path.join(ROOT, "designs", "eggs", "c_style")
    for kind, fn in EGGS:
        if kinds and kind not in kinds:
            continue
        egg = fn()
        name = kind + "Egg"
        build(egg, name, bb_dir)
        build(egg, name, preview)
        bbmodel_to_luau.main(os.path.join("designs", "eggs", "c_style", name + ".bbmodel"),
                             os.path.join(ROOT, "src", "shared", "Eggs", name + "Model.luau"))
        tile = 420
        sheet = Image.new("RGB", (tile * 2, tile))
        for r, view in enumerate(C.VIEWS):
            sheet.paste(render(egg.parts, W=tile, H=tile, fov=28, **view), (r * tile, 0))
        sheet.save(os.path.join(preview, name + ".png"))
        im = render(egg.parts, W=700, H=1100, fov=28, transparent=True, **C.VIEWS[0])
        im = im.crop(im.getbbox())
        im.save(os.path.join(ROOT, "assets", "ui", kind + "EggRender.png"))
        padded = Image.new("RGBA", (im.width + 16, im.height + 16))
        padded.paste(im, (8, 8))
        padded.save(os.path.join(preview, "renders", name + ".png"))
        print(kind, len(egg.parts), "parts, render", im.size)


if __name__ == "__main__":
    main(*sys.argv[1:])
