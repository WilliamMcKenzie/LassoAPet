"""The Lava Whale's egg: the Whale's egg (ocean_eggs.whale_egg: grooved pale base, spiral
glyph on the front, dashes down the top, little flukes) in the Lava Whale's rock and ash,
the glyph and dashes glowing lava, and its banded unicorn horn on top.

Run from the repo root: python3 tools/lava_whale_egg.py [game]
Writes LavaWhaleEgg.bbmodel and LavaWhaleEgg.png to /mnt/project-files/animals/lavawhale;
`game` writes the game's files (ocean_eggs.main).
"""

import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import ocean_eggs as O  # noqa: E402
import horse_egg_takes as C  # noqa: E402
from horse_egg_takes import H  # noqa: E402
from partlib import render  # noqa: E402

OUT = "/mnt/project-files/animals/lavawhale"
ROCK, DEEP, ASH, GROOVE, LAVA = (182, 100, 62), (136, 74, 50), (246, 196, 140), (216, 156, 104), (255, 140, 30)
SWAP = {(40, 116, 206): ROCK, (26, 78, 158): DEEP, (214, 244, 250): ASH, (150, 210, 232): GROOVE, (96, 226, 246): LAVA}


def lava_whale_egg():
    egg = O.whale_egg()
    for p in egg.parts:
        c = tuple(p.color)
        if c in SWAP:
            p.color = SWAP[c]
        if c == (96, 226, 246):
            p.name = "Glow" + p.name
    # the unicorn horn: rings stepping up and forward, rock and lava, a glowing tip
    rings = (0.3, 0.25, 0.2, 0.15, 0.1)
    for i, hw in enumerate(rings):
        y, dz = H + i * 0.22, -0.05 * i
        glows = i % 2 or i == len(rings) - 1
        egg.block(f"{'Glow' if glows else ''}Horn{i}", (-hw, y, dz - hw), (hw, y + 0.22, dz + hw), LAVA if glows else DEEP)
    return egg


def main(out=OUT):
    os.makedirs(out, exist_ok=True)
    egg = lava_whale_egg()
    O.build(egg, "LavaWhaleEgg", out)
    for p in egg.parts:
        if p.name.startswith("Glow"):
            p.neon = True
    tile = 420
    sheet = Image.new("RGB", (tile * 2, tile))
    for r, view in enumerate(C.VIEWS):
        sheet.paste(render(egg.parts, W=tile, H=tile, fov=30, **view), (r * tile, 0))
    sheet.save(os.path.join(out, "LavaWhaleEgg.png"))
    print(len(egg.parts), "parts")


def game():
    O.EGGS = [("LavaWhale", lava_whale_egg)]
    O.main("LavaWhale", preview=OUT)


if __name__ == "__main__":
    game() if sys.argv[1:2] == ["game"] else main(*sys.argv[1:])
