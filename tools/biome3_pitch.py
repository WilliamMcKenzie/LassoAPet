"""Biome 3 pitch: three candidate biomes as quick renders for QM to pick from.

Run: python3 tools/biome3_pitch.py [out_dir]

Each candidate gets two panels: the course (its ground and wall checker, its
obstacles, its Uncommon and Legendary as rough blockouts) and a level 3 pen
(the pen's 12x12 tiles in the biome's ground colours, posts in its post colour)
on the home grass. Blockouts are shape and colour only: no bones yet.
"""

import os
import sys

import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(__file__))
import partlib  # noqa: E402
from partlib import Part, T, render  # noqa: E402
import pens  # noqa: E402
from animal_designs import font  # noqa: E402

MEADOW = [(77, 196, 63), (105, 255, 74)]
EYE_W, PUP = (255, 255, 255), (30, 30, 45)


class Kit:
    def __init__(self, off=(0, 0, 0), k=1.0):
        self.parts, self.off, self.k = [], np.array(off, float), k

    def box(self, name, lo, hi, color, plain=False):
        lo = np.array(lo, float) * self.k + self.off
        hi = np.array(hi, float) * self.k + self.off
        self.parts.append(Part(name, hi - lo, T(*((lo + hi) / 2)), color, plain=plain))

    def eyes(self, x0, x1, y0, y1, z, side_x=None):
        """Plain eyes on a front face at z (toward -z), pupil set back from the plate."""
        for s in (-1, 1):
            a, b = sorted((s * x0, s * x1))
            self.box("Eye", (a, y0, z - 0.1), (b, y1, z), EYE_W, True)
            w, h = (b - a) * 0.5, (y1 - y0) * 0.55
            cx = (a + b) / 2
            self.box("Pupil", (cx - w / 2, y0 + 0.05, z - 0.075), (cx + w / 2, y0 + 0.05 + h, z), PUP, True)


def quad_legs(m, x_in, x_out, z_f, z_b, h, w, color, foot=None):
    for s in (-1, 1):
        a, b = sorted((s * x_in, s * x_out))
        for z in (z_f, z_b):
            m.box("Leg", (a, 0, z - w / 2), (b, h, z + w / 2), color)
            if foot:
                m.box("Foot", (a - 0.05, 0, z - w / 2 - 0.05), (b + 0.05, 0.6, z + w / 2 + 0.05), foot)


# ---------------------------------------------------------------- Snowy Peaks

def penguin(m):
    navy, white, beak = (44, 52, 78), (250, 250, 250), (255, 150, 40)
    m.box("Body", (-1.4, 0.5, -1.2), (1.4, 5.0, 1.3), navy)
    m.box("Belly", (-1.0, 0.7, -1.3), (1.0, 3.6, -1.2), white, True)
    m.box("Beak", (-0.4, 3.7, -2.0), (0.4, 4.2, -1.2), beak)
    m.eyes(0.5, 1.1, 4.1, 4.7, -1.2)
    for s in (-1, 1):
        a, b = sorted((s * 1.4, s * 1.8))
        m.box("Flipper", (a, 1.6, -0.6), (b, 3.8, 0.6), navy)
        a, b = sorted((s * 0.2, s * 1.2))
        m.box("Foot", (a, 0, -1.8), (b, 0.5, 0.2), beak)


def mammoth(m):
    fur, dark, tusk, snow = (158, 100, 64), (122, 74, 48), (250, 244, 226), (255, 255, 255)
    m.box("Body", (-3.2, 5, -3.5), (3.2, 11.5, 5), fur)
    m.box("Hump", (-2.6, 11.5, -3.5), (2.6, 12.6, 1.5), fur)
    m.box("Snow", (-2.7, 12.6, -3.0), (2.7, 13.0, 1.0), snow)
    m.box("Head", (-2.6, 6.5, -7), (2.6, 12, -3.5), fur)
    m.box("Trunk", (-0.8, 3, -8), (0.8, 8, -7), dark)
    m.box("TrunkTip", (-0.8, 2.2, -9), (0.8, 3.4, -7.6), dark)
    m.eyes(1.2, 2.0, 9.4, 10.4, -7)
    for s in (-1, 1):
        a, b = sorted((s * 1.3, s * 2.1))
        m.box("Tusk", (a, 5.5, -8.4), (b, 6.3, -7), tusk)
        m.box("TuskTip", (a, 6.3, -9.2), (b, 8.0, -8.4), tusk)
        a, b = sorted((s * 2.6, s * 3.6))
        m.box("Ear", (a, 7.5, -6.2), (b, 11.5, -4.2), dark)
    quad_legs(m, 1.0, 3.0, -2.0, 3.6, 5, 2.2, fur, dark)
    m.box("Tail", (-0.4, 7, 5), (0.4, 10, 5.8), dark)


def ice_block(m):
    m.box("Ice", (-4, 0, -4), (4, 8, 4), (168, 222, 250))
    m.box("Snow", (-4.2, 8, -4.2), (4.2, 9, 4.2), (255, 255, 255))


def snowman(m):
    w = (255, 255, 255)
    m.box("Base", (-3, 0, -3), (3, 5, 3), w)
    m.box("Mid", (-2.2, 5, -2.2), (2.2, 8.6, 2.2), w)
    m.box("Head", (-1.6, 8.6, -1.6), (1.6, 11.6, 1.6), w)
    m.box("Nose", (-0.3, 9.6, -3.0), (0.3, 10.2, -1.6), (255, 140, 40))
    for s in (-1, 1):
        a, b = sorted((s * 0.5, s * 1.1))
        m.box("Coal", (a, 10.5, -1.7), (b, 11.1, -1.6), PUP, True)
    for y in (6.0, 7.4):
        m.box("Button", (-0.35, y, -2.3), (0.35, y + 0.7, -2.2), PUP, True)


# ---------------------------------------------------------------- Volcano

def lava_lizard(m):
    red, belly, spike = (232, 84, 52), (255, 196, 70), (255, 150, 40)
    m.box("Body", (-1.5, 1.2, -2.5), (1.5, 3.0, 2.5), red)
    m.box("Head", (-1.2, 1.4, -5.0), (1.2, 3.2, -2.5), red)
    m.box("Belly", (-1.0, 1.1, -2.3), (1.0, 1.2, 2.3), belly, True)
    m.eyes(0.3, 1.0, 2.2, 2.9, -5.0)
    for i, z in enumerate((-1.5, 0, 1.5)):
        m.box("Spike", (-0.3, 3.0, z - 0.4), (0.3, 3.8, z + 0.4), spike)
    m.box("Tail", (-0.6, 1.3, 2.5), (0.6, 2.3, 6.0), red)
    quad_legs(m, 1.5, 2.3, -1.6, 1.6, 1.6, 0.8, red)


def dragon(m):
    red, belly, horn, wing = (224, 58, 52), (255, 206, 80), (255, 236, 150), (255, 140, 50)
    m.box("Body", (-2.6, 5, -3.5), (2.6, 9.5, 4.5), red)
    m.box("Belly", (-1.8, 4.9, -3.3), (1.8, 5.0, 4.3), belly, True)
    m.box("Neck", (-1.4, 8, -6), (1.4, 12.5, -3.5), red)
    m.box("Head", (-1.9, 11.5, -8.5), (1.9, 14.5, -4.2), red)
    m.box("Snout", (-1.4, 11.5, -10.5), (1.4, 13.2, -8.5), red)
    m.eyes(0.6, 1.5, 13.2, 14.2, -8.5)
    for s in (-1, 1):
        a, b = sorted((s * 0.9, s * 1.6))
        m.box("Horn", (a, 14.5, -6.0), (b, 16.6, -5.2), horn)
        a, b = sorted((s * 2.6, s * 9.5))
        m.box("Wing", (a, 9.2, -2.5), (b, 9.7, 3.0), wing)
        a, b = sorted((s * 2.6, s * 9.5))
        m.box("Spar", (a, 9.7, -2.8), (b, 10.3, -2.0), red)
    m.box("Tail", (-1.1, 6, 4.5), (1.1, 8.2, 11), red)
    m.box("TailTip", (-1.6, 6.2, 11), (1.6, 8.0, 12.6), belly)
    for z in (-2, 0, 2, 4):
        m.box("Ridge", (-0.35, 9.5, z - 0.5), (0.35, 10.5, z + 0.5), belly)
    quad_legs(m, 1.2, 2.6, -2.2, 3.2, 5, 1.8, red, belly)


def magma_rock(m):
    rock, lava = (70, 60, 70), (255, 120, 30)
    m.box("Rock", (-4.5, 0, -4), (4.5, 6, 4), rock)
    m.box("Rock2", (-3, 6, -3), (3.5, 10, 3), rock)
    m.box("Crack", (-2.5, 2, -4.1), (-1.9, 6, -4.0), lava, True)
    m.box("Crack2", (1.0, 5, -3.1), (1.6, 9, -3.0), lava, True)
    m.box("Top", (-1.5, 10, -1.5), (2.0, 10.4, 1.5), lava, True)


def obsidian_spike(m):
    ob = (48, 38, 64)
    m.box("Base", (-3, 0, -3), (3, 5, 3), ob)
    m.box("Mid", (-2, 5, -2), (2, 10, 2), ob)
    m.box("Tip", (-1, 10, -1), (1, 14, 1), ob)


# ---------------------------------------------------------------- Candy Land

def gummy_bear(m):
    red = (240, 60, 90)
    m.box("Body", (-1.6, 0.8, -1.2), (1.6, 4.6, 1.2), red)
    m.box("Head", (-1.5, 4.6, -1.3), (1.5, 7.4, 1.3), red)
    m.box("Muzzle", (-0.7, 4.9, -1.8), (0.7, 5.9, -1.3), (255, 120, 140))
    m.eyes(0.4, 1.0, 6.2, 6.8, -1.3)
    for s in (-1, 1):
        a, b = sorted((s * 0.8, s * 1.6))
        m.box("Ear", (a, 7.4, -0.4), (b, 8.2, 0.4), red)
        a, b = sorted((s * 1.6, s * 2.3))
        m.box("Arm", (a, 2.4, -0.5), (b, 4.2, 0.5), red)
        a, b = sorted((s * 0.3, s * 1.5))
        m.box("Leg", (a, 0, -0.9), (b, 0.8, 0.7), red)


def ginger_rex(m):
    cookie, icing, drops = (196, 124, 62), (255, 255, 255), [(255, 70, 90), (70, 200, 110), (80, 150, 255)]
    m.box("Body", (-2.4, 5, -2.5), (2.4, 10.5, 3.5), cookie)
    m.box("Neck", (-1.8, 10.5, -3.5), (1.8, 12, 0.5), cookie)
    m.box("Head", (-2.2, 11, -8), (2.2, 15, -1.5), cookie)
    m.box("Jaw", (-1.9, 10.0, -7.6), (1.9, 11.0, -2.5), cookie)
    m.box("Icing", (-2.25, 12.2, -8.1), (2.25, 12.5, -1.8), icing, True)
    m.eyes(0.8, 1.7, 13.4, 14.4, -8)
    for i, y in enumerate((6.2, 7.8, 9.4)):
        m.box("Drop", (-0.5, y, -2.9), (0.5, y + 0.8, -2.5), drops[i])
    for s in (-1, 1):
        a, b = sorted((s * 0.6, s * 2.4))
        m.box("Leg", (a, 0, -1.2), (b, 5, 2.2), cookie)
        m.box("Foot", (a, 0, -2.6), (b, 1, -1.2), cookie)
        m.box("Cuff", (a - 0.05, 3.2, -1.25), (b + 0.05, 3.6, 2.25), icing, True)
        a, b = sorted((s * 2.4, s * 3.2))
        m.box("Arm", (a, 8, -3.5), (b, 8.8, -1.5), cookie)
    m.box("Tail", (-1.3, 6.5, 3.5), (1.3, 9.5, 10), cookie)
    for z in (5.0, 7.0, 9.0):
        m.box("Stripe", (-1.35, 9.5, z - 0.25), (1.35, 9.55, z + 0.25), icing, True)


def gumdrop(m):
    g, sug = (80, 210, 120), (200, 255, 210)
    m.box("L1", (-4, 0, -4), (4, 3, 4), g)
    m.box("L2", (-3.2, 3, -3.2), (3.2, 5.5, 3.2), g)
    m.box("L3", (-2.2, 5.5, -2.2), (2.2, 7.2, 2.2), g)
    m.box("Sugar", (-2.3, 7.2, -2.3), (2.3, 7.5, 2.3), sug, True)


def lollipop(m):
    m.box("Stick", (-0.5, 0, -0.5), (0.5, 9, 0.5), (255, 255, 255))
    rings = [(255, 80, 150), (255, 255, 255), (255, 80, 150), (255, 220, 60)]
    for i, c in enumerate(rings):
        r = 4 - i
        m.box("Ring", (-r, 13 - r, -0.6 - i * 0.05), (r, 13 + r, 0.6 + i * 0.05), c)


BIOMES = [
    dict(name="Snowy Peaks", ground=[(214, 234, 252), (238, 247, 255)], wall=[(118, 176, 232), (142, 198, 246)],
         post=(120, 170, 225), obstacles=[ice_block, snowman], pets=(penguin, mammoth),
         roster="Penguin (U) · Snow Fox (R) · Polar Bear (E) · Mammoth (L)"),
    dict(name="Volcano", ground=[(200, 82, 58), (226, 104, 70)], wall=[(66, 56, 70), (86, 74, 90)],
         post=(48, 38, 64), obstacles=[magma_rock, obsidian_spike], pets=(lava_lizard, dragon),
         roster="Lava Lizard (U) · Magma Beetle (R) · Lava Golem (E) · Dragon (L)"),
    dict(name="Candy Land", ground=[(255, 178, 214), (255, 206, 230)], wall=[(120, 220, 194), (156, 238, 214)],
         post=(240, 70, 110), obstacles=[gumdrop, lollipop], pets=(gummy_bear, ginger_rex),
         roster="Gummy Bear (U) · Marshmallow Sheep (R) · Donut Turtle (E) · Gingerbread Rex (L)"),
]

W, H = 640, 440


def set_ground(colors):
    partlib.GROUND = np.array(colors[0], float)
    partlib.GROUND2 = np.array(colors[1], float)


def course(b):
    set_ground(b["ground"])
    parts = []
    # right-hand corridor wall, 4-stud checker
    for zi in range(-12, 12):
        for yi in range(4):
            c = b["wall"][(zi + yi) % 2]
            parts.append(Part("Wall", (4, 4, 4), T(26, yi * 4 + 2, zi * 4 + 2), c, plain=True))
    for f, off in zip(b["obstacles"], ((10, 0, 22), (-16, 0, 12))):
        k = Kit(off)
        f(k)
        parts += k.parts
    small, big = b["pets"]
    for f, off in ((small, (-9, 0, -4)), (big, (4, 0, -2))):
        k = Kit(off)
        f(k)
        parts += k.parts
    return render(parts, eye=(-30, 24, -40), target=(4, 4, 6), W=W, H=H, fov=42)


def pen(b):
    set_ground(MEADOW)
    parts = []
    for i in range(12):
        for j in range(12):
            c = b["ground"][(i + j) % 2]
            x, z = -24 + i * 4 + 2, -24 + j * 4 + 2
            parts.append(Part("Tile", (4, 0.2, 4), T(x, 0.1, z), c, plain=True))
    for name, size, centre, R, color, visible in pens.pen_parts(0, 0, "front"):
        if not visible:
            continue
        cf = np.eye(4)
        cf[:3, :3] = R
        cf[:3, 3] = centre + np.array([0, 0.2, 0])
        parts.append(Part(name, size, cf, b["post"] if name == "Post" else color))
    small, big = b["pets"]
    for f, off in ((small, (-10, 0.2, -6)), (big, (6, 0.2, 4))):
        k = Kit(off)
        f(k)
        parts += k.parts
    return render(parts, eye=(-34, 40, -58), target=(0, 2, 2), W=W, H=H, fov=44)


def main(out):
    os.makedirs(out, exist_ok=True)
    band = 70
    board = Image.new("RGB", (W * 2, (H + band) * len(BIOMES)), (255, 255, 255))
    d = ImageDraw.Draw(board)
    for i, b in enumerate(BIOMES):
        y = i * (H + band)
        d.text((16, y + 8), f"{chr(65 + i)}. {b['name']}", fill=(20, 20, 20), font=font(28))
        d.text((16, y + 42), b["roster"] + "   |   left: course   right: pen LV. 3", fill=(80, 80, 80), font=font(18))
        c, p = course(b), pen(b)
        board.paste(c, (0, y + band))
        board.paste(p, (W, y + band))
        row = Image.new("RGB", (W * 2, H))
        row.paste(c, (0, 0))
        row.paste(p, (W, 0))
        row.save(os.path.join(out, b["name"].replace(" ", "") + ".png"))
    board.save(os.path.join(out, "pitch.png"))
    print("wrote", out)


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "/mnt/project-files/biomes/biome3")
