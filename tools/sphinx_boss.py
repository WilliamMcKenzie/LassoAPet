"""The Sphinx: World 2 Ancient Tomb's boss (QM, Oct 13: "a sphinx boss which chases you,
very detailed"). A huge sandstone lion with a pharaoh's head:
- a gold and lapis striped nemes headdress (cap, side flaps, lappets down the chest, a
  queue down the back of the neck) with a gold uraeus cobra rearing on the forehead
- a stern face: glowing turquoise eyes ringed in black kohl with flicks out the sides,
  angry brows, a straight nose, a thin mouth, a striped false beard
- a broad usekh collar on the chest in bands of turquoise, gold, lapis and carnelian with
  gold drops
- great falcon wings off its shoulders in gold, turquoise and lapis feathers with gold tips
- a striped cloth over its back, gold cartouche plaques with an ankh on each flank
- big lion paws with lapis and gold bracelets and gold claws, a lion tail with a dark tuft
Quadruped bones (root, neck, EarL, EarR, Tail, Leg*) with quad animations, plus WingL and
WingR flapping. Every bone rests at 0.

Run: python3 tools/sphinx_boss.py [out_dir] [--gif]
Writes designs/bosses/Sphinx.bbmodel and renders to /mnt/project-files/animals/bosses/.
"""

import math
import os
import shutil
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import animal_designs as A  # noqa: E402
from animal_designs import Animal, quad_animations, rot_z, at  # noqa: E402
from partlib import Part, T, render  # noqa: E402
from horse_rig import pose  # noqa: E402
from snow_designs import pyramid  # noqa: E402

NAME = "Sphinx"
SAND, SAND_DARK, SAND_LIGHT = (226, 186, 112), (188, 146, 76), (242, 210, 150)
GOLD, GOLD_DARK = (255, 200, 30), (204, 150, 14)
LAPIS, TURQ, CARNELIAN = (28, 62, 168), (36, 196, 196), (196, 52, 36)
KOHL, MOUTH, TUFT = (16, 16, 24), (110, 60, 40), (120, 76, 36)
GLOW_EYE, GLOW_RED = (80, 250, 255), (255, 50, 50)


def slab(a, name, center, u, v, size, color, bone):
    """A box centred on `center`: size[0] along u, size[1] along v, size[2] along u x v."""
    u = np.array(u, float)
    u /= np.linalg.norm(u)
    v = np.array(v, float)
    v = v - u * (v @ u)
    v /= np.linalg.norm(v)
    R = np.eye(4)
    R[:3, :3] = np.column_stack([u, v, np.cross(u, v)])
    p = Part(name, np.array(size, float), T(*center) @ R, color)
    p.bone = bone
    a.parts.append(p)
    return p


def stripes(a, name, lo, hi, axis, n, colors, bone):
    """A box cut into n flush bands along axis (0 x, 1 y, 2 z), cycling colours."""
    lo, hi = np.array(lo, float), np.array(hi, float)
    step = (hi[axis] - lo[axis]) / n
    for i in range(n):
        a0, a1 = lo.copy(), hi.copy()
        a0[axis] = lo[axis] + step * i
        a1[axis] = lo[axis] + step * (i + 1)
        a.box(f"{name}{i + 1}", a0, a1, colors[i % len(colors)], bone)


def sphinx():
    a = Animal(NAME, "Legendary")
    a.bone_order += [("WingL", "root"), ("WingR", "root")]

    # body
    x, y0, y1, z0, z1 = 2.1, 3.4, 7.0, -3.2, 4.2
    a.body(x, y0, y1, z0, z1, SAND)
    a.box("Belly", (-x + 0.3, y0 - 0.15, -2.0), (x - 0.3, y0, 3.0), SAND_DARK, "root")
    # striped cloth over the back, down to mid-flank, with a gold hem
    stripes(a, "Cloth", (-x - 0.06, 5.6, -0.4), (x + 0.06, y1 + 0.08, 3.0), 2, 6, [LAPIS, GOLD], "root")
    for side, sx in (("L", -1), ("R", 1)):
        ha, hb = sorted((sx * x, sx * (x + 0.1)))
        a.box("Hem" + side, (ha, 5.4, -0.45), (hb, 5.6, 3.05), GOLD_DARK, "root")
        # cartouche: a gold plaque with a lapis face and a gold ankh, on the haunch
        pa, pb = sorted((sx * x, sx * (x + 0.08)))
        qa, qb = sorted((sx * x, sx * (x + 0.12)))
        ra, rb = sorted((sx * x, sx * (x + 0.16)))
        a.box("Cartouche" + side, (pa, 3.7, 3.05), (pb, 5.3, 4.0), GOLD, "root")
        a.box("CartoucheFace" + side, (qa, 3.85, 3.15), (qb, 5.15, 3.9), LAPIS, "root")
        a.box("AnkhStem" + side, (ra, 3.95, 3.47), (rb, 4.6, 3.58), GOLD, "root")
        a.box("AnkhBar" + side, (ra, 4.55, 3.3), (rb, 4.65, 3.75), GOLD, "root")
        a.box("AnkhLoopT" + side, (ra, 4.95, 3.4), (rb, 5.05, 3.65), GOLD, "root")
        a.box("AnkhLoopL" + side, (ra, 4.65, 3.32), (rb, 5.0, 3.42), GOLD, "root")
        a.box("AnkhLoopR" + side, (ra, 4.65, 3.63), (rb, 5.0, 3.73), GOLD, "root")

    # legs: thick, big paws with bracelets and claws
    for leg in A.LEGS:
        sx = -1 if leg[1] == "L" else 1
        front = leg[0] == "F"
        xa, xb = sorted((sx * 0.6, sx * 2.05))
        za = z0 + 0.001 if front else z1 - 1.6
        zb = za + 1.6
        name = "Leg" + leg
        a.box(name, (xa, 1.0, za), (xb, y0, zb), SAND, name)
        a.box("BraceletL" + leg, (xa - 0.08, 1.5, za - 0.08), (xb + 0.08, 1.75, zb + 0.08), LAPIS, name)
        a.box("BraceletG" + leg, (xa - 0.08, 1.25, za - 0.08), (xb + 0.08, 1.5, zb + 0.08), GOLD, name)
        a.box("Paw" + leg, (xa - 0.05, 0, za - 0.7), (xb + 0.05, 1.0, zb), SAND_LIGHT, name)
        cw = (xb - xa) / 3
        for k in range(3):
            cx = xa + cw * (k + 0.5)
            pyramid(a, f"Claw{leg}{k + 1}", (cx - 0.17, 0.05, za - 0.7), (cx + 0.17, 0.4, za - 0.7), "-z", 0.45, GOLD, name)
        a.pivots[name] = ((xa + xb) / 2, y0 - 0.025, zb - 0.05 if front else za + 0.05)

    # neck and head
    N = "neck"
    a.box("Neck", (-1.35, 6.0, -4.3), (1.35, 8.6, -2.5), SAND, N)
    fz = -5.6  # the face's front
    a.box("Head", (-1.3, 8.3, fz), (1.3, 10.5, -3.3), SAND, N)
    a.box("Chin", (-0.8, 8.1, fz + 0.05), (0.8, 8.4, -4.2), SAND, N)
    # nemes: cap, headband, side flaps, lappets down the chest, queue behind
    a.box("NemesCap", (-1.6, 10.4, fz - 0.15), (1.6, 11.3, -2.6), GOLD, N)
    for i, cx in enumerate((-1.2, -0.4, 0.4, 1.2)):
        a.box(f"CapStripe{i + 1}", (cx - 0.15, 11.3, fz - 0.15), (cx + 0.15, 11.36, -2.6), LAPIS, N)
    a.box("Headband", (-1.62, 10.3, fz - 0.2), (1.62, 10.55, fz - 0.1), LAPIS, N)
    for side, sx in (("L", -1), ("R", 1)):
        fa, fb = sorted((sx * 1.3, sx * 2.25))
        stripes(a, "Flap" + side, (fa, 7.6, -5.2), (fb, 10.6, -2.9), 1, 8, [GOLD, LAPIS], N)
        la, lb = sorted((sx * 1.35, sx * 2.15))
        stripes(a, "Lappet" + side, (la, 5.4, -5.25), (lb, 7.6, -4.55), 1, 6, [LAPIS, GOLD], N)
        # kohl-ringed glowing eyes with flicks, under angry brows
        ka, kb = sorted((sx * 0.2, sx * 1.05))
        a.box("EyeLid" + side, (ka, 9.88, fz - 0.06), (kb, 10.02, fz), KOHL, N)
        a.box("EyeLine" + side, (ka + 0.05 * (sx > 0), 9.5, fz - 0.06), (kb - 0.05 * (sx < 0), 9.57, fz), KOHL, N)
        wa, wb = sorted((sx * 1.0, sx * 1.4))
        a.box("EyeFlick" + side, (wa, 9.55, fz - 0.06), (wb, 9.68, fz), KOHL, N)
        ea, eb = sorted((sx * 0.25, sx * 1.0))
        a.box("GlowEye" + side, (ea, 9.57, fz - 0.04), (eb, 9.88, fz), GLOW_EYE, N).neon = True
        pa, pb = sorted((sx * 0.56, sx * 0.68))
        a.box("PupilSlit" + side, (pa, 9.6, fz - 0.07), (pb, 9.86, fz - 0.04), KOHL, N)
        ia, ib = sx * 0.15, sx * 1.15
        a.tri("Brow" + side, [(ia, 10.05), (ib, 10.3), (ia, 10.3)], fz - 0.1, fz, KOHL, N)
        # ears just showing under the flaps
        ra, rb = sorted((sx * 1.3, sx * 1.45))
        a.box("Ear" + side, (ra, 9.0, -4.4), (rb, 9.8, -3.9), SAND_DARK, "Ear" + side)
        a.pivots["Ear" + side] = (sx * 1.35, 9.4, -4.15)
    a.box("Queue", (-0.6, 7.2, -2.7), (0.6, 10.5, -1.9), GOLD, N)
    stripes(a, "QueueBand", (-0.62, 7.2, -2.72), (0.62, 7.8, -1.88), 1, 2, [LAPIS, GOLD], N)
    a.box("Nose", (-0.22, 8.9, fz - 0.3), (0.22, 9.55, fz), SAND_DARK, N)
    a.box("Mouth", (-0.5, 8.6, fz - 0.03), (0.5, 8.72, fz), MOUTH, N)
    # false beard: striped, down from the chin, its tip curling forward
    stripes(a, "Beard", (-0.32, 6.9, -5.45), (0.32, 8.15, -4.85), 1, 5, [GOLD, LAPIS], N)
    a.box("BeardTip", (-0.32, 6.65, -5.75), (0.32, 6.95, -4.9), GOLD, N)
    # uraeus: a cobra rearing on the forehead, hood spread, glowing red eyes
    a.box("CobraBody", (-0.13, 10.55, fz - 0.32), (0.13, 11.4, fz - 0.15), GOLD, N)
    a.box("CobraHood", (-0.36, 11.0, fz - 0.36), (0.36, 11.75, fz - 0.24), GOLD, N)
    a.box("CobraBelly", (-0.14, 11.05, fz - 0.4), (0.14, 11.6, fz - 0.36), LAPIS, N)
    a.box("CobraHead", (-0.16, 11.75, fz - 0.5), (0.16, 11.95, fz - 0.15), GOLD_DARK, N)
    for side, sx in (("L", -1), ("R", 1)):
        ga, gb = sorted((sx * 0.06, sx * 0.14))
        a.box("GlowCobraEye" + side, (ga, 11.8, fz - 0.53), (gb, 11.88, fz - 0.49), GLOW_RED, N).neon = True
    a.pivots[N] = (0, 6.6, -3.2)

    # usekh collar: bands across the chest, narrowing downwards, gold drops at the bottom
    for i, (y, w, c) in enumerate(((6.25, 2.0, TURQ), (5.85, 1.85, GOLD), (5.45, 1.65, LAPIS),
                                   (5.05, 1.4, CARNELIAN), (4.7, 1.15, GOLD))):
        a.box(f"Collar{i + 1}", (-w, y - 0.4 if i < 4 else y - 0.35, z0 - 0.1 - 0.02 * i), (w, y, z0), c, "root")
    for i, cx in enumerate(np.linspace(-0.9, 0.9, 5)):
        a.box(f"CollarDrop{i + 1}", (cx - 0.11, 4.0, z0 - 0.14), (cx + 0.11, 4.35, z0 - 0.06), GOLD_DARK, "root")
    a.box("CollarNeck", (-1.45, 6.0, -4.4), (1.45, 6.4, -2.4), TURQ, N)
    a.box("CollarNeckGold", (-1.42, 6.4, -4.37), (1.42, 6.6, -2.43), GOLD, N)

    # tail: down off the rump, curving out, a dark tuft with a gold band
    pts = [(0, 6.4, z1), (0, 5.6, z1 + 0.6), (0, 4.6, z1 + 1.0), (0, 3.6, z1 + 1.1)]
    for i in range(3):
        p, q = np.array(pts[i]), np.array(pts[i + 1])
        slab(a, f"Tail{i + 1}", (p + q) / 2, (1, 0, 0), q - p, (0.36, np.linalg.norm(q - p) + 0.2, 0.36), SAND, "Tail")
    a.box("TailBand", (-0.24, 3.55, z1 + 0.92), (0.24, 3.75, z1 + 1.3), GOLD, "Tail")
    a.box("TailTuft", (-0.35, 2.7, z1 + 0.85), (0.35, 3.55, z1 + 1.4), TUFT, "Tail")
    a.pivots["Tail"] = (0, 6.4, z1)

    # wings: off the shoulders, sweeping up and back; three feather rows on each
    span, n = 6.5, 9
    for side, sx in (("L", -1), ("R", 1)):
        bone = "Wing" + side
        root = np.array([sx * 1.7, 7.0, -1.2])
        a.pivots[bone] = tuple(root)
        u = np.array([sx * math.cos(math.radians(38)), math.sin(math.radians(38)), 0.35])
        u /= np.linalg.norm(u)
        slab(a, "WingBone" + side, root + u * span / 2, u, (0, 0, 1), (span, 0.45, 0.4), GOLD, bone)
        for k in range(n):
            s = (k + 0.5) / n
            p = root + u * span * s
            # feathers trail back at the root and fan outward and down towards the tip
            back = np.array([sx * 0.9 * s, -0.25 - 0.4 * s, 1.0])
            back /= np.linalg.norm(back)
            normal_side = np.cross(u, back)
            for row, (L, c, off) in enumerate(((1.1, GOLD, 0.12), (2.0 + 0.8 * s, TURQ, 0.0), (3.0 + 1.6 * s, LAPIS, -0.12))):
                w = span / n * 1.15
                c0 = p + back * L / 2 + normal_side * off * sx
                slab(a, f"Feather{side}{row + 1}_{k + 1}", c0, u, back, (w, L, 0.16), c, bone)
                if row == 2:
                    slab(a, f"FeatherTip{side}{k + 1}", p + back * (L + 0.18) + normal_side * off * sx, u, back,
                         (w * 0.8, 0.36, 0.16), GOLD, bone)

    a.meta = {"seat": (0, 7.4, 0.8), "neck_loop": {"center": (0, 9.4, -4.4), "radius": 2.4}}
    a.animations = animations
    return a


def animations():
    out = quad_animations()

    def flap(L, amp, bias, beats=1):
        keys = [(L * i / 16, bias + amp * math.sin(2 * math.pi * beats * i / 16)) for i in range(17)]
        return {"WingL": [rot_z([(t, -v) for t, v in keys])], "WingR": [rot_z(keys)]}

    for name, (amp, bias) in (("idle", (6, 0)), ("walk", (14, 2)), ("gallop", (30, 5))):
        L, tracks = out[name]
        tracks.update(flap(L, amp, bias, 1 if name != "idle" else 1))
    return out


CAMS = [dict(eye=(-16, 12, -22), target=(0, 6.5, 0)), dict(eye=(0, 10.5, -16), target=(0, 8.5, -2)),
        dict(eye=(18, 12, 16), target=(0, 6.5, 0)), dict(eye=(-3, 10.5, -10), target=(0, 9.4, -4))]


def main(out="/mnt/project-files/animals/bosses"):
    os.makedirs(out, exist_ok=True)
    designs = os.path.join(A.ROOT, "designs", "bosses")
    a = sphinx()
    m = A.build_animal(a, designs)
    shutil.copy(os.path.join(designs, NAME + ".bbmodel"), out)
    print(f"{NAME}: {len(a.parts)} parts")
    W, H = 600, 600
    sheet = Image.new("RGB", (W * 2, H * 2))
    parts = pose(m, None, 0)
    for i, cam in enumerate(CAMS):
        sheet.paste(render(parts, W=W, H=H, fov=40, **cam), ((i % 2) * W, (i // 2) * H))
    sheet.save(os.path.join(out, NAME + ".png"))
    if "--gif" in sys.argv:
        frames = []
        for name, k, loops in (("idle", 24, 1), ("walk", 16, 2), ("gallop", 12, 3)):
            anim = next(x for x in m["animations"] if x["name"] == name)
            for _ in range(loops):
                for i in range(k):
                    ps = pose(m, anim, anim["length"] * i / k)
                    im = Image.new("RGB", (W * 2, H))
                    for c in (0, 2):
                        im.paste(render(ps, W=W, H=H, fov=40, **CAMS[c]), ((c // 2) * W, 0))
                    frames.append(A.label(im, [name] * 2))
        A.gif(os.path.join(out, NAME + "_anims.gif"), frames, fps=20)


if __name__ == "__main__":
    main(*[x for x in sys.argv[1:] if not x.startswith("--")])
