"""QM (Oct 10): the mesh Boulder on each of the 4 dirt patches between the pens.
The live floor and rocks come from stamina-loop's tools/arc_base.luau (copied here as
live_arc_base.luau); rock_meshes.py is the rock-meshes branch's mesh builder."""
import math
import os
import re
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import base_life as B  # noqa: E402
from base_life import A, Part, T  # noqa: E402
import rock_meshes as RM  # noqa: E402

SRC = open(os.path.join(HERE, "live_arc_base.luau")).read()
FLOOR = [tuple(map(int, m)) for m in re.findall(r"\{ ([01]), (-?\d+), (-?\d+), (\d+), (\d+) \}", SRC)]
ROCKS = [(n, float(x), float(z), float(y)) for n, x, z, y in
         re.findall(r'\{ "(\w+)", (-?[\d.]+), (-?[\d.]+), (-?[\d.]+) \}', SRC.split("local ROCKS")[1].split("}\n")[0] + "}\n")]
SCALE = 2.5
COLOR = (159, 161, 172)
BUILDERS = {name[4:]: (fn, seed) for name, fn, seed, _ in RM.ROCKS}


def dirt_at(x, z):
    for d, lx, lz, sx, sz in FLOOR:
        if lx <= x < lx + sx and lz <= z < lz + sz:
            return d
    return 0


def floor():
    out = []
    for d, lx, lz, sx, sz in FLOOR:
        for x in range(lx, lx + sx, 4):
            for z in range(lz, lz + sz, 4):
                top = -1 if d else 0
                k = (x // 4 + z // 4) % 2
                out.append(Part("Floor", (4, top + 2, 4), T(x + 2, (top - 2) / 2, z + 2), (A.GRASS, A.DIRT)[d][k]))
    return out


def patches():
    """Dirt components outside the yard (between the pens): centroids."""
    cells = {(x, z) for d, lx, lz, sx, sz in FLOOR if d
             for x in range(lx, lx + sx, 8) for z in range(lz, lz + sz, 8)}
    seen, comps = set(), []
    for c in cells:
        if c in seen:
            continue
        st, comp = [c], []
        seen.add(c)
        while st:
            x, z = st.pop()
            comp.append((x, z))
            for n in ((x + 8, z), (x - 8, z), (x, z + 8), (x, z - 8)):
                if n in cells and n not in seen:
                    seen.add(n)
                    st.append(n)
        comps.append(comp)
    comps.sort(key=len)
    return [(np.mean([x + 4 for x, _ in c]), np.mean([z + 4 for _, z in c]), len(c)) for c in comps]


def rock(name, x, z, yaw, scale=SCALE):
    fn, seed = BUILDERS[name]
    chunks = [[t * scale for t in tris] for tris in RM.build(fn, seed)]
    top = -1 if dirt_at(x, z) else 0
    parts = RM.as_parts(chunks, x, z, yaw=yaw, color=COLOR)
    for p in parts:
        p.cf = T(0, top, 0) @ p.cf
    return parts


def scene(spots):
    parts = floor() + A.wall_parts()
    for p in A.pens():
        parts += B.pen_floor(p) + A.fence(p)
    for n, x, z, yaw in ROCKS:
        parts += rock(n, x, z, yaw)
    for x, z, yaw in spots:
        parts += rock("Boulder", x, z, yaw)
    k = B.TA.Kit()
    k.box("Carl", (-112, 0, 16), (-96, 9, 24), (240, 210, 170))
    k.box("Podium", (98, 0, 14), (110, 3, 26), (230, 60, 60))
    k.box("Podium", (99, 3, 15), (109, 5, 25), (245, 245, 245))
    return parts + k.parts




def main():
    spots = [(x, z, yaw) for (x, z, _), yaw in zip(patches()[:4], (-20, 20, 60, -60))]
    parts = scene(spots)
    for view in sys.argv[1:] or ["top", "home"]:
        B.shoot(parts, "mesh_boulders", view, "Boulders on the dirt patches")
    B.shoot(scene([]), "mesh_now", "top", "Now")


if __name__ == "__main__":
    main()
