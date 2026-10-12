"""Desert ground: patchy sand, dry grass and raised sandstone checker.

Run: python3 tools/desert_ground.py            render a preview of the layout
     python3 tools/desert_ground.py --map      also write it into src/world/World.rbxmx

Sand is the base floor. Dry grass patches sit flush with it. Sandstone
plateaus stand one stud higher. The layout is on an 8-stud grid (2x2 floor
tiles), so every patch starts and ends where the 8-stud checker texture repeats
and each type's 4-stud checker lines up with the others. Patches come from
smoothed value noise, so they read as natural blobs.

In the map, the desert's one Ground part is replaced by rectangles merged from
that grid, all in World.Ground: "Ground" (sand), "Grass" and "Stone". Their
colours come from Config (WorldColors paints them by name); the ride lifts
animals onto anything in World.Ground whose top is above 0 (Shared/Ground).
"""

import os
import re
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
from partlib import Part, T, render  # noqa: E402

ROOT = os.path.join(os.path.dirname(__file__), "..")
WORLD = os.path.join(ROOT, "src", "world", "World.rbxmx")

CELL = 8
HALF_W = 56  # corridor half width (Config.CourseHalfWidth)
Z_START, Z_END = -2168, -3984  # the desert's near and far edges (QM, Oct 11: 1.5x as long, tools/course_resize.py; was -3376)
NESTS = [(16, -2388), (-14, -2588), (18, -2808), (-14, -3196), (18, -3416), (-16, -3816)]  # desert nests stay on flat ground
NEST_CLEAR = 14
SAND = [(232, 188, 102), (250, 214, 130)]  # these match Config.Biomes Desert
GRASS = [(184, 172, 70), (200, 188, 86)]
STONE = [(206, 146, 84), (222, 164, 100)]
WALL = [(206, 118, 72), (226, 138, 88)]
STONE_UP = 1  # sandstone stands this many studs above the sand
KINDS = ("Ground", "Grass", "Stone")


def noise(nx, nz, cell, seed):
    """Value noise: random values on a coarse grid, smoothly upsampled."""
    rng = np.random.default_rng(seed)
    gx, gz = int(nx / cell) + 2, int(nz / cell) + 2
    g = rng.random((gx, gz))
    xs, zs = np.arange(nx) / cell, np.arange(nz) / cell
    x0, z0 = xs.astype(int), zs.astype(int)
    fx, fz = xs - x0, zs - z0
    sx, sz = fx * fx * (3 - 2 * fx), fz * fz * (3 - 2 * fz)
    a = g[x0][:, z0]
    b = g[x0 + 1][:, z0]
    c = g[x0][:, z0 + 1]
    d = g[x0 + 1][:, z0 + 1]
    sx, sz = sx[:, None], sz[None, :]
    return (a * (1 - sx) + b * sx) * (1 - sz) + (c * (1 - sx) + d * sx) * sz


def cell_centre(i, j):
    return -HALF_W + i * CELL + CELL / 2, Z_START - j * CELL - CELL / 2


def layout(seed=3):
    """Kind index per 8-stud cell: 0 sand, 1 dry grass, 2 sandstone."""
    nx, nz = 2 * HALF_W // CELL, (Z_START - Z_END) // CELL
    n1 = noise(nx, nz, 3, seed) * 0.75 + noise(nx, nz, 1.5, seed + 1) * 0.25
    n2 = noise(nx, nz, 2.5, seed + 2) * 0.75 + noise(nx, nz, 1.2, seed + 3) * 0.25
    kind = np.zeros((nx, nz), int)
    kind[n2 > 0.62] = 1
    kind[n1 > 0.64] = 2
    for i in range(nx):
        for j in range(nz):
            x, z = cell_centre(i, j)
            if kind[i, j] == 2 and any(abs(x - a) < NEST_CLEAR + CELL / 2 and abs(z - b) < NEST_CLEAR + CELL / 2
                                       for a, b in NESTS):
                kind[i, j] = 0
    return kind


def rects(kind):
    """Greedy merge of same-kind cells into rectangles: (k, i0, j0, i1, j1), ends exclusive."""
    nx, nz = kind.shape
    done = np.zeros_like(kind, bool)
    out = []
    for i in range(nx):
        for j in range(nz):
            if done[i, j]:
                continue
            k = kind[i, j]
            j1 = j
            while j1 < nz and kind[i, j1] == k and not done[i, j1]:
                j1 += 1
            i1 = i + 1
            while i1 < nx and all(kind[i1, jj] == k and not done[i1, jj] for jj in range(j, j1)):
                i1 += 1
            done[i:i1, j:j1] = True
            out.append((k, i, j, i1, j1))
    return out


def box(k, i0, j0, i1, j1):
    """(centre, size) of a rectangle; tops at 0 (sand, grass) or STONE_UP, bottoms at -2."""
    top = STONE_UP if k == 2 else 0
    x0, x1 = -HALF_W + i0 * CELL, -HALF_W + i1 * CELL
    z0, z1 = Z_START - j0 * CELL, Z_START - j1 * CELL
    return ((x0 + x1) / 2, (top - 2) / 2, (z0 + z1) / 2), (x1 - x0, top + 2, z0 - z1)


def preview(kind, out, length=200):
    """The first `length` studs of the desert from the ride camera and up close."""
    parts = []
    nx, nz = kind.shape
    for i in range(nx):
        for j in range(min(nz, length // CELL)):
            k = kind[i, j]
            top = STONE_UP if k == 2 else 0
            colors = (SAND, GRASS, STONE)[k]
            for di in (0, 1):
                for dj in (0, 1):
                    x = -HALF_W + i * CELL + di * 4 + 2
                    z = -j * CELL - dj * 4 - 2
                    chk = (di + dj) % 2
                    parts.append(Part(KINDS[k], (4, top + 1, 4), T(x, (top - 1) / 2, z), colors[chk]))
    for side in (-1, 1):
        for zi in range(length // 4):
            for yi in range(4):
                parts.append(Part("Wall", (4, 4, 4), T(side * (HALF_W + 2), yi * 4 + 2, -zi * 4 - 2),
                                  WALL[(zi + yi) % 2], plain=True))
    os.makedirs(out, exist_ok=True)
    kw = dict(W=1000, H=640, fog=False, ground=False)
    ride = render(parts, eye=(0, 70, 30), target=(0, 0, -70), fov=50, **kw)
    close = render(parts, eye=(-30, 14, -20), target=(-4, 0, -62), fov=45, **kw)
    board = Image.new("RGB", (1000, 1280))
    board.paste(ride, (0, 0))
    board.paste(close, (0, 640))
    board.save(os.path.join(out, "desert_ground.png"))


def item_span(s, start):
    depth = 0
    for m in re.finditer(r"<Item\b|</Item>", s[start:]):
        depth += 1 if m.group() == "<Item" else -1
        if depth == 0:
            return start + m.end()


def write_patches(old_refs, ref_prefix, boxes, template=None):
    """Replace a biome's floor parts in World.rbxmx. old_refs: regex of the
    referents to replace (the biome's one Ground part, or the patches a previous
    run wrote); the first one is the template (its textures come along).
    boxes: (name, centre, size) per new part. template: when no old_refs part
    exists yet (a new biome), the referent regex of a part to copy (kept).
    Returns how many were written."""
    s = open(WORLD).read()
    old = [m.start() for m in re.finditer(r'<Item class="Part" referent="(%s)"' % old_refs, s)]
    if not old and template:
        st = re.search(r'<Item class="Part" referent="(%s)"' % template, s).start()
        template = s[st:item_span(s, st)]
        template_start = item_span(s, st) + 1
    else:
        assert old, "floor part not found: " + old_refs
        template_start = old[0]
        template = s[template_start:item_span(s, template_start)]
    for st in reversed(old):
        s = s[:st] + s[item_span(s, st):].lstrip("\n")
    items = []
    for n, (name, (cx, cy, cz), (sx, sy, sz)) in enumerate(boxes):
        refs = iter(range(3))
        t = re.sub(r'referent="[A-Z0-9]+"', lambda m: f'referent="{ref_prefix}{n * 3 + next(refs):05d}"', template)
        t = re.sub(r'<string name="Name">[^<]*</string>', f'<string name="Name">{name}</string>', t, count=1)
        t = re.sub(r'<Vector3 name="size">.*?</Vector3>',
                   f'<Vector3 name="size"><X>{sx:g}</X><Y>{sy:g}</Y><Z>{sz:g}</Z></Vector3>', t, count=1)
        t = re.sub(r'(<CoordinateFrame name="CFrame">)<X>[^<]*</X><Y>[^<]*</Y><Z>[^<]*</Z>',
                   rf'\g<1><X>{cx:g}</X><Y>{cy:g}</Y><Z>{cz:g}</Z>', t, count=1)
        items.append(t)
    s = s[:template_start] + "\n".join(items) + "\n" + s[template_start:]
    open(WORLD, "w").write(s)
    return len(items)


def write_map(kind):
    boxes = [(KINDS[k],) + box(k, i0, j0, i1, j1) for k, i0, j0, i1, j1 in rects(kind)]
    return write_patches(r"DSRT0001|DGND\d+", "DGND", boxes)


def main():
    kind = layout()
    preview(kind, "/mnt/project-files/biomes/desert_ground")
    counts = {KINDS[k]: int((kind == k).sum()) for k in range(3)}
    print("cells:", counts, "rects:", len(rects(kind)))
    if "--map" in sys.argv:
        print("wrote", write_map(kind), "parts into", WORLD)


if __name__ == "__main__":
    main()
