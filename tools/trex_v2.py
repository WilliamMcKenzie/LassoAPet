"""T-Rex (QM Oct 11): a blocky tyrannosaur in our animals' style, loosely after QM's
reference (orange with dark brown tiger stripes down the back, legs and tail, a cream
belly and lower jaw, a big boxy head with a grumpy brow and a yellow eye, lilac teeth
round the jaw, tiny arms with black claws, thick legs and a long tail). Static draft.

Run: python3 tools/trex_v2.py [out_dir]
writes TRex.bbmodel, TRex.png (three views) and TRex_vs_horse.png to out_dir.
`animate <src> <dst>` writes idle, walk and gallop into QM's file, with GIFs.

Bones: root, LegL/LegR, ArmL/ArmR, neck (head) > Jaw, Tail > Tail2.
"""

import json
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import animal_designs as A  # noqa: E402
import convert_designs as C  # noqa: E402
from convert_designs import Conv, SIDES, X  # noqa: E402
from horse_rig import pose  # noqa: E402
from partlib import render  # noqa: E402

ROOT = os.path.join(os.path.dirname(__file__), "..")
OUT = "/mnt/project-files/animals/trex/v2"

ORANGE = (240, 140, 52)
STRIPE = (168, 82, 32)
CREAM = (252, 218, 166)
TOOTH = (222, 212, 250)
CLAW = (40, 38, 46)
EYE = (255, 206, 40)
NOSTRIL = (90, 44, 20)
T = 0.18  # stripe thickness


def trex():
    a = Conv("TRex", "Legendary", 1.0)
    a.pivots["root"] = (0, 8.0, 0)

    def stripe(name, hw, ytop, depth, z0, z1, bone):
        """A dark stripe over the top and down both sides of a block hw wide."""
        a.b(name, (-hw - T, ytop, z0), (hw + T, ytop + T, z1), STRIPE, bone)
        for side, sx in SIDES:
            x0, x1 = X(sx, hw, hw + T)
            a.b(name + side, (x0, ytop - depth, z0), (x1, ytop + T, z1), STRIPE, bone)

    # ---- legs: thick striped thighs, shins leaning back, wide feet with three black-clawed toes
    for side, sx in SIDES:
        leg = a.bone("Leg" + side, "root", (sx * 1.9, 7.6, 1.2))
        x0, x1 = X(sx, 1.1, 2.9)
        a.b("Thigh" + side, (x0, 4.4, -0.8), (x1, 8.6, 3.2), ORANGE, leg)
        xs0, xs1 = X(sx, 2.9, 2.9 + T)
        for i, (y0, z0) in enumerate(((7.6, -0.6), (6.6, -0.4), (5.6, -0.2))):
            a.b(f"ThighStripe{side}{i}", (xs0, y0, z0), (xs1, y0 + 0.45, z0 + 2.4), STRIPE, leg)
        x0, x1 = X(sx, 1.3, 2.7)
        a.b("Shin" + side, (x0, 1.0, 0.4), (x1, 4.6, 2.2), ORANGE, leg)
        xs0, xs1 = X(sx, 2.7, 2.7 + T)
        a.b(f"ShinStripe{side}", (xs0, 2.6, 0.6), (xs1, 3.0, 2.0), STRIPE, leg)
        x0, x1 = X(sx, 1.1, 2.9)
        a.b("Foot" + side, (x0, 0.0, -1.2), (x1, 1.0, 2.2), ORANGE, leg)
        for i, dx in enumerate((-0.6, 0.0, 0.6)):
            xc = sx * 2.0 + dx
            a.b(f"Toe{side}{i}", (xc - 0.25, 0.0, -2.0 + 0.2 * (i != 1)), (xc + 0.25, 0.7, -1.2), ORANGE, leg)
            zt = -2.0 + 0.2 * (i != 1)
            a.pyr(f"Claw{side}{i}", (xc - 0.22, 0.05, zt), (xc + 0.22, 0.55, zt), "-z", 0.55, CLAW, leg)

    # ---- body: a big orange box held level, cream belly and chest, stripes down the back
    a.b("Body", (-2.4, 5.6, -3.6), (2.4, 10.2, 4.0), ORANGE, "root")
    a.b("Belly", (-2.0, 5.2, -3.2), (2.0, 5.6, 3.4), CREAM, "root")
    a.b("Chest", (-1.9, 5.6, -3.9), (1.9, 8.8, -3.6), CREAM, "root")
    for i, z in enumerate((-2.8, -1.2, 0.4, 2.0, 3.4)):
        stripe(f"BackStripe{i}", 2.4, 10.2, 2.2 - 0.3 * (i % 2), z, z + 0.6, "root")

    # ---- tiny arms: two blocks bent forward, two black claws
    for side, sx in SIDES:
        arm = a.bone("Arm" + side, "root", (sx * 2.0, 7.6, -3.0))
        x0, x1 = X(sx, 1.6, 2.5)
        a.b("UpperArm" + side, (x0, 6.2, -3.7), (x1, 7.8, -2.6), ORANGE, arm)
        a.b("Forearm" + side, (x0, 5.6, -4.8), (x1, 6.4, -3.5), ORANGE, arm)
        for i, dx in enumerate((-0.2, 0.2)):
            xc = sx * 2.05 + dx
            a.pyr(f"ArmClaw{side}{i}", (xc - 0.14, 5.65, -4.8), (xc + 0.14, 6.0, -4.8), "-z", 0.4, CLAW, arm)

    # ---- tail: two segments tapering to a point, cream under, stripes over
    tail = a.bone("Tail", "root", (0, 8.4, 4.0))
    a.b("Tail1", (-2.0, 6.2, 4.0), (2.0, 9.8, 8.6), ORANGE, tail)
    a.b("TailBelly1", (-1.7, 5.9, 4.0), (1.7, 6.2, 8.4), CREAM, tail)
    for i, z in enumerate((5.0, 6.6, 8.0)):
        stripe(f"TailStripe1{i}", 2.0, 9.8, 1.8, z, z + 0.5, tail)
    tail2 = a.bone("Tail2", "Tail", (0, 8.0, 8.6))
    a.b("Tail2", (-1.4, 6.8, 8.6), (1.4, 9.0, 12.6), ORANGE, tail2)
    a.b("TailBelly2", (-1.1, 6.6, 8.6), (1.1, 6.8, 12.4), CREAM, tail2)
    a.b("TailTip", (-0.8, 7.2, 12.6), (0.8, 8.5, 15.2), ORANGE, tail2)
    for i, z in enumerate((9.6, 11.0)):
        stripe(f"TailStripe2{i}", 1.4, 9.0, 1.3, z, z + 0.45, tail2)
    stripe("TailStripe3", 0.8, 8.5, 0.8, 13.6, 14.0, tail2)

    # ---- neck and the big boxy head: grumpy brow, yellow eye, nostril, stripes on top
    head = a.bone("neck", "root", (0, 9.4, -3.6))
    a.b("Neck", (-1.8, 7.0, -6.0), (1.8, 10.6, -3.4), ORANGE, head)
    a.b("Throat", (-1.5, 6.7, -5.8), (1.5, 7.0, -3.6), CREAM, head)
    stripe("NeckStripe", 1.8, 10.6, 1.4, -5.2, -4.6, head)
    a.b("Head", (-2.0, 8.6, -11.8), (2.0, 11.8, -5.6), ORANGE, head)
    a.b("Snout", (-1.8, 11.8, -11.4), (1.8, 12.1, -8.8), ORANGE, head)
    for i, z in enumerate((-7.4, -6.4)):
        stripe(f"HeadStripe{i}", 2.0, 11.8, 1.2, z, z + 0.5, head)
    for side, sx in SIDES:
        a.side_eye(side, sx, 2.0, 10.0, 11.1, -8.8, -7.6, head, eye=EYE)
        x0, x1 = X(sx, 1.2, 2.2)
        a.b("Brow" + side, (x0, 11.1, -9.2), (x1, 11.6, -7.3), STRIPE, head)
        x0, x1 = X(sx, 1.2, 2.15)
        a.b("BrowLow" + side, (x0, 11.0, -9.3), (x1, 11.25, -8.7), STRIPE, head)
        x0, x1 = X(sx, 2.0, 2.06)
        a.b("Nostril" + side, (x0, 10.9, -11.3), (x1, 11.3, -11.0), NOSTRIL, head)
    # the lower jaw, cream, hinged under the eye; lilac teeth hang over its edge all round
    jaw = a.bone("Jaw", "neck", (0, 8.6, -6.0))
    a.b("Jaw", (-1.9, 7.3, -11.6), (1.9, 8.6, -6.0), CREAM, jaw)
    a.b("Chin", (-1.6, 7.0, -11.2), (1.6, 7.3, -7.0), CREAM, jaw)
    for side, sx in SIDES:
        for i, z in enumerate(np.arange(-11.2, -6.6, 0.75)):
            x0, x1 = X(sx, 1.72, 2.0)
            a.pyr(f"Tooth{side}{i}", (x0, 8.6, z - 0.28), (x1, 8.6, z + 0.28), "-y", 0.6, TOOTH, head)
    for i, x in enumerate(np.arange(-1.35, 1.4, 0.68)):
        a.pyr(f"ToothFront{i}", (x - 0.28, 8.6, -11.8), (x + 0.28, 8.6, -11.52), "-y", 0.6, TOOTH, head)
    a.meta = {"seat": (0, 10.38, 0.6), "neck_loop": {"center": (0, 8.8, -4.7), "radius": 2.2}}
    return a


def main(out=OUT):
    os.makedirs(out, exist_ok=True)
    a, model, parts = C.build(trex)
    model["meta"]["format_version"] = "5.0"
    path = os.path.join(out, "TRex.bbmodel")
    with open(path, "w") as f:
        json.dump(model, f, separators=(",", ":"))
    for p in parts:
        if p.name.startswith(("Eye", "Pupil", "Tooth", "Claw", "ArmClaw", "Nostril")):
            p.plain = True
    lo, hi = C.bounds(parts)
    c = (lo + hi) / 2
    r = np.linalg.norm(hi - lo) / 2
    W = 480
    sheet = Image.new("RGB", (W * 3, W))
    for i, v in enumerate(((-19, 8, -21), (-30, 4, 0), (19, 12, 21))):
        v = np.array(v, float)
        eye = c + v / np.linalg.norm(v) * r / np.tan(np.radians(17)) * 1.05
        sheet.paste(render(parts, eye=eye, target=c, W=W, H=W, fov=34), (i * W, 0))
    A.label(sheet, ["T-Rex", "side", "back"], 22).save(os.path.join(out, "TRex.png"))
    horse = json.load(open(os.path.join(ROOT, "designs", "animals", "Horse.bbmodel")))
    cam = dict(eye=(-36, 14, -36), target=(0, 6, 1), W=W, H=W, fov=36)
    pair = Image.new("RGB", (W * 2, W))
    pair.paste(render(pose(horse, None, 0), **cam), (0, 0))
    pair.paste(render(parts, **cam), (W, 0))
    A.label(pair, ["Horse", "T-Rex"], 22).save(os.path.join(out, "TRex_vs_horse.png"))
    print("wrote", path, len(parts), "parts")


def animations(m):
    """QM's file holds the jaw wide open at rest (a roar), so the jaw keys close it from there
    (+X shuts it). +X on root leans the body nose-down."""
    import math
    from snake_rig import track
    from snow_rig import bump, grounded
    s, TAU = math.sin, 2 * math.pi
    feet = {e["name"] for e in m["elements"] if e["name"].startswith(("Foot", "Toe", "Claw"))}

    def jaws(L, f, n):
        return {j: [track(L, lambda u: (f(u), 0, 0), n)] for j in ("Jaw", "Jaw2")}

    def run(L, stride, lean, roll, sway, bob, hop, shut, n=16):
        # a heavy stomp: legs swing in turn, the body rolls over the planted leg, the tail
        # swings the other way, the head bobs twice a stride and the jaw chomps
        tr = {"root": [track(L, lambda u: (lean, 0, roll * s(TAU * u)), n)]}
        for side, ph in (("L", 0.0), ("R", 0.5)):
            tr["Leg" + side] = [track(L, lambda u, ph=ph: (-lean + stride * s(TAU * (u + ph)), 0, 0), n)]
            tr["Arm" + side] = [track(L, lambda u, ph=ph: (12 * s(TAU * (u + ph + 0.25)), 0, 0), n)]
        tr["neck"] = [track(L, lambda u: (-lean * 0.7 + bob * s(2 * TAU * u), -sway * 0.4 * s(TAU * u), 0), n)]
        tr["Tail"] = [track(L, lambda u: (-lean * 0.5 + 3 * s(2 * TAU * u), sway * s(TAU * u), 0), n)]
        tr["Tail2"] = [track(L, lambda u: (2 * s(2 * TAU * u - 1), sway * 1.2 * s(TAU * u - 0.9), 0), n)]
        tr.update(jaws(L, lambda u: shut * (0.5 + 0.5 * s(2 * TAU * u)), n))
        tr["root"] = grounded(m, L, tr, feet, n, extra=lambda u: hop * abs(s(TAU * u)))
        return L, tr

    out = {}
    # idle: breathes, looks about, shuts its jaw, then throws its head up into a roar
    L = 4.0
    out["idle"] = (L, {
        "root": [track(L, lambda u: (1.5 * s(TAU * u), 0, 0), 32)],
        "neck": [track(L, lambda u: (-14 * bump(u, 0.72, 0.07) + 2 * s(TAU * u), 22 * s(TAU * u) * (1 - bump(u, 0.72, 0.12)), 0), 64)],
        "Tail": [track(L, lambda u: (0, 10 * s(TAU * u + 1), 0), 32)],
        "Tail2": [track(L, lambda u: (0, 12 * s(TAU * u + 0.2), 0), 32)],
        "ArmL": [track(L, lambda u: (-18 * bump(u, 0.72, 0.07), 0, 0), 48)],
        "ArmR": [track(L, lambda u: (-18 * bump(u, 0.72, 0.07), 0, 0), 48)],
        **jaws(L, lambda u: 30 * (1 - bump(u, 0.72, 0.1)) * (0.6 + 0.4 * bump(u, 0.35, 0.15)), 64),
    })
    out["walk"] = run(1.0, stride=24, lean=3, roll=4, sway=10, bob=4, hop=0, shut=24)
    out["gallop"] = run(0.5, stride=42, lean=12, roll=3, sway=6, bob=6, hop=10, shut=12)
    return out


def animate(src, dst, out=OUT):
    """Write idle, walk and gallop into QM's file (src) as dst, with preview GIFs.
    QM's right arm bone ArmL2 is renamed ArmR."""
    import horse_rig
    horse_rig.EULER = "ZYX"  # QM's hand-made file
    from horse_rig import write_animations
    from snow_rig import group_ids, posed
    m = json.load(open(src))
    for g in m["groups"]:
        if g["name"] == "ArmL2":
            g["name"] = "ArmR"
    m["animations"] = []
    write_animations(m, group_ids(m), animations(m))
    with open(dst, "w") as f:
        json.dump(m, f, separators=(",", ":"))
    W = 420
    cams = [dict(eye=(-30, 13, -32), target=(0, 6, 0), W=W, H=W, fov=40), dict(eye=(-44, 7, 0), target=(0, 6, 1), W=W, H=W, fov=38)]

    def frame(name, t):
        anim = next(x for x in m["animations"] if x["name"] == name)
        ps = posed(m, anim, t)
        for p in ps:
            if p.name.startswith(("Eye", "Pupil", "Tooth", "Claw", "ArmClaw", "Nostril")):
                p.plain = True
        im = Image.new("RGB", (W * 2, W))
        for i, c in enumerate(cams):
            im.paste(render(ps, **c), (i * W, 0))
        return A.label(im, [name, ""], 22)

    for name, n in (("idle", 32), ("walk", 16), ("gallop", 12)):
        L = next(x for x in m["animations"] if x["name"] == name)["length"]
        A.gif(os.path.join(out, f"TRex_{name}.gif"), [frame(name, L * i / n) for i in range(n)], fps=n / L)
    print("wrote", dst)


if __name__ == "__main__":
    if sys.argv[1:2] == ["animate"]:
        animate(*sys.argv[2:])
    else:
        main(*sys.argv[1:])
