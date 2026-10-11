"""The Phoenix's egg (QM Oct 11: "EPIC ... complex/interesting to look at"), in take C's
style (tools/ocean_eggs.py): the octo shell heating up from crimson at the base to gold
at the top, with
  - flames licking up from the base all the way round (orange -> gold -> glowing tip),
  - a folded flame wing on each side: a crimson arm, feathers hanging down and back,
  - a gold flame emblem on the front,
  - three flame streamers trailing out the back like its tail,
  - the Phoenix's two curly plumes and a little flame on top.
Glow* parts are Neon in game.

Run from the repo root: python3 tools/phoenix_egg.py
Writes designs/eggs/c_style/PhoenixEgg.bbmodel, src/shared/Eggs/PhoenixEggModel.luau,
assets/ui/PhoenixEggRender.png and previews in /mnt/project-files/animals/phoenix/.
"""

import math
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import ocean_eggs as O  # noqa: E402
from egg_designs import SPLIT  # noqa: E402
from horse_egg_takes import H, LH, WIDTHS, shell  # noqa: E402
from partlib import Part, T, Ry  # noqa: E402
from phoenix_design import CRIMSON, RED, ORANGE, GOLD, FLAME  # noqa: E402

PREVIEW = "/mnt/project-files/animals/phoenix"


def face_block(egg, name, k, y0, y1, u0, u1, a, out, color):
    """A box standing on octo face k (0 = front, 2 = right, counting clockwise from above):
    u0..u1 across the face, from a - 0.05 (just inside the shell) to a + out."""
    t = math.radians(45 * k)
    d = (math.sin(t), -math.cos(t))  # outward normal in (x, z)
    side = (math.cos(t), math.sin(t))  # along the face, to the right seen from outside
    depth = out + 0.05
    r = a - 0.05 + depth / 2
    u = (u0 + u1) / 2
    cx, cz = d[0] * r + side[0] * u, d[1] * r + side[1] * u
    p = Part(name, (u1 - u0, y1 - y0, depth), T(cx, (y0 + y1) / 2, cz) @ Ry(180 - 45 * k), color)
    p.bone = "top" if (y0 + y1) / 2 > SPLIT else "bottom"
    egg.parts.append(p)
    return p


def glow(col):
    return "Glow" if col == FLAME else ""


def phoenix_egg():
    egg = shell([CRIMSON, CRIMSON, RED, RED, ORANGE, ORANGE, GOLD])
    a1 = WIDTHS[1] / 2  # flames stand on layer 1's faces and reach past layer 2
    # flames licking up all the way round: a tall tongue in the middle of each face, a
    # shorter one beside it (alternating sides), red at the root to a glowing tip
    for k in range(8):
        for j, (u, h, w) in enumerate(((0.0, 1.0, 0.26), (0.26 if k % 2 else -0.26, 0.6, 0.18))):
            y = LH + 0.02
            for s, (col, frac) in enumerate(((ORANGE, 0.5), (GOLD, 0.3), (FLAME, 0.2))):
                y1 = y + h * frac
                ww = w * (1 - 0.25 * s)  # narrowing toward the tip
                face_block(egg, f"{glow(col)}Flame{k}_{j}_{s}", k, y, y1, u - ww / 2, u + ww / 2, a1, 0.2, col)
                y = y1
    # a folded wing on each side: a crimson arm high up, four feathers hanging down and back
    for side, sx in (("L", -1), ("R", 1)):
        def xs(inner, outer):
            return tuple(sorted((sx * inner, sx * outer)))
        x0, x1 = xs(1.05, 1.34)
        egg.block(f"WingArm{side}", (x0, 1.96, -0.58), (x1, 2.24, 0.72), CRIMSON)
        for i, (z, length) in enumerate(((-0.42, 0.75), (-0.12, 0.95), (0.18, 1.15), (0.48, 1.35))):
            y = 2.0
            for s, (col, frac) in enumerate(((ORANGE, 0.55), (GOLD, 0.27), (FLAME, 0.18))):
                y1 = y - length * frac
                zz = z + 0.06 * s  # sweeping back as they hang
                x0, x1 = xs(1.1, 1.3)
                egg.block(f"{glow(col)}WingFeather{side}{i}_{s}", (x0, y1, zz - 0.14), (x1, y, zz + 0.14), col)
                y = y1
    # a crimson flame emblem on the front, glowing at its heart
    # (on the top shell, above the front flames)
    a4, a5 = WIDTHS[4] / 2, WIDTHS[5] / 2
    for name, y0, y1, w, a, col in (("Emblem0", 1.88, 2.04, 0.56, a4, CRIMSON), ("Emblem1", 2.04, 2.22, 0.4, a4, CRIMSON),
                                     ("GlowEmblem", 1.96, 2.18, 0.16, a4 + 0.03, FLAME), ("Emblem2", 2.3, 2.46, 0.26, a5, CRIMSON),
                                     ("GlowEmblemTip", 2.46, 2.6, 0.12, a5, FLAME)):
        face_block(egg, name, 0, y0, y1, -w / 2, w / 2, a, 0.07, col)
    # three flame streamers out the back, dropping and fanning out as they go
    for i, x in enumerate((-0.32, 0.0, 0.32)):
        z, y = WIDTHS[3] / 2 - 0.05, 1.55 + (0.12 if i == 1 else 0)
        for s, col in enumerate((CRIMSON, ORANGE, GOLD, FLAME)):
            xc = x * (1 + 0.45 * s)
            egg.block(f"{glow(col)}Streamer{i}_{s}", (xc - 0.13, y - 0.2, z), (xc + 0.13, y, z + 0.3), col)
            z, y = z + 0.28, y - 0.13
    # the Phoenix's two curly plumes on top, curling forward, and a flame between them
    for side, sx in (("L", -1), ("R", 1)):
        for j, (y0, h, zc, col) in enumerate(((H - 0.05, 0.32, 0.05, ORANGE), (H + 0.27, 0.3, 0.13, ORANGE),
                                              (H + 0.57, 0.26, 0.04, GOLD), (H + 0.8, 0.18, -0.16, FLAME),
                                              (H + 0.74, 0.17, -0.36, FLAME))):
            x = sx * (0.22 + 0.04 * j)
            egg.block(f"{glow(col)}Plume{side}{j}", (x - 0.09, y0, zc - 0.11), (x + 0.09, y0 + h, zc + 0.11), col)
    egg.block("CrownFlame", (-0.12, H - 0.05, -0.12), (0.12, H + 0.2, 0.12), GOLD)
    egg.block("GlowCrownFlame", (-0.07, H + 0.2, -0.07), (0.07, H + 0.4, 0.07), FLAME)
    return egg


def main():
    O.EGGS = [("Phoenix", phoenix_egg)]
    O.main("Phoenix", preview=PREVIEW)
    # streamers and plumes poke out past ocean_eggs' frame: render the UI picture wider
    from horse_egg_takes import VIEWS
    from partlib import render
    egg = phoenix_egg()
    for p in egg.parts:
        if p.name.startswith("Glow"):
            p.neon = True
    im = render(egg.parts, W=1100, H=1300, fov=30, transparent=True, **VIEWS[0])
    im = im.crop(im.getbbox())
    im.save(os.path.join(O.ROOT, "assets", "ui", "PhoenixEggRender.png"))
    im.save(os.path.join(PREVIEW, "PhoenixEgg_render.png"))
    print("render", im.size, len(egg.parts), "parts")


def qm_render():
    """QM's edited egg (designs/eggs/c_style/PhoenixEgg.bbmodel, Oct 11) is the game's: convert
    it with `bbmodel_to_luau.py --zyx designs/eggs/c_style/PhoenixEgg.bbmodel
    src/shared/Eggs/PhoenixEggModel.luau`, then this writes its UI picture.
    Run: python3 tools/phoenix_egg.py qm"""
    import json
    from horse_egg_takes import VIEWS
    from partlib import render
    from snow_rig import posed
    import horse_rig
    horse_rig.EULER = "ZYX"  # QM's wing groups are turned about two axes
    m = json.load(open(os.path.join(O.ROOT, "designs", "eggs", "c_style", "PhoenixEgg.bbmodel")))
    ps = posed(m, None, 0)
    for p in ps:
        if p.name.startswith("Glow"):
            p.neon = True
    im = render(ps, W=1100, H=1300, fov=30, transparent=True, **VIEWS[0])
    im = im.crop(im.getbbox())
    im.save(os.path.join(O.ROOT, "assets", "ui", "PhoenixEggRender.png"))
    im.save(os.path.join(PREVIEW, "PhoenixEgg_QM.png"))
    print("render", im.size)


if __name__ == "__main__":
    qm_render() if sys.argv[1:2] == ["qm"] else main()
