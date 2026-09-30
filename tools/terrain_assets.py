"""Terrain assets for the meadow and desert (drafts for QM to vet).

Run: python3 tools/terrain_assets.py [out_dir]

  Meadow  small   Stone       a chunky grey rock
          small   Bush        a stepped round green bush
          medium  Boulder     a big grey rock with a darker base
  Desert  small   Sandstone   a stack of terracotta slabs, the floor's sandstone colours
          medium  Cactus      a saguaro in the Cactus pet's greens, ribs and spines
          medium  SandBoulder a rounded tan rock with darker bands
          large   SandMound   a stepped sand hill with a prickly pear and a dead bush on top

Everything is studded blocks (no 2D planes). A 5-stud blocky figure stands in
each row for scale. Sizes are in studs.
"""

import os
import sys

import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(__file__))
import partlib  # noqa: E402
from partlib import Part, T, Rx, Ry, Rz, render  # noqa: E402
from animal_designs import font  # noqa: E402


class Kit:
    def __init__(self):
        self.parts = []

    def box(self, name, lo, hi, color, rot=None, plain=False):
        lo, hi = np.array(lo, float), np.array(hi, float)
        cf = T(*((lo + hi) / 2))
        if rot is not None:
            cf = cf @ rot
        self.parts.append(Part(name, hi - lo, cf, color, plain=plain))

    def at(self, name, centre, size, color, rot=None):
        cf = T(*centre)
        if rot is not None:
            cf = cf @ rot
        self.parts.append(Part(name, size, cf, color))


# ---------------------------------------------------------------- meadow

GREY, GREY_D, GREY_L = (150, 156, 170), (118, 124, 140), (176, 182, 194)


def stone(k):
    k.box("Stone", (-2.2, 0, -1.8), (2.0, 2.0, 1.8), GREY)
    k.box("Stone", (-1.6, 2.0, -1.2), (1.2, 3.0, 1.4), GREY_L)
    k.box("Stone", (1.2, 0, -1.2), (2.8, 1.2, 1.0), GREY_D)


def bush(k):
    g, gl = (70, 168, 58), (98, 200, 74)
    k.box("Bush", (-2.8, 0, -2.4), (2.8, 2.4, 2.4), g)
    k.box("Bush", (-2.2, 2.4, -1.8), (2.2, 3.8, 1.8), gl)
    k.box("Bush", (-1.2, 3.8, -1.0), (1.2, 4.6, 1.0), gl)
    k.box("Bush", (-3.4, 0.4, -1.4), (-2.8, 2.0, 1.4), g)
    k.box("Bush", (2.8, 0.4, -1.4), (3.4, 2.0, 1.4), g)


def boulder(k):
    k.box("Boulder", (-4.6, 0, -3.8), (4.6, 1.6, 3.8), GREY_D)
    k.box("Boulder", (-4.2, 1.6, -3.4), (4.2, 5.4, 3.4), GREY)
    k.box("Boulder", (-3.2, 5.4, -2.6), (3.4, 7.2, 2.8), GREY)
    k.box("Boulder", (-2.0, 7.2, -1.6), (2.2, 8.0, 1.8), GREY_L)
    k.box("Boulder", (-5.4, 0, -2.0), (-4.2, 3.2, 1.8), GREY_D)


# ---------------------------------------------------------------- desert

STONE, STONE_L, STONE_D = (206, 146, 84), (222, 164, 100), (176, 116, 64)
SAND, SAND_L = (232, 188, 102), (250, 214, 130)
C_GREEN, C_RIB, C_SPINE = (118, 204, 64), (72, 150, 44), (214, 176, 96)  # the Cactus pet's


def sandstone(k):
    k.box("Slab", (-2.6, 0, -2.0), (2.6, 1.2, 2.0), STONE_D)
    k.box("Slab", (-2.2, 1.2, -1.7), (2.4, 2.4, 1.8), STONE)
    k.box("Slab", (-1.6, 2.4, -1.2), (1.6, 3.4, 1.3), STONE_L)


def ribbed(k, name, lo, hi, color=C_GREEN, rib=C_RIB):
    """A cactus block with a dark rib down the middle of each side."""
    k.box(name, lo, hi, color)
    (x0, y0, z0), (x1, y1, z1) = lo, hi
    cx, cz = (x0 + x1) / 2, (z0 + z1) / 2
    for a, b in (((cx - 0.08, y0 + 0.2, z0 - 0.05), (cx + 0.08, y1 - 0.2, z0)),
                 ((cx - 0.08, y0 + 0.2, z1), (cx + 0.08, y1 - 0.2, z1 + 0.05)),
                 ((x0 - 0.05, y0 + 0.2, cz - 0.08), (x0, y1 - 0.2, cz + 0.08)),
                 ((x1, y0 + 0.2, cz - 0.08), (x1 + 0.05, y1 - 0.2, cz + 0.08))):
        k.box("Rib", a, b, rib, plain=True)


def cactus(k):
    ribbed(k, "Trunk", (-1.2, 0, -1.2), (1.2, 11, 1.2))
    k.box("Top", (-0.9, 11, -0.9), (0.9, 11.6, 0.9), C_GREEN)
    # left arm out low and up; right arm out higher and up
    ribbed(k, "ArmL", (-3.4, 4.2, -0.8), (-1.2, 5.8, 0.8))
    ribbed(k, "ArmLUp", (-3.4, 5.8, -0.8), (-1.8, 9.0, 0.8))
    k.box("ArmLTop", (-3.1, 9.0, -0.5), (-2.1, 9.4, 0.5), C_GREEN)
    ribbed(k, "ArmR", (1.2, 6.2, -0.8), (3.2, 7.6, 0.8))
    ribbed(k, "ArmRUp", (1.6, 7.6, -0.8), (3.2, 10.0, 0.8))
    k.box("ArmRTop", (1.9, 10.0, -0.5), (2.9, 10.4, 0.5), C_GREEN)
    for x, y, z in ((-1.2, 2.5, -1.2), (1.2, 8.8, -1.2), (-1.2, 9.6, 1.2), (-3.4, 7.4, -0.8), (3.2, 8.8, -0.8)):
        k.box("Spine", (x - 0.1, y - 0.1, z - 0.5 if z < 0 else z), (x + 0.1, y + 0.1, z if z < 0 else z + 0.5),
              C_SPINE, plain=True)


def sand_boulder(k):
    band = (214, 162, 96)
    k.box("Rock", (-4.2, 0, -3.6), (4.2, 1.4, 3.6), band)
    k.box("Rock", (-4.0, 1.4, -3.4), (4.0, 3.6, 3.4), (234, 190, 122))
    k.box("Rock", (-3.8, 3.6, -3.2), (3.8, 4.4, 3.2), band)
    k.box("Rock", (-3.2, 4.4, -2.6), (3.2, 6.4, 2.6), (234, 190, 122))
    k.box("Rock", (-2.0, 6.4, -1.6), (2.2, 7.2, 1.8), (246, 208, 144))


def prickly_pear(k, x, y, z):
    pad = (104, 188, 70)
    fruit = (236, 76, 120)
    k.box("Pad", (x - 1.3, y, z - 0.35), (x + 1.3, y + 3.0, z + 0.35), pad)
    k.at("Pad", (x - 1.9, y + 3.6, z), (1.8, 2.4, 0.6), pad, Rz(28))
    k.at("Pad", (x + 1.7, y + 3.9, z + 0.1), (1.8, 2.6, 0.6), pad, Rz(-24))
    k.at("Pad", (x + 0.2, y + 3.9, z - 0.8), (0.6, 2.2, 1.6), pad, Rx(-26))
    for fx, fy in ((-2.5, 5.0), (-1.3, 5.1), (2.2, 5.4), (1.1, 5.2)):
        k.box("Fruit", (x + fx - 0.35, y + fy - 0.1, z - 0.35), (x + fx + 0.35, y + fy + 0.6, z + 0.35), fruit)
    for sx, sy in ((-0.6, 1.2), (0.7, 2.2), (-0.2, 0.5)):
        k.box("Spine", (x + sx - 0.08, y + sy - 0.08, z - 0.75), (x + sx + 0.08, y + sy + 0.08, z - 0.35),
              C_SPINE, plain=True)


def dead_bush(k, x, y, z):
    twig = (138, 96, 60)
    k.box("Twig", (x - 0.25, y, z - 0.25), (x + 0.25, y + 1.2, z + 0.25), twig)
    for yaw, lean, h in ((0, 35, 2.2), (120, 40, 2.0), (240, 30, 2.4), (60, 55, 1.6), (190, 60, 1.5)):
        R = Ry(yaw) @ Rz(lean)
        centre = np.array([x, y + 1.0, z]) + (R @ np.array([0, h / 2, 0, 0]))[:3]
        k.at("Twig", centre, (0.3, h, 0.3), twig, R)


def sand_mound(k):
    layers = [(12, 1.2), (10, 1.2), (8, 1.2), (5.5, 1.0)]  # half widths and heights, stepped up
    y = 0
    for i, (hw, h) in enumerate(layers):
        k.box("Mound", (-hw, y, -hw * 0.8), (hw, y + h, hw * 0.8), ((224, 174, 90), (240, 198, 116))[i % 2])
        y += h
    prickly_pear(k, -1.4, y, 0.4)
    dead_bush(k, 3.0, y, -1.0)


def figure(k, x=0):
    """A 5-stud blocky figure for scale."""
    skin, shirt, pants = (245, 205, 48), (13, 105, 172), (40, 127, 71)
    k.box("Leg", (x - 1.0, 0, -0.5), (x, 2, 0.5), pants)
    k.box("Leg", (x, 0, -0.5), (x + 1.0, 2, 0.5), pants)
    k.box("Torso", (x - 1.0, 2, -0.5), (x + 1.0, 4, 0.5), shirt)
    k.box("Arm", (x - 2.0, 2, -0.5), (x - 1.0, 4, 0.5), skin)
    k.box("Arm", (x + 1.0, 2, -0.5), (x + 2.0, 4, 0.5), skin)
    k.box("Head", (x - 0.6, 4, -0.6), (x + 0.6, 5.2, 0.6), skin)


ROWS = [
    ("Meadow", [(77, 196, 63), (105, 255, 74)], [
        ("Stone (small)", stone, 6), ("Bush (small)", bush, 7), ("Boulder (medium)", boulder, 11)]),
    ("Desert", [(232, 188, 102), (250, 214, 130)], [
        ("Sandstone (small)", sandstone, 6), ("Cactus (medium)", cactus, 7),
        ("Sand boulder (medium)", sand_boulder, 10), ("Sand mound (large)", sand_mound, 24)]),
]
GAP = 5  # studs between assets
PX_PER_STUD = 20
H = 400


class Shifted:
    """Kit wrapper that offsets everything a builder adds along x."""

    def __init__(self, kit, dx):
        self.kit, self.dx = kit, dx

    def box(self, name, lo, hi, color, rot=None, plain=False):
        self.kit.box(name, (lo[0] + self.dx, lo[1], lo[2]), (hi[0] + self.dx, hi[1], hi[2]), color, rot, plain)

    def at(self, name, centre, size, color, rot=None):
        self.kit.at(name, (centre[0] + self.dx, centre[1], centre[2]), size, color, rot)


def row_image(name, ground, items):
    """One scene per biome, assets side by side, a long lens so sizes compare."""
    k = Kit()
    entries = [("", figure, 4)] + items
    total = sum(w for _, _, w in entries) + GAP * (len(entries) - 1)
    x = -total / 2
    centres = []
    for label, builder, w in entries:
        # the camera looks down +z at the assets' fronts, so +x is on screen left
        builder(Shifted(k, -(x + w / 2)))
        centres.append((label, -(x + w / 2)))
        x += w + GAP
    partlib.GROUND = np.array(ground[1], float)
    partlib.GROUND2 = np.array(ground[0], float)
    W = int((total + 8) * PX_PER_STUD)
    eye, target, fov = (0, 60, -150), (0, 4, 0), 2 * np.degrees(np.arctan(H / 2 / PX_PER_STUD / 162))
    img = render(k.parts, eye=eye, target=target, W=W, H=H, fov=fov, fog=False)
    e, r, u, f = partlib.look_at(eye, target)
    focal = (H / 2) / np.tan(np.radians(fov) / 2)
    band = 36
    out = Image.new("RGB", (W, H + band), (255, 255, 255))
    out.paste(img, (0, band))
    d = ImageDraw.Draw(out)
    d.text((8, 8), name, fill=(130, 130, 130), font=font(18))
    for label, cx in centres:
        dv = np.array([cx, 0, 0]) - e
        px = W / 2 + focal * (dv @ r) / (dv @ f)
        tw = d.textlength(label, font=font(16))
        d.text((px - tw / 2, 10), label, fill=(20, 20, 20), font=font(16))
    return out


def main(out):
    os.makedirs(out, exist_ok=True)
    rows = [row_image(*row) for row in ROWS]
    board = Image.new("RGB", (max(r.width for r in rows), sum(r.height for r in rows)), (255, 255, 255))
    y = 0
    for r in rows:
        board.paste(r, (0, y))
        y += r.height
    board.save(os.path.join(out, "terrain_assets.png"))
    print("wrote", out)


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "/mnt/project-files/biomes/terrain_assets")
