"""Gumball Golem: World 3 Candyland giga rare (about 1 in 1000 spawns). A giant lumbering
golem whose body IS a gumball machine. Its belly is a cherry-red machine base with a
chrome coin plate (a gold coin stuck half way in the slot), a chrome crank that turns as it
walks and a chute door that grins (white chiclet teeth, a bubblegum tongue with a gumball
rolling out). Its chest and head is the giant glass globe: a cage of pale sky-blue glass
ribs belted round the middle by a chrome band, packed with rainbow gumballs bulging between
the ribs, two big googly eyes on glass panes at the front and a chrome lid on top that the
rider sits on (a cherry cushion with a gumball pommel). Arms and legs are stacked giant
gumballs and swirl-striped jawbreakers, ending in huge swirl jawbreaker fists and chunky
grape feet with white gumball toes.

Bones (every rest baked into the parts, every bone at 0, convert WITHOUT --zyx):
  root    the machine base (hips and belly), parent of everything
  neck    the globe, lid and seat (the chest and head)
  Balls   the gumballs packed inside the globe (they rattle as it stomps), child of neck
  ArmL/R  the arms, children of neck (they hang off the chrome belt)
  LegFL/R the legs (biped legs use the front-leg names, as the Cactus boss and Asura)
  Crank   the chrome crank on the coin plate, spins about z

    python3 tools/gumball_golem.py [--still]
"""

import math
import os
import random
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(__file__))
import candy_common as C  # noqa: E402
from candy_common import T, Rx, Ry, Rz, TAU, track  # noqa: E402
from animal_designs import Animal  # noqa: E402

NAME = "GumballGolem"
RED, RED_DK = C.CHERRY, C.CHERRY_DK
GLASS = (176, 226, 255)
GLASS_DK = (120, 190, 246)
SHINE = (250, 254, 255)
CHROME = (206, 214, 226)
CHROME_DK = (150, 160, 178)
GOLD = (255, 200, 40)
GOLD_DK = (226, 150, 20)
GUM = [C.CHERRY, C.LEMON, C.LIME, C.SKY, C.GRAPE, C.ORANGE, C.BUBBLE, C.WHITE]
GUM_DK = [C.CHERRY_DK, C.LEMON_DK, C.LIME_DK, C.SKY_DK, C.GRAPE_DK, C.ORANGE_DK, C.BUBBLE_DK, (226, 222, 236)]

GC = np.array([0.0, 12.9, 0.0])  # globe centre
R = 4.0                           # globe (rib) radius
HIP_X, HIP_Y = 2.1, 5.2
SHOULDER = np.array([R + 0.45, GC[1] - 0.1, 0.0])


def axes(z, y_hint):
    """A rotation whose local z is z and local y is as close to y_hint as it can be."""
    z = np.array(z, float)
    z /= np.linalg.norm(z)
    y = np.array(y_hint, float) - np.dot(y_hint, z) * z
    if np.linalg.norm(y) < 1e-6:
        y = np.array([1.0, 0, 0]) - z[0] * z
    y /= np.linalg.norm(y)
    x = np.cross(y, z)
    M = np.eye(4)
    M[:3, 0], M[:3, 1], M[:3, 2] = x, y, z
    return M


def gumball_golem():
    a = Animal(NAME, "Legendary")
    a.bone_order = [("root", None), ("neck", "root"), ("Balls", "neck"), ("ArmL", "neck"), ("ArmR", "neck"),
                    ("LegFL", "root"), ("LegFR", "root"), ("Crank", "root")]
    rnd = random.Random(7)

    def cube_ball(name, c, s, col, bone, shine=False, M=None, seg=10):
        """A round gumball of diameter s centred on c (a smooth mesh)."""
        C.hull(a, "Smooth" + name, C.G.ellipsoid(c, (s / 2,) * 3, seg=seg, rings=seg // 2), col, bone)

    def band(name, c, r, dy, h, col, bone, seg=12):
        """A stripe round a ball: the slice of a slightly bigger sphere from dy - h/2 to dy + h/2."""
        P = C.G.ellipsoid(c, (r * 1.05,) * 3, seg=seg, rings=8, twist=0.0)
        P[:, 1] = np.clip(P[:, 1], c[1] + dy - h / 2, c[1] + dy + h / 2)
        C.hull(a, "Smooth" + name, P, col, bone)

    def jaw(name, c, r, cols, bone, **_):
        """A striped jawbreaker: a round ball in cols[0] wrapped by bands in the other colours."""
        c = np.array(c, float)
        s = 2 * r
        cube_ball(name, c, s, cols[0], bone, seg=12)
        nb = len(cols) - 1
        for k, col in enumerate(cols[1:]):
            dy = (k - (nb - 1) / 2) * min(0.42 * s / max(nb - 1, 1), 0.28 * s) if nb > 1 else 0.0
            band(f"{name}Band{k + 1}", c, r, dy, 0.12 * s, col, bone)

    # ================================================================ machine base (root)
    bx, by0, by1, bz = 3.4, 4.9, 8.9, 2.9
    a.box("Base", (-bx, by0, -bz), (bx, by1, bz), RED, "root")
    C.sym(a, "BaseSide*", (bx, by0 + 0.35, -bz + 0.35), (bx + 0.25, by1 - 0.35, bz - 0.35), RED, "root")
    a.box("BaseBack", (-bx + 0.35, by0 + 0.35, bz), (bx - 0.35, by1 - 0.35, bz + 0.25), RED, "root")
    a.box("BaseFront", (-bx + 0.35, by0 + 0.35, -bz - 0.25), (bx - 0.35, by1 - 0.35, -bz), RED, "root")
    # plinth and shoulder lip in the dark stop
    a.box("Plinth", (-bx - 0.3, by0 - 0.35, -bz - 0.45), (bx + 0.3, by0 + 0.35, bz + 0.45), RED_DK, "root")
    a.box("Lip", (-bx - 0.2, by1 - 0.4, -bz - 0.4), (bx + 0.2, by1 + 0.1, bz + 0.4), RED_DK, "root")
    # chrome collar the globe sits in (stepped rings)
    C.hull(a, "SmoothCollar", C.G.prism((0, by1 + 0.1, 0), 3.1, 0.9, seg=16, top=0.95), CHROME, "root")
    # chrome corner posts (rivets down the edges)
    for sx in (-1, 1):
        for sz in (-1, 1):
            side = ("L" if sx < 0 else "R") + ("F" if sz < 0 else "B")
            a.box("MetalPost" + side, (sx * bx - 0.3, by0 + 0.35, sz * bz - 0.3), (sx * bx + 0.3, by1 - 0.4, sz * bz + 0.3),
                  CHROME, "root")
            for k, y in enumerate((5.9, 7.9)):
                a.box(f"Rivet{side}{k + 1}", (sx * bx - 0.36, y, sz * bz - 0.36), (sx * bx + 0.36, y + 0.3, sz * bz + 0.36),
                      CHROME_DK, "root")
    fz = -bz - 0.25  # the front face
    # coin plate: chrome, raised, with a slot and a gold coin half way in
    a.box("MetalPlate", (-1.35, 6.75, fz - 0.3), (1.35, 8.55, fz), CHROME, "root")
    a.box("MetalPlateRim", (-1.5, 6.6, fz - 0.15), (1.5, 8.7, fz), CHROME_DK, "root")
    a.box("Slot", (-0.5, 7.85, fz - 0.42), (0.5, 8.15, fz - 0.3), C.CHOC_DK, "root")
    a.box("Coin", (-0.32, 8.0, fz - 0.4), (0.32, 8.75, fz - 0.32), GOLD, "root")
    a.box("CoinTop", (-0.22, 8.75, fz - 0.4), (0.22, 8.85, fz - 0.32), GOLD_DK, "root")
    # side bolts on the plate
    for sx in (-1, 1):
        a.box("MetalBolt" + ("L" if sx < 0 else "R"), (sx * 1.05 - 0.15, 6.9, fz - 0.4), (sx * 1.05 + 0.15, 7.2, fz - 0.3),
              CHROME_DK, "root")
    # the crank (its own bone, spins about z): hub, arm and a cherry knob
    hub = np.array([0.0, 7.45, fz - 0.3])
    a.pivots["Crank"] = tuple(hub)
    C.rbox(a, "MetalHub", (0.75, 0.75, 0.3), T(*hub) @ T(0, 0, -0.15) @ Rz(45), CHROME_DK, "Crank")
    C.rbox(a, "MetalHubCap", (0.5, 0.5, 0.2), T(*hub) @ T(0, 0, -0.4), CHROME, "Crank")
    C.rbox(a, "MetalCrankArm", (1.6, 0.34, 0.22), T(*hub) @ T(0.55, 0, -0.55), CHROME, "Crank")
    C.rbox(a, "MetalCrankStem", (0.22, 0.22, 0.5), T(*hub) @ T(1.15, 0, -0.85), CHROME, "Crank")
    cube_ball("CrankKnob", hub + (1.15, 0, -1.3), 0.65, C.CHERRY, "Crank")
    # the chute door: a grinning mouth with chiclet teeth, a bubblegum tongue and a gumball
    a.box("MetalChute", (-1.9, 5.25, fz - 0.35), (1.9, 6.45, fz), CHROME, "root")
    a.box("MetalChuteLip", (-2.05, 5.15, fz - 0.55), (2.05, 5.4, fz - 0.05), CHROME_DK, "root")
    a.box("Mouth", (-1.55, 5.4, fz - 0.42), (1.55, 6.25, fz - 0.3), C.CHOC_DK, "root")
    a.wedge("MouthCornerL", (-1.55, 5.4, fz - 0.43), (-1.15, 5.8, fz - 0.31), CHROME_DK,
            "root", "down_front")
    for k in range(5):
        x = -1.2 + 0.6 * k
        a.box(f"Tooth{k + 1}", (x - 0.24, 5.9, fz - 0.55), (x + 0.24, 6.25, fz - 0.3), C.WHITE, "root")
    a.box("Tongue", (-0.85, 5.35, fz - 0.7), (0.85, 5.55, fz - 0.3), C.BUBBLE, "root")
    a.box("TongueTip", (-0.7, 5.25, fz - 1.0), (0.7, 5.45, fz - 0.7), C.BUBBLE_DK, "root")
    cube_ball("ChuteGum", (0.25, 5.85, fz - 0.95), 0.6, C.LIME, "root")
    # back: a lemon price label tablet and a big screw-in coin box
    a.box("BackPanel", (-1.4, 6.0, bz + 0.25), (1.4, 8.0, bz + 0.5), RED_DK, "root")
    a.box("Label", (-1.1, 6.3, bz + 0.5), (1.1, 7.7, bz + 0.7), C.LEMON, "root")
    a.box("LabelCoin", (-0.4, 6.65, bz + 0.7), (0.4, 7.35, bz + 0.85), GOLD_DK, "root")
    # side decals: a big swirl candy boss on each side
    for side, sx in (("L", -1), ("R", 1)):
        xs = sorted((sx * (bx + 0.25), sx * (bx + 0.5)))
        a.box("SideBoss" + side, (xs[0], 6.2, -1.1), (xs[1], 8.2, 1.1), C.WHITE, "root")
        xs2 = sorted((sx * (bx + 0.5), sx * (bx + 0.65)))
        a.box("SideBossRing" + side, (xs2[0], 6.5, -0.8), (xs2[1], 7.9, 0.8), C.CHERRY, "root")
        xs3 = sorted((sx * (bx + 0.65), sx * (bx + 0.8)))
        a.box("SideBossDot" + side, (xs3[0], 6.85, -0.45), (xs3[1], 7.55, 0.45), C.LEMON, "root")
    a.pivots["root"] = (0, 7.0, 0)

    # ================================================================ globe (neck)
    # A chunky stepped glass globe: pale sky glass blocks with a neat grid of rainbow
    # gumballs pressed into every side, bulging out between glass mullions.
    a.pivots["neck"] = (0, by1 + 0.5, 0)
    a.pivots["Balls"] = tuple(GC)
    g = 4.2  # globe radius
    C.hull(a, "SmoothGlobe", C.G.ellipsoid(GC, (g, g, g), seg=20, rings=10), GLASS, "neck")
    k_ball = [0]

    def gum(c, size=1.6):
        k_ball[0] += 1
        col = rnd.choice(GUM)
        cube_ball(f"Gum{k_ball[0]}", c, size, col, "Balls")

    # rainbow gumballs pressed into the glass all over, bulging out (a golden spiral, skipping
    # the face and the shoulder hubs)
    for i in range(130):
        y = 1 - 2 * (i + 0.5) / 130
        rr, t = math.sqrt(1 - y * y), i * 2.39996
        d = np.array((rr * math.cos(t), y, rr * math.sin(t)))
        if y > 0.8 or y < -0.72 or (d[2] < -0.55 and -0.25 < y < 0.75) or abs(d[0]) > 0.85 and abs(y) < 0.3:
            continue
        gum(GC + d * (g - 0.15), 1.55)
    print("globe gumballs:", k_ball[0])
    # a glass glint on the upper-left front
    for k, (phi, az, h) in enumerate(((28, -42, 1.6), (48, -36, 0.5))):
        p_, a_ = math.radians(phi), math.radians(az)
        d = np.array((math.cos(p_) * math.sin(a_), math.sin(p_), -math.cos(p_) * math.cos(a_)))
        C.stick(a, f"Glint{k + 1}", GC + d * g, d, (0.4, h, 0.2), SHINE, "neck", 0, 0.5)
    # googly eyes on the front of the glass, under chunky lemon-stick brows
    for side, sx in (("L", -1), ("R", 1)):
        d = np.array((sx * 0.3, 0.3, -1.0))
        d /= np.linalg.norm(d)
        C.surface_eye(a, side, GC + d * g, d, 2.0, 2.3, "neck")
        d2 = np.array((sx * 0.3, 0.68, -0.85))
        d2 /= np.linalg.norm(d2)
        C.stick(a, "Brow" + side, GC + d2 * g, d2, (2.4, 0.5, 0.6), C.LEMON_DK, "neck", sx * 8, 0.3)
    # chrome shoulder hubs on the sides
    for side, sx in (("L", -1), ("R", 1)):
        C.hull(a, "SmoothShoulderHub" + side, C.G.prism(GC + (sx * (g - 0.6), 0, 0), 1.3, 1.0, seg=12,
               M=C.G.R("z", -90 * sx)), CHROME, "neck")
    # chrome lid on top, the seat on it
    top = GC[1] + g
    C.hull(a, "SmoothLid", C.G.dome((0, top - 0.75, 0), 3.0, 1.9, seg=16, rings=4, base=0.3), CHROME, "neck")
    sy = top + 1.15
    a.box("Seat", (-1.25, sy, -0.9), (1.25, sy + 0.4, 1.5), RED, "neck")
    a.box("SeatBack", (-1.3, sy, 1.5), (1.3, sy + 1.0, 1.95), RED_DK, "neck")
    a.box("SeatPipe", (-1.38, sy + 1.0, 1.45), (1.38, sy + 1.2, 2.0), C.WHITE, "neck")
    cube_ball("Pommel", (0, sy + 0.45, -1.2), 0.8, C.LEMON, "neck")
    for side, sx in (("L", -1), ("R", 1)):
        xs = sorted((sx * 1.25, sx * 1.45))
        a.box("SeatSide" + side, (xs[0], sy - 0.05, -0.9), (xs[1], sy + 0.55, 1.5), C.WHITE, "neck")

    # ================================================================ arms (stacked gumballs)
    for side, sx in (("L", -1), ("R", 1)):
        bone = "Arm" + side
        S = SHOULDER * (sx, 1, 1)
        a.pivots[bone] = tuple(S)
        jaw("Shoulder" + side, S + (sx * 0.95, 0.1, 0), 1.35, [C.SKY, C.WHITE, C.CHERRY, C.WHITE], bone)
        E = S + (sx * 1.7, -3.2, 0.25)
        cube_ball("UpperArm" + side, S + (sx * 1.35, -1.8, 0.1), 1.9, C.LIME, bone)
        jaw("Elbow" + side, E, 1.0, [C.ORANGE, C.LEMON], bone)
        cube_ball("Forearm" + side, E + (sx * 0.2, -1.45, -0.2), 1.85, C.BUBBLE, bone)
        F = E + (sx * 0.35, -3.9, -0.4)
        # the jawbreaker fist: a big cherry ball banded with white and lemon stripes
        fs = 3.3
        cube_ball("Fist" + side, F, fs, C.CHERRY, bone)
        for k, (dy, col) in enumerate(((0.75, C.WHITE), (0.0, C.LEMON), (-0.75, C.WHITE))):
            band(f"Fist{side}Band{k + 1}", F, fs / 2, dy, 0.4, col, bone)
        for k in range(3):  # gumball knuckles across the front
            cube_ball(f"Knuckle{side}{k + 1}", F + (sx * 0.95 * (k - 1), 0.3, -1.8), 0.9,
                      GUM[(k * 3 + (2 if sx > 0 else 0)) % 8], bone)
        cube_ball("Thumb" + side, F + (-sx * 1.75, 0.3, -0.9), 0.95, C.MINT, bone)
        # a licorice cuff where the forearm meets the fist
        C.rbox(a, "Cuff" + side, (1.9, 0.45, 1.9), T(*(F + (0, 1.65, 0))) @ Ry(45), C.CHOC, bone)

    # ================================================================ legs
    for side, sx in (("L", -1), ("R", 1)):
        bone = "LegF" + side
        H = np.array([sx * HIP_X, HIP_Y, 0.0])
        a.pivots[bone] = tuple(H)
        jaw("Hip" + side, H + (0, -0.35, 0), 1.35, [C.LEMON, C.WHITE, C.CHERRY, C.WHITE], bone)
        cube_ball("Thigh" + side, H + (sx * 0.1, -1.75, 0), 2.0, C.SKY, bone)
        jaw("Knee" + side, H + (sx * 0.15, -3.1, -0.15), 1.1, [C.GRAPE, C.BUBBLE], bone)
        # chunky grape foot: stepped slab, dark sole, white gumball toes
        fx0, fx1 = sx * HIP_X - 1.45, sx * HIP_X + 1.45
        a.box("Foot" + side, (fx0, 0.3, -2.0), (fx1, 1.35, 1.5), C.GRAPE, bone)
        a.box("FootTop" + side, (fx0 + 0.3, 1.35, -1.7), (fx1 - 0.3, 1.75, 1.2), C.GRAPE, bone)
        a.box("Sole" + side, (fx0 - 0.1, 0.0, -2.1), (fx1 + 0.1, 0.3, 1.6), C.GRAPE_DK, bone)
        for k in range(3):
            x = sx * HIP_X + (k - 1) * 0.95
            cube_ball(f"Toe{side}{k + 1}", (x, 0.75, -2.2), 0.85, C.WHITE, bone)
        a.box("Ankle" + side, (sx * HIP_X - 0.75, 1.75, -0.75), (sx * HIP_X + 0.75, 2.4, 0.75), C.GRAPE_DK, bone)

    a.meta = {"seat": (0, round(sy + 0.4, 2), 0.3),
              "neck_loop": {"center": (0, round(by1 + 0.6, 2), 0), "radius": 3.3}}
    a.animations = animations
    return a


LEG_LEN = HIP_Y  # hip to ground, studs


def drop(deg):
    """Blockbench units the root sinks so a leg turned deg still reaches the ground."""
    return -LEG_LEN * (1 - math.cos(math.radians(deg))) * 10


def animations():
    """Negative x rotation leans the body forward (toward -z). The crank spins, the gumballs
    rattle, the globe sways."""
    s = lambda u, ph=0.0: math.sin(TAU * (u - ph))

    L = 3.0
    idle = {
        "root": [track(L, lambda u: (0, 0, 0), 4),
                 track(L, lambda u: (0, -1.2 * (1 - math.cos(TAU * u)) / 2, 0), 16, "position")],
        "neck": [track(L, lambda u: (1.5 * s(u), 5 * s(u, 0.2), 2 * s(u, 0.1)), 16)],
        "Balls": [track(L, lambda u: (0, 0.6 * abs(s(2 * u)), 0), 16, "position")],
        "ArmL": [track(L, lambda u: (2 * s(u, 0.3), 0, -3 * (1 - math.cos(TAU * u)) / 2), 16)],
        "ArmR": [track(L, lambda u: (2 * s(u, 0.3), 0, 3 * (1 - math.cos(TAU * u)) / 2), 16)],
        "Crank": [{"channel": "rotation", "interp": "linear",
                   "keys": [(round(L * k / 4, 4), (0, 0, -90 * k)) for k in range(5)]}],
    }

    def gait(L, leg, arm, sway, pitch, hop, rattle, n):
        th = lambda u: leg * s(u)
        return {
            "root": [track(L, lambda u: (pitch, 0, sway * s(u)), n),
                     track(L, lambda u: (0, drop(th(u)) + hop * abs(s(u)), 0), n, "position")],
            "neck": [track(L, lambda u: (-pitch * 0.4 + 2 * s(2 * u, 0.15), -sway * 1.2 * s(u), -sway * 0.6 * s(u)), n)],
            "Balls": [track(L, lambda u: (0, rattle * abs(s(u, 0.1)), 0), n, "position")],
            "LegFL": [track(L, lambda u: (th(u) - pitch, 0, 0), n)],
            "LegFR": [track(L, lambda u: (-th(u) - pitch, 0, 0), n)],
            "ArmL": [track(L, lambda u: (-arm * s(u) + pitch * 0.5, 0, -4 - 3 * abs(s(u))), n)],
            "ArmR": [track(L, lambda u: (arm * s(u) + pitch * 0.5, 0, 4 + 3 * abs(s(u))), n)],
            "Crank": [{"channel": "rotation", "interp": "linear",
                       "keys": [(round(L * k / 4, 4), (0, 0, -90 * k)) for k in range(5)]}],
        }

    return {"idle": (L, idle),
            "walk": (1.3, gait(1.3, 20, 18, 4, 0, 2.5, 1.0, 24)),
            "gallop": (0.8, gait(0.8, 34, 42, 5, -8, 6.0, 1.8, 24))}


if __name__ == "__main__":
    C.publish(gumball_golem(), still="--still" in sys.argv)
