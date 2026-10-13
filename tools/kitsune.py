"""Kitsune (World 2, Temple, Legendary): a great white fox spirit. Nine huge tails fanned
up behind it like a halo, each ending in a blue spirit flame; a shrine rope (shimenawa)
with zigzag paper streamers and a gold bell round its neck; a glowing wish jewel between
its tall red-lined ears; amber slit eyes with red markings; a red and gold saddle cloth;
red socks and gold anklets; four blue fox-fire wisps floating at its sides.

    python3 tools/kitsune.py

writes designs/temple/Kitsune.bbmodel (convert without --zyx), the preview
/mnt/project-files/world2/temple/renders/Kitsune.png, a four-view sheet and an animation gif
(--still skips the gif). The tails and wisps are built already turned (rests baked into the
parts, every bone at 0); each tail is a chain of three bones that ripples like a flame.
"""

import json
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import animal_designs as A  # noqa: E402
from horse_rig import pose  # noqa: E402
from partlib import Part, T, Rx, Ry, Rz, render  # noqa: E402
from snow_designs import pyramid  # noqa: E402

NAME = "Kitsune"
WHITE = (250, 248, 244)
CREAM = (236, 228, 214)
RED = (222, 38, 52)
GOLD = (255, 196, 52)
STRAW = (232, 206, 140)
DARK = (38, 30, 44)
AMBER = (255, 176, 30)
SPIRIT = (80, 196, 255)
SPIRIT_CORE = (196, 240, 255)
JEWEL = (120, 230, 255)

TAILS = 9
TAIL_SEGS = [(1.7, 0.8), (2.3, 1.25), (2.0, 1.05)]  # (length, width) from the base out


def kitsune():
    a = A.Animal(NAME, "Legendary")
    a.bone_order = [("root", None), ("neck", "root"), ("EarL", "neck"), ("EarR", "neck"), ("Tail", "root")]
    a.bone_order += [("Leg" + leg, "root") for leg in A.LEGS]

    def rbox(name, size, M, color, bone):
        p = Part(name, size, M, color)
        p.bone = bone
        a.parts.append(p)
        return p

    def rpyr(name, M, w, d, h, color, bone):
        """Square pyramid, base w x d on local y = 0, tip at local (0, h, 0), placed by M."""
        base = [(-w / 2, 0, -d / 2), (w / 2, 0, -d / 2), (w / 2, 0, d / 2), (-w / 2, 0, d / 2)]
        pts = [(M @ np.array([*v, 1.0]))[:3] for v in base]
        tip = (M @ np.array([0, h, 0, 1.0]))[:3]
        p = Part(name, (1, 1, 1), np.eye(4), color, "Poly")
        p.polys = [np.array(pts)] + [np.array([pts[i], pts[(i + 1) % 4], tip]) for i in range(4)]
        p.bone = bone
        a.parts.append(p)
        return p

    # ---- body, chest ruff, legs
    a.body(1.5, 3.6, 6.4, -3.2, 3.2, WHITE)
    a.box("Belly", (-1.35, 3.45, -2.6), (1.35, 3.6, 2.6), CREAM, "root")
    a.box("Ruff", (-1.75, 4.0, -3.7), (1.75, 7.0, -1.6), WHITE, "root")
    a.wedge("RuffTuft", (-1.5, 3.4, -3.7), (1.5, 4.0, -2.6), CREAM, "root", "down_front")
    for side, sx in (("L", -1), ("R", 1)):
        for i, (y0, z0, ln) in enumerate(((4.4, -3.4, 0.8), (5.4, -3.2, 1.0), (6.3, -3.0, 0.7))):
            x = sx * 1.75
            pyramid(a, f"Ruff{side}{i + 1}", (x, y0, z0), (x, y0 + 0.8, z0 + 1.1), ("+x" if sx > 0 else "-x"), ln, WHITE, "root")

    for leg in A.LEGS:
        sx = -1 if leg[1] == "L" else 1
        front = leg[0] == "F"
        z0 = -2.9 if front else 1.8
        z1 = z0 + 1.1
        xa, xb = sorted((sx * 0.45, sx * 1.45))
        bone = "Leg" + leg
        a.box(bone, (xa, 1.5, z0), (xb, 3.6, z1), WHITE, bone)
        a.box("Anklet" + leg, (xa - 0.08, 1.3, z0 - 0.08), (xb + 0.08, 1.5, z1 + 0.08), GOLD, bone)
        a.box("Sock" + leg, (xa - 0.04, 0.6, z0 - 0.04), (xb + 0.04, 1.3, z1 + 0.04), RED, bone)
        a.box("Paw" + leg, (xa, 0, z0 - 0.35), (xb, 0.6, z1), WHITE, bone)
        a.pivots[bone] = ((xa + xb) / 2, 3.575, z1 - 0.05 if front else z0 + 0.05)
        # red flame marking sweeping up the outside of each thigh
        xo = sx * 1.5
        xs = sorted((xo, xo + sx * 0.1))
        a.box("Mark" + leg, (xs[0], 4.2, z0 + 0.2), (xs[1], 5.6, z0 + 0.6), RED, "root")
        a.box("Mark" + leg + "2", (xs[0], 5.2, z0 + 0.6), (xs[1], 5.9, z0 + 0.95), RED, "root")

    # ---- saddle cloth (the seat)
    a.box("Saddle", (-1.6, 6.4, -0.8), (1.6, 6.6, 2.2), RED, "root")
    a.box("SaddleTrimF", (-1.65, 6.35, -0.95), (1.65, 6.72, -0.75), GOLD, "root")
    a.box("SaddleTrimB", (-1.65, 6.35, 2.15), (1.65, 6.72, 2.35), GOLD, "root")
    for side, sx in (("L", -1), ("R", 1)):
        xs = sorted((sx * 1.5, sx * 1.65))
        a.box("Drape" + side, (xs[0], 5.0, -0.6), (xs[1], 6.4, 2.0), RED, "root")
        xh = sorted((sx * 1.5, sx * 1.7))
        a.box("Hem" + side, (xh[0], 4.8, -0.65), (xh[1], 5.05, 2.05), GOLD, "root")
        xm = sorted((sx * 1.65, sx * 1.78))
        a.box("Crest" + side, (xm[0], 5.45, 0.4), (xm[1], 6.05, 1.0), GOLD, "root")

    # ---- neck, shrine rope, paper streamers, bell
    a.box("Neck", (-0.95, 6.0, -3.5), (0.95, 8.4, -1.9), WHITE, "neck")
    a.box("Rope", (-1.08, 7.0, -3.62), (1.08, 7.45, -1.78), STRAW, "neck")
    for i, x in enumerate((-0.7, -0.15, 0.4)):
        a.box(f"RopeTwist{i + 1}", (x, 6.98, -3.66), (x + 0.3, 7.47, -3.6), GOLD, "neck")
    for side, x in (("L", -0.75), ("R", 0.75)):
        for k in range(3):
            dx = 0.12 if k % 2 else -0.12
            a.box(f"Shide{side}{k + 1}", (x + dx - 0.18, 6.55 - 0.45 * k, -3.85), (x + dx + 0.18, 7.0 - 0.45 * k, -3.7), WHITE, "neck")
    # red bow tied at the back of the rope, its two ribbons streaming down the neck
    a.box("Bow", (-0.55, 6.95, -1.8), (0.55, 7.5, -1.55), RED, "neck")
    a.box("BowKnot", (-0.2, 7.0, -1.6), (0.2, 7.45, -1.45), GOLD, "neck")
    for side, sx in (("L", -1), ("R", 1)):
        rbox("Ribbon" + side, (0.32, 1.6, 0.14), T(sx * 0.35, 6.3, -1.45) @ Rz(sx * 14) @ Rx(18), RED, "neck")
        rbox("RibbonEnd" + side, (0.36, 0.3, 0.16), T(sx * 0.55, 5.45, -1.15) @ Rz(sx * 14) @ Rx(18), GOLD, "neck")
    a.box("BellCord", (-0.07, 6.6, -3.82), (0.07, 7.0, -3.7), RED, "neck")
    a.box("Bell", (-0.42, 5.85, -4.2), (0.42, 6.6, -3.75), GOLD, "neck")
    a.box("BellKnob", (-0.15, 6.6, -4.05), (0.15, 6.75, -3.85), GOLD, "neck")
    a.box("PlainBellSlot", (-0.28, 6.0, -4.25), (0.28, 6.1, -4.2), DARK, "neck")

    # ---- head
    a.box("Head", (-1.2, 8.0, -4.8), (1.2, 10.2, -2.0), WHITE, "neck")
    a.box("Snout", (-0.7, 8.1, -6.6), (0.7, 9.1, -4.8), WHITE, "neck")
    a.wedge("Bridge", (-0.7, 9.1, -6.0), (0.7, 9.4, -4.8), WHITE, "neck")
    a.box("Jaw", (-0.62, 7.9, -6.4), (0.62, 8.1, -4.8), CREAM, "neck")
    a.box("Nose", (-0.3, 8.7, -6.75), (0.3, 9.15, -6.55), DARK, "neck")
    for side, sx in (("L", -1), ("R", 1)):
        x = sx * 1.2
        ax = "+x" if sx > 0 else "-x"
        if sx > 0:  # the left cheek wears the mask instead
            pyramid(a, f"Cheek{side}1", (x, 8.0, -3.9), (x, 9.0, -2.4), ax, 0.9, WHITE, "neck")
            pyramid(a, f"Cheek{side}2", (x, 8.7, -3.3), (x, 9.5, -2.3), ax, 0.6, WHITE, "neck")
        # amber slit eyes on the brow, red markings flaring up and out from them
        xa, xb = sorted((sx * 0.3, sx * 1.0))
        e = a.box("GlowEye" + side, (xa, 9.45, -4.85), (xb, 9.95, -4.8), AMBER, "neck")
        e.plain = True
        c = sx * 0.62
        p = a.box("Pupil" + side, (c - 0.07, 9.5, -4.88), (c + 0.07, 9.9, -4.85), DARK, "neck")
        p.plain = True
        ma, mb = sorted((sx * 1.0, sx * 1.2))
        a.box("Liner" + side, (ma, 9.75, -4.9), (mb, 10.2, -4.8), RED, "neck")
        la, lb = sorted((sx * 0.3, sx * 1.0))
        a.box("Lash" + side, (la, 9.95, -4.9), (lb, 10.05, -4.8), RED, "neck")
    # a little shrine fox mask (white, red markings) worn on the left side of the head
    a.box("Mask", (-1.42, 8.3, -3.1), (-1.2, 9.6, -2.0), WHITE, "neck")
    a.box("MaskSnout", (-1.72, 8.4, -2.8), (-1.42, 8.9, -2.3), WHITE, "neck")
    a.box("PlainMaskNose", (-1.78, 8.62, -2.65), (-1.72, 8.88, -2.45), DARK, "neck")
    for k, (z0, z1) in enumerate(((-3.0, -2.72), (-2.38, -2.1))):
        a.box(f"MaskEye{k + 1}", (-1.5, 9.0, z0), (-1.42, 9.2, z1), RED, "neck")
        pyramid(a, f"MaskEar{k + 1}", (-1.42, 9.6, z0 - 0.08), (-1.2, 9.6, z1 + 0.08), "+y", 0.5, RED, "neck")
    a.box("MaskMouth", (-1.5, 8.45, -2.95), (-1.42, 8.55, -2.15), RED, "neck")
    a.box("BrowFlame", (-0.14, 9.95, -4.9), (0.14, 10.2, -4.8), RED, "neck")
    a.upright_ears(0.72, 10.2, -3.4, -2.8, 0.58, 2.5, WHITE, inner=RED)
    for side, sx in (("L", -1), ("R", 1)):
        ra, rb = sorted((sx * 0.25, sx * 1.2))
        a.box("EarRing" + side, (ra, 10.2, -3.48), (rb, 10.4, -2.72), GOLD, "Ear" + side)

    # wish jewel (hoshi no tama) on a gold mount between the ears
    a.box("JewelMount", (-0.35, 10.2, -4.1), (0.35, 10.45, -3.4), GOLD, "neck")
    rbox("GlowJewel", (0.55, 0.55, 0.55), T(0, 10.78, -3.75) @ Rz(45), JEWEL, "neck")
    rpyr("GlowJewelFlame", T(0, 11.05, -3.75), 0.42, 0.42, 0.75, SPIRIT, "neck")

    # ---- nine tails fanned up behind like a halo, blue flame at every tip
    base = np.array([0, 5.7, 3.0])
    a.tail_axes = []
    a.pivots["Tail"] = tuple(base)
    for i in range(TAILS):
        f = i / (TAILS - 1) * 2 - 1  # -1 .. 1, left to right
        phi = 70 * f
        k = (1.1 - 0.2 * abs(f)) * (1 if i % 2 == 0 else 0.92)  # the middle tails longest, the back row shorter
        M = T(*(base + (0.35 * f, 0, 0))) @ Rz(-phi) @ Rx(16 if i % 2 == 0 else 44)
        a.tail_axes.append((M[:3, 0].copy(), M[:3, 2].copy()))  # its bend-back and fan-sideways axes
        parent = "Tail"
        for s, (ln, w) in enumerate(TAIL_SEGS):
            ln *= k
            bone = f"Tail{i + 1}{'abc'[s]}"
            a.bone_order.append((bone, parent))
            a.pivots[bone] = tuple(M[:3, 3])
            rbox(bone, (w, ln + 0.25, w), M @ T(0, ln / 2, 0), WHITE, bone)
            parent = bone
            M = M @ T(0, ln, 0) @ Rx(8) @ Rz(12 * f)
        rbox(f"GlowTail{i + 1}", (0.98, 0.5, 0.98), M @ T(0, 0.1, 0), SPIRIT_CORE, parent)
        rpyr(f"GlowFlame{i + 1}", M @ T(0, 0.35, 0), 0.98, 0.98, 1.5 * k, SPIRIT, parent)

    # ---- fox-fire wisps floating at its sides
    for j, (x, y, z) in enumerate(((-3.0, 7.2, -3.2), (3.0, 7.2, -3.2), (-3.1, 3.4, 0.8), (3.1, 3.4, 0.8))):
        bone = f"Wisp{j + 1}"
        a.bone_order.append((bone, "root"))
        a.pivots[bone] = (x, y, z)
        rbox(bone.replace("Wisp", "GlowWisp"), (0.7, 0.7, 0.7), T(x, y, z) @ Ry(45) @ Rx(35), SPIRIT_CORE, bone)
        rpyr(bone.replace("Wisp", "GlowWispFlame"), T(x, y + 0.3, z), 0.6, 0.6, 1.0, SPIRIT, bone)

    a.pivots["neck"] = (0, 6.4, -2.7)
    a.meta = {"seat": (0, 6.65, 0.7), "neck_loop": {"center": (0, 7.2, -2.7), "radius": 1.4}}
    for p in a.parts:
        p.neon = p.name.startswith("Glow")
    a.animations = lambda: animations(a)
    return a


def animations(a):
    """The Horse's idle, walk and leap gallop for the body, legs, neck and ears. On top:
    the tail fan bobs as one (Tail) and each tail ripples from its base out, bending back
    and swaying in the fan, a little delayed per segment and per tail, so the nine flow
    like flames; harder the faster it goes. The wisps bob and spin."""
    out = {}
    for name, (L, tracks) in A.quad_animations().items():
        tracks = dict(tracks)
        strong = {"idle": 0.0, "walk": 0.5, "gallop": 1.0}[name]
        cycles = max(1, round(L / 1.2)) if name == "idle" else 1
        n = 16
        wave = lambda k, ph: np.sin(2 * np.pi * (cycles * k / n - ph))
        # the whole fan: leans back a little at speed and bobs with the stride
        tracks["Tail"] = [{"channel": "rotation", "interp": "catmullrom", "keys": [
            (round(L * k / n, 4), (8 * strong + (2 + 3 * strong) * wave(k, 0), 0, 0)) for k in range(n + 1)]}]
        for i, (bend, fan) in enumerate(a.tail_axes):
            for s in range(3):
                ph = 0.08 * s + 0.11 * i
                back = (4 + 4 * strong) * (1 + 0.4 * s)
                sway = (3 + 3 * strong) * (1 + 0.5 * s)
                keys = []
                for k in range(n + 1):
                    v = bend * (back * wave(k, ph) + 4 * strong) + fan * sway * wave(k, ph + 0.25)
                    keys.append((round(L * k / n, 4), tuple(float(x) for x in v)))
                tracks[f"Tail{i + 1}{'abc'[s]}"] = [{"channel": "rotation", "interp": "catmullrom", "keys": keys}]
        for j in range(4):
            spin = [(round(L * k / 4, 4), (0, 90 * k * (1 if j % 2 else -1), 0)) for k in range(5)]
            bob = [(round(L * k / n, 4), (0, (2 + strong) * float(np.sin(2 * np.pi * (k / n + 0.25 * j))), 0)) for k in range(n + 1)]
            tracks[f"Wisp{j + 1}"] = [{"channel": "rotation", "interp": "linear", "keys": spin},
                                      {"channel": "position", "interp": "catmullrom", "keys": bob}]
        if name == "gallop":  # ears laid back a touch less than the Horse's
            tracks["EarL"] = tracks["EarR"] = [A.rot_x([(0, 20), (L, 20)])]
        out[name] = (L, tracks)
    return out


SHOT = "/mnt/project-files/world2/temple/renders"
BG = (240, 240, 236)


def shot(parts, **cam):
    im = render(parts, transparent=True, **cam)
    out = Image.new("RGB", im.size, BG)
    out.paste(im, (0, 0), im)
    return out


def main(out=os.path.join(A.ROOT, "designs", "temple")):
    os.makedirs(out, exist_ok=True)
    os.makedirs(SHOT, exist_ok=True)
    a = kitsune()
    model = A.build_animal(a, out)
    print(f"{NAME}: {len(a.parts)} parts")
    shot(a.parts, eye=(-19, 12, -17), target=(0, 6.8, 0.8), W=900, H=900, fov=42).save(os.path.join(SHOT, NAME + ".png"))
    views = [dict(eye=(-17, 12, -19), target=(0, 6.2, 0.5)), dict(eye=(-26, 7, 0), target=(0, 6.2, 0.5)),
             dict(eye=(15, 13, 19), target=(0, 6.2, 0.5)), dict(eye=(0, 8, -24), target=(0, 6.2, 0))]
    sheet = Image.new("RGB", (1000, 1000))
    for i, cam in enumerate(views):
        sheet.paste(shot(a.parts, W=500, H=500, fov=42, **cam), ((i % 2) * 500, (i // 2) * 500))
    sheet.save(os.path.join(os.path.dirname(SHOT), "Kitsune_views.png"))
    if "--still" in sys.argv:
        return
    frames = []
    cams = [dict(eye=(-26, 8, -2), target=(0, 6.2, 0.5)), dict(eye=(-19, 12, -17), target=(0, 6.8, 0.8))]
    for name, nf in (("idle", 24), ("walk", 20), ("gallop", 16)):
        anim = A.anim_named(model, name)
        for k in range(nf):
            ps = pose(model, anim, k / nf * anim["length"])
            for p in ps:
                p.neon = p.name.startswith("Glow")
            im = Image.new("RGB", (800, 400))
            for c, cam in enumerate(cams):
                im.paste(shot(ps, W=400, H=400, fov=44, **cam), (400 * c, 0))
            frames.append(A.label(im, ["run" if name == "gallop" else name] * 2))
    A.gif(os.path.join(os.path.dirname(SHOT), "Kitsune_anims.gif"), frames, fps=20)


if __name__ == "__main__":
    main(*[x for x in sys.argv[1:] if not x.startswith("--")])
