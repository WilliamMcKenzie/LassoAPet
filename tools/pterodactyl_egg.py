"""The Pterodactyl's egg (QM Oct 11), in take C's style: the octo shell in the Pterodactyl's
purple with a cream base, dark purple stripes down the sides, a little orange bat wing folded
up on each side (purple leading edge over stepped membrane columns, real blocks) and its
red-orange crest sweeping back off the top.

Run from the repo root: python3 tools/pterodactyl_egg.py
Writes PterodactylEgg.bbmodel and PterodactylEgg.png in /mnt/project-files/animals/pterodactyl/ and\nassets/ui/PterodactylEggRender.png. In game: designs/eggs/c_style/PterodactylEgg.bbmodel.
"""

import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(__file__))
import horse_egg_takes as C  # noqa: E402
from egg_designs import SPLIT  # noqa: E402
from horse_egg_takes import H, LH, WIDTHS, shell  # noqa: E402
from partlib import render  # noqa: E402

OUT = "/mnt/project-files/animals/pterodactyl"
PURPLE, STRIPE, CREAM = (150, 98, 222), (82, 50, 156), (252, 218, 166)
CREST, WEB, WEB_EDGE = (255, 84, 52), (255, 150, 72), (240, 106, 54)


def ptero_egg():
    egg = shell([CREAM, PURPLE, PURPLE, PURPLE, PURPLE, PURPLE, PURPLE])
    C.front_plate(egg, "Belly", -0.42, 0.42, LH + 0.05, 4 * LH, CREAM, depth=0.05, plain=False)
    # stripes down both sides, one block per layer so they follow the shell
    for i in range(2, 6):
        a = WIDTHS[i] / 2
        for sx in (-1, 1):
            for j, z in enumerate((-0.42, 0.42)):
                x0, x1 = sorted((sx * (a - 0.04), sx * (a + 0.04)))
                egg.block(f"Stripe{i}{'LR'[sx > 0]}{j}", (x0, i * LH, z - 0.08), (x1, (i + 1) * LH, z + 0.08), STRIPE)
    # folded wings: columns stepping out and up from the shell's side, each a membrane slab
    # under a purple leading edge, the membrane's lower part darker, a black claw at the top
    for sx, side in ((-1, "L"), (1, "R")):
        n, w = 5, 0.22
        for k in range(n):
            xa = 1.02 + k * w
            x0, x1 = sorted((sx * xa, sx * (xa + w)))
            top = 1.5 + 0.24 * k
            bot = 0.7 + 0.22 * k
            mid = bot + 0.3 * (top - bot)
            egg.block(f"WingEdge{side}{k}", (x0, top, -0.1), (x1, top + 0.14, 0.1), PURPLE).bone = "bottom"
            egg.block(f"WingWeb{side}{k}", (x0, mid, -0.07), (x1, top, 0.07), WEB).bone = "bottom"
            egg.block(f"WingWebEdge{side}{k}", (x0, bot, -0.07), (x1, mid, 0.07), WEB_EDGE).bone = "bottom"
        xa = 1.02 + n * w
        x0, x1 = sorted((sx * xa, sx * (xa + 0.14)))
        egg.block(f"WingTip{side}", (x0, 1.5 + 0.24 * (n - 1), -0.08), (x1, 1.5 + 0.24 * (n - 1) + 0.34, 0.08), PURPLE).bone = "bottom"
    # the crest: steps rising up and back over the top of the shell, then a point
    for i, (z0, z1, y0, y1) in enumerate(((-0.35, 0.15, H - 0.08, H + 0.22), (0.05, 0.5, H - 0.02, H + 0.42), (0.4, 0.8, H + 0.12, H + 0.6))):
        egg.block(f"Crest{i}", (-0.12, y0, z0), (0.12, y1, z1), CREST).bone = "top"
    base = np.array([0.0, H + 0.36, 0.8])
    q = [base + d for d in ((-0.11, -0.22, 0), (0.11, -0.22, 0), (0.11, 0.22, 0), (-0.11, 0.22, 0))]
    tip = base + (0, 0.12, 0.55)
    egg.poly("CrestTip", [q] + [[q[j], q[(j + 1) % 4], tip] for j in range(4)], CREST, bone="top")
    return egg


def main(out=OUT):
    import json
    import egg_designs as E
    from horse_rig import write_animations
    from partlib import write_bbmodel
    egg = ptero_egg()
    bones = [("egg", None, (0, 0, 0)), ("bottom", "egg", (0, 0, 0)), ("top", "egg", (0, SPLIT, 0))]
    model, groups = write_bbmodel(egg.parts, "PterodactylEgg", None, bones=bones)
    write_animations(model, groups, E.animations())
    with open(os.path.join(out, "PterodactylEgg.bbmodel"), "w") as f:
        json.dump(model, f, separators=(",", ":"))
    from PIL import Image
    tile = 520
    sheet = Image.new("RGB", (tile * 3, tile))
    views = list(C.VIEWS) + [dict(eye=(-11, 3.4, 0), target=(0, 2.4, 0))]
    for r, view in enumerate(views):
        v = {k: tuple(np.array(x, float) + [0, 0.4, 0]) for k, x in view.items()}
        sheet.paste(render(egg.parts, W=tile, H=tile, fov=32, **v), (r * tile, 0))
    sheet.save(os.path.join(out, "PterodactylEgg.png"))
    # the game's UI picture
    im = render(egg.parts, W=1100, H=1300, fov=30, transparent=True, **C.VIEWS[0])
    im = im.crop(im.getbbox())
    im.save(os.path.join(os.path.dirname(__file__), "..", "assets", "ui", "PterodactylEggRender.png"))
    print("render", im.size)
    print(len(egg.parts), "parts")


if __name__ == "__main__":
    main()
