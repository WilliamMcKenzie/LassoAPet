"""The Ankylosaurus's egg, in take C's style (tools/ocean_eggs.py), like the T-Rex's
(tools/trex_egg.py): the octo shell in mustard over a cream base, brown armour bands right
round the top half, rows of bone-white spikes down both sides, a brown armour cap with spikes
on top, and the club tail out the back.

Run from the repo root: python3 tools/ankylosaurus_egg.py [game]
Preview: AnkylosaurusEgg.bbmodel/.png in /mnt/project-files/animals/ankylosaurus; `game` writes
the game's files (ocean_eggs.main: designs/eggs/c_style, Eggs/AnkylosaurusEggModel.luau, render).
"""

import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import ocean_eggs as O  # noqa: E402
import horse_egg_takes as C  # noqa: E402
from ankylosaurus import BAND, BODY, SPIKE  # noqa: E402
from egg_designs import octo_layer  # noqa: E402
from horse_egg_takes import CRACK_LAYER, LH, N, WIDTHS, shell  # noqa: E402
from partlib import render  # noqa: E402
from trex_egg import faces  # noqa: E402
from trex_v2 import CREAM  # noqa: E402

OUT = "/mnt/project-files/animals/ankylosaurus"


def spike(egg, name, base, axis, sign, w, ln, bone):
    """A stepped spike: two blocks, the outer one smaller, pointing along axis (0 x, 1 y)."""
    for k, (f, d0, d1) in enumerate(((1.0, 0.0, 0.55), (0.5, 0.55, 1.0))):
        lo, hi = list(base), list(base)
        for a in range(3):
            if a == axis:
                lo[a], hi[a] = sorted((base[a] + sign * d0 * ln, base[a] + sign * d1 * ln))
            else:
                lo[a], hi[a] = base[a] - w * f / 2, base[a] + w * f / 2
        egg.block(f"{name}{k}", tuple(lo), tuple(hi), SPIKE).bone = bone


def ankylosaurus_egg():
    egg = shell([CREAM, CREAM, BODY, BODY, BODY, BODY, BODY])
    # armour bands right round two of the top half's layers
    for i in (CRACK_LAYER, CRACK_LAYER + 2):
        y0 = i * LH + 0.12
        octo_layer(egg, f"{i}Band", y0, y0 + 0.24, WIDTHS[i] + 0.12, BAND, "top")
    # spikes down both sides: one per layer, on the side faces
    for i in range(2, N):
        a, c = faces(WIDTHS[i])
        bone = "top" if i >= CRACK_LAYER else "bottom"
        for side, sx in (("L", -1), ("R", 1)):
            for k, z in enumerate((-0.3, 0.3)):
                spike(egg, f"Spike{side}{i}{k}", (sx * a, i * LH + LH / 2, z), 0, sx, 0.2, 0.3, bone)
    # an armour cap on top with a ring of spikes
    top = N * LH
    a6, c6 = faces(WIDTHS[N - 1])
    egg.block("Cap", (-a6 + 0.1, top - 0.02, -a6 + 0.1), (a6 - 0.1, top + 0.14, a6 - 0.1), BAND).bone = "top"
    for k, (x, z) in enumerate(((-0.3, -0.3), (0.3, -0.3), (-0.3, 0.3), (0.3, 0.3))):
        spike(egg, f"CapSpike{k}", (x, top + 0.14, z), 1, 1, 0.22, 0.32, "top")
    # the club tail out the back, low on the bottom half
    zb = WIDTHS[2] / 2
    egg.block("Tail", (-0.22, 2 * LH + 0.08, zb - 0.05), (0.22, 2 * LH + 0.34, zb + 0.55), BODY)
    egg.block("Club", (-0.42, 2 * LH - 0.02, zb + 0.55), (0.42, 2 * LH + 0.44, zb + 0.95), BAND)
    for side, sx in (("L", -1), ("R", 1)):
        spike(egg, "ClubKnob" + side, (sx * 0.42, 2 * LH + 0.21, zb + 0.75), 0, sx, 0.18, 0.2, "bottom")
    return egg


def main(out=OUT):
    os.makedirs(out, exist_ok=True)
    egg = ankylosaurus_egg()
    O.build(egg, "AnkylosaurusEgg", out)
    tile = 420
    sheet = Image.new("RGB", (tile * 2, tile))
    for r, view in enumerate(C.VIEWS):
        sheet.paste(render(egg.parts, W=tile, H=tile, fov=30, **view), (r * tile, 0))
    sheet.save(os.path.join(out, "AnkylosaurusEgg.png"))
    print(len(egg.parts), "parts")


def game():
    O.EGGS = [("Ankylosaurus", ankylosaurus_egg)]
    O.main("Ankylosaurus", preview=OUT)


if __name__ == "__main__":
    game() if sys.argv[1:2] == ["game"] else main(*sys.argv[1:])
