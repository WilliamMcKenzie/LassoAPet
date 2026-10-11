"""The Spinosaurus's egg (QM Oct 11), in take C's style: the octo shell in the Spinosaurus's
teal with a cream base and dark teal stripes down the sides, and its sail running front to
back over the top: dark red spines with gold tips fanned like QM's, orange webbing between
them in stepped columns (real blocks). Design only, not in the game.

Run from the repo root: python3 tools/spinosaurus_egg.py
Writes SpinosaurusEgg.bbmodel and renders in /mnt/project-files/animals/spinosaurus/.
"""

import math
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(__file__))
import horse_egg_takes as C  # noqa: E402
from egg_designs import SPLIT  # noqa: E402
from horse_egg_takes import H, LH, WIDTHS, shell  # noqa: E402
from partlib import render  # noqa: E402

OUT = "/mnt/project-files/animals/spinosaurus"
TEAL, STRIPE, CREAM = (64, 172, 132), (36, 116, 92), (252, 218, 166)
SPINE, TIP, WEB = (150, 28, 40), (255, 214, 90), (255, 136, 40)


def spine(egg, name, base, d, length, w):
    d = np.asarray(d, float) / np.linalg.norm(d)
    u = np.array([1.0, 0, 0])
    v = np.cross(d, u)
    base = np.asarray(base, float)
    q = lambda c: [c - u * w - v * w, c + u * w - v * w, c + u * w + v * w, c - u * w + v * w]  # noqa: E731
    q0, q1 = q(base), q(base + d * length)
    egg.poly(name, [q0[::-1], q1] + [[q0[j], q0[(j + 1) % 4], q1[(j + 1) % 4], q1[j]] for j in range(4)], SPINE)
    tip = base + d * (length + 0.32)
    egg.poly(name + "Tip", [q1[::-1]] + [[q1[j], q1[(j + 1) % 4], tip] for j in range(4)], TIP)
    return base + d * length


def spino_egg():
    egg = shell([CREAM, TEAL, TEAL, TEAL, TEAL, TEAL, TEAL])
    # cream belly on the front, like the dinosaur's
    C.front_plate(egg, "Belly", -0.42, 0.42, LH + 0.05, 4 * LH, CREAM, depth=0.05, plain=False)
    # dark tiger stripes running down both sides, one block per layer so they follow the shell
    for i in range(2, 6):
        a = WIDTHS[i] / 2
        for sx in (-1, 1):
            for j, z in enumerate((-0.42, 0.0, 0.42)):
                x0, x1 = sorted((sx * (a - 0.04), sx * (a + 0.04)))
                egg.block(f"Stripe{i}{'LR'[sx > 0]}{j}", (x0, i * LH, z - 0.08), (x1, (i + 1) * LH, z + 0.08), STRIPE)
    # the sail: spines fanned from front to back over the top, webbing between them
    n = 7
    base_y = H - 0.12
    tops = []
    for k in range(n):
        f = (k - (n - 1) / 2) / ((n - 1) / 2)  # -1 front .. +1 back
        z = 0.5 * f
        ang = math.radians(32 * f)
        d = (0, math.cos(ang), math.sin(ang))
        L = 1.5 * (1 - 0.45 * f * f)
        tops.append(spine(egg, f"SailSpine{k}", (0, base_y - 0.12 * f * f, z), d, L, 0.08))
    for k in range(n - 1):
        (y0, z0), (y1, z1) = (tops[k][1], tops[k][2]), (tops[k + 1][1], tops[k + 1][2])
        za, zb = sorted((z0, z1))
        f0 = (k - (n - 1) / 2) / ((n - 1) / 2)
        f1 = (k + 1 - (n - 1) / 2) / ((n - 1) / 2)
        foot = base_y - 0.12 * max(f0 * f0, f1 * f1) - 0.05
        # stepped columns so the webbing follows the arch between the two spine tops
        for s in range(3):
            t0, t1 = s / 3, (s + 1) / 3
            ztop = z0 + (z1 - z0) * (t0 + t1) / 2
            ytop = y0 + (y1 - y0) * (t0 + t1) / 2 - 0.08
            zs = sorted((z0 + (z1 - z0) * t0, z0 + (z1 - z0) * t1))
            egg.block(f"SailWeb{k}_{s}", (-0.03, foot, zs[0]), (0.03, ytop, zs[1]), WEB).bone = "top"
            del ztop
        del za, zb
    return egg


def main(out=OUT):
    import json
    import egg_designs as E
    from horse_rig import write_animations
    from partlib import write_bbmodel
    egg = spino_egg()
    bones = [("egg", None, (0, 0, 0)), ("bottom", "egg", (0, 0, 0)), ("top", "egg", (0, SPLIT, 0))]
    model, groups = write_bbmodel(egg.parts, "SpinosaurusEgg", None, bones=bones)
    write_animations(model, groups, E.animations())
    with open(os.path.join(out, "SpinosaurusEgg.bbmodel"), "w") as f:
        json.dump(model, f, separators=(",", ":"))
    from PIL import Image
    tile = 520
    sheet = Image.new("RGB", (tile * 3, tile))
    views = list(C.VIEWS) + [dict(eye=(-11, 3.4, 0), target=(0, 2.4, 0))]
    for r, view in enumerate(views):
        v = {k: tuple(np.array(x, float) + [0, 0.4, 0]) for k, x in view.items()}
        sheet.paste(render(egg.parts, W=tile, H=tile, fov=32, **v), (r * tile, 0))
    sheet.save(os.path.join(out, "SpinosaurusEgg.png"))
    print(len(egg.parts), "parts")


if __name__ == "__main__":
    main()
