"""Gingerbread Man: World 3 Candyland Uncommon ("run, run, as fast as you can"). A thick
gingerbread cookie on two legs: a round stepped head, arms angled out and down, white piped
icing (wavy cuffs on the wrists and ankles, a smile, brows), three gumdrop buttons (cherry,
lime, lemon), bubblegum cheeks, googly plate eyes, and a peppermint cushion on his back
between the shoulders for the rider. Every cookie block is 1.6 studs thick (no flat cutouts).

Bones: root (the torso) -> neck (head), ArmL, ArmR, LegHL, LegHR (hips). Rests baked, all
bones at 0 (convert without --zyx).

  idle    bobbing on the spot, arms swaying, head tilting
  walk    a jaunty march, arms swinging opposite the legs
  gallop  a flat-out sprint, leaning forward, legs and arms pumping

    python3 tools/gingerbread_man.py [--still]
"""

import math
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import candy_common as C  # noqa: E402
from animal_designs import Animal  # noqa: E402

COOKIE = C.GINGER
COOKIE_DK = C.GINGER_DK
ICE = C.ICING
ZF, ZB = -0.8, 0.8  # cookie front and back faces


def gingerbread(name="GingerbreadMan", rarity="Uncommon"):
    a = Animal(name, rarity)
    a.bone_order = [("root", None), ("neck", "root"), ("ArmL", "root"), ("ArmR", "root"),
                    ("LegHL", "root"), ("LegHR", "root")]

    # ---- torso: a stepped cookie slab, darker baked edge round the sides
    a.box("Torso", (-1.9, 3.2, ZF), (1.9, 6.6, ZB), COOKIE, "root")
    a.box("TorsoHip", (-1.6, 2.9, ZF + 0.1), (1.6, 3.2, ZB - 0.1), COOKIE, "root")
    C.sym(a, "TorsoEdge*", (1.9, 3.4, ZF + 0.15), (2.05, 6.4, ZB - 0.15), COOKIE_DK, "root")
    # three gumdrop buttons: a base and a smaller top each
    for i, (y, col, dk) in enumerate(((5.6, C.CHERRY, C.CHERRY_DK), (4.7, C.LIME, C.LIME_DK), (3.8, C.LEMON, C.LEMON_DK))):
        a.box(f"Button{i + 1}", (-0.4, y - 0.3, ZF - 0.25), (0.4, y + 0.3, ZF), dk, "root")
        a.box(f"ButtonTop{i + 1}", (-0.25, y - 0.18, ZF - 0.45), (0.25, y + 0.2, ZF - 0.25), col, "root")
    # piped icing belt: a wavy line of blocks across the hips
    for i in range(7):
        xx = -1.5 + i * 0.5
        dy = 0.12 if i % 2 else 0.0
        a.box(f"BeltIcing{i + 1}", (xx - 0.22, 3.15 + dy, ZF - 0.2), (xx + 0.22, 3.35 + dy, ZF), ICE, "root")
    # peppermint cushion on the back for the rider: red and white wedges as stripes
    stripes = [C.CHERRY, ICE, C.CHERRY, ICE, C.CHERRY]
    for i, col in enumerate(stripes):
        xa = -1.5 + 0.6 * i
        cut = 0.3 if i in (0, 4) else 0.0  # outer stripes shorter: a round mint
        a.box(f"Mint{i + 1}", (xa, 5.0 + cut, ZB), (xa + 0.6, 6.6 - cut, ZB + 1.0), col, "root")
    a.box("MintTop", (-1.2, 6.6, ZB + 0.1), (1.2, 6.8, ZB + 0.9), C.CHERRY_DK, "root")

    # ---- head (neck bone): round from stepped blocks
    a.box("Head", (-1.6, 6.9, ZF), (1.6, 9.3, ZB), COOKIE, "neck")
    a.box("HeadWide", (-1.85, 7.3, ZF + 0.05), (1.85, 8.9, ZB - 0.05), COOKIE, "neck")
    a.box("HeadTop", (-1.15, 9.3, ZF + 0.05), (1.15, 9.65, ZB - 0.05), COOKIE, "neck")
    a.box("Neck", (-0.9, 6.5, ZF + 0.1), (0.9, 6.9, ZB - 0.1), COOKIE, "neck")
    # a bite out of the top-right of his head (a notch, darker crumb inside)
    a.box("Bite", (1.15, 9.0, ZF + 0.05), (1.6, 9.3, ZB - 0.05), COOKIE_DK, "neck")
    C.front_eyes(a, 0.68, 8.0, 8.95, ZF, 0.7, "neck")
    # icing brows, smile and cheeks
    C.sym(a, "Brow*", (0.35, 9.0, ZF - 0.15), (1.05, 9.15, ZF), ICE, "neck")
    for i, (xx, yy) in enumerate(((-0.9, 7.55), (-0.5, 7.3), (0.0, 7.22), (0.5, 7.3), (0.9, 7.55))):
        a.box(f"Smile{i + 1}", (xx - 0.24, yy, ZF - 0.18), (xx + 0.24, yy + 0.2, ZF), ICE, "neck")
    C.sym(a, "Cheek*", (1.15, 7.65, ZF - 0.1), (1.55, 7.95, ZF), C.BUBBLE, "neck")
    a.pivots["neck"] = (0, 6.6, 0)

    # ---- arms: angled out and down, rounded hand, wavy icing cuff
    for side, sx in (("L", -1), ("R", 1)):
        bone = "Arm" + side
        sh = (sx * 1.7, 6.0, 0)
        hand = (sx * 3.7, 4.4, 0)
        C.beam(a, "Arm" + side, sh, hand, 1.6, 1.3, COOKIE, bone, pad=0.6)
        C.beam(a, "Hand" + side, (sx * 3.55, 4.52, 0), (sx * 4.15, 4.04, 0), 1.75, 1.0, COOKIE, bone)
        for k, t in enumerate((0.62, 0.72)):
            p = (sh[0] + (hand[0] - sh[0]) * t, sh[1] + (hand[1] - sh[1]) * t, ZF - 0.08)
            C.beam(a, f"Cuff{side}{k + 1}", (p[0], p[1], ZF - 0.02), (p[0], p[1], ZF - 0.2), 0.32 if k else 0.2, 1.35, ICE, bone)
        a.pivots[bone] = (sx * 1.8, 6.0, 0)

    # ---- legs: thick cookie legs with rounded feet and icing ankle bands
    for side, sx in (("L", -1), ("R", 1)):
        bone = "LegH" + side
        xa, xb = sorted((sx * 0.25, sx * 1.75))
        a.box("Leg" + side, (xa, 0.4, ZF), (xb, 3.4, ZB), COOKIE, bone)
        fa, fb = sorted((sx * 0.15, sx * 1.85))
        a.box("Foot" + side, (fa, 0, ZF - 0.15), (fb, 0.5, ZB), COOKIE, bone)
        for k in range(3):
            xx = xa + 0.25 + k * 0.5
            dy = 0.1 if k % 2 else 0.0
            a.box(f"Ankle{side}{k + 1}", (xx - 0.22, 1.0 + dy, ZF - 0.18), (xx + 0.22, 1.2 + dy, ZF), ICE, bone)
        a.pivots[bone] = (sx * 1.0, 3.3, 0)

    a.pivots["root"] = (0, 4.5, 0)
    a.meta = {"seat": (0, 6.6, 1.5), "neck_loop": {"center": (0, 8.2, 0), "radius": 2.2}}
    a.animations = animations
    return a


def animations():
    tr = C.track

    def moves(L, leg, arm, bob, lean, n):
        s = lambda u, ph=0.0: math.sin(C.TAU * (u - ph))
        return {
            "root": [tr(L, lambda u: (-lean, 0, 3 * s(u) if leg < 40 else 0), n),
                     tr(L, lambda u: (0, bob * abs(s(u)), 0), n, "position")],
            "neck": [tr(L, lambda u: (lean * 0.5, 0, -4 * s(u)), n)],
            "LegHL": [tr(L, lambda u: (leg * s(u), 0, 0), n)],
            "LegHR": [tr(L, lambda u: (-leg * s(u), 0, 0), n)],
            "ArmL": [tr(L, lambda u: (-arm * s(u), 0, 0), n)],
            "ArmR": [tr(L, lambda u: (arm * s(u), 0, 0), n)],
        }

    L = 2.0
    idle = (L, {"root": [C.track(L, lambda u: (0, 2 * abs(math.sin(C.TAU * u)), 0), 16, "position")],
                "neck": [C.track(L, lambda u: (0, 0, 6 * math.sin(C.TAU * u)), 16)],
                "ArmL": [C.track(L, lambda u: (0, 0, -6 + 6 * math.sin(C.TAU * u)), 16)],
                "ArmR": [C.track(L, lambda u: (0, 0, 6 - 6 * math.sin(C.TAU * u)), 16)]})
    return {"idle": idle, "walk": (0.8, moves(0.8, 28, 24, 3, 2, 16)), "gallop": (0.5, moves(0.5, 50, 45, 6, 14, 16))}


if __name__ == "__main__":
    C.publish(gingerbread(), still="--still" in sys.argv)
