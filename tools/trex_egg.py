"""The T-Rex's egg, in take C's style (tools/ocean_eggs.py): the octo shell in the T-Rex's
orange over a cream base, dark brown tiger stripes round the sides and back, a jaw of lilac
teeth meeting at the crack (the top half's teeth hang down, the bottom's stand up), tiny
clawed arms on the sides and a stubby striped tail out the back.

Run from the repo root: python3 tools/trex_egg.py [game]
Preview: TRexEgg.bbmodel/.png in /mnt/project-files/animals/trex/v2; `game` writes the game's
files (ocean_eggs.main: designs/eggs/c_style, Eggs/TRexEggModel.luau, assets/ui render).
"""

import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import ocean_eggs as O  # noqa: E402
import horse_egg_takes as C  # noqa: E402
from horse_egg_takes import CRACK_LAYER, LH, N, WIDTHS, shell  # noqa: E402
from partlib import render  # noqa: E402
from trex_v2 import CLAW, CREAM, ORANGE, STRIPE, TOOTH  # noqa: E402

OUT = "/mnt/project-files/animals/trex/v2"


def faces(w):
    """(a, c): the half width of layer w and its corner cut, as egg_designs.octo_layer."""
    c = round(w / (2 + 2 ** 0.5) / 0.1) * 0.1
    return w / 2, c


def trex_egg():
    egg = shell([CREAM, CREAM, ORANGE, ORANGE, ORANGE, ORANGE, ORANGE])
    # tiger stripes: dashes on both sides and the back of each orange layer, staggered
    for i in range(2, N):
        a, c = faces(WIDTHS[i])
        y0 = i * LH + 0.1
        y1 = y0 + 0.22
        off = 0.18 if i % 2 else -0.18
        for side, sx in (("L", -1), ("R", 1)):
            x0, x1 = sorted((sx * (a - 0.02), sx * (a + 0.07)))
            egg.block(f"Stripe{side}{i}", (x0, y0, off - 0.3), (x1, y1, off + 0.3), STRIPE)
        egg.block(f"StripeB{i}", (-off - 0.28, y0, a - 0.02), (-off + 0.28, y1, a + 0.07), STRIPE)
    a6, _ = faces(WIDTHS[N - 1])
    for k, z in enumerate((-0.25, 0.15)):
        egg.block(f"StripeTop{k}", (-a6 + 0.1, N * LH - 0.02, z), (a6 - 0.1, N * LH + 0.06, z + 0.18), STRIPE)
    # the jaw at the crack: teeth hang from the top half over the bottom half's front, and
    # the bottom's teeth stand up between them
    y = CRACK_LAYER * LH
    zf = -WIDTHS[CRACK_LAYER - 1] / 2
    egg.block("Mouth", (-0.56, y - 0.5, zf - 0.05), (0.56, y - 0.02, zf + 0.02), (110, 36, 40)).bone = "bottom"
    for k, x in enumerate((-0.42, -0.14, 0.14, 0.42)):
        t = egg.block(f"Tooth{k}", (x - 0.1, y - 0.2, zf - 0.08), (x + 0.1, y, zf + 0.02), TOOTH)
        tip = egg.block(f"ToothTip{k}", (x - 0.05, y - 0.32, zf - 0.08), (x + 0.05, y - 0.2, zf + 0.02), TOOTH)
        t.bone = tip.bone = "top"
    for k, x in enumerate((-0.28, 0.0, 0.28)):
        egg.block(f"ToothLow{k}", (x - 0.08, y - 0.5, zf - 0.08), (x + 0.08, y - 0.34, zf + 0.02), TOOTH).bone = "bottom"
    # tiny arms with black claws on the sides, low on the top half
    i = CRACK_LAYER - 1
    a, c = faces(WIDTHS[i])
    for side, sx in (("L", -1), ("R", 1)):
        x0, x1 = sorted((sx * (a - 0.05), sx * (a + 0.22)))
        egg.block("Arm" + side, (x0, i * LH + 0.1, -0.55), (x1, i * LH + 0.32, -0.25), ORANGE)
        x0, x1 = sorted((sx * (a + 0.04), sx * (a + 0.2)))
        egg.block("Claw" + side, (x0, i * LH + 0.04, -0.68), (x1, i * LH + 0.16, -0.55), CLAW)
    # a stubby tail out the back, low, with a stripe
    zb = WIDTHS[2] / 2
    egg.block("Tail", (-0.32, 2 * LH + 0.05, zb - 0.05), (0.32, 2 * LH + 0.4, zb + 0.4), ORANGE)
    egg.block("TailTip", (-0.2, 2 * LH + 0.08, zb + 0.4), (0.2, 2 * LH + 0.3, zb + 0.7), ORANGE)
    egg.block("TailStripe", (-0.34, 2 * LH + 0.04, zb + 0.18), (0.34, 2 * LH + 0.42, zb + 0.28), STRIPE)
    return egg


def main(out=OUT):
    os.makedirs(out, exist_ok=True)
    egg = trex_egg()
    O.build(egg, "TRexEgg", out)
    tile = 420
    sheet = Image.new("RGB", (tile * 2, tile))
    for r, view in enumerate(C.VIEWS):
        sheet.paste(render(egg.parts, W=tile, H=tile, fov=30, **view), (r * tile, 0))
    sheet.save(os.path.join(out, "TRexEgg.png"))
    print(len(egg.parts), "parts")


def game():
    O.EGGS = [("TRex", trex_egg)]
    O.main("TRex", preview=OUT)


if __name__ == "__main__":
    game() if sys.argv[1:2] == ["game"] else main(*sys.argv[1:])
