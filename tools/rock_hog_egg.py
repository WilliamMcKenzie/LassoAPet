"""The Rock Hog's egg, in take C's style (tools/ocean_eggs.py): the octo shell in the Rock
Hog's Basalt colours (slate coat, a navy band, dark hoof base) with its two fiery horns
on top, stepping out and up from dark red to a yellow tip (Glow parts are Neon in game).

Run from the repo root: python3 tools/rock_hog_egg.py
Writes designs/eggs/c_style/RockHogEgg.bbmodel, src/shared/Eggs/RockHogEggModel.luau,
assets/ui/RockHogEggRender.png and previews in /mnt/project-files/animals/rockhog/.
"""

import math
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(__file__))
import ocean_eggs as O  # noqa: E402
from egg_designs import ear_half  # noqa: E402
from horse_egg_takes import H, LH, WIDTHS, shell  # noqa: E402
from rock_hog import SCHEMES  # noqa: E402

S = SCHEMES["Basalt"]


def rock_hog_egg():
    egg = shell([S["hooves"], S["coat"], S["coat"], S["mane"], S["coat"], S["coat"], S["coat"]])
    for side, sx in (("L", -1), ("R", 1)):
        y = H - 0.1
        for i, (x, hw, h) in enumerate(((0.28, 0.2, 0.24), (0.36, 0.17, 0.24), (0.44, 0.13, 0.24))):
            egg.block(f"GlowHorn{side}{i}", (sx * x - hw, y, -hw), (sx * x + hw, y + h, hw), S["horn"][i])
            y += h
        x, hw = 0.44 * sx, 0.13
        for half, d in (("A", -1), ("B", 1)):
            ear_half(egg, f"GlowHornTip{side}{half}", [(x, y), (x + d * hw, y), (x, y + 0.45)], -hw, hw, S["horn"][3])
    # hella spikes (QM): rows of fiery spikes out of every face of layers 1, 3 and 5,
    # red low on the egg to yellow at the top
    for i, col in ((1, S["horn"][0]), (3, S["horn"][1]), (5, S["horn"][2])):
        a, y = WIDTHS[i] / 2, (i + 0.5) * LH
        b, L = (0.2, 1.0) if i < 5 else (0.17, 0.8)
        for k in range(8):
            t = math.radians(45 * k)
            d, u = np.array([math.sin(t), 0, -math.cos(t)]), np.array([math.cos(t), 0, math.sin(t)])
            c = d * (a - 0.05) + np.array([0, y, 0])
            up = np.array([0, b, 0])
            q = [c - u * b - up, c + u * b - up, c + u * b + up, c - u * b + up]
            tip = d * (a + L) + np.array([0, y, 0])
            faces = [q[::-1]] + [[q[j], q[(j + 1) % 4], tip] for j in range(4)]
            egg.poly(f"GlowSpike{i}{k}", faces, col)
    return egg


def generated():
    O.EGGS = [("RockHog", rock_hog_egg)]
    O.main("RockHog", preview="/mnt/project-files/animals/rockhog")
    # the spikes poke out past ocean_eggs' 700 px wide frame: render the UI picture wider
    from horse_egg_takes import VIEWS
    from partlib import render
    egg = rock_hog_egg()
    im = render(egg.parts, W=1100, H=1100, fov=28, transparent=True, **VIEWS[0])
    im = im.crop(im.getbbox())
    im.save(os.path.join(O.ROOT, "assets", "ui", "RockHogEggRender.png"))
    print("render", im.size)


def qm_render():
    """QM's hand-edited egg (designs/eggs/c_style/RockHogEgg.bbmodel, 2x horns) is the game's
    now: convert it with `bbmodel_to_luau.py designs/eggs/c_style/RockHogEgg.bbmodel
    src/shared/Eggs/RockHogEggModel.luau`, then this writes its UI picture (camera raised
    so the tall horns fit). Run: python3 tools/rock_hog_egg.py qm"""
    import json
    import numpy as np
    from horse_egg_takes import VIEWS
    from partlib import render
    from snow_rig import posed
    m = json.load(open(os.path.join(O.ROOT, "designs", "eggs", "c_style", "RockHogEgg.bbmodel")))
    ps = posed(m, None, 0)
    for p in ps:
        if p.name.startswith("Glow"):
            p.neon = True
    v = {k: tuple(np.array(x, float) + [0, 0.6, 0]) for k, x in VIEWS[0].items()}
    im = render(ps, W=1100, H=1100, fov=28, transparent=True, **v)
    im = im.crop(im.getbbox())
    im.save(os.path.join(O.ROOT, "assets", "ui", "RockHogEggRender.png"))
    print("render", im.size)


if __name__ == "__main__":
    qm_render() if sys.argv[1:2] == ["qm"] else generated()
