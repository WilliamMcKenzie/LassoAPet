"""Jade Statue and Garnet Statue: World 2 Temple's two Epics (QM, Oct 13: "very badass").
A pair of temple guardian lions (foo dogs) come to life, carved from gemstone with gold
trim: a huge square head with an open roaring mouth and pyramid fangs, a heavy brow over
black eyes with glowing pupils, a chunky mane studded with round curls, a gold collar
with a bell under the chin, gold anklets and claws, a curled plume of a tail, and muscle
slabs on the shoulders and haunches.

The two are one build in two stones, each with its own crown:
  Jade:   green, a gold flame crown of spikes over the mane, gold studs down the spine.
  Garnet: deep red, two big gold horns sweeping back, garnet crystal shards down the spine.

Same bones as every quadruped (root, neck, EarL, EarR, Tail, Leg*), quad animations.

    python3 tools/temple_statues.py [out_dir] [renders_dir]

writes designs/temple/JadeStatue.bbmodel and GarnetStatue.bbmodel and the 3/4 renders.
"""

import json
import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import animal_designs as A  # noqa: E402
from animal_designs import Animal, quad_animations  # noqa: E402
from partlib import render  # noqa: E402
from horse_rig import pose  # noqa: E402
from snow_designs import pyramid  # noqa: E402

GOLD = (240, 190, 24)
GOLD_DARK = (196, 140, 16)
EYE_BLACK = (24, 24, 30)
MOUTH = (60, 20, 26)
FANG = (250, 246, 232)

STONES = {
    "Jade": dict(main=(64, 176, 110), dark=(34, 128, 80), light=(132, 222, 164), vein=(24, 96, 62),
                 glow=(150, 255, 200), crest="crown"),
    "Garnet": dict(main=(186, 28, 52), dark=(122, 14, 36), light=(236, 84, 102), vein=(92, 8, 26),
                   glow=(255, 214, 40), crest="horns"),
}


def statue(stone):
    s = STONES[stone]
    MAIN, DARK, LIGHT, VEIN = s["main"], s["dark"], s["light"], s["vein"]
    a = Animal(stone + "Statue", "Epic")

    # body: chest and back, gold band round the belly
    x, y0, y1, z0, z1 = 2.0, 3.2, 6.8, -3.0, 3.6
    a.body(x, y0, y1, z0, z1, MAIN)
    a.box("Belly", (-x - 0.05, y0 - 0.05, -0.6), (x + 0.05, y0 + 0.55, 0.6), GOLD, "root")
    # carved veins on the flanks
    for side, sx in (("L", -1), ("R", 1)):
        xa, xb = sorted((sx * x, sx * (x + A.PLATE)))
        a.box("Vein" + side + "1", (xa, 4.6, 0.9), (xb, 4.9, 2.6), VEIN, "root")
        a.box("Vein" + side + "2", (xa, 4.9, 2.3), (xb, 5.9, 2.6), VEIN, "root")
        # muscle slabs: shoulders and haunches
        ha, hb = sorted((sx * x, sx * (x + 0.35)))
        a.box("Shoulder" + side, (ha, 4.4, -2.9), (hb, 6.5, -1.3), DARK, "root")
        a.box("Haunch" + side, (ha, 3.8, 1.5), (hb, 6.3, 3.5), DARK, "root")
        ga, gb = sorted((sx * (x + 0.35), sx * (x + 0.45)))
        a.box("ShoulderGold" + side, (ga, 5.3, -2.5), (gb, 5.6, -1.7), GOLD, "root")

    # spine: gold ridge from the rider back to the tail, studs or crystal shards on it
    a.box("Ridge", (-0.45, y1, 1.6), (0.45, y1 + 0.3, z1), GOLD, "root")
    for i, z in enumerate((2.2, 3.1)):
        if s["crest"] == "horns":
            pyramid(a, f"Shard{i + 1}", (-0.4, y1 + 0.3, z - 0.4), (0.4, y1 + 0.3, z + 0.4), "+y", 1.6 - 0.4 * i, LIGHT, "root")
        else:
            pyramid(a, f"Stud{i + 1}", (-0.35, y1 + 0.3, z - 0.35), (0.35, y1 + 0.3, z + 0.35), "+y", 0.8, GOLD, "root")

    # thick legs, big paws with gold anklets and claws
    for leg in A.LEGS:
        sx = -1 if leg[1] == "L" else 1
        front = leg[0] == "F"
        xa, xb = sorted((sx * 0.55, sx * 2.0))
        za = z0 + 0.001 if front else z1 - 0.001 - 1.5
        zb = za + 1.5
        name = "Leg" + leg
        a.box(name, (xa, 1.3, za), (xb, y0, zb), MAIN, name)
        a.box("Anklet" + leg, (xa - 0.08 * (sx < 0), 0.9, za - 0.08), (xb + 0.08 * (sx > 0), 1.3, zb + 0.08), GOLD, name)
        a.box("Paw" + leg, (xa - 0.1 * (sx < 0), 0, za - 0.5), (xb + 0.1 * (sx > 0), 0.9, zb), LIGHT, name)
        cw = (xb - xa) / 3
        for k in range(3):
            cx = xa + cw * (k + 0.5)
            pyramid(a, f"Claw{leg}{k + 1}", (cx - 0.18, 0.05, za - 0.5), (cx + 0.18, 0.41, za - 0.5), "-z", 0.45, GOLD, name)
        a.pivots[name] = ((xa + xb) / 2, y0 - 0.025, zb - 0.05 if front else za + 0.05)

    # head: big square block out front, roaring mouth
    hx, hy0, hy1, hz0, hz1 = 1.8, 5.0, 8.6, -6.3, -3.0
    a.box("Head", (-hx, 6.2, hz0), (hx, hy1, hz1), MAIN, "neck")
    a.box("Jaw", (-1.5, hy0, -6.0), (1.5, 5.4, hz1), MAIN, "neck")
    a.box("Mouth", (-1.25, 5.4, -6.9), (1.25, 6.2, hz1), MOUTH, "neck")
    a.box("Tongue", (-0.6, 5.4, -6.7), (0.6, 5.6, -5.4), (232, 92, 110), "neck")
    a.box("Muzzle", (-1.3, 6.2, -7.1), (1.3, 7.1, hz0), LIGHT, "neck")
    a.box("Nose", (-0.55, 7.1, -7.15), (0.55, 7.5, -6.6), GOLD, "neck")
    a.box("Chin", (-1.3, hy0 - 0.2, -7.0), (1.3, 5.4, -6.0), LIGHT, "neck")
    # fangs: two long ones down from the muzzle, two short ones up from the chin
    for side, sx in (("L", -1), ("R", 1)):
        fa, fb = sorted((sx * 0.7, sx * 1.1))
        pyramid(a, "Fang" + side, (fa, 6.2, -7.05), (fb, 6.2, -6.65), "-y", 1.0, FANG, "neck")
        ta, tb = sorted((sx * 0.45, sx * 0.8))
        pyramid(a, "Tusk" + side, (ta, 5.4, -6.95), (tb, 5.4, -6.6), "+y", 0.55, FANG, "neck")
        # black eyes with glowing pupils on the front, under a heavy brow
        ea, eb = sorted((sx * 0.35, sx * 1.35))
        a.box("Eye" + side, (ea, 7.1, hz0 - 0.05), (eb, 7.9, hz0), EYE_BLACK, "neck")
        pa, pb = sorted((sx * 0.6, sx * 1.1))
        # Glow prefix: Neon in game (bbmodel_to_luau NEON)
        a.box("GlowPupil" + side, (pa, 7.25, hz0 - 0.08), (pb, 7.75, hz0 - 0.08 + A.PUPIL_BACK), s["glow"], "neck").neon = True
        # angry slant: a carved wedge over each eye's inner corner
        ia, ib = sx * 0.3, sx * 1.4
        a.tri("Scowl" + side, [(ia, 7.95), (ib, 7.95), (ia, 7.35)], hz0 - 0.15, hz0, DARK, "neck")
    a.box("Brow", (-1.9, 7.9, -6.75), (1.9, 8.5, -5.6), DARK, "neck")
    a.box("BrowGold", (-0.4, 7.95, -6.8), (0.4, 8.45, -6.75), GOLD, "neck")

    # mane: a thick ring round the head with rows of round curls on its face
    mz0, mz1 = -4.7, -3.0
    a.box("ManeL", (-3.0, 4.4, mz0), (-hx, 9.4, mz1), DARK, "neck")
    a.box("ManeR", (hx, 4.4, mz0), (3.0, 9.4, mz1), DARK, "neck")
    a.box("ManeTop", (-hx, hy1, mz0), (hx, 9.4, mz1), DARK, "neck")
    a.box("ManeChin", (-hx, 4.4, mz0), (hx, hy0, mz1), DARK, "neck")
    a.box("ManeCap", (-hx, hy1, -6.0), (hx, 9.1, mz0), DARK, "neck")
    a.box("ManeBack", (-2.6, 5.0, mz1), (2.6, 9.0, -1.6), DARK, "neck")
    curls = [(-2.4, 8.6), (-2.4, 7.2), (-2.4, 5.8), (2.4, 8.6), (2.4, 7.2), (2.4, 5.8),
             (-1.1, 9.0), (0, 9.0), (1.1, 9.0), (-0.7, 4.75), (0.7, 4.75)]
    for i, (cx, cy) in enumerate(curls):
        a.box(f"Curl{i + 1}", (cx - 0.35, cy - 0.35, mz0 - 0.25), (cx + 0.35, cy + 0.35, mz0), LIGHT, "neck")
    a.pivots["neck"] = (0, 6.2, -3.0)

    # gold collar round the neck and a bell under the chin
    a.box("Collar", (-2.1, 4.2, -3.3), (2.1, 4.8, -2.6), GOLD, "neck")
    a.box("Bell", (-0.45, 3.4, -4.4), (0.45, 4.4, -3.5), GOLD, "neck")
    a.box("BellSlit", (-0.3, 3.55, -4.45), (0.3, 3.7, -4.4), GOLD_DARK, "neck")

    # small drooping ears out of the mane's top corners
    for side, sx in (("L", -1), ("R", 1)):
        bone = "Ear" + side
        xa, xb = sorted((sx * 2.4, sx * 3.3))
        a.box(bone, (xa, 8.6, -4.2), (xb, 9.3, -3.4), MAIN, bone)
        a.pivots[bone] = ((xa + xb) / 2, 8.9, -3.8)

    # crest: a flame crown of gold spikes (Jade) or two big horns sweeping back (Garnet)
    if s["crest"] == "crown":
        for i, (cx, h) in enumerate(((-1.8, 1.0), (-0.9, 1.4), (0, 1.9), (0.9, 1.4), (1.8, 1.0))):
            pyramid(a, f"Crown{i + 1}", (cx - 0.4, 9.4, -4.3), (cx + 0.4, 9.4, -3.5), "+y", h, GOLD, "neck")
        a.box("GlowCrownGem", (-0.3, 9.6, -4.5), (0.3, 10.2, -4.3), s["glow"], "neck").neon = True
    else:
        for side, sx in (("L", -1), ("R", 1)):
            xa, xb = sorted((sx * 0.8, sx * 1.5))
            a.box("HornBase" + side, (xa, 9.1, -5.4), (xb, 10.0, -4.6), GOLD, "neck")
            ra, rb = sorted((sx * 0.85, sx * 1.45))
            a.box("Horn" + side, (ra, 9.8, -4.7), (rb, 10.5, -3.4), GOLD, "neck")
            pyramid(a, "HornTip" + side, (ra, 9.8, -3.4), (rb, 10.5, -3.4), "+z", 1.3, GOLD, "neck")
        a.box("GlowBrowGem", (-0.3, 8.5, -6.1), (0.3, 9.1, -5.9), s["glow"], "neck").neon = True

    # tail: rises off the rump and curls forward into a plume
    a.box("Tail", (-0.45, 5.6, z1), (0.45, 8.0, z1 + 0.9), MAIN, "Tail")
    a.box("TailCurl", (-0.7, 8.0, z1 - 0.6), (0.7, 9.0, z1 + 1.1), LIGHT, "Tail")
    a.box("TailBand", (-0.5, 7.0, z1 - 0.05), (0.5, 7.4, z1 + 0.95), GOLD, "Tail")
    pyramid(a, "TailTip", (-0.5, 9.0, z1 - 0.4), (0.5, 9.0, z1 + 0.6), "+y", 0.9, LIGHT, "Tail")
    a.pivots["Tail"] = (0, 6.0, z1)

    a.meta = {"seat": (0, 6.8, 0.3), "neck_loop": {"center": (0, 6.8, -4.6), "radius": 2.8}}
    a.animations = quad_animations
    return a


CAM = dict(eye=(-15, 12, -26), target=(0, 5.2, -1.2), W=640, H=640, fov=32)
BG = (238, 238, 232)


def shot(m):
    im = render(pose(m, None, 0), transparent=True, **CAM)
    bg = Image.new("RGBA", im.size, BG + (255,))
    bg.alpha_composite(im)
    return bg.convert("RGB")


def main(out=os.path.join(A.ROOT, "designs", "temple"), renders="/mnt/project-files/world2/temple/renders"):
    os.makedirs(out, exist_ok=True)
    os.makedirs(renders, exist_ok=True)
    for stone in STONES:
        a = statue(stone)
        m = A.build_animal(a, out)
        print(f"{a.name}: {len(a.parts)} parts")
        shot(m).save(os.path.join(renders, a.name + ".png"))


if __name__ == "__main__":
    main(*sys.argv[1:])
