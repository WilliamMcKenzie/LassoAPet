"""Castle padding animals (see tools/filler_core.py)."""

from filler_core import F, grow, quad, bird, mound, bug, lift, RED_EYE  # noqa: F401

STONE = (150, 150, 146)
STONE2 = (120, 120, 118)
GOLD = (240, 196, 60)
ROYAL = (60, 70, 170)
RED = (190, 40, 50)
STEEL = (180, 186, 196)
PINK = (236, 160, 176)


def corgi():
    a = F("Corgi")
    fur, white = (230, 150, 70), (252, 248, 240)
    quad(a, fur, 1.0, 0.5, 2.0, -1.8, 1.8, legw=0.4, legd=0.5, foot_h=0.15, foot=white, belly=white, belly_h=0.35,
         hw=0.85, hh=1.3, hl=1.1, hy=1.5, snout=(0.45, 0.55, 0.5), snout_c=white, nose_c=(30, 26, 26),
         ears=("up", 0.4, 0.9), ear_in=PINK, tail=("stub", 0.6))
    a.C("Collar", 0.9, 1.5, 1.8, -2.0, -1.7, RED, "neck")
    a.C("Tag", 0.2, 1.1, 1.5, -2.06, -2.0, GOLD, "neck")
    return a


def goose():
    a = F("Goose")
    white, beak = (248, 248, 246), (250, 150, 40)
    bird(a, white, w=0.9, leg_h=1.0, bh=1.6, z0=-1.2, z1=1.4, hw=0.55, hh=1.0, hl=1.2, head_y=4.0, head_dz=-0.6,
         beak_c=beak, beak_l=0.8, beak_w=0.3, leg_c=beak, tail_l=0.6)
    a.C("Neck", 0.35, 2.4, 4.2, -1.6, -0.9, white, "neck")
    a.C("Bow", 0.4, 2.8, 3.1, -1.65, -0.85, ROYAL, "neck")
    return a


def pigeon():
    a = F("Pigeon", "flyer")
    grey, neck = (150, 156, 170), (100, 160, 140)
    bird(a, grey, w=0.6, leg_h=0, bh=1.2, z0=-0.8, z1=0.8, hw=0.5, hh=0.8, hl=0.9, head_y=0.7, beak_c=(70, 70, 76),
         beak_l=0.4, beak_w=0.15, span=2.2, chord=1.0, tail_l=0.8, fly=4.0, pupil=(220, 90, 40))
    a.C("Neck", 0.62, 4.6, 5.0, -0.85, -0.2, neck)
    a.C("Scroll", 0.25, 3.8, 4.0, -0.5, 0.3, (250, 240, 210))
    return a


def ferret():
    a = F("Ferret")
    fur, mask, cream = (200, 170, 130), (90, 70, 56), (250, 240, 220)
    h = quad(a, fur, 0.55, 0.5, 1.5, -2.0, 2.0, legw=0.3, legd=0.4, foot_h=0.1, foot=mask, hw=0.5, hh=0.8, hl=0.9,
             hy=1.0, hc=cream, nose_c=PINK, ears=("round", 0.25), tail=("long", 1.6, 0.4), tail_c=mask)
    a.S("Mask", 0.2, 0.51, 1.45, 1.65, h["hz0"] - 0.01, h["z1"], mask, "neck")
    a.C("Hat", 0.35, 1.8, 2.1, -2.6, -1.9, ROYAL, "neck")
    return a


def swan():
    a = F("Swan")
    white, beak = (250, 250, 252), (240, 120, 40)
    a.C("Body", 1.2, 0.0, 1.6, -1.4, 1.8, white)
    a.C("Back", 0.9, 1.6, 2.2, -0.6, 2.2, white)
    a.S("Wing", 1.2, 1.4, 0.6, 2.4, -0.6, 2.0, (236, 236, 240))
    a.C("Neck", 0.35, 1.6, 4.4, -1.6, -1.0, white, "neck")
    a.C("Neck2", 0.35, 3.8, 4.4, -2.2, -1.6, white, "neck")
    a.C("Head", 0.45, 4.0, 4.9, -2.6, -1.6, white, "neck")
    a.C("Mask", 0.3, 4.1, 4.6, -2.65, -2.4, (30, 30, 34), "neck")
    a.P("Beak", -0.25, 0.25, 4.15, 4.55, -2.65, -2.65, "-z", 0.8, beak, "neck")
    a.eyes2(0.45, 4.45, 4.75, -2.4, -2.15)
    a.C("Crown", 0.3, 4.9, 5.2, -2.3, -1.9, GOLD, "neck")
    return a


def peacock():
    a = F("Peacock")
    blue, green, fan, eye = (40, 90, 200), (40, 140, 110), (60, 150, 90), (60, 60, 160)
    bird(a, blue, w=0.8, leg_h=1.4, bh=1.6, z0=-1.0, z1=1.2, hw=0.5, hh=0.9, hl=1.0, head_y=3.8, head_dz=-0.2,
         beak_c=(200, 190, 160), beak_l=0.4, beak_w=0.15, leg_c=(150, 140, 130), tail_l=0, wing_c=green)
    a.C("Neck", 0.35, 2.6, 4.0, -1.0, -0.4, blue, "neck")
    a.SP("Crest", 0.0, 0.25, 4.7, 4.7, -0.7, -0.4, "+y", 0.7, blue, "neck")
    a.C("Fan", 2.6, 1.8, 5.2, 1.2, 1.6, fan)
    a.C("FanTop", 1.8, 5.2, 6.2, 1.2, 1.6, fan)
    for i, (x, y) in enumerate(((-1.8, 3.0), (0.0, 4.0), (1.8, 3.0), (-1.0, 5.2), (1.0, 5.2))):
        a.B(f"Plain{i}", x - 0.3, x + 0.3, y - 0.3, y + 0.3, 1.15, 1.2, eye)
    return a


def jester_monkey():
    a = F("JesterMonkey")
    a.label = "Jester Monkey"
    fur, face = (130, 90, 60), (230, 196, 160)
    a.C("Body", 0.8, 1.2, 2.8, -0.6, 0.6, fur)
    a.S("Leg", 0.2, 0.75, 0.0, 1.2, -0.4, 0.4, fur)
    a.S("Arm", 0.8, 1.2, 0.6, 2.6, -0.4, 0.2, fur)
    a.C("Head", 0.8, 2.8, 4.2, -0.8, 0.6, fur, "neck")
    a.C("Face", 0.6, 2.9, 3.9, -0.85, -0.8, face, "neck")
    a.eyes2(0.8, 3.4, 3.75, -0.7, -0.4)
    a.S("Ear", 0.8, 1.1, 3.3, 3.8, -0.2, 0.2, face, "neck")
    a.B("HatL", -0.85, 0.0, 4.2, 4.6, -0.85, 0.65, RED, "neck")
    a.B("HatR", 0.0, 0.85, 4.2, 4.6, -0.85, 0.65, GOLD, "neck")
    a.P("PointL", -0.85, -0.25, 4.6, 4.6, -0.4, 0.2, "+y", 1.0, RED, "neck")
    a.P("PointR", 0.25, 0.85, 4.6, 4.6, -0.4, 0.2, "+y", 1.0, GOLD, "neck")
    a.C("Tail", 0.15, 0.6, 2.2, 0.6, 0.9, fur)
    a.C("Tail2", 0.15, 0.6, 0.9, 0.9, 1.8, fur)
    return a


def armored_ram():
    a = F("ArmoredRam")
    a.label = "Armored Ram"
    wool, face, horn = (240, 236, 226), (90, 80, 76), (200, 170, 120)
    h = quad(a, wool, 1.6, 2.2, 4.8, -2.4, 2.4, legw=0.6, foot_h=0.4, foot=STEEL, hw=0.9, hh=1.8, hl=1.8, hy=3.6,
             hc=face, tail=("stub", 0.8))
    a.C("Helm", 0.95, h["y1"] - 0.6, h["y1"] + 0.2, h["hz0"] - 0.05, h["z1"], STEEL, "neck")
    a.C("Barding", 1.65, 3.2, 4.85, -2.4, -0.6, ROYAL)
    a.C("Trim", 1.7, 3.0, 3.3, -2.4, -0.6, GOLD)
    a.S("Horn", 0.6, 1.4, h["y1"] - 0.3, h["y1"] + 0.5, h["z1"] - 1.0, h["z1"] + 0.4, horn, "neck")
    a.S("Horn2", 0.9, 1.6, h["y0"] + 0.4, h["y1"] - 0.3, h["z1"] - 0.2, h["z1"] + 0.4, horn, "neck")
    a.SP("HornTip", 0.9, 1.6, h["y0"] + 0.4, h["y0"] + 1.0, h["z1"] - 0.2, h["z1"] + 0.4, "-z", 1.2, horn, "neck")
    return a


def mastiff():
    a = F("Mastiff")
    fur, muzzle = (200, 160, 110), (60, 50, 46)
    quad(a, fur, 1.5, 2.2, 4.8, -2.4, 2.4, legw=0.6, foot_h=0.2, hw=1.3, hh=2.0, hl=1.6, hy=3.8,
         snout=(0.8, 1.0, 0.8), snout_c=muzzle, nose_c=(30, 26, 26), ears=("flop", 1.0), ear_c=muzzle, tail=("long", 1.6, 0.5))
    a.C("Collar", 1.35, 3.8, 4.2, -2.6, -2.2, (60, 50, 46), "neck")
    a.S("Stud", 0.4, 0.7, 3.85, 4.15, -2.7, -2.6, STEEL, "neck")
    return a


def falcon():
    a = F("Falcon", "flyer")
    c, belly = (110, 100, 96), (240, 230, 214)
    bird(a, c, w=0.8, leg_h=0, bh=1.4, z0=-1.0, z1=1.0, hw=0.6, hh=0.9, hl=1.0, head_y=0.9, belly=belly,
         beak_c=(240, 190, 60), beak_l=0.5, beak_w=0.2, span=4.0, chord=1.3, tail_l=1.2, fly=4.5)
    a.C("Hood", 0.65, 6.0, 6.35, -1.1, 0.1, (150, 60, 40), "neck")
    a.P("Plume", -0.15, 0.15, 6.35, 6.35, -0.5, -0.2, "+y", 0.6, GOLD, "neck")
    return a


# ---------------------------------------------------------------- rare

def gargoyle():
    a = F("Gargoyle", "flyer", rare=True)
    a.C("Body", 1.2, 3.6, 6.0, -1.2, 1.2, STONE)
    a.C("Head", 1.0, 5.4, 7.2, -2.2, -0.6, STONE, "neck")
    a.C("Snout", 0.6, 5.5, 6.3, -2.8, -2.2, STONE2, "neck")
    a.eyes2(1.0, 6.4, 6.8, -2.0, -1.6, RED_EYE)
    a.SP("Horn", 0.3, 0.8, 7.2, 7.2, -1.2, -0.7, "+y", 1.2, STONE2, "neck")
    a.S("Wing", 1.2, 3.4, 5.6, 6.0, -0.6, 1.4, STONE2)
    a.S("Wing2", 3.4, 4.6, 4.6, 6.0, -0.4, 1.0, STONE2)
    a.SP("WingTip", 4.6, 4.6, 4.6, 6.0, -0.4, 0.4, "+x", 1.2, STONE2)
    a.S("Leg", 0.5, 1.2, 2.6, 3.6, -1.0, 0.0, STONE)
    a.C("Tail", 0.3, 3.8, 4.4, 1.2, 3.4, STONE)
    a.P("TailTip", -0.3, 0.3, 3.8, 4.4, 3.4, 3.4, "+z", 0.8, STONE2)
    return a


def war_bull():
    a = F("WarBull", rare=True)
    a.label = "War Bull"
    fur, horn = (60, 44, 40), (240, 226, 190)
    h = quad(a, fur, 2.2, 2.8, 6.6, -3.2, 3.2, legw=0.9, foot_h=0.6, foot=STEEL, hw=1.4, hh=2.4, hl=1.8, hy=4.6,
             snout=(1.0, 1.0, 0.6), snout_c=(110, 90, 86), tail=("rope", 2.4), pupil=RED_EYE)
    a.C("Plate", 1.45, h["y1"] - 1.0, h["y1"] + 0.1, h["hz0"] - 0.05, h["z1"] + 0.1, STEEL, "neck")
    a.C("Blanket", 2.25, 4.4, 6.7, -1.2, 2.0, RED)
    a.C("Trim", 2.3, 4.2, 4.5, -1.2, 2.0, GOLD)
    a.C("Ring", 0.4, h["y0"] + 0.1, h["y0"] + 0.5, h["z0"] - 0.1, h["z0"], GOLD, "neck")
    a.S("Horn", 1.4, 2.4, h["y1"] - 0.8, h["y1"] - 0.2, h["z1"] - 1.2, h["z1"] - 0.6, horn, "neck")
    a.SP("HornTip", 2.0, 2.4, h["y1"] - 0.2, h["y1"] - 0.2, h["z1"] - 1.2, h["z1"] - 0.6, "+y", 1.4, horn, "neck")
    return a


def royal_stag():
    a = F("RoyalStag", rare=True)
    a.label = "Royal Stag"
    white = (250, 250, 250)
    h = quad(a, white, 1.4, 4.0, 6.6, -2.6, 2.6, legw=0.5, foot=GOLD, foot_h=0.5, neck=(0.7, 1.1), hy=7.8,
             hw=0.85, hh=1.3, hl=1.7, snout=(0.6, 0.8, 0.5), nose_c=(60, 60, 70), ears=("side", 0.7), pupil=(60, 100, 200),
             tail=("up", 0.8, 0.7))
    a.C("Cape", 1.45, 5.4, 6.7, -2.6, 0.4, ROYAL)
    a.C("CapeTrim", 1.5, 5.2, 5.5, -2.6, 0.4, GOLD)
    for side, sx in (("L", -1), ("R", 1)):
        x0, x1 = sorted((sx * 0.3, sx * 0.6))
        a.box("Antler" + side, (x0, h["y1"], h["z1"] - 0.6), (x1, h["y1"] + 2.6, h["z1"] - 0.3), GOLD, "neck")
        x0, x1 = sorted((sx * 0.6, sx * 1.8))
        a.box("Branch" + side, (x0, h["y1"] + 1.2, h["z1"] - 0.6), (x1, h["y1"] + 1.5, h["z1"] - 0.3), GOLD, "neck")
        a.box("Branch2" + side, (x0, h["y1"] + 2.3, h["z1"] - 0.6), (x1, h["y1"] + 2.6, h["z1"] - 0.3), GOLD, "neck")
        e0, e1 = (x1 - 0.3, x1) if sx > 0 else (x0, x0 + 0.3)
        a.P("Tine" + side, e0, e1, h["y1"] + 1.5, h["y1"] + 1.5, h["z1"] - 0.6, h["z1"] - 0.3, "+y", 0.8, GOLD, "neck")
        a.P("Tine2" + side, e0, e1, h["y1"] + 2.6, h["y1"] + 2.6, h["z1"] - 0.6, h["z1"] - 0.3, "+y", 1.0, GOLD, "neck")
    return a


def griffin():
    a = F("Griffin", "flyer", rare=True)
    fur, feather, beak = (210, 160, 80), (250, 248, 240), (240, 190, 60)
    quad(a, fur, 1.4, 2.6, 5.0, -2.4, 2.6, legw=0.5, foot_h=0.4, foot=beak, hw=1.0, hh=1.8, hl=1.6, hy=5.0,
         hc=feather, tail=("rope", 2.6), pupil=(240, 140, 30))
    a.P("Beak", -0.5, 0.5, 5.4, 6.2, -4.0, -4.0, "-z", 1.2, beak, "neck")
    a.C("Chest", 1.45, 3.4, 5.4, -2.6, -1.0, feather)
    a.SP("Tuft", 0.4, 0.9, 6.3, 6.8, -1.4, -1.4, "+z", 1.2, feather, "neck")
    a.S("Wing", 1.4, 5.4, 5.4, 5.8, -1.6, 1.4, feather)
    a.SP("WingTip", 5.4, 5.4, 5.4, 5.8, -1.6, 0.4, "+x", 2.0, feather)
    a.S("Wing2", 1.4, 4.0, 5.0, 5.4, -1.6, 0.6, (230, 200, 140))
    return a


def fortress_tortoise():
    """Titan: a tortoise carrying a little castle, towers and battlements on its shell."""
    a = F("FortressTortoise", "titan", rare=True)
    a.label = "Fortress Tortoise"
    skin, shell, rim, roof = (120, 140, 100), (110, 90, 70), (80, 64, 50), (60, 70, 150)
    a.C("Shell", 9.0, 6.0, 14.0, -10.0, 10.0, shell)
    a.C("Rim", 9.4, 5.0, 6.6, -10.4, 10.4, rim)
    a.C("Keep", 6.0, 14.0, 24.0, -6.0, 6.0, STONE)
    for i, x in enumerate((-5.0, -1.6, 1.6, 5.0)):
        a.B(f"Merlon{i}", x - 1.0, x + 1.0, 24.0, 25.6, -6.0, -4.4, STONE2)
    a.B("Gate", -1.6, 1.6, 14.0, 18.6, -6.1, -6.0, (70, 50, 40))
    a.B("Tower", -3.0, 3.0, 24.0, 32.0, -3.0, 3.0, STONE)
    a.P("Spire", -3.4, 3.4, 32.0, 32.0, -3.4, 3.4, "+y", 6.0, roof)
    a.B("Pole", -0.2, 0.2, 38.0, 41.0, -0.2, 0.2, (90, 70, 50))
    a.B("Flag", 0.2, 3.0, 39.4, 41.0, -0.1, 0.1, RED)
    for leg, (x, z) in {"FL": (-6.5, -6.5), "FR": (6.5, -6.5), "HL": (-6.5, 6.5), "HR": (6.5, 6.5)}.items():
        a.B("Leg" + leg, x - 2.2, x + 2.2, 0, 6.0, z - 2.2, z + 2.2, skin)
    a.C("Neck", 2.4, 6.0, 10.0, -14.0, -10.0, skin, "neck")
    a.C("Head", 3.0, 8.0, 13.0, -18.0, -13.0, skin, "neck")
    a.B("PlainMouth", -2.2, 2.2, 9.0, 9.4, -18.05, -18.0, (60, 70, 50), "neck")
    a.eyes2(3.0, 11.0, 12.0, -17.4, -16.4)
    a.C("Tail", 0.8, 5.5, 7.0, 10.4, 12.0, skin)
    return a


COMMON = [corgi, goose, pigeon, ferret, swan, peacock, jester_monkey, armored_ram, mastiff, falcon]
RARE = [gargoyle, war_bull, royal_stag, griffin, fortress_tortoise]
GROUND = ((152, 152, 144), (140, 140, 132))
