"""Stone portal gate (QM, Oct 12): the archway from QM's reference as one low-poly,
studded mesh in the rock meshes' style (tools/rock_meshes.py). Stone only: the opening
is left empty (no swirl).

Built from chamfered, slightly jittered stone blocks (each a convex hull): a two-step
base, two pillars (plinth, shaft with a raised panel, stepped capital) and a round arch
of chunky blocks with a pointed keystone at the crown. Studs, y up, base at y = 0, the
gate faces -z (Roblox front), the opening centred on x = 0.

Run: python3 tools/portal_gate.py
Writes design/portal/PortalGate.obj (the whole gate), design/portal/pieces/PortalGate_<i>.obj
(one per stone, same origin, each its own shade: pieces/shades.txt) and design/portal/portal_gate.png.
Import like the rocks (Import 3D, studs; MeshPart, rock colour, stud material).
"""

import math
import os
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import partlib  # noqa: E402
from partlib import Part, render  # noqa: E402
import terrain_assets as TA  # noqa: E402
from rock_meshes import ROCK, hull_tris, write_obj, as_parts  # noqa: E402

OUT = os.path.join(HERE, "..", "design", "portal")
RNG = np.random.default_rng(12)

OPEN_HALF = 7.0      # half the opening between the pillar shafts at the arch's spring
SHAFT = 6.0          # pillar shaft width (square)
DEPTH = 6.0          # pillar / arch depth (front to back)
BASE_H = (1.4, 1.4)  # the two base steps


# corners of a hexahedron in this order: (x-, y-, z-), (x+, y-, z-), (x+, y+, z-), (x-, y+, z-),
# then the same four at z+; each corner's three edge neighbours:
NEIGH = {0: (1, 3, 4), 1: (0, 2, 5), 2: (1, 3, 6), 3: (0, 2, 7),
         4: (5, 7, 0), 5: (4, 6, 1), 6: (5, 7, 2), 7: (4, 6, 3)}


def block(corners, chamfer=0.35, jitter=0.12):
    """A chamfered stone: each corner jittered, then cut back toward its three
    neighbours by `chamfer` studs (convex hull of those 24 points)."""
    c = np.array(corners, float) + RNG.uniform(-jitter, jitter, (8, 3))
    pts = []
    for i in range(8):
        for j in NEIGH[i]:
            d = c[j] - c[i]
            pts.append(c[i] + d / np.linalg.norm(d) * min(chamfer * RNG.uniform(0.7, 1.4), np.linalg.norm(d) * 0.3))
    return np.array(pts)


def box(x0, y0, z0, x1, y1, z1, chamfer=0.35, jitter=0.12):
    return block([(x0, y0, z0), (x1, y0, z0), (x1, y1, z0), (x0, y1, z0),
                  (x0, y0, z1), (x1, y0, z1), (x1, y1, z1), (x0, y1, z1)], chamfer, jitter)


def row(x0, x1, y0, y1, z0, z1, n, chamfer=0.4):
    """A course of n stone slabs side by side with uneven joints."""
    cuts = np.linspace(x0, x1, n + 1)
    cuts[1:-1] += RNG.uniform(-0.18, 0.18, n - 1) * (x1 - x0) / n
    return [box(cuts[i] + 0.05, y0, z0 + RNG.uniform(-0.15, 0.15), cuts[i + 1] - 0.05,
                y1 + RNG.uniform(-0.15, 0.1), z1 + RNG.uniform(-0.15, 0.15), chamfer) for i in range(n)]


def gate():
    chunks = []
    hx = OPEN_HALF + SHAFT  # outer face of each shaft
    d2 = DEPTH / 2
    # the two-step base: a wide bottom course, a narrower one on it
    y = 0.0
    chunks += row(-hx - 4.2, hx + 4.2, -0.6, y + BASE_H[0], -d2 - 3.6, d2 + 2.0, 5)
    y += BASE_H[0]
    chunks += row(-hx - 2.2, hx + 2.2, y - 0.2, y + BASE_H[1], -d2 - 1.6, d2 + 1.0, 4)
    y += BASE_H[1]
    for s in (-1, 1):
        x_in, x_out = s * OPEN_HALF, s * hx
        lo, hi = min(x_in, x_out), max(x_in, x_out)
        # plinth: a chunky block wider than the shaft
        chunks.append(box(lo - 0.8, y - 0.2, -d2 - 0.8, hi + 0.8, y + 4.6, d2 + 0.8, 0.5))
        chunks.append(box(lo - 0.4, y + 4.6, -d2 - 0.4, hi + 0.4, y + 5.6, d2 + 0.4, 0.3))
        # shaft, with a raised panel on its front face
        chunks.append(box(lo, y + 5.6, -d2, hi, y + 12.0, d2, 0.3))
        chunks.append(box(lo + 1.1, y + 6.6, -d2 - 0.7, hi - 1.1, y + 11.0, -d2 + 0.6, 0.25, 0.05))
        # stepped capital
        chunks.append(box(lo - 0.4, y + 12.0, -d2 - 0.4, hi + 0.4, y + 13.0, d2 + 0.4, 0.3))
        chunks.append(box(lo - 0.9, y + 13.0, -d2 - 0.9, hi + 0.9, y + 14.2, d2 + 0.9, 0.35))
    spring = y + 14.2
    # the arch: a half ring of chunky blocks over the opening, its ends on the capitals
    r_in, r_out = OPEN_HALF + 0.2, hx + 1.4
    n = 7  # the keystone takes the middle slot
    edges = np.linspace(0, math.pi, n + 1)
    edges[1:-1] += RNG.uniform(-0.05, 0.05, n - 1)
    zf, zb = -d2 - 0.5, d2 + 0.5
    for i in range(n):
        a0, a1 = edges[i] + 0.012, edges[i + 1] - 0.012
        ro = r_out + RNG.uniform(-0.3, 0.4)
        if i == n // 2:  # the keystone: taller, pokes out at the front, pointed below
            am = (a0 + a1) / 2
            w = 2.0
            top = spring + r_out + 1.4
            bot = spring + r_in - 2.4
            pts = []
            for z in (zf - 0.6, zb):
                pts += [(-w, top, z), (w, top, z), (-w * 1.15, spring + r_in + 0.6, z),
                        (w * 1.15, spring + r_in + 0.6, z), (0, bot, z)]
            k = np.array(pts) + RNG.uniform(-0.08, 0.08, (len(pts), 3))
            chunks.append(k)
            continue
        cs = [(math.cos(a), math.sin(a)) for a in (a0, a1)]
        # corner order as block(): inner/outer at the two ends, front then back
        def P(cs_, r, z):
            return (cs_[0] * r, spring + cs_[1] * r, z)
        corners = [P(cs[0], r_in, zf), P(cs[1], r_in, zf), P(cs[1], ro, zf), P(cs[0], ro, zf),
                   P(cs[0], r_in, zb), P(cs[1], r_in, zb), P(cs[1], ro, zb), P(cs[0], ro, zb)]
        chunks.append(block(corners, 0.4))
    band = len(chunks)
    # a thin inner band under the arch (the reference's moulding), set back a little
    for i in range(n):
        a0, a1 = edges[i] + 0.01, edges[i + 1] - 0.01
        cs = [(math.cos(a), math.sin(a)) for a in (a0, a1)]
        r0, r1 = r_in - 0.7, r_in + 0.1
        zf2, zb2 = -d2 + 0.6, d2 - 0.6
        def Q(c, r, z):
            return (c[0] * r, spring + c[1] * r, z)
        chunks.append(block([Q(cs[0], r0, zf2), Q(cs[1], r0, zf2), Q(cs[1], r1, zf2), Q(cs[0], r1, zf2),
                             Q(cs[0], r0, zb2), Q(cs[1], r0, zb2), Q(cs[1], r1, zb2), Q(cs[0], r1, zb2)], 0.15, 0.04))
    tris = [hull_tris(c) for c in chunks]
    # the pieces (QM, Oct 12: each stone its own shade, like the rocks): one per stone,
    # the inner band as one piece; each a list of hulls
    return tris, [[t] for t in tris[:band]] + [tris[band:]]


def shades(n, seed=5):
    """A shade index per piece (the meadow rock's five, tools/biome_rocks.SHADES),
    never the same twice in a row."""
    rng = np.random.default_rng(seed)
    out = []
    for _ in range(n):
        out.append(int(rng.choice([k for k in range(5) if not out or k != out[-1]])))
    return out


def main():
    os.makedirs(OUT, exist_ok=True)
    chunks, pieces = gate()
    nt = write_obj("PortalGate", chunks, os.path.join(OUT, "PortalGate.obj"))
    # each piece its own OBJ, same origin as the whole gate (Studio uploads them, one
    # MeshPart each, all at the gate's CFrame) in its shade (PIECE_SHADES)
    import biome_rocks as BR
    pdir = os.path.join(OUT, "pieces")
    os.makedirs(pdir, exist_ok=True)
    for f in os.listdir(pdir):
        os.remove(os.path.join(pdir, f))
    idx = shades(len(pieces))
    for i, piece in enumerate(pieces):
        write_obj(f"PortalGate_{i + 1}", piece, os.path.join(pdir, f"PortalGate_{i + 1}.obj"))
    cols = [BR.SHADES["Meadow"][k] for k in idx]
    with open(os.path.join(pdir, "shades.txt"), "w") as f:
        f.write("# piece: RGB (the meadow rock shades, tools/biome_rocks.SHADES)\n")
        f.writelines(f"PortalGate_{i + 1}: {c[0]}, {c[1]}, {c[2]}\n" for i, c in enumerate(cols))
    print(f"{len(pieces)} pieces")
    pts = np.concatenate([np.concatenate(t) for t in chunks])
    size = pts.max(0) - np.array([pts.min(0)[0], 0, pts.min(0)[2]])
    print(f"PortalGate: {nt} tris, {size[0]:.1f} x {size[1]:.1f} x {size[2]:.1f} studs")
    partlib.GROUND = np.array((105, 255, 74), float)
    partlib.GROUND2 = np.array((77, 196, 63), float)
    k = TA.Kit()
    TA.figure(k, 0)
    fig = [Part(p.name, p.size, partlib.T(-3, 2.8, -8) @ p.cf, p.color) for p in k.parts]
    parts = [p for piece, c in zip(pieces, cols) for p in as_parts(piece, color=c)] + fig
    from PIL import Image
    a = render(parts, eye=(-30, 18, -62), target=(0, 13, 0), W=900, H=900, fov=42, fog=False, outline=False)
    b = render(parts, eye=(0, 14, -70), target=(0, 14, 0), W=900, H=900, fov=40, fog=False, outline=False)
    out = Image.new("RGB", (1800, 900))
    out.paste(a, (0, 0))
    out.paste(b, (900, 0))
    out.save(os.path.join(OUT, "portal_gate.png"))


if __name__ == "__main__":
    main()
