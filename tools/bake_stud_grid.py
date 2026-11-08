"""Bakes the studs into the baseplate grid (QM, Nov 8: one Texture a face, not a grid + a stud
Texture each: ~23,000 fewer Textures on the map). Each picture is what the two drew together:
the grid black at Config.BaseplateTransparency, the stud decal (rbxassetid://7447638591,
assets/terrain/Stud.png) at StudStyle's transparency over it. Shown untinted (Color3 white,
Transparency 0) by Shared/BakedStuds.

  StudGridFloor.png      ground tops: Roblox's Baseplate (assets/terrain/Baseplate.png), 1-stud studs
  StudGridFloorSide.png  ground sides: the 2x2 grid (assets/terrain/Baseplate2x2.png), 1-stud studs
  StudGridWall.png       walls and caps: the 2x2 grid, 2-stud studs (StudStyle TileScale 2)

All 512 px for an 8-stud tile. Re-run (and re-upload) if those transparencies change.
Only the home base wears these (QM, Nov 8); on its ground the whole grid overlay (squares and
lines) is scaled so a dark square darkens the ground by GROUND_DARK (5%).
"""

import os
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
T = os.path.join(HERE, "..", "assets", "terrain")
SIZE, TILE = 512, 8
CHECKER_T = 0.8  # Config.BaseplateTransparency
GROUND_T, WALL_T = 0.5, 0.4  # Config.StudStyle GroundTransparency, Transparency
GROUND_DARK = 0.05  # how much a dark square darkens the home base ground (QM, Nov 8: 5%, was ~9%)


def alpha(path, resample, square=None):
    a = Image.open(path).convert("RGBA").getchannel("A")
    if square is not None:  # (the whole overlay, so the dark squares darken by GROUND_DARK)
        k = GROUND_DARK / (square / 255 * (1 - CHECKER_T))
        a = a.point(lambda v: round(v * k))
    return a.resize((SIZE, SIZE), resample)


def bake(grid, stud_studs, stud_t, out):
    stud = Image.open(os.path.join(T, "Stud.png")).convert("RGBA")
    px = SIZE * stud_studs // TILE
    stud = stud.resize((px, px), Image.LANCZOS)
    sp = stud.load()
    gp = grid.load()
    img = Image.new("RGBA", (SIZE, SIZE))
    op = img.load()
    for y in range(SIZE):
        for x in range(SIZE):
            r, g, b, a = sp[x % px, y % px]
            sa = a / 255 * (1 - stud_t)
            ca = gp[x, y] / 255 * (1 - CHECKER_T)
            oa = sa + ca * (1 - sa)
            if oa <= 0:
                op[x, y] = (0, 0, 0, 0)
                continue
            # (the grid is black: only the stud adds colour)
            c = [v * sa / oa for v in (r, g, b)]
            op[x, y] = (round(c[0]), round(c[1]), round(c[2]), round(oa * 255))
    img.save(os.path.join(T, out))
    print(out, img.getextrema())


# (147 and 217: the dark squares' alpha in Baseplate.png and Baseplate2x2.png)
bake(alpha(os.path.join(T, "Baseplate.png"), Image.LANCZOS, 147), 1, GROUND_T, "StudGridFloor.png")
bake(alpha(os.path.join(T, "Baseplate2x2.png"), Image.NEAREST, 217), 1, GROUND_T, "StudGridFloorSide.png")
bake(alpha(os.path.join(T, "Baseplate2x2.png"), Image.NEAREST), 2, WALL_T, "StudGridWall.png")
