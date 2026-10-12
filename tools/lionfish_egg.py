"""The Lionfish's egg (QM Oct 11: "make an egg for it, very spikey"), in take C's style: the
octo shell striped cream and red-orange like the Lionfish, bristling with banded spines
(red/cream frustums and a pyramid tip, built as meshes) out of every layer, a tall crest
raked back over the top, two brow spines at the front, a fan of spines on each side and a
maroon tail fin. QM: every spine goes in ONE bone, "Spikes" (child of egg).
Design only, not in the game.

Run from the repo root: python3 tools/lionfish_egg.py
Writes LionfishEgg.bbmodel and renders in /mnt/project-files/animals/lionfish/.
"""

import math
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(__file__))
import horse_egg_takes as C  # noqa: E402
from egg_designs import SPLIT  # noqa: E402
from horse_egg_takes import H, LH, WIDTHS, shell  # noqa: E402
from lionfish import CREAM, STRIPE, PEACH, MAROON  # noqa: E402
from partlib import render  # noqa: E402

OUT = "/mnt/project-files/animals/lionfish"
BANDS = (STRIPE, CREAM, STRIPE, CREAM)


def frame(d):
    d = np.array(d, float)
    d /= np.linalg.norm(d)
    a = np.array([0, 1.0, 0]) if abs(d[1]) < 0.9 else np.array([1.0, 0, 0])
    u = np.cross(d, a)
    u /= np.linalg.norm(u)
    return d, u, np.cross(d, u)


def spine(egg, name, base, d, length, b=0.11):
    """Banded spine from base along d: three tapering frustums then a pyramid tip."""
    d, u, v = frame(d)
    base = np.array(base, float)
    sq = lambda c, w: [c - u * w - v * w, c + u * w - v * w, c + u * w + v * w, c - u * w + v * w]  # noqa: E731
    fr = (0.22, 0.2, 0.2, 0.38)  # band lengths as fractions; last = tip
    s, w = 0.0, b
    for i, f in enumerate(fr):
        c0, c1 = base + d * s * length, base + d * (s + f) * length
        q0 = sq(c0, w)
        if i < 3:
            w1 = w * 0.84
            q1 = sq(c1, w1)
            faces = [q0[::-1], q1] + [[q0[j], q0[(j + 1) % 4], q1[(j + 1) % 4], q1[j]] for j in range(4)]
            w = w1
        else:
            faces = [q0[::-1]] + [[q0[j], q0[(j + 1) % 4], c1] for j in range(4)]
        egg.poly(f"{name}_{i}", faces, BANDS[i], bone="Spikes")
        s += f


def lionfish_egg():
    egg = shell([PEACH, STRIPE, CREAM, STRIPE, CREAM, STRIPE, CREAM])
    # spines out of every face of layers 1..5, alternate layers turned half a face, tilting up
    for i in range(1, 6):
        a, y = WIDTHS[i] / 2, (i + 0.5) * LH
        L = 0.95 if i < 5 else 0.75
        for k in range(8):
            t = math.radians(45 * k + (22.5 if i % 2 == 0 else 0))
            r = a * math.cos(math.radians(22.5)) / math.cos(math.radians(22.5 if i % 2 == 0 else 0)) - 0.06
            out = np.array([math.sin(t), 0, -math.cos(t)])
            spine(egg, f"Spine{i}{k}", out * r + [0, y, 0], out + [0, 0.25 + 0.08 * i, 0], L)
    # tall crest over the top, front to back, raking back
    for j, (z, L) in enumerate(((-0.45, 1.1), (-0.22, 1.35), (0.0, 1.45), (0.22, 1.35), (0.44, 1.15), (0.62, 0.9))):
        spine(egg, f"Crest{j}", (0, H - 0.08 - 0.25 * abs(z), z), (0, 1, 0.35 + 0.6 * max(z, 0)), L, 0.12)
    # brow spines at the front of the top
    for side, sx in (("L", -1), ("R", 1)):
        spine(egg, f"Brow{side}", (sx * 0.35, H - 0.25, -0.45), (sx * 0.5, 1, -0.4), 0.6, 0.09)
    # pectoral fans: five long spines splayed out of each side
    for side, sx in (("L", -1), ("R", 1)):
        a, y = WIDTHS[3] / 2, 3 * LH + 0.1
        for j, az in enumerate((-35, -10, 15, 40, 65)):
            t = math.radians(az)
            spine(egg, f"Fan{side}{j}", (sx * (a - 0.05), y, 0.05), (sx * math.cos(t), -0.15 + 0.004 * az, math.sin(t)), 1.25, 0.09)
    # maroon tail fin out the back
    z = WIDTHS[3] / 2
    egg.block("TailStem", (-0.1, 3 * LH, z - 0.05), (0.1, 4 * LH, z + 0.3), MAROON)
    egg.block("TailFin", (-0.1, 2 * LH + 0.1, z + 0.3), (0.1, 5 * LH - 0.1, z + 0.6), MAROON)
    return egg


def main(out=OUT):
    from horse_rig import write_animations
    from partlib import write_bbmodel
    import egg_designs as E
    import json
    egg = lionfish_egg()
    bones = [("egg", None, (0, 0, 0)), ("bottom", "egg", (0, 0, 0)), ("top", "egg", (0, SPLIT, 0)), ("Spikes", "egg", (0, 0, 0))]
    model, groups = write_bbmodel(egg.parts, "LionfishEgg", None, bones=bones)
    write_animations(model, groups, E.animations())
    with open(os.path.join(out, "LionfishEgg.bbmodel"), "w") as f:
        json.dump(model, f, separators=(",", ":"))
    from PIL import Image
    tile = 520
    sheet = Image.new("RGB", (tile * 2, tile))
    for r, view in enumerate(C.VIEWS):
        v = {k: tuple(np.array(x, float) + [0, 0.4, 0]) for k, x in view.items()}
        sheet.paste(render(egg.parts, W=tile, H=tile, fov=34, **v), (r * tile, 0))
    sheet.save(os.path.join(out, "LionfishEgg.png"))
    im = render(egg.parts, W=1100, H=1200, fov=34, transparent=True,
                **{k: tuple(np.array(x, float) + [0, 0.4, 0]) for k, x in C.VIEWS[0].items()})
    im.crop(im.getbbox()).save(os.path.join(out, "LionfishEgg_render.png"))
    print(len(egg.parts), "parts;", sum(p.bone == "Spikes" for p in egg.parts), "in Spikes")


if __name__ == "__main__":
    main()
