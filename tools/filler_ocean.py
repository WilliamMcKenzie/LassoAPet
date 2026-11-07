"""Ocean padding animals (see tools/filler_core.py). Parts named Glow* glow like Neon."""

from filler_core import F, grow, quad, bird, fish, mound, bug  # noqa: F401

SAND = (232, 214, 160)
PINK = (236, 160, 176)


def pufferfish():
    a = F("Pufferfish")
    yel, belly, spine = (240, 200, 90), (250, 244, 220), (180, 140, 60)
    a.C("Belly", 1.3, 0.3, 1.0, -1.3, 1.3, belly)
    a.C("Body", 1.3, 1.0, 2.8, -1.3, 1.3, yel)
    a.B("Mouth", -0.3, 0.3, 1.2, 1.5, -1.35, -1.3, (200, 100, 80), "neck")
    a.eyes2(1.3, 1.9, 2.4, -1.2, -0.7)
    a.spikes("Spine", (-0.7, 0.7), 2.8, (-0.6, 0.6), 0.4, 0.6, spine)
    a.SP("Side", 1.3, 1.3, 1.2, 1.6, 0.2, 0.6, "+x", 0.5, spine)
    a.C("TailRoot", 0.3, 1.3, 2.1, 1.3, 1.7, yel)
    a.W("Fin", -0.15, 0.15, 1.7, 2.6, 1.7, 2.5, (220, 170, 70))
    a.S("SideFin", 1.3, 1.7, 1.4, 1.7, -0.4, 0.2, (220, 170, 70))
    return a


def seahorse():
    a = F("Seahorse")
    c, fin = (240, 140, 60), (250, 200, 100)
    a.C("Tail", 0.3, 0.0, 0.4, 0.0, 1.0, c)
    a.C("Tail2", 0.35, 0.0, 1.4, -0.2, 0.3, c)
    a.C("Belly", 0.6, 1.2, 3.0, -0.6, 0.5, c)
    a.C("Chest", 0.55, 3.0, 3.8, -0.4, 0.6, c)
    a.C("Head", 0.5, 3.6, 4.6, -0.6, 0.6, c, "neck")
    a.C("Snout", 0.2, 3.9, 4.25, -1.6, -0.6, c, "neck")
    a.eyes2(0.5, 4.0, 4.35, -0.5, -0.2)
    a.P("Crown", -0.3, 0.3, 4.6, 4.6, -0.1, 0.4, "+y", 0.6, fin, "neck")
    a.W("Fin", -0.1, 0.1, 1.8, 3.0, 0.5, 1.2, fin, "up_back")
    a.spikes("Ridge", (0.0,), 3.8, (0.3,), 0.3, 0.4, fin)
    return a


def shrimp():
    a = F("Shrimp")
    c, dark = (250, 130, 110), (220, 90, 80)
    for i, (w, h, z0, z1) in enumerate(((0.6, 1.2, -1.2, -0.2), (0.55, 1.1, -0.2, 0.6), (0.45, 0.9, 0.6, 1.3), (0.35, 0.7, 1.3, 1.9))):
        a.C(f"Seg{i}", w, 0.4, 0.4 + h, z0, z1, c if i % 2 == 0 else dark, "neck" if i == 0 else "root")
    a.C("Tail", 0.6, 0.4, 0.7, 1.9, 2.6, dark)
    a.eyes2(0.6, 1.1, 1.4, -1.1, -0.8)
    a.S("Feeler", 0.2, 0.3, 1.4, 1.5, -3.0, -1.2, dark, "neck")
    a.P("Rostrum", -0.15, 0.15, 1.2, 1.5, -1.2, -1.2, "-z", 0.8, c, "neck")
    for i, z in enumerate((-0.8, -0.2, 0.4)):
        a.S(f"Leg{i}", 0.3, 0.45, 0.0, 0.4, z, z + 0.15, dark)
    return a


def sea_urchin():
    a = F("SeaUrchin")
    a.label = "Sea Urchin"
    body, spine = (110, 60, 130), (150, 90, 180)
    a.C("Body", 1.0, 0.0, 1.6, -1.0, 1.0, body)
    a.spikes("Top", (-0.5, 0.5), 1.6, (-0.5, 0.5), 0.6, 1.0, spine)
    a.SP("Side", 1.0, 1.0, 0.3, 1.2, -0.45, 0.45, "+x", 0.8, spine)
    a.P("Front", -0.45, 0.45, 0.3, 1.2, -1.0, -1.0, "-z", 0.8, spine)
    a.P("Back", -0.45, 0.45, 0.3, 1.2, 1.0, 1.0, "+z", 0.8, spine)
    a.eyes2(1.0, 0.7, 1.1, -0.95, -0.6)
    return a


def garden_eel():
    a = F("GardenEel", "burrower")
    a.label = "Garden Eel"
    white, spot = (250, 248, 240), (40, 40, 44)
    mound(a, 1.4, 0.6, SAND)
    a.C("Seg", 0.35, 0.6, 2.4, -0.35, 0.35, white)
    a.C("Spot", 0.36, 1.4, 1.7, -0.2, 0.2, spot)
    a.C("Seg2", 0.35, 2.4, 3.6, -0.6, 0.1, white)
    a.C("Spot2", 0.36, 2.9, 3.2, -0.4, -0.1, spot)
    a.C("Head", 0.4, 3.4, 4.1, -1.3, -0.3, white, "neck")
    a.eyes2(0.4, 3.75, 4.0, -1.15, -0.9)
    a.C("Seg3", 0.3, 0.3, 1.6, 1.8, 2.4, (240, 160, 60))
    a.C("Head3", 0.32, 1.5, 2.0, 1.4, 2.4, (240, 160, 60))
    a.eyes2(0.32, 1.65, 1.9, 1.5, 1.75)
    return a


def seagull():
    a = F("Seagull", "flyer")
    white, grey = (250, 250, 250), (170, 176, 186)
    bird(a, white, w=0.7, leg_h=0, bh=1.3, z0=-0.9, z1=1.0, hw=0.55, hh=0.9, hl=1.0, head_y=0.8, beak_c=(250, 200, 60),
         beak_l=0.7, beak_w=0.2, span=4.4, chord=1.2, tail_l=0.8, fly=4.5, wing_c=grey)
    return a


def pelican():
    a = F("Pelican", "flyer")
    white, pouch = (246, 244, 236), (250, 190, 90)
    bird(a, white, w=1.0, leg_h=0, bh=1.8, z0=-1.2, z1=1.4, hw=0.6, hh=1.0, hl=1.2, head_y=1.4, beak_c=pouch,
         beak_l=0.4, beak_w=0.3, span=5.2, chord=1.6, tail_l=0.8, fly=4.0, wing_c=(200, 196, 190))
    a.C("Bill", 0.3, 5.7, 6.0, -3.6, -1.6, pouch, "neck")
    a.C("Pouch", 0.3, 5.0, 5.7, -3.2, -1.6, (240, 150, 70), "neck")
    a.C("Fish", 0.15, 5.2, 5.5, -3.0, -2.2, (120, 170, 220), "neck")
    return a


def sea_otter():
    a = F("SeaOtter")
    a.label = "Sea Otter"
    fur, face = (130, 90, 60), (220, 200, 170)
    a.C("Body", 1.0, 0.0, 1.6, -1.2, 2.0, fur)
    a.C("Chest", 0.8, 1.6, 2.6, -1.4, -0.2, fur)
    a.C("Head", 0.8, 1.8, 3.2, -2.6, -1.0, face, "neck")
    a.C("Snout", 0.4, 2.0, 2.6, -3.0, -2.6, face, "neck")
    a.nose(0.25, 2.3, 2.55, -3.0, (40, 30, 30))
    a.eyes2(0.8, 2.7, 3.0, -2.5, -2.2)
    a.S("Ear", 0.6, 0.8, 3.2, 3.45, -1.6, -1.3, fur, "neck")
    a.S("Paw", 0.3, 0.7, 2.0, 2.4, -2.0, -1.4, fur)
    a.C("Shell", 0.5, 2.4, 2.6, -2.2, -1.6, (230, 160, 160))
    a.S("Foot", 0.4, 0.9, 0.0, 0.3, 2.0, 2.8, fur)
    a.C("Tail", 0.4, 0.0, 0.4, 2.0, 3.4, fur)
    return a


def sea_turtle():
    a = F("SeaTurtle")
    a.label = "Sea Turtle"
    skin, shell, rim = (120, 170, 120), (90, 120, 70), (200, 190, 130)
    a.C("Shell", 1.8, 0.6, 2.2, -1.8, 1.8, shell)
    a.C("Rim", 1.95, 0.4, 0.9, -1.95, 1.95, rim)
    a.C("Top", 1.2, 2.2, 2.7, -1.2, 1.2, shell)
    a.C("Head", 0.7, 0.8, 1.9, -3.0, -1.8, skin, "neck")
    a.eyes2(0.7, 1.35, 1.65, -2.9, -2.6)
    a.S("Flipper", 1.9, 3.4, 0.0, 0.3, -1.6, -0.6, skin)
    a.SP("FlipperTip", 3.4, 3.4, 0.0, 0.3, -1.6, -0.6, "+x", 0.6, skin)
    a.S("Back", 1.0, 1.9, 0.0, 0.3, 1.4, 2.4, skin)
    return a


def swordfish():
    a = F("Swordfish")
    blue, belly = (60, 90, 160), (220, 230, 240)
    fish(a, blue, w=0.8, h=1.8, z0=-1.6, z1=2.2, belly=belly, fin_c=(40, 60, 120))
    a.P("Sword", -0.2, 0.2, 1.1, 1.5, -1.6, -1.6, "-z", 3.2, (150, 160, 180), "neck")
    return a


# ---------------------------------------------------------------- rare

def manta_ray():
    a = F("MantaRay", rare=True)
    a.label = "Manta Ray"
    top, belly = (50, 60, 90), (240, 244, 250)
    a.C("Belly", 2.0, 0.6, 1.0, -3.0, 2.0, belly)
    a.C("Body", 2.0, 1.0, 2.0, -3.0, 2.0, top)
    a.S("Wing", 2.0, 5.0, 1.2, 1.7, -2.0, 1.4, top)
    a.SP("WingTip", 5.0, 5.0, 1.2, 1.7, -1.6, 0.4, "+x", 2.0, top)
    a.S("Horn", 1.2, 1.8, 0.8, 1.6, -4.0, -3.0, top, "neck")
    a.eyes2(2.0, 1.3, 1.7, -2.8, -2.4)
    a.C("Tail", 0.2, 1.2, 1.5, 2.0, 6.0, top)
    a.C("Spot", 1.0, 2.0, 2.05, -1.0, 0.4, (220, 226, 236))
    grow(a, 1.6)
    return a


def hammerhead():
    a = F("Hammerhead", rare=True)
    grey, belly = (130, 140, 156), (236, 240, 246)
    fish(a, grey, w=1.2, h=2.4, z0=-2.6, z1=3.4, belly=belly, fin_c=(100, 110, 130), mouth=(60, 50, 60))
    a.C("Hammer", 2.8, 1.6, 2.4, -3.4, -2.4, grey, "neck")
    a.parts = [p for p in a.parts if not p.name.startswith(("Eye", "Pupil"))]  # eyes go on the hammer's ends
    a.eyes2(2.8, 1.75, 2.25, -3.3, -2.9)
    a.W("BigDorsal", -0.3, 0.3, 2.8, 4.8, -0.4, 1.4, (100, 110, 130), "up_back")
    grow(a, 1.5)
    return a


def anglerfish():
    a = F("Anglerfish", rare=True)
    skin, tooth = (70, 60, 70), (250, 250, 240)
    a.C("Body", 1.6, 0.4, 3.2, -1.4, 1.6, skin)
    a.C("Jaw", 1.7, 0.2, 1.4, -2.4, -1.4, skin, "neck")
    a.C("Head", 1.5, 1.8, 3.2, -2.2, -1.4, skin, "neck")
    a.B("PlainMouth", -1.4, 1.4, 1.4, 1.8, -2.25, -2.2, (30, 20, 30), "neck")
    a.spikes("Tooth", (-1.1, -0.4, 0.4, 1.1), 1.4, (-2.2,), 0.3, 0.6, tooth, bone="neck")
    a.eyes2(1.5, 2.4, 2.8, -2.1, -1.7, (230, 230, 120))
    a.C("Rod", 0.1, 3.2, 4.6, -1.0, -0.8, skin, "neck")
    a.C("Rod2", 0.1, 4.4, 4.6, -3.0, -0.8, skin, "neck")
    a.C("GlowLure", 0.35, 3.6, 4.3, -3.4, -2.7, (150, 250, 230), "neck")
    a.C("TailRoot", 0.8, 1.2, 2.4, 1.6, 2.2, skin)
    a.W("FinTop", -0.2, 0.2, 1.8, 3.2, 2.2, 3.4, (100, 80, 100))
    a.W("FinBottom", -0.2, 0.2, 0.6, 1.8, 2.2, 3.2, (100, 80, 100), "down_front")
    grow(a, 1.3)
    return a


def orca():
    a = F("Orca", rare=True)
    blk, white = (30, 30, 36), (250, 250, 250)
    fish(a, blk, w=2.2, h=4.0, z0=-4.6, z1=4.6, belly=white, fin_c=blk, fin_h=3.0, dorsal=False)
    a.W("TallDorsal", -0.3, 0.3, 4.4, 8.0, -0.4, 1.6, blk, "up_back")
    a.S("Patch", 2.0, 2.01, 2.6, 3.2, -3.6, -2.4, white, "neck")
    a.C("Saddle", 1.2, 4.4, 4.45, 1.6, 3.0, (150, 150, 160))
    grow(a, 2.0)
    return a


def spider_crab():
    """Titan: a giant spider crab on stilt legs; the shell rides high above the herd."""
    a = F("SpiderCrab", "titan", rare=True)
    a.label = "Giant Spider Crab"
    shell, leg, joint, spot = (220, 110, 70), (230, 140, 90), (250, 236, 210), (180, 80, 50)
    y = 30.0
    a.C("Shell", 6.0, y, y + 6.0, -6.0, 6.0, shell)
    a.C("Top", 4.0, y + 6.0, y + 8.0, -4.0, 4.0, shell)
    a.spikes("Spine", (-3.0, 0.0, 3.0), y + 8.0, (-2.0, 1.5), 1.2, 1.6, spot)
    a.S("Stalk", 1.0, 1.8, y + 4.0, y + 7.0, -6.6, -5.4, shell, "neck")
    a.S("PlainBall", 0.8, 2.0, y + 7.0, y + 8.2, -6.8, -5.6, (30, 30, 40), "neck")
    for i, z in enumerate((-4.5, -1.5, 1.5, 4.5)):
        spread = 16.0 + abs(z) * 0.6
        a.S(f"Leg{i}", 6.0, spread, y + 1.5, y + 2.5, z - 0.6, z + 0.6, leg)
        a.S(f"Knee{i}", spread - 0.1, spread + 1.3, y + 1.0, y + 3.0, z - 0.8, z + 0.8, joint)
        a.S(f"Shin{i}", spread, spread + 1.2, 2.0, y + 1.0, z - 0.6, z + 0.6, leg)
        a.SP(f"Toe{i}", spread, spread + 1.2, 2.0, 2.0, z - 0.6, z + 0.6, "-y", 2.0, joint)
    a.S("Arm", 2.0, 3.0, y - 6.0, y + 1.0, -7.0, -6.0, leg)
    a.S("Claw", 1.5, 3.5, y - 9.0, y - 6.0, -8.0, -5.0, shell)
    return a


COMMON = [pufferfish, seahorse, shrimp, sea_urchin, garden_eel, seagull, pelican, sea_otter, sea_turtle, swordfish]
RARE = [manta_ray, hammerhead, anglerfish, orca, spider_crab]
GROUND = ((234, 216, 164), (222, 204, 152))
