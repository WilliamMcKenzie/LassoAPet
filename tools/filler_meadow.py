"""Meadow padding animals (see tools/filler_core.py)."""

from filler_core import F, quad, bird, mound, bug, RED_EYE  # noqa: F401

PINK = (244, 168, 186)
DIRT = (140, 98, 62)


def sheep():
    a = F("Sheep")
    wool, face = (246, 244, 236), (70, 64, 70)
    quad(a, wool, 1.9, 2.2, 5.4, -2.6, 2.6, legw=0.7, foot_h=0, hw=1.0, hh=2.0, hl=1.8, hy=3.6, hc=face,
         ears=("side", 0.8), ear_c=face, tail=("stub", 0.9))
    for p in a.parts:
        if p.name.startswith("Leg"):
            p.color = face
    a.C("WoolCap", 1.1, 5.6, 6.2, -4.0, -2.9, wool, "neck")  # fluffy fringe on top of the head
    return a


def cow():
    a = F("Cow")
    white, black = (250, 250, 246), (44, 44, 50)
    bands = [(-3.0, -1.4, white), (-1.4, 0.2, black), (0.2, 1.6, white), (1.6, 3.2, black)]
    h = quad(a, white, 2.0, 3.0, 6.4, -3.0, 3.2, bands=bands, legw=0.8, foot=(60, 60, 64), foot_h=0.5,
             hw=1.3, hh=2.3, hl=2.0, hy=4.8, snout=(1.3, 1.2, 0.8), snout_c=PINK, nose_c=(200, 110, 130),
             ears=("side", 0.8), tail=("rope", 2.4))
    a.SP("Horn", 0.7, 1.1, h["y1"], h["y1"], h["z1"] - 1.2, h["z1"] - 0.8, "+y", 0.9, (240, 230, 200), "neck")
    return a


def duck():
    a = F("Duck")
    bird(a, (250, 250, 248), w=0.9, leg_h=0.8, bh=1.6, z0=-1.2, z1=1.3, hw=0.7, hh=1.4, hl=1.3, head_y=2.0,
         beak_c=(250, 160, 40), beak_l=0.9, beak_w=0.5, tail_l=0.6)
    return a


def mole():
    a = F("Mole", "burrower")
    fur, pink = (78, 66, 70), (246, 160, 176)
    mound(a, 2.4, 1.6, DIRT)
    a.C("Body", 1.1, 1.2, 3.4, -1.0, 0.9, fur)
    a.C("Head", 0.9, 2.2, 3.8, -2.2, -0.6, fur, "neck")
    a.C("Snout", 0.45, 2.4, 3.0, -2.9, -2.2, pink, "neck")
    a.nose(0.3, 2.65, 2.95, -2.9, (200, 90, 110))
    a.eyes2(0.9, 3.2, 3.5, -2.0, -1.75)
    a.S("Paw", 0.8, 1.6, 1.6, 2.0, -2.4, -1.4, pink)
    a.spikes("Claw", (-1.4, -1.0, 1.0, 1.4), 2.0, (-2.2,), 0.3, 0.4, (240, 236, 220))
    return a


def hedgehog():
    a = F("Hedgehog")
    spine, face = (110, 82, 58), (228, 196, 160)
    quad(a, spine, 1.2, 0.5, 2.3, -1.4, 1.6, legw=0.5, legd=0.5, foot_h=0, hw=0.8, hh=1.2, hl=1.0, hy=0.7,
         hc=face, snout=(0.35, 0.5, 0.5), nose_c=(40, 30, 30), ears=("round", 0.35))
    a.spikes("Spike", (-0.8, 0.0, 0.8), 2.3, (-1.0, -0.1, 0.8), 0.7, 0.8, (90, 64, 44))
    a.SP("SideSpike", 1.2, 1.2, 1.2, 1.8, -0.6, 0.6, "+x", 0.6, (90, 64, 44))
    return a


def goat():
    a = F("Goat")
    coat = (236, 230, 216)
    h = quad(a, coat, 1.3, 2.6, 4.8, -2.2, 2.2, legw=0.55, foot=(80, 70, 66), foot_h=0.4, neck=(0.7, 1.0), hy=5.2,
             hw=0.8, hh=1.5, hl=1.8, ears=("side", 0.7), tail=("up", 0.8, 0.5))
    a.C("Beard", 0.25, h["y0"] - 0.8, h["y0"], h["hz0"], h["hz0"] + 0.5, (200, 194, 180), "neck")
    a.SP("Horn", 0.3, 0.7, h["y1"], h["y1"], h["z1"] - 0.6, h["z1"] - 0.2, "+z", 1.4, (140, 120, 100), "neck")
    return a


def frog():
    a = F("Frog")
    g, belly = (110, 196, 80), (224, 236, 160)
    a.C("Belly", 1.3, 0.3, 0.9, -1.4, 1.2, belly)
    a.C("Body", 1.3, 0.9, 2.1, -1.4, 1.2, g)
    a.S("Thigh", 1.3, 1.9, 0.0, 1.2, 0.0, 1.4, g)
    a.S("Foot", 1.6, 2.4, 0.0, 0.25, -0.4, 0.4, (90, 170, 60))
    a.S("Arm", 0.7, 1.1, 0.0, 0.9, -1.4, -0.9, g)
    # bulging eyes on top, at the sides
    for side, sx in (("L", -1), ("R", 1)):
        x0, x1 = sorted((sx * 0.5, sx * 1.3))
        a.box("Bulge" + side, (x0, 2.1, -1.4), (x1, 2.8, -0.6), g, "neck")
    a.eyes2(1.3, 2.15, 2.65, -1.3, -0.8)
    a.B("PlainMouth", -1.0, 1.0, 1.05, 1.2, -1.45, -1.4, (60, 120, 50), "neck")
    return a


def snail():
    a = F("Snail")
    body, shell, ring = (200, 210, 150), (196, 120, 70), (150, 84, 50)
    a.C("Foot", 0.6, 0, 0.6, -1.8, 1.4, body)
    a.C("Neck", 0.5, 0.6, 1.8, -1.8, -1.0, body, "neck")
    a.S("Stalk", 0.15, 0.35, 1.8, 2.6, -1.6, -1.4, body, "neck")
    a.S("PlainBall", 0.1, 0.45, 2.6, 2.95, -1.68, -1.33, (40, 40, 50), "neck")
    a.C("Shell", 0.8, 0.6, 2.6, -0.8, 1.2, shell)
    a.C("Ring", 0.85, 1.2, 2.0, -0.3, 0.7, ring)
    return a


def bee():
    a = F("Bee", "flyer")
    yel, blk = (250, 206, 50), (40, 36, 40)
    a.C("Head", 0.7, 3.0, 4.2, -2.0, -0.9, blk, "neck")
    a.eyes2(0.7, 3.5, 3.95, -1.85, -1.4)
    for i, (z0, z1, c) in enumerate(((-0.9, -0.2, yel), (-0.2, 0.4, blk), (0.4, 1.0, yel), (1.0, 1.5, blk))):
        a.C(f"Body{i + 1}", 0.9, 2.8, 4.4, z0, z1, c)
    a.P("Stinger", -0.35, 0.35, 3.25, 3.95, 1.5, 1.5, "+z", 0.8, blk)
    a.S("Wing", 0.3, 1.8, 4.4, 4.6, -0.7, 0.5, (220, 240, 255))
    a.S("Antenna", 0.25, 0.4, 4.2, 4.9, -1.9, -1.75, blk, "neck")
    return a


def hamster():
    a = F("Hamster")
    fur, cream = (232, 168, 96), (250, 236, 210)
    quad(a, fur, 1.0, 0.3, 1.9, -1.0, 1.0, legw=0.4, legd=0.4, foot_h=0, belly=cream, belly_h=0.5, hw=0.95,
         hh=1.4, hl=1.0, hy=0.4, nose_c=(220, 120, 140), ears=("round", 0.4), ear_in=PINK)
    a.S("Cheek", 0.95, 1.2, 0.6, 1.2, -2.0, -1.2, cream, "neck")
    return a


# ---------------------------------------------------------------- rare

def owl():
    a = F("Owl", "flyer", rare=True)
    brown, cream = (150, 110, 70), (236, 214, 170)
    bird(a, brown, w=1.4, leg_h=0, bh=3.0, z0=-1.2, z1=1.2, hw=1.4, hh=1.8, hl=2.0, head_y=3.0, belly=cream,
         beak_c=(240, 180, 60), beak_l=0.6, beak_w=0.3, span=4.0, chord=1.8, tail_l=1.2, fly=4.0, pupil=(30, 20, 10))
    a.SP("Tuft", 0.8, 1.4, 4.8, 4.8, -0.6, -0.2, "+y", 0.9, brown, "neck")
    return a


def giraffe():
    a = F("Giraffe", rare=True)
    coat, spot = (240, 196, 100), (170, 104, 46)
    bands = [(-2.6, -1.4, coat), (-1.4, -0.6, spot), (-0.6, 0.6, coat), (0.6, 1.4, spot), (1.4, 2.6, coat)]
    h = quad(a, coat, 1.5, 6.0, 9.0, -2.6, 2.6, bands=bands, legw=0.6, foot=(90, 60, 40), foot_h=0.5,
             neck=(0.6, 1.2), hy=15.0, hw=0.8, hh=1.4, hl=2.4, ears=("side", 0.6), tail=("rope", 2.6))
    # neck patches as flush slices
    a.C("NeckSpot", 0.62, 11.0, 12.0, -2.6, -1.4, spot, "neck")
    a.C("NeckSpot2", 0.62, 13.0, 13.8, -2.6, -1.4, spot, "neck")
    a.SP("Ossicone", 0.3, 0.6, h["y1"], h["y1"], h["z1"] - 0.8, h["z1"] - 0.5, "+y", 0.8, spot, "neck")
    return a


def hippo():
    a = F("Hippo", rare=True)
    grey, pinkish = (150, 132, 160), (226, 160, 170)
    h = quad(a, grey, 2.8, 1.6, 6.6, -3.6, 3.6, legw=1.2, legd=1.6, foot_h=0.4, belly=pinkish, belly_h=0.8,
             hw=2.4, hh=3.4, hl=2.6, hy=2.6, snout=(2.6, 2.2, 1.6), snout_c=grey, ears=("round", 0.6), tail=("stub", 0.6))
    a.S("Nostril", 0.6, 1.2, h["y0"] + 2.2, h["y0"] + 2.3, h["z0"] + 0.3, h["z0"] + 0.9, (90, 70, 90), "neck")
    a.spikes("Tusk", (-1.8, 1.8), h["y0"] + 2.2, (h["z0"] + 0.4,), 0.5, 0.7, (250, 246, 230), bone="neck")
    return a


def badger():
    a = F("Badger", rare=True)
    grey, blk, white = (130, 130, 136), (36, 36, 40), (246, 246, 246)
    h = quad(a, grey, 1.4, 0.7, 2.6, -2.2, 2.4, legw=0.6, legd=0.7, foot=blk, foot_h=0.25, hw=1.0, hh=1.5, hl=1.6,
             hy=1.0, hc=white, snout=(0.5, 0.7, 0.8), snout_c=white, nose_c=blk, ears=("round", 0.35), ear_c=blk,
             tail=("stub", 0.6))
    a.C("Stripe", 0.3, h["y1"] - 0.01, h["y1"] + 0.05, h["hz0"] - 0.01, h["z1"], blk, "neck")
    a.S("Mask", 0.35, 1.01, 1.7, 2.1, h["hz0"] - 0.01, h["z1"], blk, "neck")
    return a


def hillback_tortoise():
    """Titan: a giant tortoise with a grassy hill and a tree on its shell."""
    a = F("HillbackTortoise", "titan", rare=True)
    a.label = "Hillback Tortoise"
    skin, shell, rim, grass, trunk, leaf = (150, 160, 110), (120, 90, 60), (90, 66, 44), (96, 186, 70), (110, 74, 44), (60, 150, 60)
    a.C("Shell", 8.0, 6.0, 14.0, -9.0, 9.0, shell)
    a.C("Rim", 8.4, 5.0, 6.6, -9.4, 9.4, rim)
    a.C("Hill", 6.5, 14.0, 17.0, -7.0, 7.0, grass)
    a.C("Hill2", 4.0, 17.0, 19.0, -4.0, 4.0, grass)
    a.B("Trunk", -1.0, 1.0, 19.0, 26.0, 0.0, 2.0, trunk)
    a.B("Leaves", -4.0, 4.0, 25.0, 30.0, -3.0, 5.0, leaf)
    a.B("Leaves2", -2.5, 2.5, 30.0, 32.0, -1.5, 3.5, leaf)
    for leg, (x, z) in {"FL": (-6, -6), "FR": (6, -6), "HL": (-6, 6), "HR": (6, 6)}.items():
        a.B("Leg" + leg, x - 2.0, x + 2.0, 0, 6.0, z - 2.0, z + 2.0, skin)
    a.S("Toe", 4.6, 7.4, 0, 0.8, -8.4, -8.0, (220, 214, 190))
    a.C("Neck", 2.2, 6.0, 10.0, -13.0, -9.0, skin, "neck")
    a.C("Head", 2.8, 8.0, 13.0, -17.0, -12.0, skin, "neck")
    a.B("PlainMouth", -2.0, 2.0, 9.0, 9.4, -17.05, -17.0, (70, 70, 50), "neck")
    a.eyes2(2.8, 11.0, 12.0, -16.4, -15.4)
    a.C("Tail", 0.8, 5.5, 7.0, 9.4, 11.0, skin)
    return a


COMMON = [sheep, cow, duck, mole, hedgehog, goat, frog, snail, bee, hamster]
RARE = [owl, giraffe, hippo, badger, hillback_tortoise]
GROUND = ((96, 196, 70), (88, 184, 64))
