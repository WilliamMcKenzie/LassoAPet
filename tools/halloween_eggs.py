"""Eggs for the Halloween world's animals (Oct 15), in the Garden eggs' style (tools/garden_eggs.py):
the octo shell coloured like the animal, a few of its features in real blocks and pyramids, googly
plate eyes on the front. (The Soul Horse keeps its own egg.)

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
from horse_egg_takes import LH, N, WIDTHS, shell, layer_of  # noqa: E402
import halloween_black_cat as cat, halloween_bat as bat, halloween_pumpkin_pup as pup  # noqa: E402,E401
import halloween_tarantula as spider, halloween_werewolf as wolf, halloween_ghost as ghost  # noqa: E402,E401
import halloween_skeleton_dog as dog, halloween_tombstone as tomb, halloween_zombie_bear as bear  # noqa: E402,E401
import halloween_wisp_wolf as wisp, halloween_grim_reaper as reaper  # noqa: E402,E401


# (the Garden eggs' helpers, copied: tools/garden_eggs.py)
WHITE, PUPIL = (255, 255, 255), (24, 22, 30)
TOP = N * LH


def fz(y, out=0.0):
    """The front face's z at height y, plus out further forward."""
    return -WIDTHS[layer_of(y)] / 2 - out


def half(y):
    return WIDTHS[layer_of(y)] / 2


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


def eyes(egg, y, size=0.34, gap=0.1, glow=None, white=WHITE, out=0.0):
    """Two googly plate eyes on the front at height y (pupils glow on the big ones)."""
    z = fz(y, out)
    for s in (-1, 1):
        n = "LR"[s > 0]
        x0, x1 = sorted((s * gap, s * (gap + size)))
        egg.block(f"Eye{n}", (x0, y - size / 2, z - 0.05), (x1, y + size / 2, z + 0.01), white)
        p = size * 0.5
        cx = (x0 + x1) / 2
        egg.block(f"{'Glow_Pupil' if glow else 'Pupil'}{n}", (cx - p / 2, y - p / 2 - 0.03, z - 0.08),
                  (cx + p / 2, y + p / 2 - 0.03, z - 0.04), glow or PUPIL)


def spot(egg, name, x, y, w, color, side=0):
    """A raised spot on the front (side=0) or on a side (side=+-1), with real depth."""
    if side == 0:
        z = fz(y)
        egg.block(name, (x - w / 2, y - w / 2, z - 0.06), (x + w / 2, y + w / 2, z + 0.01), color)
    else:
        xx = side * half(y)
        egg.block(name, (min(xx, xx + side * 0.06), y - w / 2, x - w / 2), (max(xx, xx + side * 0.06), y + w / 2, x + w / 2), color)


def ring_spikes(egg, name, y, n, L, hw, color, tilt=0.0, out=0.0, offset=0.0, skip_front=0.0):
    """Pyramids pointing out round the egg at height y (tilt > 0 points them up)."""
    r = half(y) + out
    for k in range(n):
        a = 2 * math.pi * (k + offset) / n
        if abs(math.atan2(math.sin(a), math.cos(a))) < skip_front:
            continue  # leave the face clear
        d = np.array([math.sin(a), tilt, -math.cos(a)])
        pyr(egg, f"{name}{k}", (r * math.sin(a), y, -r * math.cos(a)), d, L, hw, hw * 0.6, color)


def ears(egg, col, x=0.3, h=0.45, w=0.18):
    for s in (-1, 1):
        pyr(egg, f"Ear{'LR'[s > 0]}", (s * x, TOP - 0.05, 0), (s * 0.2, 1, 0), h, w, w * 0.7, col, bone="top")


def black_cat_egg():
    c = cat.C
    egg = shell([c["fur"]] * 4 + [c["collar"]] + [c["fur"]] * 2)
    eyes(egg, 2.2)
    spot(egg, "Nose", 0, 1.75, 0.18, c["pink"])
    spot(egg, "Bell", 0, 1.38, 0.22, c["bell"])
    ears(egg, c["fur"])
    return egg


def bat_egg():
    c = bat.C
    egg = shell([c["furdark"]] + [c["fur"]] * 6)
    eyes(egg, 2.0)
    for s in (-1, 1):
        pyr(egg, f"Fang{'LR'[s > 0]}", (s * 0.15, 1.45, fz(1.5) - 0.03), (0, -1, 0), 0.22, 0.06, 0.04, c["fang"])
        pyr(egg, f"Wing{'LR'[s > 0]}", (s * 0.75, 1.8, 0.1), (s, 0.3, 0.2), 0.6, 0.3, 0.06, c["wing"])
    ears(egg, c["fur"], h=0.6)
    return egg


def pumpkin_pup_egg():
    c = pup.C
    egg = shell([c["fur"]] * 2 + [c["pumpkin"]] * 5)
    eyes(egg, 2.3)
    egg.block("Glow_Grin", (-0.4, 1.6, fz(1.65) - 0.06), (0.4, 1.78, fz(1.65) + 0.01), c["glow"])
    egg.block("Stem", (-0.1, TOP - 0.02, -0.1), (0.1, TOP + 0.35, 0.1), c["stem"]).bone = "top"
    return egg


def tarantula_egg():
    c = spider.C
    egg = shell([c["furdark"]] + [c["fur"]] * 2 + [c["orange"]] + [c["fur"]] * 3)
    eyes(egg, 2.3)
    for s in (-1, 1):
        pyr(egg, f"Fang{'LR'[s > 0]}", (s * 0.15, 1.85, fz(1.9) - 0.03), (0, -1, 0), 0.25, 0.07, 0.05, c["orange"])
    ring_spikes(egg, "Leg", 1.0, 8, 0.4, 0.08, c["furdark"], tilt=-0.3, offset=0.5)
    return egg


def werewolf_egg():
    c = wolf.C
    egg = shell([c["shorts"]] + [c["fur"]] * 6)
    eyes(egg, 2.3)
    egg.block("Snout", (-0.3, 1.5, fz(1.65) - 0.15), (0.3, 1.85, fz(1.65) + 0.01), c["furlight"])
    egg.block("Nose", (-0.12, 1.75, fz(1.65) - 0.2), (0.12, 1.87, fz(1.65) - 0.12), c["nose"])
    ears(egg, c["furdark"], h=0.6)
    return egg


def ghost_egg():
    c = ghost.C
    egg = shell([c["ghostdark"]] + [c["ghost"]] * 6)
    eyes(egg, 2.3)
    spot(egg, "Mouth", 0, 1.8, 0.2, c["mouth"])
    return egg


def skeleton_dog_egg():
    c = dog.C
    egg = shell([c["bone"]] * 3 + [c["collar"]] + [c["bone"]] * 3)
    eyes(egg, 2.35, white=c["bone"])
    for k, y in enumerate((0.7, 1.0, 1.3)):
        egg.block(f"Rib{k}", (-0.5, y, fz(y) - 0.04), (0.5, y + 0.1, fz(y) + 0.01), c["socket"])
    ears(egg, c["bone"], h=0.4)
    return egg


def tombstone_egg():
    c = tomb.C
    egg = shell([c["stonedark"]] + [c["stone"]] * 5 + [c["moss"]])
    eyes(egg, 2.4)
    egg.block("Plaque", (-0.4, 1.2, fz(1.4) - 0.06), (0.4, 1.7, fz(1.4) + 0.01), c["plaque"])
    egg.block("Letters", (-0.28, 1.4, fz(1.4) - 0.09), (0.28, 1.5, fz(1.4) - 0.05), c["letters"])
    return egg


def zombie_bear_egg():
    c = bear.C
    egg = shell([c["furdark"]] + [c["fur"]] * 6)
    eyes(egg, 2.3)
    spot(egg, "Patch", -0.45, 1.2, 0.35, c["patch"])
    egg.block("Stitch", (-0.65, 1.17, fz(1.2) - 0.1), (-0.25, 1.23, fz(1.2) - 0.05), c["stitch"])
    spot(egg, "Nose", 0, 1.75, 0.2, c["stitch"])
    for s in (-1, 1):
        egg.block(f"Ear{'LR'[s > 0]}", (s * 0.3 - 0.13, TOP - 0.05, -0.1), (s * 0.3 + 0.13, TOP + 0.2, 0.1), c["furdark"]).bone = "top"
    return egg


def wisp_wolf_egg():
    c = wisp.C
    egg = shell([c["furdark"]] + [c["fur"]] * 6)
    eyes(egg, 2.3)
    egg.block("Snout", (-0.3, 1.5, fz(1.65) - 0.15), (0.3, 1.85, fz(1.65) + 0.01), c["snout"])
    ring_spikes(egg, "Glow_Wisp", 1.0, 6, 0.35, 0.1, c["wisp"], tilt=0.5, offset=0.5, skip_front=0.6)
    ears(egg, c["furdark"], h=0.6)
    return egg


def grim_reaper_egg():
    c = reaper.C
    egg = shell([c["robe"]] * 5 + [c["robedark"]] * 2)
    z = min(fz(2.0), fz(2.55))  # (the face spans two layers: in front of the wider)
    egg.block("Face", (-0.4, 2.0, z - 0.08), (0.4, 2.55, z + 0.01), c["skull"])
    eyes(egg, 2.3, size=0.26, gap=0.06, out=0.1 + fz(2.3) - z)
    egg.block("Handle", (0.85, 0.3, -0.06), (0.97, 3.2, 0.06), c["wood"])
    egg.block("Glow_Blade", (0.3, 3.0, -0.08), (1.0, 3.2, 0.08), c["blade"])
    return egg


EGGS = [("BlackCat", black_cat_egg), ("Bat", bat_egg), ("PumpkinPup", pumpkin_pup_egg), ("PurpleTarantula", tarantula_egg),
        ("Werewolf", werewolf_egg), ("Ghost", ghost_egg), ("SkeletonDog", skeleton_dog_egg), ("TombstoneCrawler", tombstone_egg),
        ("ZombieBear", zombie_bear_egg), ("WispWolf", wisp_wolf_egg), ("GrimReaper", grim_reaper_egg)]

if __name__ == "__main__":
    O.EGGS = EGGS
    O.main(*sys.argv[1:], preview="/mnt/project-files/halloween/animals/eggs")
