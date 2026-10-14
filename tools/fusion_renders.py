"""Renders example fusions (src/shared/Fusion.luau): the base, the donor and the hybrid
side by side, repainted with the same palette rules as the game (src/shared/Palettes.luau,
parsed from the Luau file so there's one source of truth).

Run from the repo root:
  python3 tools/fusion_renders.py [--seed N] [--count N] [Base:Donor ...]
Writes fusions.png (a contact sheet) to OUT.
"""

import colorsys
import os
import random
import re
import sys

from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, os.path.dirname(__file__))
import pet_headshots as P  # noqa: E402

ROOT = os.path.join(os.path.dirname(__file__), "..")
OUT = "/mnt/project-files/fusions"
RARITIES = ["Common", "Uncommon", "Rare", "Epic", "Legendary"]


def palettes():
    src = open(os.path.join(ROOT, "src/shared/Palettes.luau")).read()
    out = {}
    for m in re.finditer(r"\n\t(\w+) = \{\n(.*?)\n\t\},", src, re.S):
        kind, body = m.group(1), m.group(2)
        slots, base, parts = {}, {}, {}
        for e in re.finditer(r'\{ "(\w+)", (\d+), (\d+), (\d+) \}', body):
            slot, rgb = e.group(1), tuple(int(x) for x in e.group(2, 3, 4))
            slots[rgb] = slot
            base.setdefault(slot, rgb)
        pm = re.search(r"parts = \{(.*?)\}", body)
        if pm:
            for name, slot in re.findall(r'(\w+) = "(\w+)"', pm.group(1)):
                parts[name] = slot
        out[kind] = dict(slots=slots, base=base, parts=parts)
    return out


def config_numbers(name):
    src = open(os.path.join(ROOT, "src/shared/Config.luau")).read()
    block = re.search(r"\n\t?" + name + r" = \{(.*?)\n\t?\}", src, re.S) or re.search(r"Config\." + name + r" = \{(.*?)\n\}", src, re.S)
    return {k: float(v) for k, v in re.findall(r"(\w+) = ([\d.]+)", block.group(1))}


def rarity(kind):
    path = os.path.join(ROOT, "src/shared/Animals", kind + ".luau")
    m = re.search(r'"(Common|Uncommon|Rare|Epic|Legendary)"', open(path).read())
    return m.group(1) if m else "Common"


def lerp(c, t, f):
    return tuple(a + (b - a) * f for a, b in zip(c, t))


def donor_color(base, slot):
    if slot in base:
        return [x / 255 for x in base[slot]]
    body = [x / 255 for x in base.get("Body", (200, 200, 200))]
    mark = [x / 255 for x in base["Marking"]] if "Marking" in base else None
    if slot == "Belly":
        return lerp(body, (1, 1, 1), 0.55)
    if slot == "Marking":
        return lerp(body, (0, 0, 0), 0.35)
    if slot == "Accent":
        return lerp(mark, (1, 1, 1), 0.3) if mark else lerp(body, (1, 1, 1), 0.3)
    if slot == "Horn":
        return [x / 255 for x in base["Hoof"]] if "Hoof" in base else lerp(body, (1, 1, 1), 0.6)
    if slot == "Hoof":
        return [x / 255 for x in base["Horn"]] if "Horn" in base else lerp(body, (0, 0, 0), 0.5)
    return body


def shade(c, frm, to):
    if tuple(c) == tuple(frm):
        return to
    h, s, v = colorsys.rgb_to_hsv(*c)
    h0, s0, v0 = colorsys.rgb_to_hsv(*frm)
    h1, s1, v1 = colorsys.rgb_to_hsv(*to)
    dh = (h - h0 + 0.5) % 1 - 0.5
    hue = (h1 + (dh if abs(dh) < 0.08 else 0)) % 1
    sat = s1 * s / s0 if s0 > 0.05 else s1 + (s - s0)
    if v <= v0:
        val = v1 * (v / v0 if v0 > 0 else 1)
    else:
        val = v1 + (1 - v1) * (v - v0) / max(1 - v0, 0.01)
    return colorsys.hsv_to_rgb(hue, min(max(sat, 0), 1), min(max(val, 0), 1))


def recolor(pal, kind, fuse, name, rgb):
    own, donor = pal[kind], pal[fuse]
    slot = own["parts"].get(name) or own["slots"].get(tuple(rgb))
    if not slot or slot == "Fixed":
        return rgb
    frm = [x / 255 for x in own["base"].get(slot, rgb)]
    c = shade([x / 255 for x in rgb], frm, donor_color(donor["base"], slot))
    return tuple(int(x * 255 + 0.5) for x in c)


def shot(kind, fuse=None, pal=None, size=360):
    st = P.STYLES["action"]
    pose = ("idle", 0.0) if kind in P.ACTION_IDLE else st["pose"]
    parts = P.parts_of(kind, P.load(kind), pose)
    if fuse:
        for p in parts:
            p.color = recolor(pal, kind, fuse, p.name, p.color)
    eye, target = P.camera(kind, st, parts)
    im = P.render(parts, eye=eye, target=target, W=720, H=720, fov=st["fov"], transparent=True, outline=False)
    im = im.crop(im.getbbox())
    side = int(max(im.size) * 1.08)
    sq = Image.new("RGBA", (side, side))
    sq.paste(im, ((side - im.width) // 2, (side - im.height) // 2))
    return sq.resize((size, size), Image.LANCZOS)


def order(a, b, income):
    ra, rb = RARITIES.index(rarity(a)), RARITIES.index(rarity(b))
    if rb > ra or (rb == ra and income.get(b, 0) > income.get(a, 0)):
        return b, a
    return a, b


def font(n):
    for f in ("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",):
        if os.path.exists(f):
            return ImageFont.truetype(f, n)
    return ImageFont.load_default()


def sheet(pairs, path):
    pal = palettes()
    tiers = config_numbers("PetTiers")
    growth = 1.6
    cell, pad, head = 300, 20, 46
    W = 3 * cell + 2 * pad + 220
    rows = []
    for base, donor in pairs:
        scale = growth ** (tiers.get(donor, 1) - tiers.get(base, 1))
        rows.append((base, donor, scale, shot(base, size=cell), shot(donor, size=cell), shot(base, donor, pal, size=cell)))
        print(base, "x", donor, f"size x{scale:.2f}", flush=True)
    H = len(rows) * (cell + head + pad) + pad
    im = Image.new("RGB", (W, H), (244, 240, 230))
    d = ImageDraw.Draw(im)
    f, small = font(26), font(20)
    for i, (base, donor, scale, a, b, h) in enumerate(rows):
        y = pad + i * (cell + head + pad)
        x0 = pad
        d.text((x0, y), f"{base} (base, {rarity(base)})", fill=(40, 40, 40), font=small)
        d.text((x0 + cell + 40, y), f"{donor} (donor, {rarity(donor)})", fill=(40, 40, 40), font=small)
        d.text((x0 + 2 * cell + 80, y), f"{base} x {donor}  size x{scale:.2g}", fill=(150, 40, 90), font=small)
        for j, pic in enumerate((a, b, h)):
            im.paste(pic, (x0 + j * (cell + 40), y + head - 10), pic)
        d.text((x0 + cell + 8, y + head + cell // 2 - 20), "+", fill=(80, 80, 80), font=f)
        d.text((x0 + 2 * cell + 48, y + head + cell // 2 - 20), "=", fill=(80, 80, 80), font=f)
    im.save(path)
    print("wrote", path)


def main(args):
    seed, count, pairs = 7, 10, []
    while args:
        a = args.pop(0)
        if a == "--seed":
            seed = int(args.pop(0))
        elif a == "--count":
            count = int(args.pop(0))
        else:
            pairs.append(tuple(a.split(":")))
    pal = palettes()
    income = config_numbers("PetIncome")
    if not pairs:
        rng = random.Random(seed)
        kinds = sorted(k for k in P.MODELS if k in pal)
        while len(pairs) < count:
            a, b = rng.sample(kinds, 2)
            pairs.append(order(a, b, income))
    os.makedirs(OUT, exist_ok=True)
    sheet(pairs, os.path.join(OUT, f"fusions_seed{seed}.png" if not args else "fusions.png"))


if __name__ == "__main__":
    main(sys.argv[1:])
