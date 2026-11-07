"""Dungeon padding animals (see tools/filler_core.py). Parts named Glow* glow like Neon."""

from filler_core import F, grow, quad, bird, mound, bug, RED_EYE, GLOW_EYE  # noqa: F401

STONE = (110, 110, 120)
DARK = (70, 70, 80)
PINK = (236, 160, 176)


def rat():
    a = F("Rat")
    fur = (120, 110, 110)
    quad(a, fur, 0.7, 0.4, 1.6, -1.2, 1.2, legw=0.3, legd=0.35, foot_h=0.1, foot=PINK, hw=0.6, hh=0.9, hl=0.9,
         hy=0.7, snout=(0.3, 0.45, 0.6), nose_c=PINK, ears=("round", 0.45), ear_c=PINK, pupil=RED_EYE,
         tail=("long", 2.4, 0.25), tail_c=PINK)
    return a


def cave_bat():
    a = F("CaveBat", "flyer")
    a.label = "Cave Bat"
    fur, wing = (70, 56, 70), (50, 40, 56)
    a.C("Body", 0.6, 4.0, 5.2, -0.5, 0.7, fur)
    a.C("Head", 0.55, 4.8, 5.9, -1.0, -0.1, fur, "neck")
    a.eyes2(0.55, 5.2, 5.55, -0.95, -0.65, RED_EYE)
    a.SP("Ear", 0.1, 0.5, 5.9, 5.9, -0.6, -0.3, "+y", 1.0, fur, "neck")
    a.P("Fang", -0.15, 0.15, 4.8, 4.8, -1.05, -0.9, "-y", 0.4, (250, 250, 250), "neck")
    a.S("Wing", 0.6, 3.0, 4.8, 5.0, -0.4, 0.6, wing)
    a.SP("WingTip", 3.0, 3.0, 4.2, 5.0, -0.4, 0.4, "+x", 1.4, wing)
    a.S("Claw", 2.7, 3.0, 5.0, 5.4, -0.4, -0.1, wing)
    return a


def cave_spider():
    a = F("CaveSpider")
    a.label = "Cave Spider"
    body, leg = (60, 54, 64), (44, 40, 48)
    a.C("Abdomen", 1.2, 1.0, 2.6, 0.0, 2.2, body)
    a.C("Mark", 0.5, 2.6, 2.65, 0.6, 1.6, (200, 60, 60))
    a.C("Head", 0.8, 0.9, 2.0, -1.4, 0.0, body, "neck")
    for i, x in enumerate((-0.4, 0.4)):
        a.B(f"GlowEye{i}", x - 0.15, x + 0.15, 1.5, 1.8, -1.45, -1.4, RED_EYE, "neck")
    for i, z in enumerate((-1.2, -0.6, -0.1, 0.4)):
        a.S(f"Leg{i}", 0.8, 2.0, 1.4, 1.7, z - 0.12, z + 0.12, leg)
        a.S(f"Shin{i}", 1.8, 2.0, 0.0, 1.4, z - 0.12, z + 0.12, leg)
    a.SP("Fang", 0.1, 0.4, 0.9, 0.9, -1.4, -1.2, "-y", 0.5, (230, 220, 200), "neck")
    return a


def green_slime():
    a = F("GreenSlime")
    a.label = "Green Slime"
    g, core = (120, 220, 110), (70, 160, 70)
    a.C("Body", 1.6, 0.0, 2.8, -1.6, 1.6, g)
    a.C("Top", 1.1, 2.8, 3.4, -1.1, 1.1, g)
    a.C("Core", 0.7, 0.8, 1.8, -0.4, 0.6, core)
    a.C("Drip", 1.7, 0.0, 0.4, -1.7, 1.7, core)
    a.eyes2(1.6, 1.6, 2.3, -1.4, -0.8)
    return a


def centipede():
    a = F("Centipede")
    red, leg = (170, 60, 50), (230, 160, 70)
    a.C("Head", 0.6, 0.3, 1.1, -3.0, -2.2, red, "neck")
    a.eyes2(0.6, 0.65, 0.9, -2.9, -2.6)
    a.SP("Pincer", 0.2, 0.5, 0.3, 0.6, -3.0, -3.0, "-z", 0.6, leg, "neck")
    a.S("Antenna", 0.2, 0.35, 1.1, 1.9, -3.0, -2.85, leg, "neck")
    for i in range(5):
        z0 = -2.2 + i * 1.0
        a.C(f"Seg{i}", 0.55 - i * 0.04, 0.3, 1.0 - i * 0.04, z0, z0 + 0.9, red if i % 2 == 0 else (140, 46, 40))
        a.S(f"Leg{i}", 0.5, 1.1, 0.0, 0.25, z0 + 0.3, z0 + 0.6, leg)
    return a


def olm():
    a = F("Olm")
    skin, gill = (250, 214, 210), (240, 120, 140)
    a.C("Body", 0.5, 0.3, 1.1, -1.4, 1.6, skin)
    a.C("Head", 0.55, 0.3, 1.1, -2.6, -1.4, skin, "neck")
    a.S("Gill", 0.55, 0.9, 0.7, 1.2, -1.6, -1.4, gill, "neck")
    a.S("Gill2", 0.55, 0.8, 1.0, 1.5, -1.8, -1.6, gill, "neck")
    a.S("Leg", 0.5, 0.8, 0.0, 0.3, -1.0, -0.7, skin)
    a.S("Leg2", 0.5, 0.8, 0.0, 0.3, 1.0, 1.3, skin)
    a.C("Tail", 0.3, 0.4, 0.9, 1.6, 3.2, skin)
    a.W("TailFin", -0.1, 0.1, 0.9, 1.3, 1.8, 3.2, skin, "up_back")
    return a


def rust_beetle():
    a = F("RustBeetle")
    a.label = "Rust Beetle"
    shell, dark = (190, 100, 50), (110, 60, 40)
    bug(a, [("Head", 0.5, 0.4, 1.1, -1.6, -1.0, dark), ("Body", 1.0, 0.3, 1.7, -1.0, 1.4, shell)],
        leg_c=dark, leg_out=0.5, leg_t=0.22, antenna=0.8)
    a.eyes2(0.5, 0.7, 0.95, -1.55, -1.3)
    a.C("Split", 0.1, 1.7, 1.75, -1.0, 1.4, dark)
    a.S("Rivet", 0.35, 0.65, 1.7, 1.78, -0.3, 0.0, (230, 200, 120))
    return a


def tunnel_worm():
    a = F("TunnelWorm", "burrower")
    a.label = "Tunnel Worm"
    skin, ring = (200, 140, 140), (170, 110, 116)
    mound(a, 2.2, 1.0, STONE, DARK)
    for i, (w, y0, y1, dz) in enumerate(((1.0, 0.8, 2.0, 0.0), (0.95, 2.0, 3.0, -0.3), (0.9, 3.0, 3.8, -0.7))):
        a.C(f"Seg{i}", w, y0, y1, -1.0 + dz, 1.0 + dz, skin if i % 2 == 0 else ring)
    a.C("Head", 0.9, 3.4, 4.6, -2.4, -0.2, skin, "neck")
    a.B("PlainMouth", -0.6, 0.6, 3.6, 4.2, -2.45, -2.4, (80, 30, 40), "neck")
    a.spikes("Tooth", (-0.3, 0.3), 3.6, (-2.3,), 0.2, 0.3, (250, 250, 240), bone="neck")
    a.eyes2(0.9, 4.0, 4.35, -2.2, -1.9)
    return a


def crypt_snail():
    a = F("CryptSnail")
    a.label = "Crypt Snail"
    body, shell, moss = (180, 190, 200), (120, 120, 130), (90, 140, 80)
    a.C("Foot", 0.6, 0, 0.6, -1.8, 1.4, body)
    a.C("Neck", 0.5, 0.6, 1.8, -1.8, -1.0, body, "neck")
    a.S("Stalk", 0.15, 0.35, 1.8, 2.6, -1.6, -1.4, body, "neck")
    a.S("GlowBall", 0.1, 0.45, 2.6, 2.95, -1.68, -1.33, (140, 240, 200), "neck")
    a.C("Shell", 0.9, 0.6, 2.6, -0.8, 1.4, shell)
    a.C("Brick", 0.95, 1.4, 1.9, -0.8, 1.4, DARK)
    a.C("Moss", 0.7, 2.6, 2.8, -0.4, 1.0, moss)
    return a


def cave_cricket():
    a = F("CaveCricket")
    a.label = "Cave Cricket"
    body, leg = (190, 170, 140), (150, 130, 100)
    a.C("Head", 0.5, 0.6, 1.4, -1.6, -0.9, body, "neck")
    a.eyes2(0.5, 0.95, 1.2, -1.55, -1.3)
    a.C("Body", 0.6, 0.5, 1.6, -0.9, 1.4, body)
    a.S("Antenna", 0.15, 0.3, 1.4, 1.55, -4.0, -1.4, leg, "neck")
    a.S("Thigh", 0.6, 0.9, 1.0, 2.6, 0.6, 1.4, leg)
    a.S("Shin", 0.6, 0.9, 0.0, 1.0, 1.4, 2.2, leg)
    a.S("FrontLeg", 0.6, 0.9, 0.0, 0.5, -1.1, -0.8, leg)
    return a


# ---------------------------------------------------------------- rare

def mimic():
    a = F("Mimic", rare=True)
    wood, iron, tongue = (150, 100, 56), (90, 90, 100), (220, 80, 110)
    a.C("Chest", 1.8, 0.6, 2.6, -1.4, 1.4, wood)
    a.C("Band", 1.85, 0.6, 2.6, -0.3, 0.3, iron)
    a.C("Lid", 1.8, 3.2, 4.2, -1.4, 1.4, wood, "neck")
    a.C("LidBand", 1.85, 3.2, 4.2, -0.3, 0.3, iron, "neck")
    a.C("Tongue", 0.6, 2.4, 2.7, -3.0, 0.6, tongue)
    a.spikes("Tooth", (-1.3, -0.4, 0.4, 1.3), 2.6, (-1.2,), 0.35, 0.6, (250, 250, 240))
    a.spikes("TopTooth", (-0.9, 0.0, 0.9), 3.2, (-1.2,), 0.35, -0.6, (250, 250, 240), "-y", "neck")
    for i, x in enumerate((-0.6, 0.6)):
        a.B(f"GlowEye{i}", x - 0.25, x + 0.25, 2.75, 3.05, -1.0, -0.6, GLOW_EYE, "neck")
    for leg, (x, z) in {"FL": (-1.4, -1.0), "FR": (1.4, -1.0), "HL": (-1.4, 1.0), "HR": (1.4, 1.0)}.items():
        a.B("Leg" + leg, x - 0.3, x + 0.3, 0, 0.6, z - 0.3, z + 0.3, iron)
    grow(a, 1.8)
    return a


def lantern_toad():
    a = F("LanternToad", rare=True)
    a.label = "Lantern Toad"
    skin, belly = (70, 90, 100), (170, 190, 170)
    a.C("Belly", 1.8, 0.3, 1.0, -1.8, 1.6, belly)
    a.C("Body", 1.8, 1.0, 3.0, -1.8, 1.6, skin)
    a.S("Thigh", 1.8, 2.4, 0.0, 1.6, 0.0, 1.8, skin)
    a.S("Arm", 1.0, 1.5, 0.0, 1.1, -1.8, -1.2, skin)
    a.S("Bulge", 0.7, 1.8, 3.0, 3.6, -1.8, -0.9, skin, "neck")
    a.eyes2(1.8, 3.0, 3.5, -1.7, -1.2)
    a.C("Stalk", 0.15, 3.0, 5.4, -0.8, -0.5, skin, "neck")
    a.C("Stalk2", 0.15, 5.1, 5.4, -2.4, -0.5, skin, "neck")
    a.C("GlowLantern", 0.45, 4.0, 4.9, -2.85, -1.95, (250, 240, 140), "neck")
    a.C("Wire", 0.06, 4.9, 5.1, -2.46, -2.34, skin, "neck")
    grow(a, 1.5)
    return a


def cave_bear():
    a = F("CaveBear", rare=True)
    a.label = "Cave Bear"
    fur, snout = (90, 80, 76), (150, 130, 120)
    quad(a, fur, 2.2, 2.4, 6.4, -3.0, 3.0, legw=0.9, legd=1.4, foot_h=0.4, foot=(50, 44, 44), hw=1.6, hh=2.6, hl=2.2,
         hy=4.4, snout=(0.8, 1.2, 1.0), snout_c=snout, nose_c=(30, 26, 26), ears=("round", 0.6), pupil=RED_EYE,
         tail=("stub", 0.6))
    a.C("Hump", 1.8, 6.4, 7.2, -3.0, -0.6, fur)
    a.spikes("Crystal", (-0.8, 0.6), 7.2, (-2.2, -1.2), 0.6, 1.2, (150, 220, 250))
    return a


def basilisk():
    a = F("Basilisk", rare=True)
    green, belly, crest = (70, 120, 70), (200, 200, 140), (200, 60, 50)
    h = quad(a, green, 1.4, 1.2, 3.2, -2.6, 2.6, legw=0.5, legd=0.8, foot_h=0.2, foot=(40, 60, 40), belly=belly,
             belly_h=0.5, hw=1.0, hh=1.5, hl=2.0, hy=2.2, pupil=(240, 200, 40))
    a.C("Tail", 0.9, 1.6, 2.8, 2.6, 4.6, green)
    a.C("Tail2", 0.6, 1.8, 2.6, 4.6, 6.4, green)
    a.P("TailTip", -0.4, 0.4, 1.9, 2.5, 6.4, 6.4, "+z", 1.2, green)
    a.spikes("Crest", (0.0,), 3.2, (-2.0, -1.0, 0.0, 1.0, 2.0), 0.6, 0.9, crest)
    a.P("HeadCrest", -0.3, 0.3, h["y1"], h["y1"], h["hz0"] + 0.3, h["z1"] - 0.3, "+y", 1.4, crest, "neck")
    return a


def abyss_pillbug():
    """Titan: a giant cave isopod, banded armour plates as flush slices."""
    a = F("AbyssPillbug", "titan", rare=True)
    a.label = "Abyss Pillbug"
    plate, seam, leg = (150, 150, 170), (100, 100, 120), (200, 190, 200)
    for i in range(7):
        z0 = -14.0 + i * 4.0
        a.C(f"Plate{i}", 10.0 - abs(i - 3) * 0.8, 3.0, 13.0 - abs(i - 3) * 0.8, z0, z0 + 3.4, plate)
        a.C(f"Seam{i}", 9.6 - abs(i - 3) * 0.8, 3.0, 12.6 - abs(i - 3) * 0.8, z0 + 3.4, z0 + 4.0, seam)
    a.C("Head", 6.0, 3.0, 10.0, -18.0, -14.0, plate, "neck")
    a.eyes2(6.0, 7.0, 8.6, -17.4, -15.8, (30, 30, 40))
    a.S("Antenna", 2.0, 3.0, 8.0, 9.0, -28.0, -18.0, leg, "neck")
    a.S("Antenna2", 3.0, 3.8, 8.0, 14.0, -28.0, -27.0, leg, "neck")
    for i, z in enumerate((-10.0, -2.0, 6.0)):
        a.S(f"Leg{i}", 8.0, 10.0, 0.0, 3.0, z - 1.0, z + 1.0, leg)
    a.SP("Uropod", 3.0, 4.0, 4.0, 5.0, 14.0, 14.0, "+z", 4.0, seam)
    return a


COMMON = [rat, cave_bat, cave_spider, green_slime, centipede, olm, rust_beetle, tunnel_worm, crypt_snail, cave_cricket]
RARE = [mimic, lantern_toad, cave_bear, basilisk, abyss_pillbug]
GROUND = ((112, 112, 122), (100, 100, 110))
