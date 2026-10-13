"""Giant Golem: World 2 Woodland Maze's Legendary. An XXL stone giant (QM: "like
the golem from clash of clans, xxl giant stone guy with glowing ORANGE eyes"),
our own take: knuckle-walking on huge boulder fists, massive stacked boulder
shoulders, a tiny head sunk low between them under a heavy brow with glowing
orange eyes, a glowing orange crack down the chest, short stumpy hind legs, and
the woodland on its back (moss caps with autumn-orange leaf tufts).
Built on animal_designs.Animal so it shares the quadruped rig and animations.

    python3 tools/giant_golem.py [out_dir]

writes designs/woodland/GiantGolem.bbmodel and the render to
/mnt/project-files/world2/woodland/renders/GiantGolem.png.
"""

import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import animal_designs as A  # noqa: E402
from partlib import render  # noqa: E402
from horse_rig import pose  # noqa: E402

STONE = (150, 142, 132)
DARK = (112, 104, 96)
LIGHT = (180, 173, 162)
MOSS = (110, 186, 68)
LEAF = (242, 109, 57)  # the Woodland walls' autumn orange #F26D39
GLOW = (255, 156, 20)


def golem():
    a = A.Animal("GiantGolem", "Legendary")
    a.bone_order = [("root", None), ("neck", "root")] + [("Leg" + leg, "root") for leg in A.LEGS]

    # torso: deep chest up front, lower back behind it where the rider sits
    a.body(2.4, 3.8, 8.4, -0.6, 3.6, STONE)
    a.box("Chest", (-2.7, 3.8, -3.4), (2.7, 9.0, -0.6), DARK, "root")
    a.box("ChestPlate", (-2.2, 3.9, -3.7), (2.2, 5.6, -3.4), STONE, "root")
    # glowing crack down the chest plate (Glow prefix: Neon in game)
    a.box("GlowCrack1", (-0.3, 3.9, -3.8), (0.3, 4.9, -3.6), GLOW, "root").neon = True
    a.box("GlowCrack2", (0.1, 4.7, -3.8), (0.8, 5.3, -3.6), GLOW, "root").neon = True
    a.box("GlowCrack3", (-0.9, 4.3, -3.8), (-0.2, 4.8, -3.6), GLOW, "root").neon = True
    a.box("Hip", (-2.2, 4.0, 3.6), (2.2, 7.8, 4.1), DARK, "root")
    # moss on the back with leaf tufts, and two boulder humps behind the rider
    a.box("MossBack", (-2.0, 8.4, -0.6), (2.0, 8.6, 3.0), MOSS, "root")
    a.box("Hump1", (-1.4, 7.8, 3.0), (1.4, 9.4, 4.2), LIGHT, "root")
    a.box("Hump1Moss", (-1.2, 9.4, 3.2), (1.2, 9.6, 4.0), MOSS, "root")
    a.box("Leaf1", (0.3, 9.6, 3.4), (0.8, 9.9, 3.8), LEAF, "root")
    a.box("Leaf2", (-1.3, 8.6, 2.2), (-0.8, 8.9, 2.6), LEAF, "root")

    # arms (front legs): boulder shoulders, thick arms, giant fists on the ground
    for leg, sx in (("FL", -1), ("FR", 1)):
        name = "Leg" + leg

        def xs(a0, a1):
            return tuple(sorted((sx * a0, sx * a1)))

        x0, x1 = xs(2.4, 4.4)
        a.box("Arm" + leg, (x0, 3.0, -3.0), (x1, 7.6, -0.9), STONE, name)
        r0, r1 = xs(4.4, 4.8)
        a.box("Elbow" + leg, (r0, 4.2, -2.6), (r1, 5.6, -1.3), LIGHT, name)
        f0, f1 = xs(2.4, 4.9)
        a.box("Fist" + leg, (f0, 0, -4.0), (f1, 3.0, -0.6), DARK, name)
        k0, k1 = xs(2.6, 4.7)
        a.box("Knuckles" + leg, (k0, 0.3, -4.4), (k1, 2.2, -4.0), LIGHT, name)
        # boulder shoulder, stepped so it reads round: core, outer bulge, top cap
        s0, s1 = xs(1.9, 5.0)
        a.box("Shoulder" + leg, (s0, 7.0, -3.9), (s1, 9.6, -0.3), STONE, name)
        b0, b1 = xs(5.0, 5.5)
        a.box("Bulge" + leg, (b0, 7.5, -3.4), (b1, 9.1, -0.8), LIGHT, name)
        c0, c1 = xs(2.3, 4.7)
        a.box("ShoulderTop" + leg, (c0, 9.6, -3.5), (c1, 10.3, -0.7), LIGHT, name)
        m0, m1 = xs(2.5, 4.5)
        a.box("Moss" + leg, (m0, 10.3, -3.3), (m1, 10.5, -0.9), MOSS, name)
        l0, l1 = xs(3.0, 3.6)
        a.box("Leaf" + leg, (l0, 10.5, -2.5), (l1, 10.9, -1.9), LEAF, name)
        a.pivots[name] = (sx * 3.4, 8.4, -2.1)

    # short stumpy hind legs on wide feet
    for leg, sx in (("HL", -1), ("HR", 1)):
        name = "Leg" + leg
        x0, x1 = sorted((sx * 0.5, sx * 2.2))
        a.box(name, (x0, 1.0, 1.6), (x1, 4.0, 3.4), STONE, name)
        f0, f1 = sorted((sx * 0.3, sx * 2.4))
        a.box("Foot" + leg, (f0, 0, 1.2), (f1, 1.0, 3.6), DARK, name)
        a.pivots[name] = ((x0 + x1) / 2, 3.9, 1.65)

    # head: tiny, sunk low and forward between the shoulders under a heavy brow
    a.box("Head", (-1.3, 5.7, -4.7), (1.3, 7.8, -3.0), DARK, "neck")
    a.box("Brow", (-1.55, 7.3, -5.05), (1.55, 8.2, -3.0), LIGHT, "neck")
    a.box("Jaw", (-1.1, 5.3, -4.95), (1.1, 6.1, -3.2), STONE, "neck")
    for side, sx in (("L", -1), ("R", 1)):
        e0, e1 = sorted((sx * 0.3, sx * 1.0))
        a.box("GlowEye" + side, (e0, 6.5, -4.8), (e1, 7.25, -4.65), GLOW, "neck").neon = True
    a.pivots["neck"] = (0, 7.4, -3.0)

    a.meta = {"seat": (0, 8.6, 1.2), "neck_loop": {"center": (0, 6.8, -4.0), "radius": 1.6}}

    base = a.animations
    a.animations = lambda: {k: (L, {b: t for b, t in tr.items() if b in dict(a.bone_order)})
                            for k, (L, tr) in base().items()}
    return a


CAM = dict(eye=(-25, 16, -20), target=(0, 5.4, 0.2), W=640, H=640, fov=36)
BG = (238, 238, 232)


def main(out=os.path.join(A.ROOT, "designs", "woodland"), shots="/mnt/project-files/world2/woodland/renders"):
    os.makedirs(out, exist_ok=True)
    os.makedirs(shots, exist_ok=True)
    a = golem()
    m = A.build_animal(a, out)
    print(f"{a.name}: {len(a.parts)} parts")
    from PIL import Image
    im = render(pose(m, None, 0), transparent=True, **CAM)
    bg = Image.new("RGBA", im.size, BG + (255,))
    bg.alpha_composite(im)
    bg.convert("RGB").save(os.path.join(shots, "GiantGolem.png"))


if __name__ == "__main__":
    main(*sys.argv[1:])
