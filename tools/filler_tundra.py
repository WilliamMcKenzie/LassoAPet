"""Tundra padding animals (see tools/filler_core.py)."""

from filler_core import F, quad, bird, fish, mound, bug, ICE_EYE  # noqa: F401

SNOW = (244, 248, 255)
PINK = (244, 168, 186)


def arctic_fox():
    a = F("ArcticFox")
    a.label = "Arctic Fox"
    fur = (246, 248, 252)
    quad(a, fur, 0.9, 1.4, 3.0, -1.6, 1.8, legw=0.4, legd=0.5, foot_h=0.2, foot=(210, 216, 230), hw=0.8, hh=1.3,
         hl=1.2, hy=2.6, snout=(0.4, 0.6, 0.9), nose_c=(40, 40, 50), ears=("up", 0.35, 0.8), ear_in=(220, 226, 240),
         tail=("long", 2.2, 1.1))
    return a


def seal():
    a = F("Seal")
    grey, spot = (170, 180, 196), (130, 140, 160)
    a.C("Body", 1.3, 0.0, 2.0, -1.4, 1.6, grey)
    a.C("Spot", 1.31, 1.0, 1.6, -0.2, 0.6, spot)
    a.C("Rear", 1.0, 0.0, 1.4, 1.6, 2.8, grey)
    a.S("Flipper", 0.2, 1.1, 0.0, 0.3, 2.8, 3.8, spot)
    a.C("Head", 1.0, 1.2, 3.0, -2.6, -1.0, grey, "neck")
    a.C("Snout", 0.6, 1.3, 2.0, -3.2, -2.6, (200, 206, 220), "neck")
    a.nose(0.3, 1.7, 2.0, -3.2, (40, 40, 50))
    a.eyes2(1.0, 2.1, 2.6, -2.5, -2.0)
    a.S("Fin", 1.3, 2.0, 0.0, 0.3, -1.2, -0.3, spot)
    return a


def arctic_hare():
    a = F("ArcticHare")
    a.label = "Arctic Hare"
    fur = (250, 250, 252)
    quad(a, fur, 0.9, 0.6, 2.2, -1.0, 1.4, legw=0.45, legd=0.5, foot_h=0, hw=0.75, hh=1.2, hl=1.1, hy=1.8,
         nose_c=PINK, ears=("up", 0.35, 1.5), ear_in=(240, 220, 226), tail=("stub", 0.7))
    return a


def lemming():
    a = F("Lemming", "burrower")
    fur, dark = (200, 150, 100), (70, 56, 50)
    mound(a, 1.6, 1.0, SNOW, (226, 236, 250), z=0.4)
    a.C("Body", 0.8, 0.6, 2.0, -0.8, 0.8, fur)
    a.C("Back", 0.4, 1.8, 2.05, -0.8, 0.8, dark)
    a.C("Head", 0.7, 0.8, 2.0, -1.8, -0.8, fur, "neck")
    a.nose(0.2, 1.2, 1.4, -1.8, PINK)
    a.eyes2(0.7, 1.45, 1.75, -1.7, -1.4)
    a.S("Ear", 0.3, 0.55, 2.0, 2.3, -1.2, -1.0, fur, "neck")
    a.S("Paw", 0.4, 0.9, 0.6, 0.9, -2.1, -1.6, (230, 190, 170))
    return a


def ermine():
    a = F("Ermine")
    white, blk = (250, 250, 252), (30, 30, 36)
    quad(a, white, 0.6, 0.6, 1.6, -2.0, 2.0, legw=0.3, legd=0.45, foot_h=0, hw=0.55, hh=0.9, hl=1.0, hy=1.2,
         nose_c=PINK, ears=("round", 0.3), tail=("long", 1.4, 0.45))
    a.C("TailTip", 0.25, 1.0, 1.45, 3.4, 4.2, blk)
    return a


def puffin():
    a = F("Puffin")
    blk, white = (36, 36, 44), (250, 250, 250)
    bird(a, blk, w=0.8, leg_h=0.4, bh=1.8, z0=-0.9, z1=0.9, hw=0.65, hh=1.1, hl=1.1, head_y=2.0, belly=white,
         beak_c=(240, 110, 50), beak_l=0.7, beak_w=0.4, leg_c=(240, 120, 50), tail_l=0.4)
    a.S("Cheek", 0.65, 0.66, 2.2, 2.9, -1.0, -0.2, white, "neck")
    return a


def snowy_owl():
    a = F("SnowyOwl", "flyer")
    a.label = "Snowy Owl"
    white, fleck = (250, 250, 252), (60, 60, 70)
    bird(a, white, w=1.0, leg_h=0, bh=2.0, z0=-0.9, z1=0.9, hw=1.0, hh=1.3, hl=1.4, head_y=2.0, beak_c=(60, 60, 60),
         beak_l=0.4, beak_w=0.2, span=3.4, chord=1.4, tail_l=0.8, fly=4.0, pupil=(240, 190, 40))
    a.C("Fleck", 1.01, 4.6, 5.0, -0.4, 0.2, fleck)
    a.C("Fleck2", 1.01, 5.3, 5.6, 0.2, 0.6, fleck)
    return a


def ice_moth():
    a = F("IceMoth", "flyer")
    a.label = "Ice Moth"
    body, wing, glow = (220, 230, 250), (150, 210, 250), (90, 200, 250)
    a.C("Body", 0.4, 3.0, 3.8, -0.8, 1.4, body)
    a.C("Head", 0.4, 3.1, 3.7, -1.4, -0.8, body, "neck")
    a.eyes2(0.4, 3.3, 3.6, -1.35, -1.1, (40, 60, 120))
    a.S("Wing", 0.4, 2.6, 3.6, 3.75, -1.0, 0.6, wing)
    a.S("Wing2", 0.4, 1.8, 3.6, 3.75, 0.6, 1.8, wing)
    a.S("Spot", 1.2, 1.9, 3.75, 3.8, -0.5, 0.2, glow)
    a.S("Feeler", 0.15, 0.3, 3.7, 4.5, -1.4, -1.2, body, "neck")
    return a


def wolverine():
    a = F("Wolverine")
    fur, band, face = (80, 60, 50), (200, 160, 110), (60, 46, 40)
    quad(a, fur, 1.2, 0.8, 2.6, -1.8, 1.8, legw=0.5, legd=0.6, foot_h=0.2, foot=(30, 26, 26), hw=0.9, hh=1.3, hl=1.1,
         hy=1.4, hc=face, snout=(0.45, 0.6, 0.5), nose_c=(30, 26, 26), ears=("round", 0.35), tail=("long", 1.2, 0.8))
    a.S("Stripe", 1.2, 1.21, 1.8, 2.2, -1.8, 1.8, band)
    return a


def musk_ox():
    a = F("MuskOx")
    a.label = "Musk Ox"
    fur, skirt, horn = (90, 70, 56), (70, 54, 44), (230, 220, 196)
    h = quad(a, fur, 1.9, 2.0, 5.6, -2.6, 2.6, legw=0.7, foot=(220, 210, 190), foot_h=0.4, belly=skirt, belly_h=1.0,
             hw=1.1, hh=2.0, hl=1.6, hy=3.0, snout=(0.7, 0.9, 0.6), snout_c=(120, 100, 86))
    a.C("Skirt", 1.95, 1.0, 2.2, -2.5, 2.5, skirt)
    a.C("Hump", 1.6, 5.6, 6.4, -2.6, -0.4, fur)
    a.S("Horn", 0.2, 1.3, h["y1"], h["y1"] + 0.5, h["z1"] - 1.2, h["z1"] - 0.4, horn, "neck")
    a.SP("HornTip", 1.3, 1.6, h["y1"] - 0.6, h["y1"] + 0.5, h["z1"] - 1.2, h["z1"] - 0.4, "-y", 1.2, horn, "neck")
    return a


# ---------------------------------------------------------------- rare

def walrus():
    a = F("Walrus", rare=True)
    skin, whisk, tusk = (180, 130, 110), (230, 210, 180), (250, 246, 230)
    a.C("Body", 2.4, 0.0, 4.4, -2.4, 2.6, skin)
    a.C("Rear", 1.8, 0.0, 3.0, 2.6, 4.4, skin)
    a.S("Flipper", 0.3, 1.8, 0.0, 0.4, 4.4, 5.6, (150, 104, 90))
    a.S("Fin", 2.4, 3.4, 0.0, 0.4, -2.0, -0.6, (150, 104, 90))
    a.C("Head", 1.8, 2.6, 5.4, -4.2, -2.2, skin, "neck")
    a.C("Muzzle", 1.4, 2.6, 3.8, -4.8, -4.2, whisk, "neck")
    a.eyes2(1.8, 4.3, 4.8, -4.0, -3.5)
    a.SP("Tusk", 0.6, 1.1, 2.6, 2.6, -4.8, -4.3, "-y", 2.2, tusk, "neck")
    return a


def reindeer():
    a = F("Reindeer", rare=True)
    fur, mane, antler = (150, 110, 80), (236, 226, 210), (220, 200, 160)
    h = quad(a, fur, 1.3, 3.4, 5.8, -2.4, 2.4, legw=0.5, foot=(60, 50, 44), foot_h=0.4, neck=(0.7, 1.1), hy=6.6,
             hw=0.8, hh=1.3, hl=1.7, snout=(0.6, 0.8, 0.5), nose_c=(220, 50, 50), ears=("side", 0.6), tail=("stub", 0.6),
             tail_c=mane)
    a.C("Mane", 0.75, 4.8, 6.8, -2.6, -1.3, mane, "neck")
    for side, sx in (("L", -1), ("R", 1)):
        x0, x1 = sorted((sx * 0.3, sx * 0.6))
        a.box("Antler" + side, (x0, h["y1"], h["z1"] - 0.6), (x1, h["y1"] + 2.4, h["z1"] - 0.3), antler, "neck")
        x0, x1 = sorted((sx * 0.6, sx * 1.6))
        a.box("Branch" + side, (x0, h["y1"] + 1.6, h["z1"] - 0.6), (x1, h["y1"] + 1.9, h["z1"] - 0.3), antler, "neck")
        a.P("Tine" + side, x1 - 0.3 if sx > 0 else x0, x1 if sx > 0 else x0 + 0.3, h["y1"] + 1.9, h["y1"] + 1.9,
            h["z1"] - 0.6, h["z1"] - 0.3, "+y", 1.2, antler, "neck")
        a.P("Brow" + side, x0 if sx > 0 else x1 - 0.3, x0 + 0.3 if sx > 0 else x1, h["y1"] + 0.6, h["y1"] + 0.9,
            h["z1"] - 0.6, h["z1"] - 0.6, "-z", 1.0, antler, "neck")
    return a


def narwhal():
    a = F("Narwhal", rare=True)
    grey, spot = (180, 190, 206), (120, 130, 150)
    fish(a, grey, w=1.6, h=2.8, z0=-3.0, z1=3.0, belly=(236, 240, 248), fin_c=spot, dorsal=False)
    a.P("Tusk", -0.3, 0.3, 1.8, 2.4, -3.0, -3.0, "-z", 5.0, (250, 244, 220), "neck")
    a.C("Spot", 1.61, 2.6, 3.0, 0.0, 1.0, spot)
    return a


def snow_leopard():
    a = F("SnowLeopard", rare=True)
    a.label = "Snow Leopard"
    fur, spot = (230, 230, 226), (90, 90, 96)
    bands = [(-2.2, -1.2, fur), (-1.2, -0.8, spot), (-0.8, 0.2, fur), (0.2, 0.6, spot), (0.6, 2.2, fur)]
    quad(a, fur, 1.2, 2.0, 3.8, -2.2, 2.2, bands=bands, legw=0.5, foot_h=0, hw=0.95, hh=1.6, hl=1.4, hy=3.0,
         snout=(0.5, 0.6, 0.4), nose_c=PINK, ears=("round", 0.4), pupil=ICE_EYE, tail=("long", 3.6, 1.0))
    a.C("TailBand", 0.51, 2.7, 3.7, 4.2, 4.6, spot)
    return a


def glacier_mammoth():
    """Titan: a woolly mammoth as tall as a hill, frost on its back."""
    a = F("GlacierMammoth", "titan", rare=True)
    a.label = "Glacier Mammoth"
    fur, dark, tusk, ice = (130, 90, 64), (96, 66, 48), (250, 246, 230), (180, 226, 250)
    a.C("Body", 9.0, 14.0, 30.0, -11.0, 11.0, fur)
    a.C("Skirt", 9.2, 12.0, 16.0, -11.2, 11.2, dark)
    a.C("Hump", 7.0, 30.0, 34.0, -10.0, 0.0, fur)
    a.C("Frost", 7.05, 34.0, 35.0, -10.0, 0.0, ice)
    a.spikes("Icicle", (-4.0, 0.0, 4.0), 35.0, (-7.0, -3.0), 1.6, 2.6, ice)
    for leg, (sx, z) in {"FL": (-1, -7.5), "FR": (1, -7.5), "HL": (-1, 7.5), "HR": (1, 7.5)}.items():
        a.B("Leg" + leg, sx * 6.0 - 2.6, sx * 6.0 + 2.6, 2.0, 14.0, z - 2.6, z + 2.6, fur)
        a.B("Foot" + leg, sx * 6.0 - 2.8, sx * 6.0 + 2.8, 0.0, 2.0, z - 2.8, z + 2.8, dark)
    a.C("Head", 5.0, 20.0, 33.0, -17.0, -10.99, fur, "neck")
    a.eyes2(5.0, 27.0, 28.8, -16.2, -14.6)
    a.S("Ear", 5.0, 5.6, 22.0, 30.0, -12.0, -9.0, dark, "neck")
    a.C("Trunk", 1.8, 8.0, 22.0, -19.0, -16.99, fur, "neck")
    a.C("Trunk2", 1.4, 3.0, 8.0, -20.0, -17.2, fur, "neck")
    a.S("Tusk", 2.8, 4.0, 18.0, 20.0, -21.0, -17.0, tusk, "neck")
    a.SP("TuskTip", 2.8, 4.0, 18.0, 20.0, -21.0, -19.8, "+y", 5.0, tusk, "neck")
    return a


COMMON = [arctic_fox, seal, arctic_hare, lemming, ermine, puffin, snowy_owl, ice_moth, wolverine, musk_ox]
RARE = [walrus, reindeer, narwhal, snow_leopard, glacier_mammoth]
GROUND = ((238, 244, 252), (224, 234, 246))
