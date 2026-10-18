"""Eggs for World 3's Candyland animals (Oct 14), in take C's style (tools/ocean_eggs.py): the
octo shell in each animal's colours with one or two signature candy details on top or down the
front, no faces, each well under 150 parts.

Run from the repo root: python3 tools/candy_eggs.py [Kind ...]
Writes designs/eggs/c_style/<Kind>Egg.bbmodel, src/shared/Eggs/<Kind>EggModel.luau,
assets/ui/<Kind>EggRender.png and previews in /mnt/project-files/world3/candyland/eggs/.
"""

import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import candy_common as C  # noqa: E402
import ocean_eggs as O  # noqa: E402
from horse_egg_takes import LH, N, WIDTHS, shell  # noqa: E402
from crystal_elephant_egg import point, shard  # noqa: E402

TOP = N * LH


def zf(i, d=0.0):
    """The front face (-z) of layer i, pushed out by d."""
    return -WIDTHS[i] / 2 - d


def on_top(egg, k):
    for p in egg.parts[-k:]:
        p.bone = "top"


def front_dot(egg, name, x, layer, y, r, color, d=0.06):
    egg.block(name, (x - r, y - r, zf(layer, d)), (x + r, y + r, zf(layer, -0.04)), color)


def gummy_bear(body=C.CHERRY, dark=C.CHERRY_DK, belly=C.STRAWB):
    egg = shell([dark, belly, body, body, body, body, body])
    for s in (-1, 1):  # round bear ears on top
        x = s * 0.42
        egg.block(f"Ear{'LR'[s > 0]}", (x - 0.28, TOP - 0.1, -0.15), (x + 0.28, TOP + 0.35, 0.15), body)
        egg.block(f"EarTop{'LR'[s > 0]}", (x - 0.18, TOP + 0.35, -0.12), (x + 0.18, TOP + 0.45, 0.12), body)
    on_top(egg, 4)
    return egg


def yellow_gummy_bear():
    """The Gummy Bear's egg in the Yellow Gummy Bear's lemon (QM, Oct 15)."""
    return gummy_bear((250, 196, 28), (206, 142, 12), (255, 226, 92))


def green_gummy_bear():
    """The Gummy Bear's egg in the Green Gummy Bear's lime (QM, Oct 15)."""
    return gummy_bear((58, 184, 58), (28, 124, 40), (132, 224, 88))


def gumdrop_frog():
    egg = shell([C.ORANGE_DK, C.ORANGE, C.ORANGE, C.ORANGE, C.ORANGE, C.ORANGE, C.ORANGE])
    for s in (-1, 1):  # eye bumps on top
        x = s * 0.3
        egg.block(f"Bump{'LR'[s > 0]}", (x - 0.24, TOP - 0.1, -0.35), (x + 0.24, TOP + 0.3, 0.05), C.ORANGE)
    on_top(egg, 2)
    sugar = [(-0.5, 1, 0.65), (0.45, 2, 1.1), (-0.2, 3, 1.55), (0.55, 4, 2.0), (-0.6, 4, 2.15), (0.1, 5, 2.5)]
    for i, (x, layer, y) in enumerate(sugar):
        front_dot(egg, f"Sugar{i}", x, layer, y, 0.08, C.WHITE)
    return egg


def gingerbread_man():
    egg = shell([C.GINGER_DK, C.GINGER, C.GINGER, C.GINGER, C.GINGER, C.GINGER, C.GINGER])
    for i, (y, col) in enumerate(((2.15, C.CHERRY), (1.65, C.LIME), (1.15, C.LEMON))):
        layer = int(y / LH)
        front_dot(egg, f"Button{i}", 0, layer, y, 0.14, col, 0.1)
    for i in range(5):  # a wavy icing band across the front of layer 1
        x = -0.6 + 0.3 * i
        y = 0.62 + (0.06 if i % 2 else 0)
        egg.block(f"Icing{i}", (x - 0.13, y, zf(1, 0.06)), (x + 0.13, y + 0.1, zf(1, -0.04)), C.ICING)
    for i in range(3):  # and round the top
        x = -0.3 + 0.3 * i
        y = 2.85 + (0.06 if i % 2 else 0)
        egg.block(f"IcingTop{i}", (x - 0.13, y, zf(6, 0.06)), (x + 0.13, y + 0.1, zf(6, -0.04)), C.ICING)
    return egg


def creampuff():
    egg = shell([C.PASTRY_DK, C.PASTRY, C.PASTRY, C.WHITE, C.PASTRY, C.PASTRY, C.PASTRY])
    for i, x in enumerate((-0.6, 0.1, 0.7)):  # cream drips
        egg.block(f"Drip{i}", (x - 0.12, 3 * LH - 0.22, zf(2, 0.04)), (x + 0.12, 3 * LH, zf(2, -0.04)), C.WHITE)
    egg.block("Cherry", (-0.22, TOP - 0.05, -0.22), (0.22, TOP + 0.38, 0.22), C.CHERRY)
    egg.block("Stem", (0.0, TOP + 0.38, -0.03), (0.06, TOP + 0.62, 0.03), C.LIME_DK)
    on_top(egg, 2)
    return egg


def swoll_fairy():
    egg = shell([C.MINT_DK, C.BUBBLE, C.LILAC, C.MINT, C.MINT, C.BUBBLE, C.BUBBLE])
    for s in (-1, 1):  # little candy-glass wings on the sides
        w = WIDTHS[4] / 2
        xa, xb = sorted((s * w, s * (w + 0.5)))
        egg.block(f"Wing{'LR'[s > 0]}", (xa, 1.9, 0.05), (xb, 2.6, 0.2), C.SKY)
        xc, xd = sorted((s * w, s * (w + 0.32)))
        egg.block(f"WingLow{'LR'[s > 0]}", (xc, 1.5, 0.05), (xd, 1.9, 0.2), C.LILAC)
    egg.block("Bun", (-0.25, TOP - 0.05, -0.2), (0.25, TOP + 0.3, 0.25), C.GRAPE)
    egg.block("Bow", (-0.35, TOP + 0.05, 0.25), (0.35, TOP + 0.25, 0.35), C.CHERRY)
    on_top(egg, 2)
    return egg


def desire_troll():
    egg = shell([C.STRAWB_DK, C.STRAWB, C.STRAWB, C.STRAWB, C.STRAWB, C.STRAWB, C.STRAWB])
    for s in (-1, 1):  # candy-corn tusks up the front
        x = s * 0.5
        z0, z1 = zf(2, 0.14), zf(2, -0.08)
        egg.block(f"TuskW{'LR'[s > 0]}", (x - 0.12, 0.9, z0), (x + 0.12, 1.1, z1), C.WHITE)
        egg.block(f"TuskO{'LR'[s > 0]}", (x - 0.12, 1.1, z0), (x + 0.12, 1.3, z1), C.ORANGE)
        point(egg, f"TuskY{'LR'[s > 0]}", (x, 1.3, (z0 + z1) / 2), (0, 1, 0), 0.12, 0.3, C.LEMON)
    egg.block("Hair", (-0.4, TOP - 0.05, -0.3), (0.3, TOP + 0.3, 0.3), C.LILAC)
    egg.block("HairPuff", (-0.1, TOP + 0.3, -0.2), (0.35, TOP + 0.5, 0.2), C.SKY)
    on_top(egg, 2)
    return egg


def rock_candy_dragon():
    egg = shell([C.CHERRY_DK, C.CHERRY, C.CHERRY, C.CHERRY, C.CHERRY, C.CHERRY, C.CHERRY])
    for i, (x, z, h, col) in enumerate(((0, 0, 0.6, C.LEMON), (-0.3, 0.2, 0.4, C.SKY), (0.3, 0.15, 0.45, C.LIME))):
        shard(egg, f"Crystal{i}", (x, TOP - 0.1, z), (0, 1, 0), 0.13, h, 0.3, col, "top")
    for i, (layer, col) in enumerate(((2, C.GRAPE), (3, C.MINT), (4, C.BUBBLE))):  # rainbow crystals down the back
        shard(egg, f"Spine{i}", (0, layer * LH + LH / 2, WIDTHS[layer] / 2 - 0.05), (0, 0.4, 1), 0.1, 0.1, 0.25, col)
    return egg


def gumball_golem():
    egg = shell([C.CHERRY_DK, C.CHERRY, C.CHERRY, (172, 220, 245), (172, 220, 245), (172, 220, 245), (172, 220, 245)])
    balls = [(-0.55, 3, C.LEMON), (0.0, 3, C.GRAPE), (0.55, 3, C.LIME), (-0.4, 4, C.ORANGE), (0.35, 4, C.CHERRY),
             (-0.1, 5, C.BUBBLE), (0.0, 6, C.SKY)]
    for i, (x, layer, col) in enumerate(balls):
        front_dot(egg, f"Gumball{i}", x, layer, layer * LH + LH / 2, 0.14, col, 0.08)
    egg.block("CoinPlate", (-0.25, 0.55, zf(1, 0.06)), (0.25, 1.05, zf(1, -0.04)), (200, 206, 216))
    egg.block("Cap", (-0.35, TOP - 0.05, -0.35), (0.35, TOP + 0.2, 0.35), (200, 206, 216))
    egg.block("CapKnob", (-0.12, TOP + 0.2, -0.12), (0.12, TOP + 0.35, 0.12), C.CHERRY)
    on_top(egg, 2)
    return egg


def gigacorn():
    egg = shell([C.LILAC, C.WHITE, C.WHITE, C.WHITE, C.WHITE, C.WHITE, C.WHITE])
    for i, col in enumerate((C.CHERRY, C.WHITE, C.CHERRY, C.WHITE)):  # the candy-cane horn
        w = 0.17 - 0.025 * i
        egg.block(f"Horn{i}", (-w, TOP - 0.05 + 0.18 * i, -0.3 - w), (w, TOP + 0.13 + 0.18 * i, -0.3 + w), col)
    point(egg, "GlowHornTip", (0, TOP + 0.67, -0.3), (0, 1, 0), 0.08, 0.3, C.STRAWB, "top")
    on_top(egg, 5)
    for i, (layer, col) in enumerate(((6, C.BUBBLE), (5, C.SKY), (4, C.LILAC), (3, C.BUBBLE), (2, C.SKY))):
        zb = WIDTHS[layer] / 2
        egg.block(f"Mane{i}", (-0.22, layer * LH, zb - 0.05), (0.22, (layer + 1) * LH, zb + 0.14), col)
    return egg


O.EGGS = [("GummyBear", gummy_bear), ("YellowGummyBear", yellow_gummy_bear), ("GreenGummyBear", green_gummy_bear), ("GumdropFrog", gumdrop_frog), ("GingerbreadMan", gingerbread_man),
          ("Creampuff", creampuff), ("SwollFairy", swoll_fairy), ("DesireTroll", desire_troll),
          ("RockCandyDragon", rock_candy_dragon), ("GumballGolem", gumball_golem), ("Gigacorn", gigacorn)]

if __name__ == "__main__":
    O.main(*sys.argv[1:], preview="/mnt/project-files/world3/candyland/eggs")
