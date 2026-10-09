"""Intentional dirt outside the main yard (QM, Oct 9), after the atlas modifiers in
QM's MapMaker (studio-imperium/atlas): CropCircle / Pattern are quasi-crystals, a sum
of cosine waves at N evenly spaced angles, cut into bands; Voronoi picks whole cells.
Tile maps only (2D previews) to choose a look; 4-stud tiles, same base as arc_base."""
import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, "..", "..", "tools"))
import arc_base as A  # noqa: E402

NX, NZ = 2 * A.W // 4, A.D // 4


def quasi(x, y, angles):
    """atlas quasiCrystal: 0..1"""
    v = 0.0
    ang = 2 * math.pi
    d = ang / angles
    for _ in range(int(math.ceil(angles))):
        v += math.cos(math.cos(ang) * x + math.sin(ang) * y)
        ang -= d
    return (v / math.ceil(angles) + 1) / 2


def main_yard():
    """The yard, lane and gate aprons from arc_base with its stray patches turned off."""
    k = A.ground_kind()
    yard = np.zeros_like(k)
    for i in range(NX):
        for j in range(NZ):
            x, z = -A.W + i * 4 + 2, j * 4 + 2
            r = math.hypot(x - A.CENTRE[0], z - A.CENTRE[1])
            if k[i, j] and (r < A.RC - A.PEN / 2 + 2 or (z < A.CENTRE[1] and abs(x) < 70)):
                yard[i, j] = 1
    return yard


def blocked():
    """Tiles that must stay grass: under/around pens, 2 tiles off walls, rocks."""
    b = np.zeros((NX, NZ), bool)
    for i in range(NX):
        for j in range(NZ):
            x, z = -A.W + i * 4 + 2, j * 4 + 2
            if abs(x) > A.W - 8 or z > A.D - 8 or (z < 8 and abs(x) > A.CORR - 8):
                b[i, j] = True
            for p in A.pens():
                t = math.radians(p["a"])
                dx, dz = x - p["x"], z - p["z"]
                al, o = -dx * math.sin(t) + dz * math.cos(t), dx * math.cos(t) + dz * math.sin(t)
                if abs(al) < A.PEN / 2 + 4 and abs(o) < A.PEN / 2 + 4:
                    b[i, j] = True
    import big_rocks as BR
    for name, x, z, yaw in BR.BIG:
        if name == "Tor":
            continue
        for px, pz in BR.footprint(name, x, z, yaw):
            i, j = int((px + A.W) // 4), int(pz // 4)
            b[max(0, i - 2):i + 3, max(0, j - 2):j + 3] = True
    return b


# spots in the grass for designed patches: the wedges between pens and the open corners
SPOTS = [(-58, 218, 5), (58, 218, 5), (-130, 126, 5), (130, 126, 5), (-66, 28, 5), (66, 28, 5), (-150, 198, 4), (150, 198, 4)]  # (x, z, radius in tiles): the biggest clear discs of grass


def crop_circles(angles=7, band=0.5):
    """A: crop circles. Each spot gets one quasi-crystal rosette cut to a disc, so every
    patch is a clear round motif with rings and petals."""
    out = np.zeros((NX, NZ), int)
    for cx, cz, s in SPOTS:
        ci, cj = (cx + A.W) / 4, cz / 4
        R = s + 0.5
        scale = 0.9 * 7 / s  # puts the outer ring just inside the disc
        for i in range(NX):
            for j in range(NZ):
                dx, dy = i + 0.5 - ci, j + 0.5 - cj
                r = math.hypot(dx, dy)
                if r > R:
                    continue
                v = quasi(dx * scale, dy * scale, angles)
                if v > band or r < 1.6:
                    out[i, j] = 1
    return out


def pattern_band(angles=5, scale=0.55, band=0.7):
    """B: one big quasi-crystal Pattern over the whole base (atlas NewPattern), shown only in
    the grass ring round the yard: repeating star-like patches that line up across the map."""
    out = np.zeros((NX, NZ), int)
    for i in range(NX):
        for j in range(NZ):
            if quasi(i * scale, j * scale, angles) > band:
                out[i, j] = 1
    return out


def voronoi_cells(n=40, pick=0.3, seed=4):
    """C: Voronoi. The grass is cut into cells; a few whole cells are dirt, each with a
    one-tile grass rim (atlas SelectiveBorder), so patches are big chunky shapes."""
    rng = np.random.default_rng(seed)
    half = np.c_[rng.uniform(NX / 2, NX, n // 2), rng.uniform(0, NZ, n // 2)]
    pts = np.r_[half, np.c_[NX - half[:, 0], half[:, 1]]]  # mirrored, so the two sides match
    d_half = rng.random(n // 2) < pick
    dirt = np.r_[d_half, d_half]
    ii, jj = np.meshgrid(np.arange(NX) + 0.5, np.arange(NZ) + 0.5, indexing="ij")
    d = (ii[..., None] - pts[:, 0]) ** 2 + (jj[..., None] - pts[:, 1]) ** 2
    cell = d.argmin(-1)
    out = dirt[cell].astype(int)
    rim = np.zeros_like(out)
    rim[1:, :] |= cell[1:, :] != cell[:-1, :]
    rim[:-1, :] |= cell[:-1, :] != cell[1:, :]
    rim[:, 1:] |= cell[:, 1:] != cell[:, :-1]
    rim[:, :-1] |= cell[:, :-1] != cell[:, 1:]
    out[rim.astype(bool)] = 0
    return out


def compose(extra):
    yard = main_yard()
    b = blocked()
    k = yard.copy()
    ring = ~b & (yard == 0)
    # keep a one-tile grass gap so the extras never merge into the yard
    near = np.zeros_like(yard)
    for di in (-1, 0, 1):
        for dj in (-1, 0, 1):
            near |= np.roll(np.roll(yard, di, 0), dj, 1)
    k[(extra == 1) & ring & (near == 0)] = 1
    return k


def picture(k, title, path, px=6):
    img = Image.new("RGB", (NX * px, NZ * px + 40), (135, 207, 250))
    d = ImageDraw.Draw(img)
    G = [(77, 196, 63), (105, 255, 74)]
    Dt = [(225, 150, 104), (248, 170, 114)]
    b = blocked()
    for i in range(NX):
        for j in range(NZ):
            c = (Dt if k[i, j] else G)[(i + j) % 2]
            y = 40 + (NZ - 1 - j) * px
            d.rectangle([i * px, y, i * px + px - 1, y + px - 1], fill=c)
    for p in A.pens():  # pen outlines
        pts = []
        for lx, lz in ((-1, -1), (1, -1), (1, 1), (-1, 1), (-1, -1)):
            x, z = A.local(p, lx * A.PEN / 2, lz * A.PEN / 2)
            pts.append(((x + A.W) / 4 * px, 40 + (NZ - z / 4) * px))
        d.line(pts, fill=(204, 108, 52), width=3)
    f = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 22)
    d.text((NX * px / 2, 20), title, font=f, fill="white", anchor="mm", stroke_width=3, stroke_fill="black")
    img.save(path)
    return img


if __name__ == "__main__":
    takes = [("A  crop circles", crop_circles()), ("B  voronoi cells", voronoi_cells())]
    imgs = [picture(compose(e), t, os.path.join(HERE, f"dirt_{t[0]}.png")) for t, e in takes]
    W = sum(i.width for i in imgs) + 20 * (len(imgs) - 1)
    board = Image.new("RGB", (W, imgs[0].height), (135, 207, 250))
    x = 0
    for i in imgs:
        board.paste(i, (x, 0))
        x += i.width + 20
    board.save(os.path.join(HERE, "dirt_takes.png"))
