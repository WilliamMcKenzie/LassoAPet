"""The Seraph eggs (QM, Oct 13: "an EPIC seraph egg, recolor it for all the seraphs"), in
take C's style (tools/ocean_eggs.py): the octo shell gold below and feather-white above, with
the Seraph on it. One big glowing eye on the front with a glowing iris, a ring of gold round its
middle covered in little eyes, six small wings (three pairs: up, out and down) fanning out
of its sides, and a glowing halo floating over the top. Three colourings, the bosses' own
(tools/angel_boss.py): Seraph (gold and white), CrimsonSeraph, CrystalSeraph.

Run from the repo root: python3 tools/seraph_egg.py [Seraph CrimsonSeraph CrystalSeraph]
Writes designs/eggs/c_style/<Kind>Egg.bbmodel, src/shared/Eggs/<Kind>EggModel.luau,
assets/ui/<Kind>EggRender.png and previews in /mnt/project-files/animals/bosses/eggs/.
"""

import math
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(__file__))
import ocean_eggs as O  # noqa: E402
from horse_egg_takes import LH, N, WIDTHS, front_plate, shell  # noqa: E402

TAU = 2 * math.pi
# the bosses' palettes (tools/angel_boss.py COLORS / CRIMSON / CRYSTAL), copied so this
# doesn't pull in its command-line handling
PALETTES = {
    "Seraph": {"gold": (255, 194, 38), "deep": (222, 146, 24), "feather": (255, 255, 255), "cream": (255, 244, 214),
               "iris": (70, 178, 255), "glow": (255, 226, 90), "tip": (255, 214, 120)},
    "CrimsonSeraph": {"gold": (84, 22, 30), "deep": (56, 14, 20), "feather": (168, 30, 46), "cream": (136, 22, 38),
                      "iris": (255, 59, 92), "glow": (255, 59, 92), "tip": (255, 92, 116)},
    "CrystalSeraph": {"gold": (0, 190, 231), "deep": (0, 146, 186), "feather": (229, 131, 251), "cream": (242, 170, 253),
                      "iris": (229, 131, 251), "glow": (92, 225, 255), "tip": (92, 225, 255)},
}
WHITE, BLACK = (255, 255, 255), (20, 20, 26)


def slab(egg, name, center, a, b, size, color, bone=None):
    """A box centred on `center` with its length along unit a, width along unit b and
    thickness along a x b: size = (length, width, thickness)."""
    a = np.array(a, float) / np.linalg.norm(a)
    b = np.array(b, float) / np.linalg.norm(b)
    n = np.cross(a, b)
    c = np.array(center, float)
    L, W, T = (s / 2 for s in size)
    v = {(i, j, k): c + i * L * a + j * W * b + k * T * n for i in (-1, 1) for j in (-1, 1) for k in (-1, 1)}
    faces = [[v[(-1, -1, -1)], v[(-1, 1, -1)], v[(1, 1, -1)], v[(1, -1, -1)]],
             [v[(-1, -1, 1)], v[(1, -1, 1)], v[(1, 1, 1)], v[(-1, 1, 1)]],
             [v[(-1, -1, -1)], v[(1, -1, -1)], v[(1, -1, 1)], v[(-1, -1, 1)]],
             [v[(-1, 1, -1)], v[(-1, 1, 1)], v[(1, 1, 1)], v[(1, 1, -1)]],
             [v[(-1, -1, -1)], v[(-1, -1, 1)], v[(-1, 1, 1)], v[(-1, 1, -1)]],
             [v[(1, -1, -1)], v[(1, 1, -1)], v[(1, 1, 1)], v[(1, -1, 1)]]]
    return egg.poly(name, faces, color, bone=bone)


def seraph_egg(kind):
    P = PALETTES[kind]
    egg = shell([P["deep"], P["gold"], P["gold"], P["gold"], P["feather"], P["feather"], P["feather"]])
    top = N * LH

    # the big eye on the front, across the middle layers
    y0, y1 = 2.2 * LH, 4.1 * LH
    front_plate(egg, "GlowEye", -0.55, 0.55, y0, y1, WHITE, depth=0.06)
    ym = (y0 + y1) / 2
    front_plate(egg, "GlowIris", -0.3, 0.3, ym - 0.3, ym + 0.3, P["iris"], depth=0.1)
    front_plate(egg, "Pupil", -0.14, 0.14, ym - 0.14, ym + 0.14, BLACK, depth=0.14)

    # a gold ring round its middle, tilted (front down, under the eye), with eyes on it
    n = 14
    R = WIDTHS[2] / 2 + 0.3
    yc, tilt = 2.0 * LH, math.radians(16)
    for k in range(n):
        th = TAU * (k + 0.5) / n
        r = np.array([math.sin(th), 0, -math.cos(th)])  # k = 0 at the front
        t = np.array([math.cos(th), 0, math.sin(th)])
        # tilt about X: points at the front drop, at the back rise
        rot = lambda p: np.array([p[0], p[1] * math.cos(tilt) + p[2] * math.sin(tilt), -p[1] * math.sin(tilt) + p[2] * math.cos(tilt)])
        c = np.array([0, yc, 0]) + rot(R * r)
        up = rot(np.array([0, 1.0, 0]))
        slab(egg, f"Ring{k}", c, rot(t), up, (TAU * R / n * 1.12, 0.32, 0.14), P["gold"] if k % 2 else P["deep"], "bottom")
        if k % 2 == 0:
            out = rot(r)
            slab(egg, f"GlowRingEye{k}", c + out * 0.08, rot(t), up, (0.24, 0.24, 0.04), WHITE, "bottom").plain = True
            slab(egg, f"RingPupil{k}", c + out * 0.105, rot(t), up, (0.12, 0.12, 0.03), BLACK, "bottom").plain = True

    # six little wings fanning out of its sides, a little behind the middle
    for pair, (ang, y, lengths) in enumerate(((48, 5.4 * LH, (1.15, 1.0, 0.8)), (8, 4.4 * LH, (1.35, 1.2, 0.95)),
                                             (-34, 3.4 * LH, (1.0, 0.85, 0.7)))):
        layer = min(int(y / LH), N - 1)
        for s in (-1, 1):
            side = "LR"[s > 0]
            root = np.array([s * (WIDTHS[layer] / 2 - 0.1), y, 0.25])
            for k, L in enumerate(lengths):
                fa = math.radians(ang + 11 - 11 * k)
                d = np.array([s * math.cos(fa), math.sin(fa), 0])
                w = np.cross([0, 0, 1.0], d) * s
                col = P["feather"] if k % 2 == 0 else P["cream"]
                bone = "top" if y > 4 * LH else "bottom"
                slab(egg, f"Wing{side}{pair}F{k}", root + d * L / 2 + np.array([0, 0, 0.03 * k]), d, w,
                     (L, 0.36, 0.08), col, bone)
                slab(egg, f"Wing{side}{pair}T{k}", root + d * (L + 0.08) + np.array([0, 0, 0.03 * k]), d, w,
                     (0.16, 0.3, 0.08), P["tip"], bone)

    # the glowing halo over the top
    n = 10
    R = 0.42
    for k in range(n):
        th = TAU * (k + 0.5) / n
        r = np.array([math.sin(th), 0, -math.cos(th)])
        t = np.array([math.cos(th), 0, math.sin(th)])
        slab(egg, f"GlowHalo{k}", np.array([0, top + 0.35, 0]) + R * r, t, r, (TAU * R / n * 1.15, 0.1, 0.08),
             P["glow"], "top")
    return egg


if __name__ == "__main__":
    kinds = sys.argv[1:] or list(PALETTES)
    O.EGGS = [(k, lambda k=k: seraph_egg(k)) for k in kinds]
    O.main(*kinds, preview="/mnt/project-files/animals/bosses/eggs")
