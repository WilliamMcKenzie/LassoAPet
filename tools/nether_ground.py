"""Nether biome concept: red sand, red stone and lava ground laid out by QM's
MapMaker "Hot" biome, angled walls that funnel and open up, and sideways lava
geysers on the walls of the open stretches.

Run: python3 tools/nether_ground.py     render the concept into /mnt/project-files/biomes/nether/

Ground: a port of github.com/WilliamMcKenzie/MapMaker server/mapgen.go's Hot
biome (studio-imperium/atlas): the floor is split into Voronoi cells, an
"infection" spreads out from a few origin cells, and each cell gets a
sub-biome by how many rings it is from the nearest origin (decay 0.4):
  0  Pattern(3.3, LAVA, GRAVEL)                       big lava swirls
  1  Pattern(15, LAVA, RUIN) + border(GRAVEL, LAVA)    wavy lava in stone, sand rims
  2  Voronoi(20, RUIN, LAVA) + border(GRAVEL, LAVA)    broken stone and lava bits
GRAVEL is our red sand (base), RUIN our red stone (a stud up), LAVA a stud down.
One atlas tile is one 4-stud checker tile. A long course has several origins
(atlas' single Infect on a square map would make most of a long strip sub-biome 2).
"""

import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(__file__))
from partlib import Part, T, Ry, render  # noqa: E402
import terrain_assets as TA  # noqa: E402

OUT = "/mnt/project-files/biomes/nether"
TILE = 4
# Colours picked off QM's reference (MapMaker's Hot biome).
SAND = [(107, 49, 32), (117, 56, 38)]   # gravel
STONE = [(78, 38, 29), (88, 43, 32)]    # ruin (its dark grid lines read as a darker tone)
LAVA = [(216, 116, 51), (234, 138, 60)]
WALL = [(62, 28, 22), (74, 34, 26)]
STONE_UP, LAVA_DOWN = 1, 1
WALL_ROWS = 5
GRAVEL, RUIN, LAVA_T = 0, 1, 2


# ---------------------------------------------------------------- ground (atlas port)

def pattern(angles, values, X, Y):
    """atlas.NewPattern: a quasi-crystal of cos waves at evenly turned angles."""
    v = np.zeros_like(X, float)
    angle = 2.0 * 3.14156
    delta = angle / angles
    i = 0
    while i < angles:
        v += np.cos(np.cos(angle) * X + np.sin(angle) * Y)
        angle -= delta
        i += 1
    t = (v / angles + 1.0) / 2.0 * len(values)
    idx = np.maximum(0, np.floor(t)).astype(int) % len(values)
    return np.array(values)[idx]


def selective_border(val, cell, border, around):
    """atlas.NewSelectiveBorder: `around` tiles touching another value, another
    cell or the map edge become `border`."""
    nx, nz = val.shape
    edge = np.zeros_like(val, bool)
    for dx, dz in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        sv = np.full_like(val, -1)
        sc = np.full_like(cell, -1)
        xs = slice(max(dx, 0), nx + min(dx, 0))
        xd = slice(max(-dx, 0), nx + min(-dx, 0))
        zs = slice(max(dz, 0), nz + min(dz, 0))
        zd = slice(max(-dz, 0), nz + min(-dz, 0))
        sv[xd, zd] = val[xs, zs]
        sc[xd, zd] = cell[xs, zs]
        edge |= (sv != around) | (sc != cell)
    out = val.copy()
    out[(val == around) & edge] = border
    return out


def ground(nx, nz, seed=7, area=144, origin_every=200):
    """Tile kind per 4-stud tile, x across (nx) and z along (nz)."""
    rng = np.random.default_rng(seed)
    X, Y = np.meshgrid(np.arange(nx, dtype=float), np.arange(nz, dtype=float), indexing="ij")
    # Voronoi cells
    n = max(4, nx * nz // area)
    pts = np.stack([rng.uniform(0, nx, n), rng.uniform(0, nz, n)], 1)
    cell = np.zeros((nx, nz), int)
    best = np.full((nx, nz), np.inf)
    for k, (px, pz) in enumerate(pts):
        d = np.hypot(X - px, Y - pz)
        m = d < best
        best[m], cell[m] = d[m], k
    # cell adjacency (tiles touching across a cell edge)
    adj = [set() for _ in range(n)]
    for a, b in ((cell[1:, :], cell[:-1, :]), (cell[:, 1:], cell[:, :-1])):
        m = a != b
        for p, q in zip(a[m], b[m]):
            adj[p].add(q)
            adj[q].add(p)
    # infection rings from origins spaced along the course
    origins = []
    for z0 in range(0, nz, origin_every):
        zc = z0 + rng.uniform(0.2, 0.8) * min(origin_every, nz - z0)
        origins.append(int(cell[int(rng.uniform(0.2, 0.8) * nx), min(int(zc), nz - 1)]))
    ring = np.full(n, 10 ** 6)
    frontier = list(set(origins))
    for o in frontier:
        ring[o] = 0
    r = 0
    while frontier:
        r += 1
        nxt = []
        for c in frontier:
            for a in adj[c]:
                if ring[a] > r:
                    ring[a] = r
                    nxt.append(a)
        frontier = nxt
    biome = np.minimum(2, np.floor(0.4 * (ring + 1)).astype(int))[cell]
    # sub-biomes
    b0 = pattern(3.3, [LAVA_T, GRAVEL], X, Y)
    b1 = pattern(15, [LAVA_T, RUIN], X, Y)
    b2 = np.full((nx, nz), GRAVEL)
    for k in range(n):
        m = cell == k
        if not m.any() or biome[m][0] != 2:
            continue
        tx, tz = X[m], Y[m]
        crng = np.random.default_rng(20 + k)
        pick = crng.integers(0, len(tx), 20)
        sx, sz = tx[pick], tz[pick]
        d = (tx[:, None] - sx[None]) ** 2 + (tz[:, None] - sz[None]) ** 2
        near = d.argmin(1)
        b2[m] = np.array([RUIN, LAVA_T])[(sx[near] + sz[near]).astype(int) % 2]
    val = np.where(biome == 0, b0, np.where(biome == 1, b1, b2))
    b1b = selective_border(np.where(biome == 1, val, -9), np.where(biome == 1, cell, -1), GRAVEL, LAVA_T)
    b2b = selective_border(np.where(biome == 2, val, -9), np.where(biome == 2, cell, -1), GRAVEL, LAVA_T)
    val = np.where(biome == 1, b1b, np.where(biome == 2, b2b, val))
    return val, biome


# ---------------------------------------------------------------- walls

def wall_profile(length, seed=5):
    """Control points (z along, left x, right x): the corridor pinches to a
    funnel, then opens into a wide chamber, and so on. The walls run straight
    between points, so every change of width is an angled wall."""
    rng = np.random.default_rng(seed)
    pts = [(0.0, -56.0, 56.0)]
    z = 0.0
    wide = False
    while z < length:
        z += rng.uniform(90, 140)  # the angled run
        if wide:
            c = rng.uniform(-14, 14)
            hw = rng.uniform(24, 32)  # a 50-60 stud funnel
        else:
            c = rng.uniform(-10, 10)
            hw = rng.uniform(80, 96)  # a 160-190 stud chamber
        l, r = c - hw + rng.uniform(-8, 8), c + hw + rng.uniform(-8, 8)
        pts.append((z, l, r))
        z += rng.uniform(60, 110) if wide else rng.uniform(110, 170)  # hold it
        pts.append((z, l + rng.uniform(-10, 10), r + rng.uniform(-10, 10)))
        wide = not wide
    return pts


def walls_at(prof, z):
    """Left and right wall x at distance z along."""
    for (z0, l0, r0), (z1, l1, r1) in zip(prof, prof[1:]):
        if z0 <= z <= z1:
            t = (z - z0) / (z1 - z0)
            return l0 + (l1 - l0) * t, r0 + (r1 - r0) * t
    return prof[-1][1], prof[-1][2]


def wall_parts(prof, z_from, z_to):
    """Checker wall blocks along each straight wall run, turned to its angle.
    World z is minus the distance along."""
    parts = []
    for side in (1, 2):
        out = -1 if side == 1 else 1
        for a, b in zip(prof, prof[1:]):
            za, zb = a[0], b[0]
            if zb < z_from or za > z_to:
                continue
            xa, xb = a[side], b[side]
            ax, az = xb - xa, -(zb - za)  # run direction in world xz
            L = math.hypot(ax, az)
            ang = math.degrees(math.atan2(-az, ax))  # Ry(ang) turns local +x onto the run
            nx_, nz_ = -az / L, ax / L  # a normal; flip it to point out of the corridor
            if nx_ * out < 0:
                nx_, nz_ = -nx_, -nz_
            nseg = max(1, int(round(L / 4)))
            for k in range(nseg + 1):  # one extra block closes the joint
                t = (k + 0.5) / nseg
                cx, cz = xa + ax * t, -za + az * t
                for yi in range(-1, WALL_ROWS):
                    cf = T(cx + nx_ * 2, yi * 4 + 2, cz + nz_ * 2) @ Ry(ang)
                    parts.append(Part("Wall", (L / nseg + 0.2, 4, 4), cf, WALL[(k + yi) % 2], plain=True))
    return parts


# ---------------------------------------------------------------- the lava geyser

def lava(name, size, cf, c=0, glow=True):
    p = Part(name, size, cf, LAVA[c], plain=True)
    p.neon = glow
    return p


def geyser(base, y=6, spray=0.0, seed=0):
    """A red stone vent lying on its side on a wall; base is the wall point's
    frame, local +x into the corridor. spray 0 = idle (lava in the mouth),
    0..1 = how far the jet has reached. The jet shoots out, then arcs down."""
    loc = []
    for k, (w, d) in enumerate(((10, 3), (8, 2.5), (6, 2))):
        x = sum((3, 2.5, 2)[:k]) + d / 2
        loc.append(Part("Vent", (d, w, w), T(x, y, 0), STONE[k % 2]))
    mx = 8
    for dy, dz, sz in ((2.5, 0, (1, 1, 6)), (-2.5, 0, (1, 1, 6)), (0, 2.5, (1, 4, 1)), (0, -2.5, (1, 4, 1))):
        loc.append(Part("Rim", sz, T(mx, y + dy, dz), SAND[1]))
    loc.append(lava("Mouth", (0.6, 4, 4), T(mx - 0.2, y, 0), 1))
    loc.append(lava("Drip", (0.6, y - 1, 1.2), T(0.4, (y - 1) / 2, 1.5)))
    loc.append(lava("Drip", (0.6, y - 3, 1), T(0.4, (y - 3) / 2, -2)))
    if spray > 0:
        arc = lambda t: y + 0.25 * t - 0.0045 * t * t  # noqa: E731
        reach = 80 * spray
        for i in range(int(reach / 3)):
            t = i * 3
            h = arc(t)
            if h < 0.5:
                break
            w = 3.6 + 0.04 * t
            loc.append(lava("Jet", (3.2, w, w), T(mx + t + 1.5, h, math.sin(t * 0.35) * 0.6), i % 2))
        rng = np.random.default_rng(seed)
        for _ in range(int(10 * spray)):
            t = rng.uniform(4, reach)
            loc.append(lava("Blob", (1.2, 1.2, 1.2), T(mx + t, max(arc(t) + rng.uniform(1.5, 4), 1), rng.uniform(-4, 4)), 1))
        land = next((t for t in np.arange(0, reach, 0.5) if arc(t) < 0.5), None)
        if land is not None:
            for dx, dz, w in ((0, 0, 8), (3, 3, 4), (-2, -4, 4)):
                loc.append(lava("Splash", (w, 0.4, w), T(mx + land + dx, 0.2, dz), 1))
    for p in loc:
        p.cf = base @ p.cf
    return loc


def geyser_spots(prof, length):
    """Geysers sit on the walls of the open stretches only (corridor wider than
    120 studs), alternating sides about every 60 studs. Returns (z, side, frame)
    with the frame's +x pointing into the corridor, square to the wall."""
    spots = []
    z, side = 30.0, 1
    while z < length:
        l, r = walls_at(prof, z)
        if r - l > 120:
            x = l if side == 1 else r
            l2, r2 = walls_at(prof, z + 1)
            ax, az = ((l2 - l) if side == 1 else (r2 - r)), -1.0  # wall direction in world xz
            k = math.hypot(ax, az)
            nx_, nz_ = -az / k, ax / k
            if nx_ * (1 if side == 1 else -1) < 0:
                nx_, nz_ = -nx_, -nz_
            ang = math.degrees(math.atan2(-nz_, nx_))  # Ry(ang) turns local +x onto the normal
            spots.append((z, side, T(x, 0, -z) @ Ry(ang)))
            side = 3 - side
            z += 60
        else:
            z += 8
    return spots


# ---------------------------------------------------------------- renders

def scene(val, prof, x0, z_from, z_to, sprays):
    parts = []
    nx, nz = val.shape
    for j in range(max(0, int(z_from // TILE)), min(nz, int(z_to // TILE))):
        zc = j * TILE + 2
        l, r = walls_at(prof, zc)
        for i in range(nx):
            xc = x0 + i * TILE + 2
            if xc < l - 6 or xc > r + 6:
                continue
            k = val[i, j]
            top = (0, STONE_UP, -LAVA_DOWN)[k]
            pal = (SAND, STONE, LAVA)[k]
            parts.append(Part(("Ground", "Stone", "Lava")[k], (4, top + 2, 4), T(xc, (top - 2) / 2, -zc),
                              pal[(i + j) % 2], plain=(k == 2)))
    parts += wall_parts(prof, z_from - 40, z_to + 40)
    for n, (z, side, cf) in enumerate(geyser_spots(prof, z_to + 20)):
        if z_from - 20 < z < z_to + 20:
            parts += geyser(cf, spray=sprays[n % len(sprays)], seed=n)
    return parts


def label(img, text, size=30):
    d = ImageDraw.Draw(img)
    d.text((16, 12), text, fill=(255, 255, 255), font=TA.font(size), stroke_width=3, stroke_fill=(0, 0, 0))
    return img


def topdown(val, prof, x0, length, px=3):
    """Map view: the ride starts at the bottom, outside the walls is black,
    geysers are yellow dots with a line where they spray."""
    nx, nz = val.shape
    nz = min(nz, int(length // TILE))
    img = np.zeros((nz, nx, 3), np.uint8)
    for j in range(nz):
        l, r = walls_at(prof, j * TILE + 2)
        for i in range(nx):
            xc = x0 + i * TILE + 2
            if xc < l or xc > r:
                img[nz - 1 - j, i] = (24, 12, 10)
            else:
                img[nz - 1 - j, i] = (SAND, STONE, LAVA)[val[i, j]][(i + j) % 2]
    im = Image.fromarray(img).resize((nx * px, nz * px), Image.NEAREST)
    d = ImageDraw.Draw(im)
    s = px / TILE
    for z, side, cf in geyser_spots(prof, length):
        wx, wz = cf[0, 3], -cf[2, 3]
        dx, dz = cf[0, 0], -cf[2, 0]
        X, Y = (wx - x0) * s, (length - wz) * s
        d.line((X, Y, X + dx * 70 * s, Y - dz * 70 * s), fill=(255, 220, 60), width=3)
        d.ellipse((X - 6, Y - 6, X + 6, Y + 6), fill=(255, 220, 60), outline=(0, 0, 0))
    return im


def main():
    os.makedirs(OUT, exist_ok=True)
    length = 1600
    prof = wall_profile(length)
    half = 112  # the generated floor is wider than the widest chamber
    x0 = -half
    nx, nz = 2 * half // TILE, length // TILE
    val, biome = ground(nx, nz)
    print({k: int((val == v).sum()) for k, v in (("sand", GRAVEL), ("stone", RUIN), ("lava", LAVA_T))},
          "sub-biomes", np.bincount(biome.ravel(), minlength=3))
    topdown(val, prof, x0, length, px=8).save(os.path.join(OUT, "nether_map.png"))
    if "--map-only" in sys.argv:
        return

    kw = dict(W=1100, H=680, fog=False, ground=False)
    z_open = geyser_spots(prof, length)[0][0]
    shots = []
    near = scene(val, prof, x0, 0, 320, [1.0, 0, 0.5])
    shots.append(label(render(near, eye=(0, 70, -10), target=(0, 0, -110), fov=55, **kw), "Ride view: the course opens into a chamber"))
    zc = z_open + 40
    mid = scene(val, prof, x0, zc - 120, zc + 200, [1.0, 0, 0.5, 1.0])
    shots.append(label(render(mid, eye=(0, 75, -(zc - 90)), target=(0, 0, -(zc + 30)), fov=60, **kw),
                       "Ride view: geysers firing, the funnel ahead"))
    low = scene(val, prof, x0, zc - 40, zc + 140, [1.0, 0, 0.5, 1.0])
    shots.append(label(render(low, eye=(-20, 16, -(zc - 30)), target=(10, 2, -(zc + 50)), fov=55, **kw),
                       "Close up"))
    board = Image.new("RGB", (1100, 680 * 3))
    for n, im in enumerate(shots):
        board.paste(im, (0, 680 * n))
    board.save(os.path.join(OUT, "nether_ride.png"))

    # the geyser on its own, on an angled wall: idle, starting, full spray
    gprof = [(0, -40, 40), (200, -90, 90)]
    spot = geyser_spots(gprof, 200)[0]
    out = []
    for sp, title in ((0, "Idle"), (0.45, "Starting"), (1.0, "Full spray")):
        parts = scene(val[:, :60], gprof, x0, max(0, spot[0] - 50), spot[0] + 90, [0])
        parts = [p for p in parts if p.name not in ("Vent", "Rim", "Mouth", "Drip")] + geyser(spot[2], spray=sp)
        wx, wz = spot[2][0, 3], spot[2][2, 3]
        im = render(parts, eye=(wx + 70, 30, wz + 50), target=(wx + 25, 4, wz - 5), fov=50, W=700, H=520,
                    fog=False, ground=False)
        out.append(label(im, title))
    sheet = Image.new("RGB", (2100, 520))
    for n, im in enumerate(out):
        sheet.paste(im, (700 * n, 0))
    sheet.save(os.path.join(OUT, "lava_geyser.png"))


if __name__ == "__main__":
    main()
