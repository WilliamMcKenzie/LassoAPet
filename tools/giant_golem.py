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
from snow_designs import pyramid  # noqa: E402

STONE = (150, 142, 132)
DARK = (104, 97, 90)
LIGHT = (184, 177, 166)
MOSS = (110, 186, 68)
LEAF = (242, 109, 57)  # the Woodland walls' autumn orange #F26D39
LEAF2 = (255, 170, 40)
BARK = (121, 72, 46)  # the Woodland floor brown #79482E
GLOW = (255, 156, 20)


def golem():
    a = A.Animal("GiantGolem", "Legendary")
    a.bone_order = [("root", None), ("neck", "root")] + [("Leg" + leg, "root") for leg in A.LEGS]

    def glow(name, lo, hi, bone):
        # Glow prefix: Neon in game (bbmodel_to_luau NEON)
        a.box("Glow" + name, lo, hi, GLOW, bone).neon = True

    # ---- torso: deep chest up front, broad back behind it where the rider sits
    a.body(2.4, 3.8, 8.4, -0.6, 3.6, STONE)
    a.box("Chest", (-2.8, 3.6, -3.4), (2.8, 9.2, -0.6), DARK, "root")
    for side, sx in (("L", -1), ("R", 1)):
        x0, x1 = sorted((sx * 0.3, sx * 2.6))
        a.box("Pec" + side, (x0, 6.4, -3.8), (x1, 8.8, -3.4), LIGHT, "root")
        g0, g1 = sorted((sx * 1.0, sx * 2.2))
        glow("PecVein" + side, (g0, 6.25, -3.55), (g1, 6.45, -3.45), "root")
        v0, v1 = sorted((sx * 2.0, sx * 2.2))
        glow("SideVein" + side, (v0, 4.2, -3.45), (v1, 6.3, -3.35), "root")
        b0, b1 = sorted((sx * 2.4, sx * 2.45))
        glow("BackVein" + side, (b0, 5.0, 0.4), (b1, 5.2, 2.6), "root")
        glow("BackVeinUp" + side, (b0, 5.2, 2.4), (b1, 7.0, 2.6), "root")
    # glowing core in a stone frame, with a gem pushing out of it
    a.box("CoreFrameTop", (-1.1, 5.9, -3.7), (1.1, 6.3, -3.4), STONE, "root")
    a.box("CoreFrameBot", (-1.1, 3.9, -3.7), (1.1, 4.3, -3.4), STONE, "root")
    a.box("CoreFrameL", (-1.1, 4.3, -3.7), (-0.75, 5.9, -3.4), STONE, "root")
    a.box("CoreFrameR", (0.75, 4.3, -3.7), (1.1, 5.9, -3.4), STONE, "root")
    glow("Core", (-0.75, 4.3, -3.55), (0.75, 5.9, -3.45), "root")
    pyramid(a, "GlowGem", (-0.5, 4.6, -3.55), (0.5, 5.6, -3.55), "-z", 0.7, GLOW, "root").neon = True
    a.box("Belly", (-2.2, 3.2, -3.0), (2.2, 3.8, 3.0), DARK, "root")
    a.box("Hip", (-2.2, 4.0, 3.6), (2.2, 7.8, 4.1), DARK, "root")

    # ---- back: stone slabs either side of the seat (kept under it), mossy pad, spine of rock spikes
    for side, sx in (("L", -1), ("R", 1)):
        x0, x1 = sorted((sx * 1.5, sx * 2.6))
        a.box("BackSlab" + side, (x0, 7.9, -0.4), (x1, 8.5, 2.8), LIGHT, "root")
    a.box("MossBack", (-1.4, 8.4, -0.4), (1.4, 8.6, 2.8), MOSS, "root")
    a.box("Hump", (-1.4, 7.8, 2.8), (1.4, 9.4, 4.2), LIGHT, "root")
    a.box("HumpMoss", (-1.2, 9.4, 3.0), (1.2, 9.6, 4.0), MOSS, "root")
    for i, (z, h) in enumerate(((3.1, 1.2), (3.8, 1.7))):
        pyramid(a, f"Spine{i + 1}", (-0.45, 9.6, z - 0.4), (0.45, 9.6, z + 0.4), "+y", h, DARK, "root")
    pyramid(a, "Spine3", (-0.4, 6.5, 4.1), (0.4, 7.5, 4.1), "+z", 1.0, DARK, "root")
    a.box("Leaf1", (-1.3, 8.6, 2.0), (-0.8, 8.9, 2.5), LEAF, "root")
    a.box("Leaf2", (0.7, 9.6, 3.3), (1.1, 9.85, 3.7), LEAF2, "root")

    # ---- arms (front legs)
    for leg, sx in (("FL", -1), ("FR", 1)):
        name = "Leg" + leg

        def xs(a0, a1):
            return tuple(sorted((sx * a0, sx * a1)))

        # boulder shoulder, plated, stepped so it reads round
        a.box("Shoulder" + leg, xs(1.9, 5.0)[:1] + (7.0, -3.9), xs(1.9, 5.0)[1:] + (9.8, -0.3), STONE, name)
        a.box("ShoulderFront" + leg, xs(2.2, 4.8)[:1] + (7.4, -4.25), xs(2.2, 4.8)[1:] + (9.4, -3.9), LIGHT, name)
        a.box("ShoulderOut" + leg, xs(5.0, 5.5)[:1] + (7.4, -3.4), xs(5.0, 5.5)[1:] + (9.4, -0.8), LIGHT, name)
        a.box("ShoulderTop" + leg, xs(2.3, 4.7)[:1] + (9.8, -3.5), xs(2.3, 4.7)[1:] + (10.4, -0.7), LIGHT, name)
        glow("ShoulderVein" + leg, xs(3.3, 3.5)[:1] + (7.6, -4.35), xs(3.3, 3.5)[1:] + (9.0, -4.2), name)
        glow("ShoulderVein2" + leg, xs(3.5, 4.4)[:1] + (8.8, -4.35), xs(3.5, 4.4)[1:] + (9.0, -4.2), name)
        if sx > 0:
            # right shoulder: a crown of rock spikes
            for i, (cx, cz, h) in enumerate(((3.0, -2.6, 1.6), (4.1, -1.5, 2.4), (3.4, -1.2, 1.1))):
                b = xs(cx - 0.45, cx + 0.45)
                pyramid(a, f"SpikeFR{i + 1}", (b[0], 10.4, cz - 0.45), (b[1], 10.4, cz + 0.45), "+y", h, DARK, name)
            pyramid(a, "SpikeFR4", (5.5, 7.8, -2.6), (5.5, 9.0, -1.4), "+x", 1.3, DARK, name)
        else:
            # left shoulder: moss and a little autumn tree growing out of it
            a.box("MossFL", xs(2.5, 4.5)[:1] + (10.4, -3.3), xs(2.5, 4.5)[1:] + (10.6, -0.9), MOSS, name)
            a.box("TrunkFL", xs(3.3, 3.75)[:1] + (10.6, -2.3), xs(3.3, 3.75)[1:] + (12.2, -1.85), BARK, name)
            a.box("CanopyFL", xs(2.6, 4.45)[:1] + (11.8, -3.0), xs(2.6, 4.45)[1:] + (13.0, -1.15), LEAF, name)
            a.box("CanopyTopFL", xs(3.0, 4.05)[:1] + (13.0, -2.6), xs(3.0, 4.05)[1:] + (13.6, -1.55), LEAF2, name)
            a.box("LeafFL", xs(4.45, 4.75)[:1] + (12.0, -2.3), xs(4.45, 4.75)[1:] + (12.5, -1.8), LEAF2, name)
            pyramid(a, "SpikeFL4", (-5.5, 7.8, -2.6), (-5.5, 9.0, -1.4), "-x", 1.3, DARK, name)
        # upper arm, glowing elbow joint, wide plated forearm
        a.box("Arm" + leg, xs(2.6, 4.3)[:1] + (5.6, -2.9), xs(2.6, 4.3)[1:] + (7.0, -1.0), STONE, name)
        glow("Elbow" + leg, xs(2.65, 4.25)[:1] + (5.2, -2.85), xs(2.65, 4.25)[1:] + (5.6, -1.05), name)
        a.box("Forearm" + leg, xs(2.3, 4.7)[:1] + (2.6, -3.3), xs(2.3, 4.7)[1:] + (5.2, -0.6), DARK, name)
        a.box("Bracer" + leg, xs(4.7, 5.0)[:1] + (3.0, -2.9), xs(4.7, 5.0)[1:] + (4.8, -1.0), LIGHT, name)
        a.box("BracerFront" + leg, xs(2.6, 4.4)[:1] + (3.2, -3.6), xs(2.6, 4.4)[1:] + (4.8, -3.3), LIGHT, name)
        bx = sx * 5.0
        pyramid(a, "ArmSpike" + leg, (bx, 3.5, -2.4), (bx, 4.3, -1.6), "+x" if sx > 0 else "-x", 0.9, DARK, name)
        # fist: palm block, four knuckles, a thumb on the inside
        a.box("Fist" + leg, xs(2.3, 4.9)[:1] + (0, -3.6), xs(2.3, 4.9)[1:] + (2.6, -0.5), STONE, name)
        for i in range(4):
            k = xs(2.4 + 0.6 * i, 2.95 + 0.6 * i)
            top = 1.9 if i % 2 else 2.2
            a.box(f"Knuckle{leg}{i + 1}", (k[0], 0, -4.3), (k[1], top, -3.6), LIGHT if i % 2 else STONE, name)
        a.box("Thumb" + leg, xs(2.0, 2.3)[:1] + (0.5, -3.4), xs(2.0, 2.3)[1:] + (1.9, -2.3), LIGHT, name)
        a.pivots[name] = (sx * 3.4, 8.4, -2.1)

    # ---- hind legs: thigh, glowing knee, shin, big toed foot
    for leg, sx in (("HL", -1), ("HR", 1)):
        name = "Leg" + leg

        def xs(a0, a1):
            return tuple(sorted((sx * a0, sx * a1)))

        a.box(name, xs(0.4, 2.4)[:1] + (2.4, 1.4), xs(0.4, 2.4)[1:] + (4.2, 3.6), STONE, name)
        glow("Knee" + leg, xs(0.5, 2.3)[:1] + (2.1, 1.5), xs(0.5, 2.3)[1:] + (2.4, 3.5), name)
        a.box("Shin" + leg, xs(0.55, 2.25)[:1] + (0.9, 1.6), xs(0.55, 2.25)[1:] + (2.1, 3.4), DARK, name)
        a.box("Foot" + leg, xs(0.2, 2.6)[:1] + (0, 1.2), xs(0.2, 2.6)[1:] + (0.9, 3.8), STONE, name)
        for i in range(2):
            t = xs(0.35 + 1.15 * i, 1.3 + 1.15 * i)
            a.box(f"Toe{leg}{i + 1}", (t[0], 0, 0.75), (t[1], 0.7, 1.2), LIGHT, name)
        a.pivots[name] = (sx * 1.4, 3.9, 1.65)

    # ---- head: sunk low between the shoulders, heavy horned brow, glowing eyes and maw
    a.box("Head", (-1.3, 5.7, -4.7), (1.3, 7.8, -3.0), DARK, "neck")
    a.box("Brow", (-1.6, 7.3, -5.1), (1.6, 8.2, -3.0), LIGHT, "neck")
    a.box("BrowRidge", (-0.35, 7.3, -5.3), (0.35, 8.4, -4.9), LIGHT, "neck")
    a.box("Jaw", (-1.15, 5.1, -5.0), (1.15, 5.95, -3.2), STONE, "neck")
    glow("Maw", (-0.8, 5.95, -4.92), (0.8, 6.25, -4.72), "neck")
    for side, sx in (("L", -1), ("R", 1)):
        e0, e1 = sorted((sx * 0.3, sx * 1.05))
        glow("Eye" + side, (e0, 6.55, -4.85), (e1, 7.25, -4.7), "neck")
        c0, c1 = sorted((sx * 1.3, sx * 1.6))
        a.box("Cheek" + side, (c0, 5.6, -4.5), (c1, 7.3, -3.2), STONE, "neck")
        h0, h1 = sorted((sx * 0.8, sx * 1.5))
        pyramid(a, "Horn" + side, (h0, 8.2, -4.9), (h1, 8.2, -4.2), "+y", 1.1, DARK, "neck")
        f0, f1 = sorted((sx * 0.6, sx * 1.0))
        pyramid(a, "Fang" + side, (f0, 5.95, -5.0), (f1, 5.95, -4.6), "+y", 0.55, LIGHT, "neck")
    a.pivots["neck"] = (0, 7.4, -3.0)

    a.meta = {"seat": (0, 8.6, 1.2), "neck_loop": {"center": (0, 6.8, -4.0), "radius": 1.6}}

    a.animations = animations
    return a


def animations():
    """Heavy and slow, not the horse's leap: a breathing idle, a lumbering diagonal walk with
    a side-to-side sway, and a gorilla knuckle-run gallop (both fists reach and plant together,
    the hind legs push off between). Angles in degrees, heights in Blockbench units (10 = 1 stud).
    Front legs reach forward on +X, hind legs kick back on -X."""
    rx, rz, py, at = A.rot_x, A.rot_z, A.pos_y, A.at
    cr = "catmullrom"

    L = 2.4
    idle = (L, {
        "root": [py(at(L, [(0, 0), (0.5, -1.5), (1, 0)]))],
        "neck": [rx(at(L, [(0, 0), (0.5, 4), (1, 0)]), cr)],
        "LegFL": [rx(at(L, [(0, 0), (0.5, 2), (1, 0)]), cr)],
        "LegFR": [rx(at(L, [(0, 0), (0.5, 2), (1, 0)]), cr)],
    })

    L = 1.4
    walk = (L, {
        "root": [py(at(L, [(0, 0), (0.25, 4), (0.5, 0), (0.75, 4), (1, 0)])),
                 rz(at(L, [(0, 0), (0.25, 3), (0.5, 0), (0.75, -3), (1, 0)]), cr)],
        "neck": [rx(at(L, [(0, 0), (0.25, -3), (0.5, 0), (0.75, -3), (1, 0)]), cr)],
        "LegFL": [rx(at(L, [(0, 20), (0.5, -20), (1, 20)]), cr)],
        "LegFR": [rx(at(L, [(0, -20), (0.5, 20), (1, -20)]), cr)],
        "LegHL": [rx(at(L, [(0, -18), (0.5, 18), (1, -18)]), cr)],
        "LegHR": [rx(at(L, [(0, 18), (0.5, -18), (1, 18)]), cr)],
    })

    L = 0.9
    fists = [(0, -22), (0.2, -22), (0.55, 38), (0.8, 38), (1, -22)]
    gallop = (L, {
        "root": [py(at(L, [(0, 0), (0.25, 2), (0.6, 14), (0.85, 4), (1, 0)])),
                 rx(at(L, [(0, 5), (0.5, -4), (1, 5)]), cr)],
        "neck": [rx(at(L, [(0, -6), (0.5, 2), (1, -6)]), cr)],
        "LegFL": [rx(at(L, fists), cr)],
        "LegFR": [rx(at(L, [(min(1, u + 0.04) if 0 < u < 1 else u, v) for u, v in fists]), cr)],
        "LegHL": [rx(at(L, [(0, 26), (0.35, -30), (0.6, -30), (0.85, 26), (1, 26)]), cr)],
        "LegHR": [rx(at(L, [(0, 26), (0.38, -30), (0.63, -30), (0.88, 26), (1, 26)]), cr)],
    })
    return {"idle": idle, "walk": walk, "gallop": gallop}


CAM = dict(eye=(-15, 13, -27), target=(0, 6.0, 0.0), W=640, H=640, fov=36)
BG = (238, 238, 232)
SIDE = dict(eye=(-32, 9, -1), target=(0, 5.5, -0.5), W=360, H=360, fov=38)
ANIMS = "/mnt/project-files/world2/woodland/giant_golem"


def main(out=os.path.join(A.ROOT, "designs", "woodland"), shots="/mnt/project-files/world2/woodland/renders"):
    os.makedirs(out, exist_ok=True)
    os.makedirs(shots, exist_ok=True)
    os.makedirs(ANIMS, exist_ok=True)
    a = golem()
    m = A.build_animal(a, out)
    print(f"{a.name}: {len(a.parts)} parts")
    from PIL import Image
    im = render(pose(m, None, 0), transparent=True, **CAM)
    bg = Image.new("RGBA", im.size, BG + (255,))
    bg.alpha_composite(im)
    bg.convert("RGB").save(os.path.join(shots, "GiantGolem.png"))
    frames = []
    for name, n in (("idle", 24), ("walk", 28), ("gallop", 18)):
        anim = A.anim_named(m, name)
        for i in range(n):
            frames.append(A.label(render(pose(m, anim, i / n * anim["length"]), **SIDE), [name]))
    A.gif(os.path.join(ANIMS, "GiantGolem_anims.gif"), frames, fps=20)


if __name__ == "__main__":
    main(*sys.argv[1:])
