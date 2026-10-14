"""The Volcano Tortoise's egg, in take C's style (tools/ocean_eggs.py): the octo shell
in the tortoise's colours (QM's palette: tan skin at the bottom, the dark shell rim,
then the reddish brown shell) with a little stepped stone volcano on top, its crater
and drips glowing lava (Glow parts are Neon in game).

Run from the repo root: python3 tools/tortoise_egg.py [out_dir]
Writes VolcanoTortoiseEgg.bbmodel and VolcanoTortoiseEgg.png to out_dir only (not in game yet).
"""

import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import ocean_eggs as O  # noqa: E402
import horse_egg_takes as C  # noqa: E402
from horse_egg_takes import H, LH, shell  # noqa: E402
from partlib import render  # noqa: E402

OUT = "/mnt/project-files/animals/tortoise"
SKIN, RIM, SHELL, SHELL_TOP = (178, 150, 102), (92, 50, 36), (122, 66, 44), (118, 78, 62)
ROCK, ROCK_DARK = (112, 96, 90), (92, 78, 74)
LAVA, LAVA_HOT = (255, 116, 24), (255, 186, 60)


def tortoise_egg():
    # the top two layers are the volcano's stone: the egg is a little volcano
    egg = shell([SKIN, SKIN, RIM, SHELL, SHELL, ROCK, ROCK_DARK])
    top = H
    # glowing lava ring round a hot crater on the very top
    for i, (lo, hi) in enumerate((((-0.42, -0.42), (0.42, -0.2)), ((-0.42, 0.2), (0.42, 0.42)),
                                  ((-0.42, -0.2), (-0.2, 0.2)), ((0.2, -0.2), (0.42, 0.2)))):
        egg.block(f"GlowRim{i}", (lo[0], top - 0.02, lo[1]), (hi[0], top + 0.1, hi[1]), LAVA)
    egg.block("GlowCrater", (-0.2, top - 0.04, -0.2), (0.2, top + 0.04, 0.2), LAVA_HOT)
    # lava running down the stone layers on all four faces (u along the face, how far down)
    y5, y6 = 5 * LH, 6 * LH  # the stone layers' bottoms
    for i, (face, u, down) in enumerate((("F", -0.05, 0.25), ("B", 0.1, 0.18), ("L", 0.08, 0.3), ("R", -0.1, 0.12))):
        for j, (half, y0, y1) in enumerate(((0.5, y6 + 0.12, top), (0.9, y5 + down, y6 + 0.04))):
            lo, hi = (u - 0.09, y0, -half - 0.03), (u + 0.09, y1, -half + 0.02)
            if j == 1:  # across the ledge between the two layers
                ledge = ((u - 0.09, y6, -0.9), (u + 0.09, y6 + 0.04, -0.48))
            else:
                ledge = None
            for k, (a, b) in enumerate([(lo, hi)] + ([ledge] if ledge else [])):
                egg.block(f"GlowDrip{i}{j}{k}", *turn(face, a, b), LAVA)
    return egg


def turn(face, lo, hi):
    """A box drawn on the front (-z) face, turned onto face F, B, L or R."""
    (x0, y0, z0), (x1, y1, z1) = lo, hi
    if face == "F":
        return (x0, y0, z0), (x1, y1, z1)
    if face == "B":
        return (x0, y0, -z1), (x1, y1, -z0)
    if face == "L":
        return (z0, y0, x0), (z1, y1, x1)
    return (-z1, y0, x0), (-z0, y1, x1)


def main(out=OUT):
    os.makedirs(out, exist_ok=True)
    egg = tortoise_egg()
    O.build(egg, "VolcanoTortoiseEgg", out)
    for p in egg.parts:
        if p.name.startswith("Glow"):
            p.neon = True
    tile = 420
    sheet = Image.new("RGB", (tile * 2, tile))
    for r, view in enumerate(C.VIEWS):
        sheet.paste(render(egg.parts, W=tile, H=tile, fov=28, **view), (r * tile, 0))
    sheet.save(os.path.join(out, "VolcanoTortoiseEgg.png"))
    print(len(egg.parts), "parts")


def game():
    """Into the game: designs/eggs/c_style/VolcanoTortoiseEgg.bbmodel, its Luau model and
    assets/ui/VolcanoTortoiseEggRender.png (ocean_eggs.main)."""
    O.EGGS = [("VolcanoTortoise", tortoise_egg)]
    O.main("VolcanoTortoise", preview=OUT)


if __name__ == "__main__":
    if sys.argv[1:2] == ["game"]:
        game()
    else:
        main(*sys.argv[1:])
