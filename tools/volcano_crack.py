"""The volcano's big lava crack (QM, Oct 10: the ViewportStencil demo's crack, recoloured,
3x; Oct 11: at the end of the volcano, a geyser later, nothing yet).

Run: python3 tools/volcano_crack.py
Writes design/volcano/VolcanoCrack.gltf: the two meshes ViewportStencil
(src/shared/ViewportStencil) needs, in studs, the floor's top at y = 0:
  CrackMask    a flat square with the crack's opening cut out, every vertex's
               alpha 0: not drawn, but it hides the inside everywhere but the opening
  CrackInside  walls straight down from the opening's edge and a flat bottom,
               vertex coloured scorched red at the rim to hot yellow at the bottom
The outline is the approved render's (design/lava_biome, seed 100, 48 studs).
"""
import base64
import json
import math
import os
import struct

import numpy as np
from shapely import constrained_delaunay_triangles
from shapely.geometry import Point, Polygon, box
from shapely.ops import unary_union

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "design", "volcano", "VolcanoCrack.gltf")
SIZE, SEED = 48, 100
DEPTH = SIZE * 0.55
MASK_MARGIN = 1.15  # the mask square is this much wider than the opening
# down the walls: (fraction of the depth, colour), the bottom's colour
WALL = [(0.0, (164, 46, 22)), (0.45, (255, 116, 22)), (1.0, (255, 196, 70))]
BOTTOM = (255, 220, 110)


def outline(size, rng):
    """A jagged body with curling tendrils (as design/lava_biome demo_outline)."""
    shapes = []
    r0 = size * 0.42
    body = []
    n = 14
    for i in range(n):
        a = 2 * math.pi * i / n + rng.uniform(-0.12, 0.12)
        r = r0 * (rng.uniform(1.1, 1.45) if i % 2 else rng.uniform(0.6, 0.85))
        body.append((r * math.cos(a), r * math.sin(a)))
    shapes.append(Polygon(body))
    nt = int(rng.integers(5, 8))
    for i in range(nt):
        a = 2 * math.pi * i / nt + rng.uniform(-0.35, 0.35)
        x, z = r0 * 0.6 * math.cos(a), r0 * 0.6 * math.sin(a)
        steps = int(rng.integers(3, 5))
        bend = rng.uniform(-0.5, 0.5)
        w = size * rng.uniform(0.08, 0.12)
        left, right = [], []
        for k in range(steps + 1):
            nx, nz = -math.sin(a), math.cos(a)
            ww = w * (1 - k / steps) ** 1.3
            left.append((x + nx * ww, z + nz * ww))
            right.append((x - nx * ww, z - nz * ww))
            ln = size * rng.uniform(0.14, 0.22)
            x, z = x + ln * math.cos(a), z + ln * math.sin(a)
            a += bend + rng.uniform(-0.35, 0.35)
        shapes.append(Polygon(left + right[::-1]).buffer(0))
    u = unary_union(shapes)
    if u.geom_type != "Polygon":
        u = max(u.geoms, key=lambda g: g.area)
    return u.simplify(0.05)


def lin(c):
    """sRGB 0-255 to linear 0-1 (glTF vertex colours are linear)."""
    out = []
    for v in c:
        v /= 255
        out.append(v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4)
    return out


def tris_of(poly):
    """Triangles filling a polygon (holes too), as lists of (x, z)."""
    out = []
    for t in constrained_delaunay_triangles(poly).geoms:
        if poly.contains(t.representative_point()):
            out.append(list(t.exterior.coords)[:3])
    return out


class Mesh:
    def __init__(self):
        self.pos, self.nrm, self.col, self.idx = [], [], [], []

    def tri(self, a, b, c, ca, cb, cc, up=None):
        """One flat triangle; turned so its normal is up (or faces `up`, a point)."""
        a, b, c = map(np.array, (a, b, c))
        n = np.cross(b - a, c - a)
        n /= np.linalg.norm(n)
        want = np.array([0, 1.0, 0]) if up is None else np.array(up) - (a + b + c) / 3
        if np.dot(n, want) < 0:
            b, c, cb, cc, n = c, b, cc, cb, -n
        k = len(self.pos)
        for p, col in ((a, ca), (b, cb), (c, cc)):
            self.pos.append(p)
            self.nrm.append(n)
            self.col.append(col)
        self.idx += [k, k + 1, k + 2]


def build():
    poly = outline(SIZE, np.random.default_rng(SEED))
    ring = list(poly.exterior.coords)[:-1]
    mask, inside = Mesh(), Mesh()
    x0, z0, x1, z1 = poly.bounds
    half = max(abs(x0), abs(x1), abs(z0), abs(z1)) * MASK_MARGIN
    clear = [1.0, 1.0, 1.0, 0.0]
    for t in tris_of(box(-half, -half, half, half).difference(poly)):
        mask.tri(*[(x, 0, z) for x, z in t], clear, clear, clear)
    bottom = lin(BOTTOM) + [1.0]
    for t in tris_of(poly):
        inside.tri(*[(x, -DEPTH, z) for x, z in t], bottom, bottom, bottom)
    rows = [(f, lin(c) + [1.0]) for f, c in WALL]
    for i in range(len(ring)):
        (ax, az), (bx, bz) = ring[i], ring[(i + 1) % len(ring)]
        dx, dz = bx - ax, bz - az
        ln = math.hypot(dx, dz)
        if ln < 1e-6:
            continue
        nx, nz = -dz / ln, dx / ln
        if not poly.contains(Point((ax + bx) / 2 + nx * 0.02, (az + bz) / 2 + nz * 0.02)):
            nx, nz = -nx, -nz
        for (f0, c0), (f1, c1) in zip(rows, rows[1:]):
            y0, y1 = -DEPTH * f0, -DEPTH * f1
            face = ((ax + bx) / 2 + nx, (y0 + y1) / 2, (az + bz) / 2 + nz)  # (into the crack)
            inside.tri((ax, y0, az), (bx, y0, bz), (bx, y1, bz), c0, c0, c1, face)
            inside.tri((ax, y0, az), (bx, y1, bz), (ax, y1, az), c0, c1, c1, face)
    return mask, inside, half


def write_gltf(meshes, path):
    buf = bytearray()
    views, accessors, gmeshes, nodes = [], [], [], []

    def add(data, fmt, count, kind, comp, target, minmax=None):
        while len(buf) % 4:
            buf.append(0)
        off = len(buf)
        for row in data:
            buf.extend(struct.pack(fmt, *(row if isinstance(row, (list, tuple, np.ndarray)) else [row])))
        views.append({"buffer": 0, "byteOffset": off, "byteLength": len(buf) - off, "target": target})
        acc = {"bufferView": len(views) - 1, "componentType": comp, "count": count, "type": kind}
        if minmax:
            acc["min"], acc["max"] = minmax
        accessors.append(acc)
        return len(accessors) - 1

    for name, m in meshes:
        pos = np.array(m.pos, float)
        p = add(pos.tolist(), "<3f", len(pos), "VEC3", 5126, 34962, (pos.min(0).tolist(), pos.max(0).tolist()))
        n = add(np.array(m.nrm).tolist(), "<3f", len(m.nrm), "VEC3", 5126, 34962)
        c = add(m.col, "<4f", len(m.col), "VEC4", 5126, 34962)
        i = add(m.idx, "<I", len(m.idx), "SCALAR", 5125, 34963)
        gmeshes.append({"name": name, "primitives": [{"attributes": {"POSITION": p, "NORMAL": n, "COLOR_0": c},
                                                      "indices": i, "material": 0}]})
        nodes.append({"name": name, "mesh": len(gmeshes) - 1})
    doc = {
        "asset": {"version": "2.0", "generator": "tools/volcano_crack.py"},
        "scene": 0, "scenes": [{"name": "VolcanoCrack", "nodes": list(range(len(nodes)))}],
        "nodes": nodes, "meshes": gmeshes,
        "materials": [{"name": "VertexColour", "pbrMetallicRoughness": {"baseColorFactor": [1, 1, 1, 1],
                                                                         "metallicFactor": 0, "roughnessFactor": 1},
                       "alphaMode": "BLEND", "doubleSided": False}],
        "buffers": [{"byteLength": len(buf),
                     "uri": "data:application/octet-stream;base64," + base64.b64encode(bytes(buf)).decode()}],
        "bufferViews": views, "accessors": accessors,
    }
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        json.dump(doc, f)


if __name__ == "__main__":
    mask, inside, half = build()
    write_gltf([("CrackMask", mask), ("CrackInside", inside)], OUT)
    print("wrote", OUT, f"mask {2 * half:.1f} x {2 * half:.1f} studs ({len(mask.idx) // 3} tris),",
          f"inside {len(inside.idx) // 3} tris, {DEPTH:.1f} deep")
