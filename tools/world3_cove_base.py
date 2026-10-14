"""World 3's home base re-imagined as a pirate cove (QM, Oct 14 23:25: his reference picture):
one sand plateau with small square-ish pools, sandstone cliffs for walls, the sea round it.

Run: python3 tools/world3_cove_base.py [dump.json] [out_dir]
     reads Studio's dump of the live base (/mnt/project-files/world3_base_dump.json: pens,
     decor, spawn, portal), writes the cliff meshes (design/w3_base/pieces, OBJ + colours.txt,
     the props threads' format), tools/world3_cove_base.luau, and renders a top-down and
     rider views to /mnt/project-files/world3/cove_base/.

- Floor: sand at the base's height (top 1). Pools of the water tile (top -2), each ringed by
  wet sand (-1) then damp sand (0), QM's layered rule. Pools keep clear of the walls (sand
  meets the cliffs), the pens at their biggest, the course's mouth, the spawn, the Worlds
  portal and QM's decor; rides cross them (a sunk tile, like the course's).
- Walls: a row of sandstone cliff blocks (meshes: a sandstone body, a pale sand top) along
  the old walls' line, their inner faces on it, never further in; tops 12 to 24 studs above
  the floor, so the sea shows over them. Bushes and a few small palms on top. The old walls
  stay as invisible barriers.
- The sea: the water tile all round outside the cliffs, 13 studs below the floor.
"""

import json
import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from desert_ground import rects  # noqa: E402

# The base inside its walls (the live layout, Oct 14: tools/world3_baselower.luau put the sand top at 1)
X0, X1, Z0, Z1 = -216, 216, 0, 320
GATE = 56  # the course's mouth: x -56..56 at z 0
C = 4  # floor cells, studs
NX, NZ = (X1 - X0) // C, (Z1 - Z0) // C
SAND, DAMP, WET, WATER = 0, 1, 2, 3
TILES = {SAND: ("Ground", 1), DAMP: ("DampSand", 0), WET: ("WetSand", -1), WATER: ("Water", -2)}
VIEW = {SAND: (236, 210, 156), DAMP: (224, 194, 140), WET: (244, 230, 196), WATER: (46, 178, 196)}  # (Config's, stamina-loop 819778c: for the renders only)
SEA_TOP, CLIFF_FOOT = -12, -20  # the sea's top; the cliffs' meshes start below it
ROCK, TOP, LEAF, LEAF2 = (214, 182, 132), (226, 196, 146), (70, 136, 52), (95, 168, 62)  # Config's (819778c): WallColors B and A, CapColor, Grass
SEED = 7


# ---- the live layout ----------------------------------------------------------------------

def load(path):
    d = json.load(open(path))
    pens = []
    for p in d["pens"]:
        tiles = next(q for q in d["parts"] if q["path"] == "Pens.%s.Tiles" % p["name"])
        pens.append((p["name"], p["pivot"][0], p["pivot"][2], p["size"][0], p["size"][2], tiles["rot"][1]))
    decor = []
    for m in d["models"]:
        if m["path"].startswith("World.BaseDecor."):
            name = m["path"].split(".")[-1]
            r = 9 if name.startswith("Palm") else max(m["bboxSize"][0], m["bboxSize"][2]) / 2
            decor.append((name, m["pivot"][0], m["pivot"][2], r))
    spawn = next(n["pos"] for n in d["named"] if n["path"] == "World.SpawnLocation")
    return pens, decor, (spawn[0], spawn[2])


def cells():
    xs = X0 + C * np.arange(NX) + C / 2
    zs = Z0 + C * np.arange(NZ) + C / 2
    return np.meshgrid(xs, zs, indexing="ij")


def dilate(m, n=1):
    for _ in range(n):
        p = np.pad(m, 1)
        out = m.copy()
        for di in (-1, 0, 1):
            for dj in (-1, 0, 1):
                out |= p[1 + di:1 + di + m.shape[0], 1 + dj:1 + dj + m.shape[1]]
        m = out
    return m


def blocked(pens, decor, spawn):
    """Cells no pool (or its rims) may touch."""
    x, z = cells()
    b = np.zeros((NX, NZ), bool)
    b |= (x < X0 + 16) | (x > X1 - 16) | (z > Z1 - 16) | (z < Z0 + 16)  # sand along the cliffs
    for _, px, pz, sx, sz, yaw in pens:  # the pens at their biggest, 8 studs round
        a = math.radians(yaw)
        u = (x - px) * math.cos(a) - (z - pz) * math.sin(a)
        v = (x - px) * math.sin(a) + (z - pz) * math.cos(a)
        b |= (np.abs(u) < sx / 2 + 4) & (np.abs(v) < sz / 2 + 4)
    b |= (np.abs(x) < GATE) & (z < 24)  # the mouth by the start line
    b |= np.hypot(x - spawn[0], z - spawn[1]) < 20
    for _, dx, dz, r in decor:
        b |= np.hypot(x - dx, z - dz) < r + 2
    return b


def pools(block, rng, want=16):
    """Water: blocky pools (two or three overlapping rectangles), each with room for its rims."""
    water = np.zeros((NX, NZ), bool)
    tries = 0
    n = 0
    while n < want and tries < 4000:
        tries += 1
        i, j = int(rng.integers(0, NX)), int(rng.integers(0, NZ))
        p = np.zeros_like(water)
        for k in range(int(rng.integers(2, 4))):
            w, h = int(rng.integers(2, 6)), int(rng.integers(2, 6))
            a = i + int(rng.integers(-2, 3)) if k else i
            c = j + int(rng.integers(-2, 3)) if k else j
            p[max(a, 0):min(a + w, NX), max(c, 0):min(c + h, NZ)] = True
        foot = dilate(p, 2)
        if (foot & block).any() or (dilate(foot, 2) & water).any():  # rims clear, and sand between pools
            continue
        water |= p
        n += 1
    return water


def floor(water):
    kind = np.full((NX, NZ), SAND)
    wet = dilate(water) & ~water
    kind[dilate(wet | water) & ~wet & ~water] = DAMP
    kind[wet] = WET
    kind[water] = WATER
    # the layered rule: no two cells (diagonals too) more than a rung apart
    p = np.pad(kind, 1, mode="edge")
    for di in (-1, 0, 1):
        for dj in (-1, 0, 1):
            assert (np.abs(kind - p[1 + di:1 + di + NX, 1 + dj:1 + dj + NZ]) <= 1).all()
    return kind


# ---- the cliffs -----------------------------------------------------------------------------

def ring(w, d, c, y):
    """An octagon: a w x d rectangle with its corners cut by c, at height y (x, z centred)."""
    hw, hd = w / 2, d / 2
    return [(-hw + c, y, -hd), (hw - c, y, -hd), (hw, y, -hd + c), (hw, y, hd - c),
            (hw - c, y, hd), (-hw + c, y, hd), (-hw, y, hd - c), (-hw, y, -hd + c)]


def prism(rings, rng, jitter):
    """Faces between stacked rings (first at the bottom), closed top and bottom; vertices jittered."""
    v = [np.array(p) + np.r_[rng.uniform(-jitter, jitter), 0, rng.uniform(-jitter, jitter)] for r in rings for p in r]
    n = len(rings[0])
    f = []
    for k in range(len(rings) - 1):
        for a in range(n):
            b = (a + 1) % n
            f.append((k * n + a, k * n + b, (k + 1) * n + b, (k + 1) * n + a))
    f.append(tuple(range(n - 1, -1, -1)))  # bottom
    top = (len(rings) - 1) * n
    f.append(tuple(top + a for a in range(n)))  # top
    return np.array(v), f


def cliff(w, d, h, rng):
    """One sandstone block, w wide (x), d deep (z, inner face at -z), its top h above its foot:
    the body slightly tapered, a pale top 4 deep, its upper edge bevelled."""
    t = h - 4
    body = prism([ring(w, d, 2, 0), ring(w - 1.2, d - 1.2, 2, t)], rng, 0.5)
    cap = prism([ring(w - 0.6, d - 0.6, 2, t), ring(w - 0.6, d - 0.6, 2, h - 1.5), ring(w - 3, d - 3, 1.5, h)], rng, 0.4)
    # keep the inner face (-z) flat on the wall line: no vertex in front of it
    for v, _ in (body, cap):
        v[:, 2] = np.maximum(v[:, 2], -d / 2)
    return [("Rock", ROCK, body), ("Top", TOP, cap)]


def ico(r, sq):
    g = (1 + 5 ** 0.5) / 2
    v = np.array([(-1, g, 0), (1, g, 0), (-1, -g, 0), (1, -g, 0), (0, -1, g), (0, 1, g), (0, -1, -g), (0, 1, -g),
                  (g, 0, -1), (g, 0, 1), (-g, 0, -1), (-g, 0, 1)], float)
    v = v / np.linalg.norm(v[0]) * r
    v[:, 1] *= sq
    f = [(0, 11, 5), (0, 5, 1), (0, 1, 7), (0, 7, 10), (0, 10, 11), (1, 5, 9), (5, 11, 4), (11, 10, 2), (10, 7, 6), (7, 1, 8),
         (3, 9, 4), (3, 4, 2), (3, 2, 6), (3, 6, 8), (3, 8, 9), (4, 9, 5), (2, 4, 11), (6, 2, 10), (8, 6, 7), (9, 8, 1)]
    return v, f


def bush(rng):
    """Three squashed low-poly balls of leaves."""
    out = []
    for k, (ox, oz, r) in enumerate([(0, 0, 4), (3.2, 1, 3), (-3, 0.6, 3.2)]):
        v, f = ico(r, 0.7)
        v = v + np.array([ox, r * 0.55, oz])
        out.append(("Leaves%d" % (k + 1), LEAF if k == 0 else LEAF2, (v, f)))
    return out


VARIANTS = [(20, 20, 34), (24, 22, 38), (18, 20, 40), (22, 24, 44), (26, 22, 36), (20, 22, 42)]  # (w, d, h above the foot)


def meshes():
    rng = np.random.default_rng(SEED)
    out = {"Cliff%d" % (k + 1): cliff(w, d, h, rng) for k, (w, d, h) in enumerate(VARIANTS)}
    out["Bush"] = bush(rng)
    return out


def write_meshes(ms, folder):
    os.makedirs(folder, exist_ok=True)
    lines = ["# piece: label, RGB"]
    for name, pieces in ms.items():
        for k, (label, rgb, (v, f)) in enumerate(pieces):
            key = "%s_%d" % (name, k + 1)
            with open(os.path.join(folder, key + ".obj"), "w") as fh:
                for p in v:
                    fh.write("v %.3f %.3f %.3f\n" % tuple(p))
                for face in f:
                    fh.write("f " + " ".join(str(a + 1) for a in face) + "\n")
            lines.append("%s: %s, %d, %d, %d" % (key, label, *rgb))
    open(os.path.join(folder, "colours.txt"), "w").write("\n".join(lines) + "\n")


def walls():
    """The old walls' inner lines, as (start, end, inward normal): the cliffs stand outside them."""
    return [((X0, Z0), (X0, Z1), (1, 0)), ((X0, Z1), (X1, Z1), (0, -1)), ((X1, Z1), (X1, Z0), (-1, 0)),
            ((X1, Z0), (GATE + 8, Z0), (0, 1)), ((-GATE - 8, Z0), (X0, Z0), (0, 1))]


def place_cliffs(rng):
    """Blocks shoulder to shoulder along each wall, inner faces on its line, tops varied."""
    out = []  # (name, x, z, yaw, scale y)
    for (ax, az), (bx, bz), (nx, nz) in walls():
        L = math.hypot(bx - ax, bz - az)
        ux, uz = (bx - ax) / L, (bz - az) / L
        s = -6.0  # (past the corner, so corners close)
        while s < L + 4:
            k = int(rng.integers(0, len(VARIANTS)))
            w, d, h = VARIANTS[k]
            sy = rng.uniform(0.85, 1.12)
            c = s + w / 2
            back = d / 2 + rng.uniform(0, 1.5)  # the inner face on the line, or a hair behind it
            x, z = ax + ux * c - nx * back, az + uz * c - nz * back
            yaw = math.degrees(math.atan2(nx, nz)) + 180  # (its -z face toward the base)
            if z < Z0 + 1 and abs(x) < GATE + 56:  # rising to the course's 48-high walls at the mouth
                f = max(0.0, 1 - (abs(x) - GATE - 8) / 48)
                sy = max(sy, f * (48 - CLIFF_FOOT) / h)
            out.append(("Cliff%d" % (k + 1), x, z, yaw, sy))
            # now and then a taller block behind it, for a stepped skyline
            if rng.random() < 0.45:
                k2 = int(rng.integers(0, len(VARIANTS)))
                w2, d2, _ = VARIANTS[k2]
                b2 = d + d2 / 2 - 4
                out.append(("Cliff%d" % (k2 + 1), ax + ux * (c + rng.uniform(-4, 4)) - nx * b2, az + uz * (c + rng.uniform(-4, 4)) - nz * b2, yaw + rng.uniform(-8, 8), sy * rng.uniform(1.15, 1.35)))
            s += w - 3
    return out


def top_of(name, sy):
    return CLIFF_FOOT + VARIANTS[int(name[5:]) - 1][2] * sy


def place_greens(cl, rng):
    """Bushes on about half the front blocks' tops, a small palm on one in eight."""
    out = []
    for name, x, z, yaw, sy in cl:
        r = rng.random()
        if r < 0.5:
            out.append(("Bush", x + rng.uniform(-3, 3), top_of(name, sy) - 0.5, z + rng.uniform(-3, 3), rng.uniform(0, 360), rng.uniform(0.9, 1.4)))
        elif r < 0.62:
            out.append(("PalmTreeSmall", x, top_of(name, sy) - 0.5, z, rng.uniform(0, 360), 1.5))
    return out


# ---- output -----------------------------------------------------------------------------------

def floor_parts(kind):
    out = []
    for k, i0, j0, i1, j1 in rects(kind):
        name, top = TILES[int(k)]
        out.append((name, X0 + i0 * C, Z0 + j0 * C, (i1 - i0) * C, (j1 - j0) * C, top))
    return out


def write_luau(kind, cl, greens, path):
    body = open(os.path.join(HERE, "world3_cove_base.luau.in")).read()
    body = (body.replace("--FLOOR--", "\n".join('\t{ "%s", %d, %d, %d, %d, %d },' % p for p in floor_parts(kind)))
            .replace("--CLIFFS--", "\n".join('\t{ "%s", %.1f, %.1f, %.1f, %.3f },' % p for p in cl))
            .replace("--GREENS--", "\n".join('\t{ "%s", %.1f, %.1f, %.1f, %.1f, %.2f },' % p for p in greens))
            .replace("--SEA_TOP--", str(SEA_TOP)).replace("--CLIFF_FOOT--", str(CLIFF_FOOT)))
    open(path, "w").write(body)


def overhead(kind, cl, greens, pens, decor, path, s=2):
    pad = 60
    W, H = (X1 - X0 + 2 * pad) * s, (Z1 - Z0 + 2 * pad) * s
    im = Image.new("RGB", (W, H), VIEW[WATER])
    d = ImageDraw.Draw(im)

    def P(x, z):  # back wall at the top, the course's mouth at the bottom
        return (x - X0 + pad) * s, (Z1 - z + pad) * s

    for i in range(NX):
        for j in range(NZ):
            x, z = X0 + i * C, Z0 + j * C
            col = VIEW[int(kind[i, j])]
            if (i + j) % 2 and kind[i, j] != WATER:
                col = tuple(v - 8 for v in col)
            a, b = P(x, z + C)
            d.rectangle([a, b, a + C * s - 1, b + C * s - 1], fill=col)
    d.rectangle([*P(-GATE, Z0), *P(GATE, Z0 - pad)], fill=VIEW[SAND])
    for name, x, z, yaw, sy in sorted(cl, key=lambda c: top_of(c[0], c[4])):
        w, dd, _ = VARIANTS[int(name[5:]) - 1]
        a = math.radians(yaw)
        pts = []
        for cx, cz in ((-w / 2, -dd / 2), (w / 2, -dd / 2), (w / 2, dd / 2), (-w / 2, dd / 2)):
            pts.append(P(x + cx * math.cos(a) + cz * math.sin(a), z - cx * math.sin(a) + cz * math.cos(a)))
        t = (top_of(name, sy) - 8) / 30
        d.polygon(pts, fill=tuple(int(v * (0.85 + 0.15 * t)) for v in TOP), outline=ROCK)
    for name, x, y, z, *_ in greens:
        r = 5 if name == "Bush" else 8
        a, b = P(x, z)
        d.ellipse([a - r * s, b - r * s, a + r * s, b + r * s], fill=LEAF)
    for name, px, pz, sx, sz, yaw in pens:
        a = math.radians(yaw)
        pts = [P(px + u * math.cos(a) + v * math.sin(a), pz - u * math.sin(a) + v * math.cos(a)) for u, v in
               ((-sx / 2, -sz / 2), (sx / 2, -sz / 2), (sx / 2, sz / 2), (-sx / 2, sz / 2))]
        d.polygon(pts, outline=(120, 70, 30), width=3)
        d.text(P(px, pz), name, fill=(60, 40, 20))
    for name, x, z, r in decor:
        a, b = P(x, z)
        d.ellipse([a - r * s, b - r * s, a + r * s, b + r * s], outline=(30, 110, 40), width=2)
    im.save(path)


def rider(kind, ms, cl, greens, palm, path, eye, target):
    import partlib
    from partlib import Part
    parts = []
    for name, x0, z0, sx, sz, top in floor_parts(kind):
        parts.append(Part(name, (sx, top + 3, sz), partlib.T(x0 + sx / 2, (top - 3) / 2, z0 + sz / 2), VIEW[[k for k, t in TILES.items() if t[0] == name][0]]))
    parts.append(Part("Mouth", (2 * GATE, 3, 200), partlib.T(0, -0.5, -100), VIEW[SAND]))
    for sg in (-1, 1):
        parts.append(Part("CourseWall", (8, 48, 200), partlib.T(sg * (GATE + 4), 24, -100), TOP))  # (Config's WallColors)
    for x0, x1, z0, z1 in ((-1500, X0 - 30, -400, 1500), (X1 + 30, 1500, -400, 1500), (X0 - 30, X1 + 30, Z1 + 30, 1500)):
        parts.append(Part("Sea", (x1 - x0, 2, z1 - z0), partlib.T((x0 + x1) / 2, SEA_TOP - 1, (z0 + z1) / 2), VIEW[WATER]))

    def mesh(pieces, cf):
        for label, rgb, (v, f) in pieces:
            vv = (cf[:3, :3] @ v.T).T + cf[:3, 3]
            for face in f:
                for a in range(1, len(face) - 1):
                    t = np.array([vv[face[0]], vv[face[a]], vv[face[a + 1]]])
                    n = np.cross(t[1] - t[0], t[2] - t[0])
                    ln = np.linalg.norm(n)
                    if ln < 1e-9:
                        continue
                    inner = t.mean(0) - n / ln * 0.5
                    p = Part(label, (1, 1, 1), np.eye(4), rgb, shape="Poly")
                    p.polys = [t, np.array([inner, inner, inner])]
                    parts.append(p)

    for name, x, z, yaw, sy in cl:
        mesh(ms[name], partlib.T(x, CLIFF_FOOT, z) @ partlib.Ry(yaw) @ np.diag([1, sy, 1, 1.0]))
    for name, x, y, z, yaw, sc in greens:
        pieces = ms["Bush"] if name == "Bush" else palm
        mesh(pieces, partlib.T(x, y, z) @ partlib.Ry(yaw) @ np.diag([sc, sc, sc, 1.0]))
    img = partlib.render(parts, eye=eye, target=target, W=1280, H=720, fov=60, fog=False, outline=False, ground=False, studs=False)
    img.save(path)


def load_palm(meshes):
    base = os.path.join(meshes, "design", "pirate", "pieces")
    out = []
    for line in open(os.path.join(base, "colours.txt")):
        if not line.startswith("PalmTreeSmall_"):
            continue
        key, rest = line.split(":", 1)
        rgb = tuple(int(v) for v in rest.split(",")[1:4])
        v, f = [], []
        for row in open(os.path.join(base, key.strip() + ".obj")):
            if row.startswith("v "):
                v.append([float(t) for t in row.split()[1:4]])
            elif row.startswith("f "):
                f.append(tuple(int(t.split("/")[0]) - 1 for t in row.split()[1:]))
        out.append((key, rgb, (np.array(v), f)))
    return out


def main():
    argv = sys.argv[1:]
    if "--views" in argv:
        k = argv.index("--views")
        argv = argv[:k] + argv[k + 2:]
    args = argv
    dump = args[0] if args else "/mnt/project-files/world3_base_dump.json"
    out = args[1] if len(args) > 1 else "/mnt/project-files/world3/cove_base"
    os.makedirs(out, exist_ok=True)
    pens, decor, spawn = load(dump)
    rng = np.random.default_rng(SEED)
    block = blocked(pens, decor, spawn)
    water = pools(block, rng)
    kind = floor(water)
    ms = meshes()
    write_meshes(ms, os.path.join(HERE, "..", "design", "w3_base", "pieces"))
    cl = place_cliffs(np.random.default_rng(SEED + 1))
    greens = place_greens(cl, np.random.default_rng(SEED + 2))
    write_luau(kind, cl, greens, os.path.join(HERE, "world3_cove_base.luau"))
    overhead(kind, cl, greens, pens, decor, os.path.join(out, "top_down.png"))
    print("pools", int(water.sum()), "cells; floor parts", len(floor_parts(kind)), "; cliffs", len(cl), "; greens", len(greens))
    if "--views" in sys.argv:
        palm = load_palm(sys.argv[sys.argv.index("--views") + 1])
        rider(kind, ms, cl, greens, palm, os.path.join(out, "view_from_start.png"), (0, 12, -6), (0, 6, 120))
        rider(kind, ms, cl, greens, palm, os.path.join(out, "view_to_mouth.png"), (0, 14, 200), (40, 4, 40))
        rider(kind, ms, cl, greens, palm, os.path.join(out, "view_aerial.png"), (-180, 150, -120), (0, 0, 170))


if __name__ == "__main__":
    main()
