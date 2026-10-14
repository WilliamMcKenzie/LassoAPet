"""Eggs for World 3's Pirate Cove animals (Oct 14), in take C's style (tools/ocean_eggs.py): the octo
shell in each animal's colours with one or two signature details, each well under 150 parts.

Run from the repo root: python3 tools/pirate_eggs.py [Kind ...]
Writes designs/eggs/c_style/<Kind>Egg.bbmodel, src/shared/Eggs/<Kind>EggModel.luau,
assets/ui/<Kind>EggRender.png and previews in /mnt/project-files/world3/pirate_cove/eggs/.
"""

import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import ocean_eggs as O  # noqa: E402
from egg_designs import octo_layer  # noqa: E402
from horse_egg_takes import LH, N, WIDTHS, shell  # noqa: E402
from crystal_elephant_egg import point  # noqa: E402

TOP = N * LH
WHITE, BLACK, PUPIL = (255, 255, 255), (34, 30, 40), (22, 20, 30)
GOLD, GOLDD = (255, 196, 36), (206, 140, 22)


def zf(i, d=0.0):
    """The front face (-z) of layer i, pushed out by d."""
    return -WIDTHS[i] / 2 - d


def glow(egg):
    for p in egg.parts:
        if p.name.startswith("Glow"):
            p.plain = True
            p.neon = True
    return egg


def googly(egg, name, x, y, z, r=0.2):
    egg.block(name, (x - r, y - r, z - 0.04), (x + r, y + r, z + 0.02), WHITE)
    egg.block(name + "Pupil", (x - r * 0.5, y - r * 0.6, z - 0.07), (x + r * 0.5, y + r * 0.4, z - 0.03), PUPIL)


def tricorn(egg, name, hat=BLACK, trim=GOLD, w=1.1):
    """A little black tricorn on the egg's top with gold trim and a white skull on the front."""
    t = TOP - 0.05
    egg.block(name + "Brim", (-w, t, -w * 0.85), (w, t + 0.12, w * 0.85), hat)
    egg.block(name + "Crown", (-w * 0.6, t + 0.12, -w * 0.5), (w * 0.6, t + 0.6, w * 0.55), hat)
    egg.block(name + "Band", (-w * 0.62, t + 0.12, -w * 0.52), (w * 0.62, t + 0.24, w * 0.57), trim)
    egg.block(name + "Front", (-w * 0.8, t + 0.12, -w * 0.85), (w * 0.8, t + 0.55, -w * 0.72), hat)
    egg.block(name + "Skull", (-0.14, t + 0.25, -w * 0.88), (0.14, t + 0.48, -w * 0.84), WHITE)
    for s in (-1, 1):
        xa, xb = sorted((s * w * 0.95, s * w * 0.8))
        egg.block(name + "Side" + "LR"[s > 0], (xa, t + 0.12, -w * 0.7), (xb, t + 0.5, w * 0.7), hat)
    for p in egg.parts[-7:]:
        p.bone = "top"


def red_crab():
    R, RD, CR, OR, TIP = (232, 52, 40), (170, 28, 30), (255, 226, 176), (255, 128, 40), (40, 30, 36)
    egg = shell([CR, CR, R, R, R, R, RD])
    for i, (x, y) in enumerate(((-0.5, 2.6), (0.6, 2.2), (0.0, 1.5))):
        egg.block(f"Speck{i}", (x - 0.12, y - 0.12, zf(int(y / LH), 0.03)), (x + 0.12, y + 0.12, zf(int(y / LH), -0.02)), OR)
    for s in (-1, 1):
        n = "LR"[s > 0]
        x = s * 0.35
        egg.block(f"Stalk{n}", (x - 0.06, TOP - 0.05, -0.1), (x + 0.06, TOP + 0.35, 0.02), R).bone = "top"
        egg.block(f"EyeBall{n}", (x - 0.18, TOP + 0.3, -0.2), (x + 0.18, TOP + 0.66, 0.16), R).bone = "top"
        googly(egg, f"Eye{n}", x, TOP + 0.48, -0.2, 0.14)
        # claws on the sides: a red block with a dark pyramid tip
        w = WIDTHS[2] / 2
        xa, xb = sorted((s * w, s * (w + 0.35)))
        egg.block(f"Claw{n}", (xa, 1.0, -0.45), (xb, 1.4, 0.0), R)
        point(egg, f"ClawTip{n}", (s * (w + 0.17), 1.2, -0.45), (0, 0, -1), 0.14, 0.3, TIP)
    for p in egg.parts:
        if p.name.startswith(("Eye", "Stalk")):
            p.bone = "top"
    return egg


def parrot():
    R, RD, Y, B = (232, 36, 44), (168, 20, 36), (255, 206, 30), (36, 112, 236)
    egg = shell([B, B, Y, R, R, R, R])
    tricorn(egg, "Hat", w=0.85)
    point(egg, "Beak", (0, 2.4, zf(5) + 0.05), (0, -0.5, -1), 0.16, 0.35, (250, 236, 200), "top")
    for s in (-1, 1):
        n = "LR"[s > 0]
        googly(egg, f"Eye{n}", s * 0.32, 2.75, zf(6) - 0.02, 0.13)
        w = WIDTHS[3] / 2
        xa, xb = sorted((s * w, s * (w + 0.18)))
        egg.block(f"Wing{n}", (xa, 0.9, -0.5), (xb, 1.7, 0.6), B)
        egg.block(f"WingBand{n}", (xa, 1.5, -0.52), (xb, 1.7, 0.62), Y)
    for p in egg.parts:
        if p.name.startswith("Eye"):
            p.bone = "top"
    return egg


def banana_monkey():
    F, FD, T, RED, BAN, ST = (140, 82, 44), (96, 54, 30), (246, 200, 150), (232, 40, 48), (255, 222, 40), (90, 64, 30)
    egg = shell([FD, F, F, F, F, RED, RED])
    # the face: a tan patch on the front with plate eyes and a grin
    z = zf(3, 0.02)
    egg.block("Face", (-0.6, 1.0, z), (0.6, 2.2, z + 0.05), T)
    googly(egg, "EyeL", -0.27, 1.9, z - 0.01, 0.15)
    googly(egg, "EyeR", 0.27, 1.9, z - 0.01, 0.15)
    egg.block("Mouth", (-0.3, 1.25, z - 0.03), (0.3, 1.38, z + 0.01), (120, 30, 40))
    for i, x in enumerate((-0.3, 0.35)):
        egg.block(f"Dot{i}", (x - 0.08, 2.7, zf(5, 0.03)), (x + 0.08, 2.86, zf(5, -0.01)), WHITE)
    # a banana lying across the top, stem up
    egg.block("Banana", (-0.6, TOP, -0.12), (0.6, TOP + 0.24, 0.12), BAN).bone = "top"
    egg.block("BananaL", (-0.85, TOP + 0.12, -0.1), (-0.55, TOP + 0.34, 0.1), BAN).bone = "top"
    egg.block("BananaR", (0.55, TOP + 0.12, -0.1), (0.85, TOP + 0.34, 0.1), BAN).bone = "top"
    egg.block("Stem", (0.82, TOP + 0.3, -0.05), (0.92, TOP + 0.45, 0.05), ST).bone = "top"
    return egg


def treasure_hermit():
    W, WD, P = (170, 98, 46), (110, 60, 30), (160, 70, 220)
    egg = shell([WD, W, W, W, W, W, W])
    # two gold straps over the top and a gold lock on the front
    for s in (-1, 1):
        x = s * 0.45
        for i in range(N):
            z = WIDTHS[i] / 2
            egg.block(f"Strap{'LR'[s > 0]}{i}", (x - 0.1, i * LH, -z - 0.04), (x + 0.1, (i + 1) * LH, -z + 0.02), GOLD)
    egg.block("Lock", (-0.18, 2.0, zf(4, 0.06)), (0.18, 2.4, zf(4, -0.02)), GOLD)
    egg.block("Keyhole", (-0.05, 2.12, zf(4, 0.08)), (0.05, 2.28, zf(4, 0.05)), BLACK)
    egg.block("Glow_Ruby", (-0.14, TOP, -0.14), (0.14, TOP + 0.28, 0.14), (255, 40, 80)).bone = "top"
    # a purple claw poking out of the side
    w = WIDTHS[1] / 2
    egg.block("Claw", (w - 0.05, 0.4, -0.5), (w + 0.4, 0.8, -0.05), P)
    point(egg, "ClawTip", (w + 0.18, 0.6, -0.5), (0, 0, -1), 0.15, 0.3, (40, 30, 50))
    return glow(egg)


def eyepatch_shark():
    S, SD, BE, RED = (40, 150, 255), (26, 96, 200), (30, 92, 196), (232, 36, 48)
    egg = shell([BE, BE, S, S, S, S, S])
    point(egg, "Dorsal", (0, TOP - 0.05, 0.1), (0, 1, 0.5), 0.16, 0.7, S, "top")
    # a grin of pyramid teeth hanging along the front
    z = zf(2, 0.02)
    egg.block("Mouth", (-0.6, 0.85, z), (0.6, 1.1, z + 0.04), (196, 36, 64))
    for i, x in enumerate((-0.45, -0.15, 0.15, 0.45)):
        point(egg, f"Tooth{i}", (x, 1.1, z - 0.01), (0, -1, 0), 0.07, 0.18, WHITE, "bottom")
    googly(egg, "EyeL", -0.35, 2.05, zf(4) - 0.02, 0.16)
    egg.block("Patch", (0.17, 1.88, zf(4, 0.04)), (0.53, 2.24, zf(4, -0.01)), BLACK)
    egg.block("Strap", (-0.7, 2.28, zf(4, 0.03)), (0.7, 2.36, zf(4, -0.01)), BLACK)
    egg.block("Bandana", (-WIDTHS[5] / 2 - 0.03, 5 * LH, -0.4), (WIDTHS[5] / 2 + 0.03, 5 * LH + 0.22, 0.4), RED)
    return egg


def treasure_turtle():
    G, GD, SK, SAND = (60, 150, 60), (34, 100, 44), (52, 196, 172), (250, 222, 150)
    egg = shell([SK, GD, G, G, G, GD, SAND])
    for i, (x, y) in enumerate(((-0.5, 1.4), (0.5, 1.4), (0.0, 2.1))):
        egg.block(f"Scute{i}", (x - 0.16, y - 0.16, zf(int(y / LH), 0.03)), (x + 0.16, y + 0.16, zf(int(y / LH), -0.01)), GOLD)
    # a tiny palm on top
    egg.block("Trunk", (-0.07, TOP, -0.07), (0.07, TOP + 0.7, 0.07), (150, 98, 52)).bone = "top"
    for i, d in enumerate(((1, 0), (-1, 0), (0, 1), (0, -1))):
        point(egg, f"Frond{i}", (0, TOP + 0.7, 0), (d[0], -0.2, d[1]), 0.1, 0.45, (60, 210, 70), "top")
    return egg


def ghost_ship():
    H, HD, SAIL = (124, 66, 170), (78, 38, 114), (110, 255, 226)
    egg = shell([HD, H, H, H, H, H, HD])
    octo_layer(egg, "Rail", 3 * LH - 0.06, 3 * LH + 0.06, WIDTHS[3] + 0.1, GOLD, "bottom")
    egg.block("Mast", (-0.05, TOP - 0.05, -0.05), (0.05, TOP + 1.0, 0.05), (120, 78, 46)).bone = "top"
    egg.block("Glow_Sail", (-0.4, TOP + 0.3, -0.12), (0.4, TOP + 0.85, -0.06), SAIL).bone = "top"
    egg.block("Flag", (0.05, TOP + 0.85, -0.02), (0.35, TOP + 1.05, 0.02), BLACK).bone = "top"
    for s in (-1, 1):
        egg.block(f"Glow_Eye{'LR'[s > 0]}", (s * 0.4 - 0.15, 1.8, zf(3, 0.04)), (s * 0.4 + 0.15, 2.1, zf(3, -0.01)), (150, 255, 110))
    for i, x in enumerate((-0.3, 0.0, 0.3)):
        point(egg, f"Fang{i}", (x, 1.1, zf(2, 0.02)), (0, -1, 0), 0.07, 0.2, WHITE, "bottom")
    return glow(egg)


def jolly_roger_wyvern():
    BO, BD, SA = (248, 242, 222), (196, 182, 156), (36, 32, 48)
    egg = shell([BD, BO, BO, SA, BO, BO, BO])
    for s in (-1, 1):
        n = "LR"[s > 0]
        point(egg, f"Horn{n}", (s * 0.3, TOP - 0.05, 0.1), (s * 0.3, 0.7, 0.6), 0.1, 0.55, BD, "top")
        egg.block(f"Glow_Eye{n}", (s * 0.33 - 0.12, 2.55, zf(5, 0.04)), (s * 0.33 + 0.12, 2.75, zf(5, -0.01)), (90, 255, 130))
        w = WIDTHS[3] / 2
        xa, xb = sorted((s * w, s * (w + 0.3)))
        egg.block(f"Wing{n}", (xa, 1.2, -0.3), (xb, 1.9, 0.7), SA)
        point(egg, f"WingTip{n}", (s * (w + 0.15), 1.2, 0.2), (0, -1, 0), 0.12, 0.25, SA, "bottom")
    egg.block("Skull", (-0.2, 1.42, zf(3, 0.04)), (0.2, 1.75, zf(3, -0.01)), WHITE)
    return glow(egg)


def dreadstump():
    C, CD, BE = (214, 34, 44), (150, 20, 34), (44, 32, 30)
    egg = shell([(60, 70, 140), C, C, C, (250, 196, 150), (250, 196, 150), (250, 196, 150)])
    tricorn(egg, "Hat", w=0.95)
    z = zf(4, 0.02)
    egg.block("Beard", (-0.55, 1.5, z), (0.55, 2.1, z + 0.05), BE)
    egg.block("Nose", (-0.1, 2.2, zf(5, 0.1)), (0.1, 2.4, zf(5, -0.02)), (236, 110, 100)).bone = "top"
    googly(egg, "EyeL", -0.27, 2.6, zf(5) - 0.02, 0.13)
    googly(egg, "EyeR", 0.27, 2.6, zf(5) - 0.02, 0.13)
    egg.block("Buckle", (-0.15, 0.55, zf(1, 0.04)), (0.15, 0.8, zf(1, -0.01)), GOLD)
    egg.block("Belt", (-WIDTHS[1] / 2 - 0.02, 0.6, -0.5), (WIDTHS[1] / 2 + 0.02, 0.75, 0.5), BLACK)
    for p in egg.parts:
        if p.name.startswith("Eye"):
            p.bone = "top"
    return egg


EGGS = [("RedCrab", red_crab), ("Parrot", parrot), ("BananaMonkey", banana_monkey), ("TreasureHermit", treasure_hermit),
        ("EyepatchShark", eyepatch_shark), ("TreasureTurtle", treasure_turtle), ("GhostShip", ghost_ship),
        ("JollyRogerWyvern", jolly_roger_wyvern), ("Dreadstump", dreadstump)]

if __name__ == "__main__":
    O.EGGS = EGGS
    O.main(*sys.argv[1:], preview="/mnt/project-files/world3/pirate_cove/eggs")
