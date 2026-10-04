"""War Elephant (Rare, Large): a Rhino-style elephant in simple dark plate armour.

Superseded (Oct 4): the game uses QM's edit, designs/godlands/WarElephant.bbmodel and
designs/eggs/c_style/WarElephantEgg.bbmodel. This script writes the first draft into
designs/war only; never point it at QM's files.

Run: python3 tools/war_elephant.py [out_dir]   writes WarElephant.bbmodel, WarElephantEgg.bbmodel, previews
QM's file: python3 tools/bbmodel_to_luau.py --zyx designs/godlands/WarElephant.bbmodel src/shared/Animals/WarElephantModel.luau

Built like the Rhino (tools/animal_designs.py): the same Animal blocks and rig, so the
legs, neck, ears and tail bend the way QM's rules say, with the horse's idle and walk
and the leap gallop. The trunk and tusks hang off the neck bone.
"""

import json
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import animal_designs as A  # noqa: E402
import horse_egg_takes as HE  # noqa: E402
from snow_designs import pyramid  # noqa: E402
from horse_rig import pose  # noqa: E402
from partlib import render  # noqa: E402
from PIL import Image  # noqa: E402

SKIN = (156, 152, 166)
SKIN_DARK = (122, 118, 134)
ARMOUR = (56, 60, 74)
TRIM = (98, 104, 122)
TUSK = (246, 238, 214)
NAIL = (226, 218, 198)
SPIKE = (150, 156, 174)


def war_elephant():
    a = A.Animal("WarElephant", "Rare")
    a.body(2.2, 2.9, 7.6, -3.2, 3.8, SKIN)
    a.legs(0.6, 2.1, 1.8, 0.5, SKIN, NAIL)
    # big head right on the body's front, trunk hanging down and curling forward
    a.box("Head", (-1.6, 4.8, -6.4), (1.6, 8.2, -3.199), SKIN, "neck")
    a.box("Trunk", (-0.6, 3.2, -7.4), (0.6, 5.6, -6.4), SKIN, "neck")
    a.box("Trunk2", (-0.5, 1.6, -7.5), (0.5, 3.2, -6.5), SKIN, "neck")
    a.box("TrunkTip", (-0.45, 1.0, -8.1), (0.45, 1.6, -6.7), SKIN_DARK, "neck")
    for side, sx in (("L", -1), ("R", 1)):
        xa, xb = sorted((sx * 0.85, sx * 1.3))
        a.box("Tusk" + side, (xa, 4.3, -7.6), (xb, 4.8, -5.4), TUSK, "neck")
        a.box("TuskTip" + side, (xa + 0.05 * sx, 4.8, -8.0), (xb - 0.05 * sx, 5.3, -7.4), TUSK, "neck")
        # steel spikes capping the tusks
        lo, hi = sorted((sx * 0.85, sx * 1.3))
        pyramid(a, "TuskSpike" + side, (lo, 5.3, -8.0), (hi, 5.3, -7.4), "+y", 0.9, SPIKE, "neck")
        pyramid(a, "TuskSpikeFront" + side, (lo, 4.3, -7.6), (hi, 4.8, -7.6), "-z", 0.5, SPIKE, "neck")
        # big flat ears on the head's sides, folding back from their front edge
        xa, xb = sorted((sx * 1.6, sx * 2.05))
        bone = "Ear" + side
        a.box(bone, (xa, 4.4, -5.0), (xb, 8.6, -1.8), SKIN_DARK, bone)
        a.box(bone + "Lobe", (xa, 3.4, -4.2), (xb, 4.4, -1.8), SKIN_DARK, bone)
        a.pivots[bone] = (sx * 1.825, 4.4, -5.0)
    a.eyes(1.6, 6.5, 7.3, -6.2, -5.4)
    a.pivots["neck"] = (0, 7.6, -3.2)
    a.tail(0.25, 7.0, 4.4, 0.5, SKIN, (60, 56, 64), tip_h=0.9)

    # armour: a head plate, a plated blanket over the back, a skirt of plates down each side
    a.box("HeadPlate", (-1.3, 6.0, -6.75), (1.3, 8.4, -6.399), ARMOUR, "neck")
    a.box("HeadRidge", (-0.3, 6.2, -6.95), (0.3, 8.6, -6.75), TRIM, "neck")
    a.box("BackPlate", (-2.4, 5.8, -2.9), (2.4, 8.0, 3.4), ARMOUR, "root")
    a.box("BackTrim", (-2.45, 5.6, -2.95), (2.45, 5.9, 3.45), TRIM, "root")
    for i, (z0, z1) in enumerate(((-3.0, -0.9), (-0.8, 1.3), (1.4, 3.5))):
        for side, sx in (("L", -1), ("R", 1)):
            xa, xb = sorted((sx * 2.2, sx * 2.5))
            a.box(f"Skirt{side}{i + 1}", (xa, 3.7, z0), (xb, 5.6, z1), ARMOUR, "root")
    # pyramid spikes: a row down the back, one on each side plate, one on the head plate
    for k, z in enumerate((-2.2, -0.4, 1.4, 2.8)):
        pyramid(a, f"Spine{k + 1}", (-0.4, 8.0, z - 0.4), (0.4, 8.0, z + 0.4), "+y", 1.1, SPIKE, "root")
    for i, z in enumerate((-1.95, 0.25, 2.45)):
        for side, sx in (("L", -1), ("R", 1)):
            pyramid(a, f"SideSpike{side}{i + 1}", (sx * 2.5, 4.3, z - 0.35), (sx * 2.5, 5.0, z + 0.35), ("+x" if sx > 0 else "-x"), 0.7, SPIKE, "root")
    pyramid(a, "HeadSpike", (-0.3, 8.6, -6.95), (0.3, 8.6, -6.35), "+y", 0.9, SPIKE, "neck")
    a.meta = {"seat": (0, 8.1, 1.2), "neck_loop": {"center": (0, 6.4, -4.6), "radius": 2.3}}
    return a


def war_elephant_egg():
    egg = HE.shell([ARMOUR, SKIN, SKIN, SKIN, SKIN, SKIN, SKIN])
    # big flat ears out to the sides of the top shell
    y0, y1 = 4 * HE.LH + 0.1, 6 * HE.LH + 0.2
    for side, sx in (("L", -1), ("R", 1)):
        x = HE.WIDTHS[5] / 2
        xa, xb = sorted((sx * (x - 0.05), sx * (x + 0.25)))
        egg.block("Ear" + side, (xa, y0, -0.3), (xb, y1, 0.5), SKIN_DARK).bone = "top"
    # trunk down the front, tusks either side
    zf = -HE.WIDTHS[4] / 2
    egg.block("Trunk", (-0.22, 2 * HE.LH, zf - 0.3), (0.22, 5 * HE.LH, zf + 0.05), SKIN_DARK).bone = "top"
    for side, sx in (("L", -1), ("R", 1)):
        xa, xb = sorted((sx * 0.35, sx * 0.55))
        egg.block("Tusk" + side, (xa, 3 * HE.LH, zf - 0.45), (xb, 3 * HE.LH + 0.2, zf + 0.05), TUSK).bone = "top"
    # dark armour plates: a band round the crack and a ridge down the back
    for i in (3,):
        HE.front_plate(egg, f"Band{i}", -0.6, 0.6, i * HE.LH, (i + 1) * HE.LH, ARMOUR, depth=0.05, plain=False)
    HE.back_ridge(egg, ARMOUR, range(1, HE.N), name="Plate", out=0.15, hw=0.45)
    for i in (2, 4, 5):
        z = HE.WIDTHS[i] / 2 + 0.15
        y = (i + 0.5) * HE.LH
        pyramid(egg, f"Spike{i}", (-0.2, y - 0.2, z), (0.2, y + 0.2, z), "+z", 0.4, SPIKE, "top" if i >= 4 else "bottom")
    return egg


def main(out="designs/war"):
    os.makedirs(out, exist_ok=True)
    a = war_elephant()
    m = A.build_animal(a, out)
    with open(os.path.join(out, "meta.json"), "w") as f:
        json.dump({a.name: dict(rarity=a.rarity, **a.meta)}, f, indent=1)
    rhino = A.build_animal(A.rhino(), "/tmp")
    cams = [dict(eye=(-22, 13, -24), target=(0, 4.8, -1), W=520, H=480, fov=36),
            dict(eye=(26, 10, 18), target=(0, 4.8, 0), W=520, H=480, fov=36),
            dict(eye=(-34, 6, -1), target=(0, 4.8, -1), W=520, H=480, fov=34)]
    tiles = [render(pose(m, None, 0), **c) for c in cams]
    tiles.append(render(pose(rhino, None, 0), **cams[2]))
    sheet = Image.new("RGB", (520 * len(tiles), 480))
    for i, t in enumerate(tiles):
        sheet.paste(t, (520 * i, 0))
    sheet.save(os.path.join(out, "WarElephant.png"))
    gallop = A.anim_named(m, "gallop")
    frames = [render(pose(m, gallop, i / 16 * gallop["length"]), **cams[2]).resize((390, 360)) for i in range(16)]
    A.gif(os.path.join(out, "WarElephant_gallop.gif"), frames, fps=20)
    egg = war_elephant_egg()
    HE.build(egg, "WarElephantEgg", HE.E.SPLIT, out)
    egg_tiles = [render(egg.parts, W=360, H=360, fov=28, **v) for v in HE.VIEWS]
    es = Image.new("RGB", (720, 360))
    for i, t in enumerate(egg_tiles):
        es.paste(t, (360 * i, 0))
    es.save(os.path.join(out, "WarElephantEgg.png"))
    print(f"WarElephant: {len(a.parts)} parts, egg {len(egg.parts)} parts")


if __name__ == "__main__":
    main(*sys.argv[1:])
