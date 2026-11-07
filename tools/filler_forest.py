"""Forest padding animals (see tools/filler_core.py)."""

from filler_core import F, grow, quad, bird, mound, bug  # noqa: F401

DIRT = (110, 80, 54)
LEAF = (70, 150, 60)
PINK = (236, 160, 176)


def squirrel():
    a = F("Squirrel")
    fur, cream = (196, 110, 56), (250, 230, 200)
    quad(a, fur, 0.7, 0.5, 1.8, -1.0, 1.0, legw=0.3, legd=0.4, foot_h=0, belly=cream, belly_h=0.35, hw=0.65, hh=1.1,
         hl=0.9, hy=1.4, nose_c=(60, 40, 30), ears=("up", 0.25, 0.6))
    a.C("Tail", 0.6, 1.2, 3.6, 1.0, 1.9, fur)
    a.C("TailTop", 0.6, 3.0, 3.8, 0.0, 1.9, fur)
    a.C("Acorn", 0.3, 1.2, 1.7, -2.0, -1.5, (150, 100, 50), "neck")
    return a


def raccoon():
    a = F("Raccoon")
    fur, mask, white = (130, 126, 126), (40, 40, 44), (240, 240, 240)
    h = quad(a, fur, 1.1, 0.8, 2.6, -1.8, 1.8, legw=0.45, legd=0.6, foot_h=0.2, foot=mask, hw=0.95, hh=1.4, hl=1.2,
             hy=1.8, hc=white, snout=(0.4, 0.6, 0.5), nose_c=mask, ears=("up", 0.35, 0.7), ear_c=fur)
    a.S("Mask", 0.3, 0.96, 2.5, 2.9, h["hz0"] - 0.01, h["z1"], mask, "neck")
    a.C("Tail", 0.45, 1.2, 2.2, 1.8, 2.4, fur)
    a.C("Tail2", 0.45, 1.2, 2.2, 2.4, 2.9, mask)
    a.C("Tail3", 0.45, 1.2, 2.2, 2.9, 3.5, fur)
    a.C("Tail4", 0.45, 1.2, 2.2, 3.5, 4.0, mask)
    return a


def skunk():
    a = F("Skunk")
    blk, white = (36, 36, 40), (250, 250, 250)
    quad(a, blk, 1.0, 0.6, 2.2, -1.6, 1.6, legw=0.4, legd=0.5, foot_h=0, hw=0.8, hh=1.2, hl=1.1, hy=1.2,
         snout=(0.35, 0.5, 0.4), nose_c=PINK, ears=("round", 0.3))
    a.C("Stripe", 0.35, 2.2, 2.25, -1.6, 1.6, white)
    a.C("HeadStripe", 0.15, 2.4, 2.45, -2.7, -1.6, white, "neck")
    a.C("Tail", 0.7, 1.4, 4.2, 1.6, 2.6, blk)
    a.C("TailStripe", 0.25, 1.4, 4.2, 2.6, 2.65, white)
    a.C("TailTop", 0.7, 3.4, 4.4, 0.6, 1.6, blk)
    return a


def woodpecker():
    a = F("Woodpecker", "flyer")
    blk, white, red = (40, 40, 44), (250, 250, 250), (220, 40, 40)
    bird(a, blk, w=0.6, leg_h=0, bh=1.3, z0=-0.8, z1=0.8, hw=0.55, hh=0.9, hl=1.0, head_y=0.8, belly=white,
         beak_c=(80, 80, 80), beak_l=0.9, beak_w=0.18, span=2.6, chord=1.1, tail_l=1.0, fly=3.8)
    a.C("Crest", 0.4, 5.5, 5.8, -0.9, 0.2, red, "neck")
    return a


def beaver():
    a = F("Beaver")
    fur, tail, tooth = (140, 90, 56), (80, 70, 70), (250, 240, 200)
    h = quad(a, fur, 1.3, 0.5, 2.6, -1.8, 1.8, legw=0.5, legd=0.6, foot_h=0.15, foot=(60, 40, 30), hw=1.0, hh=1.5,
             hl=1.2, hy=1.0, snout=(0.6, 0.7, 0.5), snout_c=(170, 120, 80), nose_c=(40, 30, 30), ears=("round", 0.3))
    a.C("Tooth", 0.3, h["y0"] - 0.4, h["y0"], h["z0"] + 0.05, h["z0"] + 0.25, tooth, "neck")
    a.C("Tail", 0.9, 0.2, 0.6, 1.8, 4.2, tail)
    a.C("Log", 0.4, 0.0, 0.8, -4.2, -3.2, (120, 80, 50))
    return a


def porcupine():
    a = F("Porcupine")
    fur, quill = (90, 70, 56), (236, 226, 200)
    quad(a, fur, 1.2, 0.5, 2.2, -1.6, 1.6, legw=0.5, legd=0.5, foot_h=0, hw=0.7, hh=1.0, hl=1.0, hy=0.7,
         snout=(0.35, 0.5, 0.4), snout_c=(140, 110, 90), nose_c=(40, 30, 30))
    a.spikes("Quill", (-0.7, 0.0, 0.7), 2.2, (-1.0, 0.0, 1.0), 0.6, 1.4, quill)
    a.SP("Back", 0.0, 0.0, 1.0, 1.8, 1.6, 1.6, "+z", 1.0, quill)
    return a


def stag_beetle():
    a = F("StagBeetle")
    a.label = "Stag Beetle"
    shell, jaw = (60, 40, 30), (120, 70, 40)
    bug(a, [("Head", 0.7, 0.4, 1.2, -1.8, -1.0, shell), ("Body", 1.0, 0.3, 1.6, -1.0, 1.6, shell)],
        leg_c=(40, 30, 24), leg_out=0.5, leg_t=0.22)
    a.eyes2(0.7, 0.75, 1.0, -1.7, -1.45)
    a.S("Jaw", 0.4, 0.7, 0.8, 1.1, -3.0, -1.8, jaw, "neck")
    a.SP("JawTip", 0.0, 0.4, 0.8, 1.1, -3.0, -2.7, "-x", 0.5, jaw, "neck")
    a.C("Split", 0.08, 1.6, 1.65, -1.0, 1.6, (30, 20, 16))
    return a


def raven():
    a = F("Raven", "flyer")
    blk = (36, 34, 44)
    bird(a, blk, w=0.8, leg_h=0, bh=1.5, z0=-1.0, z1=1.2, hw=0.6, hh=1.0, hl=1.2, head_y=0.9, beak_c=(30, 30, 34),
         beak_l=0.9, beak_w=0.28, span=4.2, chord=1.4, tail_l=1.4, fly=4.0, wing_c=(50, 46, 64))
    return a


def rootworm():
    a = F("Rootworm", "burrower")
    bark, moss = (120, 86, 56), LEAF
    mound(a, 2.2, 1.0, DIRT)
    for i, (w, y0, y1, dz) in enumerate(((0.9, 0.8, 1.9, 0.0), (0.85, 1.9, 2.9, -0.4), (0.8, 2.9, 3.6, -0.9))):
        a.C(f"Seg{i}", w, y0, y1, -0.9 + dz, 0.9 + dz, bark)
    a.C("Head", 0.85, 3.2, 4.4, -2.6, -0.6, bark, "neck")
    a.C("Moss", 0.9, 4.4, 4.7, -2.0, -0.6, moss, "neck")
    a.P("Sprout", -0.3, 0.3, 4.7, 4.7, -1.6, -1.0, "+y", 0.9, (110, 200, 80), "neck")
    a.eyes2(0.85, 3.8, 4.15, -2.4, -2.1)
    a.S("Root", 2.2, 3.4, 0.0, 0.3, -0.3, 0.3, bark)
    return a


def red_panda():
    a = F("RedPanda")
    a.label = "Red Panda"
    fur, dark, white = (200, 90, 40), (60, 36, 30), (250, 244, 236)
    h = quad(a, fur, 1.0, 0.8, 2.4, -1.6, 1.6, legw=0.4, legd=0.5, foot_h=0, hw=0.95, hh=1.3, hl=1.1, hy=1.7,
             snout=(0.4, 0.5, 0.4), snout_c=white, nose_c=(40, 30, 30), ears=("up", 0.35, 0.6), ear_in=white,
             pupil=(60, 30, 20))
    for p in a.parts:
        if p.name.startswith("Leg"):
            p.color = dark
    a.S("Cheek", 0.5, 0.96, h["y0"] + 0.1, h["y0"] + 0.5, h["hz0"] - 0.01, h["hz0"] + 0.4, white, "neck")
    for i, (z0, z1, c) in enumerate(((1.6, 2.2, fur), (2.2, 2.6, dark), (2.6, 3.2, fur), (3.2, 3.6, dark))):
        a.C(f"Tail{i}", 0.45, 1.0, 2.0, z0, z1, c)
    return a


# ---------------------------------------------------------------- rare

def deer():
    a = F("Deer", rare=True)
    fur, white, antler = (180, 120, 70), (250, 244, 230), (230, 210, 170)
    h = quad(a, fur, 1.2, 3.4, 5.6, -2.2, 2.2, legw=0.45, foot=(60, 46, 40), foot_h=0.4, neck=(0.6, 1.0), hy=6.6,
             hw=0.75, hh=1.2, hl=1.5, snout=(0.5, 0.7, 0.5), nose_c=(40, 30, 30), ears=("side", 0.7), tail=("up", 0.7, 0.6),
             tail_c=white)
    a.S("Spot", 1.2, 1.21, 5.0, 5.3, -0.8, -0.4, white)
    a.S("Spot2", 1.2, 1.21, 4.6, 4.9, 0.4, 0.8, white)
    for side, sx in (("L", -1), ("R", 1)):
        x0, x1 = sorted((sx * 0.3, sx * 0.55))
        a.box("Antler" + side, (x0, h["y1"], h["z1"] - 0.6), (x1, h["y1"] + 1.8, h["z1"] - 0.35), antler, "neck")
        x0, x1 = sorted((sx * 0.55, sx * 1.4))
        a.box("Branch" + side, (x0, h["y1"] + 1.0, h["z1"] - 0.6), (x1, h["y1"] + 1.25, h["z1"] - 0.35), antler, "neck")
        a.P("Tine" + side, min(x0, x1) if sx < 0 else x1 - 0.25, min(x0, x1) + 0.25 if sx < 0 else x1, h["y1"] + 1.25,
            h["y1"] + 1.25, h["z1"] - 0.6, h["z1"] - 0.35, "+y", 0.9, antler, "neck")
    return a


def grey_wolf():
    a = F("GreyWolf", rare=True)
    a.label = "Grey Wolf"
    fur, cream, dark = (130, 130, 140), (230, 226, 220), (70, 70, 80)
    quad(a, fur, 1.2, 2.6, 4.6, -2.4, 2.4, legw=0.45, foot=dark, foot_h=0.3, belly=cream, belly_h=0.5, hw=1.0,
         hh=1.6, hl=1.5, hy=4.0, snout=(0.55, 0.8, 1.1), snout_c=cream, nose_c=(30, 30, 34), ears=("up", 0.4, 1.0),
         ear_c=dark, pupil=(240, 190, 40), tail=("long", 2.6, 0.9))
    a.C("Ruff", 1.25, 3.4, 4.7, -2.4, -1.2, cream)
    a.C("Saddle", 0.9, 4.6, 4.7, -0.6, 1.8, dark)
    return a


def lynx():
    a = F("Lynx", rare=True)
    fur, spot, dark = (200, 170, 130), (150, 120, 90), (40, 36, 34)
    h = quad(a, fur, 1.1, 2.2, 4.0, -2.0, 2.0, legw=0.5, foot_h=0, hw=1.0, hh=1.5, hl=1.3, hy=3.4,
             snout=(0.45, 0.55, 0.4), snout_c=(240, 226, 200), nose_c=PINK, ears=("up", 0.35, 1.0), ear_c=fur,
             pupil=(130, 190, 60), tail=("stub", 0.8))
    a.S("Tuft", 0.4, 0.6, h["y1"] + 1.0, h["y1"] + 1.6, h["z1"] - 0.8, h["z1"] - 0.6, dark, "neck")
    a.S("Ruff", 1.0, 1.3, h["y0"], h["y0"] + 0.8, h["hz0"] + 0.4, h["z1"], (240, 226, 200), "neck")
    a.S("Spot", 1.1, 1.11, 3.0, 3.4, -1.0, -0.6, spot)
    a.S("Spot2", 1.1, 1.11, 2.6, 3.0, 0.4, 0.8, spot)
    return a


def brown_bear():
    a = F("BrownBear", rare=True)
    a.label = "Brown Bear"
    fur, snout = (120, 76, 44), (180, 130, 90)
    quad(a, fur, 2.4, 2.6, 7.0, -3.2, 3.2, legw=1.0, legd=1.5, foot_h=0.4, foot=(60, 40, 30), hw=1.7, hh=2.7, hl=2.2,
         hy=5.0, snout=(0.9, 1.2, 1.2), snout_c=snout, nose_c=(30, 24, 20), ears=("round", 0.7), tail=("stub", 0.7))
    a.C("Hump", 2.0, 7.0, 7.8, -3.2, -0.6, fur)
    a.C("Fish", 0.3, 5.0, 5.8, -7.4, -5.6, (120, 160, 200), "neck")
    return a


def ancient_moose():
    """Titan: a moose as tall as the trees, its antlers grown into branches with leaves."""
    a = F("AncientMoose", "titan", rare=True)
    a.label = "Ancient Moose"
    fur, dark, antler, moss = (90, 64, 46), (60, 44, 34), (200, 180, 140), (80, 160, 70)
    h = quad(a, fur, 6.0, 20.0, 34.0, -12.0, 12.0, legw=2.6, legd=3.0, foot_h=1.6, foot=dark, neck=(3.5, 5.0), hy=33.0,
             hw=3.6, hh=6.0, hl=9.0, snout=(3.0, 4.0, 3.0), snout_c=dark, ears=("side", 2.0), tail=("stub", 2.0))
    a.C("Hump", 5.0, 34.0, 37.0, -12.0, -4.0, fur)
    a.C("Bell", 1.4, 27.0, 33.0, h["hz0"] + 1.0, h["hz0"] + 3.0, dark, "neck")
    a.C("Moss", 6.05, 33.0, 34.05, -4.0, 12.0, moss)
    for side, sx in (("L", -1), ("R", 1)):
        x0, x1 = sorted((sx * 2.0, sx * 4.0))
        a.box("Antler" + side, (x0, h["y1"], h["z1"] - 4.0), (x1, h["y1"] + 3.0, h["z1"] - 2.0), antler, "neck")
        x0, x1 = sorted((sx * 4.0, sx * 13.0))
        a.box("Palm" + side, (x0, h["y1"] + 2.0, h["z1"] - 5.0), (x1, h["y1"] + 3.4, h["z1"] - 1.0), antler, "neck")
        for i, k in enumerate((6.0, 9.0, 12.0)):
            a.P(f"Tine{side}{i}", sx * k - 0.9, sx * k + 0.9, h["y1"] + 3.4, h["y1"] + 3.4, h["z1"] - 4.0, h["z1"] - 2.0,
                "+y", 4.0, antler, "neck")
        x0, x1 = sorted((sx * 7.0, sx * 11.0))
        a.box("Leaves" + side, (x0, h["y1"] + 3.4, h["z1"] - 5.0), (x1, h["y1"] + 5.0, h["z1"] - 1.0), moss, "neck")
    return a


COMMON = [squirrel, raccoon, skunk, woodpecker, beaver, porcupine, stag_beetle, raven, rootworm, red_panda]
RARE = [deer, grey_wolf, lynx, brown_bear, ancient_moose]
GROUND = ((74, 142, 62), (66, 130, 56))
