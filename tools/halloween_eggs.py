"""Eggs for the Halloween world's animals (Oct 15), in the Garden eggs' style (tools/garden_eggs.py):
redone in the Meadow and Desert eggs' style (QM, Oct 15): the octo shell in the animal's colours with
bold bands and each animal's own feature in chunky blocks (ears, tail, wings, legs); no faces.
(The Soul Horse keeps its own egg.)

Run from the repo root: python3 tools/halloween_eggs.py [Kind ...]
Writes designs/eggs/c_style/<Kind>Egg.bbmodel, src/shared/Eggs/<Kind>EggModel.luau,
assets/ui/<Kind>EggRender.png and previews in /mnt/project-files/halloween/animals/eggs/.
"""

import math
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import ocean_eggs as O  # noqa: E402
import numpy as np  # noqa: E402
import horse_egg_takes as C  # noqa: E402
from horse_egg_takes import front_plate  # noqa: E402
from desert_eggs import fin, ribs  # noqa: E402
from horse_egg_takes import LH, N, WIDTHS, shell, layer_of  # noqa: E402
import halloween_black_cat as cat, halloween_bat as bat, halloween_pumpkin_pup as pup  # noqa: E402,E401
import halloween_tarantula as spider, halloween_werewolf as wolf, halloween_ghost as ghost  # noqa: E402,E401
import halloween_skeleton_dog as dog, halloween_tombstone as tomb, halloween_zombie_bear as bear  # noqa: E402,E401
import halloween_wisp_wolf as wisp, halloween_grim_reaper as reaper  # noqa: E402,E401


# (the Garden eggs' helpers, copied: tools/garden_eggs.py)
TOP = N * LH


def fz(y, out=0.0):
    """The front face's z at height y, plus out further forward."""
    return -WIDTHS[layer_of(y)] / 2 - out


def pyr(egg, name, base, d, L, hw, ht, color, bone=None):
    d = np.array(d, float) / np.linalg.norm(d)
    wv = np.array([1.0, 0, 0]) if abs(d[0]) < 0.9 else np.array([0, 0, 1.0])
    wv = wv - d * (wv @ d)
    wv /= np.linalg.norm(wv)
    tv = np.cross(d, wv)
    b = np.array(base, float)
    c = [b - wv * hw - tv * ht, b + wv * hw - tv * ht, b + wv * hw + tv * ht, b - wv * hw + tv * ht]
    a = b + d * L
    return egg.poly(name, [c] + [[c[i], c[(i + 1) % 4], a] for i in range(4)], color, bone=bone)


def X(sx, a0, a1):
    return sorted((sx * a0, sx * a1))


def black_cat_egg():
    c = cat.C
    egg = shell([c["fur"], c["fur"], c["fur"], c["collar"], c["fur"], c["fur"], c["fur"]])
    C.ears(egg, c["fur"], c["pink"], x=0.5, hw=0.42, h=1.0)
    zf = -WIDTHS[3] / 2
    egg.block("Bell", (-0.2, 3 * LH - 0.3, zf - 0.3), (0.2, 3 * LH + 0.1, zf + 0.1), c["bell"])
    # a tall tail up the back with a hooked tip
    z, y = WIDTHS[2] / 2, 2 * LH
    egg.block("Tail", (-0.18, y, z - 0.05), (0.18, y + 0.35, z + 0.4), c["fur"])
    egg.block("Tail2", (-0.18, y + 0.35, z + 0.04), (0.18, y + 1.4, z + 0.4), c["fur"])
    egg.block("TailTip", (-0.18, y + 1.4, z - 0.3), (0.18, y + 1.75, z + 0.4), c["fur"])
    return egg


def bat_egg():
    c = bat.C
    egg = shell([c["furdark"], c["fur"], c["fur"], c["fur"], c["fur"], c["fur"], c["fur"]])
    C.ears(egg, c["fur"], c["pink"], x=0.45, hw=0.36, h=1.3)
    # folded wings down each side: a long arm block and three finger points
    for side, sx in (("L", -1), ("R", 1)):
        a = WIDTHS[4] / 2
        y = 4 * LH
        x0, x1 = X(sx, a - 0.05, a + 0.35)
        egg.block("Wing" + side, (x0, y - 0.1, -0.25), (x1, y + 0.25, 0.35), c["wing"])
        for k, (y0, y1) in enumerate(((y - 1.2, y - 0.1), (y - 0.9, y - 0.1), (y - 0.6, y - 0.1))):
            x0, x1 = X(sx, a + 0.05, a + 0.35)
            egg.block(f"Finger{side}{k}", (x0, y0, -0.25 + 0.22 * k), (x1, y1, -0.07 + 0.22 * k), c["wing"])
    return egg


def pumpkin_pup_egg():
    c = pup.C
    rib = (226, 104, 14)
    egg = shell([c["furdark"], c["fur"], c["fur"], c["pumpkin"], c["pumpkin"], c["pumpkin"], c["pumpkin"]])
    ribs(egg, rib, range(3, N))
    egg.block("Stem", (-0.15, TOP - 0.05, -0.15), (0.15, TOP + 0.5, 0.15), c["stem"]).bone = "top"
    egg.block("StemTip", (-0.15, TOP + 0.35, 0.15), (0.15, TOP + 0.5, 0.4), c["stem"]).bone = "top"
    # leaf ears flopping down the sides
    for side, sx in (("L", -1), ("R", 1)):
        a = WIDTHS[5] / 2
        x0, x1 = X(sx, a - 0.05, a + 0.25)
        egg.block("Leaf" + side, (x0, 5 * LH - 0.5, -0.3), (x1, 6 * LH, 0.3), c["leaf"])
    return egg


def tarantula_egg():
    c = spider.C
    egg = shell([c["furdark"], c["fur"], c["fur"], c["orange"], c["fur"], c["fur"], c["orange"]])
    # four legs a side: an orange thigh up and out, a dark shin down to the ground
    for side, sx in (("L", -1), ("R", 1)):
        a = WIDTHS[2] / 2
        for k, z in enumerate((-0.6, -0.2, 0.2, 0.6)):
            x0, x1 = X(sx, a - 0.05, a + 0.4)
            egg.block(f"Thigh{side}{k}", (x0, 2 * LH, z - 0.1), (x1, 2 * LH + 0.25, z + 0.1), c["orange"])
            x0, x1 = X(sx, a + 0.25, a + 0.45)
            egg.block(f"Shin{side}{k}", (x0, 0, z - 0.1), (x1, 2 * LH, z + 0.1), c["furdark"])
    return egg


def werewolf_egg():
    c = wolf.C
    egg = shell([c["shorts"], c["shorts"], c["fur"], c["fur"], c["fur"], c["fur"], c["fur"]])
    C.ears(egg, c["furdark"], c["furlight"], x=0.5, hw=0.38, h=1.2)
    # shaggy tufts down the back and a bushy tail
    for i in (3, 5):
        fin(egg, f"Tuft{i}", i * LH + 0.05, (i + 1) * LH + 0.25, 0.45, 0.25, c["furdark"])
    z, y = WIDTHS[2] / 2, 2 * LH
    egg.block("Tail", (-0.25, y - 0.1, z - 0.05), (0.25, y + 0.4, z + 0.6), c["fur"])
    egg.block("TailTip", (-0.25, y + 0.1, z + 0.6), (0.25, y + 0.5, z + 0.9), c["furlight"])
    return egg


def ghost_egg():
    c = ghost.C
    egg = shell([c["ghostdark"], c["ghost"], c["ghost"], c["ghost"], c["ghost"], c["ghost"], c["ghost"]])
    # a wavy hem of points round the bottom and two stubby arms
    for k in range(8):
        a = 2 * math.pi * (k + 0.5) / 8
        r = WIDTHS[1] / 2
        pyr(egg, f"Hem{k}", (r * math.sin(a), LH, -r * math.cos(a)), (math.sin(a) * 0.4, -1, -math.cos(a) * 0.4), 0.45, 0.22, 0.12, c["ghost"])
    for side, sx in (("L", -1), ("R", 1)):
        a = WIDTHS[3] / 2
        x0, x1 = X(sx, a - 0.05, a + 0.5)
        egg.block("Arm" + side, (x0, 3 * LH, -0.2), (x1, 3 * LH + 0.35, 0.2), c["ghostdark"])
    return egg


def skeleton_dog_egg():
    c = dog.C
    egg = shell([c["bonedark"], c["bone"], c["bone"], c["collar"], c["bone"], c["bone"], c["bone"]])
    for i in (1, 2):
        front_plate(egg, f"Rib{i}", -0.5, 0.5, i * LH + 0.15, i * LH + 0.32, c["socket"], depth=0.05, plain=False)
    C.ears(egg, c["bone"], None, x=0.45, hw=0.3, h=0.8)
    # a bone tail: shaft and knobbly end
    z, y = WIDTHS[2] / 2, 2 * LH
    egg.block("Tail", (-0.12, y, z - 0.05), (0.12, y + 0.9, z + 0.3), c["bone"])
    egg.block("TailKnob", (-0.22, y + 0.9, z), (0.22, y + 1.15, z + 0.4), c["bone"])
    return egg


def tombstone_egg():
    c = tomb.C
    egg = shell([c["stonedark"], c["stone"], c["stone"], c["stone"], c["stone"], c["stone"], c["moss"]])
    zf = -WIDTHS[4] / 2
    egg.block("Cross", (-0.12, 3 * LH, zf - 0.15), (0.12, 5 * LH + 0.2, zf + 0.05), c["stonedark"])
    egg.block("CrossBar", (-0.4, 4 * LH + 0.1, zf - 0.15), (0.4, 4 * LH + 0.35, zf + 0.05), c["stonedark"])
    for side, sx in (("L", -1), ("R", 1)):
        a = WIDTHS[5] / 2
        x0, x1 = X(sx, a - 0.3, a + 0.1)
        egg.block("Moss" + side, (x0, 5 * LH, -0.4), (x1, 5 * LH + 0.25, 0.4), c["moss"])
    return egg


def zombie_bear_egg():
    c = bear.C
    egg = shell([c["furdark"], c["fur"], c["fur"], c["fur"], c["fur"], c["fur"], c["fur"]])
    front_plate(egg, "Patch", -0.55, -0.05, 2 * LH, 3 * LH + 0.2, c["patch"], depth=0.05, plain=False)
    front_plate(egg, "Stitch", -0.65, 0.05, 2 * LH + 0.3, 2 * LH + 0.4, c["stitch"], depth=0.08, plain=False)
    front_plate(egg, "Bandage", 0.15, 0.55, LH, 2 * LH, c["bandage"], depth=0.05, plain=False)
    for side, sx in (("L", -1), ("R", 1)):  # round ears: chunky blocks, as the Pig's
        x0, x1 = X(sx, 0.35, 0.75)
        egg.block("Ear" + side, (x0, TOP - 0.2, -0.15), (x1, TOP + 0.3, 0.15), c["furdark"]).bone = "top"
    return egg


def wisp_wolf_egg():
    c = wisp.C
    egg = shell([c["furdark"], c["fur"], c["fur"], c["fur"], c["fur"], c["fur"], c["fur"]])
    C.ears(egg, c["furdark"], c["snout"], x=0.5, hw=0.36, h=1.3)
    for i in (2, 4):  # glowing wisp flames up the back
        fin(egg, f"Glow_Wisp{i}", i * LH + 0.05, (i + 1) * LH + 0.4, 0.55, 0.25, c["wisp"])
    z, y = WIDTHS[1] / 2, LH
    egg.block("Glow_Tail", (-0.25, y, z - 0.05), (0.25, y + 0.5, z + 0.7), c["wisp"])
    egg.block("Glow_TailTip", (-0.2, y + 0.25, z + 0.7), (0.2, y + 0.7, z + 1.0), c["wisphot"])
    return egg


def grim_reaper_egg():
    c = reaper.C
    egg = shell([c["robe"], c["robe"], c["robe"], c["robe"], c["robedark"], c["robedark"], c["robedark"]])
    # a hood peak on top and a scythe stood beside it
    egg.block("HoodPeak", (-0.25, TOP - 0.05, 0.0), (0.25, TOP + 0.35, 0.45), c["robedark"]).bone = "top"
    a = WIDTHS[3] / 2
    egg.block("Handle", (a + 0.1, 0, -0.08), (a + 0.25, TOP + 0.3, 0.08), c["wood"])
    egg.block("Glow_Blade", (a - 0.2, TOP + 0.05, -0.9), (a + 0.25, TOP + 0.3, -0.08), c["blade"])
    egg.block("Glow_BladeTip", (a - 0.2, TOP - 0.25, -1.1), (a + 0.05, TOP + 0.1, -0.85), c["blade"])
    return egg


EGGS = [("BlackCat", black_cat_egg), ("Bat", bat_egg), ("PumpkinPup", pumpkin_pup_egg), ("PurpleTarantula", tarantula_egg),
        ("Werewolf", werewolf_egg), ("Ghost", ghost_egg), ("SkeletonDog", skeleton_dog_egg), ("TombstoneCrawler", tombstone_egg),
        ("ZombieBear", zombie_bear_egg), ("WispWolf", wisp_wolf_egg), ("GrimReaper", grim_reaper_egg)]

if __name__ == "__main__":
    O.EGGS = EGGS
    O.main(*sys.argv[1:], preview="/mnt/project-files/halloween/animals/eggs")
