"""Style options for the guide arrows (the trail on the ground from your pet to the
next egg or animal; Ride.client's EggGuide beam and Tutorial's TutorialGuide), next
to the yellow ring under an animal for comparison (QM, Oct 3: "no glow and the
same exact colour as the rings").

Run: python3 tools/guide_arrow_options.py
Writes /mnt/project-files/ui/guide_arrows/guide_arrow_options.png and each option's
beam texture (128x128, white on clear: the beam tints it) as tex_<key>.png.

The beam is drawn as the game draws it: a strip 4 studs wide lying 1.4 studs up,
from 6 studs ahead of the pet to the target, the texture repeating every
TextureLength studs, fading in and out over the first and last 8-10%, drawn on top
of everything. A glowing beam (LightEmission 1) adds its colour to what's under
it; a flat one (LightEmission 0, LightInfluence 0) paints it, like the ring's dashes.
"""

import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

sys.path.insert(0, os.path.dirname(__file__))
import pet_headshots as P  # noqa: E402
from partlib import Part, T, Ry, render, look_at  # noqa: E402

ROOT = os.path.join(os.path.dirname(__file__), "..")
OUT = "/mnt/project-files/ui/guide_arrows"
RING = (255, 255, 0)  # FFFF00, Outline.luau

W, H, FOV = 760, 560, 50
EYE, TARGET = np.array([0.0, 34, 26]), np.array([-4.0, 0, -22])  # the riding camera looks well down
GOAL = np.array([-14.0, 0, -44])  # the animal the trail leads to


def texture(kind, n=128):
    """A beam texture, white on clear. The image's x axis runs along the trail
    (x = 0 at the pet's end), y across it."""
    im = Image.new("RGBA", (n, n))
    d = ImageDraw.Draw(im)
    if kind == "current":
        # assets/ui/GuideArrow.png, turned to point along +x
        src = Image.open(os.path.join(ROOT, "assets", "ui", "GuideArrow.png")).convert("RGBA").resize((n, n))
        return src.rotate(90, expand=False)
    if kind == "solid":  # a fat chevron, no edge, more space round it
        pts = [(0.2, 0.08), (0.62, 0.5), (0.2, 0.92), (0.02, 0.92), (0.44, 0.5), (0.02, 0.08)]
        d.polygon([(x * n + 0.2 * n, y * n) for x, y in pts], fill=(255, 255, 255, 255))
    elif kind == "triangle":  # a solid arrowhead
        d.polygon([(0.3 * n, 0.12 * n), (0.8 * n, 0.5 * n), (0.3 * n, 0.88 * n)], fill=(255, 255, 255, 255))
    elif kind == "dash":  # like the ring's dashes: a run of short bars
        d.rounded_rectangle((0.12 * n, 0.36 * n, 0.72 * n, 0.64 * n), radius=int(0.1 * n), fill=(255, 255, 255, 255))
    elif kind == "double":  # two thinner chevrons close together
        for x0 in (0.12, 0.42):
            pts = [(0.0, 0.14), (0.3, 0.5), (0.0, 0.86), (-0.14, 0.86), (0.16, 0.5), (-0.14, 0.14)]
            d.polygon([((x + x0 + 0.14) * n, y * n) for x, y in pts], fill=(255, 255, 255, 255))
    return im


# key, label, texture, colour, glow, texture length (studs), width (studs)
OPTIONS = [
    ("A", "A  now: glowing pale yellow", "current", (255, 236, 120), True, 5, 4),
    ("B", "B  same arrows, flat FFFF00, no glow", "current", RING, False, 5, 4),
    ("C", "C  fat solid chevrons, flat FFFF00, spaced out", "solid", RING, False, 7, 4.5),
    ("D", "D  solid arrowheads, flat FFFF00", "triangle", RING, False, 6, 4),
    ("E", "E  double chevrons, flat FFFF00", "double", RING, False, 8, 4.5),
    ("F", "F  dashes like the ring, flat FFFF00", "dash", RING, False, 4, 3.2),
]


def scaled(kind, at, yaw=0.0):
    model = P.load(kind)
    parts = P.parts_of(kind, model, ("gallop", 0.3))
    pts = np.concatenate([q for p in parts for q in p.polys])
    d = pts.max(0) - pts.min(0)
    s = 10.4 / math.sqrt(sorted(d)[1] * sorted(d)[2])  # Config.PetSmallSize, tier 1
    c, sn = math.cos(math.radians(yaw)), math.sin(math.radians(yaw))
    R = np.array([[c, 0, sn], [0, 1, 0], [-sn, 0, c]])
    for p in parts:
        p.polys = [(q * s) @ R.T + at for q in p.polys]
    return parts, max(d[0], d[2]) * s


def ring(at, size):
    """Outline.luau's ring: ten dashes (60% of each slot), lying just off the floor, flat FFFF00."""
    radius = 0.5 * size * 0.75 + 1
    parts = []
    for k in range(10):
        a0 = 2 * math.pi * k / 10
        for j in range(5):  # each dash as a few short blocks along the arc
            a = a0 + 2 * math.pi / 10 * 0.6 * (j + 0.5) / 5
            x, z = at[0] + radius * math.cos(a), at[2] + radius * math.sin(a)
            p = Part(f"Ring{k}{j}", (0.6, 0.1, radius * 2 * math.pi / 10 * 0.6 / 5 + 0.05),
                     T(x, 0.2, z) @ Ry(-math.degrees(a)), RING, plain=True)
            p.neon = True
            parts.append(p)
    return parts


def scene():
    pet, _ = scaled("Horse", np.array([0.0, 0, 0]))
    pig, size = scaled("Pig", GOAL, 20)
    for p in pet + pig:
        p.neon = getattr(p, "neon", False)
    return render(pet + pig + ring(GOAL, size), eye=EYE, target=TARGET, W=W, H=H, fov=FOV, outline=False)


def beam(base, tex, color, glow, length, width):
    """Paints the guide beam onto a rendered frame, as Ride.client lays it."""
    eye, r, u, f = look_at(EYE, TARGET)
    focal = (H / 2) / math.tan(math.radians(FOV) / 2)
    px, py = np.meshgrid(np.arange(W) + 0.5, np.arange(H) + 0.5)
    dirs = r * ((px - W / 2) / focal)[..., None] - u * ((py - H / 2) / focal)[..., None] + f
    y0 = 1.4
    t = (y0 - eye[1]) / np.where(dirs[..., 1] < -1e-6, dirs[..., 1], np.nan)
    gx, gz = eye[0] + t * dirs[..., 0], eye[2] + t * dirs[..., 2]
    start = np.array([0.0, -6.0])
    end = np.array([GOAL[0], GOAL[2]])
    along = (end - start) / np.linalg.norm(end - start)
    side = np.array([-along[1], along[0]])
    L = np.linalg.norm(end - start)
    rel_x, rel_z = gx - start[0], gz - start[1]
    s = rel_x * along[0] + rel_z * along[1]  # studs along the trail
    w = rel_x * side[0] + rel_z * side[1]  # studs across it
    inside = np.isfinite(s) & (s >= 0) & (s <= L) & (np.abs(w) <= width / 2)
    tx = np.asarray(tex, float) / 255
    n = tx.shape[0]
    ui = np.clip(((s % length) / length * n).astype(int), 0, n - 1)
    vi = np.clip(((w / width + 0.5) * n).astype(int), 0, n - 1)
    texel = tx[vi, ui]
    # the fade at each end (Ride.client's Transparency keys)
    frac = np.clip(s / L, 0, 1)
    fade = np.interp(frac, [0, 0.08, 0.9, 1], [0, 0.85 if glow else 1, 0.85 if glow else 1, 0])
    alpha = np.where(inside, texel[..., 3] * fade, 0)[..., None]
    col = texel[..., :3] * np.array(color) / 255
    img = np.asarray(base.convert("RGB"), float) / 255
    if glow:
        out = img + col * alpha  # LightEmission 1: adds light
        halo = Image.fromarray((np.clip(col * alpha, 0, 1) * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(3))
        out += np.asarray(halo, float) / 255 * 0.5
    else:
        out = img * (1 - alpha) + col * alpha
    return Image.fromarray((np.clip(out, 0, 1) * 255).astype(np.uint8))


def main():
    os.makedirs(OUT, exist_ok=True)
    base = scene()
    cols = 3
    rows = math.ceil(len(OPTIONS) / cols)
    crop = (150, 40, 590, 480)  # the pet, the trail and the animal it leads to
    tw, th = crop[2] - crop[0], crop[3] - crop[1]
    sheet = Image.new("RGB", (tw * cols, (th + 30) * rows), (255, 255, 255))
    d = ImageDraw.Draw(sheet)
    for i, (key, label, kind, color, glow, length, width) in enumerate(OPTIONS):
        tex = texture(kind)
        tex.save(os.path.join(OUT, f"tex_{key}.png"))
        im = beam(base, tex, color, glow, length, width)
        im.save(os.path.join(OUT, f"option_{key}.png"))
        x, y = (i % cols) * tw, (i // cols) * (th + 30)
        sheet.paste(im.crop(crop), (x, y + 30))
        d.text((x + 8, y + 9), label, fill=(20, 20, 20))
    path = os.path.join(OUT, "guide_arrow_options.png")
    sheet.save(path)
    print("wrote", path)


if __name__ == "__main__":
    main()
