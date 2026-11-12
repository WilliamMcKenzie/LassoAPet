"""World 2's walls (QM, Oct 13): every biome's colours, and engravings on the base's and the
Meadow's marble (gold) and the Ancient Tomb's gold (lapis, red and bronze).

Run: python3 tools/world2_walls.py [out_dir]
     draws the two engravings as see-through pixel art (assets/world2/WallMarble.png and
     WallTomb.png, 16 px a stud), a preview of each on its wall in out_dir, and nothing else:
     tools/world2_walls.luau lays them in Studio (a Texture on each wall's inside face, over
     its checker, so no parts) once Studio has uploaded them and filled in their ids.

Each image is one tile PERIOD studs long and the wall's full 48 studs tall, symmetric about
its middle, so it reads the same whichever way a face's U runs and lines up from one wall
part to the next (tools/world2_walls.luau sets each one's offset from where it starts).
"""

import os
import sys

from PIL import Image

HERE = os.path.dirname(__file__)
PERIOD, HEIGHT, PX = 64, 48, 16  # studs along, studs up, pixels a stud

GOLD = (226, 186, 52)  # the marble's inlay
MARBLE = [(236, 232, 224), (218, 214, 206)]  # (World 2's Meadow WallColors: preview only)
TOMB = [(211, 183, 66), (196, 168, 54)]  # #D3B742 (preview only)
LAPIS, RED, BRONZE, TURQ = (38, 76, 160), (184, 56, 40), (150, 116, 28), (40, 166, 158)

# A Greek key, 8 studs wide and 7 up, spiralling in; its mirror is the next one along.
KEY = [
    "#######.",
    "#.....#.",
    "#.###.#.",
    "#.#.#.#.",
    "#.#...#.",
    "#.#####.",
    "#.......",
]

# The tomb's glyphs, stacked in the cartouche (each symmetric, 8 wide).
GLYPHS = [
    (LAPIS, [  # an ankh
        "..####..",
        ".#....#.",
        ".#....#.",
        "..#..#..",
        "########",
        "...##...",
        "...##...",
        "...##...",
    ]),
    (RED, [  # the sun
        "..####..",
        ".######.",
        "###..###",
        "##.##.##",
        "###..###",
        ".######.",
        "..####..",
    ]),
    (LAPIS, [  # a scarab
        "#......#",
        ".#.##.#.",
        "..####..",
        ".######.",
        "########",
        ".######.",
        "#.####.#",
    ]),
]


class Art:
    """A PERIOD x HEIGHT grid of studs (y up from the wall's foot), None = see-through."""

    def __init__(self):
        self.g = [[None] * PERIOD for _ in range(HEIGHT)]

    def put(self, x, y, col):
        if 0 <= y < HEIGHT:
            self.g[y][x % PERIOD] = col

    def rect(self, x0, y0, w, h, col):
        for x in range(x0, x0 + w):
            for y in range(y0, y0 + h):
                self.put(x, y, col)

    def bitmap(self, x0, y_top, rows, col, mirror=False):
        for r, line in enumerate(rows):
            for c, ch in enumerate(line[::-1] if mirror else line):
                if ch == "#":
                    self.put(x0 + c, y_top - r, col)

    def symmetric(self):
        return all(self.g[y][x] == self.g[y][(PERIOD - 1 - x)] for y in range(HEIGHT) for x in range(PERIOD))

    def png(self, path):
        im = Image.new("RGBA", (PERIOD * PX, HEIGHT * PX), (0, 0, 0, 0))
        px = im.load()
        for y in range(HEIGHT):
            for x in range(PERIOD):
                c = self.g[y][x]
                if c:
                    for a in range(PX):
                        for b in range(PX):
                            px[x * PX + a, (HEIGHT - 1 - y) * PX + b] = (*c, 255)
        im.save(path)

    def preview(self, path, wall, tiles=3, s=6):
        """tiles of it on the wall's colour and 4-stud checker, s pixels a stud."""
        im = Image.new("RGB", (PERIOD * tiles * s, HEIGHT * s))
        px = im.load()
        for X in range(PERIOD * tiles):
            for y in range(HEIGHT):
                c = self.g[y][X % PERIOD] or wall[(X // 4 + y // 4) % 2]
                for a in range(s):
                    for b in range(s):
                        px[X * s + a, (HEIGHT - 1 - y) * s + b] = c
        im.save(path)


def marble():
    """The base's and Meadow's marble: a gold line along the foot, panels framed in gold with
    a diamond in each, and a frieze of Greek keys along the top between two gold lines."""
    a = Art()
    a.rect(0, 3, PERIOD, 1, GOLD)  # the foot's line
    # Panels: a frame 52 wide, 22 up, its corners squared off; a diamond in its middle.
    x0, x1, y0, y1 = 6, 58, 8, 29  # (x1, y1 exclusive)
    a.rect(x0, y0, x1 - x0, 1, GOLD)
    a.rect(x0, y1 - 1, x1 - x0, 1, GOLD)
    a.rect(x0, y0, 1, y1 - y0, GOLD)
    a.rect(x1 - 1, y0, 1, y1 - y0, GOLD)
    for cx, cy in ((x0 + 2, y0 + 2), (x1 - 3, y0 + 2), (x0 + 2, y1 - 3), (x1 - 3, y1 - 3)):
        a.put(cx, cy, GOLD)  # (a stud in each corner)
    cy = (y0 + y1 - 1) // 2  # 18
    for r in range(8):  # a diamond outline, 8 out
        for dx in (-r, r - 1):
            a.put(32 + dx, cy + (7 - r), GOLD)
            a.put(32 + dx, cy - (7 - r), GOLD)
    a.rect(31, cy - 1, 2, 3, GOLD)  # its middle
    a.rect(30, cy, 4, 1, GOLD)
    # Long lines either side of the diamond, out to the frame (a stud short of it).
    a.rect(x0 + 4, cy, 32 - 9 - (x0 + 4) + 1, 1, GOLD)
    a.rect(32 + 8, cy, x1 - 4 - 40, 1, GOLD)
    # The frieze: lines at 33 and 44, keys in between (rows 35..41), facing in pairs.
    a.rect(0, 33, PERIOD, 1, GOLD)
    a.rect(0, 43, PERIOD, 1, GOLD)
    for k in range(PERIOD // 8):
        a.bitmap(k * 8, 41, KEY, GOLD, mirror=k % 2 == 1)
    return a


def tomb():
    """The tomb's gold: a bronze foot, a cartouche of glyphs between stepped pyramids, a row
    of hanging bronze triangles and a band of lapis, red and turquoise along the top."""
    a = Art()
    a.rect(0, 1, PERIOD, 3, BRONZE)  # the foot
    a.rect(0, 5, PERIOD, 1, LAPIS)
    # The cartouche: an outline 12 wide, its corners rounded, an ankh, the sun and a scarab stacked in it.
    x0, x1, y0, y1 = 26, 38, 7, 39  # (x1, y1 exclusive)
    a.rect(x0 + 1, y0, x1 - x0 - 2, 1, BRONZE)
    a.rect(x0 + 1, y1 - 1, x1 - x0 - 2, 1, BRONZE)
    a.rect(x0, y0 + 1, 1, y1 - y0 - 2, BRONZE)
    a.rect(x1 - 1, y0 + 1, 1, y1 - y0 - 2, BRONZE)
    a.rect(x0 - 1, y0 - 1, x1 - x0 + 2, 1, BRONZE)  # (the bar under it, as a cartouche has)
    top = y1 - 3
    for col, rows in GLYPHS:
        a.bitmap(28, top, rows, col)
        top -= len(rows) + 2
    # A stepped pyramid either side, sharing the tile's edge (whole across x 0 / 64).
    for step in range(9):
        h = 9 - step  # half its width, in studs
        a.rect(-h, 7 + step, 2 * h, 1, BRONZE)
        a.put(-h, 7 + step, RED if step % 2 else BRONZE)
        a.put(h - 1, 7 + step, RED if step % 2 else BRONZE)
    a.rect(-1, 16, 2, 2, (255, 222, 90))  # its gilded tip
    # Lines and the hanging triangles under the band.
    a.rect(0, 40, PERIOD, 1, BRONZE)
    for k in range(PERIOD // 8):
        for r in range(3):
            a.rect(k * 8 + 1 + r, 39 - r, 6 - 2 * r, 1, BRONZE)
    # The band: 6-stud blocks 2 apart, red / lapis / turquoise, mirrored about the middle.
    a.rect(0, 41, PERIOD, 1, BRONZE)
    for k, col in enumerate([RED, LAPIS, TURQ, LAPIS, LAPIS, TURQ, LAPIS, RED]):
        a.rect(k * 8 + 1, 42, 6, 4, col)
    a.rect(0, 46, PERIOD, 1, BRONZE)
    return a


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else "/mnt/project-files/biomes/world2_walls"
    os.makedirs(out, exist_ok=True)
    assets = os.path.join(HERE, "..", "assets", "world2")
    os.makedirs(assets, exist_ok=True)
    for name, art, wall in (("WallMarble", marble(), MARBLE), ("WallTomb", tomb(), TOMB)):
        assert art.symmetric(), name + " isn't symmetric about its middle"
        art.png(os.path.join(assets, name + ".png"))
        art.preview(os.path.join(out, name.lower() + "_preview.png"), wall)
        print(name, sum(c is not None for row in art.g for c in row), "studs inlaid")


if __name__ == "__main__":
    main()
