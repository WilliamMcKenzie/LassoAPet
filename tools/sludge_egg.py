"""The Sludge's egg, in take C's style (tools/ocean_eggs.py): the octo shell in the
Sludge's olive (tools/sludge_design.py), a brown nub on top, three black eyes with
yellow under them and a wide black mouth with a yellow lip on the front, and a brown
twig poking out of each side.

Run from the repo root: python3 tools/sludge_egg.py
Writes designs/eggs/c_style/SludgeEgg.bbmodel, src/shared/Eggs/SludgeEggModel.luau,
assets/ui/SludgeEggRender.png and previews in /mnt/project-files/animals/sludge/.
"""

import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import ocean_eggs as O  # noqa: E402
from sludge_design import COLORS  # noqa: E402
from horse_egg_takes import LH, N, WIDTHS, shell  # noqa: E402


def sludge_egg():
    body, light, brown, dark = COLORS["body"], COLORS["light"], COLORS["brown"], COLORS["dark"]
    yellow, black = COLORS["yellow"], COLORS["black"]
    egg = shell([body, body, light, body, light, body, body])
    top = N * LH
    egg.block("Nub", (-0.35, top - 0.05, -0.35), (0.35, top + 0.25, 0.35), brown)

    def front(name, layer, x0, x1, y0, y1, col, out=0.06):
        z = WIDTHS[layer] / 2
        egg.block(name, (x0, y0, -z - out), (x1, y1, -z + 0.05), col)

    # mouth low on the front, eyes above
    y = 2.5 * LH
    front("Mouth", 2, -0.55, 0.55, y - 0.2, y + 0.2, black)
    front("Lip", 2, -0.38, 0.38, y - 0.32, y - 0.2, yellow, 0.09)
    for name, x, layer in (("EyeL", -0.42, 4), ("EyeR", 0.42, 4), ("EyeTop", 0.0, 5)):
        yc = (layer + 0.55) * LH
        front(name, layer, x - 0.12, x + 0.12, yc - 0.12, yc + 0.12, black)
        front(name + "Glint", layer, x - 0.12, x + 0.12, yc - 0.24, yc - 0.12, yellow)
    # a twig out of each side
    for sx in (-1, 1):
        x = WIDTHS[3] / 2
        yc = 3.4 * LH
        lo, hi = sorted((sx * (x - 0.05), sx * (x + 0.3)))
        egg.block("Arm" + str(sx), (lo, yc - 0.08, -0.08), (hi, yc + 0.08, 0.08), brown)
        tx = sx * (x + 0.22)
        egg.block("Twig" + str(sx), (tx - 0.08, yc + 0.08, -0.08), (tx + 0.08, yc + 0.36, 0.08), dark)
    return egg


if __name__ == "__main__":
    O.EGGS = [("Sludge", sludge_egg)]
    O.main("Sludge", preview="/mnt/project-files/animals/sludge")
