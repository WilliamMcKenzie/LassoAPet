"""Pterodactyl (QM Oct 11): a small flying dino, the T-Rex's blocky head and stripe style
(tools/trex_v2.py, raptor_design.py: one oversized block per stripe) on the Phoenix's flying
body (tools/phoenix_design.py): purple with dark purple stripes, a long gold beak, a swept
back red-orange crest, a yellow eye under a dark brow, big leathery orange wings on a purple
arm and long finger with three little claws at the wrist, legs tucked back, a stub tail.

Run: python3 tools/pterodactyl.py [out_dir]
writes Pterodactyl.bbmodel, Pterodactyl.png (three views) and Pterodactyl_vs_horse.png.
`animate` then writes Pterodactyl_anim.bbmodel (idle hover, walk glide, gallop fast flap)
and GIFs.

Bones: root, WingL/WingR, LegL/LegR, neck (head) > Jaw, Tail.
"""

import json
import math
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
from trex_v2 import CLAW, CREAM, EYE, NOSTRIL  # noqa: E402

ROOT = os.path.join(os.path.dirname(__file__), "..")
OUT = "/mnt/project-files/animals/pterodactyl"

PURPLE = (150, 98, 222)
STRIPE = (82, 50, 156)
BEAK = (255, 198, 52)
CREST = (255, 84, 52)
WEB = (255, 150, 72)  # wing membrane
WEB_EDGE = (240, 106, 54)  # its trailing edge
OVER = 0.025  # stripe blocks stand this far out of the body (QM's dino rule)
PLAIN = ("Eye", "Pupil", "Claw", "HandClaw", "Nostril", "FingerTip", "BeakTip", "JawTip", "CrestTip")


def wing_y(x):
    """Bottom of the wing's leading edge along x: rising a little toward the tip."""
    return 6.7 + 0.1 * (x - 1.2)


def web_back(x):
    """How far back the membrane reaches at x: from the body's back to nothing at the tip,
    bowed so the wing is broad near the body and pointed at the end."""
    t = min(1.0, (x - 1.2) / (16.4 - 1.2))
    return -0.6 + 3.8 * (1 - t ** 2.0)


def pterodactyl():
    a = Conv("Pterodactyl", "Rare", 1.0)
    a.pivots["root"] = (0, 6.0, 0)

    def stripe(name, hw, ytop, depth, z0, z1, bone):
        a.b(name, (-hw - OVER, ytop - depth, z0), (hw + OVER, ytop + OVER, z1), STRIPE, bone)

    # ---- body: small and light, cream belly, stripes down the back
    a.b("Body", (-1.2, 5.0, -2.0), (1.2, 7.2, 2.0), PURPLE, "root")
    a.b("Belly", (-1.0, 4.8, -1.8), (1.0, 5.0, 1.8), CREAM, "root")
    a.b("Chest", (-0.95, 5.0, -2.2), (0.95, 6.6, -2.0), CREAM, "root")
    for i, z in enumerate((-1.3, -0.1, 1.1)):
        stripe(f"BackStripe{i}", 1.2, 7.2, 1.1 - 0.2 * (i % 2), z, z + 0.4, "root")

    # ---- stub tail
    tail = a.bone("Tail", "root", (0, 6.4, 2.0))
    a.b("Tail", (-0.35, 6.0, 2.0), (0.35, 6.7, 3.6), PURPLE, tail)
    a.pyr("TailTip", (-0.3, 6.05, 3.6), (0.3, 6.65, 3.6), "+z", 0.6, PURPLE, tail)

    # ---- legs tucked back under it in flight (the Phoenix's), black claws
    for side, sx in SIDES:
        leg = a.bone("Leg" + side, "root", (sx * 0.75, 5.2, 1.0))
        x0, x1 = X(sx, 0.4, 1.1)
        a.b("Thigh" + side, (x0, 4.4, 0.4), (x1, 5.3, 1.6), PURPLE, leg)
        x0, x1 = X(sx, 0.55, 0.95)
        a.b("Shin" + side, (x0, 4.1, 1.4), (x1, 4.6, 3.0), PURPLE, leg)
        for i, dx in enumerate((-0.2, 0.0, 0.2)):
            xc = sx * 0.75 + dx
            a.b(f"Toe{side}{i}", (xc - 0.08, 3.95, 2.9), (xc + 0.08, 4.3, 3.5), PURPLE, leg)
            a.pyr(f"Claw{side}{i}", (xc - 0.07, 3.98, 3.5), (xc + 0.07, 4.27, 3.5), "+z", 0.3, CLAW, leg)

    # ---- wings: a purple arm and forearm out to the wrist (three little claws pointing
    # forward), then the long thin wing finger out to a point; the membrane hangs behind
    # it in stepped columns, broad by the body and pointed at the tip, its trailing edge darker
    for side, sx in SIDES:
        wing = a.bone("Wing" + side, "root", (sx * 1.2, 7.0, -1.0))
        for name, xa, xb, th, z0, z1 in (("Arm", 1.2, 5.6, 0.8, -1.5, -0.5), ("Forearm", 5.6, 9.6, 0.6, -1.4, -0.6),
                                         ("Finger", 9.6, 15.6, 0.4, -1.1, -0.7)):
            x0, x1 = X(sx, xa, xb)
            y = wing_y((xa + xb) / 2)
            a.b(f"Wing{name}{side}", (x0, y, z0), (x1, y + th, z1), PURPLE, wing)
        x0, x1 = X(sx, 3.0, 3.5)
        stripe_y = wing_y(3.25)
        a.b("ArmStripe" + side, (x0, stripe_y - OVER, -1.5 - OVER), (x1, stripe_y + 0.8 + OVER, -0.5 + OVER), STRIPE, wing)
        x0, x1 = X(sx, 15.6, 15.6)
        y = wing_y(15.6)
        a.pyr("FingerTip" + side, (x0, y, -1.1), (x1, y + 0.4, -0.7), "+x" if sx > 0 else "-x", 0.8, PURPLE, wing)
        # the wrist: a knob with three claws
        x0, x1 = X(sx, 9.2, 10.0)
        y = wing_y(9.6)
        a.b("Wrist" + side, (x0, y - 0.1, -1.6), (x1, y + 0.7, -0.5), PURPLE, wing)
        for i, dx in enumerate((-0.25, 0.0, 0.25)):
            xc = sx * (9.6 + dx)
            a.pyr(f"HandClaw{side}{i}", (xc - 0.08, y + 0.15, -1.6), (xc + 0.08, y + 0.45, -1.6), "-z", 0.45, CLAW, wing)
        # membrane columns, each a thin slab just under the leading edge
        cols = np.arange(1.2, 15.6, 1.2)
        for i, xa in enumerate(cols):
            xb = min(xa + 1.2, 15.6)
            back = web_back((xa + xb) / 2) + (0.25 if i % 2 else 0)  # a scalloped edge
            if back <= -0.4:
                continue
            y = wing_y((xa + xb) / 2) + 0.05
            x0, x1 = X(sx, xa, xb)
            edge = max(-0.6, back - 0.5)
            a.b(f"Web{side}{i}", (x0, y, -0.6), (x1, y + 0.3, edge), WEB, wing)
            a.b(f"WebEdge{side}{i}", (x0, y, edge), (x1, y + 0.3, back), WEB_EDGE, wing)

    # ---- neck up into a blocky T-Rex-style head with a long pointed beak and a swept crest
    head = a.bone("neck", "root", (0, 7.0, -2.0))
    a.b("Neck", (-0.65, 6.4, -3.3), (0.65, 8.6, -1.8), PURPLE, head)
    a.b("Throat", (-0.5, 6.25, -3.2), (0.5, 6.4, -2.0), CREAM, head)
    stripe("NeckStripe", 0.65, 8.6, 0.7, -2.7, -2.35, head)
    a.b("Head", (-0.95, 8.0, -5.0), (0.95, 9.6, -2.8), PURPLE, head)
    stripe("HeadStripe", 0.95, 9.6, 0.6, -3.6, -3.25, head)
    a.b("Beak", (-0.65, 8.55, -7.6), (0.65, 9.35, -5.0), BEAK, head)
    a.b("Beak2", (-0.45, 8.6, -8.8), (0.45, 9.2, -7.6), BEAK, head)
    a.pyr("BeakTip", (-0.4, 8.62, -8.8), (0.4, 9.18, -8.8), "-z", 0.9, BEAK, head)
    for side, sx in SIDES:
        a.side_eye(side, sx, 0.95, 8.6, 9.4, -4.5, -3.7, head, eye=EYE)
        x0, x1 = X(sx, 0.5, 1.0)
        a.b("Brow" + side, (x0, 9.3, -4.8), (x1, 9.65, -3.5), STRIPE, head)
        x0, x1 = X(sx, 0.65, 0.7)
        a.b("Nostril" + side, (x0, 9.0, -6.6), (x1, 9.2, -6.3), NOSTRIL, head)
    # the crest: red-orange steps sweeping up and back off the skull to a point
    for i, (z0, z1, y0, y1) in enumerate(((-4.4, -3.0, 9.6, 10.0), (-3.4, -2.0, 9.8, 10.4), (-2.4, -1.0, 10.1, 10.8))):
        a.b(f"Crest{i}", (-0.3, y0, z0), (0.3, y1, z1), CREST, head)
    a.pyr("CrestTip", (-0.28, 10.35, -1.0), (0.28, 10.8, -1.0), "+z", 1.6, CREST, head)
    jaw = a.bone("Jaw", "neck", (0, 8.5, -4.6))
    a.b("Jaw", (-0.55, 8.1, -7.4), (0.55, 8.55, -4.6), BEAK, jaw)
    a.b("Jaw2", (-0.38, 8.15, -8.5), (0.38, 8.55, -7.4), BEAK, jaw)
    a.pyr("JawTip", (-0.33, 8.18, -8.5), (0.33, 8.52, -8.5), "-z", 0.7, BEAK, jaw)
    a.meta = {"seat": (0, 7.6, 0.4), "neck_loop": {"center": (0, 8.8, -3.9), "radius": 1.3}}
    return a


def mark(parts):
    for p in parts:
        if p.name.startswith(PLAIN):
            p.plain = True


def main(out=OUT):
    os.makedirs(out, exist_ok=True)
    a, model, parts = C.build(pterodactyl)
    model["meta"]["format_version"] = "5.0"
    path = os.path.join(out, "Pterodactyl.bbmodel")
    with open(path, "w") as f:
        json.dump(model, f, separators=(",", ":"))
    mark(parts)
    lo, hi = C.bounds(parts)
    c = (lo + hi) / 2
    r = np.linalg.norm(hi - lo) / 2
    T = 480
    sheet = Image.new("RGB", (T * 3, T))
    for i, v in enumerate(((-19, 10, -21), (-30, 4, 0), (19, 16, 21))):
        v = np.array(v, float)
        eye = c + v / np.linalg.norm(v) * r / np.tan(np.radians(17)) * 1.05
        sheet.paste(render(parts, eye=eye, target=c, W=T, H=T, fov=34), (i * T, 0))
    A.label(sheet, ["Pterodactyl", "side", "back"], 22).save(os.path.join(out, "Pterodactyl.png"))
    horse = json.load(open(os.path.join(ROOT, "designs", "animals", "Horse.bbmodel")))
    cam = dict(eye=(-40, 16, -40), target=(0, 6, 0), W=T, H=T, fov=36)
    pair = Image.new("RGB", (T * 2, T))
    pair.paste(render(pose(horse, None, 0), **cam), (0, 0))
    pair.paste(render(parts, **cam), (T, 0))
    A.label(pair, ["Horse", "Pterodactyl"], 22).save(os.path.join(out, "Pterodactyl_vs_horse.png"))
    print("wrote", path, len(parts), "parts")


# ---------------------------------------------------------------- flying animations
# Like the Phoenix it never lands: idle a hover, walk a glide (wings held out, a beat every so
# often), gallop a fast flap nose-down. Built on phoenix_design.flight, minus its plumes, with
# the beak snapping open in a caw.
def animations():
    from phoenix_design import flap, flight
    from snake_rig import track
    from snow_rig import bump

    def ptero(L, beats, amp, raise_, bob, pitch, tail, caw):
        L, tr = flight(L, beats, amp, raise_, bob, pitch, tail)
        tr.pop("Plume")
        tr.pop("Plume2")
        tr["Jaw"] = [track(L, lambda u: (caw(u), 0, 0), 48)]
        return L, tr

    out = {
        "idle": ptero(2.4, 2, 30, 6, 8, 0, 8, lambda u: 32 * bump(u, 0.7, 0.05)),
        "gallop": ptero(0.9, 2, 46, 2, 12, 14, 12, lambda u: 10),
    }
    # walk: a glide, wings held up a little and rocking, one quick beat per loop
    L = 2.4

    def glide(u):
        return 0.25 * math.sin(2 * math.pi * u) + (flap((u - 0.5) / 0.35) if 0.5 <= u < 0.85 else 0) * 0.9

    out["walk"] = (L, {
        "WingL": [track(L, lambda u: (0, 0, -(8 + 30 * glide(u))), 64)],
        "WingR": [track(L, lambda u: (0, 0, 8 + 30 * glide(u)), 64)],
        "root": [track(L, lambda u: (4 + 2 * glide(u), 0, 5 * math.sin(2 * math.pi * u)), 64),
                 track(L, lambda u: (0, -6 * glide(u), 0), 64, "position")],
        "neck": [track(L, lambda u: (-3 - 2 * glide(u), 0, -3 * math.sin(2 * math.pi * u)), 64)],
        "Tail": [track(L, lambda u: (-6 * glide(u), 4 * math.sin(2 * math.pi * u), 0), 64)],
        "LegL": [track(L, lambda u: (12, 0, 0), 4)],
        "LegR": [track(L, lambda u: (12, 0, 0), 4)],
        "Jaw": [track(L, lambda u: (24 * bump(u, 0.2, 0.05), 0, 0), 48)],
    })
    return out


def animate(out=OUT):
    from horse_rig import write_animations
    from snow_rig import group_ids, posed
    m = json.load(open(os.path.join(out, "Pterodactyl.bbmodel")))
    m["animations"] = []
    write_animations(m, group_ids(m), animations())
    with open(os.path.join(out, "Pterodactyl_anim.bbmodel"), "w") as f:
        json.dump(m, f, separators=(",", ":"))
    T = 420
    cams = [dict(eye=(-26, 13, -28), target=(0, 6.5, 0), W=T, H=T, fov=40), dict(eye=(0, 8, -36), target=(0, 6.5, 0), W=T, H=T, fov=40)]
    for anim in m["animations"]:
        L, nf = anim["length"], 24
        frames = []
        for i in range(nf):
            ps = posed(m, anim, L * i / nf)
            mark(ps)
            im = Image.new("RGB", (T * 2, T))
            for c, cam in enumerate(cams):
                im.paste(render(ps, **cam), (c * T, 0))
            frames.append(A.label(im, [anim["name"], ""], 22))
        A.gif(os.path.join(out, f"Pterodactyl_{anim['name']}.gif"), frames, fps=nf / L)
    print("wrote Pterodactyl_anim.bbmodel")


if __name__ == "__main__":
    if sys.argv[1:2] == ["animate"]:
        animate(*sys.argv[2:])
    else:
        main(*sys.argv[1:])
