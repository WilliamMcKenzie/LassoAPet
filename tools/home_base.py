"""Resize the home base in src/world/World.rbxmx to fit the grown pens (QM, Oct 3).

Run: python3 tools/home_base.py

The base is x -HALF_W..HALF_W, z 0..DEPTH inside its walls (tools/pens.py), with
the course corridor (x -56..56) opening at z = 0. Moves and resizes the home
floor, the back, side and front walls and their caps. Edges stay on the 8-stud
grid so the wall checker lines up (tools/check_walls.py). Safe to rerun.
"""

import os
import re
import sys

sys.path.insert(0, os.path.dirname(__file__))
from desert_ground import WORLD, item_span  # noqa: E402
from pens import HALF_W as W, DEPTH as D  # noqa: E402

CORRIDOR = 56
# referent: (centre, size)
LAYOUT = {
    "RBX00000006": ((0, -1, (D + 8) / 2), (2 * W, 2, D + 8)),  # floor, under the back wall too
    "RBX00000014": ((0, 24, D + 4), (2 * W + 16, 48, 8)),  # back wall
    "RBX0000001D": ((0, 49, D + 3), (2 * W + 16, 2, 10)),
    "RBX00000032": ((-W - 4, 24, D / 2 - 4), (8, 48, D + 8)),  # left wall
    "RBX0000003B": ((-W - 3, 49, D / 2), (10, 2, D - 4)),
    "RBX00000050": ((W + 4, 24, D / 2 - 4), (8, 48, D + 8)),  # right wall
    "RBX00000059": ((W + 3, 49, D / 2), (10, 2, D - 4)),
    "RBX00000028": ((-(W + CORRIDOR) / 2, 24, -4), (W - CORRIDOR, 48, 8)),  # front walls
    "RBX00000031": ((-(W + CORRIDOR + 6) / 2, 49, -3), (W - CORRIDOR + 10, 2, 10)),
    "RBX00000046": (((W + CORRIDOR) / 2, 24, -4), (W - CORRIDOR, 48, 8)),
    "RBX0000004F": (((W + CORRIDOR + 6) / 2, 49, -3), (W - CORRIDOR + 10, 2, 10)),
}


def main():
    s = open(WORLD).read()
    for ref, (c, size) in LAYOUT.items():
        a = s.index(f'<Item class="Part" referent="{ref}">')
        b = item_span(s, a)
        xml = s[a:b]
        xml = re.sub(r'<Vector3 name="size">.*?</Vector3>',
                     '<Vector3 name="size"><X>%g</X><Y>%g</Y><Z>%g</Z></Vector3>' % size, xml, count=1)
        xml = re.sub(r'(<CoordinateFrame name="CFrame">)<X>[^<]*</X><Y>[^<]*</Y><Z>[^<]*</Z>',
                     r'\g<1><X>%g</X><Y>%g</Y><Z>%g</Z>' % c, xml, count=1)
        s = s[:a] + xml + s[b:]
    open(WORLD, "w").write(s)
    print("home base: x", -W, "..", W, "z 0 ..", D)


if __name__ == "__main__":
    main()
