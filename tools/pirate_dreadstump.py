"""Dreadstump the Pirate King: World 3 Pirate Cove's boss (Oct 14), after RotMG's Pirate Cave boss.
A giant, round pirate captain who charges through you: a long red captain's coat with gold
trim and buttons, gold epaulettes, a black belt with a big gold buckle, a white frilled shirt,
a huge black beard with two gold-ringed braids, a big red nose, bushy brows over googly plate
eyes, and a giant black tricorn with gold trim, a white skull and crossbones and a red plume.
A gold cutlass in his right hand, an iron hook for his left, a black boot on one leg and a
wooden peg leg on the other (the stump). His parrot rides on his shoulder. As a pet you ride
on his shoulders, behind the head (seat on the back of the collar).

Run: python3 tools/pirate_dreadstump.py [--gif]

Bones: root (hips) -> body (torso, head, hat, parrot) -> ArmL (hook), ArmR (cutlass);
root -> LegL (boot), LegR (peg); root -> Coat (coat tails flap).

  idle    breathing, cutlass swaying, looking about
  walk    a stomping, swaying peg-leg march
  gallop  a charge: leaning in, cutlass raised, big strides, coat tails flying
"""

import math

import numpy as np

from pirate_lib import Model, track, TAU

NAME = "Dreadstump"
C = {"coat": (214, 34, 44), "coatdark": (150, 20, 34), "shirt": (252, 248, 236), "skin": (250, 196, 150),
     "nose": (236, 110, 100), "beard": (44, 32, 30), "hat": (34, 30, 40), "belt": (40, 32, 30),
     "boot": (50, 36, 30), "peg": (176, 118, 66), "pegdark": (126, 82, 44), "iron": (150, 156, 170),
     "blade": (226, 232, 242), "plume": (255, 70, 90), "parrot": (60, 200, 80), "parrotwing": (36, 120, 230),
     "beak": (255, 200, 60), "pants": (60, 70, 140)}


def build():
    m = Model(NAME, C)
    yh = 4.6  # hips
    root = m.group("root", (0, yh, 0))
    m.put(root, [m.box("Hips", (0, yh + 0.4, 0), (5.4, 1.6, 4.2), "pants")])

    body = m.group("body", (0, yh + 1.0, 0), root)
    p = [m.box("Belly", (0, yh + 3.2, -0.2), (6.6, 4.6, 5.4), "coat"),
         m.box("BellyShirt", (0, yh + 3.0, -2.95), (3.0, 4.0, 0.2), "shirt"),
         m.box("Chest", (0, yh + 6.2, 0), (7.0, 2.6, 4.8), "coat"),
         m.box("Collar", (0, yh + 7.6, 0.2), (5.0, 0.8, 4.2), "coatdark"),
         m.box("Belt", (0, yh + 2.0, -0.2), (6.8, 0.9, 5.6), "belt"),
         m.box("Buckle", (0, yh + 2.0, -3.05), (1.6, 1.3, 0.2), "gold"),
         m.box("BuckleHole", (0, yh + 2.0, -3.17), (0.8, 0.5, 0.06), "belt")]
    # gold trim down both coat fronts, gold buttons, shirt frills
    for s in (-1, 1):
        n = "LR"[s > 0]
        p += [m.box(f"Trim{n}", (s * 1.75, yh + 4.2, -2.95), (0.45, 6.2, 0.22), "gold"),
              m.box(f"Lapel{n}", (s * 1.4, yh + 6.6, -2.5), (1.2, 1.8, 0.3), "coatdark")]
        for j, y in enumerate((yh + 3.2, yh + 4.4, yh + 5.6)):
            p.append(m.box(f"Button{n}{j + 1}", (s * 2.4, y, -3.0), (0.45, 0.45, 0.2), "gold"))
    for j, y in enumerate((yh + 6.0, yh + 5.2, yh + 4.4)):
        p.append(m.box(f"Frill{j + 1}", (0, y, -3.05 - 0.15 * (j % 2)), (1.8 - 0.2 * j, 0.5, 0.35), "shirt"))
    # epaulettes: gold pads with a fringe of little gold blocks
    for s in (-1, 1):
        n = "LR"[s > 0]
        p.append(m.box(f"Epaulette{n}", (s * 3.5, yh + 7.6, 0), (2.0, 0.5, 2.2), "gold"))
        for j, z in enumerate((-0.8, 0, 0.8)):
            p.append(m.box(f"Fringe{n}{j + 1}", (s * 4.4, yh + 7.0, z), (0.3, 0.8, 0.3), "golddark"))

    # head: skin face, big nose, brows, plate eyes, a huge beard with two braids
    hy = yh + 9.8
    p += [m.box("Head", (0, hy, -0.2), (4.4, 4.0, 4.0), "skin"),
          m.box("Nose", (0, hy - 0.2, -2.6), (1.2, 1.3, 1.0), "nose"),
          m.box("Beard", (0, hy - 1.6, -1.0), (4.8, 2.6, 2.8), "beard"),
          m.box("BeardLow", (0, hy - 3.2, -1.4), (3.6, 1.2, 2.2), "beard"),
          m.box("Moustache", (0, hy - 0.85, -2.45), (3.4, 0.6, 0.6), "beard"),
          m.box("Mouth", (0, hy - 1.6, -2.42), (1.4, 0.4, 0.1), "coatdark")]
    for s in (-1, 1):
        n = "LR"[s > 0]
        p += m.eye(f"Eye{n}", (s * 0.95, hy + 0.55, -2.25), "front", size=1.25, look=(-s * 0.15, 0, 0))
        p += [m.box(f"Brow{n}", (s * 1.0, hy + 1.45, -2.3), (1.6, 0.45, 0.4), "beard", m_rot("z", s * 14)),
              m.box(f"Sideburn{n}", (s * 2.2, hy, -0.6), (0.3, 2.2, 1.8), "beard"),
              m.box(f"Ear{n}", (s * 2.3, hy + 0.3, 0.3), (0.4, 1.0, 0.8), "skin")]
        # beard braids with gold rings
        b0 = np.array([s * 1.0, hy - 3.6, -1.6])
        p += [m.seg(f"Braid{n}", b0, b0 + [s * 0.2, -1.8, -0.3], 0.6, 0.6, "beard"),
              m.box(f"BraidRing{n}", b0 + [s * 0.1, -0.9, -0.15], (0.75, 0.3, 0.75), "gold"),
              m.pyr(f"BraidTip{n}", b0 + [s * 0.2, -1.8, -0.3], (0, -1, 0), (1, 0, 0), 0.6, 0.3, 0.3, "beard")]
    # the tricorn: wide brim turned up at the sides and back, crown, gold trim, skull, plume
    ty = hy + 2.2
    p += [m.box("HatBrim", (0, ty, 0), (6.4, 0.4, 5.6), "hat"),
          m.box("HatCrown", (0, ty + 1.3, 0.2), (4.2, 2.4, 3.8), "hat"),
          m.box("HatBand", (0, ty + 0.5, 0.2), (4.3, 0.5, 3.9), "gold"),
          m.box("HatFront", (0, ty + 1.3, -2.6), (5.0, 2.0, 0.4), "hat"),
          m.box("HatFrontTrim", (0, ty + 2.35, -2.6), (5.2, 0.3, 0.5), "gold"),
          m.box("HatSkull", (0, ty + 1.5, -2.85), (1.4, 1.2, 0.1), "white"),
          m.box("HatSkullJaw", (0, ty + 0.8, -2.85), (0.9, 0.4, 0.1), "white"),
          m.box("HatSkullEyeL", (-0.33, ty + 1.55, -2.92), (0.4, 0.4, 0.05), "hat"),
          m.box("HatSkullEyeR", (0.33, ty + 1.55, -2.92), (0.4, 0.4, 0.05), "hat"),
          m.box("HatBoneA", (0, ty + 0.75, -2.88), (2.6, 0.3, 0.06), "white", m_rot("z", 25)),
          m.box("HatBoneB", (0, ty + 0.75, -2.88), (2.6, 0.3, 0.06), "white", m_rot("z", -25)),
          m.box("HatBack", (0, ty + 1.2, 2.7), (5.0, 1.8, 0.4), "hat")]
    for s in (-1, 1):
        n = "LR"[s > 0]
        p += [m.box(f"HatSide{n}", (s * 3.0, ty + 1.2, 0), (0.4, 1.8, 5.0), "hat"),
              m.box(f"HatSideTrim{n}", (s * 3.0, ty + 2.15, 0), (0.5, 0.3, 5.1), "gold")]
    # the plume: a red feather sweeping back off the left of the crown, a pyramid tip
    pb = np.array([-1.6, ty + 2.4, 0.6])
    p += [m.seg("Plume1", pb, pb + [-0.6, 1.8, 1.4], 0.9, 0.5, "plume"),
          m.seg("Plume2", pb + [-0.6, 1.8, 1.4], pb + [-1.0, 2.3, 3.4], 0.8, 0.45, "plume"),
          m.pyr("PlumeTip", pb + [-1.0, 2.3, 3.4], (-0.15, -0.3, 1), (1, 0, 0), 1.2, 0.4, 0.22, "plume")]
    # his parrot on the right shoulder: green with blue wings, a hooked beak, plate eyes
    pp = np.array([3.4, yh + 8.9, 0.4])
    p += [m.box("ParrotBody", pp, (1.4, 1.9, 1.5), "parrot"),
          m.box("ParrotHead", pp + [0, 1.3, -0.3], (1.2, 1.1, 1.2), "parrot"),
          m.pyr("ParrotBeak", pp + [0, 1.2, -0.95], (0, -0.6, -1), (1, 0, 0), 0.6, 0.3, 0.25, "beak"),
          m.box("ParrotWingL", pp + [-0.75, -0.1, 0.2], (0.2, 1.4, 1.2), "parrotwing"),
          m.box("ParrotWingR", pp + [0.75, -0.1, 0.2], (0.2, 1.4, 1.2), "parrotwing"),
          m.seg("ParrotTail", pp + [0, -0.8, 0.6], pp + [0, -2.0, 1.6], 0.6, 0.25, "parrotwing", up=(0, 0, 1))]
    for s in (-1, 1):
        p += m.eye(f"ParrotEye{'LR'[s > 0]}", pp + [s * 0.63, 1.45, -0.35], s, size=0.55)
    m.put(body, p)

    # arms: big coat sleeves with gold cuffs; a hook on the left, a gold cutlass in the right
    for s in (-1, 1):
        n = "LR"[s > 0]
        sh = np.array([s * 4.1, yh + 6.8, 0])
        arm = m.group(f"Arm{n}", tuple(sh), body)
        el = sh + np.array([s * 0.6, -2.6, -0.4])
        wr = el + np.array([0, -1.6, -1.6])
        q = [m.box(f"Shoulder{n}", sh, (2.0, 2.0, 2.0), "coat"),
             m.seg(f"UpperArm{n}", sh, el, 1.8, 1.8, "coat"),
             m.seg(f"Forearm{n}", el, wr, 1.7, 1.7, "coat"),
             m.box(f"Cuff{n}", wr, (2.1, 0.8, 2.1), "gold", None)]
        if s < 0:
            # the hook: an iron cup, then a curved hook of three blocks ending in a point
            h0 = wr + [0, -0.7, -0.3]
            q += [m.box("HookCup", h0, (1.2, 0.9, 1.2), "iron"),
                  m.seg("Hook1", h0, h0 + [0, -1.1, -0.4], 0.4, 0.4, "iron"),
                  m.seg("Hook2", h0 + [0, -1.1, -0.4], h0 + [0, -1.6, -1.4], 0.4, 0.4, "iron"),
                  m.seg("Hook3", h0 + [0, -1.6, -1.4], h0 + [0, -1.0, -2.1], 0.38, 0.38, "iron"),
                  m.pyr("HookTip", h0 + [0, -1.0, -2.1], (0, 1, 0.3), (1, 0, 0), 0.7, 0.2, 0.2, "iron")]
        else:
            # a fist gripping a gold-hilted cutlass held forward and up, the blade curving
            hd = wr + [0, -0.8, -0.3]
            q += [m.box("Fist", hd, (1.4, 1.4, 1.4), "skin"),
                  m.box("Guard", hd + [0, 0, -0.9], (0.5, 1.8, 0.4), "gold"),
                  m.box("Pommel", hd + [0, 0, 0.9], (0.6, 0.6, 0.6), "gold")]
            b0 = hd + np.array([0, 0.2, -1.1])
            pts = [b0, b0 + [0, 0.6, -2.4], b0 + [0, 1.6, -4.6], b0 + [0, 3.0, -6.2]]
            for k, (a, b) in enumerate(zip(pts, pts[1:])):
                q.append(m.seg(f"Blade{k + 1}", a, b, 0.3, 1.0 - 0.12 * k, "blade", up=(0, 1, 0)))
            q.append(m.pyr("BladeTip", pts[-1], pts[-1] - pts[-2], (0, 1, 0), 1.2, 0.35, 0.15, "blade"))
        m.put(arm, q)

    # legs: a black boot on the left, a wooden peg on the right
    for s in (-1, 1):
        n = "LR"[s > 0]
        hip = np.array([s * 1.6, yh, 0])
        leg = m.group(f"Leg{n}", tuple(hip), root)
        q = [m.box(f"Thigh{n}", hip + [0, -1.0, 0], (2.2, 2.2, 2.4), "pants")]
        if s < 0:
            q += [m.box("Boot", (hip[0], 1.5, 0), (2.2, 2.4, 2.4), "boot"),
                  m.box("BootTop", (hip[0], 2.9, 0), (2.5, 0.7, 2.7), "boot"),
                  m.box("BootToe", (hip[0], 0.5, -1.4), (2.2, 1.0, 1.6), "boot"),
                  m.box("BootBuckle", (hip[0], 1.4, -1.25), (0.8, 0.6, 0.1), "gold")]
        else:
            q += [m.box("PegCap", (hip[0], 2.9, 0), (2.0, 0.8, 2.0), "pegdark"),
                  m.seg("Peg", (hip[0], 2.6, 0), (hip[0], 0.6, 0), 1.0, 1.0, "peg"),
                  m.box("PegRing", (hip[0], 1.6, 0), (1.2, 0.3, 1.2), "gold"),
                  m.box("PegFoot", (hip[0], 0.3, 0), (0.8, 0.6, 0.8), "pegdark")]
        m.put(leg, q)

    # coat tails behind, flapping
    coat = m.group("Coat", (0, yh + 1.6, 2.4), root)
    m.put(coat, [m.box("CoatTailL", (-1.6, yh - 0.2, 2.75), (2.6, 3.6, 0.5), "coat"),
                 m.box("CoatTailR", (1.6, yh - 0.2, 2.75), (2.6, 3.6, 0.5), "coat"),
                 m.box("CoatHem", (0, yh - 1.9, 2.75), (5.6, 0.4, 0.6), "gold")])
    return m


def m_rot(axis, deg):
    from pirate_lib import R
    return R(axis, deg)


def animations():
    L = 2.4
    idle = {"body": [track(L, lambda u: (0, 4 * math.sin(TAU * u), 0), 16),
                     track(L, lambda u: (0, 0.2 * math.sin(TAU * u * 2), 0), 16, "position")],
            "ArmR": [track(L, lambda u: (-6 + 6 * math.sin(TAU * u), 0, 0), 16)],
            "ArmL": [track(L, lambda u: (4 * math.sin(TAU * u + 1), 0, 0), 16)],
            "Coat": [track(L, lambda u: (3 * math.sin(TAU * u), 0, 0), 16)]}

    def stride(L, amp, arm, lean, bob, raise_=0.0, n=16):
        return {"LegL": [track(L, lambda u: (amp * math.sin(TAU * u), 0, 0), n)],
                "LegR": [track(L, lambda u: (-amp * math.sin(TAU * u), 0, 0), n)],
                "ArmL": [track(L, lambda u: (-arm * math.sin(TAU * u), 0, 0), n)],
                "ArmR": [track(L, lambda u: (-raise_ + arm * 0.5 * math.sin(TAU * u), 0, 0), n)],
                "body": [track(L, lambda u: (lean, 0, 6 * math.sin(TAU * u)), n)],
                "root": [track(L, lambda u: (0, bob * abs(math.sin(TAU * u)), 0), n, "position")],
                "Coat": [track(L, lambda u: (10 + 8 * abs(math.sin(TAU * u)), 0, 0), n)]}

    return {"idle": (L, idle), "walk": (1.0, stride(1.0, 26, 20, 4, 0.5)),
            "gallop": (0.55, stride(0.55, 40, 30, 14, 1.2, raise_=50))}


if __name__ == "__main__":
    build().save(animations())
