"""World 3's stone walls (QM, Oct 14): a band of carved runes along each wall's inside face.

Run: python3 tools/world3_runes.py
     draws assets/world3/WallRunes.png: see-through pixel art, one tile PERIOD studs along and
     the wall's 48 studs up (8 px a stud). tools/world3_runes.luau lays it as a Texture named
     "Engraving" on every wall part's inside face, lined up from part to part.
Grooves are a darker stone with a lighter lip under each stroke, so they read as cut in.
"""
import os
from PIL import Image

HERE = os.path.dirname(__file__)
PERIOD, HEIGHT, PX = 64, 48, 8
GROOVE, LIP = (112, 106, 100, 255), (226, 221, 212, 255)

# Elder-Futhark-like runes, 5 wide x 9 tall (each cell half a stud).
RUNES = [
    ["#....", "#..#.", "#.#..", "##...", "#....", "#....", "#....", "#....", "#...."],  # fehu-ish
    ["#...#", "##..#", "#.#.#", "#..##", "#...#", "#...#", "#...#", "#...#", "#...#"],
    ["..#..", ".#.#.", "#...#", ".#.#.", "..#..", ".#.#.", "#...#", ".#.#.", "..#.."],  # ingwaz stack
    ["#...#", ".#.#.", "..#..", "..#..", "..#..", "..#..", "..#..", "..#..", "..#.."],  # algiz flipped
    ["..#..", "..#..", ".###.", "#.#.#", "..#..", "..#..", "..#..", "..#..", "..#.."],  # tiwaz/algiz
    ["#...#", "##.##", "#.#.#", "#...#", "#...#", "#...#", "#...#", "#...#", "#...#"],  # mannaz-ish
    ["###..", "#..#.", "#..#.", "###..", "#.#..", "#..#.", "#...#", "#....", "#...."],  # raido
    ["#....", "##...", "#.#..", "#..#.", "#.#..", "##...", "#....", "#....", "#...."],  # thurisaz
]
CELL = PX // 2  # half a stud
W, H = PERIOD * PX, HEIGHT * PX
img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
px = img.load()

def cell(cx, cy, colour):
    for x in range(cx * CELL, cx * CELL + CELL):
        for y in range(cy * CELL, cy * CELL + CELL):
            if 0 <= x < W and 0 <= y < H:
                px[x, y] = colour

def groove(cx, cy):
    cell(cx, cy, GROOVE)

# band from 20 to 31 studs up (cells from the top: 48 studs = 96 cells)
top_line, bottom_line = (48 - 31) * 2, (48 - 20) * 2
for cx in range(PERIOD * 2):
    groove(cx, top_line)
    groove(cx, bottom_line)
# runes between, 9 cells tall, each 5 wide with 3 cells between
y0 = top_line + 3
x = 2
i = 0
while x + 5 <= PERIOD * 2 - 1:
    rune = RUNES[i % len(RUNES)]
    for ry, row in enumerate(rune):
        for rx, ch in enumerate(row):
            if ch == "#":
                groove(x + rx, y0 + ry)
    x += 8
    i += 1
# a lighter lip under every groove cell (where there's no groove), one px tall
lip = []
for xx in range(W):
    for yy in range(H - 1):
        if px[xx, yy] == GROOVE and px[xx, yy + 1][3] == 0:
            lip.append((xx, yy + 1))
for xx, yy in lip:
    px[xx, yy] = LIP
out = os.path.join(HERE, "..", "assets", "world3", "WallRunes.png")
img.save(out)
print(out, img.size)
