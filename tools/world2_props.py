"""World 2's props (QM, Oct 13; draft): the Rock mesh thread's crimson set in the Crimson
Lands and its crystals and fungi in the Crystal Cavern, World 1 style: clusters hugging
the walls, the middle of the course clear.

Run: python3 tools/world2_props.py [out_dir] [--meshes DIR]
     writes tools/world2_props.luau and renders an overhead of each biome and a rider's
     view (the rider's view needs the meshes' pieces, design/crimson/pieces and
     design/crystals/pieces from branch claude/rock-meshes-ggc7md: DIR holds design/).

Clusters every 60 to 110 studs down each biome, one side then the other (now and then
both), each within REACH studs of its wall: a big piece against the wall, a middle
one beside it, small ones round their feet. Big and middle pieces are Obstacles
(smashed when ridden into, with an invisible Base footprint and a Tier); small ones
are walk-through Decor. Nothing within NEST_CLEAR of a nest, nothing on the Cavern's
planks, every piece on the tile height under it. In the Crimson Lands a cluster that
lands on stone is runestones; elsewhere mushrooms. In the Cavern, crystal clusters
and fungus clusters alternate.

The Luau clones each piece from ServerStorage.World2Assets.<Name>: a Model of the
coloured MeshParts, at the mesh's own size (1x), pivot at its base's middle.
"""

import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(__file__))
from funnel_grid import half_width, map_x  # noqa: E402
import world2_crimson as crimson  # noqa: E402
import world2_cavern as cavern  # noqa: E402

HERE = os.path.dirname(__file__)
SCALE = 2  # (World 1's lobby plants are 2x to 4x their meshes)
REACH = 28  # studs from the wall a cluster may reach
NEST_CLEAR = 20
OFFSET = 1000
# name: (half footprint at 1x (x, z), tier or None for walk-through decor)
PIECES = {
    "MushroomGiant": ((3, 3), 3), "MushroomMedium": ((2, 2), 2), "MushroomSmall": ((1, 1), None),
    "CrimsonTuft": ((1.4, 1.4), None), "RunestoneTall": ((2.4, 1.6), 2), "RunestoneShort": ((2.2, 1.6), 1),
    "RuneBlock": ((4.4, 2.3), 1),
    "CrystalCyanXXL": ((8, 8), 3), "CrystalPinkXXL": ((8, 8), 3), "CrystalCyanLarge": ((4.4, 4.4), 2),
    "CrystalPinkLarge": ((4.4, 4.4), 2), "CrystalCyanMedium": ((2.5, 2.5), None), "CrystalPinkMedium": ((2.5, 2.5), None),
    "FungusLarge": ((3, 3), 2), "FungusMedium": ((2, 2), 1), "FungusCluster": ((2.5, 2), None),
}
CRIMSON_NESTS = [(16, -2388), (-14, -2588), (18, -2808), (-14, -3196), (18, -3416), (-16, -3816)]  # (desert_ground.NESTS)
COLOURS = {}  # piece colours for the renders, read from the pieces' colours.txt


def radius(name):
    hx, hz = PIECES[name][0]
    return max(hx, hz) * SCALE


class Biome:
    def __init__(self, mod, name, nests, seed):
        self.mod, self.name, self.seed = mod, name, seed
        if mod is crimson:
            self.kind = mod.layout()
            self.top = np.vectorize(lambda k: mod.TOPS.get(int(k), 0))(self.kind)
        else:
            self.kind = mod.layout()
            self.top = np.vectorize(lambda k: mod.TOPS.get(int(k), 0))(self.kind)
        self.nests = [(float(map_x(x, z)), z) for x, z in nests]

    def cell(self, x, z):
        m = self.mod
        i, j = int((x + m.OUT) // m.CELL), int((m.Z0 - z) // m.CELL)
        if 0 <= i < m.NX and 0 <= j < m.NZ:
            return int(self.kind[i, j]), int(self.top[i, j])
        return m.VOID, 0


def layout(b):
    m = b.mod
    rng = np.random.default_rng(b.seed)
    out = []  # (name, x, z, yaw, y)

    def fits(name, x, z):
        r = radius(name)
        if abs(x) > half_width(z) - r * 0.6 or abs(x) < half_width(z) - REACH:
            return False
        if z > m.Z0 - 12 or z < m.Z1 + 12:
            return False
        if any(math.hypot(x - a, z - c) < NEST_CLEAR + r for a, c in b.nests):
            return False
        k, _ = b.cell(x, z)
        if k == m.VOID or (m is cavern and k == cavern.PLANKS):
            return False
        return all(math.hypot(x - a, z - c) > (r + radius(n2)) * 0.8 for n2, a, c, _, _ in out)

    def put(name, x, z):
        if fits(name, x, z):
            out.append((name, x, z, float(rng.uniform(0, 360)), b.cell(x, z)[1]))
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

    z = m.Z0 - rng.uniform(30, 60)
    side = 1 if rng.random() < 0.5 else -1
    count = 0
    while z > m.Z1 + 30:
        sides = [side, -side] if rng.random() < 0.25 else [side]
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
            else:
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
            count += 1
        side = -side
        z -= rng.uniform(60, 110)
    return out


def overhead(b, props, path, s=2, rows=4):
    m = b.mod
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
        for name, x, z, _, _ in props:
            if r * seg * m.CELL <= m.Z0 - z < (r + 1) * seg * m.CELL:
                rad = radius(name)
                col = COLOURS.get(name, (255, 255, 255))
                tier = PIECES[name][1]
                d.ellipse([*P(x - rad, z + rad), *P(x + rad, z - rad)], fill=col,
                          outline=(20, 20, 20) if tier else (255, 255, 255), width=s)
        for x, z in b.nests:
            if r * seg * m.CELL <= m.Z0 - z < (r + 1) * seg * m.CELL:
                d.ellipse([*P(x - 6, z + 6), *P(x + 6, z - 6)], outline=(255, 255, 255), width=2 * s)
    im.save(path)


def load_pieces(meshes):
    """{name: [(colour, [triangles])]} from design/<set>/pieces/*.obj and colours.txt."""
    out = {}
    for folder in ("crimson", "crystals"):
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
    m = b.mod
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
                wc = getattr(m, "WALL", [(150, 60, 70)])[0] if m is cavern else (96, 22, 36)
                parts.append(Part("W", (8, 48, 16), partlib.T(sgn * (half_width(z) + 4), 24, z), wc))
    for name, x, z, yaw, y in props:
        if not (z_far < z < z_eye + 10):
            continue
        cf = partlib.T(x, y, z) @ partlib.Ry(yaw) @ np.diag([SCALE, SCALE, SCALE, 1.0])
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
        for name, x, z, yaw, y in props:
            tier = PIECES[name][1]
            hx, hz = PIECES[name][0]
            rows.append('\t{ "%s", "%s", %.1f, %d, %.1f, %d, %d, %.1f, %.1f },'
                        % (bname, name, x, y, z, round(yaw), tier or 0, hx * SCALE * 2, hz * SCALE * 2))
    body = open(os.path.join(HERE, "world2_props.luau.in")).read()
    body = body.replace("--SCALE--", str(SCALE)).replace("--PROPS--", "\n".join(rows))
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
    pieces = load_pieces(meshes) if os.path.exists(os.path.join(meshes, "design", "crimson", "pieces")) else {}
    sets = []
    for mod, name, nests, seed in ((crimson, "Crimson", CRIMSON_NESTS, 71), (cavern, "Cavern", [(16, -4272), (-14, -4832), (18, -5472)], 73)):
        b = Biome(mod, name, nests, seed)
        props = layout(b)
        sets.append((name, props))
        overhead(b, props, os.path.join(out, f"{name.lower()}_props.png"))
        if pieces:
            rider_view(b, props, pieces, os.path.join(out, f"{name.lower()}_view.png"), mod.Z0 - 300)
        print(name, len(props), {n: sum(1 for p in props if p[0] == n) for n in sorted({p[0] for p in props})})
    print("props:", write_luau(sets))


if __name__ == "__main__":
    main()
