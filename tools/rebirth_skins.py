"""Rebirth skin drafts (QM, Oct 13): Gold, Diamond and Galaxy versions of existing
pets, rendered side by side with the normal pet. Preview only; nothing in the game
reads this yet.

How a skin is applied (the same rule the game would use at build time):
  - every part keeps its shape and studs; its colour is replaced by the skin's ramp
    picked by the part's original brightness, so dark manes stay darker than bodies
    and the animal still reads as itself
  - Eye/Pupil parts (the googly eyes) and Nostrils keep their colours
  - Glow parts stay Neon, recoloured to the skin's accent
  - Gold and Diamond add sparkle glints (a ParticleEmitter in game); Galaxy adds a
    star speckle on the body (a tiled star Texture in game, like the stud texture)

Run: python3 tools/rebirth_skins.py [Kind ...]   -> /mnt/project-files/skins/
"""

import colorsys
import math
import os
import random
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

sys.path.insert(0, os.path.dirname(__file__))
import pet_headshots as P  # noqa: E402
from partlib import render  # noqa: E402

OUT = "/mnt/project-files/skins"
KEEP = ("Eye", "Pupil", "Nostril")


def lum(c):
    r, g, b = (v / 255 for v in c)
    return 0.3 * r + 0.55 * g + 0.15 * b


def ramp(stops, t):
    t = min(max(t, 0), 1) * (len(stops) - 1)
    i = min(int(t), len(stops) - 2)
    f = t - i
    a, b = np.array(stops[i], float), np.array(stops[i + 1], float)
    return tuple(int(v) for v in a + (b - a) * f)


SKINS = {
    # dark bronze -> rich gold -> pale shine
    "Gold": dict(stops=[(120, 74, 8), (214, 150, 20), (255, 206, 52), (255, 238, 150)], span=(0.15, 0.85), glow=(255, 230, 90),
                 sparkle=(255, 250, 210), stars=0),
    # deep ice blue -> cyan -> near white, with alternate parts a facet lighter
    "Diamond": dict(stops=[(36, 118, 222), (80, 196, 250), (160, 232, 255), (232, 250, 255)], span=(0.1, 0.8), glow=(150, 240, 255),
                    sparkle=(255, 255, 255), stars=0, facet=0.18),
    # midnight navy -> violet -> magenta nebula, Neon cyan accents
    "Galaxy": dict(stops=[(18, 14, 52), (52, 28, 120), (110, 48, 170), (190, 80, 200)], span=(0.1, 0.75), glow=(90, 230, 255),
                   sparkle=None, stars=1),
}


def skinned(parts, skin):
    s = SKINS[skin]
    for i, p in enumerate(parts):
        if p.name.startswith(KEEP):
            continue
        if p.neon:
            p.color = s["glow"]
            continue
        t = lum(p.color)
        lo, hi = s["span"]
        t = lo + (hi - lo) * t  # blacks stay off the darkest stop, white bodies off the palest
        if s.get("facet") and hash(p.name) % 2:
            t += s["facet"]
        p.color = ramp(s["stops"], t)
    return parts


def mask_pass(parts):
    """Neon magenta for skinned parts, eyes as they are: where a pixel is magenta the
    skin's surface shows, so stars land on the body and never on the eyes."""
    for p in parts:
        if not p.name.startswith(KEEP):
            p.color, p.neon = (255, 0, 255), True
    return parts


def star(draw, x, y, r, col, a=255):
    """A four-point twinkle."""
    w = max(1, r / 5)
    draw.polygon([(x, y - r), (x + w, y - w), (x + r, y), (x + w, y + w), (x, y + r), (x - w, y + w), (x - r, y),
                  (x - w, y - w)], fill=col + (a,))


def frame(kind):
    st = P.STYLES["hero"]
    model = P.load(kind)
    parts = P.parts_of(kind, model, ("idle", 0.0))
    return P.camera(kind, st, parts), st, model


def shoot(kind, skin, cam, st, model, R=900):
    eye, target = cam
    parts = P.parts_of(kind, model, ("idle", 0.0))
    if skin:
        skinned(parts, skin)
    im = render(parts, eye=eye, target=target, W=R, H=R, fov=st["fov"], transparent=True, outline=False)
    if not skin:
        return im
    s = SKINS[skin]
    rnd = random.Random(hash((kind, skin)) & 0xffff)
    mask = None
    m = render(mask_pass(P.parts_of(kind, model, ("idle", 0.0))), eye=eye, target=target, W=R, H=R, fov=st["fov"],
               transparent=True, outline=False)
    a = np.asarray(m).astype(int)
    mask = (a[..., 3] > 200) & (a[..., 0] > 200) & (a[..., 1] < 90) & (a[..., 2] > 200)
    ys, xs = np.nonzero(mask)
    if s["stars"]:
        # a starfield on the surface (in game: a tiled star Texture on each part)
        layer = Image.new("RGBA", im.size)
        d = ImageDraw.Draw(layer)
        for _ in range(len(xs) // 260):
            k = rnd.randrange(len(xs))
            x, y = xs[k], ys[k]
            big = rnd.random() < 0.12
            col = rnd.choice([(255, 255, 255), (255, 255, 255), (170, 240, 255), (255, 200, 250)])
            if big:
                star(d, x, y, rnd.uniform(5, 9), col)
            else:
                rr = rnd.uniform(0.8, 2.0)
                d.ellipse([x - rr, y - rr, x + rr, y + rr], fill=col + (255,))
        # soft nebula wisps
        neb = Image.new("RGBA", im.size)
        nd = ImageDraw.Draw(neb)
        for _ in range(6):
            k = rnd.randrange(len(xs))
            rr = rnd.uniform(40, 90)
            col = rnd.choice([(255, 90, 220), (80, 200, 255), (160, 90, 255)])
            nd.ellipse([xs[k] - rr, ys[k] - rr * 0.6, xs[k] + rr, ys[k] + rr * 0.6], fill=col + (70,))
        neb = neb.filter(ImageFilter.GaussianBlur(28))
        keep = Image.fromarray((mask * 255).astype(np.uint8))
        neb.putalpha(Image.fromarray(np.minimum(np.asarray(neb)[..., 3], np.asarray(keep)).astype(np.uint8)))
        layer.putalpha(Image.fromarray(np.minimum(np.asarray(layer)[..., 3], np.asarray(keep)).astype(np.uint8)))
        im = Image.alpha_composite(Image.alpha_composite(im, neb), layer)
    if s["sparkle"]:
        # glints on the surface plus a few floating around it (a ParticleEmitter in game)
        layer = Image.new("RGBA", im.size)
        d = ImageDraw.Draw(layer)
        for _ in range(max(10, len(xs) // 9000)):
            k = rnd.randrange(len(xs))
            star(d, xs[k], ys[k], rnd.uniform(8, 18), s["sparkle"])
        bb = im.getbbox()
        for _ in range(9):
            x = rnd.uniform(bb[0] - 30, bb[2] + 30)
            y = rnd.uniform(bb[1] - 30, bb[3])
            star(d, x, y, rnd.uniform(6, 14), s["sparkle"], 230)
        glow = layer.filter(ImageFilter.GaussianBlur(4))
        im = Image.alpha_composite(Image.alpha_composite(im, glow), layer)
    return im


def sheet(kinds):
    os.makedirs(OUT, exist_ok=True)
    cols = [None, "Gold", "Diamond", "Galaxy"]
    C = 340
    head = 60
    W, H = C * len(cols), head + C * len(kinds)
    out = Image.new("RGB", (W, H), (238, 242, 248))
    d = ImageDraw.Draw(out)
    try:
        font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 28)
        small = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 20)
    except OSError:
        font = small = ImageFont.load_default()
    bgs = {None: (238, 242, 248), "Gold": (255, 246, 214), "Diamond": (224, 244, 255), "Galaxy": (34, 26, 66)}
    for j, c in enumerate(cols):
        d.rectangle([j * C, head, (j + 1) * C, H], fill=bgs[c])
        d.text((j * C + C / 2, head / 2), c or "Normal", fill=(40, 40, 60), font=font, anchor="mm")
    for i, kind in enumerate(kinds):
        cam, st, model = frame(kind)
        ims = [shoot(kind, c, cam, st, model) for c in cols]
        box = ims[0].getbbox()
        for b in ims[1:]:
            bb = b.getbbox()
            box = (min(box[0], bb[0]), min(box[1], bb[1]), max(box[2], bb[2]), max(box[3], bb[3]))
        w, h = box[2] - box[0], box[3] - box[1]
        side = int(max(w, h) * 1.08)
        for j, im in enumerate(ims):
            sq = Image.new("RGBA", (side, side))
            sq.paste(im.crop(box), ((side - w) // 2, (side - h) // 2))
            sq = sq.resize((C - 20, C - 20), Image.LANCZOS)
            out.paste(sq, (j * C + 10, head + i * C + 10), sq)
            full = Image.new("RGBA", sq.size, bgs[cols[j]] + (255,))
            Image.alpha_composite(full, sq).save(os.path.join(OUT, f"{kind}_{cols[j] or 'Normal'}.png"))
        d.text((10, head + i * C + 8), kind, fill=(200, 200, 220) if False else (90, 90, 110), font=small)
    out.save(os.path.join(OUT, "rebirth_skins_lineup.png"))
    print(os.path.join(OUT, "rebirth_skins_lineup.png"))


if __name__ == "__main__":
    sheet(sys.argv[1:] or ["Horse", "Lion", "MajesticUnicorn", "Asura"])
