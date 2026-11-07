"""Egg pictures for every World 1 animal (QM, Nov 7: "we need eggs for all animals, some currently
don't have any; alpha pets' eggs can just be reskins").

Renders each egg straight from its src/shared/Eggs/<Kind>EggModel.luau (the same front view and
crop as tools/ocean_eggs.py), so it works for eggs whose design lives elsewhere (Fight to Steal an
Egg's tools/later_eggs.py). The alphas' eggs are their base's egg recoloured (ALPHAS below):
written as src/shared/Eggs/<Alpha>EggModel.luau.

    python3 tools/egg_icons.py              alpha egg models + assets/ui/<Kind>EggRender.png for MISSING
    python3 tools/egg_icons.py Kind ...     just those

Then upload the renders on the Mac with Studio open (tools/studio/imgup.py) and put the ids in
Config.EggIcons.
"""

import colorsys
import os
import re
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
from partlib import Part, render  # noqa: E402

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
EGGS = os.path.join(ROOT, "src", "shared", "Eggs")
UI = os.path.join(ROOT, "assets", "ui")
PREVIEW = "/mnt/project-files/animals/eggs"
VIEW = dict(eye=(-3.5, 4.6, -10.5), target=(0, 2.05, 0))  # tools/horse_egg_takes.py VIEWS[0]

LINE = re.compile(r'^(\s*\{ name = "([^"]+)".*color = Color3\.fromRGB\()([0-9, ]+)(\).*)$')
PART = re.compile(r'class = "(\w+)", size = Vector3\.new\(([^)]*)\), cframe = CFrame\.new\(([^)]*)\), color = Color3\.fromRGB\(([^)]*)\)')


def hsv(fn):
    """A recolour from a function of (h, s, v) in 0..1."""
    def f(rgb):
        h, s, v = colorsys.rgb_to_hsv(*(c / 255 for c in rgb))
        return tuple(int(round(max(0, min(1, c)) * 255)) for c in colorsys.hsv_to_rgb(*fn(h, s, v)))
    return f


def tint(rgb_to, keep_light=0.0):
    """Everything in one hue (rgb_to's), by its brightness; whites stay pale if keep_light."""
    th, ts, _ = colorsys.rgb_to_hsv(*(c / 255 for c in rgb_to))
    return hsv(lambda h, s, v: (th, ts * (1 - keep_light * max(0, v - s) ** 2), v))


def hue_shift(frm, to, width=0.12):
    """Hues near frm (0..360) moved to to; the rest as they were."""
    a, b = frm / 360, to / 360

    def fn(h, s, v):
        d = (h - a + 0.5) % 1 - 0.5
        if abs(d) < width and s > 0.15:
            return ((b + d) % 1, s, v)
        return (h, s, v)
    return hsv(fn)


# alpha: (base, recolour) - in the spirit of their animals (tools/alpha_skins.py, tools/alpha_designs.py)
ALPHAS = {
    "GoldenPig": ("Pig", tint((240, 190, 40), keep_light=0.6)),  # gold
    "AlphaFish": ("Fish", hue_shift(215, 45, 0.15)),  # yellow instead of blue
    "AlphaRhino": ("Rhino", hsv(lambda h, s, v: (0.0, max(s, 0.3), v * 0.9))),  # tinted red
    "EmperorScorpion": ("Scorpion", hsv(lambda h, s, v: (0.72, s * 0.5 + 0.15, v * 0.38))),  # dark scales
    "AlphaSpineLizard": ("SpineLizard", hsv(lambda h, s, v: (h, s, v * 0.62))),  # darker
    "AlphaSnake": ("Snake", hue_shift(190, 120, 0.12)),  # green instead of blue
    "AlphaSandworm": ("Sandworm", hsv(lambda h, s, v: (h, s * 0.45, min(1, v * 1.05)))),  # faded sand
    "AlphaBoar": ("Boar", hsv(lambda h, s, v: (h, s, v * 0.55))),  # the Elder Boar: dark
    "AlphaIceGolem": ("IceGolem", hue_shift(205, 44, 0.14)),  # yellow instead of blue
    "AlphaIcebringer": ("Icebringer", hsv(lambda h, s, v: (0.6, max(s, 0.55), v * 0.85))),  # deep glowing blue
    "AlphaRockHog": ("RockHog", hsv(lambda h, s, v: (0.05 + 0.06 * v, 0.9, 0.35 + 0.65 * v))),  # molten
    "AlphaLavaWhale": ("LavaWhale", hsv(lambda h, s, v: (h, s, v) if s > 0.75 and v > 0.85 else (0.75, s * 0.4, v * 0.32))),  # obsidian, lava glow kept
    "AlphaPhoenix": ("Phoenix", hsv(lambda h, s, v: (0.63 - min(h, 0.17) * 0.8 if (h < 0.2 or h > 0.9) else h, s, v))),  # blue fire
}

# World 1 eggs with no picture in Config.EggIcons (Nov 7), alphas last
MISSING = [
    "AbyssPillbug", "AbyssWhale", "AncientMoose", "Anglerfish", "ArmoredRam", "AshBehemoth", "BoneSteed", "BoneWyrm",
    "BrownBear", "CaveCricket", "CaveSpider", "ChessKnight", "Coyote", "CrimsonDrake", "CryptSnail", "CrystalTortoise",
    "Deer", "DungeonRat", "Elephant", "FireAnt", "FortressTortoise", "Gecko", "Giraffe", "GlacierMammoth", "Griffin",
    "Hammerhead", "HillbackTortoise", "LivingArmor", "MagmaCrab", "MantaRay", "Mimic", "MirageElephant", "MysticOwl",
    "Narwhal", "Oryx", "Ostrich", "Pelican", "Rat", "Reindeer", "RoyalEagle", "RoyalPeacock", "RoyalStag", "RoyalSteed",
    "Seahorse", "Seal", "Shrimp", "Shroom", "Slime", "Snail", "SpiritDeer", "SpiritFox", "SpiritLoong", "StagBeetle",
    "Swan", "Walrus", "WarBoar", "WebSpider", "Zebra",
] + list(ALPHAS)


def nums(s):
    return [float(x) for x in s.split(",")]


def load(kind):
    parts = []
    for line in open(os.path.join(EGGS, kind + "EggModel.luau")):
        m = PART.search(line)
        if not m:
            continue
        cls, size, cf, col = m.groups()
        c = nums(cf)
        M = np.eye(4)
        M[:3, 3] = c[:3]
        if len(c) == 12:
            M[:3, :3] = np.array(c[3:]).reshape(3, 3)
        parts.append(Part("p", nums(size), M, tuple(int(x) for x in nums(col)),
                          "Wedge" if cls == "WedgePart" else "Block"))
    return parts


def recolour(alpha):
    base, fn = ALPHAS[alpha]
    out = [f"-- GENERATED by tools/egg_icons.py: the {base}'s egg ({base}EggModel) recoloured for the {alpha}."
           " Don't edit by hand."]
    for line in open(os.path.join(EGGS, base + "EggModel.luau")).read().split("\n"):
        m = LINE.match(line)
        if m:
            head, _, rgb, tail = m.groups()
            line = head + ", ".join(str(c) for c in fn(tuple(int(x) for x in nums(rgb)))) + tail
        out.append(line)
    open(os.path.join(EGGS, alpha + "EggModel.luau"), "w").write("\n".join(out))


def picture(kind):
    im = render(load(kind), W=700, H=1100, fov=28, transparent=True, **VIEW)
    im = im.crop(im.getbbox())
    im.save(os.path.join(UI, kind + "EggRender.png"))
    return im


def main(*kinds):
    kinds = kinds or MISSING
    os.makedirs(PREVIEW, exist_ok=True)
    for a in ALPHAS:
        if a in kinds:
            recolour(a)
    ims = []
    for k in kinds:
        ims.append((k, picture(k)))
        print(k)
    # a contact sheet, alphas next to their bases
    from animal_designs import font
    from PIL import ImageDraw
    tile, cols = 200, 10
    sheet = Image.new("RGB", (tile * cols, tile * ((len(ims) + cols - 1) // cols)), (255, 255, 255))
    d = ImageDraw.Draw(sheet)
    for i, (k, im) in enumerate(ims):
        im = im.copy()
        im.thumbnail((tile - 20, tile - 40))
        x, y = (i % cols) * tile, (i // cols) * tile
        sheet.paste(im, (x + (tile - im.width) // 2, y + 28), im)
        d.text((x + 6, y + 6), k, fill=(20, 20, 20), font=font(13))
    sheet.save(os.path.join(PREVIEW, "all.png"))
    if any(a in kinds for a in ALPHAS):
        al = [a for a in ALPHAS if a in kinds]
        s2 = Image.new("RGB", (tile * len(al), tile * 2), (255, 255, 255))
        d = ImageDraw.Draw(s2)
        for i, a in enumerate(al):
            for r, k in enumerate((ALPHAS[a][0], a)):
                im = Image.open(os.path.join(UI, k + "EggRender.png")) if r == 0 else dict(ims)[a]
                im = im.copy()
                im.thumbnail((tile - 20, tile - 40))
                s2.paste(im, (i * tile + (tile - im.width) // 2, r * tile + 28), im)
                d.text((i * tile + 6, r * tile + 6), k, fill=(20, 20, 20), font=font(13))
        s2.save(os.path.join(PREVIEW, "alphas.png"))
    print("wrote", PREVIEW)


if __name__ == "__main__":
    main(*sys.argv[1:])
