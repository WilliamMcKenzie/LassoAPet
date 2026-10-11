"""The Volcano biome's floor, walls and nests (QM, Oct 11: after the Ocean; the look is
design/lava_biome's, approved Oct 10: warm browns, not dark, lava along the walls).

Run: python3 tools/volcano.py           writes them into src/world/World.rbxmx
Re-running replaces what a previous run wrote (VGND floor, VWAL walls, VNST nests).

Floor (8-stud cells, the 4-stud checker lines up): baked-earth brown at 0, lighter
ash flush, darker crust plates a stud up, and lava pools a stud down (Neon), laid out
as a quasicrystal round the big crack (layout below). The start, the nests, the crack
(tools/volcano_crack.py) and the finish stay plain floor.
"""
import os
import re
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from desert_ground import WORLD, CELL, rects, write_patches, item_span  # noqa: E402
import funnel_grid as FG  # noqa: E402
import quasicrystal as QC  # noqa: E402
import ocean_walls as OW  # noqa: E402
import ocean_nests as ON  # noqa: E402

Z_START = -16192  # the ocean's far edge
LENGTH = 7680     # as long as the ocean (Config.Biomes Volcano.Length)
END = Z_START - LENGTH
KINDS = ("Ground", "Ash", "Crust", "Lava")
TOP = (0, 0, 1, -1)
NESTS = [((16, -18) [k % 2], Z_START - 500 - k * 1100) for k in range(7)]
NEST_IN = 12  # tools/funnel.luau moves each nest this far in from the wall on its side
NEST_CLEAR = 26  # game studs round a nest kept plain (it's grown 2.6^0.8 there)
START_CLEAR = 16
END_CLEAR = 320  # studs before the far wall no rocks go: the finish line (50 in) and the crack (Config.VolcanoCrack)
CRACK_Z = END + 50 + 110  # Config: -CourseLength + FinishFromEnd + VolcanoCrack.FromFinish
CRACK_CLEAR = 56  # game studs each way round the crack kept plain (its mask is 92.6 across)
FINISH_CLEAR = 80
BAND = 1024  # parts at most this long (Roblox caps a part at 2048)

# The floor is a quasicrystal (QM, Oct 11: patterns with a rhyme and reason, like his
# map maker's atlas; tools/quasicrystal.py), drawn as it shows in game (tools/funnel_grid.py).
# Its middle is pushed off the course's centre line by OFFSET (QM, Oct 11: zoomed well
# out, off centre, so it isn't mirrored). Like atlas's lava biome, the bands are lava, floor, ash
# and crust, and every lava pool's edge cells turn to crust: lava ringed by a raised rim.
ANGLES, PATTERN = 5, 12
OFFSET = (173.4, -291.7)  # studs (random): the pattern's middle, from the crack
BANDS = (3, 0, 1, 2)  # lowest to highest value: lava, floor, ash, crust


def quasi(X, Z):
    """The pattern's 0..1 value at game (x, z)."""
    return QC.value(Z - CRACK_Z - OFFSET[1], X - OFFSET[0], ANGLES, PATTERN)


def nest_spots():
    """Where each nest ends up in game (the funnel moves it out by its wall)."""
    return [(np.sign(x) * (FG.half_width(z) - NEST_IN), z) for x, z in NESTS]


def layout():
    """The floor as a funnel_grid.Grid of kinds (KINDS); .at(x, z) reads it on the straight course."""
    grid = FG.Grid(Z_START, END, BAND)
    for b in grid.bands:
        X, Z = b.centres()
        # (worked out a cell past each band end, so a rim never stops at a band's edge)
        Xp, Zp = np.meshgrid(X[:, 0], np.concatenate([[Z[0, 0] + CELL], Z[0], [Z[0, -1] - CELL]]), indexing="ij")
        kind = QC.selective_border(QC.pattern(quasi(Xp, Zp), BANDS), 2, 3)[:, 1:-1]
        kind[Z_START - Z < START_CLEAR] = 0
        kind[Z < END + FINISH_CLEAR] = 0
        kind[(abs(X) < CRACK_CLEAR) & (abs(Z - CRACK_Z) < CRACK_CLEAR)] = 0
        for nx, nz in nest_spots():
            kind[(abs(X - nx) < NEST_CLEAR) & (abs(Z - nz) < NEST_CLEAR)] = 0
        b.kind = kind
    return grid


def boxes(grid):
    return grid.boxes(KINDS, TOP, rects)


def glow_lava():
    s = open(WORLD).read()
    s = re.sub(r'(<Item class="Part" referent="VGND\d+"><Properties>\n<string name="Name">Lava</string>\n'
               r'<bool name="Anchored">true</bool>\n)(?!<token name="Material">)',
               r'\g<1><token name="Material">288</token>\n', s)
    open(WORLD, "w").write(s)


def strip(s, pattern):
    while True:
        m = re.search(r'\n?<Item class="(?:Part|Model)" referent="%s"' % pattern, s)
        if not m:
            return s
        st = m.start() + (1 if s[m.start()] == "\n" else 0)
        s = s[:m.start()] + s[item_span(s, st):]


def walls():
    """Side walls and caps (copies of the desert's) in 8 segments a side, and the far
    wall moved to the volcano's end."""
    s = strip(open(WORLD).read(), r"VWAL\d+")
    segs = 8
    zs = [Z_START - round(LENGTH * k / segs / 8) * 8 for k in range(segs + 1)]
    new, n = [], 0
    for sx in (-1, 1):
        wall = s[slice(*OW.item(s, OW.WALL[sx]))]
        cap = s[slice(*OW.item(s, OW.CAP[sx]))]
        for k in range(segs):
            seg, zc = zs[k] - zs[k + 1], (zs[k] + zs[k + 1]) / 2
            for tmpl, size, pos in ((wall, (8, 48, seg), (sx * 60, 24, zc)), (cap, (10, 2, seg - 1), (sx * 59, 49, zc + 0.5))):
                def ref(m):
                    nonlocal n
                    n += 1
                    return f'referent="VWAL{n:05d}"'
                new.append(OW.resize(re.sub(r'referent="[A-Za-z0-9]+"', ref, tmpl), size, pos))
    for ref, y, dz in ((OW.FAR_WALL, 24, -4), (OW.FAR_CAP, 49, -3)):
        a, b = OW.item(s, ref)
        xml = s[a:b]
        size = re.search(r'<Vector3 name="size"><X>([^<]*)</X><Y>([^<]*)</Y><Z>([^<]*)</Z>', xml).groups()
        s = s[:a] + OW.resize(xml, tuple(float(v) for v in size), (0, y, END + dz)) + s[b:]
    a, b = OW.item(s, OW.WALL[1])
    s = s[:b] + "\n" + "\n".join(new) + s[b:]
    open(WORLD, "w").write(s)
    return len(new)


def nests():
    s = open(ON.PATH, encoding="utf-8").read()
    s = ON.strip(s, "VNST")
    a = s.index(f'<Item class="Model" referent="{ON.SRC}">')
    depth, i = 0, a
    for m in re.finditer(r"<Item\b|</Item>", s[a:]):
        depth += 1 if m.group(0) != "</Item>" else -1
        if depth == 0:
            i = a + m.end()
            break
    block = s[a:i]
    out = []
    for n, (x, z) in enumerate(NESTS):
        dx, dz = x - ON.SRC_AT[0], z - ON.SRC_AT[1]
        refs = {}
        b = re.sub(r'referent="(\w+)"', lambda m: 'referent="%s"' % refs.setdefault(
            m.group(1), "VNST%d_%04d" % (n, len(refs))), block)

        def move(m):
            return "<X>%g</X><Y>%s</Y><Z>%g</Z>" % (round(float(m.group(1)) + dx, 4), m.group(2),
                                                     round(float(m.group(3)) + dz, 4))
        b = re.sub(r'(?<=<CoordinateFrame name="CFrame">)<X>([^<]+)</X><Y>([^<]+)</Y><Z>([^<]+)</Z>', move, b)
        out.append(b)
    s = s[:i] + "\n" + "\n".join(out) + s[i:]
    open(ON.PATH, "w", encoding="utf-8").write(s)
    return len(out)


if __name__ == "__main__":
    grid = layout()
    print("cells", {KINDS[k]: sum(int((b.kind == k).sum()) for b in grid.bands) for k in range(4)})
    print("wrote", write_patches(r"VGND\d+", "VGND", boxes(grid), template=r"DGND00000"), "volcano floor parts")
    glow_lava()
    print("wrote", walls(), "volcano wall parts; far wall at", END - 4)
    print("wrote", nests(), "volcano nests")
