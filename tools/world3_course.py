"""World 3's course (QM, Oct 14; draft): four new biomes past the pirate-island base, in order
Pirate Cove, Garden, Candyland and Cnidaria.

Run: python3 tools/world3_course.py [out_dir]
     renders each biome top-down to out_dir (default /mnt/project-files/world3/terrain) and
     writes tools/world3_course.luau (the walls, clearing World 2's copied course) and
     tools/world3_<biome>.luau (each biome's floor) from their .luau.in templates.

- Each biome is about 2x as long as its World 1 / World 2 equivalent (Meadow 2168,
  Desert 1816, Snow 1920, Ocean 3120): 4336, 3632, 3840 and 6240 studs, 18048 in all.
- The course isn't a straight funnel any more: PROFILE gives its half width at points down
  the course, straight walls between them, so it widens into bays and narrows into necks.
  Never wider than World 1's and World 2's widest (Config.CourseMaxHalfWidth, 137).
- Every floor is a quasicrystal (tools/quasicrystal.py, QM's map maker) cut into bands,
  laid out in game space (no funnel: the walls follow PROFILE, the floor is built to fit).
- QM's layered rule: each biome's tiles form a ladder, and a tile only ever touches the
  ones a rung either side of it (diagonals too), so there is always a transition ring.
  check() asserts it. The upper rung sits a stud above the lower.
"""

import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(__file__))
from desert_ground import rects  # noqa: E402
from quasicrystal import value  # noqa: E402

HERE = os.path.dirname(__file__)
CELL, BLOCK = 8, 1000
MAXW = 137  # Config.CourseMaxHalfWidth: World 1's Jurassic and World 2's Tomb at their widest

# (name, length): about 2x Meadow, Desert, Snow, Ocean
BIOMES = [("PirateCove", 4336), ("Garden", 3632), ("Candyland", 3840), ("Cnidaria", 6240)]
STARTS = [0]
for _, n in BIOMES:
    STARTS.append(STARTS[-1] - n)
END = STARTS[-1]  # -18048

# The course's half width at points down it (z, half width), straight walls between them.
PROFILE = [
    # Pirate Cove: out of the base's 56, a cove, a neck, a wide lagoon bay, narrowing to the gate
    (0, 56), (-480, 64), (-880, 92), (-1440, 92), (-1840, 68), (-2240, 72), (-2680, 108), (-3240, 108), (-3760, 80), (-4336, 76),
    # Garden: a lawn, a hedge-lined walk, a wide formal garden, a narrower gate
    (-4800, 102), (-5240, 82), (-5720, 82), (-6200, 118), (-6840, 118), (-7360, 92), (-7968, 88),
    # Candyland: a plaza, a neck, a wide sugar field, narrowing
    (-8400, 114), (-8880, 114), (-9320, 94), (-9880, 128), (-10520, 128), (-11040, 104), (-11808, 100),
    # Cnidaria: open reef, two trenches' necks, the widest at the end
    (-12400, 130), (-13000, MAXW), (-13640, 112), (-14320, 112), (-15000, MAXW), (-15840, MAXW), (-16520, 118), (-17280, 132), (END, 128),
]


def half_width(z):
    zs = [p[0] for p in PROFILE]
    if z >= zs[0]:
        return PROFILE[0][1]
    for (z0, h0), (z1, h1) in zip(PROFILE, PROFILE[1:]):
        if z1 <= z <= z0:
            return h0 + (h1 - h0) * (z0 - z) / (z0 - z1)
    return PROFILE[-1][1]


OUT = int(math.ceil(MAXW / CELL)) * CELL  # 144
NX = 2 * OUT // CELL
VOID = -1


class Biome:
    """A ladder of tiles (rung 0 the lowest), the floor's grid and its quasicrystal."""

    def __init__(self, index, tiles):
        self.index, self.name = index, BIOMES[index][0]
        self.z0, self.z1 = STARTS[index], STARTS[index + 1]
        self.nz = (self.z0 - self.z1) // CELL
        self.tiles = tiles  # [rung] = (name, top, part colour, checker colour or None)
        xs = -OUT + CELL * np.arange(NX) + CELL / 2
        zs = self.z0 - CELL * np.arange(self.nz) - CELL / 2
        self.x, self.z = np.meshgrid(xs, zs, indexing="ij")
        self.inside = np.zeros((NX, self.nz), bool)  # cells with floor (out to under the walls)
        self.hw = np.array([half_width(z) for z in zs])
        for j in range(self.nz):
            h = max(half_width(self.z0 - j * CELL), half_width(self.z0 - (j + 1) * CELL))
            edge = int(math.ceil(h / CELL)) * CELL
            self.inside[:, j] = np.abs(self.x[:, j]) < edge
        self.rung = np.zeros((NX, self.nz), int)
        self.free = np.zeros((NX, self.nz), bool)  # structures the ladder doesn't rule (boardwalks)

    def quasi(self, angles, scale, offset):
        return value(self.x + offset[0], self.z + offset[1], angles, scale)

    def band(self, q, cuts):
        """q's quantiles (inside the walls) cut at `cuts` (rising): rung 0 below the first."""
        qs = np.quantile(q[self.inside], cuts)
        self.rung = np.searchsorted(qs, q).astype(int)


def neighbours(a, fill):
    """The 8 neighbours of every cell (padded with fill)."""
    p = np.pad(a, 1, constant_values=fill)
    nx, nz = a.shape
    return [p[1 + dx:1 + dx + nx, 1 + dz:1 + dz + nz] for dx in (-1, 0, 1) for dz in (-1, 0, 1) if dx or dz]


def lower(rung, inside):
    """The layered rule from below: a cell is at most a rung above every neighbour (tiles
    round a lower patch step down to it: the rim)."""
    big = 999
    r = np.where(inside, rung, big)
    while True:
        m = np.min(neighbours(r, big), axis=0) + 1
        new = np.where(inside, np.minimum(r, m), big)
        if (new == r).all():
            return np.where(inside, new, 0)
        r = new


def raise_(rung, inside, fixed):
    """The layered rule from above, round a stamped feature: neighbours are lifted to at
    most a rung below (fixed cells keep theirs)."""
    r = np.where(inside, rung, -999)
    while True:
        m = np.max(neighbours(r, -999), axis=0) - 1
        new = np.where(inside & ~fixed, np.maximum(r, m), r)
        if (new == r).all():
            return np.where(inside, new, 0)
        r = new


def tidy(rung, inside, passes=2):
    """No lone tiles: a cell unlike 6 or more of its 8 neighbours takes their rung."""
    for _ in range(passes):
        nb = np.array(neighbours(rung, -1))
        for k in np.unique(rung):
            many = (nb == k).sum(axis=0) >= 6
            rung = np.where(inside & many & (rung != k), k, rung)
    return rung


def patches(rung, inside):
    """Each joined patch (4-way) of one rung: (rung, cells, the rungs round it)."""
    nx, nz = rung.shape
    seen = np.zeros_like(inside)
    for i in range(nx):
        for j in range(nz):
            if seen[i, j] or not inside[i, j]:
                continue
            k, cells, todo, rim = rung[i, j], [], [(i, j)], []
            seen[i, j] = True
            while todo:
                a, c = todo.pop()
                cells.append((a, c))
                for da, dc in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    a2, c2 = a + da, c + dc
                    if 0 <= a2 < nx and 0 <= c2 < nz and inside[a2, c2]:
                        if rung[a2, c2] == k:
                            if not seen[a2, c2]:
                                seen[a2, c2] = True
                                todo.append((a2, c2))
                        else:
                            rim.append(int(rung[a2, c2]))
            yield k, cells, rim


def blocks(rung):
    """Every cell that is part of a 2x2 block of its own rung."""
    nx, nz = rung.shape
    same = np.zeros((nx, nz), bool)
    same[:-1, :-1] = (rung[:-1, :-1] == rung[1:, :-1]) & (rung[:-1, :-1] == rung[:-1, 1:]) & (rung[:-1, :-1] == rung[1:, 1:])
    out = same.copy()
    out[1:, :] |= same[:-1, :]
    out[:, 1:] |= same[:, :-1]
    out[1:, 1:] |= same[:-1, :-1]
    return out


def blocky(rung, inside):
    """No patch smaller than 2x2 (QM: big joined patches, no stray tiles): a patch with no
    2x2 block of itself in it takes the rung most common round it."""
    rung = rung.copy()
    block = blocks(rung)
    for k, cells, rim in list(patches(rung, inside)):
        if rim and not any(block[a, c] for a, c in cells):
            vals, counts = np.unique(rim, return_counts=True)
            for a, c in cells:
                rung[a, c] = vals[np.argmax(counts)]
    return rung


def despeck(rung, inside, keep=(), least=0, only=None):
    """After the rims are drawn: a peak (or pit) with no 2x2 block in it (or under `least`
    cells), every neighbour a rung below (above) it, drops (rises) to them. Keeps the layered
    rule. (Not rungs in keep; with `only`, just that rung.)"""
    while True:
        changed = False
        block = blocks(rung)
        for k, cells, rim in list(patches(rung, inside)):
            small = len(cells) < least or not any(block[a, c] for a, c in cells)
            if k not in keep and (only is None or k == only) and rim and len(set(rim)) == 1 and abs(rim[0] - k) == 1 and small:
                for a, c in cells:
                    rung[a, c] = rim[0]
                changed = True
        if not changed:
            return rung


def settle(rung, inside):
    """Banded tiles to a finished floor: no small patches, the transition rims, no specks."""
    rung = blocky(tidy(rung, inside), inside)
    return despeck(lower(rung, inside), inside)


def check(b, ladder=None):
    """QM's layered rule: no two cells (diagonals too) more than a rung apart, outside the
    free structures; `ladder` maps rungs to their ladder step when two tiles share one."""
    step = np.asarray(ladder)[b.rung] if ladder is not None else b.rung
    big = 10 ** 6
    s = np.where(b.inside & ~b.free, step, big)
    for nb in neighbours(s, big):
        both = (s != big) & (nb != big)
        bad = both & (np.abs(s - nb) > 1)
        assert not bad.any(), "%s: tiles two rungs apart touch at %s" % (b.name, np.argwhere(bad)[:5].tolist())


def specks(b):
    """How many patches have no 2x2 block (the transition rims excepted: rungs with a lower
    and a higher one round them)."""
    block, n = blocks(b.rung), 0
    for k, cells, rim in patches(b.rung, b.inside & ~b.free):
        if not any(block[a, c] for a, c in cells) and not (min(rim, default=k) < k < max(rim, default=k)):
            n += 1
    return n


def seam(b, rows, r):
    """The biome's first and last `rows` rows all rung r (where it meets the last biome and the next)."""
    b.rung[:, :rows] = r
    b.rung[:, -rows:] = r


def along(b, lo, hi):
    """0..1 down the course's width: 0 at its narrowest (lo), 1 at its widest (hi), per cell."""
    return np.broadcast_to(np.clip((b.hw - lo) / (hi - lo), 0, 1), b.rung.shape)


# ---- the biomes ----------------------------------------------------------------------

def rgb(h):
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def pirate_cove():
    """Sand islands in a lagoon: sand a stud up, wet sand, the water tile a stud down, its
    deep middles darker. 7 angles (lacy rings: atolls). More lagoon in the wide bays. Plank
    boardwalks a stud up carry the middle lane over any long stretch of water."""
    b = Biome(0, [
        ("DeepWater", -1, (30, 120, 205), None),  # the water tile's darker tint
        ("Water", -1, (49, 170, 235), None),  # QM's blue tile (rbxassetid://128871935822673)
        ("WetSand", 0, (225, 189, 120), (208, 172, 105)),  # (QM in Studio, Oct 14: stamina-loop d803ac1; was 206, 172, 110 / 194, 160, 98)
        ("Ground", 2, (240, 218, 160), (230, 206, 146)),  # light sand, as the base's: a stud above the damp sand (QM, Oct 14: stamina-loop b7441d8; was 1)
        ("Planks", 1, (150, 100, 60), None),  # boardwalks: plain boards, no checker
        ("DampSand", 1, (233, 204, 140), (219, 189, 126)),  # (QM, Oct 14: stamina-loop 97c9aa0) between the sand and the wet sand, at the sand's height
    ])
    q = b.quasi(7, 13, (517, 233))
    q = q + 0.12 * (0.5 - along(b, 64, 108))  # (wider: more water, the lower q)
    b.band(q, [0.1, 0.32, 0.5])
    b.rung[b.rung == 2] = 3  # (wet sand only as the rim round water, never a patch of its own)
    seam(b, 5, 3)
    b.rung[:, -5:] = 2  # (its far end wet sand at 0, level with the Garden's lawn)
    b.rung = settle(b.rung, b.inside)
    # Boardwalks: the middle four tiles, in a few long runs that span the lagoons: water under
    # the middle lane joined across gaps of under 120 studs, kept if 200 studs or longer, and
    # run on to dry sand at both ends.
    mid = NX // 2
    wet = np.nonzero((b.rung[mid - 2:mid + 2] <= 1).any(axis=0))[0]
    runs = []
    for j in wet:
        if runs and j - runs[-1][1] < 15:
            runs[-1][1] = j
        else:
            runs.append([j, j])
    for a, c in runs:
        if c - a < 25:
            continue
        while a > 6 and (b.rung[mid - 2:mid + 2, a] < 3).any():
            a -= 1
        while c < b.nz - 7 and (b.rung[mid - 2:mid + 2, c] < 3).any():
            c += 1
        b.rung[mid - 2:mid + 2, a:c + 1] = 4
        b.free[mid - 2:mid + 2, a:c + 1] = True
    b.rung = despeck(b.rung, b.inside & ~b.free)  # (water and wet sand cut to slivers beside the boards)
    # Wet sand only by water: a stretch of wet sand touching no water (the rims of pools the
    # boards paved over) goes dry; then sand flecks between pools (no 2x2) go wet.
    keep = b.inside & ~b.free
    for k, cells, rim in list(patches(b.rung, keep)):
        if k == 2:
            near = {b.rung[a + da, c + dc] for a, c in cells for da in (-1, 0, 1) for dc in (-1, 0, 1)
                    if 0 <= a + da < NX and 0 <= c + dc < b.nz and keep[a + da, c + dc]}
            if not near & {0, 1}:
                for a, c in cells:
                    b.rung[a, c] = 3
    b.rung = despeck(b.rung, keep, only=3)
    # Damp sand: every sand cell touching wet sand (diagonals too), so sand never meets it directly.
    wet = np.zeros_like(b.inside)
    for nb in neighbours(np.where(b.inside & ~b.free & (b.rung == 2), 1, 0), 0):
        wet |= nb == 1
    b.rung[(b.rung == 3) & wet & ~b.free] = 5
    check(b, [0, 1, 2, 4, 4, 3])  # (the damp sand a step between the wet sand and the sand)
    walls = dict(wall=[(124, 82, 50), (112, 73, 44)], cap=(240, 218, 160), gate=(255, 160, 40))  # driftwood, sand top, treasure gold
    return b, walls


def garden():
    """Rich soil sunk a stud, dark lawn, bright lawn a stud up, and raised flowerbeds two up
    ringed by the bright lawn. 5 angles (stars: formal beds). A flagstone path winds down
    the course a stud up, bright lawn either side."""
    b = Biome(1, [
        ("Soil", -1, rgb("6E482C"), rgb("624026")),
        ("Ground", 0, rgb("4CAA34"), rgb("449C2E")),  # dark lawn
        ("Grass", 1, rgb("7ED648"), rgb("72C83E")),  # bright lawn
        ("Flowers", 2, rgb("FF82BE"), rgb("F470B0")),  # flowerbeds, a stud above the lawn
        ("Path", 1, rgb("C4BEB0"), rgb("B4AEA0")),  # flagstones, flush with the bright lawn
    ])
    q = b.quasi(5, 10, (311, 977))
    b.band(q, [0.12, 0.55, 0.94])  # (half the flowerbeds: QM's critic, Oct 14)
    seam(b, 5, 1)
    b.rung = settle(b.rung, b.inside)
    # The path: three tiles wide, swinging side to side, never within 24 of the walls.
    path = np.zeros_like(b.inside)
    for j in range(b.nz):
        z = b.z0 - j * CELL
        swing = (b.hw[j] - 36) * math.sin(z / 260.0) * 0.8
        c = int(round((swing + OUT) / CELL - 0.5))
        path[c - 1:c + 2, j] = True
    path[:, :6] = path[:, -6:] = False
    b.rung[path] = 4
    ladder = [0, 1, 2, 3, 3]  # (the path and the beds share the top step: both ringed by bright lawn)
    step = np.asarray(ladder)[b.rung]
    step = raise_(step, b.inside, path | (b.rung == 3))
    b.rung = np.where(path, 4, np.where(b.rung == 3, 3, step))
    b.rung = despeck(b.rung, b.inside & ~path)
    check(b, ladder)
    walls = dict(wall=[rgb("23561F"), rgb("1E4A1B")], cap=rgb("FF78AA"), gate=rgb("FF5CAA"))  # dark hedge (the lawn's green hid the edge), blossom top
    return b, walls, ladder


def candyland():
    """Melted chocolate sunk a stud, deep pink frosting, vanilla cream a stud up, mint plateaus two up.
    8 angles (rosettes). A candy-cane path, red and white bands across it, a stud up all the
    way down the middle, cream either side."""
    b = Biome(2, [
        ("Chocolate", -1, rgb("6E3E28"), rgb("623622")),
        ("Ground", 0, rgb("F0609E"), rgb("E25292")),  # deep pink frosting
        ("Cream", 1, rgb("FFECC8"), rgb("F8E0B8")),  # warm vanilla
        ("Mint", 2, rgb("82ECC4"), rgb("74E0B6")),
        ("Stripe", 1, rgb("F03C50"), rgb("DC3446")),  # the candy cane's red bands
        ("Icing", 1, rgb("FFF5F5"), rgb("F5E8EA")),  # and its white ones
    ])
    q = b.quasi(8, 15, (743, 151))
    b.band(q, [0.16, 0.52, 0.9])  # (fewer, bigger mint plateaus)
    seam(b, 5, 1)
    b.rung = settle(b.rung, b.inside)
    # The candy cane: four tiles wide down the middle the whole way, bands two tiles deep.
    mid = NX // 2
    cane = np.zeros_like(b.inside)
    cane[mid - 2:mid + 2, 6:b.nz - 6] = True
    b.rung[cane] = 4
    stripes = (np.arange(b.nz) // 2) % 2 == 0
    b.rung[cane & stripes[None, :]] = 5
    ladder = [0, 1, 2, 3, 3, 3]
    step = raise_(np.asarray(ladder)[b.rung], b.inside, cane | (b.rung == 3))
    b.rung = np.where(cane | (b.rung == 3), b.rung, step)
    b.rung = despeck(b.rung, b.inside & ~cane, least=16, only=3)  # (mint: a few big plateaus, no small blocks)
    check(b, ladder)
    walls = dict(wall=[rgb("FFAAD2"), rgb("F59BC6")], cap=rgb("FFFFFF"), gate=rgb("8CF0DC"))  # frosting, icing top, mint gate
    return b, walls, ladder


def cnidaria():
    """An underwater reef: deep blue trenches sunk a stud, pale seabed, pink coral a stud up,
    and glowing kelp-green at the reef's peaks two up, ringed by the coral. 9 angles (coral
    rosettes). The reef grows where the course is wide, trenches where it narrows. A calm lane
    of seabed down the middle to ride."""
    b = Biome(3, [
        ("Trench", -1, rgb("1E50D2"), rgb("1A46BC")),  # saturated deep blue
        ("Ground", 0, rgb("ECDEB8"), rgb("E2D2AA")),  # pale seabed sand
        ("Coral", 1, rgb("FF8096"), rgb("F47088")),
        ("Glow", 2, rgb("78FF8C"), rgb("64F078")),  # glowing kelp-green peaks
    ])
    q = b.quasi(9, 16, (229, 661))
    w = along(b, 112, MAXW)
    b.band(q + 0.1 * (w - 0.5), [0.12, 0.55, 0.94])
    lane = np.abs(b.x) < 36  # (the riding lane: plain seabed)
    b.rung[lane] = 1
    seam(b, 5, 1)
    b.rung = settle(b.rung, b.inside)
    b.rung[lane] = 1
    b.rung = despeck(lower(b.rung, b.inside), b.inside)
    b.rung = despeck(b.rung, b.inside, least=24, only=0)  # (no confetti of little trenches)
    check(b)
    walls = dict(wall=[rgb("142044"), rgb("101A3A")], cap=rgb("FF6EBE"), gate=rgb("5AFFC8"))  # dark blue rock (darker than the trenches), coral top
    return b, walls, None


# ---- output ----------------------------------------------------------------------------

def boxes(b):
    """(rung, low x, near z, size x, size z) per part, merged, no part over BLOCK long."""
    key = np.where(b.inside, b.rung, VOID)
    out = []
    rows = BLOCK // CELL
    for j0 in range(0, b.nz, rows):
        for k, i0, a, i1, c in rects(key[:, j0:j0 + rows]):
            if k != VOID:
                out.append((int(k), -OUT + i0 * CELL, b.z0 - (j0 + a) * CELL, (i1 - i0) * CELL, (c - a) * CELL))
    assert all(p[3] <= 2048 and p[4] <= 2048 for p in out)
    return out


def wall_segments():
    """Each side's wall as straight pieces between PROFILE points: (centre x, z, length, yaw)."""
    out = []
    for (z0, h0), (z1, h1) in zip(PROFILE, PROFILE[1:]):
        for sg in (-1, 1):
            # the inner face on the line from (sg h0, z0) to (sg h1, z1); the wall 8 thick behind it
            dx, dz = sg * (h1 - h0), z1 - z0
            length = math.hypot(dx, dz)
            yaw = math.atan2(dx, dz)
            # the outward normal (away from the course's middle)
            ox, oz = dz / length, -dx / length
            if ox * sg < 0:
                ox, oz = -ox, -oz
            cx = sg * (h0 + h1) / 2 + ox * 4
            cz = (z0 + z1) / 2 + oz * 4
            out.append((round(cx, 3), round(cz, 3), round(length + 8, 3), round(yaw, 6), sg))
    return out


def render(b, walls, out, rows=4, s=1):
    """Top-down, the biome cut into `rows` strips side by side (near end at the top left)."""
    seg = int(math.ceil(b.nz / rows))
    w, h = NX * CELL * s, seg * CELL * s
    im = Image.new("RGB", (rows * (w + 24) - 24, h), (255, 255, 255))
    d = ImageDraw.Draw(im)
    shade = {}
    for r in range(rows):
        ox = r * (w + 24)
        for j in range(r * seg, min(b.nz, (r + 1) * seg)):
            for i in range(NX):
                if not b.inside[i, j]:
                    continue
                name, top, col, chk = b.tiles[int(b.rung[i, j])]
                for a in range(2):
                    for c in range(2):
                        colour = col if chk is None or (a + c) % 2 == 0 else chk
                        if name in ("Water", "DeepWater"):
                            colour = col if (a + c + (i + j) % 2) % 2 else tuple(min(255, v + 14) for v in col)
                        if name == "Planks":
                            colour = col if c == 0 else tuple(v - 12 for v in col)
                        x0, y0 = ox + (i * CELL + a * 4) * s, ((j - r * seg) * CELL + c * 4) * s
                        d.rectangle([x0, y0, x0 + 4 * s - 1, y0 + 4 * s - 1], fill=colour)
            # a dark line along every step, on its low side: shows the heights
            for i in range(NX):
                if not b.inside[i, j]:
                    continue
                t = b.tiles[int(b.rung[i, j])][1]
                x0, y0 = ox + i * CELL * s, (j - r * seg) * CELL * s
                if i + 1 < NX and b.inside[i + 1, j] and b.tiles[int(b.rung[i + 1, j])][1] != t:
                    xx = x0 + CELL * s if b.tiles[int(b.rung[i + 1, j])][1] < t else x0 + CELL * s - 1
                    d.line([(xx, y0), (xx, y0 + CELL * s - 1)], fill=(60, 50, 40))
                if j + 1 < min(b.nz, (r + 1) * seg) and b.inside[i, j + 1] and b.tiles[int(b.rung[i, j + 1])][1] != t:
                    yy = y0 + CELL * s if b.tiles[int(b.rung[i, j + 1])][1] < t else y0 + CELL * s - 1
                    d.line([(x0, yy), (x0 + CELL * s - 1, yy)], fill=(60, 50, 40))
        # the walls
        for j in range(r * seg, min(b.nz, (r + 1) * seg)):
            z = b.z0 - j * CELL
            for sg in (-1, 1):
                x0, x1 = sg * half_width(z), sg * half_width(z - CELL)
                y0, y1 = (j - r * seg) * CELL * s, (j + 1 - r * seg) * CELL * s
                d.polygon([(ox + (x0 + OUT) * s, y0), (ox + (x1 + OUT) * s, y1),
                           (ox + (x1 + OUT + sg * 8) * s, y1), (ox + (x0 + OUT + sg * 8) * s, y0)], fill=walls["wall"][0])
                d.line([(ox + (x0 + OUT + sg * 8) * s, y0), (ox + (x1 + OUT + sg * 8) * s, y1)], fill=walls["cap"], width=2)
        d.text((ox + 4, 4), "%s  z %d" % (b.name, b.z0 - r * seg * CELL), fill=(0, 0, 0))
    im.save(out)
    return im


def overview(biomes, out):
    """The whole course, squeezed 8x along z, every biome's floor and walls: the funnel's shape."""
    k = 8
    w = NX * CELL
    h = -END // k
    im = Image.new("RGB", (w + 220, h), (255, 255, 255))
    d = ImageDraw.Draw(im)
    for b, walls in biomes:
        for j in range(0, b.nz):
            y = (-b.z0 + j * CELL) // k
            for i in range(NX):
                if b.inside[i, j]:
                    d.rectangle([i * CELL, y, i * CELL + CELL - 1, y], fill=b.tiles[int(b.rung[i, j])][2])
        for j in range(b.nz):
            z = b.z0 - j * CELL
            y = (-z) // k
            for sg in (-1, 1):
                x = OUT + sg * half_width(z)
                d.rectangle([min(x, x + sg * 8), y, max(x, x + sg * 8), y], fill=walls["wall"][0])
        y0 = -b.z0 // k
        d.line([(0, y0), (w, y0)], fill=walls["gate"], width=3)
        d.text((w + 10, y0 + 6), "%s\n%d studs\nz %d" % (b.name, b.z0 - b.z1, b.z0), fill=(0, 0, 0))
    for z, hw in PROFILE:
        d.text((w + 120, -z // k - 6), "%d" % hw, fill=(120, 120, 120))
    im.save(out)


def write(biomes, ladders):
    base = open(os.path.join(HERE, "world3_floor.luau.in")).read()
    for (b, walls), ladder in zip(biomes, ladders):
        kinds = "\n".join('\t[%d] = { "%s", %d, rgb(%d, %d, %d), %s },' % (
            r, t[0], t[1], *t[2], "rgb(%d, %d, %d)" % t[3] if t[3] else "nil") for r, t in enumerate(b.tiles))
        parts = boxes(b)
        body = (base.replace("--NAME--", b.name).replace("--NEAR--", str(b.z0)).replace("--FAR--", str(b.z1))
                .replace("--KINDS--", kinds)
                .replace("--WALL--", "rgb(%d, %d, %d), rgb(%d, %d, %d), rgb(%d, %d, %d)" % (*walls["wall"][0], *walls["wall"][1], *walls["cap"]))
                .replace("--FLOOR--", "\n".join("\t{ %d, %d, %d, %d, %d }," % p for p in parts)))
        open(os.path.join(HERE, "world3_%s.luau" % b.name.lower()), "w").write(body)
        print(b.name, "specks:", specks(b), "parts:", len(parts), {t[0]: int(((b.rung == r) & b.inside).sum()) for r, t in enumerate(b.tiles)})
    body = open(os.path.join(HERE, "world3_course.luau.in")).read()
    body = body.replace("--END--", str(END)).replace("--WALLS--", "\n".join(
        "\t{ %s, %s, %s, %s }," % p[:4] for p in wall_segments()))
    open(os.path.join(HERE, "world3_course.luau"), "w").write(body)


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else "/mnt/project-files/world3/terrain"
    os.makedirs(out, exist_ok=True)
    assert max(h for _, h in PROFILE) <= MAXW and all(z % CELL == 0 for z, _ in PROFILE)
    made = [pirate_cove(), garden(), candyland(), cnidaria()]
    biomes = [(m[0], m[1]) for m in made]
    ladders = [None] + [m[2] for m in made[1:]]
    for b, walls in biomes:
        render(b, walls, os.path.join(out, "%d_%s.png" % (b.index + 1, b.name)))
    overview(biomes, os.path.join(out, "0_course_overview.png"))
    if os.path.exists(os.path.join(HERE, "world3_floor.luau.in")):
        write(biomes, ladders)


if __name__ == "__main__":
    main()
