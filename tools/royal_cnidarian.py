"""The Royal Cnidarian: World 3 Cnidaria (the reef)'s boss, also a Legendary pet (ref RotMG's
Cnidarian Reef boss: "electric jellyfish ensnare all trespassers"). A gigantic crowned
jellyfish: a tall domed bell of stacked royal violet / magenta tiers with dark stops between
them, a big gold crown with
glowing jewels on top (the rider sits inside the crown ring), an angry face on the front
(googly eyes, scowling brows, a jagged toothy mouth), a frilled skirt of eight rim panels,
a curtain of twelve long glowing trailing tentacles and four thick frilly oral arms, and
four little Gold Cnidarian minions orbiting it.

    python3 tools/royal_cnidarian.py [--gif]

writes designs/cnidaria/RoyalCnidarian.bbmodel and previews in
/mnt/project-files/world3/cnidaria/renders/. ZYX, every bone rests at 0. Faces -Z.
Bones: root (bell, face, crown; rider on top) -> Skirt1..8 (rim panels),
root -> Tent1..12 -> Tent1b -> Tent1c (trailing tentacles),
root -> Arm1..4 -> Arm1b -> Arm1c (oral arms),
root -> Orbit (spins about Y) -> Minion1..4 (gold jellies, bobbing).

  idle    slow regal bob, skirt pulsing, tentacles rippling, minions circling
  walk    quicker pulses, leaning in, minions faster
  gallop  big snappy pulses, nosed down, tentacles streaming back, minions whirling
"""

import math
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(__file__))
from cnidaria_kit import TAU, Build, finish, rot, track  # noqa: E402

NAME = "RoyalCnidarian"
COLORS = {
    "bell": (150, 40, 220), "bell2": (205, 45, 200), "bell3": (235, 120, 250), "stop": (70, 12, 110),
    "rim": (225, 50, 175), "frill": (255, 140, 225), "glowc": (60, 235, 255), "glowp": (255, 70, 205),
    "arm": (240, 90, 210), "arm2": (160, 40, 200),
    "gold": (255, 200, 40), "gold2": (215, 135, 20), "ruby": (255, 40, 100), "mouth": (40, 6, 50),
    "tooth": (255, 250, 235), "white": (255, 255, 255), "pupil": (20, 12, 30), "brow": (55, 8, 80),
    "mgold": (255, 215, 70), "mgold2": (235, 160, 30), "mglow": (255, 245, 150),
}
Y = 10.5  # the bell's rim height
TIERS = ((14.0, 1.4, "bell"), (13.4, 1.4, "bell2"), (12.2, 1.3, "bell"), (10.4, 1.2, "bell3"),
         (8.0, 1.0, "bell2"), (5.2, 0.8, "bell3"))
TOP = Y + sum(t[1] for t in TIERS)  # the seat (top of the bell, inside the crown)


def tier_y(k):
    return Y + sum(t[1] for t in TIERS[:k])


def radius_at(y):
    """Roughly the bell's outer radius at height y."""
    for k, (w, h, _) in enumerate(TIERS):
        if y <= tier_y(k) + h:
            return w * 0.5
    return 0.0


def outdir(a):
    return np.array([math.sin(a), 0.0, math.cos(a)])


def tdir(a):
    return np.array([math.cos(a), 0.0, -math.sin(a)])


def build():
    b = Build(NAME, COLORS)
    root = b.group("root", (0, Y + 3, 0))

    # ---- the bell: six octagonal tiers (two crossed slabs each), dark stops between
    for k, (w, h, c) in enumerate(TIERS):
        y = tier_y(k) + h / 2
        b.box(root, f"Bell{k + 1}a", (0, y, 0), (w, h, w * 0.62), c)
        b.box(root, f"Bell{k + 1}b", (0, y, 0), (w * 0.62, h, w), c)
        if k in (0, 2, 4):  # a dark stop band just under the next tier
            yy = tier_y(k) + h - 0.15
            b.box(root, f"Stop{k + 1}a", (0, yy, 0), (w + 0.12, 0.3, w * 0.62 + 0.12), "stop")
            b.box(root, f"Stop{k + 1}b", (0, yy, 0), (w * 0.62 + 0.12, 0.3, w + 0.12), "stop")
    # the underside, a little recessed
    b.box(root, "Subumbrella", (0, Y - 0.1, 0), (10.5, 0.3, 10.5), "stop")

    # ---- the face (front, -Z)
    zf = -6.75
    for s in (-1, 1):
        b.eye(root, "LR"[s > 0], (s * 2.4, Y + 2.7, zf), (0, 0, -1), (2.7, 3.0), look=(-s * 0.35, -0.2))
        # scowling brows: the inner ends low
        b.box(root, "Brow" + "LR"[s > 0], (s * 2.3, Y + 4.45, zf - 0.05), (3.2, 0.75, 0.6), "brow",
              rot(("z", s * 22)))
    b.box(root, "Mouth", (0, Y + 0.75, -7.02), (6.0, 1.15, 0.3), "mouth")
    b.box(root, "LipTop", (0, Y + 1.4, -7.05), (6.4, 0.3, 0.4), "stop")
    for j in range(5):
        x = -2.4 + 1.2 * j
        b.spike(root, f"ToothT{j + 1}", (x, Y + 1.32, -7.25), (x, Y + 0.45, -7.3), 0.75, "tooth", d=0.3)
    for j in range(4):
        x = -1.8 + 1.2 * j
        b.spike(root, f"ToothB{j + 1}", (x, Y + 0.18, -7.25), (x, Y + 0.85, -7.3), 0.6, "tooth", d=0.3)

    # ---- the crown: an octagonal gold band round the top tier, spikes and jewels
    rc, hb = 3.3, 1.9
    yb = tier_y(4) + 1.0  # sits on tier 5
    seg = 2 * rc * math.tan(math.radians(22.5)) + 0.25
    for k in range(8):
        a = math.radians(45 * k)
        d = outdir(a)
        M = rot(("y", math.degrees(a)))
        b.box(root, f"Crown{k + 1}", d * rc + np.array([0, yb + hb / 2, 0]), (seg, hb, 0.5), "gold", M)
        b.box(root, f"CrownBase{k + 1}", d * (rc + 0.1) + np.array([0, yb + 0.2, 0]), (seg + 0.1, 0.4, 0.7), "gold2", M)
        b.box(root, f"GlowGem{k + 1}", d * (rc + 0.35) + np.array([0, yb + hb / 2 - 0.05, 0]), (0.75, 0.75, 0.3),
              "ruby" if k % 2 else "glowc", M @ rot(("z", 45)))
        tall = k % 2 == 0
        h = 2.8 if tall else 1.6
        base = d * rc + np.array([0, yb + hb, 0])
        b.spike(root, f"CrownSpike{k + 1}", base, base + d * (0.5 if tall else 0.3) + np.array([0, h, 0]), 1.3 if tall else 1.0,
                "gold", d=0.5)
        if tall:
            b.box(root, f"GlowJewel{k + 1}", base + d * 0.5 + np.array([0, h - 0.1, 0]), (0.7, 0.7, 0.7),
                  "glowp" if k % 4 else "glowc", rot(("y", 45), ("x", 35)))

    # ---- the frilled skirt: eight rim panels, each its own bone
    for k in range(8):
        a = math.radians(22.5 + 45 * k)
        d, t = outdir(a), np.array([math.cos(a), 0, -math.sin(a)])
        pivot = d * 6.5 + np.array([0, Y + 0.3, 0])
        sk = b.group(f"Skirt{k + 1}", pivot, root)
        M = rot(("y", math.degrees(a)))
        b.box(sk, f"Skirt{k + 1}", pivot + d * 0.45 + np.array([0, -0.75, 0]), (5.6, 1.8, 0.6), "rim",
              M @ rot(("x", 22)))
        for j, s in enumerate((-1.4, 1.4)):
            c = pivot + d * 0.95 + t * s + np.array([0, -2.0, 0])
            b.box(sk, f"Frill{k + 1}{'ab'[j]}", c, (2.3, 1.1, 0.45), "frill", M @ rot(("x", 22), ("z", 10 * s)))

    # ---- twelve long glowing trailing tentacles, three bones each
    lens = (3.4, 3.2, 2.4)
    for k in range(12):
        a = math.radians(15 + 30 * k)
        d = outdir(a)
        r0 = 5.3 if k % 2 else 4.6
        p = d * r0 + np.array([0, Y - 0.1, 0])
        col = "glowc" if k % 2 == 0 else "glowp"
        parent = root
        for j, L in enumerate(lens):
            nm = f"Tent{k + 1}" + ("", "b", "c")[j]
            g = b.group(nm, p, parent)
            q = p + d * (0.45 - 0.2 * j) + np.array([0, -L, 0])
            b.bar(g, "Glow" + nm, p, q, 0.6 - 0.05 * j, col, over=0.1)
            if j == 2:  # a pointed tip
                b.spike(g, "Glow" + nm + "Tip", q, q + d * 0.1 + np.array([0, -1.3, 0]), 0.6, col)
            parent, p = g, q

    # ---- four thick frilly oral arms, three bones each
    for k in range(4):
        a = math.radians(45 + 90 * k)
        d = outdir(a)
        p = d * 1.4 + np.array([0, Y - 0.2, 0])
        parent = root
        for j, L in enumerate((3.2, 3.0, 2.6)):
            nm = f"Arm{k + 1}" + ("", "b", "c")[j]
            g = b.group(nm, p, parent)
            q = p + d * (0.6 + 0.2 * j) + np.array([0, -L, 0])
            b.bar(g, nm, p, q, 1.3 - 0.25 * j, "arm", d=0.9 - 0.15 * j, over=0.15)
            for f, sd in enumerate((-1, 1)):
                b.box(g, nm + "Frill" + "LR"[f], (p + q) / 2 + d * 0.15 + tdir(a) * sd * (0.75 - 0.1 * j),
                      (0.9 - 0.12 * j, L * 0.85, 0.45), "frill" if f else "arm2",
                      rot(("y", math.degrees(a)), ("z", sd * 12)))
            parent, p = g, q

    # ---- the Orbit: four Gold Cnidarians circling
    orbit = b.group("Orbit", (0, Y + 3, 0), root)
    for k in range(4):
        a = math.radians(45 + 90 * k)
        d = outdir(a)
        c = d * 12.0 + np.array([0, Y + 2.5 + (0.8 if k % 2 else -0.6), 0])
        mg = b.group(f"Minion{k + 1}", c, orbit)
        M = rot(("y", math.degrees(a)))
        b.box(mg, f"Minion{k + 1}Bell", c, (3.2, 1.3, 2.0), "mgold", M)
        b.box(mg, f"Minion{k + 1}Bellb", c, (2.0, 1.3, 3.2), "mgold", M)
        b.box(mg, f"Minion{k + 1}Top", c + np.array([0, 1.0, 0]), (2.0, 0.8, 1.3), "mgold", M)
        b.box(mg, f"Minion{k + 1}Topb", c + np.array([0, 1.0, 0]), (1.3, 0.8, 2.0), "mgold", M)
        b.box(mg, f"GlowMinion{k + 1}", c + np.array([0, 1.55, 0]), (0.6, 0.4, 0.6), "mglow", M @ rot(("y", 45)))
        b.box(mg, f"Minion{k + 1}Rim", c + np.array([0, -0.6, 0]), (2.9, 0.35, 2.9), "mgold2", M @ rot(("y", 45)))
        for s in (-1, 1):
            b.eye(mg, f"M{k + 1}" + "LR"[s > 0], c + d * 1.63 + M @ np.array([s * 0.5, 0.15, 0]), d, 0.75,
                  look=(-s * 0.3, 0))
        for j in range(4):
            q = math.radians(45 + 90 * j)
            top = c + np.array([0.7 * math.sin(q), -0.75, 0.7 * math.cos(q)])
            end = top + np.array([0.2 * math.sin(q), -2.2, 0.2 * math.cos(q)])
            b.bar(mg, f"Minion{k + 1}Tent{j + 1}", top, end, 0.35, "mgold2", over=0.1)
    return b.model()


def animations():
    def swim(L, pulse, bob, lean, wave, armamp, spin, trail=0.0):
        tr = {"root": [track(L, lambda u: (lean + 2.5 * math.sin(TAU * u), 0, 1.5 * math.sin(TAU * u + 0.7)), 16),
                       track(L, lambda u: (0, bob * math.sin(TAU * u - 1.0), 0), 16, "position")]}
        for k in range(8):
            a = math.radians(22.5 + 45 * k)
            tx, tz = math.cos(a), -math.sin(a)  # the panel's hinge (tangent) axis
            tr[f"Skirt{k + 1}"] = [track(L, lambda u, tx=tx, tz=tz: (
                -tx * pulse * (0.5 + math.sin(TAU * u)), 0, -tz * pulse * (0.5 + math.sin(TAU * u))), 16)]
        for k in range(12):
            a = math.radians(15 + 30 * k)
            tx, tz = math.cos(a), -math.sin(a)
            sx, sz = math.sin(a), math.cos(a)  # a sideways swing too, so the curtain ripples
            for j, sfx in enumerate(("", "b", "c")):
                amp = wave * (1 + 0.35 * j)
                ph = 0.55 * k + 1.1 * j

                def f(u, amp=amp, ph=ph, tx=tx, tz=tz, sx=sx, sz=sz, j=j):
                    w = amp * math.sin(TAU * u - ph)
                    s = 0.6 * amp * math.sin(TAU * u - ph - 1.3)
                    return (tx * w + sx * s + (trail if j == 0 else trail * 0.3), 0, tz * w + sz * s)
                tr[f"Tent{k + 1}{sfx}"] = [track(L, f, 16)]
        for k in range(4):
            a = math.radians(45 + 90 * k)
            tx, tz = math.cos(a), -math.sin(a)
            for j, sfx in enumerate(("", "b", "c")):
                amp = armamp * (1 + 0.3 * j)
                tr[f"Arm{k + 1}{sfx}"] = [track(L, lambda u, amp=amp, k=k, j=j, tx=tx, tz=tz: (
                    tx * amp * math.sin(TAU * u - k - 1.0 * j) + (trail * 0.8 if j == 0 else 0), 0,
                    tz * amp * math.sin(TAU * u - k - 1.0 * j)), 16)]
        tr["Orbit"] = [track(L, lambda u: (0, -spin * u, 0), 16, interp="linear")]
        for k in range(4):
            tr[f"Minion{k + 1}"] = [track(L, lambda u, k=k: (0, 0.6 * math.sin(TAU * 2 * u - k * 1.6), 0), 16, "position")]
        return tr
    return {"idle": (3.0, swim(3.0, 10, 0.9, 0, 7, 7, 90)),
            "walk": (1.2, swim(1.2, 14, 1.1, -8, 10, 10, 90, trail=8)),
            "gallop": (0.6, swim(0.6, 18, 1.4, -18, 9, 8, 90, trail=24))}


if __name__ == "__main__":
    finish(build(), animations(), dict(eye=(-14, 24, -54), target=(0, 9.5, 0), fov=34), sheet_target=(0, 9, 0))
