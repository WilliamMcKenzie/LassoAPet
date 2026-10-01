"""Terrain assets for the meadow and desert (drafts for QM to vet).

Run: python3 tools/terrain_assets.py [out_dir] [--boulders | --redo | --snow]

  Meadow  small   Stone       a chunky grey rock
          small   Bush        a stepped round green bush
          medium  Boulder     a big grey rock with a darker base
  Desert  small   Sandstone   a stack of terracotta slabs, the floor's sandstone colours
          medium  Cactus      a saguaro in the Cactus pet's greens, ribs and spines
          medium  SandBoulder a rounded tan rock with darker bands
          large   SandMound   a stepped sand hill with a prickly pear and a dead bush on top
  Snow    small   Icicle      ice spikes breaking out of a snow drift
          medium  Pine        a snow-capped pine in three stepped tiers
          medium  IcicleLarge a tall ice crystal with leaning shards
          large   IceBoulder  tilted ice chunks under a snow drift

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


def rot(yaw=0, tilt_x=0, tilt_z=0):
    return Ry(yaw) @ Rx(tilt_x) @ Rz(tilt_z)


def stone(k):
    """A tilted chunk with a lit cap and a chip at its foot (boulder style, small)."""
    k.at("Stone", (0, 1.1, 0), (3.8, 2.6, 3.2), GREY, rot(20, 6, -10))
    k.at("Stone", (-0.2, 2.45, 0.1), (2.8, 0.6, 2.4), GREY_L, rot(26, 5, -13))
    k.at("Stone", (2.3, 0.4, -1.3), (1.4, 1.2, 1.2), GREY_D, rot(-30, 0, 12))


def bush(k):
    g, gl = (70, 168, 58), (98, 200, 74)
    k.box("Bush", (-2.8, 0, -2.4), (2.8, 2.4, 2.4), g)
    k.box("Bush", (-2.2, 2.4, -1.8), (2.2, 3.8, 1.8), gl)
    k.box("Bush", (-1.2, 3.8, -1.0), (1.2, 4.6, 1.0), gl)
    k.box("Bush", (-3.4, 0.4, -1.4), (-2.8, 2.0, 1.4), g)
    k.box("Bush", (2.8, 0.4, -1.4), (3.4, 2.0, 1.4), g)


def boulder(k):
    """Take A, a cluster: one big tilted chunk, a smaller one leaning on it and
    a pebble at its foot, each lit top / dark sides (stylized rock packs)."""
    k.at("Boulder", (0.2, 2.6, 0.3), (7.6, 6.4, 6.6), GREY, rot(18, 7, -9))
    k.at("Boulder", (-0.4, 5.9, 0.0), (5.4, 1.4, 4.8), GREY_L, rot(24, 6, -12))  # the lit cap
    k.at("Boulder", (-4.0, 1.4, -1.4), (3.6, 4.0, 3.4), GREY_D, rot(-20, -6, 16))
    k.at("Boulder", (3.8, 0.5, -2.8), (2.0, 1.6, 1.8), GREY, rot(35, 0, 8))


def boulder_b(k):
    """Take B, a split slab: two big halves leaning apart with a crack between."""
    k.at("Boulder", (-1.9, 2.8, 0), (4.2, 7.0, 6.4), GREY, rot(8, 0, 10))
    k.at("Boulder", (-2.3, 6.4, 0.2), (3.4, 0.8, 5.4), GREY_L, rot(8, 0, 10))
    k.at("Boulder", (2.1, 2.2, 0.3), (4.0, 5.6, 6.0), GREY_D, rot(-6, 4, -12))
    k.at("Boulder", (2.5, 5.1, 0.3), (3.2, 0.8, 5.0), GREY, rot(-6, 4, -12))


# ---------------------------------------------------------------- desert

STONE, STONE_L, STONE_D = (206, 146, 84), (222, 164, 100), (176, 116, 64)
SAND, SAND_L = (232, 188, 102), (250, 214, 130)
C_GREEN, C_RIB, C_SPINE = (118, 204, 64), (72, 150, 44), (214, 176, 96)  # the Cactus pet's


def sandstone(k):
    """Broken sandstone ledge: layered slabs tipped at different angles, the top
    one lit, with a chip beside (boulder style, small)."""
    k.at("Slab", (0, 0.6, 0), (5.0, 1.6, 4.0), STONE_D, rot(15, 0, 6))
    k.at("Slab", (-0.4, 1.8, 0.2), (4.0, 1.2, 3.2), STONE, rot(-10, 5, -9))
    k.at("Slab", (-0.2, 2.7, 0.1), (3.0, 0.8, 2.4), STONE_L, rot(-4, 7, -12))
    k.at("Slab", (2.8, 0.45, -1.6), (1.4, 1.0, 1.2), STONE, rot(40, 0, 14))


def ribbed(k, name, lo, hi, color=C_GREEN, rib=C_RIB):
    """A cactus block with a dark rib down the middle of each side: real ridges
    that stand D proud of the face (no flat plates)."""
    k.box(name, lo, hi, color)
    (x0, y0, z0), (x1, y1, z1) = lo, hi
    cx, cz = (x0 + x1) / 2, (z0 + z1) / 2
    D, W = 0.15, 0.1
    for a, b in (((cx - W, y0 + 0.2, z0 - D), (cx + W, y1 - 0.2, z0)),
                 ((cx - W, y0 + 0.2, z1), (cx + W, y1 - 0.2, z1 + D)),
                 ((x0 - D, y0 + 0.2, cz - W), (x0, y1 - 0.2, cz + W)),
                 ((x1, y0 + 0.2, cz - W), (x1 + D, y1 - 0.2, cz + W))):
        k.box("Rib", a, b, rib, plain=True)  # a thin ridge: no stud decal


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
    """Take A, a balanced rock (desert hoodoo): a banded base, a narrow neck and
    a wide tilted cap that overhangs it."""
    band, rock, top = (214, 162, 96), (234, 190, 122), (246, 208, 144)
    k.at("Rock", (0, 1.3, 0), (6.4, 3.0, 5.6), band, rot(12, 0, 0))
    k.at("Rock", (0.2, 3.4, 0.1), (3.6, 2.0, 3.4), rock, rot(-8, 0, 0))
    k.at("Rock", (0.6, 5.6, 0.2), (8.0, 2.6, 6.6), rock, rot(20, 5, -8))
    k.at("Rock", (0.4, 6.95, 0.1), (6.2, 0.7, 5.0), top, rot(20, 5, -8))
    k.at("Rock", (-3.6, 0.6, -2.2), (1.8, 1.4, 1.6), band, rot(40, 0, 10))


def sand_boulder_b(k):
    """Take B, wind-carved: a long rock leaning into the wind, banded, with a
    smaller chunk tucked behind."""
    band, rock, top = (214, 162, 96), (234, 190, 122), (246, 208, 144)
    k.at("Rock", (0, 2.2, 0), (8.6, 5.2, 5.4), rock, rot(10, 0, -16))
    k.at("Rock", (0, 1.6, 0), (8.8, 1.0, 5.6), band, rot(10, 0, -16))
    k.at("Rock", (0, 3.4, 0), (8.8, 1.0, 5.6), band, rot(10, 0, -16))
    k.at("Rock", (-0.8, 5.0, 0), (6.6, 0.6, 4.6), top, rot(10, 0, -16))
    k.at("Rock", (3.6, 1.2, 1.8), (3.2, 3.0, 3.0), band, rot(-25, 0, 10))


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
    """A dune: wide sand slabs piled at gentle, clashing tilts (boulder style,
    large), a lit crest on top with the prickly pear and dead bush."""
    sand, sand_l, crest = (224, 174, 90), (240, 198, 116), (250, 214, 140)
    k.at("Mound", (0, 0.6, 0), (24, 3.0, 18), sand, rot(8, 2, -4))
    k.at("Mound", (-1.5, 2.4, 0.5), (17, 2.6, 13), sand_l, rot(-12, -3, 5))
    k.at("Mound", (1.0, 4.0, -0.2), (11, 2.0, 9), sand, rot(14, 3, -6))
    k.at("Mound", (0.6, 5.1, -0.1), (8, 0.8, 6.4), crest, rot(18, 3, -7))
    k.at("Mound", (9.5, 0.3, -6.0), (4.0, 1.6, 3.4), sand_l, rot(35, 0, 10))
    top = 5.4
    prickly_pear(k, -1.2, top, 0.4)
    dead_bush(k, 2.6, top, -1.0)


# ---------------------------------------------------------------- snow

ICE, ICE_L, ICE_D = (150, 206, 244), (206, 236, 252), (112, 170, 228)
SNOW_W, SNOW_S = (246, 249, 252), (218, 228, 240)
PINE, PINE_L, BARK = (34, 122, 86), (48, 150, 104), (122, 80, 50)


def spike(k, name, x, z, h, w, color, cap, tilt=(0, 0, 0)):
    """A stepped ice spike: blocks narrowing to a point, tilted as one piece."""
    R = rot(*tilt)
    steps = [(w, 0.45), (w * 0.72, 0.3), (w * 0.46, 0.17), (w * 0.24, 0.08)]
    y = 0.0
    for i, (sw, frac) in enumerate(steps):
        sh = h * frac
        c = R[:3, :3] @ np.array([0, y + sh / 2, 0])
        k.at(name, (x + c[0], c[1], z + c[2]), (sw, sh, sw), cap if i == len(steps) - 1 else color, R)
        y += sh


def icicle(k):
    """Three ice spikes breaking out of a snow drift."""
    k.at("Icicle", (0, 0.4, 0), (4.4, 1.0, 3.8), SNOW_W, rot(12, 0, 0))
    spike(k, "Icicle", 0.2, 0, 5.2, 1.6, ICE, ICE_L, (10, 4, -8))
    spike(k, "Icicle", -1.3, 0.8, 3.2, 1.1, ICE_D, ICE_L, (-20, -6, 16))
    spike(k, "Icicle", 1.4, -0.9, 2.6, 0.9, ICE, ICE_L, (30, 8, -18))


def large_icicle(k):
    """A tall ice crystal with smaller shards leaning off it, on a snow drift."""
    k.at("IcicleLarge", (0, 0.5, 0), (8.0, 1.4, 6.8), SNOW_W, rot(-10, 0, 0))
    k.at("IcicleLarge", (-2.6, 0.9, 1.6), (3.0, 1.0, 2.6), SNOW_S, rot(20, 0, 0))
    spike(k, "IcicleLarge", 0, 0, 11.5, 3.0, ICE, ICE_L, (8, 3, -5))
    spike(k, "IcicleLarge", -2.2, 0.8, 6.5, 2.0, ICE_D, ICE_L, (-25, -5, 20))
    spike(k, "IcicleLarge", 2.3, -0.6, 5.0, 1.7, ICE, ICE_L, (35, 6, -22))
    spike(k, "IcicleLarge", 0.8, 2.0, 3.4, 1.2, ICE_D, ICE_L, (60, 18, 6))


def pine_tree(k):
    """A trunk and three stepped tiers of dark green, each dusted with snow."""
    k.box("Pine", (-0.8, 0, -0.8), (0.8, 3.0, 0.8), BARK)
    y = 2.6
    for w, h in ((9.0, 2.6), (6.8, 2.4), (4.6, 2.2)):
        k.box("Pine", (-w / 2, y, -w / 2), (w / 2, y + h, w / 2), PINE)
        k.box("Pine", (-w / 2 + 0.5, y + h, -w / 2 + 0.5), (w / 2 - 0.5, y + h + 0.5, w / 2 - 0.5), SNOW_W)
        y += h + 0.5
    k.box("Pine", (-1.2, y, -1.2), (1.2, y + 1.8, 1.2), PINE_L)
    k.box("Pine", (-0.9, y + 1.8, -0.9), (0.9, y + 2.3, 0.9), SNOW_W)


def ice_boulder(k):
    """Boulder style, large: two big tilted ice chunks leaning together, a lit
    cap under a snow drift, a shard at the foot."""
    k.at("IceBoulder", (-1.2, 3.8, 0.4), (11.0, 8.4, 9.6), ICE, rot(18, 8, -10))
    k.at("IceBoulder", (-1.8, 8.2, 0.2), (8.0, 1.4, 6.8), ICE_L, rot(24, 7, -13))
    k.at("IceBoulder", (-2.2, 9.1, 0.3), (5.4, 1.0, 4.4), SNOW_W, rot(30, 6, -12))
    k.at("IceBoulder", (5.0, 2.8, 1.4), (7.0, 6.0, 6.6), ICE_D, rot(-28, -7, 15))
    k.at("IceBoulder", (5.6, 5.8, 1.2), (4.6, 0.9, 4.2), SNOW_W, rot(-24, -6, 15))
    k.at("IceBoulder", (-7.2, 0.9, -3.4), (3.2, 2.4, 2.8), ICE_L, rot(40, 0, -10))
    k.at("IceBoulder", (2.0, 0.4, -4.6), (6.0, 1.0, 3.0), SNOW_W, rot(10, 0, 0))

def figure(k, x=0):
    """A 5-stud blocky figure for scale."""
    skin, shirt, pants = (245, 205, 48), (13, 105, 172), (40, 127, 71)
    k.box("Leg", (x - 1.0, 0, -0.5), (x, 2, 0.5), pants)
    k.box("Leg", (x, 0, -0.5), (x + 1.0, 2, 0.5), pants)
    k.box("Torso", (x - 1.0, 2, -0.5), (x + 1.0, 4, 0.5), shirt)
    k.box("Arm", (x - 2.0, 2, -0.5), (x - 1.0, 4, 0.5), skin)
    k.box("Arm", (x + 1.0, 2, -0.5), (x + 2.0, 4, 0.5), skin)
    k.box("Head", (x - 0.6, 4, -0.6), (x + 0.6, 5.2, 0.6), skin)


REDO = [
    ("Meadow", [(77, 196, 63), (105, 255, 74)], [("Stone (small)", stone, 6)]),
    ("Desert", [(232, 188, 102), (250, 214, 130)], [
        ("Sandstone (small)", sandstone, 7), ("Sand mound (large)", sand_mound, 26)]),
]

SNOW = [
    ("Snow", [(228, 234, 242), (244, 247, 251)], [
        ("Icicle (small)", icicle, 5), ("Pine tree (medium)", pine_tree, 9),
        ("Large icicle (medium)", large_icicle, 9), ("Ice boulder (large)", ice_boulder, 19)]),
]

BOULDERS = [
    ("Meadow", [(77, 196, 63), (105, 255, 74)], [
        ("Boulder A: cluster", boulder, 10), ("Boulder B: split", boulder_b, 10)]),
    ("Desert", [(232, 188, 102), (250, 214, 130)], [
        ("Sand boulder A: balanced", sand_boulder, 10), ("Sand boulder B: wind-carved", sand_boulder_b, 11)]),
]

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
    which = "boulders" if "--boulders" in sys.argv else "redo" if "--redo" in sys.argv else "snow" if "--snow" in sys.argv else "terrain_assets"
    rows = [row_image(*row) for row in {"boulders": BOULDERS, "redo": REDO, "snow": SNOW, "terrain_assets": ROWS}[which]]
    board = Image.new("RGB", (max(r.width for r in rows), sum(r.height for r in rows)), (255, 255, 255))
    y = 0
    for r in rows:
        board.paste(r, (0, y))
        y += r.height
    board.save(os.path.join(out, which + ".png"))
    print("wrote", out)


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    main(args[0] if args else "/mnt/project-files/biomes/terrain_assets")
