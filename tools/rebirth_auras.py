"""Aura drafts for the rebirth skins (QM, Oct 13: "find good auras for each skin").
Mock-ups only: the pet in its full-body skin (tools/rebirth_skins.py) with the aura
painted round it the way the game's emitters would draw it, plus the particle
textures each aura would use (drawn here, uploaded later; capped at 1024 px).

  Gold "Midas"   : a glowing gold ring on the ground (Beam), gold glints rising off the
                   pet (ParticleEmitter, star texture), a warm PointLight
  Diamond "Prism": diamond shards orbiting the body (ParticleEmitter, shard texture,
                   swirled), white flashes, icy mist round the feet
  Galaxy "Cosmos": a nebula cloud behind the pet (ParticleEmitter, puff texture, low
                   alpha), twinkling stars round it, a tilted ring of orbiting stars

Run: python3 tools/rebirth_auras.py [Kind ...]   -> /mnt/project-files/skins/
"""

import math
import os
import random
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

sys.path.insert(0, os.path.dirname(__file__))
import rebirth_skins as RS  # noqa: E402

OUT = RS.OUT
TEX = os.path.join(os.path.dirname(__file__), "..", "assets", "particles")


# ------------------------------------------------------------ particle textures

def tex_star(n=256):
    """Four-point glint with a soft core (Gold glints, Galaxy twinkles)."""
    im = Image.new("L", (n, n))
    d = ImageDraw.Draw(im)
    c, r, w = n / 2, n / 2 - 4, n * 0.06
    d.polygon([(c, c - r), (c + w, c - w), (c + r, c), (c + w, c + w), (c, c + r), (c - w, c + w), (c - r, c), (c - w, c - w)], fill=255)
    core = Image.new("L", (n, n))
    ImageDraw.Draw(core).ellipse([c - n * 0.18, c - n * 0.18, c + n * 0.18, c + n * 0.18], fill=200)
    a = np.maximum(np.asarray(im), np.asarray(core.filter(ImageFilter.GaussianBlur(n * 0.06))))
    return Image.merge("RGBA", [Image.new("L", (n, n), 255)] * 3 + [Image.fromarray(a.astype(np.uint8))])


def tex_shard(n=256):
    """A cut diamond seen from the side: crown and pavilion facets in greys, so the
    emitter's Color tints it (Diamond shards)."""
    im = Image.new("RGBA", (n, n))
    d = ImageDraw.Draw(im)
    top, girdle, tip = n * 0.18, n * 0.4, n * 0.92
    L, R, c = n * 0.1, n * 0.9, n / 2
    tl, tr = n * 0.3, n * 0.7
    facets = [  # (polygon, grey)
        ([(tl, top), (tr, top), (c, girdle)], 255),
        ([(L, girdle), (tl, top), (c, girdle)], 225),
        ([(tr, top), (R, girdle), (c, girdle)], 200),
        ([(L, girdle), (c, girdle), (c, tip)], 235),
        ([(c, girdle), (R, girdle), (c, tip)], 175),
    ]
    for poly, g in facets:
        d.polygon(poly, fill=(g, g, g, 255))
    d.line([(L, girdle), (R, girdle)], fill=(255, 255, 255, 255), width=max(2, n // 64))
    return im


def tex_puff(n=256):
    """Soft round cloud (Galaxy nebula, Diamond mist)."""
    y, x = np.mgrid[0:n, 0:n] / (n - 1) * 2 - 1
    a = np.clip(1 - np.sqrt(x * x + y * y), 0, 1) ** 1.6 * 255
    return Image.merge("RGBA", [Image.new("L", (n, n), 255)] * 3 + [Image.fromarray(a.astype(np.uint8))])


def tex_ring(n=512):
    """Glowing ring for the ground Beam (Gold)."""
    y, x = np.mgrid[0:n, 0:n] / (n - 1) * 2 - 1
    r = np.sqrt(x * x + y * y)
    a = np.exp(-((r - 0.8) / 0.07) ** 2) * 255
    return Image.merge("RGBA", [Image.new("L", (n, n), 255)] * 3 + [Image.fromarray(a.astype(np.uint8))])


TEXTURES = {"AuraStar": tex_star, "AuraShard": tex_shard, "AuraPuff": tex_puff, "AuraRing": tex_ring}


def tinted(tex, col, size, alpha=1.0, rot=0):
    t = tex.resize((max(2, int(size)), max(2, int(size))), Image.LANCZOS)
    if rot:
        t = t.rotate(rot, Image.BICUBIC, expand=True)
    arr = np.asarray(t).astype(float)
    arr[..., :3] = arr[..., :3] * np.array(col) / 255
    arr[..., 3] *= alpha
    return Image.fromarray(arr.astype(np.uint8))


def stamp(layer, img, x, y):
    layer.alpha_composite(img, (int(x - img.width / 2), int(y - img.height / 2)))


# ------------------------------------------------------------ auras

def aura(kind, skin, pet, tex, R):
    """(behind, front) RGBA layers for this pet's aura."""
    rnd = random.Random(hash((kind, skin, "aura")) & 0xffff)
    x0, y0, x1, y1 = pet.getbbox()
    cx, w, h = (x0 + x1) / 2, x1 - x0, y1 - y0
    back, front = Image.new("RGBA", (R, R)), Image.new("RGBA", (R, R))
    if skin == "Gold":
        # warm glow behind
        g = Image.new("RGBA", (R, R))
        ImageDraw.Draw(g).ellipse([cx - w * 0.7, y0 + h * 0.05, cx + w * 0.7, y1 + h * 0.05], fill=(255, 200, 60, 110))
        back.alpha_composite(g.filter(ImageFilter.GaussianBlur(w * 0.18)))
        # ground ring, back half behind the pet and front half over its feet
        rw, rh = w * 0.75, w * 0.17
        ring = Image.new("RGBA", (R, R))
        rd = ImageDraw.Draw(ring)
        for k, (wd, a) in enumerate([(22, 70), (12, 140), (5, 255)]):
            rd.ellipse([cx - rw, y1 - rh, cx + rw, y1 + rh], outline=(255, 214, 80, a), width=wd)
        ring = Image.alpha_composite(ring.filter(ImageFilter.GaussianBlur(5)), ring)
        top = ring.copy()
        top.paste((0, 0, 0, 0), (0, int(y1), R, R))
        bot = ring.copy()
        bot.paste((0, 0, 0, 0), (0, 0, R, int(y1)))
        back.alpha_composite(top)
        front.alpha_composite(bot)
        # glints rising off it
        for _ in range(26):
            x = rnd.uniform(cx - w * 0.6, cx + w * 0.6)
            y = rnd.uniform(y0 - h * 0.15, y1)
            s = rnd.uniform(14, 38) * (1.2 - (y1 - y) / h * 0.5)
            stamp(front if rnd.random() < 0.6 else back, tinted(tex["AuraStar"], (255, 222, 110), s, rnd.uniform(0.6, 1)), x, y)
    elif skin == "Diamond":
        # icy mist round the feet
        for _ in range(14):
            x = rnd.uniform(cx - w * 0.6, cx + w * 0.6)
            stamp(back if rnd.random() < 0.5 else front, tinted(tex["AuraPuff"], (200, 240, 255), rnd.uniform(70, 140), 0.35), x, y1 - rnd.uniform(0, h * 0.1))
        # shards orbiting on a tilted ellipse: the far ones behind and smaller
        n = 11
        oy, ow, oh = y0 + h * 0.5, w * 0.72, h * 0.16
        ph = rnd.uniform(0, 6.28)
        for k in range(n):
            a = ph + k * 2 * math.pi / n
            x, y = cx + ow * math.cos(a), oy + oh * math.sin(a) - h * 0.08 * math.cos(a * 2)
            near = math.sin(a) > 0
            s = (56 if near else 36) * rnd.uniform(0.8, 1.2)
            col = rnd.choice([(170, 235, 255), (220, 245, 255), (255, 220, 250), (200, 255, 240)])  # a hint of prism
            stamp(front if near else back, tinted(tex["AuraShard"], col, s, 1 if near else 0.75, rnd.uniform(-25, 25)), x, y)
        # white flashes
        for _ in range(8):
            stamp(front, tinted(tex["AuraStar"], (255, 255, 255), rnd.uniform(16, 30)), rnd.uniform(x0, x1), rnd.uniform(y0, y1))
    elif skin == "Galaxy":
        # nebula behind
        neb = Image.new("RGBA", (R, R))
        for _ in range(16):
            col = rnd.choice([(255, 80, 220), (90, 200, 255), (150, 80, 255)])
            stamp(neb, tinted(tex["AuraPuff"], col, rnd.uniform(w * 0.4, w * 0.8), 0.45),
                  rnd.uniform(cx - w * 0.55, cx + w * 0.55), rnd.uniform(y0, y1))
        back.alpha_composite(neb)
        # tilted ring of orbiting stars
        oy, ow, oh, tilt = y0 + h * 0.45, w * 0.78, h * 0.13, math.radians(-14)
        for k in range(46):
            a = k * 2 * math.pi / 46 + rnd.uniform(-0.05, 0.05)
            ex, ey = ow * math.cos(a), oh * math.sin(a)
            x = cx + ex * math.cos(tilt) - ey * math.sin(tilt)
            y = oy + ex * math.sin(tilt) + ey * math.cos(tilt)
            near = math.sin(a) > 0
            big = k % 6 == 0
            stamp(front if near else back, tinted(tex["AuraStar"], (255, 255, 255) if big else (180, 230, 255),
                                                  (26 if big else 10) * (1.2 if near else 0.8), 1 if near else 0.6), x, y)
        # twinkles around
        for _ in range(24):
            stamp(front if rnd.random() < 0.5 else back, tinted(tex["AuraStar"], rnd.choice([(255, 255, 255), (255, 200, 250), (160, 240, 255)]), rnd.uniform(8, 24)),
                  rnd.uniform(cx - w * 0.75, cx + w * 0.75), rnd.uniform(y0 - h * 0.15, y1))
    return back, front


def sheet(kinds):
    os.makedirs(OUT, exist_ok=True)
    os.makedirs(TEX, exist_ok=True)
    tex = {}
    for name, fn in TEXTURES.items():
        tex[name] = fn()
        tex[name].save(os.path.join(TEX, name + ".png"))
    skins = ["Gold", "Diamond", "Galaxy"]
    names = {"Gold": "Gold  ·  Midas aura", "Diamond": "Diamond  ·  Prism aura", "Galaxy": "Galaxy  ·  Cosmos aura"}
    bgs = {"Gold": (70, 52, 26), "Diamond": (30, 52, 78), "Galaxy": (18, 14, 40)}
    C, head, R = 420, 60, 900
    W, H = C * len(skins), head + C * len(kinds) + 150
    out = Image.new("RGB", (W, H), (238, 242, 248))
    d = ImageDraw.Draw(out)
    font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 24)
    small = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 18)
    for j, s in enumerate(skins):
        d.rectangle([j * C, head, (j + 1) * C, head + C * len(kinds)], fill=bgs[s])
        d.text((j * C + C / 2, head / 2), names[s], fill=(40, 40, 60), font=font, anchor="mm")
    for i, kind in enumerate(kinds):
        cam, st, model = RS.frame(kind)
        # shrink the pet within the frame so the aura has room
        eye, target = cam
        eye = target + (np.array(eye) - target) * 1.55
        for j, s in enumerate(skins):
            pet = RS.shoot(kind, s, (eye, target), st, model, R=R)
            back, front = aura(kind, s, pet, tex, R)
            im = Image.alpha_composite(Image.alpha_composite(back, pet), front)
            bb = im.getbbox()
            side = max(bb[2] - bb[0], bb[3] - bb[1])
            cx, cy = (bb[0] + bb[2]) / 2, (bb[1] + bb[3]) / 2
            crop = im.crop((int(cx - side / 2 * 1.05), int(cy - side / 2 * 1.05), int(cx + side / 2 * 1.05), int(cy + side / 2 * 1.05)))
            crop = crop.resize((C - 16, C - 16), Image.LANCZOS)
            out.paste(crop, (j * C + 8, head + i * C + 8), crop)
            full = Image.new("RGBA", crop.size, bgs[s] + (255,))
            Image.alpha_composite(full, crop).save(os.path.join(OUT, f"{kind}_{s}_Aura.png"))
    # the textures strip
    y = head + C * len(kinds) + 10
    d.text((10, y), "Particle textures (white, tinted per skin in game):", fill=(60, 60, 80), font=small)
    for k, (name, t) in enumerate(tex.items()):
        cell = Image.new("RGBA", (110, 110), (40, 40, 60, 255))
        cell.alpha_composite(t.resize((100, 100), Image.LANCZOS), (5, 5))
        out.paste(cell.convert("RGB"), (20 + k * 300, y + 30))
        d.text((140 + k * 300, y + 85), name, fill=(60, 60, 80), font=small, anchor="lm")
    out.save(os.path.join(OUT, "rebirth_auras_lineup.png"))
    print(os.path.join(OUT, "rebirth_auras_lineup.png"))


if __name__ == "__main__":
    sheet(sys.argv[1:] or ["Horse", "Lion", "Asura"])
