"""World 3's props (Oct 14; the World 3 props thread's sets, approved by the coordinator for QM),
placed World 1/2 style: clusters hugging the walls, the course's middle clear.

Run: python3 tools/world3_props.py [out_dir] [--meshes DIR]
     writes tools/world3_props.luau and renders an overhead of each biome (plus a rider's
     view of each when DIR holds the meshes: design/w3_<biome>/pieces from branch
     claude/world3-props-mo84d8 and design/pirate/pieces from claude/rock-meshes-ggc7md).

- Pirate Cove: palm groves with crates and barrels (the base's set: palms 3x, crates and
  barrels 2x), a cannon battery or a treasure stash now and then, an anchor, a dock jutting
  into a lagoon, rowboats on the water by the walls, a skull rock at each bay's widest, a
  shipwreck in the big lagoon bay.
- Garden: giant sunflowers, daisies and tulips over flower patches; hedge runs and picket
  fences along the walls; toadstool rings; a topiary pair or a gnome now and then; a
  watering can twice. Never on the flagstone path.
- Candyland: lollipop and candy-cane groves, ice creams and cupcakes; a gingerbread house
  and a donut arch now and then; chocolate bars and rocks; wrapped candies and gumdrops.
- Cnidaria: kelp forests; sea fans and staghorn coral; a sunken column, a bubble vent or a
  giant clam now and then; brain and tube coral, anemones and shells. Never in the seabed lane.

Big pieces are 2x (Obstacles: smashed when ridden into, with an invisible Base footprint and
a Tier), small ones 1.5x (walk-through Decor), per the props thread. Each stands on the tile
under it. The Luau clones each from ServerStorage (World3Assets.<Biome>.<Name>, found by
name anywhere under ServerStorage): a Model of the coloured MeshParts at 1x, pivot at the
middle of its base, front facing -z.
"""

import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(__file__))
import world3_course as course  # noqa: E402
from world3_course import half_width, CELL, OUT, NX  # noqa: E402

HERE = os.path.dirname(__file__)
REACH = 30  # studs from the wall a piece's middle may reach
SETS = ("w3_pirate_cove", "w3_garden", "w3_candyland", "w3_cnidaria", "pirate")
BIG = {  # name: (scale, hit box's share of the footprint)
    "SkullRock": (2, 1), "Shipwreck": (2, 1), "Anchor": (2, 0.6), "Dock": (2, 1),
    "PalmTree": (3, 0.3), "PalmTreeSmall": (3, 0.3), "Crate": (2, 1), "CrateStack": (2, 1),
    "Barrel": (2, 1), "BarrelGroup": (2, 1),
    "GiantSunflower": (2, 0.35), "GiantDaisy": (2, 0.35), "GiantTulip": (2, 0.35), "GiantToadstool": (2, 0.5),
    "HedgeWall": (2, 1), "WateringCan": (2, 1), "GardenGnome": (2, 1), "Topiary": (2, 0.6), "PicketFence": (2, 1),
    "GingerbreadHouse": (2, 1), "DonutArch": (2, 1), "Lollipop": (2, 0.25), "CandyCane": (2, 0.5),
    "IceCream": (2, 0.5), "ChocolateBar": (2, 1), "Cupcake": (2, 1), "ChocolateRocks": (2, 1),
    "Kelp": (2, 0.35), "SunkenColumn": (2, 1), "BubbleVent": (2, 0.8), "SeaFan": (2, 0.6),
    "Staghorn": (2, 0.8), "GiantClam": (2, 1),
}
SMALL = {"Rowboat", "Cannon", "Cannonballs", "TreasureChest", "TreasurePile", "GiantLeaf", "Toadstools",
         "FlowerPatch", "WrappedCandy", "Gumdrops", "BrainCoral", "TubeCoral", "Anemone", "Seashells"}
FOOT = {}  # name: (half width x, half depth z) at 1x, from the meshes
COLOURS = {}  # name: its first piece's colour, for the overheads


def load_pieces(meshes):
    """{name: [(colour, triangles)]} from design/<set>/pieces/*.obj and colours.txt; fills FOOT."""
    out, lo, hi = {}, {}, {}
    for folder in SETS:
        base = os.path.join(meshes, "design", folder, "pieces")
        for line in open(os.path.join(base, "colours.txt")):
            if ":" not in line or line.startswith("#"):
                continue
            key, rest = line.split(":", 1)
            key = key.strip()
            name = key.rsplit("_", 1)[0]
            rgb = tuple(int(v) for v in rest.split(",")[1:4])
            v, tris = [], []
            for row in open(os.path.join(base, key + ".obj")):
                if row.startswith("v "):
                    v.append([float(t) for t in row.split()[1:4]])
                elif row.startswith("f "):
                    idx = [int(t.split("/")[0]) - 1 for t in row.split()[1:]]
                    for a in range(1, len(idx) - 1):
                        tris.append(np.array([v[idx[0]], v[idx[a]], v[idx[a + 1]]]))
            v = np.array(v)
            lo[name] = np.minimum(lo.get(name, v.min(0)), v.min(0))
            hi[name] = np.maximum(hi.get(name, v.max(0)), v.max(0))
            out.setdefault(name, []).append((rgb, tris))
            COLOURS.setdefault(name, rgb)
    for name in out:
        FOOT[name] = ((hi[name][0] - lo[name][0]) / 2, (hi[name][2] - lo[name][2]) / 2)
    return out


def scale_of(name):
    return 1.5 if name in SMALL else BIG[name][0]


def radius(name):
    hx, hz = FOOT[name]
    return max(hx, hz) * scale_of(name)


def tier(name):
    if name in SMALL:
        return 0
    r = radius(name)
    return 3 if r > 14 else 2 if r > 8 else 1


class Floor:
    def __init__(self, b):
        self.b = b
        self.name = b.name

    def at(self, x, z):
        """(tile name, top) under a point, or (None, 0) off the floor."""
        b = self.b
        i, j = int((x + OUT) // CELL), int((b.z0 - z) // CELL)
        if 0 <= i < NX and 0 <= j < b.nz and b.inside[i, j]:
            t = b.tiles[int(b.rung[i, j])]
            return t[0], t[1]
        return None, 0


def layout(f, seed):
    b = f.b
    rng = np.random.default_rng(seed)
    out = []  # (name, x, z, yaw, y, scale)
    water = ("Water", "DeepWater")

    def fits(name, x, z, reach=REACH, on=None, edge=None):
        r = radius(name)
        hw = min(half_width(z - r), half_width(z), half_width(z + r))
        if abs(x) > hw - (r * 0.9 + 3 if edge is None else edge) + 0.01 or abs(x) < hw - reach:
            return False
        if z > b.z0 - 16 or z < b.z1 + 16:
            return False
        # every tile under its footprint (the middle and 8 points round it): dry ground unless
        # it's a piece for the water, and never the boards, the path or the candy cane
        kx, kz = (r * 0.7 if edge is None else edge * 0.7), r * 0.7  # (a long piece along the wall: its own depth)
        for dx, dz in [(0, 0)] + [(kx * math.cos(a), kz * math.sin(a)) for a in np.arange(8) * math.pi / 4]:
            tile, _ = f.at(x + dx, z + dz)
            if tile is None or tile in ("Planks", "Path", "Stripe", "Icing"):
                return False
            if on is not None and tile not in on:
                return False
            if on is None and tile in water:
                return False
        if f.name == "Cnidaria" and abs(x) < 36 + r:  # (the seabed lane)
            return False
        return all(math.hypot(x - a, z - c) > (r + radius(n2)) * 0.8 for n2, a, c, *_ in out)

    def put(name, x, z, yaw=None, reach=REACH, on=None, edge=None):
        name = str(name)
        r = radius(name)
        hw = min(half_width(z - r), half_width(z), half_width(z + r))
        x = math.copysign(min(abs(x), hw - (r * 0.9 + 3 if edge is None else edge)), x)  # (clear of the wall: nothing clips into it)
        if fits(name, x, z, reach, on, edge):
            yaw = float(rng.uniform(0, 360)) if yaw is None else yaw + float(rng.uniform(-5, 5))
            out.append((name, round(x, 1), round(z, 1), yaw, f.at(x, z)[1], scale_of(name)))
            return True
        return False

    def scatter(name, cx, cz, side, n, spread, yaw=None, on=None):
        done = 0
        for _ in range(n * 14):
            if done >= n:
                break
            done += put(name, cx - side * rng.uniform(0, spread), cz + rng.uniform(-spread, spread), yaw, on=on)

    def facing(s):
        return 90.0 * s  # (a piece's front, -z, turned to the course's middle)

    def along(name, s, z):
        """A long piece laid along the wall, its front to the course (its depth toward the wall)."""
        edge = FOOT[name][1] * scale_of(name)
        return put(name, s * (half_width(z) - edge - 1), z, facing(s), edge=edge)

    # Landmarks first, so the clusters fit round them.
    if f.name == "PirateCove":
        for z, s in ((-1160, -1), (-2960, 1)):  # (the two bays' widest)
            for dz in range(0, 160, 16):
                if put("SkullRock", s * (half_width(z - dz) - 18), z - dz, facing(s), reach=40, on=water + ("WetSand", "Ground")):
                    break
        for z in (-2780, -3100):  # (the big bay's lagoon: the wreck on the water)
            for s in (1, -1):
                for dz in range(0, 200, 16):
                    if put("Shipwreck", s * (half_width(z - dz) - 26), z - dz, 180 + 20 * s, reach=44, on=water + ("WetSand",)):
                        break
                else:
                    continue
                break
    elif f.name == "Garden":
        for z, s in ((b.z0 - 0.3 * (b.z0 - b.z1), 1), (b.z0 - 0.75 * (b.z0 - b.z1), -1)):
            put("WateringCan", s * (half_width(z) - 16), z, facing(s), reach=40)
    elif f.name == "Candyland":
        for k, frac in enumerate((0.12, 0.38, 0.62, 0.88)):
            z, s = b.z0 - frac * (b.z0 - b.z1), (-1) ** k
            put("GingerbreadHouse", s * (half_width(z) - 16), z, facing(s), reach=40)
        for k, frac in enumerate((0.25, 0.5, 0.75)):
            z, s = b.z0 - frac * (b.z0 - b.z1), (-1) ** (k + 1)
            along("DonutArch", s, z)
    elif f.name == "Cnidaria":
        for k in range(8):
            z, s = b.z0 - (k + 0.5) / 8 * (b.z0 - b.z1), (-1) ** k
            put(("SunkenColumn", "BubbleVent", "GiantClam")[k % 3], s * (half_width(z) - 16), z, facing(s), reach=40)

    z = b.z0 - rng.uniform(30, 60)
    side = 1 if rng.random() < 0.5 else -1
    n = 0
    while z > b.z1 + 30:
        sides = [side, -side] if rng.random() < 0.3 else [side]
        for s in sides:
            wall = s * half_width(z)
            cx = wall - s * 12
            if f.name == "PirateCove":
                if n % 7 == 3:
                    put("Cannon", cx, z, facing(s))
                    scatter("Cannon", cx, z, s, 1, 14, facing(s))
                    scatter("Cannonballs", cx, z, s, 1, 12)
                elif n % 7 == 6:
                    put("TreasureChest", cx, z, facing(s))
                    scatter("TreasurePile", cx, z, s, 2, 12)
                    scatter("Barrel", cx, z, s, 1, 14)
                elif n % 11 == 5:
                    put("Anchor", wall - s * 8, z, facing(s))
                    scatter("Crate", cx, z, s, 1, 14)
                else:
                    put(rng.choice(["PalmTree", "PalmTree", "PalmTreeSmall"]), wall - s * 14, z)
                    scatter("PalmTreeSmall", cx, z, s, int(rng.integers(0, 2)), 16)
                    scatter(rng.choice(["Crate", "CrateStack", "Barrel", "BarrelGroup"]), cx, z, s, 1, 16)
                scatter("Rowboat", cx, z, s, 1 if rng.random() < 0.35 else 0, 18, on=water)
                if n % 9 == 4:
                    for dz in range(0, 40, 8):  # (a dock reaching from the wall into a lagoon)
                        if f.at(wall - s * 30, z - dz)[0] in water and put("Dock", wall - s * 12, z - dz, facing(s), on=("WetSand", "Ground", "Water")):
                            break
            elif f.name == "Garden":
                pick = rng.choice(["hedge", "fence", "toadstools", "flowers", "flowers", "flowers"])
                if pick == "hedge":
                    for k in range(int(rng.integers(1, 4))):
                        along("HedgeWall", s, z - k * 36)
                    scatter("FlowerPatch", cx, z, s, int(rng.integers(1, 3)), 18)
                elif pick == "fence":
                    for k in range(int(rng.integers(1, 3))):
                        along("PicketFence", s, z - k * 26)
                    put(rng.choice(["Topiary", "GardenGnome"]), cx - s * 4, z - 12, facing(s))
                elif pick == "toadstools":
                    put("GiantToadstool", wall - s * 13, z)
                    scatter("Toadstools", cx, z, s, int(rng.integers(1, 3)), 16)
                    scatter("GiantLeaf", cx, z, s, int(rng.integers(0, 2)), 16)
                else:
                    put(rng.choice(["GiantSunflower", "GiantDaisy", "GiantTulip"]), wall - s * 12, z, facing(s))
                    scatter(rng.choice(["GiantSunflower", "GiantDaisy", "GiantTulip"]), cx, z, s, int(rng.integers(0, 2)), 18, facing(s))
                    scatter("FlowerPatch", cx, z, s, int(rng.integers(0, 3)), 18)
                    scatter("GiantLeaf", cx, z, s, int(rng.integers(0, 2)), 18)
            elif f.name == "Candyland":
                if rng.random() < 0.2:  # (room to breathe)
                    pass
                elif n % 4 == 1:
                    put("Lollipop", wall - s * 10, z, facing(s))
                    scatter("CandyCane", cx, z, s, 2, 16, facing(s))
                    scatter("Gumdrops", cx, z, s, 2, 18)
                elif n % 4 == 3:
                    put(rng.choice(["ChocolateBar", "ChocolateRocks"]), wall - s * 10, z, facing(s))
                    scatter("WrappedCandy", cx, z, s, 2, 18)
                else:
                    put(rng.choice(["IceCream", "Cupcake"]), wall - s * 10, z)
                    scatter(rng.choice(["Cupcake", "Lollipop"]), cx, z, s, 1, 16, facing(s))
                    scatter(rng.choice(["Gumdrops", "WrappedCandy"]), cx, z, s, int(rng.integers(1, 3)), 18)
            elif f.name == "Cnidaria":
                if rng.random() < 0.25:  # (room to breathe)
                    n += 1
                    continue
                big = rng.choice(["Kelp", "Kelp", "SeaFan", "Staghorn"])
                put(big, wall - s * 10, z, facing(s) if big == "SeaFan" else None)
                for name in rng.choice(["Kelp", "SeaFan", "Staghorn", "BrainCoral", "TubeCoral", "Anemone", "Seashells"],
                                       size=int(rng.integers(1, 3)), replace=False):
                    scatter(name, cx, z, s, 1, 18)
            n += 1
        side = -side
        z -= rng.uniform(50, 150) if f.name == "Garden" else rng.uniform(70, 120)
    return out


def overhead(b, props, path, s=1, rows=4):
    """The biome's top-down (as tools/world3_course.py draws it), each piece a disc of its
    colour, its size: obstacles outlined dark, walk-through decor white."""
    im = course.render(b, WALLCOL[b.name], path, rows=rows, s=s)
    d = ImageDraw.Draw(im)
    seg = int(math.ceil(b.nz / rows))
    w = NX * CELL * s
    for name, x, z, *_ in props:
        r = int((b.z0 - z) // (seg * CELL))
        ox = r * (w + 24)
        px, py = ox + (x + OUT) * s, (b.z0 - z - r * seg * CELL) * s
        rad = radius(name) * s
        d.ellipse([px - rad, py - rad, px + rad, py + rad], fill=COLOURS[name],
                  outline=(20, 20, 20) if tier(name) else (255, 255, 255), width=2)
    im.save(path)


def rider_view(b, props, pieces, path, z_eye, look=60):
    """The course from a rider's eye: the floor's tiles and the walls as boxes, props as meshes."""
    import partlib
    from partlib import Part
    parts = []
    z_far = z_eye - 420
    walls = WALLCOL[b.name]
    for j in range(b.nz):
        z = b.z0 - j * CELL - CELL / 2
        if not (z_far < z < z_eye + 10):
            continue
        for i in range(NX):
            if not b.inside[i, j]:
                continue
            name, top, col, chk = b.tiles[int(b.rung[i, j])]
            x = -OUT + i * CELL + CELL / 2
            for a in (0, 1):
                for c in (0, 1):
                    colour = col if chk is None or (a + c) % 2 == 0 else chk
                    parts.append(Part("F", (4, top + 2, 4), partlib.T(x - 2 + 4 * a, (top - 2) / 2, z - 2 + 4 * c), colour))
        if j % 2 == 0:
            for sg in (-1, 1):
                parts.append(Part("W", (8, 48, 16), partlib.T(sg * (half_width(z) + 4), 24, z), walls["wall"][0]))
                parts.append(Part("C", (10, 2, 16), partlib.T(sg * (half_width(z) + 3), 49, z), walls["cap"]))
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
                p.polys = [t, np.array([inner, inner, inner])]
                parts.append(p)
    img = partlib.render(parts, eye=(0, 30, z_eye), target=(0, 6, z_eye - look), W=1280, H=720, fov=60,
                         fog=False, outline=False, ground=False)
    img.save(path)


def write_luau(sets):
    rows = []
    for bname, props in sets:
        for name, x, z, yaw, y, sc in props:
            hx, hz = FOOT[name]
            k = 1 if name in SMALL else BIG[name][1]
            rows.append('\t{ "%s", "%s", %.1f, %d, %.1f, %d, %d, %.1f, %.1f, %g },'
                        % (bname, name, x, y, z, round(yaw) % 360, tier(name), max(hx * sc * 2 * k, 2), max(hz * sc * 2 * k, 2), sc))
    body = open(os.path.join(HERE, "world3_props.luau.in")).read()
    open(os.path.join(HERE, "world3_props.luau"), "w").write(body.replace("--PROPS--", "\n".join(rows)))
    return len(rows)


WALLCOL = {}


def main():
    argv = sys.argv[1:]
    meshes = os.path.join(HERE, "..")
    if "--meshes" in argv:
        k = argv.index("--meshes")
        meshes = argv[k + 1]
        argv = argv[:k] + argv[k + 2:]
    out = argv[0] if argv else "/mnt/project-files/world3/props_layout"
    os.makedirs(out, exist_ok=True)
    pieces = load_pieces(meshes)
    made = [course.pirate_cove(), course.garden(), course.candyland(), course.cnidaria()]
    sets = []
    for (b, walls, *_), seed in zip(made, (101, 103, 107, 109)):
        WALLCOL[b.name] = walls
        props = layout(Floor(b), seed)
        sets.append((b.name, props))
        overhead(b, props, os.path.join(out, "%d_%s_props.png" % (b.index + 1, b.name)))
        if "--views" in sys.argv:
            rider_view(b, props, pieces, os.path.join(out, "%d_%s_view.png" % (b.index + 1, b.name)), b.z0 - 0.4 * (b.z0 - b.z1))
        print(b.name, len(props), {n: sum(1 for p in props if p[0] == n) for n in sorted({p[0] for p in props})})
    if os.path.exists(os.path.join(HERE, "world3_props.luau.in")):
        print("props:", write_luau(sets))


if __name__ == "__main__":
    main()
