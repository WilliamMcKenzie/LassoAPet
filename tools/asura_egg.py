"""The Asura's egg (World 2 Crimson Lands Legendary; QM: "make the egg INSANELY cool"), in
take C's style (tools/ocean_eggs.py) but dressed as the Asura's armour:

  a dark slate shell with slate armour bands and two glowing cyan rings, a red glow
  leaking through a jagged crack across the front, cyan-trimmed pauldrons, the helm's
  two horns rising to glowing tips, a cyan crest jewel on the brow, and the Asura's sword
  plunged point-first into the top (glowing fuller, winged guard, wrapped grip, glowing
  pommel).

Run from the repo root: python3 tools/asura_egg.py
Writes designs/eggs/c_style/AsuraEgg.bbmodel, src/shared/Eggs/AsuraEggModel.luau,
assets/ui/AsuraEggRender.png and previews in /mnt/project-files/animals/asura/.
"""

import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import ocean_eggs as O  # noqa: E402
from egg_designs import octo_layer  # noqa: E402
from horse_egg_takes import CRACK_LAYER, LH, N, WIDTHS, shell  # noqa: E402
from asura import PALETTE  # noqa: E402

SLATE, DARK, LIGHT, STEEL = PALETTE["slate"], PALETTE["dark"], PALETTE["light"], PALETTE["steel"]
CYAN, RED = (60, 230, 255), (255, 40, 40)
TOP = N * LH


def asura_egg():
    egg = shell([DARK, DARK, SLATE, DARK, DARK, SLATE, DARK])
    # glowing cyan rings where the armour bands meet
    for name, layer in (("GlowRingLow", 2), ("GlowRingHigh", 5)):
        y = layer * LH
        octo_layer(egg, name, y - 0.05, y + 0.05, max(WIDTHS[layer - 1], WIDTHS[layer]) + 0.08, CYAN,
                   "top" if layer >= CRACK_LAYER else "bottom")
    # a jagged red glowing crack running across the front, round the corners
    z = -WIDTHS[3] / 2 - 0.05
    ys = (1.62, 1.86, 1.7, 1.98, 1.76, 1.94, 1.66, 1.9, 1.72)
    for i, y in enumerate(ys):
        x = -0.8 + i * 0.2
        p = egg.block(f"GlowCrack{i}", (x - 0.1, y - 0.07, z - 0.03), (x + 0.1, y + 0.07, z + 0.06), RED)
        p.bone = "top" if y > CRACK_LAYER * LH else "bottom"
        if i:  # the step joining it to the last one
            lo, hi = sorted((ys[i - 1], y))
            q = egg.block(f"GlowCrackStep{i}", (x - 0.13, lo, z - 0.03), (x - 0.07, hi, z + 0.06), RED)
            q.bone = p.bone
    # shoulder pauldrons with cyan trim
    for side, sx in (("L", -1), ("R", 1)):
        x0 = sx * (WIDTHS[3] / 2 - 0.05)
        egg.block(f"Pauldron{side}", (min(x0, x0 + sx * 0.22), 1.95, -0.55), (max(x0, x0 + sx * 0.22), 2.55, 0.55), SLATE).bone = "top"
        egg.block(f"GlowPauldron{side}", (min(x0, x0 + sx * 0.26), 1.9, -0.58), (max(x0, x0 + sx * 0.26), 1.98, 0.58), CYAN).bone = "top"
    # the helm's horns: up off the shoulders, out, then up to glowing tips
    y = 5 * LH
    for side, sx in (("L", -1), ("R", 1)):
        x = sx * 0.6
        for name, lo, hi, col in ((f"Horn{side}1", (x - 0.13, y, -0.16), (x + 0.13, y + 0.55, 0.16), SLATE),
                                  (f"Horn{side}2", (min(x, x + sx * 0.5) - 0.12, y + 0.45, -0.14), (max(x, x + sx * 0.5) + 0.12, y + 0.7, 0.14), SLATE),
                                  (f"Horn{side}3", (x + sx * 0.5 - 0.11, y + 0.6, -0.12), (x + sx * 0.5 + 0.11, y + 1.35, 0.12), SLATE),
                                  (f"Horn{side}4", (x + sx * 0.5 - 0.08, y + 1.35, -0.09), (x + sx * 0.5 + 0.08, y + 1.75, 0.09), LIGHT),
                                  (f"GlowHorn{side}", (x + sx * 0.5 - 0.05, y + 1.75, -0.05), (x + sx * 0.5 + 0.05, y + 2.0, 0.05), CYAN)):
            egg.block(name, lo, hi, col).bone = "top"
    # the crest jewel on the brow, glowing
    zf = -WIDTHS[5] / 2 - 0.05
    egg.block("CrestFrame", (-0.24, 5 * LH + 0.08, zf - 0.02), (0.24, 5 * LH + 0.5, zf + 0.1), LIGHT).bone = "top"
    egg.block("GlowCrest", (-0.14, 5 * LH + 0.16, zf - 0.07), (0.14, 5 * LH + 0.42, zf + 0.05), CYAN).bone = "top"
    # the sword, plunged point-first into the top
    for name, lo, hi, col in (("Blade", (-0.08, TOP - 0.3, -0.22), (0.08, TOP + 1.2, 0.22), STEEL),
                              ("BladeEdge", (-0.05, TOP - 0.3, -0.29), (0.05, TOP + 1.2, -0.22), (214, 222, 226)),
                              ("GlowFuller", (-0.09, TOP + 0.1, -0.04), (0.09, TOP + 1.1, 0.04), CYAN),
                              ("Guard", (-0.13, TOP + 1.2, -0.55), (0.13, TOP + 1.36, 0.55), LIGHT),
                              ("GuardL", (-0.11, TOP + 1.0, -0.62), (0.11, TOP + 1.36, -0.48), LIGHT),
                              ("GuardR", (-0.11, TOP + 1.0, 0.48), (0.11, TOP + 1.36, 0.62), LIGHT),
                              ("GlowGuardGem", (-0.15, TOP + 1.22, -0.09), (0.15, TOP + 1.34, 0.09), CYAN),
                              ("Grip1", (-0.08, TOP + 1.36, -0.08), (0.08, TOP + 1.52, 0.08), DARK),
                              ("Grip2", (-0.09, TOP + 1.52, -0.09), (0.09, TOP + 1.62, 0.09), LIGHT),
                              ("Grip3", (-0.08, TOP + 1.62, -0.08), (0.08, TOP + 1.8, 0.08), DARK),
                              ("GlowPommel", (-0.12, TOP + 1.8, -0.12), (0.12, TOP + 2.04, 0.12), CYAN)):
        egg.block(name, lo, hi, col).bone = "top"
    return egg


if __name__ == "__main__":
    O.EGGS = [("Asura", asura_egg)]
    O.main("Asura", preview="/mnt/project-files/animals/asura")
