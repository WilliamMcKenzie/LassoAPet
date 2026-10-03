"""Godlands concept (QM, Oct 3): the endgame biome past the Ocean, where boss events
spawn. Terrain after Realm of the Mad God's godlands: grey snow broken up by dark
stone, dead bushes and trees, and pools of lava ringed with black rock.

Run: python3 tools/godlands_concept.py [out_dir]
     python3 tools/godlands_concept.py --map    also write the game's Godlands: its
         track grids (src/server/GodlandsTracks.luau), walls and terrain pieces
Writes godlands_map.png (480 tiles of ground from above), godlands_ground.png (a
stretch of it from the riding camera and up close) and godlands_assets.png (each
terrain piece beside a 5-stud figure) to /mnt/project-files/biomes/godlands/.

Ground: the "glaciers" biome of QM's MapMaker (server/mapgen.go), ported tile for
tile onto the 4-stud checker (QM, Oct 3):
  Stone  dark plates, a stud up: whole big cells near each core, split by snow
  Snow   the lines between cells and the specks in them, at 0
  Ice    pale blue cracks and streams further out, a stud down (A), or
  Lava   the same tiles as lava, a stud down, glowing (Neon) (B)
Cells further from a core turn to ice patterns and finally plain snow; a new core
comes every CORE_EVERY tiles so the course never runs out of stone.
The columns along the walls, the start and the nests stay snow.

Terrain pieces (studded blocks, no 2D planes; lava parts are plain so they glow):
  small   DeadBush    bare grey twigs out of a snow tuft
  small   DarkStone   a tilted black chunk with snow on its top
  medium  DeadTree    a bare twisted trunk forking into crooked branches
  medium  Crag        dark slabs leaning together under snow
  large   LavaRock    a black boulder split by glowing lava seams, a lava pool at its foot
"""

import os
import sys

import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(__file__))
import partlib  # noqa: E402
from partlib import Part, T, Ry, render  # noqa: E402
from desert_ground import HALF_W  # noqa: E402
import terrain_assets as TA  # noqa: E402
from terrain_assets import rot  # noqa: E402

SNOW = [(208, 212, 224), (224, 228, 238)]  # grey snow, a shade under the Snow biome's
STONE = [(62, 60, 72), (76, 74, 88)]  # dark stone
LAVA = [(255, 72, 0), (255, 120, 10)]  # the Ocean abyss's lava
WALL = [(48, 46, 58), (62, 60, 74)]
WALL_CAP = (236, 240, 246)
STONE_UP, LAVA_DOWN = 1, 1
LENGTH = 200  # studs shown in the preview
NESTS = [(16, -150)]
NEST_CLEAR = 14
START_CLEAR = 16

# terrain colours
ROCK, ROCK_L, ROCK_D = (58, 56, 68), (80, 78, 92), (40, 38, 48)
TWIG, TWIG_D = (112, 100, 96), (86, 76, 74)  # dead grey-brown wood
SNOW_W = (238, 241, 247)
GLOW = (255, 72, 0)


TILE = 4  # the plates and cracks are drawn on the 4-stud checker, finer than the other biomes' 8
ICE = [(170, 196, 250), (184, 208, 252)]  # frozen streams, QM's reference's pale blue
ICE_DOWN = 1


# The glaciers biome of QM's MapMaker (server/mapgen.go, on studio-imperium/atlas),
# ported to the course strip. Atlas splits the world into big Voronoi cells, spreads
# a list of biomes out from a starting cell one ring of neighbours at a time (the
# index climbs by `decay` a ring), and each cell then runs its biome's modifiers.
FLOOR_V, SNOW_V, ICE_V = 1, 0, 3  # atlas tile values as our kinds: dark stone, snow, ice
GLACIERS = [
    [("voronoi", 40, [FLOOR_V] * 4 + [SNOW_V]), ("sel", FLOOR_V, SNOW_V), ("border", FLOOR_V)],
    [("voronoi", 40, [FLOOR_V] * 7 + [SNOW_V]), ("sel", FLOOR_V, SNOW_V), ("border", SNOW_V)],
    [("voronoi", 40, [FLOOR_V] * 3 + [SNOW_V, ICE_V]), ("sel", FLOOR_V, SNOW_V), ("sel", SNOW_V, ICE_V),
     ("border", SNOW_V)],
    [("pattern", 27, [FLOOR_V, SNOW_V]), ("sel", SNOW_V, ICE_V), ("sel", FLOOR_V, FLOOR_V), ("border", ICE_V),
     ("ext", SNOW_V, ICE_V)],
    [("pattern", 27, [ICE_V, SNOW_V]), ("sel", SNOW_V, ICE_V)],
    [("fill", SNOW_V)],
]
DECAY = 0.5
CELL_AREA = 134  # tiles per big cell (MapMaker: ~110 tiles square, ~90 cells)
CORE_EVERY = 170  # tiles between the dark stone cores the biomes spread from (one map has one)
MAP_LEN = 480  # tiles in the top-down map (1920 studs)


def quasicrystal(x, y, angles, values):
    """Atlas's NewPattern: a sum of cosine waves at `angles` angles over the tile coords."""
    a = 2.0 * 3.14156
    delta = a / angles
    v = np.zeros_like(x, dtype=float)
    i = 0
    while i < angles:
        v += np.cos(np.cos(a) * x + np.sin(a) * y)
        a -= delta
        i += 1
    t = ((v / angles) + 1) / 2 * len(values)
    idx = np.maximum(0, np.floor(t)).astype(int) % len(values)
    return np.array(values)[idx]


def _neighbours(a, fill):
    """The four neighbours of every tile (left, right, up, down), `fill` off the grid."""
    p = np.pad(a, 1, constant_values=fill)
    return [p[:-2, 1:-1], p[2:, 1:-1], p[1:-1, :-2], p[1:-1, 2:]]


def glaciers(nx, nz, seed=7):
    """Kind per tile (0 snow, 1 stone, 3 ice) for a strip nx wide, nz long."""
    rng = np.random.default_rng(seed)
    n = max(2, round(nx * nz / CELL_AREA))
    pts = np.column_stack([rng.uniform(0, nx, n), rng.uniform(0, nz, n)])
    ii, jj = np.meshgrid(np.arange(nx, dtype=float), np.arange(nz, dtype=float), indexing="ij")
    owner = np.argmin((ii[..., None] - pts[:, 0]) ** 2 + (jj[..., None] - pts[:, 1]) ** 2, axis=-1)
    # neighbouring cells: any two whose tiles touch
    adj = [set() for _ in range(n)]
    for a, b in ((owner[1:, :], owner[:-1, :]), (owner[:, 1:], owner[:, :-1])):
        for u, v in set(zip(a[a != b].tolist(), b[a != b].tolist())):
            adj[u].add(v)
            adj[v].add(u)
    # rings out from the cores (the nearest core wins, so the dark stone comes back every so often)
    cores = {int(owner[int(rng.uniform(0.3, 0.7) * nx), min(nz - 1, int(z))])
             for z in np.arange(rng.uniform(0.15, 0.5) * CORE_EVERY, nz, CORE_EVERY)}
    ring = {c: 0 for c in cores}
    frontier = list(cores)
    while frontier:
        nxt = []
        for c in frontier:
            for d in adj[c]:
                if d not in ring:
                    ring[d] = ring[c] + 1
                    nxt.append(d)
        frontier = nxt
    val = np.zeros((nx, nz), dtype=int)
    for c in range(n):
        biome = min(int(np.floor(DECAY * (ring.get(c, 99) + 1))), len(GLACIERS) - 1)
        mask = owner == c
        for mod in GLACIERS[biome]:
            if mod[0] == "fill":
                val[mask] = mod[1]
            elif mod[0] == "pattern":
                val[mask] = quasicrystal(ii[mask], jj[mask], mod[1], mod[2])
            elif mod[0] == "voronoi":
                # `density` origins picked from the cell's tiles; each tile takes its nearest origin's value
                tiles = np.argwhere(mask)
                r = np.random.default_rng(mod[1] + c)
                o = tiles[r.integers(0, len(tiles), mod[1])]
                near = np.argmin(((tiles[:, None, :] - o[None]) ** 2).sum(-1), axis=1)
                vals = np.array(mod[2])[(o[near, 0] + o[near, 1]) % len(mod[2])]
                val[tiles[:, 0], tiles[:, 1]] = vals
            else:
                inn = _neighbours(mask, False)
                nv = _neighbours(val, -1)
                if mod[0] == "border":  # tiles on the cell's edge
                    hit = mask & ~np.logical_and.reduce(inn)
                    val[hit] = mod[1]
                elif mod[0] == "sel":  # `around` tiles touching anything else become `border`
                    border, around = mod[1], mod[2]
                    edge = np.logical_or.reduce([~m | (v != around) for m, v in zip(inn, nv)])
                    val[mask & (val == around) & edge] = border
                elif mod[0] == "ext":  # tiles touching an `around` tile become `border`
                    border, around = mod[1], mod[2]
                    touch = np.logical_or.reduce([m & (v == around) for m, v in zip(inn, nv)])
                    val[mask & (val != around) & touch] = border
    return val


def layout(nz, seed=7, streams="ice", z0=0, clear=True):
    """Kind per 4-stud tile (0 snow, 1 stone, 2 lava, 3 ice): the glaciers map, with
    its ice as lava for variant B. `z0` slides the window along a longer map."""
    nx = 2 * HALF_W // TILE
    kind = glaciers(nx, MAP_LEN, seed)[:, z0:z0 + nz].copy()
    if streams == "lava":
        kind[kind == ICE_V] = 2
    for col in (0, -1):
        kind[col, :] = 0
    if clear:
        kind[:, : START_CLEAR // TILE] = 0
        for i in range(nx):
            for j in range(nz):
                x, z = -HALF_W + i * TILE + TILE / 2, -j * TILE - TILE / 2
                if any(abs(x - p) < NEST_CLEAR + TILE / 2 and abs(z - q) < NEST_CLEAR + TILE / 2 for p, q in NESTS):
                    kind[i, j] = 0
    return kind


# ---------------------------------------------------------------- terrain pieces

def snow_tuft(k, x, z, w, d, yaw=0):
    k.at("Snow", (x, 0.35, z), (w, 0.7, d), SNOW_W, rot(yaw, 0, 0))


def dead_bush(k):
    """Small: bare grey twigs fanning out of a snow tuft."""
    snow_tuft(k, 0, 0, 3.6, 3.0, 15)
    k.box("Twig", (-0.3, 0.4, -0.3), (0.3, 1.6, 0.3), TWIG_D)
    for yaw, lean, h, c in ((0, 38, 2.6, TWIG), (110, 42, 2.3, TWIG_D), (230, 34, 2.8, TWIG),
                            (60, 60, 1.8, TWIG_D), (170, 58, 1.9, TWIG), (300, 50, 2.0, TWIG_D)):
        R = Ry(yaw) @ partlib.Rz(lean)
        centre = np.array([0, 1.3, 0]) + (R @ np.array([0, h / 2, 0, 0]))[:3]
        k.at("Twig", centre, (0.32, h, 0.32), c, R)
        # a short fork near each tip
        tip = np.array([0, 1.3, 0]) + (R @ np.array([0, h * 0.8, 0, 0]))[:3]
        R2 = Ry(yaw + 40) @ partlib.Rz(lean - 35)
        k.at("Twig", tip + (R2 @ np.array([0, 0.45, 0, 0]))[:3], (0.24, 0.9, 0.24), c, R2)


def dark_stone(k):
    """Small: a tilted black chunk with a snow cap and a chip at its foot."""
    k.at("Rock", (0, 1.3, 0), (4.4, 2.8, 3.8), ROCK, rot(20, 6, -8))
    k.at("Rock", (0.1, 2.9, 0), (3.2, 0.6, 2.8), SNOW_W, rot(24, 6, -9))
    k.at("Rock", (2.4, 0.5, 1.4), (1.6, 1.0, 1.4), ROCK_D, rot(-30, 0, 10))


def dead_tree(k):
    """Medium: a bare, crooked trunk forking into twisted branches, snow at its foot."""
    snow_tuft(k, 0, 0, 5.0, 4.2, 10)
    segs = [((0, 0, 0), (1.5, 3.4, 1.5), (0, 0, 4)), ((0.25, 3.2, 0), (1.2, 2.8, 1.2), (0, 0, -10)),
            ((-0.2, 5.8, 0.1), (1.0, 2.2, 1.0), (0, 8, 8))]
    for (x, y, z), size, (tx, ty, tz) in segs:
        k.at("Tree", (x, y + size[1] / 2, z), size, TWIG_D, rot(ty, tx, tz))
    # branches: (start height, yaw, lean, length, thickness), each with a crooked tip
    for y0, yaw, lean, h, w in ((4.0, 20, 52, 3.4, 0.7), (5.4, 160, 48, 3.0, 0.6), (6.6, 280, 40, 2.8, 0.55),
                                (7.6, 90, 25, 2.4, 0.5), (3.2, 230, 65, 2.2, 0.5)):
        R = Ry(yaw) @ partlib.Rz(lean)
        base = np.array([0, y0, 0])
        k.at("Tree", base + (R @ np.array([0, h / 2, 0, 0]))[:3], (w, h, w), TWIG, R)
        R2 = Ry(yaw - 30) @ partlib.Rz(lean - 40)
        tip = base + (R @ np.array([0, h, 0, 0]))[:3]
        k.at("Tree", tip + (R2 @ np.array([0, 0.6, 0, 0]))[:3], (w * 0.7, 1.4, w * 0.7), TWIG_D, R2)


def crag(k):
    """Medium: two dark slabs leaning together under snow, a chunk at the foot."""
    k.at("Rock", (-1.4, 3.0, 0.2), (6.0, 6.4, 5.2), ROCK, rot(14, 6, -12))
    k.at("Rock", (2.0, 2.2, -0.4), (5.0, 4.6, 4.6), ROCK_L, rot(-22, -6, 14))
    k.at("Rock", (-1.8, 6.2, 0.1), (4.4, 0.8, 3.8), SNOW_W, rot(18, 6, -13))
    k.at("Rock", (2.4, 4.6, -0.4), (3.4, 0.7, 3.4), SNOW_W, rot(-18, -6, 14))
    k.at("Rock", (-4.6, 0.7, -2.2), (2.4, 1.6, 2.0), ROCK_D, rot(35, 0, -6))
    snow_tuft(k, 1.0, -3.0, 5.0, 2.0, -8)


def lava_rock(k):
    """Large: a black boulder split by glowing lava seams, a lava pool lapping its foot."""
    k.at("Rock", (-1.0, 4.4, 0.4), (10.0, 9.0, 9.0), ROCK, rot(16, 7, -9))
    k.at("Rock", (4.4, 3.0, 1.2), (6.6, 6.0, 6.2), ROCK_D, rot(-26, -7, 13))
    k.at("Rock", (-1.4, 9.0, 0.3), (7.0, 1.0, 6.0), ROCK_L, rot(20, 7, -10))
    k.at("Rock", (-1.6, 9.7, 0.3), (4.6, 0.7, 3.8), SNOW_W, rot(26, 6, -10))
    # the seams: thin glowing bars proud of the faces
    for c, size, r in (((-1.0, 4.6, -4.25), (0.5, 7.0, 0.3), rot(16, 7, -6)),
                       ((-3.0, 5.6, -3.6), (3.6, 0.45, 0.3), rot(16, 7, 18)),
                       ((4.0, 3.2, -1.95), (0.45, 4.6, 0.3), rot(-26, -7, 8)),
                       ((-6.05, 3.6, 0.6), (0.3, 5.0, 0.45), rot(16, 7, -9))):
        k.at("Lava", c, size, GLOW, r, plain=True)
    k.at("Lava", (2.0, 0.08, -5.4), (8.0, 0.16, 3.4), GLOW, rot(8, 0, 0), plain=True)
    k.at("Rock", (2.2, 0.35, -7.4), (9.0, 0.7, 1.2), ROCK_D, rot(8, 0, 0))
    k.at("Rock", (-6.0, 0.9, -3.6), (3.0, 2.0, 2.6), ROCK_D, rot(30, 0, -8))


ASSETS = [
    ("Godlands", SNOW, [
        ("Dead bush (small)", dead_bush, 6), ("Dark stone (small)", dark_stone, 6),
        ("Dead tree (medium)", dead_tree, 9), ("Crag (medium)", crag, 11),
        ("Lava rock (large)", lava_rock, 18)]),
]

# terrain for the preview: (builder, x, z, yaw), hugging the walls like the other biomes
PREVIEW = [
    (crag, -44, -40, 20), (dead_bush, -36, -30, 0), (dead_tree, 46, -56, 10), (dark_stone, 38, -46, 40),
    (lava_rock, -42, -96, -10), (dead_bush, 42, -110, 60), (dark_stone, 48, -124, 0),
    (dead_tree, -46, -146, 70), (crag, 44, -176, -20), (dead_bush, -38, -170, 30), (dark_stone, -48, -186, 0),
]


def scene(kind):
    parts = []
    nx, nz = kind.shape
    for i in range(nx):
        for j in range(nz):
            k = kind[i, j]
            top = (0, STONE_UP, -LAVA_DOWN, -ICE_DOWN)[k]
            x, z = -HALF_W + i * TILE + 2, -j * TILE - 2
            c = (SNOW, STONE, LAVA, ICE)[k][(i + j) % 2]
            p = Part("Lava" if k == 2 else "Floor", (4, top + 2, 4), T(x, (top - 2) / 2, z), c, plain=k == 2)
            p.neon = k == 2
            parts.append(p)
    for side in (-1, 1):
        for zi in range(LENGTH // 4):
            for yi in range(5):
                c = WALL_CAP if yi == 4 else WALL[(zi + yi) % 2]
                parts.append(Part("Wall", (4, 4, 4), T(side * (HALF_W + 2), yi * 4 + 2, -zi * 4 - 2), c, plain=True))
    for builder, x, z, yaw in PREVIEW:
        k = TA.Kit()
        builder(k)
        M = T(x, 0, z) @ Ry(yaw)
        for p in k.parts:
            q = Part(p.name, p.size, M @ p.cf, p.color, p.shape, p.plain)
            q.neon = p.name == "Lava"
            parts.append(q)
    return parts


# ---------------------------------------------------------------- the game's map
# The Godlands floor in the game is four tracks, each TRACK tiles (960 studs) of
# the map above: its two halves with ice, and the same two with the ice as lava
# (QM, Oct 3: "use all 4 tracks and randomly choose"). They're built when the
# server starts (Server/GodlandsGround), in a random order, from the grids this
# writes into Server/GodlandsTracks.luau. The walls and the terrain pieces are
# saved in World.rbxmx as usual.
Z_START = -16192  # the Ocean's far edge
TRACK = 240  # tiles per track
SLOTS = 4  # tracks end to end: Config.Biomes Godlands.Length = SLOTS x 960
END = Z_START - TRACK * TILE * SLOTS
TRACKS_LUAU = os.path.join(os.path.dirname(__file__), "..", "src", "server", "GodlandsTracks.luau")
GLYPH = {SNOW_V: ".", FLOOR_V: "#", ICE_V: "~"}


def tracks(seed=7):
    """The map cut into its tracks, each [x tile, z tile] along the course. The
    columns by the walls stay snow, and so do each track's first and last rows, so
    any two tracks meet along a snow line."""
    nx = 2 * HALF_W // TILE
    kind = glaciers(nx, MAP_LEN, seed)
    out = []
    for t in range(MAP_LEN // TRACK):
        g = kind[:, t * TRACK:(t + 1) * TRACK].copy()
        g[0, :] = g[-1, :] = g[:, 0] = g[:, -1] = SNOW_V
        out.append(g)
    return out


def write_tracks():
    grids = tracks()
    out = ["-- The Godlands floor: written by tools/godlands_concept.py --map (don't edit by hand).",
           "-- Server/GodlandsGround lays Tracks end to end in a random order when the server",
           "-- starts. Each grid row is one 4-stud row of tiles across the course (x = -56 to 56),",
           "-- the first row at the track's near end: \".\" snow (the floor), \"#\" dark stone a stud",
           "-- up, \"~\" the track's Liquid (ice, or glowing lava), flush with the snow.",
           "return {",
           f"\tTile = {TILE},",
           f"\tLength = {TRACK * TILE}, -- studs per track",
           "\tTracks = {"]
    for liquid in ("Ice", "Lava"):
        for g in range(len(grids)):
            out.append(f'\t\t{{ Grid = {g + 1}, Liquid = "{liquid}" }},')
    out += ["\t},", "\tGrids = {"]
    for g in grids:
        out.append("\t\t{")
        for j in range(g.shape[1]):
            out.append('\t\t\t"' + "".join(GLYPH[int(v)] for v in g[:, j]) + '",')
        out.append("\t\t},")
    out += ["\t},", "}", ""]
    with open(TRACKS_LUAU, "w") as f:
        f.write("\n".join(out))
    return len(grids)


def write_walls():
    """Side walls and caps for the Godlands (copies of the desert's, one per track
    per side; WorldColors paints them), and the far wall moved to the new end."""
    import re
    from desert_ground import WORLD, item_span
    import ocean_walls as OW
    s = open(WORLD).read()
    while True:  # take out the ones a previous run wrote
        m = re.search(r'\n?<Item class="Part" referent="GWAL\d+"', s)
        if not m:
            break
        st = m.start() + (1 if s[m.start()] == "\n" else 0)
        s = s[:m.start()] + s[item_span(s, st):]
    new, n = [], 0
    seg = TRACK * TILE
    for sx in (-1, 1):
        wall = s[slice(*OW.item(s, OW.WALL[sx]))]
        cap = s[slice(*OW.item(s, OW.CAP[sx]))]
        for k in range(SLOTS):
            zc = Z_START - seg * k - seg / 2
            for tmpl, size, pos in ((wall, (8, 48, seg), (sx * 60, 24, zc)),
                                    (cap, (10, 2, seg - 1), (sx * 59, 49, zc + 0.5))):
                def ref(m):
                    nonlocal n
                    n += 1
                    return f'referent="GWAL{n:05d}"'
                new.append(OW.resize(re.sub(r'referent="[A-Za-z0-9]+"', ref, tmpl), size, pos))
    for ref_, y, dz in ((OW.FAR_WALL, 24, -4), (OW.FAR_CAP, 49, -3)):
        a, b = OW.item(s, ref_)
        xml = s[a:b]
        size = re.search(r'<Vector3 name="size"><X>([^<]*)</X><Y>([^<]*)</Y><Z>([^<]*)</Z>', xml).groups()
        s = s[:a] + OW.resize(xml, tuple(float(v) for v in size), (0, y, END + dz)) + s[b:]
    a, b = OW.item(s, OW.WALL[1])
    s = s[:b] + "\n" + "\n".join(new) + s[b:]
    open(WORLD, "w").write(s)
    return len(new)


def write_obstacles():
    """The Godlands' terrain pieces (tools/course_layout.py lays them out like the
    other biomes', in clusters against the walls) into World.Obstacles, replacing any
    a previous run wrote. They're saved on flat floor: GodlandsGround lifts the ones
    that land on a stone tile once it has laid the tracks."""
    import re
    import course_layout as CL
    from desert_ground import WORLD, item_span
    items = [it for it in CL.Course().build() if it["biome"] == "Godlands"]
    models, parts = CL.obstacle_models(items, prefix="GOBS")
    s = open(WORLD).read()
    while True:
        m = re.search(r'\n?<Item class="Model" referent="GOBS\d+"', s)
        if not m:
            break
        st = m.start() + (1 if s[m.start()] == "\n" else 0)
        s = s[:m.start()] + s[item_span(s, st):]
    i = s.index('<string name="Name">Obstacles</string>')
    st = s.rindex("<Item", 0, i)
    en = item_span(s, st)  # just past the folder's </Item>
    close = en - len("</Item>")
    s = s[:close].rstrip("\n") + "\n" + "\n".join(models) + "\n" + s[close:]
    open(WORLD, "w").write(s)
    return len(models), parts


WINDOW = 120  # where along the map the 3D views sit (tiles)


def top_down(kinds, px=5, per_row=240):
    """The whole map from above, like MapMaker's viewer: each variant in rows of
    `per_row` tiles, start on the left, the course running right."""
    nx = kinds[0][1].shape[0]
    rows = MAP_LEN // per_row
    band = nx * px
    im = Image.new("RGB", (per_row * px + 20, len(kinds) * (40 + rows * (band + 10))), (24, 24, 30))
    d = ImageDraw.Draw(im)
    y = 0
    for label, kind in kinds:
        d.text((10, y + 8), label, fill=(255, 255, 255), font=TA.font(20))
        y += 40
        rgb = np.zeros(kind.shape + (3,), np.uint8)
        chk = (np.add.outer(np.arange(kind.shape[0]), np.arange(kind.shape[1])) % 2).astype(bool)
        for k, cols in enumerate((SNOW, STONE, LAVA, ICE)):
            rgb[(kind == k) & ~chk] = cols[0]
            rgb[(kind == k) & chk] = cols[1]
        strip = Image.fromarray(rgb.transpose(1, 0, 2)[:, ::-1].transpose(1, 0, 2))  # x across, z along
        for r in range(rows):
            part = strip.crop((r * per_row, 0, (r + 1) * per_row, nx)).resize((per_row * px, band), Image.NEAREST)
            im.paste(part, (10, y))
            if WINDOW >= r * per_row and WINDOW < (r + 1) * per_row:  # mark the stretch the 3D views show
                x0 = 10 + (WINDOW - r * per_row) * px
                d.rectangle((x0, y, x0 + LENGTH // TILE * px, y + band - 1), outline=(255, 214, 10), width=2)
            y += band + 10
    return im


def main(out):
    os.makedirs(out, exist_ok=True)
    kw = dict(W=800, H=560, fog=False, ground=False, outline=False)
    board = Image.new("RGB", (1600, 1120))
    d = ImageDraw.Draw(board)
    maps = []
    for r, (streams, label) in enumerate((("ice", "A  glaciers as MapMaker makes them: ice"),
                                          ("lava", "B  the same, its ice turned to lava"))):
        maps.append((label, layout(MAP_LEN, streams=streams, clear=False)))
        kind = layout(LENGTH // TILE, streams=streams, z0=WINDOW)
        parts = scene(kind)
        board.paste(render(parts, eye=(0, 70, 30), target=(0, 0, -70), fov=50, **kw), (0, r * 560))
        board.paste(render(parts, eye=(-8, 16, -60), target=(-30, 2, -100), fov=50, **kw), (800, r * 560))
        d.text((10, r * 560 + 10), label, fill=(255, 255, 255), font=TA.font(22), stroke_width=2, stroke_fill=(0, 0, 0))
        print(streams, {n: int((maps[-1][1] == k).sum()) for k, n in enumerate(("snow", "stone", "lava", "ice"))})
    board.save(os.path.join(out, "godlands_ground.png"))
    top_down(maps).save(os.path.join(out, "godlands_map.png"))

    rows = [TA.row_image(*row) for row in ASSETS]
    rows[0].save(os.path.join(out, "godlands_assets.png"))
    print("wrote", out)
    if "--map" in sys.argv:
        print("wrote", write_tracks(), "track grids into", TRACKS_LUAU)
        print("wrote", write_walls(), "wall parts")
        print("wrote %d terrain pieces (%d parts) into World.Obstacles" % write_obstacles())


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    main(args[0] if args else "/mnt/project-files/biomes/godlands")
