"""World 2's props (QM, Oct 13): the Rock mesh thread's sets in each biome, World 1 style:
clusters hugging the walls, the middle of the course clear.

Run: python3 tools/world2_props.py [out_dir] [--meshes DIR]
     writes tools/world2_props.luau and renders an overhead of each biome and a rider's
     view (the rider's view needs the meshes' pieces, design/<set>/pieces from branch
     claude/rock-meshes-ggc7md: DIR holds design/).

- Meadow: the base's pines (3x, as the base's), a big one against a wall now and then,
  a small one by it.
- Crimson Lands: mushrooms, or runestones on stone or every fourth cluster.
- Crystal Cavern: XXL crystal clusters alternating with fungus groves, off the planks.
- Woodland Maze: autumn birches, thick along both walls; the sword in the stone three times.
- Temple: little trees and stone lanterns in a row down the side dirt, the same each side
  (QM: very purposefully); tombstones and temple stones now and then; lily pads on the ponds.
- Ancient Tomb: an avenue of warrior and sword statues facing the course, standing
  sarcophagi and gold between them, a sphinx either side before each dais.

Big and middle pieces are Obstacles (smashed when ridden into, with an invisible Base
footprint and a Tier); small ones are walk-through Decor. Every piece stands on the tile
height under it. The Luau clones each piece from ServerStorage.World2Assets.<Name>: a
Model of the coloured MeshParts, at the mesh's own size (1x), pivot at its base's middle.
"""

import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(__file__))
from funnel_grid import half_width, map_x  # noqa: E402
import world2_base as base  # noqa: E402
import world2_meadow_ground as meadow  # noqa: E402
import world2_crimson as crimson  # noqa: E402
import world2_cavern as cavern  # noqa: E402
import world2_woodland as woodland  # noqa: E402
import world2_temple as temple  # noqa: E402
import world2_tomb as tomb  # noqa: E402

HERE = os.path.dirname(__file__)
SCALE = 2  # (World 1's lobby plants are 2x to 4x their meshes)
REACH = 28  # studs from the wall a cluster may reach
OFFSET = 1000
# name: (half footprint at 1x (x, z), tier or None for walk-through decor[, scale, base])
# scale: if not SCALE; base: the hit box's share of the footprint (a tree's trunk, not its crown)
PIECES = {
    "MushroomGiant": ((3, 3), 3), "MushroomMedium": ((2, 2), 2), "MushroomSmall": ((1, 1), None),
    "CrimsonTuft": ((1.4, 1.4), None), "RunestoneTall": ((2.4, 1.6), 2), "RunestoneShort": ((2.2, 1.6), 1),
    "RuneBlock": ((4.4, 2.3), 1),
    "CrystalCyanXXL": ((8, 8), 3), "CrystalPinkXXL": ((8, 8), 3), "CrystalCyanLarge": ((4.4, 4.4), 2),
    "CrystalPinkLarge": ((4.4, 4.4), 2), "CrystalCyanMedium": ((2.5, 2.5), None), "CrystalPinkMedium": ((2.5, 2.5), None),
    "FungusLarge": ((3, 3), 2), "FungusMedium": ((2, 2), 1), "FungusCluster": ((2.5, 2), None),
    # the base's pines, 3x as there
    "PineTall": ((5.5, 5.5), 3, 3, 0.4), "Pine": ((5.6, 5), 3, 3, 0.4), "PineSmall": ((4.3, 3.7), 2, 3, 0.4),
    # the woodland's
    "BirchTall": ((4.5, 4.5), 3, 2, 0.4), "BirchTwin": ((6, 6), 3, 2, 0.4), "BirchLean": ((4.5, 4), 2, 2, 0.4),
    "BirchSmall": ((3, 3.3), 2, 2, 0.4), "SwordStone": ((5.6, 4.8), 3),
    # the temple's
    "TempleTree": ((2.2, 2.2), 2, 2, 0.6), "TempleTreeSmall": ((2.1, 2.7), 1, 2, 0.6), "StoneLantern": ((2.9, 2.9), 2),
    "TempleStone": ((4.2, 3.6), 2), "TempleStoneTwin": ((4.2, 2.5), 2), "TombTall": ((2.5, 1.3), 1),
    "TombShort": ((2.4, 1.3), 1), "TombLean": ((2, 0.7), None),
    "LilyPad": ((3.5, 3.5), None, 1), "LilyPads": ((4.4, 3.2), None, 1), "LilyFlower": ((3.5, 3.4), None, 1),
    # the tomb's
    "WarriorStatue": ((3.2, 2.9), 3), "SwordStatue": ((3.3, 2.4), 3), "SarcophagusStanding": ((1.6, 1.5), 2),
    "Sarcophagus": ((4.7, 1.6), 1), "Sphinx": ((4.9, 9.2), 3), "GoldStack": ((6.5, 4.1), 2),
    "GoldBar": ((4, 2), None), "Trophy": ((3.9, 2.7), 1),
}
COLOURS = {}  # piece colours for the renders, read from the pieces' colours.txt
SETS = ("crimson", "crystals", "pines", "birches", "sword_stone", "temple", "tomb")
WALLS = {  # the renders' wall colour
    "Meadow": (236, 232, 224), "Crimson": (91, 50, 54), "Cavern": (56, 72, 103),
    "Woodland": (78, 44, 28), "Temple": (200, 200, 200), "Tomb": (211, 183, 66),
}


def scale_of(name):
    return PIECES[name][2] if len(PIECES[name]) > 2 else SCALE


def radius(name):
    hx, hz = PIECES[name][0]
    return max(hx, hz) * scale_of(name)


class Biome:
    def __init__(self, mod, name, seed):
        self.mod, self.name, self.seed = mod, name, seed
        got = mod.layout()
        self.kind, self.extra = (got if isinstance(got, tuple) else (got, None))
        if mod is meadow:
            self.Z0, self.Z1, tops, self.COLOURS = 0, -meadow.LENGTH, {base.BRIGHT: 1, base.DIRT: -1}, base.COLOURS  # (the light grass a stud up: QM, tools/world2_grass_step.luau)
        else:
            self.Z0, self.Z1, tops, self.COLOURS = mod.Z0, mod.Z1, mod.TOPS, mod.COLOURS
        self.top = np.vectorize(lambda k: tops.get(int(k), 0))(self.kind)
        self.CELL, self.OUT, self.NX, self.NZ, self.VOID = mod.CELL, mod.OUT, mod.NX, mod.NZ, mod.VOID

    def cell(self, x, z):
        i, j = int((x + self.OUT) // self.CELL), int((self.Z0 - z) // self.CELL)
        if 0 <= i < self.NX and 0 <= j < self.NZ:
            return int(self.kind[i, j]), int(self.top[i, j])
        return self.VOID, 0


def layout(b):
    m = b.mod
    rng = np.random.default_rng(b.seed)
    out = []  # (name, x, z, yaw, y, scale)

    def fits(name, x, z, reach=REACH):
        r = radius(name)
        if abs(x) > half_width(z) - r * 0.6 or abs(x) < half_width(z) - reach:
            return False
        if z > b.Z0 - 12 or z < b.Z1 + 12:
            return False
        k, _ = b.cell(x, z)
        if k == b.VOID or (m is cavern and k == cavern.PLANKS) or (m is temple and k in (temple.WATER, temple.DEEP)):
            return False
        return all(math.hypot(x - a, z - c) > (r + radius(n2)) * 0.8 for n2, a, c, *_ in out)

    def put(name, x, z, yaw=None, reach=REACH):
        if fits(name, x, z, reach):
            yaw = float(rng.uniform(0, 360)) if yaw is None else yaw + float(rng.uniform(-6, 6))
            out.append((name, x, z, yaw, b.cell(x, z)[1], scale_of(name)))
            return True
        return False

    def scatter(name, cx, cz, side, n, spread):
        done = 0
        for _ in range(n * 12):
            if done >= n:
                break
            x = cx - side * rng.uniform(0, spread)
            z = cz + rng.uniform(-spread, spread)
            done += put(name, x, z)

    def facing(s):
        return 90.0 * s  # (a piece's front, -Z, turned to the course's middle)

    if m is temple:
        return temple_props(b, rng, out, put, scatter, facing)
    if m is tomb:
        return tomb_props(b, rng, out, put, scatter, facing)

    z = b.Z0 - rng.uniform(30, 60)
    side = 1 if rng.random() < 0.5 else -1
    count = 0
    swords = [b.Z0 - f * (b.Z0 - b.Z1) for f in (0.25, 0.55, 0.85)]
    while z > b.Z1 + 30:
        both = 0.6 if m is woodland else 0.25
        sides = [side, -side] if rng.random() < both else [side]
        for s in sides:
            wall = s * half_width(z)
            cx = wall - s * 10
            if m is crimson:
                on_stone = b.cell(cx, z)[0] == crimson.STONE
                if on_stone or count % 4 == 3:
                    put("RunestoneTall", cx, z)
                    scatter(rng.choice(["RunestoneShort", "RuneBlock"]), cx, z, s, 1, 16)
                    scatter("CrimsonTuft", cx, z, s, int(rng.integers(2, 5)), 18)
                else:
                    put("MushroomGiant", cx, z)
                    scatter("MushroomMedium", cx, z, s, 1, 16)
                    scatter("MushroomSmall", cx, z, s, int(rng.integers(2, 5)), 18)
                    scatter("CrimsonTuft", cx, z, s, int(rng.integers(1, 4)), 18)
            elif m is cavern:
                cyan = rng.random() < 0.5
                a, c = ("Cyan", "Pink") if cyan else ("Pink", "Cyan")
                if count % 2 == 0:
                    put(f"Crystal{a}XXL", wall - s * 12, z)
                    scatter(f"Crystal{c}Large", cx, z, s, 1, 16)
                    scatter(f"Crystal{a}Medium", cx, z, s, int(rng.integers(1, 3)), 18)
                    scatter("FungusCluster", cx, z, s, int(rng.integers(0, 2)), 18)
                else:
                    put("FungusLarge", cx, z)
                    scatter("FungusMedium", cx, z, s, 1, 14)
                    scatter("FungusCluster", cx, z, s, int(rng.integers(2, 4)), 16)
                    scatter(f"Crystal{a}Medium", cx, z, s, int(rng.integers(0, 2)), 18)
            elif m is meadow:
                put(rng.choice(["PineTall", "Pine"]), wall - s * 14, z)
                scatter("PineSmall", wall - s * 12, z, s, int(rng.integers(0, 2)), 14)
            elif m is woodland:
                if swords and z < swords[0]:
                    swords.pop(0)
                    if put("SwordStone", wall - s * 14, z, facing(s)):
                        scatter("BirchSmall", cx, z, s, 2, 18)
                        continue
                put(rng.choice(["BirchTall", "BirchTwin"]), wall - s * 11, z)
                scatter("BirchLean", cx, z, s, int(rng.integers(0, 2)), 16)
                scatter("BirchSmall", cx, z, s, int(rng.integers(1, 3)), 18)
            count += 1
        side = -side
        z -= rng.uniform(40, 75) if m is woodland else rng.uniform(70, 120) if m is meadow else rng.uniform(60, 110)
    return out


def temple_props(b, rng, out, put, scatter, facing):
    """A row down each side's dirt, the same both sides: tree, little tree, tree, lantern,
    every 40 studs. Tombstones or temple stones now and then inside the row. Lily pads."""
    cycle = ["TempleTree", "TempleTreeSmall", "TempleTree", "StoneLantern"]
    z, k = b.Z0 - 24, 0
    while z > b.Z1 + 20:
        for s in (-1, 1):
            put(cycle[k % 4], s * (half_width(z) - temple.SIDE_W * temple.CELL / 2), z, facing(s))
        z -= 40
        k += 1
    z, side = b.Z0 - rng.uniform(80, 140), 1 if rng.random() < 0.5 else -1
    while z > b.Z1 + 30:
        cx = side * (half_width(z) - 24)
        if rng.random() < 0.5:
            put("TombTall", cx, z, facing(side))
            for name in ("TombShort", "TombLean"):
                for _ in range(10):
                    if put(name, cx - side * rng.uniform(-4, 4), z + rng.uniform(-14, 14), facing(side)):
                        break
        else:
            put(rng.choice(["TempleStone", "TempleStoneTwin"]), cx, z)
        side = -side
        z -= rng.uniform(140, 240)
    for x, z, r in b.extra or []:  # (the pond's lily pads, where tools/world2_temple.luau's discs were)
        name = rng.choice(["LilyPad", "LilyPad", "LilyPads", "LilyFlower"])
        size = PIECES[name][0][0]
        out.append((name, x, z, float(rng.uniform(0, 360)), temple.TOPS[temple.WATER], round(r / size, 2)))
    return out


def tomb_props(b, rng, out, put, scatter, facing):
    """A sphinx either side before each dais; then an avenue of statues down both walls."""
    k = b.kind
    framed = np.nonzero((k == tomb.FRAME).sum(axis=0) > 6)[0]
    starts = [j for n, j in enumerate(framed) if n == 0 or framed[n - 1] != j - 1]
    for j in starts:
        z = b.Z0 - j * b.CELL + 24
        for s in (-1, 1):
            put("Sphinx", s * (half_width(z) - 14), z, 180.0)
    z, n = b.Z0 - 40, 0
    while z > b.Z1 + 30:
        for s in (-1, 1):
            put("WarriorStatue" if n % 2 == 0 else "SwordStatue", s * (half_width(z) - 9), z, facing(s))
            zz = z - 48  # between this pair and the next
            if n % 2 == 0:
                put("SarcophagusStanding", s * (half_width(zz) - 6), zz, facing(s))
            elif rng.random() < 0.6:
                cx = s * (half_width(zz) - 12)
                if put("GoldStack", cx, zz):
                    scatter(rng.choice(["GoldBar", "Trophy"]), cx, zz, s, 2, 12)
        z -= 96
        n += 1
    return out


def overhead(b, props, path, s=2, rows=4):
    m = b
    seg = int(math.ceil(m.NZ / rows))
    w, h = m.NX * m.CELL * s, seg * m.CELL * s
    im = Image.new("RGB", (rows * (w + 20), h), (255, 255, 255))
    d = ImageDraw.Draw(im)
    for r in range(rows):
        ox = r * (w + 20)

        def P(x, z):
            return ox + (x + m.OUT) * s, (m.Z0 - z - r * seg * m.CELL) * s

        for j in range(r * seg, min(m.NZ, (r + 1) * seg)):
            for i in range(m.NX):
                k = int(b.kind[i, j])
                if k == m.VOID:
                    continue
                col = m.COLOURS[k][0]
                x0, y0 = ox + i * m.CELL * s, (j - r * seg) * m.CELL * s
                d.rectangle([x0, y0, x0 + m.CELL * s - 1, y0 + m.CELL * s - 1], fill=col)
        for name, x, z, *_ in props:
            if r * seg * m.CELL <= m.Z0 - z < (r + 1) * seg * m.CELL:
                rad = radius(name)
                col = COLOURS.get(name, (255, 255, 255))
                tier = PIECES[name][1]
                d.ellipse([*P(x - rad, z + rad), *P(x + rad, z - rad)], fill=col,
                          outline=(20, 20, 20) if tier else (255, 255, 255), width=s)
    im.save(path)


def load_pieces(meshes):
    """{name: [(colour, [triangles])]} from design/<set>/pieces/*.obj and colours.txt."""
    out = {}
    for folder in SETS:
        base = os.path.join(meshes, "design", folder, "pieces")
        cols = {}
        for line in open(os.path.join(base, "colours.txt")):
            if ":" in line and not line.startswith("#"):
                key, rest = line.split(":", 1)
                rgb = tuple(int(v) for v in rest.split(",")[1:4])
                cols[key.strip()] = rgb
        for key, rgb in cols.items():
            name = key.rsplit("_", 1)[0]
            v, tris = [], []
            for line in open(os.path.join(base, key + ".obj")):
                if line.startswith("v "):
                    v.append([float(t) for t in line.split()[1:4]])
                elif line.startswith("f "):
                    idx = [int(t.split("/")[0]) - 1 for t in line.split()[1:]]
                    for a in range(1, len(idx) - 1):
                        tris.append(np.array([v[idx[0]], v[idx[a]], v[idx[a + 1]]]))
            out.setdefault(name, []).append((rgb, tris))
            COLOURS.setdefault(name, rgb)
    return out


def rider_view(b, props, pieces, path, z_eye, look=60):
    """The course from a rider's eye: the floor's tiles and walls as boxes, props as meshes."""
    import partlib
    from partlib import Part
    m = b
    parts = []
    z_far = z_eye - 420
    for j in range(m.NZ):
        z = m.Z0 - j * m.CELL - m.CELL / 2
        if not (z_far < z < z_eye + 10):
            continue
        for i in range(m.NX):
            k = int(b.kind[i, j])
            if k == m.VOID:
                continue
            x = -m.OUT + i * m.CELL + m.CELL / 2
            top = int(b.top[i, j])
            for a in (0, 1):
                for c in (0, 1):
                    col = m.COLOURS[k][(a + c) % 2]
                    parts.append(Part("F", (4, top + 2, 4), partlib.T(x - 2 + 4 * a, (top - 2) / 2, z - 2 + 4 * c), col))
        if j % 2 == 0:
            for sgn in (-1, 1):
                wc = WALLS[b.name]
                parts.append(Part("W", (8, 48, 16), partlib.T(sgn * (half_width(z) + 4), 24, z), wc))
    for name, x, z, yaw, y, sc in props:
        if not (z_far < z < z_eye + 10):
            continue
        cf = partlib.T(x, y, z) @ partlib.Ry(yaw) @ np.diag([sc, sc, sc, 1.0])
        for rgb, tris in pieces.get(name, []):
            for t in tris:
                n = np.cross(t[1] - t[0], t[2] - t[0])
                ln = np.linalg.norm(n)
                if ln < 1e-9:
                    continue
                inner = t.mean(0) - n / ln * 0.5
                p = Part(name, (1, 1, 1), cf, rgb, shape="Poly")
                p.polys = [t, np.array([inner, inner, inner])]  # (the degenerate one sets the inside)
                parts.append(p)
    img = partlib.render(parts, eye=(0, 30, z_eye), target=(0, 6, z_eye - look), W=1280, H=720, fov=60,
                         fog=False, outline=False, ground=False)
    img.save(path)


def write_luau(sets):
    rows = []
    for bname, props in sets:
        for name, x, z, yaw, y, sc in props:
            tier = PIECES[name][1]
            hx, hz = PIECES[name][0]
            k = PIECES[name][3] if len(PIECES[name]) > 3 else 1  # (a tree's hit box: its trunk)
            rows.append('\t{ "%s", "%s", %.1f, %d, %.1f, %d, %d, %.1f, %.1f, %g },'
                        % (bname, name, x, y, z, round(yaw) % 360, tier or 0, hx * sc * 2 * k, hz * sc * 2 * k, sc))
    body = open(os.path.join(HERE, "world2_props.luau.in")).read()
    body = body.replace("--PROPS--", "\n".join(rows))
    open(os.path.join(HERE, "world2_props.luau"), "w").write(body)
    return len(rows)


def main():
    argv = sys.argv[1:]
    if "--meshes" in argv:
        k = argv.index("--meshes")
        argv = argv[:k] + argv[k + 2:]
    args = [a for a in argv if not a.startswith("--")]
    out = args[0] if args else "/mnt/project-files/biomes/world2_props"
    meshes = sys.argv[sys.argv.index("--meshes") + 1] if "--meshes" in sys.argv else os.path.join(HERE, "..")
    os.makedirs(out, exist_ok=True)
    pieces = load_pieces(meshes) if os.path.exists(os.path.join(meshes, "design", "tomb", "pieces")) else {}
    sets = []
    for mod, name, seed in ((meadow, "Meadow", 67), (crimson, "Crimson", 71), (cavern, "Cavern", 73),
                            (woodland, "Woodland", 79), (temple, "Temple", 83), (tomb, "Tomb", 89)):
        b = Biome(mod, name, seed)
        props = layout(b)
        sets.append((name, props))
        overhead(b, props, os.path.join(out, f"{name.lower()}_props.png"))
        if pieces:
            rider_view(b, props, pieces, os.path.join(out, f"{name.lower()}_view.png"), b.Z0 - 300)
        print(name, len(props), {n: sum(1 for p in props if p[0] == n) for n in sorted({p[0] for p in props})})
    print("props:", write_luau(sets))


if __name__ == "__main__":
    main()
