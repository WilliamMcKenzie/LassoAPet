"""Ladybug: World 3 Garden Uncommon (draft, Oct 14). A chunky ladybird you ride on its shell:
a domed red shell in two halves (the elytra) with raised black spots and a black seam, a black
head with white cheek patches, big googly eyes, curly antennae with ball tips, six black legs.
When it runs flat out (gallop) the shell halves lift and clear amber wings buzz underneath.

Run: python3 tools/garden_ladybug.py [--gif]
Bones (all rest 0): root -> neck (head), ShellL/ShellR, WingL/WingR, Leg{L,R}{1,2,3}.
"""

import sys

import numpy as np

import garden_lib as G
from garden_lib import Garden, Rm, track, sin, TAU

C = {"red": (214, 26, 38), "reddark": (150, 14, 28), "black": (30, 26, 32), "white": (250, 246, 236),
     "wing": (255, 196, 92), "wingvein": (176, 98, 30)}


def spot(c, r, d, size, n=16):
    """A round black spot curving with the shell (ellipsoid c, r) round direction d: a thin lens of
    shell-surface points just outside it, so it hugs the dome instead of standing off it flat."""
    d = np.array(d, float) / np.linalg.norm(d)
    e1 = np.cross(d, (0, 1, 0) if abs(d[1]) < 0.9 else (1, 0, 0))
    e1 /= np.linalg.norm(e1)
    e2 = np.cross(d, e1)
    pts = []
    for k in range(n + 1):
        a = TAU * k / n
        q = d * 3.6 + (e1 * np.cos(a) + e2 * np.sin(a)) * size * (k < n)  # (the last: the centre)
        q /= np.linalg.norm(q)
        p = q / np.linalg.norm(q / r)  # the shell's surface that way
        pts += [c + p + q * 0.06, c + p - q * 0.25]
    return pts


def build():
    g = Garden("Ladybug", C)
    y0 = 2.0
    root = g.group("root", (0, y0, 0))
    # underbody
    g.box(root, "Belly", (0, y0 - 0.2, 0.6), (4.4, 1.6, 6.0), "black")  # (inside the shell's round edge)
    # shell halves: each one faceted half-dome mesh (QM Oct 14: meshes where blocks faked a curve),
    # with three flat black spots lying in its facets (one more mesh)
    for side, s in (("L", -1), ("R", 1)):
        sh = g.group("Shell" + side, (s * 0.15, y0 + 1.0, -2.8), root)
        shell_c, shell_r = np.array([0, y0 + 0.3, 0.6]), np.array([3.45, 3.75, 4.2])
        half = G.ellipsoid(shell_c, shell_r, seg=16, rings=8, twist=0)
        half[:, 0] = s * np.maximum(s * half[:, 0], -0.12)  # (the inner face flat, at the seam)
        half[:, 1] = np.maximum(half[:, 1], y0 + 0.3)
        g.hull(sh, "SmoothShell" + side, half, "red")  # (smooth, no studs: coordinator Oct 14)
        for d, r in (((s * 0.5, 1, -0.3), 0.75), ((s * 0.4, 0.8, 0.8), 0.6), ((s * 1, 0.45, 0.1), 0.85)):
            g.hull(sh, "SmoothSpot" + side, spot(shell_c, shell_r, d, r), "black")
        # wings folded under the shell (they spread in the gallop)
        wg = g.group("Wing" + side, (s * 0.6, y0 + 1.3, -1.0), root)
        M = Rm(("y", -s * 12))
        g.box(wg, "Wing" + side, np.array([s * 1.3, y0 + 1.25, 1.4]), (1.8, 0.2, 4.4), "wing", M)
        g.box(wg, "WingVein" + side, np.array([s * 1.4, y0 + 1.3, 1.4]), (0.3, 0.3, 4.0), "wingvein", M)

    # head: black, white cheek patches, big googly eyes on the front, curly antennae
    neck = g.group("neck", (0, y0 + 0.8, -3.6), root)
    hz = -4.6
    g.box(neck, "Head", (0, y0 + 1.0, hz), (4.4, 2.8, 2.2), "black")
    g.box(neck, "Snout", (0, y0 + 0.2, hz - 1.3), (2.6, 1.2, 0.6), "black")
    for side, s in (("L", -1), ("R", 1)):
        g.box(neck, "Cheek" + side, (s * 2.05, y0 + 1.1, hz + 0.1), (0.4, 1.4, 1.4), "white")
        g.eye(neck, side, (s * 1.05, y0 + 1.6, hz - 1.18), 1.5, look=(0, -0.1))
        base = np.array([s * 0.9, y0 + 2.35, hz - 0.2])
        d1 = np.array([s * 0.35, 1, -0.4])
        d1 /= np.linalg.norm(d1)
        g.box(neck, "Antenna" + side, base + d1 * 1.0, (0.35, 2.0, 0.35), "black", G.frame(d1))
        tip = base + d1 * 2.0
        d2 = np.array([s * 0.5, 0.3, -1])
        d2 /= np.linalg.norm(d2)
        g.box(neck, "Antenna" + side, tip + d2 * 0.5, (0.35, 1.0, 0.35), "black", G.frame(d2))
        g.box(neck, "AntennaBall" + side, tip + d2 * 1.15, (0.8, 0.8, 0.8), "black")
    g.box(neck, "Smile", (0, y0 + 0.15, hz - 1.62), (1.2, 0.25, 0.1), "white")

    # six legs: out and down, a knee and a foot
    for side, s in (("L", -1), ("R", 1)):
        for k, z in enumerate((-2.2, 0.4, 2.8)):
            b = f"Leg{side}{k + 1}"
            p = np.array([s * 2.6, y0 - 0.2, z])
            leg = g.group(b, p, root)
            up = np.array([s * 1.0, 0.25, 0])
            up /= np.linalg.norm(up)
            g.box(leg, b, p + up * 0.9, (0.6, 1.8, 0.6), "black", G.frame(up))
            knee = p + up * 1.8
            g.box(leg, b + "Shin", knee + np.array([s * 0.15, -(y0 - 0.2) / 2 - 0.2, 0]), (0.55, y0 + 0.1, 0.55), "black")
            g.box(leg, b + "Foot", knee + np.array([s * 0.35, -(y0 + 0.2), 0]), (0.9, 0.35, 0.8), "black")
    return g


def animations(m):
    feet = [(f"LegL1", 0), (f"LegR2", 0), (f"LegL3", 0), (f"LegR1", 0.5), (f"LegL2", 0.5), (f"LegR3", 0.5)]

    def scuttle(L, swing, lift, lean, n=16):
        tr = {}
        for b, ph in feet:
            tr[b] = [track(L, lambda u, ph=ph: (0, swing * sin(TAU * (u + ph)), 0), n)]
        tr["root"] = [track(L, lambda u: (lean, 0, 2 * sin(TAU * u)), n),
                      track(L, lambda u: (0, lift * abs(sin(TAU * u)), 0), n, "position")]
        tr["neck"] = [track(L, lambda u: (3 * sin(2 * TAU * u), 4 * sin(TAU * u), 0), n)]
        return tr

    L = 3.0
    idle = {"neck": [track(L, lambda u: (4 * sin(TAU * u), 8 * sin(TAU * u + 1), 0), 24)],
            "LegL1": [track(L, lambda u: (0, 6 * sin(TAU * 2 * u), 0), 24)],
            "LegR1": [track(L, lambda u: (0, -6 * sin(TAU * 2 * u), 0), 24)],
            "root": [track(L, lambda u: (0, 1.5 * sin(TAU * u), 0), 24, "position")]}
    walk = scuttle(0.6, 22, 2, 0)
    gallop = scuttle(0.36, 30, 4, -4)
    for side, s in (("L", -1), ("R", 1)):
        gallop["Shell" + side] = [track(0.36, lambda u, s=s: (-25, 0, s * 38), 4)]
        gallop["Wing" + side] = [track(0.36, lambda u, s=s: (0, s * (30 + 6 * sin(TAU * 4 * u)),
                                                             s * (45 + 22 * sin(TAU * 4 * u))), 32)]
    return {"idle": (L, idle), "walk": (0.6, walk), "gallop": (0.36, gallop)}


if __name__ == "__main__":
    m = build().finish(animations)
    if "--gif" in sys.argv:
        G.gif(m, G.OUT + "/Ladybug_anims.gif")
