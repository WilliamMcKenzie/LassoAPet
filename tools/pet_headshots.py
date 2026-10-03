"""Pets panel headshots (assets/ui/Pet<Kind>.png, 512x512, transparent) for every pet,
rendered from each animal's .bbmodel the way the game builds it: no outlines (QM,
Oct 3: "no outline", "include the animal's entire body"), eyes and other plain
parts without studs, Glow parts lit flat like Neon.

Run from the repo root:
  python3 tools/pet_headshots.py options [Kind ...]   style sheet to pick from
  python3 tools/pet_headshots.py [--style NAME] [Kind ...]   write the headshots

The selected-animal card shows the image mirrored, so either facing works.
"""

import json
import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(__file__))
import horse_rig as HR  # noqa: E402
import snake_design as S  # noqa: E402
from bbmodel_to_luau import NEON, PLAIN  # noqa: E402
from partlib import render  # noqa: E402

ROOT = os.path.join(os.path.dirname(__file__), "..")
OUT = os.path.join(ROOT, "assets", "ui")
PREVIEW = "/mnt/project-files/animals/headshots"

MODELS = {
    "Horse": "horses/Horse9_Leap", "Pinto": "horses/Pinto", "Pig": "animals/Pig", "Fish": "animals/Fish",
    "Rhino": "animals/Rhino", "Unicorn": "animals/Unicorn",
    "Cactus": "desert/Cactus", "Scorpion": "desert/Scorpion", "Sandworm": "desert/Sandworm",
    "SpineLizard": "converted/SpineLizard", "Snake": "desert/Snake",
    "Penguin": "snow/Penguin", "Boar": "converted/Boar", "Snowman": "snow/Snowman",
    "IceGolem": "converted/IceGolem", "Icebringer": "converted/Icebringer",
    "Starfish": "ocean/Starfish", "Whale": "ocean/Whale", "Squid": "ocean/Squid",
    "KingCrab": "ocean/KingCrab", "Kraken": "ocean/Kraken",
}
ZYX = {"KingCrab", "IceGolem"}  # converted with --zyx (QM's hand-made multi-axis rotations)
FACING = {"Kraken": 180}
# Animals whose run makes a poor picture (the Snake stretches out thin, the Starfish
# folds its arms up) keep their idle stance in the action style.
ACTION_IDLE = {"Snake", "Starfish"}  # degrees the face is turned from -z (the Kraken's eye faces its rider)

# Camera styles: yaw (degrees round from the front, + toward the animal's left),
# pitch (degrees above level), field of view, and the pose (animation, time as a
# fraction of its length; None = rest). The idle's first frame is each animal's
# natural stance (the Snake reared and coiled, rather than lying straight).
STYLES = {
    "hero": dict(yaw=35, pitch=8, fov=26, pose=("idle", 0.0), label="A  hero: 3/4 front, low, looking up a little"),
    "classic": dict(yaw=40, pitch=24, fov=26, pose=("idle", 0.0), label="B  classic: 3/4 front from above"),
    "profile": dict(yaw=90, pitch=10, fov=26, pose=("idle", 0.0), label="C  side profile"),
    "action": dict(yaw=35, pitch=12, fov=26, pose=("gallop", 0.35), label="D  action: 3/4 front, mid-run"),
}


def load(kind):
    return json.load(open(os.path.join(ROOT, "designs", MODELS[kind] + ".bbmodel")))


def parts_of(kind, model, pose=None):
    HR.EULER = "ZYX" if kind in ZYX else "XYZ"
    anim = None
    t = 0.0
    if pose:
        anim = next((a for a in model.get("animations", []) if a["name"] == pose[0]), None)
        if anim:
            t = anim["length"] * pose[1]
    parts = S.posed(model, anim, t)
    for p in parts:
        p.neon = p.name.startswith(NEON)
        p.plain = p.plain or p.neon or p.name.startswith(PLAIN) or "In" in p.name
    return parts


def shot(kind, style, size=512, pad=0.04):
    st = STYLES[style]
    model = load(kind)
    pose = st["pose"]
    if style == "action" and kind in ACTION_IDLE:
        pose = ("idle", 0.0)
    parts = parts_of(kind, model, pose)
    pts = np.concatenate([q for p in parts for q in p.polys])
    lo, hi = pts.min(0), pts.max(0)
    c = (lo + hi) / 2
    radius = np.linalg.norm(hi - lo) / 2
    yaw, pitch = math.radians(st["yaw"] + FACING.get(kind, 0)), math.radians(st["pitch"])
    # the front is -z; yaw turns the camera round toward the animal's left (-x)
    d = np.array([-math.sin(yaw) * math.cos(pitch), math.sin(pitch), -math.cos(yaw) * math.cos(pitch)])
    dist = radius / math.sin(math.radians(st["fov"]) / 2) * 1.05
    R = 1024
    im = render(parts, eye=c + d * dist, target=c, W=R, H=R, fov=st["fov"], transparent=True, outline=False)
    im = im.crop(im.getbbox())
    side = int(max(im.size) * (1 + 2 * pad))
    sq = Image.new("RGBA", (side, side))
    sq.paste(im, ((side - im.width) // 2, (side - im.height) // 2))
    return sq.resize((size, size), Image.LANCZOS)


def options(kinds):
    """A sheet: one row per style, one column per animal, on a card-like backdrop."""
    tile = 300
    W, H = tile * len(kinds), (tile + 34) * len(STYLES)
    sheet = Image.new("RGB", (W, H), (255, 255, 255))
    draw = ImageDraw.Draw(sheet)
    for r, style in enumerate(STYLES):
        y = r * (tile + 34)
        draw.text((10, y + 8), STYLES[style]["label"], fill=(20, 20, 20))
        for k, kind in enumerate(kinds):
            bg = Image.new("RGBA", (tile, tile), (70, 150, 230, 255))
            im = shot(kind, style, tile - 20)
            bg.alpha_composite(im, (10, 10))
            sheet.paste(bg.convert("RGB"), (k * tile, y + 34))
    os.makedirs(PREVIEW, exist_ok=True)
    path = os.path.join(PREVIEW, "headshot_options.png")
    sheet.save(path)
    print("wrote", path)


def main(args):
    style = "hero"
    if "--style" in args:
        i = args.index("--style")
        style = args[i + 1]
        args = args[:i] + args[i + 2:]
    kinds = args or list(MODELS)
    os.makedirs(PREVIEW, exist_ok=True)
    for kind in kinds:
        im = shot(kind, style)
        im.save(os.path.join(OUT, f"Pet{kind}.png"))
        print("wrote", f"Pet{kind}.png")
    # a contact sheet of them all, for a quick look
    tile = 200
    cols = 7
    rows = math.ceil(len(kinds) / cols)
    sheet = Image.new("RGB", (tile * cols, tile * rows), (70, 150, 230))
    for i, kind in enumerate(kinds):
        im = Image.open(os.path.join(OUT, f"Pet{kind}.png")).resize((tile - 10, tile - 10), Image.LANCZOS)
        sheet.paste(im, ((i % cols) * tile + 5, (i // cols) * tile + 5), im)
    sheet.save(os.path.join(PREVIEW, "headshots_all.png"))


if __name__ == "__main__":
    a = sys.argv[1:]
    if a and a[0] == "options":
        options(a[1:] or ["Horse", "Kraken"])
    else:
        main(a)
