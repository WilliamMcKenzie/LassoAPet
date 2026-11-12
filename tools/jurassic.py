"""The Jurassic biome's floor, walls, nests and ribcage (QM, Oct 11: the final biome,
after the Volcano; the look is design/jurassic_biome's, Oct 10: darker jungle grass, a
rough dirt trail down the middle, brown rocks, and a stretch inside a giant ribcage).

Run: python3 tools/jurassic.py           writes them into src/world/World.rbxmx
Re-running replaces what a previous run wrote (JGND floor, JWAL walls, JNST nests, the
JRIB ribcage in World.Decor). It also moves the far wall to the Jurassic's end.

The floor is drawn as it shows in game, after tools/funnel.luau (tools/funnel_grid.py):
grass with the trail wandering down the middle, a stud lower. The ribcage stands in World.Decor
in game coordinates (the funnel leaves Decor be): bones only to look at, nothing hits them.
"""
import math
import os
import re
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from desert_ground import WORLD, CELL, rects, write_patches, item_span  # noqa: E402
from partlib import Part, T  # noqa: E402
import funnel_grid as FG  # noqa: E402
import volcano as VO  # noqa: E402
import course_layout as CL  # noqa: E402

Z_START = VO.END  # the volcano's far edge
LENGTH = 7680     # as long as the volcano (Config.Biomes Jurassic.Length, a guess)
END = Z_START - LENGTH
KINDS = ("Ground", "Trail")
TOP = (0, -1)  # the trail a stud below the grass, like the meadow's dirt (QM, Oct 11)
NESTS = [((16, -18) [k % 2], Z_START - 500 - k * 1100) for k in range(7)]
START_CLEAR = 16
BAND = 1024
BONE = [(238, 228, 202), (226, 214, 186), (246, 238, 216)]


def trail_x(z):
    """The trail's middle at z (game studs): it wanders a little either way."""
    return 26 * math.sin(z / 170) + 12 * math.sin(z / 53 + 1.3)


def trail_half(z):
    return 16 + 4 * math.sin(z / 37) + 3 * math.sin(z / 13 + 0.5)


def nest_spots():
    return [(np.sign(x) * (FG.half_width(z) - VO.NEST_IN), z) for x, z in NESTS]


def layout():
    """The floor as a funnel_grid.Grid: 0 grass, 1 trail. .at(x, z) reads it on the straight course."""
    grid = FG.Grid(Z_START, END, BAND)
    for b in grid.bands:
        X, Z = b.centres()
        tx = np.vectorize(trail_x)(Z)
        th = np.vectorize(trail_half)(Z)
        kind = (abs(X - tx) < th).astype(int)
        kind[Z_START - Z < START_CLEAR] = 0
        b.kind = kind
    return grid


def boxes(grid):
    return grid.boxes(KINDS, TOP, rects)


# ---- the ribcage (design/jurassic_biome/jurassic.py, made to the full width): a spine
# overhead along the middle, rib pairs arching out and back down to the floor by the walls.
RIB_Z0 = Z_START - 3600  # its first rib, about halfway along
RIB_N, RIB_GAP = 9, 26
RIB_TOP = 96
RIB_REACH = FG.MAX - 8


def beam(a, b, w, color):
    a, b = np.array(a, float), np.array(b, float)
    d = b - a
    z = d / np.linalg.norm(d)
    x = np.cross([0, 0, 1.0], z) if abs(z[2]) < 0.9 else np.cross([0, 1.0, 0], z)
    x /= np.linalg.norm(x)
    y = np.cross(z, x)
    cf = np.eye(4)
    cf[:3, 0], cf[:3, 1], cf[:3, 2], cf[:3, 3] = x, y, z, (a + b) / 2
    return Part("Bone", (w, w, np.linalg.norm(d) + w * 0.6), cf, color)


def ribcage():
    parts = []
    mid = (RIB_N - 1) / 2
    for k in range(RIB_N):
        z0 = RIB_Z0 - k * RIB_GAP
        s = 0.62 + 0.38 * math.cos((k - mid) / (mid + 1.2) * math.pi / 2)  # the middle ribs biggest
        top, reach, base = RIB_TOP * s, RIB_REACH * (0.7 + 0.3 * s), 26 * s
        w0 = 9 * s
        for side in (-1, 1):
            t_end = math.acos(-base / (top - base))
            n = 10
            pts = []
            for i in range(n + 1):
                t = 0.08 + (t_end - 0.08) * i / n
                pts.append((side * (6 + (reach - 6) * math.sin(t)), max(base + (top - base) * math.cos(t), -1.0),
                            z0 - (top - (base + (top - base) * math.cos(t))) * 0.22))
            for i in range(n):
                parts.append(beam(pts[i], pts[i + 1], w0 * (1 - 0.45 * i / n), BONE[(k + i) % 3 if i % 4 == 0 else 0]))
    z, i = RIB_Z0 + 50, 0
    last = RIB_Z0 - (RIB_N - 1) * RIB_GAP
    while z > last - 110:
        k = (RIB_Z0 - z) / RIB_GAP
        s = 0.62 + 0.38 * math.cos(max(-1.4, min(1.4, (k - mid) / (mid + 1.2) * math.pi / 2)))
        tail = max(0.35, 1 - max(0, -(z - last)) / 160)
        head = max(0.5, 1 - max(0, z - RIB_Z0) / 120)
        sz = 14 * s * min(tail, head)
        y = RIB_TOP * s * min(1, 0.6 + 0.4 * tail) + 2
        parts.append(Part("Bone", (sz, sz * 0.9, sz * 0.8), T(0, y, z), BONE[i % 2]))
        parts.append(Part("Bone", (sz * 0.35, sz * 0.9, sz * 0.5), T(0, y + sz * 0.8, z), BONE[2]))
        z -= sz * 1.05
        i += 1
    return parts


def write_ribcage():
    s = open(WORLD).read()
    m = re.search(r'\n?<Item class="Model" referent="JRIB000000">', s)
    if m:
        st = m.start() + (1 if s[m.start()] == "\n" else 0)
        s = s[:m.start()] + s[item_span(s, st):]
    n = [0]

    def ref():
        n[0] += 1
        return f"JRIB{n[0]:06d}"
    parts = ribcage()
    body = "\n".join(CL.part_xml(ref, p) for p in parts)
    model = ('<Item class="Model" referent="JRIB000000"><Properties>\n<string name="Name">Ribcage</string>\n'
             '</Properties>\n' + body + "\n</Item>")
    i = s.index('<string name="Name">Decor</string>')
    at = s.index("</Properties>", i) + len("</Properties>")
    s = s[:at] + "\n" + model + s[at:]
    open(WORLD, "w").write(s)
    return len(parts)


if __name__ == "__main__":
    grid = layout()
    print("cells", {KINDS[k]: sum(int((b.kind == k).sum()) for b in grid.bands) for k in range(2)})
    print("wrote", write_patches(r"JGND\d+", "JGND", boxes(grid), template=r"DGND00000"), "jurassic floor parts")
    print("wrote", VO.walls("JWAL", Z_START, LENGTH, far=END), "jurassic wall parts; far wall at", END - 4)
    print("wrote", VO.nests("JNST", NESTS), "jurassic nests")
    print("wrote", write_ribcage(), "ribcage bones into World.Decor")
