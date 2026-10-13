"""Marble Colossus: World 2 Meadow's Epic. A gorilla-stance marble golem: big
shoulders and arms that reach the ground (the front legs), short stumpy hind
legs, a small head set low between the shoulders under a heavy brow, grey
veins through the marble and gold bracers and headband (World 2's gold-on-marble).
Built on animal_designs.Animal so it shares the quadruped rig and animations.

    python3 tools/marble_colossus.py [out_dir]

writes designs/world2/MarbleColossus.bbmodel and renders to
/mnt/project-files/animals/marble_colossus/.
"""

import json
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import animal_designs as A  # noqa: E402
from partlib import render  # noqa: E402
from horse_rig import pose  # noqa: E402

MARBLE = (246, 244, 238)
VEIN = (150, 152, 162)
SHADE = (208, 205, 198)
GOLD = (240, 190, 24)
FIST = (226, 223, 216)


def colossus():
    a = A.Animal("MarbleColossus", "Epic")
    a.bone_order = [("root", None), ("neck", "root")] + [("Leg" + leg, "root") for leg in A.LEGS]

    # torso: tall chest, lower back with a sloped hump between (gorilla stance), grey veins
    a.body(2.0, 3.8, 7.0, -3.0, 2.4, MARBLE, [(-0.2, 0.5, MARBLE), (0.5, 0.8, VEIN), (0.8, 2.4, MARBLE)])
    a.box("Chest", (-2.0, 3.8, -3.0), (2.0, 8.0, -1.6), MARBLE, "root")
    a.box("ChestVein", (-2.0, 3.8, -1.6), (2.0, 8.0, -1.3), VEIN, "root")
    a.box("Chest2", (-2.0, 3.8, -1.3), (2.0, 8.0, -0.2), MARBLE, "root")
    a.wedge("Hump", (-2.0, 7.0, -0.2), (2.0, 8.0, 1.6), MARBLE, "root", "up_back")

    # arms (front legs): hang outside the torso to the ground, gold bracer over the fist
    for leg, sx in (("FL", -1), ("FR", 1)):
        name = "Leg" + leg
        xa, xb = sorted((sx * 2.0, sx * 3.6))
        z0, z1 = -3.3, -1.5
        a.box("Fist" + leg, (xa - 0.1 * (sx < 0), 0, z0 - 0.15), (xb + 0.1 * (sx > 0), 1.3, z1 + 0.05), FIST, name)
        a.box("Bracer" + leg, (xa - 0.05 * (sx < 0), 1.3, z0 - 0.05), (xb + 0.05 * (sx > 0), 1.9, z1 + 0.05), GOLD, name)
        a.box("Fore" + leg, (xa, 1.9, z0), (xb, 4.2, z1), MARBLE, name)
        a.box("Elbow" + leg, (xa, 4.2, z0), (xb, 4.5, z1), VEIN, name)
        a.box("Arm" + leg, (xa, 4.5, z0), (xb, 7.2, z1), MARBLE, name)
        pa, pb = sorted((sx * 1.8, sx * 3.9))
        a.box("Shoulder" + leg, (pa, 7.2, z0 - 0.2), (pb, 8.4, z1 + 0.3), SHADE, name)
        a.pivots[name] = ((xa + xb) / 2, 7.8, z1)

    # short stumpy hind legs with a wider foot
    for leg, sx in (("HL", -1), ("HR", 1)):
        name = "Leg" + leg
        xa, xb = sorted((sx * 0.5, sx * 1.8))
        z0, z1 = 0.8, 2.2
        a.box("Foot" + leg, (xa, 0, z0 - 0.3), (xb, 0.9, z1), FIST, name)
        a.box(name, (xa, 0.9, z0), (xb, 3.801, z1), MARBLE, name)
        a.pivots[name] = ((xa + xb) / 2, 3.775, z0 + 0.05)

    # head: small, low and out front between the shoulders, heavy brow, gold headband
    a.box("Head", (-1.2, 4.9, -4.9), (1.2, 7.3, -2.999), MARBLE, "neck")
    a.box("Brow", (-1.35, 6.7, -5.25), (1.35, 7.5, -3.0), SHADE, "neck")
    a.box("Band", (-1.25, 7.5, -5.0), (1.25, 7.9, -3.0), GOLD, "neck")
    a.box("Jaw", (-1.0, 4.9, -5.1), (1.0, 5.4, -4.9), VEIN, "neck")
    for side, sx in (("L", -1), ("R", 1)):
        xa, xb = sorted((sx * 0.25, sx * 1.0))
        a.box("Eye" + side, (xa, 5.7, -4.95), (xb, 6.65, -4.9), A.EYE_WHITE, "neck")
        pa, pb = sorted((sx * 0.4, sx * 0.8))
        a.box("Pupil" + side, (pa, 5.8, -4.98), (pb, 6.4, -4.93 + A.PUPIL_BACK), A.PUPIL, "neck")
    a.pivots["neck"] = (0, 7.3, -3.0)

    a.meta = {"seat": (0, 8.4, -0.6), "neck_loop": {"center": (0, 6.1, -4.0), "radius": 1.6}}

    base = a.animations
    a.animations = lambda: {k: (L, {b: t for b, t in tr.items() if b in dict(a.bone_order)})
                            for k, (L, tr) in base().items()}
    return a


CAM = dict(eye=(-19, 12, -21), target=(0, 4.6, -0.5), W=420, H=420, fov=36)
SIDE = dict(eye=(-30, 6, -1), target=(0, 4.6, -1), W=420, H=420, fov=34)
FRONT = dict(eye=(-6, 8, -24), target=(0, 4.6, -1), W=420, H=420, fov=34)


def main(out=os.path.join(A.ROOT, "designs", "world2"), shots="/mnt/project-files/animals/marble_colossus"):
    os.makedirs(out, exist_ok=True)
    os.makedirs(shots, exist_ok=True)
    a = colossus()
    m = A.build_animal(a, out)
    print(f"{a.name}: {len(a.parts)} parts")
    horse = json.load(open(os.path.join(A.ROOT, "designs", "animals", "Horse.bbmodel")))
    from PIL import Image
    tiles = [render(pose(horse, None, 0), **CAM), render(pose(m, None, 0), **CAM),
             render(pose(m, None, 0), **FRONT), render(pose(m, None, 0), **SIDE)]
    im = Image.new("RGB", (420 * len(tiles), 420))
    for i, t in enumerate(tiles):
        im.paste(t, (420 * i, 0))
    A.label(im, ["Horse (for size)", "Marble Colossus · Epic", "Front", "Side"]).save(os.path.join(shots, "MarbleColossus.png"))
    frames = []
    for name, L, n in (("walk", None, 20), ("gallop", None, 16)):
        anim = A.anim_named(m, name)
        for i in range(n):
            t = i / n * anim["length"]
            frames.append(A.label(render(pose(m, anim, t), **SIDE), [name]))
    A.gif(os.path.join(shots, "MarbleColossus_anims.gif"), frames, fps=20)
    json.dump(m, open(os.path.join(shots, "MarbleColossus.bbmodel"), "w"), separators=(",", ":"))


if __name__ == "__main__":
    main(*sys.argv[1:])
