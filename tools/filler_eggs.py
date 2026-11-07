"""Eggs for QM's 33 picked luck-padding animals (tools/filler_export.py PICKS), in take C's
style (tools/ocean_eggs.py): the octo shell in each animal's own colours, bold markings and
one or two of its features (ears, horns, antlers, tusks, fins, wings, antennae, spikes).

Run from the repo root: python3 tools/filler_eggs.py [Kind ...]
Writes designs/eggs/c_style/<Kind>Egg.bbmodel, src/shared/Eggs/<Kind>EggModel.luau,
assets/ui/<Kind>EggRender.png and previews (plus all.png) in /mnt/project-files/animals/filler/eggs/.
"""

import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import horse_egg_takes as C  # noqa: E402
import ocean_eggs as O  # noqa: E402
from desert_eggs import fin  # noqa: E402
from horse_egg_takes import LH, N, WIDTHS, back_ridge, ears, shell  # noqa: E402
from partlib import render  # noqa: E402

TOP = N * LH


def blk(egg, name, lo, hi, c, bone=None):
    p = egg.block(name, lo, hi, c)
    if bone:
        p.bone = bone
    return p


def spots(egg, c, where, name="Spot"):
    """Flat patches standing out of the shell, front, back and one side each: (layer, x, w)."""
    for i, (layer, x, w) in enumerate(where):
        z = WIDTHS[layer] / 2
        y = layer * LH + 0.08
        blk(egg, f"{name}F{i}", (x - w / 2, y, -z - 0.06), (x + w / 2, y + LH - 0.16, -z + 0.05), c)
        blk(egg, f"{name}B{i}", (-x - w / 2, y, z - 0.05), (-x + w / 2, y + LH - 0.16, z + 0.06), c)
        sx = 1 if i % 2 else -1
        blk(egg, f"{name}S{i}", (min(sx * z, sx * (z + 0.06) - sx * 0.11), y, x - w / 2), (max(sx * z, sx * (z + 0.06) - sx * 0.11), y + LH - 0.16, x + w / 2), c)


def front(egg, name, x0, x1, y0, y1, c, out=0.06):
    i = min(int((y0 + y1) / 2 / LH), N - 1)
    z = WIDTHS[i] / 2
    return blk(egg, name, (x0, y0, -z - out), (x1, y1, -z + 0.05), c)


def horns(egg, c, steps, tip=None, name="Horn"):
    """A stepped pair on top: steps = [(x, hw, y0, y1), ...] for the right one, mirrored left."""
    for side, sx in (("L", -1), ("R", 1)):
        for k, (x, hw, y0, y1) in enumerate(steps):
            col = tip if tip and k == len(steps) - 1 else c
            blk(egg, f"{name}{side}{k}", (sx * x - hw, y0, -hw), (sx * x + hw, y1, hw), col, "top")


def antlers(egg, c, x=0.45, h=1.0, spread=0.5, tines=2):
    for side, sx in (("L", -1), ("R", 1)):
        blk(egg, f"Antler{side}", (sx * x - 0.08, TOP - 0.15, -0.08), (sx * x + 0.08, TOP + h * 0.55, 0.08), c, "top")
        x1 = sx * (x + spread)
        blk(egg, f"Beam{side}", (min(sx * x, x1) - 0.08, TOP + h * 0.45, -0.08), (max(sx * x, x1) + 0.08, TOP + h * 0.6, 0.08), c, "top")
        blk(egg, f"BeamUp{side}", (x1 - 0.08, TOP + h * 0.45, -0.08), (x1 + 0.08, TOP + h, 0.08), c, "top")
        for t in range(tines):
            tx = sx * (x + spread * (t + 1) / (tines + 1))
            blk(egg, f"Tine{side}{t}", (tx - 0.06, TOP + h * 0.55, -0.06), (tx + 0.06, TOP + h * (0.8 + 0.1 * t), 0.06), c, "top")


def tusks(egg, c, x=0.38, y=2 * LH, long=0.6, out=0.25):
    z = WIDTHS[2] / 2
    for side, sx in (("L", -1), ("R", 1)):
        blk(egg, f"Tusk{side}", (sx * x - 0.1, y - long, -z - out), (sx * x + 0.1, y, -z - out + 0.2), c)
        blk(egg, f"TuskRoot{side}", (sx * x - 0.12, y - 0.1, -z - out + 0.1), (sx * x + 0.12, y + 0.2, -z + 0.05), c)


def antennae(egg, c, tip, x=0.25, h=0.9, lean=0.35):
    for side, sx in (("L", -1), ("R", 1)):
        blk(egg, f"Antenna{side}", (sx * x - 0.06, TOP - 0.15, -0.06), (sx * x + 0.06, TOP + h, 0.06), c, "top")
        blk(egg, f"AntennaTip{side}", (sx * (x + lean) - 0.12, TOP + h - 0.12, -0.12), (sx * (x + lean) + 0.12, TOP + h + 0.12, 0.12), tip, "top")
        blk(egg, f"AntennaBend{side}", (min(sx * x, sx * (x + lean)) - 0.05, TOP + h - 0.06, -0.05), (max(sx * x, sx * (x + lean)) + 0.05, TOP + h + 0.04, 0.05), c, "top")


def wings(egg, c, tip=None, layers=(2, 3, 4), out=0.45):
    for side, sx in (("L", -1), ("R", 1)):
        for i in layers:
            z = WIDTHS[i] / 2
            w = out * (1.2 - 0.25 * (i - layers[0]))
            blk(egg, f"Wing{side}{i}", (min(sx * z, sx * (z + w)) - 0.05, i * LH + 0.04, -0.15 + 0.2 * (i - layers[0])), (max(sx * z, sx * (z + w)) + 0.05, (i + 1) * LH - 0.04, 0.55), c)
        if tip:
            i = layers[0]
            z = WIDTHS[i] / 2
            blk(egg, f"WingTip{side}", (min(sx * z, sx * (z + out * 1.3)), i * LH - 0.2, 0.15), (max(sx * z, sx * (z + out * 1.3)), i * LH + 0.06, 0.55), tip)


def side_fins(egg, c, layer=2, out=0.45):
    z = WIDTHS[layer] / 2
    for side, sx in (("L", -1), ("R", 1)):
        blk(egg, f"Fin{side}", (min(sx * z, sx * (z + out)) - 0.04, layer * LH + 0.05, -0.3), (max(sx * z, sx * (z + out)), layer * LH + 0.2, 0.35), c)


def zigzag(egg, c, name="Crack", x0=-0.5):
    """A glowing crack running up the front."""
    for k, (x, layer) in enumerate(((x0, 1), (x0 + 0.3, 2), (x0 + 0.1, 3), (x0 + 0.45, 4), (x0 + 0.3, 5))):
        y = layer * LH
        front(egg, f"{name}{k}", x - 0.1, x + 0.1, y, y + LH, c)
        front(egg, f"{name}J{k}", x - 0.1, x + 0.35, y + LH - 0.12, y + LH + 0.02, c)


def ring_band(egg, c, layer, name="Band"):
    """An octagonal ring standing slightly out of the shell, round one layer."""
    from egg_designs import octo_layer
    octo_layer(egg, name, layer * LH + 0.1, (layer + 1) * LH - 0.1, WIDTHS[layer] + 0.12, c, "top" if layer >= C.CRACK_LAYER else "bottom")


# ---------------------------------------------------------------- Meadow
def snail():
    shellc, ring, foot = (196, 120, 70), (150, 84, 50), (200, 210, 150)
    egg = shell([foot, foot, shellc, shellc, shellc, shellc, shellc])
    for l in (2, 4):
        ring_band(egg, ring, l, f"Ring{l}")
    antennae(egg, foot, (40, 40, 50), x=0.2, h=0.7, lean=0.15)
    return egg


def giraffe():
    tan, spot, horn = (240, 196, 100), (170, 100, 50), (110, 70, 40)
    egg = shell([tan] * 7)
    spots(egg, spot, ((1, -0.5, 0.45), (2, 0.35, 0.55), (3, -0.25, 0.5), (4, 0.4, 0.45), (5, -0.2, 0.4)))
    ears(egg, tan, (230, 170, 120), x=0.75, hw=0.3, h=0.6)
    horns(egg, horn, ((0.22, 0.09, TOP - 0.15, TOP + 0.45), (0.22, 0.15, TOP + 0.45, TOP + 0.7)))
    back_ridge(egg, horn, range(3, N), name="Mane", out=0.2, hw=0.15)
    return egg


def hillback():
    shellc, rim, skin, grass = (120, 90, 60), (90, 66, 44), (150, 160, 110), (96, 186, 70)
    egg = shell([skin, rim, shellc, shellc, shellc, grass, grass])
    spots(egg, rim, ((3, -0.45, 0.5), (3, 0.45, 0.5)), "Scute")
    # a little pine on top (the animal's is the map's tall pine)
    trunk, needles = (120, 84, 58), (60, 120, 70)
    blk(egg, "Trunk", (-0.1, TOP - 0.1, -0.1), (0.1, TOP + 0.35, 0.1), trunk, "top")
    for k, (hw, y0, y1) in enumerate(((0.5, 0.3, 0.6), (0.38, 0.6, 0.9), (0.25, 0.9, 1.15), (0.12, 1.15, 1.35))):
        blk(egg, f"Tier{k}", (-hw, TOP + y0, -hw), (hw, TOP + y1, hw), needles, "top")
    return egg


# ---------------------------------------------------------------- Desert
def coyote():
    fur, belly, dark = (186, 150, 110), (236, 222, 196), (120, 92, 66)
    egg = shell([belly, belly, fur, fur, fur, fur, fur])
    ears(egg, fur, (90, 60, 50), x=0.55, hw=0.32, h=0.9)
    back_ridge(egg, dark, range(2, N), name="Back", out=0.12, hw=0.3)
    front(egg, "Muzzle", -0.3, 0.3, 2 * LH, 3 * LH, belly)
    return egg


def oryx():
    tan, dark, white = (220, 200, 170), (40, 36, 40), (250, 248, 240)
    egg = shell([white, white, dark, tan, tan, tan, white])
    front(egg, "StripeL", -0.42, -0.24, 4 * LH, 6 * LH, dark)
    front(egg, "StripeR", 0.24, 0.42, 4 * LH, 6 * LH, dark)
    ears(egg, tan, white, x=0.7, hw=0.24, h=0.5)
    # long straight horns, back-swept
    for side, sx in (("L", -1), ("R", 1)):
        for k in range(5):
            blk(egg, f"Horn{side}{k}", (sx * 0.25 - 0.08, TOP - 0.1 + k * 0.3, 0.05 + k * 0.12), (sx * 0.25 + 0.08, TOP + 0.25 + k * 0.3, 0.25 + k * 0.12), dark, "top")
    return egg


def ostrich():
    black, white, pink = (40, 36, 40), (250, 250, 250), (220, 170, 160)
    egg = shell([pink, black, black, black, black, pink, pink])
    wings(egg, white, layers=(2, 3), out=0.35)
    back_ridge(egg, white, (2, 3, 4), name="Plume", out=0.3, hw=0.35)
    front(egg, "Beak", -0.2, 0.2, 5 * LH + 0.05, 5 * LH + 0.25, (240, 180, 90), out=0.3)
    return egg


def mirage_elephant():
    grey, blanket, trim = (190, 170, 160), (180, 60, 60), (240, 196, 60)
    egg = shell([grey, grey, grey, blanket, blanket, grey, grey])
    ring_band(egg, trim, 3, "Trim")
    ears(egg, grey, (220, 160, 160), x=0.75, hw=0.45, h=0.9, base=TOP - 0.8)
    front(egg, "Trunk", -0.15, 0.15, 1 * LH, 5 * LH, grey, out=0.15)
    tusks(egg, (250, 246, 230), x=0.38)
    return egg


# ---------------------------------------------------------------- Snow
def seal():
    grey, dark, light = (170, 180, 196), (130, 140, 160), (200, 206, 220)
    egg = shell([light, light, grey, grey, grey, grey, grey])
    spots(egg, dark, ((2, -0.5, 0.3), (3, 0.4, 0.3), (4, -0.2, 0.3), (5, 0.3, 0.25)))
    side_fins(egg, dark, layer=1)
    front(egg, "Nose", -0.12, 0.12, 4 * LH + 0.1, 4 * LH + 0.3, (40, 40, 50), out=0.1)
    return egg


def reindeer():
    brown, mane, antler = (150, 110, 80), (236, 226, 210), (220, 200, 160)
    egg = shell([mane, brown, brown, mane, brown, brown, brown])
    ears(egg, brown, mane, x=0.75, hw=0.25, h=0.5)
    antlers(egg, antler, x=0.3, h=1.1, spread=0.45)
    front(egg, "Nose", -0.15, 0.15, 3 * LH + 0.1, 3 * LH + 0.35, (210, 50, 50), out=0.15)
    return egg


def walrus():
    skin, flip, muzzle = (180, 130, 110), (150, 104, 90), (230, 210, 180)
    egg = shell([flip, skin, skin, skin, skin, skin, skin])
    front(egg, "Muzzle", -0.5, 0.5, 2 * LH, 3 * LH + 0.1, muzzle, out=0.12)
    tusks(egg, (250, 246, 230), x=0.28, y=2 * LH + 0.1, long=0.75, out=0.3)
    side_fins(egg, flip, layer=1)
    return egg


def narwhal():
    blue, belly, spot = (180, 190, 206), (236, 240, 248), (120, 130, 150)
    egg = shell([belly, belly, blue, blue, blue, blue, blue])
    spots(egg, spot, ((3, -0.4, 0.25), (4, 0.35, 0.25), (5, -0.1, 0.2)))
    for k, (hw, y0, y1) in enumerate(((0.12, TOP - 0.1, TOP + 0.5), (0.09, TOP + 0.5, TOP + 1.0), (0.05, TOP + 1.0, TOP + 1.4))):
        blk(egg, f"Tusk{k}", (-hw, y0, -0.25 - hw), (hw, y1, -0.25 + hw), (250, 246, 230), "top")
    side_fins(egg, blue, layer=2)
    return egg


def glacier_mammoth():
    fur, skirt, ice = (130, 90, 64), (96, 66, 48), (190, 236, 250)
    egg = shell([skirt, skirt, fur, fur, fur, fur, ice])
    back_ridge(egg, skirt, range(3, N), name="Hump", out=0.2, hw=0.4)
    ears(egg, fur, skirt, x=0.75, hw=0.35, h=0.6, base=TOP - 0.7)
    tusks(egg, (250, 246, 230), x=0.42, y=3 * LH, long=0.9, out=0.35)
    front(egg, "Trunk", -0.14, 0.14, 1 * LH, 4 * LH, fur, out=0.14)
    return egg


# ---------------------------------------------------------------- Volcano
def fire_ant():
    red, dark, glow = (210, 60, 40), (80, 30, 30), (255, 120, 30)
    egg = shell([dark, dark, dark, red, red, red, red])
    ring_band(egg, glow, 2, "Glow")
    antennae(egg, dark, glow, x=0.2, h=0.8, lean=0.3)
    return egg


def magma_crab():
    red, rock, glow = (150, 50, 40), (50, 44, 48), (255, 120, 30)
    egg = shell([red, red, red, rock, rock, rock, rock])
    spots(egg, glow, ((4, -0.35, 0.25), (5, 0.25, 0.25), (3, 0.5, 0.2)), "Vent")
    for side, sx in (("L", -1), ("R", 1)):
        z = WIDTHS[1] / 2
        blk(egg, f"Claw{side}", (min(sx * z, sx * (z + 0.4)), LH * 1.2, -0.45), (max(sx * z, sx * (z + 0.4)), LH * 2.2, 0.0), red)
        blk(egg, f"Pincer{side}", (min(sx * (z + 0.2), sx * (z + 0.4)), LH * 2.2, -0.45), (max(sx * (z + 0.2), sx * (z + 0.4)), LH * 2.6, -0.2), red)
    antennae(egg, red, (40, 40, 50), x=0.2, h=0.45, lean=0.0)
    return egg


def ash_behemoth():
    ash, dark, glow = (80, 72, 74), (50, 44, 48), (255, 120, 30)
    egg = shell([dark, ash, ash, ash, ash, ash, dark])
    zigzag(egg, glow)
    horns(egg, dark, ((0.42, 0.14, TOP - 0.3, TOP + 0.2), (0.55, 0.1, TOP + 0.2, TOP + 0.55)), tip=glow)
    blk(egg, "Vent", (-0.22, TOP - 0.05, -0.22), (0.22, TOP + 0.15, 0.22), glow, "top")
    return egg


# ---------------------------------------------------------------- Dungeon
def rat():
    grey, pink = (120, 110, 110), (236, 160, 176)
    egg = shell([grey] * 7)
    ears(egg, grey, pink, x=0.55, hw=0.4, h=0.7)
    front(egg, "Nose", -0.12, 0.12, 3 * LH + 0.1, 3 * LH + 0.3, pink, out=0.1)
    z = WIDTHS[0] / 2
    blk(egg, "Tail0", (-0.07, 0.05, z - 0.05), (0.07, 0.2, z + 0.6), pink)
    blk(egg, "Tail1", (-0.07, 0.05, z + 0.5), (0.07, 0.6, z + 0.64), pink)
    return egg


def cave_cricket():
    tan, dark = (190, 170, 140), (150, 130, 100)
    egg = shell([dark, tan, dark, tan, dark, tan, tan])
    antennae(egg, dark, tan, x=0.15, h=1.2, lean=0.5)
    wings(egg, dark, layers=(1, 2), out=0.3)
    return egg


def crypt_snail():
    stone, brick, foot, moss, glow = (120, 120, 130), (70, 70, 80), (180, 190, 200), (90, 140, 80), (140, 240, 200)
    egg = shell([foot, foot, stone, stone, stone, stone, moss])
    spots(egg, brick, ((2, -0.45, 0.5), (3, 0.3, 0.55), (4, -0.2, 0.5), (5, 0.25, 0.4)), "Brick")
    antennae(egg, foot, glow, x=0.2, h=0.7, lean=0.15)
    return egg


def web_spider():
    body, leg, mark, glow = (60, 54, 64), (44, 40, 48), (200, 40, 50), (140, 240, 200)
    egg = shell([leg, body, body, body, body, body, body])
    front(egg, "Mark0", -0.15, 0.15, 3 * LH, 5 * LH, mark)
    front(egg, "Mark1", -0.4, 0.4, 3 * LH + 0.15, 3 * LH + 0.3, mark)
    for k, x in enumerate((-0.3, -0.12, 0.12, 0.3)):
        front(egg, f"Eye{k}", x - 0.07, x + 0.07, 5 * LH + 0.15, 5 * LH + 0.29, glow)
    for side, sx in (("L", -1), ("R", 1)):
        for j, zz in enumerate((-0.5, -0.15, 0.2, 0.55)):
            z = WIDTHS[1] / 2
            blk(egg, f"Leg{side}{j}", (min(sx * z, sx * (z + 0.45)), 2 * LH - 0.08, zz - 0.06), (max(sx * z, sx * (z + 0.45)), 2 * LH + 0.06, zz + 0.06), leg)
            blk(egg, f"Shin{side}{j}", (sx * (z + 0.45) - 0.06, 0, zz - 0.06), (sx * (z + 0.45) + 0.06, 2 * LH + 0.06, zz + 0.06), leg)
    return egg


def abyss_pillbug():
    plate, seam, leg = (150, 150, 170), (100, 100, 120), (200, 190, 200)
    egg = shell([leg, plate, plate, plate, plate, plate, plate])
    for l in (1, 2, 3, 4, 5):
        ring_band(egg, seam, l, f"Seam{l}")
    antennae(egg, leg, plate, x=0.2, h=0.6, lean=0.35)
    return egg


# ---------------------------------------------------------------- Forest
def stag_beetle():
    shellc, jaw = (60, 40, 30), (120, 70, 40)
    egg = shell([shellc] * 7)
    front(egg, "Split", -0.04, 0.04, 1 * LH, 5 * LH, (30, 20, 16))
    for side, sx in (("L", -1), ("R", 1)):
        blk(egg, f"Jaw{side}", (sx * 0.3 - 0.09, TOP - 0.2, -0.09), (sx * 0.3 + 0.09, TOP + 0.6, 0.09), jaw, "top")
        blk(egg, f"JawTip{side}", (min(sx * 0.3, sx * 0.05) - 0.09, TOP + 0.5, -0.09), (max(sx * 0.3, sx * 0.05) + 0.09, TOP + 0.65, 0.09), jaw, "top")
        blk(egg, f"JawTooth{side}", (min(sx * 0.3, sx * 0.15) - 0.05, TOP + 0.2, -0.06), (max(sx * 0.3, sx * 0.15) + 0.05, TOP + 0.3, 0.06), jaw, "top")
    return egg


def deer():
    brown, spot, white = (180, 120, 70), (250, 240, 220), (236, 226, 210)
    egg = shell([white, brown, brown, brown, brown, brown, brown])
    spots(egg, spot, ((2, -0.5, 0.15), (2, 0.4, 0.15), (3, -0.2, 0.15), (3, 0.55, 0.15), (4, 0.2, 0.15)))
    ears(egg, brown, white, x=0.75, hw=0.28, h=0.55)
    antlers(egg, (220, 200, 160), x=0.3, h=0.8, spread=0.3, tines=1)
    return egg


def brown_bear():
    fur, snout = (120, 76, 44), (190, 150, 110)
    egg = shell([fur] * 7)
    ears(egg, fur, snout, x=0.5, hw=0.25, h=0.4)
    front(egg, "Snout", -0.35, 0.35, 3 * LH, 4 * LH, snout, out=0.15)
    front(egg, "Nose", -0.12, 0.12, 4 * LH - 0.2, 4 * LH, (40, 30, 30), out=0.2)
    back_ridge(egg, (100, 62, 36), (4, 5), name="Hump", out=0.15, hw=0.4)
    return egg


def ancient_moose():
    fur, moss, antler, leaf = (90, 64, 46), (80, 160, 70), (200, 180, 140), (110, 190, 80)
    egg = shell([fur, fur, fur, fur, fur, moss, moss])
    spots(egg, moss, ((3, -0.4, 0.4), (4, 0.3, 0.45)), "Moss")
    # broad flat palms
    for side, sx in (("L", -1), ("R", 1)):
        blk(egg, f"Antler{side}", (sx * 0.3 - 0.1, TOP - 0.15, -0.1), (sx * 0.3 + 0.1, TOP + 0.35, 0.1), antler, "top")
        blk(egg, f"Palm{side}", (min(sx * 0.3, sx * 1.15), TOP + 0.3, -0.12), (max(sx * 0.3, sx * 1.15), TOP + 0.75, 0.12), antler, "top")
        for t in range(3):
            tx = sx * (0.5 + 0.28 * t)
            blk(egg, f"Tine{side}{t}", (tx - 0.07, TOP + 0.75, -0.07), (tx + 0.07, TOP + 1.0, 0.07), antler, "top")
        blk(egg, f"Leaves{side}", (sx * 0.85 - 0.15, TOP + 0.75, -0.15), (sx * 0.85 + 0.15, TOP + 0.95, 0.15), leaf, "top")
    return egg


# ---------------------------------------------------------------- Castle
def swan():
    white, wing, beak, gold = (250, 250, 252), (236, 236, 240), (240, 140, 50), (240, 196, 60)
    egg = shell([white] * 7)
    wings(egg, wing, layers=(2, 3, 4), out=0.4)
    front(egg, "Beak", -0.15, 0.15, 5 * LH, 5 * LH + 0.25, beak, out=0.25)
    front(egg, "Mask", -0.3, 0.3, 5 * LH + 0.25, 5 * LH + 0.45, (40, 36, 40))
    for k, x in enumerate((-0.25, 0.0, 0.25)):
        blk(egg, f"Crown{k}", (x - 0.08, TOP - 0.05, -0.08), (x + 0.08, TOP + 0.3, 0.08), gold, "top")
    blk(egg, "CrownBand", (-0.35, TOP - 0.1, -0.12), (0.35, TOP + 0.08, 0.12), gold, "top")
    return egg


def armored_ram():
    wool, barding, helm, trim, horn = (240, 236, 226), (60, 70, 170), (180, 186, 196), (240, 196, 60), (200, 170, 120)
    egg = shell([barding, barding, wool, wool, wool, helm, helm])
    ring_band(egg, trim, 1, "Trim")
    # curled horns down each side of the helm
    for side, sx in (("L", -1), ("R", 1)):
        z = WIDTHS[5] / 2
        blk(egg, f"Horn{side}", (min(sx * 0.3, sx * (z + 0.3)), TOP - 0.25, -0.15), (max(sx * 0.3, sx * (z + 0.3)), TOP + 0.05, 0.15), horn, "top")
        blk(egg, f"HornDown{side}", (min(sx * (z + 0.05), sx * (z + 0.3)), 5 * LH - 0.2, -0.15), (max(sx * (z + 0.05), sx * (z + 0.3)), TOP - 0.25, 0.15), horn, "top")
        blk(egg, f"HornTip{side}", (min(sx * (z + 0.05), sx * (z + 0.3)), 5 * LH - 0.2, -0.45), (max(sx * (z + 0.05), sx * (z + 0.3)), 5 * LH + 0.05, -0.15), trim, "top")
    return egg


def royal_stag():
    white, cape, trim, antler = (250, 250, 250), (60, 70, 170), (240, 196, 60), (240, 196, 60)
    egg = shell([white, cape, cape, cape, white, white, white])
    ring_band(egg, trim, 4, "CapeTrim")
    ears(egg, white, (230, 200, 200), x=0.75, hw=0.28, h=0.55)
    antlers(egg, antler, x=0.3, h=1.2, spread=0.5, tines=3)
    return egg


def griffin():
    gold, chest, wing, beak = (210, 160, 80), (250, 248, 240), (230, 200, 140), (240, 180, 60)
    egg = shell([gold, gold, gold, gold, chest, chest, chest])
    wings(egg, wing, tip=gold, layers=(2, 3, 4), out=0.5)
    front(egg, "Beak", -0.15, 0.15, 5 * LH - 0.1, 5 * LH + 0.2, beak, out=0.3)
    ears(egg, chest, None, x=0.5, hw=0.2, h=0.5)
    return egg


def fortress_tortoise():
    shellc, stone, rim, skin, flag = (110, 90, 70), (150, 150, 146), (80, 64, 50), (120, 140, 100), (200, 50, 50)
    egg = shell([skin, rim, shellc, shellc, shellc, stone, stone])
    # battlements round the top and a little tower
    hw = WIDTHS[6] / 2
    for k, (x, z) in enumerate(((-hw, -hw), (hw, -hw), (-hw, hw), (hw, hw), (0, -hw), (0, hw), (-hw, 0), (hw, 0))):
        blk(egg, f"Merlon{k}", (x - 0.1, TOP - 0.05, z - 0.1), (x + 0.1, TOP + 0.2, z + 0.1), stone, "top")
    blk(egg, "Tower", (-0.18, TOP - 0.05, -0.18), (0.18, TOP + 0.55, 0.18), stone, "top")
    blk(egg, "Spire", (-0.12, TOP + 0.55, -0.12), (0.12, TOP + 0.8, 0.12), rim, "top")
    blk(egg, "Pole", (-0.03, TOP + 0.8, -0.03), (0.03, TOP + 1.2, 0.03), rim, "top")
    blk(egg, "Flag", (0.03, TOP + 0.95, -0.02), (0.38, TOP + 1.2, 0.02), flag, "top")
    front(egg, "Gate", -0.2, 0.2, 2 * LH, 3 * LH + 0.1, rim)
    return egg


# ---------------------------------------------------------------- Ocean
def shrimp():
    red, light = (220, 90, 80), (250, 130, 110)
    egg = shell([red, light, red, light, red, light, red])
    antennae(egg, red, (40, 40, 50), x=0.15, h=1.1, lean=0.55)
    fin(egg, "Fan", 0.2, 0.9, 0.45, 0.35, light)
    return egg


def pelican():
    white, wing, pouch, tip = (246, 244, 236), (200, 196, 190), (240, 150, 70), (60, 56, 60)
    egg = shell([white] * 7)
    wings(egg, wing, tip=tip, layers=(2, 3), out=0.4)
    front(egg, "Bill", -0.15, 0.15, 5 * LH, 5 * LH + 0.2, pouch, out=0.45)
    front(egg, "Pouch", -0.25, 0.25, 3 * LH + 0.2, 5 * LH, pouch, out=0.2)
    return egg


def hammerhead():
    grey, belly, dark = (130, 140, 156), (236, 240, 246), (100, 110, 130)
    egg = shell([belly, belly, grey, grey, grey, grey, grey])
    fin(egg, "Dorsal", 2.0, 3.0, 0.5, 0.15, dark)
    blk(egg, "Hammer", (-1.0, TOP - 0.25, -0.2), (1.0, TOP + 0.05, 0.2), grey, "top")
    for side, sx in (("L", -1), ("R", 1)):
        blk(egg, f"Eye{side}", (sx * 0.95 - 0.07, TOP - 0.2, -0.24), (sx * 0.95 + 0.07, TOP - 0.06, -0.18), (20, 20, 24), "top")
    side_fins(egg, dark, layer=2)
    return egg


def manta_ray():
    dark, belly, spot = (50, 60, 90), (240, 244, 250), (110, 130, 170)
    egg = shell([belly, belly, dark, dark, dark, dark, dark])
    spots(egg, spot, ((3, -0.4, 0.2), (4, 0.3, 0.2), (5, -0.1, 0.18)))
    wings(egg, dark, layers=(2, 3), out=0.7)
    horns(egg, dark, ((0.3, 0.08, 5 * LH, TOP + 0.2),))
    return egg


def anglerfish():
    body, fin_c, tooth, glow = (70, 60, 70), (100, 80, 100), (250, 250, 240), (140, 240, 200)
    egg = shell([body] * 7)
    front(egg, "Mouth", -0.55, 0.55, 2 * LH - 0.05, 2 * LH + 0.15, (20, 16, 20))
    for k, x in enumerate((-0.4, -0.15, 0.1, 0.35)):
        front(egg, f"Tooth{k}", x - 0.06, x + 0.06, 2 * LH + 0.15, 2 * LH + 0.4, tooth, out=0.1)
    fin(egg, "FinTop", 2.2, 3.0, 0.4, 0.1, fin_c)
    blk(egg, "Rod", (-0.04, TOP - 0.1, -0.04), (0.04, TOP + 0.6, 0.04), fin_c, "top")
    blk(egg, "RodOut", (-0.04, TOP + 0.52, -0.5), (0.04, TOP + 0.6, 0.04), fin_c, "top")
    blk(egg, "Lure", (-0.13, TOP + 0.3, -0.63), (0.13, TOP + 0.56, -0.37), glow, "top")
    return egg


EGGS = [
    ("Snail", snail), ("Giraffe", giraffe), ("HillbackTortoise", hillback),
    ("Coyote", coyote), ("Oryx", oryx), ("Ostrich", ostrich), ("MirageElephant", mirage_elephant),
    ("Seal", seal), ("Reindeer", reindeer), ("Walrus", walrus), ("Narwhal", narwhal), ("GlacierMammoth", glacier_mammoth),
    ("FireAnt", fire_ant), ("MagmaCrab", magma_crab), ("AshBehemoth", ash_behemoth),
    ("Rat", rat), ("CaveCricket", cave_cricket), ("CryptSnail", crypt_snail), ("WebSpider", web_spider), ("AbyssPillbug", abyss_pillbug),
    ("StagBeetle", stag_beetle), ("Deer", deer), ("BrownBear", brown_bear), ("AncientMoose", ancient_moose),
    ("Swan", swan), ("ArmoredRam", armored_ram), ("RoyalStag", royal_stag), ("Griffin", griffin), ("FortressTortoise", fortress_tortoise),
    ("Shrimp", shrimp), ("Pelican", pelican), ("Hammerhead", hammerhead), ("MantaRay", manta_ray), ("Anglerfish", anglerfish),
]


def main(*kinds):
    out = "/mnt/project-files/animals/filler/eggs"
    O.EGGS = [(k, f) for k, f in EGGS if not kinds or k in kinds]
    O.main(*kinds, preview=out)
    # one contact sheet of the front renders
    tile, cols = 220, 9
    ims = [(k, Image.open(os.path.join(out, "renders", k + "Egg.png"))) for k, _ in O.EGGS]
    sheet = Image.new("RGB", (tile * cols, tile * ((len(ims) + cols - 1) // cols)), (255, 255, 255))
    from animal_designs import font
    from PIL import ImageDraw
    d = ImageDraw.Draw(sheet)
    for i, (k, im) in enumerate(ims):
        im = im.copy()
        im.thumbnail((tile - 20, tile - 40))
        x, y = (i % cols) * tile, (i // cols) * tile
        sheet.paste(im, (x + (tile - im.width) // 2, y + 28), im)
        d.text((x + 6, y + 6), k, fill=(20, 20, 20), font=font(14))
    sheet.save(os.path.join(out, "all.png"))
    print("wrote", os.path.join(out, "all.png"))


if __name__ == "__main__":
    main(*sys.argv[1:])
