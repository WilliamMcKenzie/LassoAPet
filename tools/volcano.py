"""The Volcano biome's floor, walls and nests (QM, Oct 11: after the Ocean; the look is
design/lava_biome's, approved Oct 10: warm browns, not dark, lava along the walls).

Run: python3 tools/volcano.py           writes them into src/world/World.rbxmx
Re-running replaces what a previous run wrote (VGND floor, VWAL walls, VNST nests).

Floor (8-stud cells, the 4-stud checker lines up): baked-earth brown at 0, lighter
ash patches flush, darker crust plates a stud up, and lava pools a stud down (Neon)
only out by the walls; the middle stays plain. The start, the nests and the end
(where the big crack is, tools/volcano_crack.py) stay plain floor.
"""
import os
import re
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from desert_ground import WORLD, CELL, HALF_W, noise, rects, write_patches, item_span  # noqa: E402
import ocean_walls as OW  # noqa: E402
import ocean_nests as ON  # noqa: E402

Z_START = -16192  # the ocean's far edge
LENGTH = 7680     # as long as the ocean (Config.Biomes Volcano.Length)
END = Z_START - LENGTH
KINDS = ("Ground", "Ash", "Crust", "Lava")
TOP = (0, 0, 1, -1)
NESTS = [((16, -18) [k % 2], Z_START - 500 - k * 1100) for k in range(7)]
NEST_CLEAR = 14
START_CLEAR = 16
END_CLEAR = 320  # studs before the far wall kept plain: the finish line (50 in) and the crack (Config.VolcanoCrack)
LAVA_COLS = (1, 2, 3)  # cells in from each wall lava may lie in (the wall's own column stays solid)
MAX_CELLS = 128  # parts at most 1024 studs long (Roblox caps a part at 2048)


def layout(seed=61):
    nx, nz = 2 * HALF_W // CELL, LENGTH // CELL
    # broad blobs: few, big patches keep the 7680-stud floor to about the ocean's part count
    ash = noise(nx, nz, 7.0, seed) * 0.8 + noise(nx, nz, 3.0, seed + 1) * 0.2
    crust = noise(nx, nz, 7.0, seed + 2) * 0.85 + noise(nx, nz, 3.0, seed + 3) * 0.15
    lava = noise(nx, nz, 5.0, seed + 4)
    kind = np.zeros((nx, nz), int)
    edge = np.zeros(nx, bool)
    for c in LAVA_COLS:
        edge[c] = edge[nx - 1 - c] = True
    side = np.zeros(nx, bool)
    side[:4] = side[-4:] = True
    kind[ash > 0.6] = 1
    kind[(crust > np.where(side, 0.6, 0.76)[:, None])] = 2
    kind[edge[:, None] & (lava > 0.68)] = 3
    kind[:, : START_CLEAR // CELL] = 0
    kind[:, nz - END_CLEAR // CELL:] = 0
    for i in range(nx):
        for j in range(nz):
            x, z = -HALF_W + i * CELL + CELL / 2, Z_START - j * CELL - CELL / 2
            if any(abs(x - a) < NEST_CLEAR + CELL / 2 and abs(z - b) < NEST_CLEAR + CELL / 2 for a, b in NESTS):
                kind[i, j] = 0
    return kind


def split(rs):
    for k, i0, j0, i1, j1 in rs:
        j = j0
        while j < j1:
            end = min(j1, (j // MAX_CELLS + 1) * MAX_CELLS)
            yield k, i0, j, i1, end
            j = end


def boxes(kind):
    out = []
    for k, i0, j0, i1, j1 in split(rects(kind)):
        top = TOP[k]
        x0, x1 = -HALF_W + i0 * CELL, -HALF_W + i1 * CELL
        z0, z1 = Z_START - j0 * CELL, Z_START - j1 * CELL
        out.append((KINDS[k], ((x0 + x1) / 2, (top - 2) / 2, (z0 + z1) / 2), (x1 - x0, top + 2, z0 - z1)))
    return out


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
    kind = layout()
    print("cells", {KINDS[k]: int((kind == k).sum()) for k in range(4)})
    print("wrote", write_patches(r"VGND\d+", "VGND", boxes(kind), template=r"DGND00000"), "volcano floor parts")
    glow_lava()
    print("wrote", walls(), "volcano wall parts; far wall at", END - 4)
    print("wrote", nests(), "volcano nests")
