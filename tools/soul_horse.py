"""Soul Horse (Godlands): QM's horse rig and layout (animal_designs.horse_body) in the
look of QM's reference (designs/godlands/SoulHorse_ref.bbmodel): a dark ghost-green
horse in steel barding (head, neck, chest, shoulder and flank plates, a saddle cloth),
glowing cyan eyes, pyramid spikes on the crest and rump, and ragged tatters (downward
pyramids) under the belly. Idle and walk are QM's horse's, the gallop the leap.

Run: python3 tools/soul_horse.py [out_dir]   writes SoulHorse.bbmodel and previews
then: python3 tools/bbmodel_to_luau.py designs/godlands/SoulHorse.bbmodel src/shared/Animals/SoulHorseModel.luau
"""

import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import animal_designs as A  # noqa: E402
from horse_rig import pose  # noqa: E402
from partlib import render  # noqa: E402
from snow_designs import pyramid  # noqa: E402

COAT = (34, 60, 52)
MANE = (24, 40, 36)
HOOF = (196, 186, 120)
STEEL = (132, 144, 162)
TRIM = (84, 88, 112)
CLOTH = (70, 74, 46)
TATTER = (112, 96, 156)
SOUL = (90, 240, 230)


def soul_horse():
    a = A.Animal("SoulHorse", "Epic")
    A.horse_body(a, COAT, MANE, HOOF, ear_inner=TRIM, stripe=False)
    for n in ("EyeL", "EyeR", "PupilL", "PupilR"):
        a.remove(n)
    for side, sx in (("L", -1), ("R", 1)):
        xa, xb = sorted((sx * 1.1, sx * 1.16))
        a.box("GlowEye" + side, (xa, 9.4, -3.6), (xb, 9.9, -2.6), SOUL, "neck")
        # cheek guards on the head, shoulder and flank plates, the saddle cloth
        xa, xb = sorted((sx * 1.1, sx * 1.3))
        a.box("Cheek" + side, (xa, 8.3, -3.9), (xb, 9.1, -1.4), STEEL, "neck")
        xa, xb = sorted((sx * 1.6, sx * 1.85))
        a.box("Pauldron" + side, (xa, 4.4, -2.75), (xb, 6.6, -0.9), STEEL, "root")
        a.box("PauldronTrim" + side, (xa - 0.02 * sx, 4.2, -2.8), (xb + 0.02 * sx, 4.45, -0.85), TRIM, "root")
        a.box("Flank" + side, (xa, 4.4, 1.4), (xb, 6.6, 3.3), STEEL, "root")
        a.box("FlankTrim" + side, (xa - 0.02 * sx, 4.2, 1.35), (xb + 0.02 * sx, 4.45, 3.35), TRIM, "root")
        xa, xb = sorted((sx * 1.6, sx * 1.7))
        a.box("Cloth" + side, (xa, 4.6, -0.9), (xb, 6.5, 1.4), CLOTH, "root")
    a.box("HeadPlate", (-1.15, 10.5, -3.9), (1.15, 10.75, -2.3), STEEL, "neck")
    a.box("Crinet", (-1.0, 5.4, -2.95), (1.0, 8.3, -2.7), STEEL, "neck")
    a.box("Peytral", (-1.85, 3.9, -3.0), (1.85, 6.2, -2.75), STEEL, "root")
    a.box("PeytralTrim", (-1.9, 3.7, -3.05), (1.9, 3.95, -2.7), TRIM, "root")
    a.box("Saddle", (-1.7, 6.5, -0.9), (1.7, 6.8, 1.4), CLOTH, "root")
    # pyramid spikes: up the crest and out the back of the mane, two on the rump
    pyramid(a, "CrestSpike1", (-0.3, 11.1, -2.25), (0.3, 11.1, -1.65), "+y", 1.1, STEEL, "neck")
    pyramid(a, "CrestSpike2", (-0.3, 11.1, -1.3), (0.3, 11.1, -0.7), "+y", 0.8, STEEL, "neck")
    pyramid(a, "ManeSpike1", (-0.3, 10.2, -0.6), (0.3, 10.8, -0.6), "+z", 0.8, STEEL, "neck")
    pyramid(a, "ManeSpike2", (-0.3, 9.0, -0.6), (0.3, 9.6, -0.6), "+z", 0.6, STEEL, "neck")
    pyramid(a, "RumpSpike1", (-0.3, 6.5, 1.8), (0.3, 6.5, 2.4), "+y", 0.9, STEEL, "root")
    pyramid(a, "RumpSpike2", (-0.25, 6.5, 2.7), (0.25, 6.5, 3.2), "+y", 0.6, STEEL, "root")
    # ragged tatters hanging under the belly
    for i, z in enumerate((-1.2, 0.0, 1.2)):
        for side, sx in (("L", -1), ("R", 1)):
            xa, xb = sorted((sx * 0.6, sx * 1.5))
            pyramid(a, f"Tatter{side}{i + 1}", (xa, 3.5, z - 0.45), (xb, 3.5, z + 0.45), "-y", 0.8 if i % 2 else 1.1, TATTER, "root")
    return a


def main(out="designs/godlands"):
    os.makedirs(out, exist_ok=True)
    a = soul_horse()
    m = A.build_animal(a, out)
    cams = [dict(eye=(-19, 12, -21), target=(0, 5.6, -0.5), W=460, H=480, fov=36),
            dict(eye=(22, 9, 16), target=(0, 5.6, 0), W=460, H=480, fov=36),
            dict(eye=(-30, 6, -1), target=(0, 5.6, -1), W=460, H=480, fov=34)]
    sheet = Image.new("RGB", (460 * len(cams), 480))
    for i, c in enumerate(cams):
        sheet.paste(render(pose(m, None, 0), **c), (460 * i, 0))
    sheet.save(os.path.join(out, "SoulHorse.png"))
    gallop = A.anim_named(m, "gallop")
    frames = [render(pose(m, gallop, i / 16 * gallop["length"]), **cams[2]).resize((345, 360)) for i in range(16)]
    A.gif(os.path.join(out, "SoulHorse_gallop.gif"), frames, fps=20)
    print(f"SoulHorse: {len(a.parts)} parts")


if __name__ == "__main__":
    main(*sys.argv[1:])
