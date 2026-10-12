"""The Velociraptor's egg, in take C's style (tools/ocean_eggs.py), a smaller sibling of the
T-Rex's (tools/trex_egg.py): the octo shell in the raptor's blue over a cream base, navy stripe
dashes round the sides and back, a toothy grin at the crack, an orange feather crest on top,
little feathered arms with black claws, a black sickle claw low on each side and a long tail
with an orange feather tip.

Run from the repo root: python3 tools/raptor_egg.py [game]
Preview: RaptorEgg.bbmodel/.png in /mnt/project-files/animals/raptor; `game` writes the game's
files (ocean_eggs.main: designs/eggs/c_style, Eggs/RaptorEggModel.luau, assets/ui render).
"""

import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import ocean_eggs as O  # noqa: E402
import horse_egg_takes as C  # noqa: E402
from horse_egg_takes import CRACK_LAYER, LH, N, WIDTHS, shell  # noqa: E402
from partlib import render  # noqa: E402
from raptor_design import BLUE, FEATHER, STRIPE  # noqa: E402
from trex_egg import faces  # noqa: E402
from trex_v2 import CLAW, CREAM, TOOTH  # noqa: E402

OUT = "/mnt/project-files/animals/raptor"


def raptor_egg():
    egg = shell([CREAM, CREAM, BLUE, BLUE, BLUE, BLUE, BLUE])
    # navy stripe dashes on both sides and the back of each blue layer, staggered
    for i in range(2, N):
        a, c = faces(WIDTHS[i])
        y0 = i * LH + 0.12
        y1 = y0 + 0.18
        off = 0.18 if i % 2 else -0.18
        for side, sx in (("L", -1), ("R", 1)):
            x0, x1 = sorted((sx * (a - 0.02), sx * (a + 0.07)))
            egg.block(f"Stripe{side}{i}", (x0, y0, off - 0.26), (x1, y1, off + 0.26), STRIPE)
        egg.block(f"StripeB{i}", (-off - 0.24, y0, a - 0.02), (-off + 0.24, y1, a + 0.07), STRIPE)
    # an orange feather crest running front to back over the top
    top = N * LH
    for k, (z, h) in enumerate(((-0.35, 0.22), (-0.05, 0.34), (0.25, 0.26))):
        egg.block(f"Crest{k}", (-0.1, top - 0.04, z - 0.13), (0.1, top + h, z + 0.13), FEATHER)
    # the grin at the crack: a row of small sharp teeth on each lip
    y = CRACK_LAYER * LH
    zf = -WIDTHS[CRACK_LAYER - 1] / 2
    egg.block("Mouth", (-0.62, y - 0.36, zf - 0.05), (0.62, y - 0.02, zf + 0.02), (110, 36, 40)).bone = "bottom"
    for k, x in enumerate((-0.48, -0.24, 0.0, 0.24, 0.48)):
        egg.block(f"Tooth{k}", (x - 0.06, y - 0.16, zf - 0.08), (x + 0.06, y, zf + 0.02), TOOTH).bone = "top"
    for k, x in enumerate((-0.36, -0.12, 0.12, 0.36)):
        egg.block(f"ToothLow{k}", (x - 0.05, y - 0.36, zf - 0.08), (x + 0.05, y - 0.22, zf + 0.02), TOOTH).bone = "bottom"
    # little arms with an orange feather and black claws, on the top half's lowest layer
    i = CRACK_LAYER
    a, c = faces(WIDTHS[i])
    for side, sx in (("L", -1), ("R", 1)):
        x0, x1 = sorted((sx * (a - 0.05), sx * (a + 0.24)))
        egg.block("Arm" + side, (x0, i * LH + 0.1, -0.5), (x1, i * LH + 0.28, -0.22), BLUE).bone = "top"
        x0, x1 = sorted((sx * (a + 0.02), sx * (a + 0.12)))
        egg.block("ArmFeather" + side, (x0, i * LH + 0.24, -0.4), (x1, i * LH + 0.46, -0.1), FEATHER).bone = "top"
        x0, x1 = sorted((sx * (a + 0.06), sx * (a + 0.22)))
        egg.block("Claw" + side, (x0, i * LH + 0.02, -0.62), (x1, i * LH + 0.14, -0.5), CLAW).bone = "top"
    # a black sickle claw low on each side, curling up
    a, c = faces(WIDTHS[1])
    for side, sx in (("L", -1), ("R", 1)):
        x0, x1 = sorted((sx * (a - 0.03), sx * (a + 0.1)))
        egg.block("Sickle" + side, (x0, LH + 0.05, -0.32), (x1, LH + 0.2, -0.08), CLAW)
        egg.block("SickleTip" + side, (x0, LH + 0.2, -0.36), (x1, LH + 0.38, -0.24), CLAW)
    # a long tail out the back with a stripe and an orange feather tip
    zb = WIDTHS[2] / 2
    egg.block("Tail", (-0.24, 2 * LH + 0.08, zb - 0.05), (0.24, 2 * LH + 0.36, zb + 0.6), BLUE)
    egg.block("TailStripe", (-0.26, 2 * LH + 0.06, zb + 0.24), (0.26, 2 * LH + 0.38, zb + 0.34), STRIPE)
    egg.block("TailFeather", (-0.3, 2 * LH + 0.1, zb + 0.6), (0.3, 2 * LH + 0.34, zb + 0.95), FEATHER)
    return egg


def main(out=OUT):
    os.makedirs(out, exist_ok=True)
    egg = raptor_egg()
    O.build(egg, "RaptorEgg", out)
    tile = 420
    sheet = Image.new("RGB", (tile * 2, tile))
    for r, view in enumerate(C.VIEWS):
        sheet.paste(render(egg.parts, W=tile, H=tile, fov=30, **view), (r * tile, 0))
    sheet.save(os.path.join(out, "RaptorEgg.png"))
    print(len(egg.parts), "parts")


def game():
    O.EGGS = [("Raptor", raptor_egg)]
    O.main("Raptor", preview=OUT)


if __name__ == "__main__":
    game() if sys.argv[1:2] == ["game"] else main(*sys.argv[1:])
