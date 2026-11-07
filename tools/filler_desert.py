"""Desert padding animals (see tools/filler_core.py)."""

from filler_core import F, quad, bird, mound, bug  # noqa: F401

SAND = (232, 200, 140)
PINK = (244, 168, 186)


def fennec_fox():
    a = F("FennecFox")
    a.label = "Fennec Fox"
    fur, cream = (240, 200, 140), (252, 240, 220)
    quad(a, fur, 0.8, 1.0, 2.4, -1.2, 1.4, legw=0.35, legd=0.4, foot_h=0, belly=cream, belly_h=0.4, hw=0.75,
         hh=1.1, hl=1.0, hy=1.9, snout=(0.35, 0.5, 0.6), snout_c=cream, nose_c=(40, 30, 30),
         ears=("up", 0.55, 2.0), ear_in=PINK, tail=("long", 1.6, 0.7))
    a.C("TailTip", 0.35, 1.0, 1.7, 3.0, 3.6, (60, 44, 34))
    return a


def meerkat():
    a = F("Meerkat")
    fur, dark, cream = (200, 164, 110), (80, 60, 46), (236, 214, 170)
    a.C("Belly", 0.6, 0.5, 3.4, -0.75, -0.5, cream)
    a.C("Body", 0.7, 0.5, 3.4, -0.5, 0.5, fur)
    a.S("Foot", 0.2, 0.7, 0, 0.5, -0.8, 0.3, fur)
    a.S("Arm", 0.7, 0.95, 2.2, 3.0, -0.75, -0.3, fur)
    a.C("Head", 0.6, 3.4, 4.4, -0.8, 0.3, fur, "neck")
    a.C("Snout", 0.3, 3.5, 3.95, -1.4, -0.8, fur, "neck")
    a.nose(0.18, 3.7, 3.95, -1.4, (40, 30, 30))
    a.S("Mask", 0.6, 0.61, 3.75, 4.2, -0.8, -0.25, dark, "neck")
    a.eyes2(0.61, 3.8, 4.1, -0.75, -0.45)
    a.S("Ear", 0.6, 0.75, 4.0, 4.3, -0.1, 0.2, dark, "neck")
    a.C("Tail", 0.2, 0, 2.0, 0.5, 0.9, fur)
    a.C("TailTip", 0.2, 0, 0.4, 0.9, 1.6, dark)
    return a


def jackrabbit():
    a = F("Jackrabbit")
    fur, cream = (190, 160, 120), (240, 226, 200)
    quad(a, fur, 0.9, 0.9, 2.6, -1.2, 1.6, legw=0.4, legd=0.5, foot_h=0, belly=cream, belly_h=0.4, hw=0.7,
         hh=1.2, hl=1.2, hy=2.2, nose_c=PINK, ears=("up", 0.45, 2.6), ear_in=(230, 170, 150), tail=("up", 0.7, 0.7),
         tail_c=(250, 250, 250))
    a.S("HindFoot", 0.4, 0.9, 0, 0.3, 1.1, 2.6, fur)
    return a


def horned_lizard():
    a = F("HornedLizard")
    a.label = "Horned Lizard"
    skin, belly, horn = (200, 160, 110), (236, 214, 170), (130, 96, 70)
    quad(a, skin, 1.6, 0.4, 1.5, -1.6, 1.6, legw=0.5, legd=0.6, foot_h=0, belly=belly, belly_h=0.3, hw=1.0,
         hh=0.9, hl=1.0, hy=0.6, tail=("long", 1.8, 0.6))
    a.spikes("Back", (-0.9, 0.0, 0.9), 1.5, (-0.9, 0.0, 0.9), 0.45, 0.5, horn)
    a.spikes("Crown", (-0.7, -0.25, 0.25, 0.7), 1.5, (-1.7,), 0.3, 0.7, horn, bone="neck")
    a.SP("Side", 1.6, 1.6, 0.7, 1.1, -0.6, 0.6, "+x", 0.5, horn)
    return a


def roadrunner():
    a = F("Roadrunner")
    c, belly = (120, 104, 90), (236, 226, 206)
    bird(a, c, w=0.6, leg_h=1.6, bh=1.2, z0=-1.0, z1=1.0, hw=0.5, hh=0.9, hl=1.0, head_y=2.6, belly=belly,
         beak_c=(70, 60, 50), beak_l=1.3, beak_w=0.22, leg_c=(150, 130, 110), tail_l=2.4, tail_c=(70, 64, 60))
    a.P("Crest", -0.3, 0.3, 3.5, 3.5, -0.1, 0.4, "+y", 0.8, (70, 64, 60), "neck")
    return a


def sand_skink():
    a = F("SandSkink", "burrower")
    a.label = "Sand Skink"
    skin, band = (230, 180, 110), (190, 120, 70)
    mound(a, 2.0, 1.0, SAND, z=0.6)
    for i, (z0, z1, c) in enumerate(((-2.6, -1.8, skin), (-1.8, -1.4, band), (-1.4, -0.6, skin), (-0.6, -0.2, band))):
        a.C(f"Body{i + 1}", 0.5, 0.0, 0.9, z0, z1, c)
    a.C("Head", 0.55, 0.0, 0.85, -3.4, -2.6, skin, "neck")
    a.P("Nose", -0.4, 0.4, 0.05, 0.75, -3.4, -3.4, "-z", 0.6, skin, "neck")
    a.eyes2(0.55, 0.45, 0.7, -3.3, -3.05)
    a.S("Leg", 0.5, 0.9, 0, 0.3, -2.3, -1.9, skin)
    a.C("Tail", 0.3, 1.0, 1.6, 2.0, 3.6, skin)
    return a


def dung_beetle():
    a = F("DungBeetle")
    a.label = "Dung Beetle"
    shell, leg, dung = (50, 60, 80), (30, 34, 44), (130, 96, 60)
    bug(a, [("Head", 0.5, 0.4, 1.0, -1.4, -0.8, shell), ("Body", 0.8, 0.3, 1.4, -0.8, 1.0, shell)],
        leg_c=leg, leg_out=0.5, leg_t=0.2)
    a.eyes2(0.5, 0.65, 0.9, -1.35, -1.1)
    a.P("Horn", -0.15, 0.15, 1.0, 1.0, -1.3, -1.0, "+y", 0.5, leg, "neck")
    a.C("Ball", 1.1, 0.0, 2.2, 1.2, 3.4, dung)
    a.C("Ball2", 0.8, 0.3, 1.9, 0.9, 3.7, dung)
    return a


def armadillo():
    a = F("Armadillo")
    shell, ring, skin = (170, 150, 130), (130, 112, 96), (220, 180, 160)
    bands = [(-1.6, -0.9, shell), (-0.9, -0.6, ring), (-0.6, 0.0, shell), (0.0, 0.3, ring), (0.3, 0.9, shell), (0.9, 1.2, ring), (1.2, 1.8, shell)]
    quad(a, shell, 1.2, 0.5, 2.3, -1.6, 1.8, bands=bands, legw=0.4, legd=0.5, foot_h=0, hw=0.6, hh=0.9, hl=0.9,
         hy=0.9, hc=skin, snout=(0.3, 0.4, 0.6), nose_c=(120, 80, 70), ears=("up", 0.25, 0.6), tail=("long", 1.5, 0.4),
         tail_c=ring)
    for p in a.parts:
        if p.name.startswith("Leg"):
            p.color = skin
    return a


def gila_monster():
    a = F("GilaMonster")
    a.label = "Gila Monster"
    blk, orng = (50, 40, 44), (240, 120, 70)
    bands = [(-1.8, -1.0, orng), (-1.0, -0.4, blk), (-0.4, 0.4, orng), (0.4, 1.0, blk), (1.0, 1.8, orng)]
    h = quad(a, orng, 1.0, 0.45, 1.4, -1.8, 1.8, bands=bands, legw=0.4, legd=0.6, foot=blk, foot_h=0.1, hw=0.75,
             hh=0.8, hl=1.1, hy=0.55, hc=blk)
    a.C("Tail", 0.5, 0.55, 1.2, 1.8, 2.8, blk)
    a.C("Tail2", 0.4, 0.6, 1.1, 2.8, 3.6, orng)
    a.P("TailTip", -0.3, 0.3, 0.6, 1.1, 3.6, 3.6, "+z", 0.8, blk)
    return a


def coyote():
    a = F("Coyote")
    fur, cream, dark = (186, 150, 110), (236, 222, 196), (110, 90, 70)
    quad(a, fur, 1.0, 2.2, 4.0, -2.0, 2.0, legw=0.4, foot=dark, foot_h=0.3, belly=cream, belly_h=0.5, hw=0.8,
         hh=1.4, hl=1.3, hy=3.6, snout=(0.45, 0.7, 1.1), snout_c=cream, nose_c=(40, 30, 30), ears=("up", 0.4, 1.0),
         ear_in=(236, 200, 180), tail=("long", 2.2, 0.8))
    a.C("TailTip", 0.4, 3.0, 3.8, 4.2, 4.6, dark)
    return a


# ---------------------------------------------------------------- rare

def camel():
    a = F("Camel", rare=True)
    fur, dark = (214, 170, 110), (150, 110, 70)
    quad(a, fur, 1.6, 5.0, 8.0, -3.0, 3.0, legw=0.6, foot=dark, foot_h=0.5, neck=(0.6, 1.4), hy=9.6, hw=0.8,
         hh=1.3, hl=1.6, snout=(0.6, 0.9, 0.9), ears=("round", 0.3), tail=("rope", 2.0))
    a.C("Hump", 1.2, 8.0, 9.6, -2.2, -0.4, fur)
    a.C("Hump2", 1.2, 8.0, 9.6, 0.6, 2.4, fur)
    a.C("HumpTop", 0.8, 9.6, 10.2, -1.8, -0.8, fur)
    a.C("HumpTop2", 0.8, 9.6, 10.2, 1.0, 2.0, fur)
    return a


def vulture():
    a = F("Vulture", "flyer", rare=True)
    c, ruff, skin = (60, 52, 50), (236, 230, 220), (220, 140, 130)
    bird(a, c, w=1.2, leg_h=0, bh=2.0, z0=-1.4, z1=1.6, hw=0.6, hh=1.0, hl=1.2, head_y=2.0, head_dz=-1.0,
         beak_c=(220, 210, 180), beak_l=0.7, beak_w=0.3, span=6.0, chord=2.2, tail_l=1.4, fly=7.0)
    for p in a.parts:
        if p.name == "Head":
            p.color = skin
    a.C("Ruff", 1.0, 8.6, 9.4, -1.6, -0.6, ruff)
    return a


def oryx():
    a = F("Oryx", rare=True)
    coat, white, blk = (220, 200, 170), (250, 248, 240), (40, 36, 40)
    bands = [(-2.4, 2.4, coat)]
    h = quad(a, coat, 1.3, 3.2, 5.6, -2.4, 2.4, bands=bands, legw=0.5, foot=blk, foot_h=0.4, belly=white, belly_h=0.5,
             neck=(0.7, 1.1), hy=6.4, hw=0.8, hh=1.4, hl=1.6, hc=white, ears=("side", 0.6), tail=("rope", 2.0))
    a.C("Flank", 1.31, 3.7, 4.2, -2.4, 2.4, blk)
    a.S("FaceStripe", 0.8, 0.81, 6.9, 7.4, h["hz0"], h["z1"], blk, "neck")
    a.SP("Horn", 0.25, 0.55, h["y1"], h["y1"], h["z1"] - 0.6, h["z1"] - 0.3, "+y", 4.2, blk, "neck")
    return a


def ostrich():
    a = F("Ostrich", rare=True)
    blk, white, skin = (40, 36, 40), (250, 250, 250), (220, 170, 160)
    bird(a, blk, w=1.6, leg_h=5.0, bh=2.6, z0=-1.8, z1=1.8, hw=0.6, hh=1.0, hl=1.2, head_y=10.6, head_dz=-0.4,
         beak_c=(220, 180, 120), beak_l=0.6, beak_w=0.3, leg_c=skin, tail_l=0.1, wing_c=blk)
    a.C("Neck", 0.35, 7.4, 10.8, -1.9, -1.2, skin, "neck")
    a.C("TailPlume", 1.0, 6.6, 8.4, 1.8, 3.0, white)
    for p in a.parts:
        if p.name == "Head":
            p.color = skin
    return a


def mirage_elephant():
    """Titan: legs taller than the dunes; the body sits up in the haze."""
    a = F("MirageElephant", "titan", rare=True)
    a.label = "Mirage Elephant"
    skin, dark, tusk, cloth, gold = (190, 170, 160), (150, 132, 124), (250, 244, 224), (180, 60, 60), (240, 190, 60)
    y0, y1 = 44.0, 56.0
    a.C("Body", 7.0, y0, y1, -9.0, 9.0, skin)
    for leg, (sx, z) in {"FL": (-1, -6.5), "FR": (1, -6.5), "HL": (-1, 6.5), "HR": (1, 6.5)}.items():
        a.B("Leg" + leg, sx * 5.0 - 1.4, sx * 5.0 + 1.4, 2.0, y0, z - 1.4, z + 1.4, skin)
        a.B("Foot" + leg, sx * 5.0 - 2.0, sx * 5.0 + 2.0, 0.0, 2.0, z - 2.0, z + 2.0, dark)
    a.C("Blanket", 7.05, 50.0, 56.05, -4.0, 4.0, cloth)
    a.C("Trim", 7.1, 49.4, 50.0, -4.0, 4.0, gold)
    a.C("Head", 4.5, 46.0, 57.0, -14.0, -8.99, skin, "neck")
    a.eyes2(4.5, 52.0, 53.6, -13.4, -12.0)
    a.S("Ear", 4.5, 5.2, 46.0, 56.0, -10.0, -6.0, dark, "neck")
    a.C("Trunk", 1.4, 34.0, 48.0, -16.0, -13.99, skin, "neck")
    a.C("Trunk2", 1.0, 26.0, 34.0, -16.0, -14.0, skin, "neck")
    a.SP("Tusk", 2.0, 3.0, 44.0, 47.0, -14.0, -14.0, "-z", 4.0, tusk, "neck")
    a.C("Tail", 0.4, 46.0, 54.0, 9.0, 9.8, dark)
    return a


COMMON = [fennec_fox, meerkat, jackrabbit, horned_lizard, roadrunner, sand_skink, dung_beetle, armadillo, gila_monster, coyote]
RARE = [camel, vulture, oryx, ostrich, mirage_elephant]
GROUND = ((234, 206, 146), (222, 192, 132))
