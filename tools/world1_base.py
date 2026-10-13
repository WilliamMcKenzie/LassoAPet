"""World 1's home base floor, redone like World 2's (QM, Oct 13: "do the same for world 1").

Run: python3 tools/world1_base.py [out_dir]
     renders it beside World 1's base as it is and writes tools/world1_base.luau.

The same layout as tools/world2_base.py (the yard, the lane to the line, the paths to the
pens' gates; darker grass always between the bright grass and the dirt; the bright grass
a stud up but under the pens and on the start line's row), in World 1's Meadow colours:
green grass, a darker green beside the dirt, the tan dirt.
"""

import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import world2_base as base  # noqa: E402
from desert_ground import rects  # noqa: E402

HERE = os.path.dirname(__file__)
COLOURS = {  # part, checker (Config's Meadow GroundColors and Patches)
    base.BRIGHT: [(113, 173, 31), (122, 190, 25)],
    base.DARK: [(92, 146, 30), (100, 160, 26)],
    base.DIRT: [(206, 146, 84), (222, 164, 100)],
}


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else "/mnt/project-files/biomes/world1_base"
    os.makedirs(out, exist_ok=True)
    kind = base.layout()
    assert base.check(kind) == 0
    base.COLOURS.update(COLOURS)  # (the renders in World 1's colours)
    base.render(base.world1(), os.path.join(out, "now.png"))
    base.render(kind, os.path.join(out, "proposed.png"))
    a, b = Image.open(os.path.join(out, "now.png")), Image.open(os.path.join(out, "proposed.png"))
    im = Image.new("RGB", (a.width * 2 + 30, a.height), (255, 255, 255))
    im.paste(a, (0, 0))
    im.paste(b, (a.width + 30, 0))
    im.save(os.path.join(out, "world1_base_compare.png"))
    rows = ["\t{ %d, %d, %d, %d, %d }," % (k, -base.W + i0 * base.CELL, j0 * base.CELL, (i1 - i0) * base.CELL, (j1 - j0) * base.CELL)
            for k, i0, j0, i1, j1 in rects(base.raise_grass(kind))]
    body = open(os.path.join(HERE, "world1_base.luau.in")).read()
    open(os.path.join(HERE, "world1_base.luau"), "w").write(body.replace("--FLOOR--", "\n".join(rows)))
    print("parts:", len(rows))


if __name__ == "__main__":
    main()
