"""Pets panel headshots (assets/ui/Pet<Kind>.png, 512x512, transparent) for every pet,
rendered from each animal's .bbmodel the way the game builds it: no outlines (QM,
Oct 3: "no outline", "include the animal's entire body"), eyes and other plain
parts without studs, Glow parts lit flat like Neon.

Run from the repo root:
  python3 tools/pet_headshots.py options [Kind ...]   style sheet to pick from
  python3 tools/pet_headshots.py [--style NAME] [Kind ...]   write the headshots
  python3 tools/pet_headshots.py gif [Kind ...]   one looping GIF of each pet's run, from the
                                                  action headshot's camera

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
    "Horse": "horses/Horse9_Leap", "Pinto": "horses/Pinto", "Pig": "animals/Pig", "Bunny": "animals/Bunny", "Fish": "animals/Fish",
    "Rhino": "animals/Rhino", "Unicorn": "animals/Unicorn",
    "Cactus": "desert/Cactus", "Kitten": "desert/Kitten", "Scorpion": "desert/Scorpion", "Sandworm": "desert/Sandworm",
    "SpineLizard": "converted/SpineLizard", "Snake": "desert/Snake",
    "Penguin": "snow/Penguin", "Boar": "converted/Boar", "Snowman": "snow/Snowman",
    "IceGolem": "converted/IceGolem", "Icebringer": "converted/Icebringer", "SnackYak": "snow/SnackYak",
    "Starfish": "ocean/Starfish", "Whale": "ocean/Whale", "Squid": "ocean/Squid",
    "KingCrab": "ocean/KingCrab", "BlueCrab": "ocean/BlueCrab", "RoboShark": "ocean/RoboShark", "Kraken": "ocean/Kraken", "FishSchool": "ocean/FishSchool",
    "Loong": "godlands/Loong", "WarElephant": "godlands/WarElephant", "SoulHorse": "godlands/SoulHorse",
    "Sludge": "sludge/Sludge",
    "Beholder": "beholder/Beholder",
    "Leviathan": "leviathan/Leviathan",
    "VolcanoTortoise": "volcano/VolcanoTortoise",
}
ZYX = {"KingCrab", "BlueCrab", "RoboShark", "IceGolem", "SnackYak", "Loong", "WarElephant", "VolcanoTortoise"}  # converted with --zyx (QM's hand-made multi-axis rotations)
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


def camera(kind, st, parts):
    """Eye and target framing these parts whole from the style's angle."""
    pts = np.concatenate([q for p in parts for q in p.polys])
    lo, hi = pts.min(0), pts.max(0)
    c = (lo + hi) / 2
    radius = np.linalg.norm(hi - lo) / 2
    yaw, pitch = math.radians(st["yaw"] + FACING.get(kind, 0)), math.radians(st["pitch"])
    # the front is -z; yaw turns the camera round toward the animal's left (-x)
    d = np.array([-math.sin(yaw) * math.cos(pitch), math.sin(pitch), -math.cos(yaw) * math.cos(pitch)])
    dist = radius / math.sin(math.radians(st["fov"]) / 2) * 1.05
    return c + d * dist, c


def shot(kind, style, size=512, pad=0.04):
    st = STYLES[style]
    model = load(kind)
    pose = st["pose"]
    if style == "action" and kind in ACTION_IDLE:
        pose = ("idle", 0.0)
    parts = parts_of(kind, model, pose)
    eye, target = camera(kind, st, parts)
    R = 1024
    im = render(parts, eye=eye, target=target, W=R, H=R, fov=st["fov"], transparent=True, outline=False)
    im = im.crop(im.getbbox())
    side = int(max(im.size) * (1 + 2 * pad))
    sq = Image.new("RGBA", (side, side))
    sq.paste(im, ((side - im.width) // 2, (side - im.height) // 2))
    return sq.resize((size, size), Image.LANCZOS)


def frame_count(length):
    """24 frames, or more/fewer so each lasts 30-60 ms: GIF times are whole hundredths
    and browsers slow anything under 20 ms right down."""
    ms = length * 1000 / 24
    if ms < 30:
        return max(12, round(length * 1000 / 30))
    if ms > 60:
        return min(48, round(length * 1000 / 50))
    return 24


def loop(kind, frames=None, size=512, pad=0.04, style="action"):
    """One loop of the animation the action headshot is taken from (the run, or the
    idle for ACTION_IDLE pets), from the headshot's exact camera: the eye and target
    are the headshot's, and every frame shares one crop so the animal moves within it
    rather than the picture jumping. Returns RGBA frames and the frame time in ms."""
    st = STYLES[style]
    model = load(kind)
    name = "idle" if kind in ACTION_IDLE else st["pose"][0]
    anim = next(a for a in model["animations"] if a["name"] == name)
    frames = frames or frame_count(anim["length"])
    start = 0.0 if kind in ACTION_IDLE else st["pose"][1]  # the first frame is the headshot
    eye, target = camera(kind, st, parts_of(kind, model, (name, start)))
    R = 1024
    ims = []
    for i in range(frames):
        parts = parts_of(kind, model, (name, (start + i / frames) % 1))
        ims.append(render(parts, eye=eye, target=target, W=R, H=R, fov=st["fov"], transparent=True, outline=False))
    boxes = np.array([im.getbbox() for im in ims])
    box = (*boxes[:, :2].min(0), *boxes[:, 2:].max(0))
    w, h = box[2] - box[0], box[3] - box[1]
    side = int(max(w, h) * (1 + 2 * pad))
    out = []
    for im in ims:
        sq = Image.new("RGBA", (side, side))
        sq.paste(im.crop(box), ((side - w) // 2, (side - h) // 2))
        out.append(sq.resize((size, size), Image.LANCZOS))
    return out, max(20, round(anim["length"] * 100 / frames) * 10)


def save_gif(path, frames, ms, bg=None):
    """A looping GIF. With bg (an RGB colour) the frames sit on it; without, the GIF is
    transparent, with alpha cut at half (GIF has no soft edges)."""
    pal = []
    for im in frames:
        if bg:
            flat = Image.new("RGBA", im.size, bg + (255,))
            flat.alpha_composite(im)
            pal.append(flat.convert("RGB").convert("P", palette=Image.ADAPTIVE, colors=255))
        else:
            a = im.getchannel("A").point(lambda v: 255 if v >= 128 else 0)
            p = im.convert("RGB").convert("P", palette=Image.ADAPTIVE, colors=255)
            p.paste(255, mask=Image.eval(a, lambda v: 255 - v))
            p.info["transparency"] = 255
            pal.append(p)
    extra = {} if bg else dict(transparency=255, disposal=2)
    pal[0].save(path, save_all=True, append_images=pal[1:], duration=ms, loop=0, optimize=False, **extra)


def gifs(kinds):
    out = os.path.join(PREVIEW, "gifs")
    os.makedirs(out, exist_ok=True)
    for kind in kinds:
        frames, ms = loop(kind)
        save_gif(os.path.join(out, f"Pet{kind}.gif"), frames, ms)
        save_gif(os.path.join(out, f"Pet{kind}_card.gif"), frames, ms, bg=(255, 214, 10))
        print("wrote", f"Pet{kind}.gif", len(frames), "frames,", ms, "ms each")


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
    if a and a[0] == "gif":
        gifs(a[1:] or list(MODELS))
    elif a and a[0] == "options":
        options(a[1:] or ["Horse", "Kraken"])
    else:
        main(a)
