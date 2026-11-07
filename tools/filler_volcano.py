"""Volcano padding animals (see tools/filler_core.py). Parts named Glow* glow like Neon."""

from filler_core import F, quad, bird, mound, bug, GLOW_EYE, RED_EYE  # noqa: F401

ROCK = (70, 60, 60)
BASALT = (50, 44, 48)
LAVA = (255, 120, 30)
EMBER = (255, 190, 60)


def fire_ant():
    a = F("FireAnt")
    a.label = "Fire Ant"
    red, dark = (210, 60, 40), (80, 30, 30)
    bug(a, [("Head", 0.45, 0.5, 1.2, -1.6, -0.9, red), ("Body", 0.35, 0.5, 1.0, -0.9, 0.0, red),
            ("Abdomen", 0.6, 0.4, 1.4, 0.0, 1.4, dark)], leg_c=dark, leg_out=0.5, leg_t=0.15, antenna=0.7)
    a.eyes2(0.45, 0.8, 1.05, -1.5, -1.25)
    a.C("GlowSting", 0.2, 0.7, 1.0, 1.4, 1.7, LAVA)
    return a


def ember_beetle():
    a = F("EmberBeetle")
    a.label = "Ember Beetle"
    shell, leg = BASALT, (36, 30, 34)
    bug(a, [("Head", 0.6, 0.4, 1.2, -1.8, -1.0, shell), ("Body", 1.1, 0.3, 1.8, -1.0, 1.6, shell)],
        leg_c=leg, leg_out=0.6, leg_t=0.25)
    a.eyes2(0.6, 0.75, 1.05, -1.7, -1.4, GLOW_EYE)
    a.C("GlowSplit", 0.15, 1.8, 1.85, -1.0, 1.6, LAVA)
    a.S("GlowSpot", 0.4, 0.8, 1.8, 1.85, -0.4, 0.4, EMBER)
    a.P("Horn", -0.25, 0.25, 0.8, 1.2, -1.8, -1.8, "-z", 0.9, shell, "neck")
    return a


def lava_toad():
    a = F("LavaToad")
    a.label = "Lava Toad"
    skin, belly = (110, 70, 60), (230, 150, 90)
    a.C("Belly", 1.6, 0.3, 1.0, -1.6, 1.4, belly)
    a.C("Body", 1.6, 1.0, 2.6, -1.6, 1.4, skin)
    a.S("Thigh", 1.6, 2.2, 0.0, 1.4, 0.0, 1.6, skin)
    a.S("Foot", 1.9, 2.7, 0.0, 0.25, -0.5, 0.5, skin)
    a.S("Arm", 0.8, 1.3, 0.0, 1.0, -1.6, -1.0, skin)
    a.S("Bulge", 0.6, 1.6, 2.6, 3.3, -1.6, -0.7, skin, "neck")
    a.eyes2(1.6, 2.65, 3.15, -1.5, -1.0, GLOW_EYE)
    a.S("GlowWart", 0.2, 0.7, 2.6, 2.65, 0.2, 0.8, LAVA)
    a.C("GlowWart2", 0.3, 2.6, 2.65, -0.4, 0.0, EMBER)
    return a


def cinder_mole():
    a = F("CinderMole", "burrower")
    a.label = "Cinder Mole"
    fur, claw = (60, 54, 56), (255, 150, 50)
    mound(a, 2.4, 1.6, ROCK, BASALT)
    a.C("GlowCrack", 2.41, 0.2, 0.4, -1.0, 1.0, LAVA)
    a.C("Body", 1.1, 1.2, 3.4, -1.0, 0.9, fur)
    a.C("Head", 0.9, 2.2, 3.8, -2.2, -0.6, fur, "neck")
    a.C("Snout", 0.45, 2.4, 3.0, -2.9, -2.2, (120, 90, 90), "neck")
    a.eyes2(0.9, 3.2, 3.5, -2.0, -1.75, GLOW_EYE)
    a.S("Paw", 0.8, 1.6, 1.6, 2.0, -2.4, -1.4, fur)
    a.spikes("GlowClaw", (-1.4, -1.0, 1.0, 1.4), 2.0, (-2.2,), 0.3, 0.5, claw)
    return a


def magma_salamander():
    a = F("MagmaSalamander")
    a.label = "Magma Salamander"
    blk = (40, 34, 38)
    bands = [(-1.6, -1.0, blk), (-1.0, -0.6, LAVA), (-0.6, 0.4, blk), (0.4, 0.8, LAVA), (0.8, 1.6, blk)]
    quad(a, blk, 0.9, 0.5, 1.4, -1.6, 1.6, bands=bands, legw=0.35, legd=0.5, foot_h=0, hw=0.8, hh=0.8, hl=1.1,
         hy=0.6, pupil=GLOW_EYE)
    for p in a.parts:
        if p.name.startswith("Body") and p.color == LAVA:
            p.name = "Glow" + p.name
    a.C("Tail", 0.5, 0.6, 1.2, 1.6, 2.8, blk)
    a.C("GlowTail", 0.4, 0.65, 1.15, 2.8, 3.4, LAVA)
    a.P("TailTip", -0.3, 0.3, 0.7, 1.1, 3.4, 3.4, "+z", 0.9, blk)
    return a


def ash_bat():
    a = F("AshBat", "flyer")
    a.label = "Ash Bat"
    fur, wing = (90, 84, 86), (60, 50, 54)
    a.C("Body", 0.7, 4.0, 5.4, -0.6, 0.8, fur)
    a.C("Head", 0.6, 5.0, 6.2, -1.2, -0.2, fur, "neck")
    a.eyes2(0.6, 5.5, 5.85, -1.15, -0.85, RED_EYE)
    a.SP("Ear", 0.15, 0.55, 6.2, 6.2, -0.8, -0.4, "+y", 0.8, fur, "neck")
    a.S("Wing", 0.7, 2.6, 5.0, 5.2, -0.4, 0.8, wing)
    a.S("Wing2", 2.6, 3.8, 4.4, 5.2, -0.4, 0.4, wing)
    a.SP("WingTip", 3.8, 3.8, 4.4, 5.2, -0.4, 0.4, "+x", 1.0, wing)
    a.C("GlowBelly", 0.4, 4.3, 4.8, -0.65, -0.6, EMBER)
    return a


def magma_crab():
    a = F("MagmaCrab")
    a.label = "Magma Crab"
    shell, leg = (150, 50, 40), (110, 40, 34)
    a.C("Shell", 1.6, 0.8, 2.0, -1.2, 1.2, shell)
    a.C("Rock", 1.1, 2.0, 2.8, -0.8, 0.8, BASALT)
    a.C("GlowVent", 0.4, 2.8, 2.9, -0.3, 0.3, LAVA)
    a.S("Stalk", 0.4, 0.6, 2.0, 2.6, -1.2, -1.0, shell, "neck")
    a.S("PlainBall", 0.3, 0.7, 2.6, 3.0, -1.3, -0.9, (255, 220, 120), "neck")
    for i, z in enumerate((-0.6, 0.2, 1.0)):
        a.S(f"Leg{i}", 1.6, 2.4, 0.8, 1.1, z - 0.15, z + 0.15, leg)
        a.S(f"Shin{i}", 2.1, 2.4, 0.0, 0.8, z - 0.15, z + 0.15, leg)
    a.S("Claw", 1.0, 2.0, 0.5, 1.5, -2.4, -1.3, shell)
    a.SP("Pincer", 1.2, 1.8, 0.9, 1.5, -2.4, -2.4, "-z", 0.8, shell)
    return a


def lava_slug():
    a = F("LavaSlug")
    a.label = "Lava Slug"
    skin = (60, 50, 50)
    a.C("Foot", 0.9, 0.0, 0.5, -2.0, 2.6, (40, 34, 36))
    a.C("Body", 0.7, 0.5, 1.4, -1.6, 2.2, skin)
    a.C("GlowStripe", 0.3, 1.4, 1.5, -1.4, 2.0, LAVA)
    a.C("Head", 0.6, 0.5, 1.9, -2.4, -1.4, skin, "neck")
    a.eyes2(0.6, 1.2, 1.5, -2.3, -2.0, GLOW_EYE)
    a.S("Horn", 0.2, 0.4, 1.9, 2.6, -2.2, -2.0, skin, "neck")
    a.S("GlowHornTip", 0.15, 0.45, 2.6, 2.9, -2.25, -1.95, EMBER, "neck")
    return a


def flame_fox():
    a = F("FlameFox")
    a.label = "Flame Fox"
    fur, cream = (220, 90, 40), (250, 220, 180)
    quad(a, fur, 0.9, 1.4, 3.0, -1.6, 1.8, legw=0.4, legd=0.5, foot_h=0.3, foot=(50, 40, 40), hw=0.8, hh=1.3,
         hl=1.2, hy=2.6, snout=(0.4, 0.6, 0.9), snout_c=cream, nose_c=(40, 30, 30), ears=("up", 0.35, 0.9),
         ear_in=(60, 40, 40), tail=("up", 2.0, 1.2), tail_c=LAVA, pupil=GLOW_EYE)
    for p in a.parts:
        if p.name == "Tail":
            p.name = "GlowTail"
    a.P("GlowFlame", -0.6, 0.6, 4.2, 4.2, 1.8, 3.0, "+y", 1.3, EMBER)
    return a


def smoke_moth():
    a = F("SmokeMoth", "flyer")
    a.label = "Smoke Moth"
    body, wing = (110, 104, 104), (150, 144, 144)
    a.C("Body", 0.45, 3.0, 3.8, -0.8, 1.6, body)
    a.C("Head", 0.45, 3.1, 3.7, -1.4, -0.8, body, "neck")
    a.eyes2(0.45, 3.3, 3.6, -1.35, -1.1, GLOW_EYE)
    a.S("Wing", 0.45, 2.8, 3.6, 3.75, -1.0, 0.8, wing)
    a.S("Wing2", 0.45, 2.0, 3.6, 3.75, 0.8, 2.0, wing)
    a.S("GlowEye", 1.4, 2.2, 3.75, 3.8, -0.6, 0.2, LAVA)
    a.S("Feeler", 0.15, 0.3, 3.7, 4.5, -1.4, -1.2, body, "neck")
    return a


# ---------------------------------------------------------------- rare

def obsidian_ram():
    a = F("ObsidianRam", rare=True)
    a.label = "Obsidian Ram"
    wool, face, horn = (60, 56, 64), (36, 32, 40), (120, 70, 160)
    h = quad(a, wool, 1.6, 2.4, 5.0, -2.4, 2.4, legw=0.6, foot_h=0.4, foot=BASALT, hw=0.9, hh=1.8, hl=1.8, hy=3.8,
             hc=face, pupil=GLOW_EYE, tail=("stub", 0.8))
    a.C("GlowCrack", 1.61, 3.4, 3.6, -2.4, 2.4, LAVA)
    # curled horns: a block back, a block down, a pyramid forward
    a.S("Horn", 0.6, 1.4, h["y1"] - 0.3, h["y1"] + 0.5, h["z1"] - 1.0, h["z1"] + 0.4, horn, "neck")
    a.S("Horn2", 0.9, 1.6, h["y0"] + 0.4, h["y1"] - 0.3, h["z1"] - 0.2, h["z1"] + 0.4, horn, "neck")
    a.SP("HornTip", 0.9, 1.6, h["y0"] + 0.4, h["y0"] + 1.0, h["z1"] - 0.2, h["z1"] + 0.4, "-z", 1.2, horn, "neck")
    return a


def ember_hound():
    a = F("EmberHound", rare=True)
    a.label = "Ember Hound"
    fur = (54, 46, 50)
    h = quad(a, fur, 1.2, 2.6, 4.6, -2.4, 2.4, legw=0.5, foot_h=0.3, foot=LAVA, hw=1.0, hh=1.6, hl=1.6, hy=4.0,
             snout=(0.6, 0.8, 1.0), nose_c=(30, 26, 26), ears=("up", 0.4, 1.0), ear_in=LAVA, pupil=GLOW_EYE,
             tail=("long", 2.4, 0.7))
    a.spikes("GlowSpine", (0.0,), 4.6, (-1.6, -0.4, 0.8), 0.6, 0.9, LAVA)
    a.C("GlowTail", 0.3, 3.75, 4.35, 4.8, 5.4, EMBER)
    return a


def fire_drake():
    a = F("FireDrake", "flyer", rare=True)
    a.label = "Fire Drake"
    red, wing, belly = (200, 50, 40), (240, 120, 40), (250, 200, 110)
    a.C("Belly", 1.0, 5.0, 5.5, -1.6, 1.6, belly)
    a.C("Body", 1.0, 5.5, 6.8, -1.6, 1.6, red)
    a.C("Neck", 0.5, 6.0, 7.6, -2.6, -1.6, red, "neck")
    a.C("Head", 0.7, 7.2, 8.4, -4.0, -2.4, red, "neck")
    a.eyes2(0.7, 7.75, 8.1, -3.6, -3.25, GLOW_EYE)
    a.SP("Horn", 0.2, 0.55, 8.4, 8.4, -2.8, -2.5, "+z", 1.0, (60, 40, 40), "neck")
    a.S("Wing", 1.0, 3.6, 6.6, 6.8, -1.2, 1.2, wing)
    a.SP("WingTip", 3.6, 3.6, 6.6, 6.8, -1.2, 1.2, "+x", 1.8, wing)
    a.C("Tail", 0.4, 5.6, 6.2, 1.6, 4.2, red)
    a.P("GlowTailTip", -0.4, 0.4, 5.6, 6.2, 4.2, 4.2, "+z", 1.2, LAVA)
    a.S("Leg", 0.4, 0.9, 4.0, 5.0, 0.4, 1.2, red)
    return a


def brimstone_bison():
    a = F("BrimstoneBison", rare=True)
    a.label = "Brimstone Bison"
    fur, mane, horn = (80, 56, 46), (50, 36, 32), (240, 220, 160)
    h = quad(a, fur, 2.0, 2.6, 6.0, -3.0, 3.4, legw=0.8, foot_h=0.5, foot=BASALT, hw=1.4, hh=2.4, hl=1.8, hy=3.4,
             hc=mane, snout=(1.0, 1.0, 0.6), snout_c=(90, 66, 56), pupil=GLOW_EYE, tail=("rope", 2.0))
    a.C("Hump", 2.1, 6.0, 7.8, -3.0, -0.6, mane)
    a.C("GlowHumpVent", 0.8, 7.8, 7.9, -2.6, -1.6, LAVA)
    a.SP("Horn", 1.4, 1.4, h["y1"] - 0.8, h["y1"] - 0.2, h["z1"] - 1.6, h["z1"] - 1.0, "+x", 0.9, horn, "neck")
    a.SP("HornUp", 2.0, 2.3, h["y1"] - 0.8, h["y1"] - 0.2, h["z1"] - 1.6, h["z1"] - 1.0, "+y", 1.0, horn, "neck")
    a.S("HornMid", 1.4, 2.3, h["y1"] - 0.8, h["y1"] - 0.2, h["z1"] - 1.6, h["z1"] - 1.0, horn, "neck")
    return a


def ash_behemoth():
    """Titan: a rhino-like giant with smoking vents (pyramids) down its back."""
    a = F("AshBehemoth", "titan", rare=True)
    a.label = "Ash Behemoth"
    skin, plate, horn = (80, 72, 74), (50, 44, 48), (60, 50, 52)
    bands = [(-12, -6, skin), (-6, -5, plate), (-5, 3, skin), (3, 4, plate), (4, 12, skin)]
    h = quad(a, skin, 9.0, 8.0, 24.0, -12.0, 12.0, bands=bands, legw=4.0, legd=5.0, foot_h=1.5, foot=plate, hw=6.0,
             hh=9.0, hl=8.0, hy=11.0, snout=(5.0, 5.0, 4.0), pupil=GLOW_EYE, ears=("round", 1.6), tail=("stub", 2.4))
    for i, z in enumerate((-8.0, -1.0, 7.0)):
        a.C(f"Vent{i}", 2.6, 24.0, 26.0, z - 2.6, z + 2.6, plate)
        a.P(f"Cone{i}", -2.6, 2.6, 26.0, 26.0, z - 2.6, z + 2.6, "+y", 4.0, plate)
        a.C(f"GlowVent{i}", 1.0, 29.0, 30.6, z - 1.0, z + 1.0, LAVA)
    a.P("Horn", -2.0, 2.0, h["y0"] + 5.0, h["y0"] + 5.0, h["z0"] + 0.2, h["z0"] + 3.8, "+y", 7.0, horn, "neck")
    a.C("GlowCrack", 9.01, 15.0, 16.0, -12.0, 12.0, LAVA)
    return a


COMMON = [fire_ant, ember_beetle, lava_toad, cinder_mole, magma_salamander, ash_bat, magma_crab, lava_slug, flame_fox, smoke_moth]
RARE = [obsidian_ram, ember_hound, fire_drake, brimstone_bison, ash_behemoth]
GROUND = ((78, 66, 64), (66, 56, 56))
