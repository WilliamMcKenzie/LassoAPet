"""Ghost Ship: World 3 Pirate Cove's giga rare (Oct 14; about 1 in 1000). A haunted pirate ship that
is alive and sails over the sand on a glowing ghostly mist. A purple hull of planks with gold
rails and trim, three masts of glowing cyan ghost sails (tattered pyramid hems, a white skull on
the mainsail), a crow's nest, a black Jolly Roger, rigging, ghost lanterns, a raised stern castle
with glowing windows and a ship's wheel, three cannons a side, and a face on the bow: big glowing
green eyes under angry brows and a mouth along the waterline full of pyramid teeth (the lower
bow is a jaw that chomps). A skull figurehead and bowsprit up front, a ghost wake trailing behind.
You ride on the deck between the fore and main masts.

Run: python3 tools/pirate_ghost_ship.py [--gif]

Bones: root (hull, deck, masts) -> Jaw (lower bow), SailF, SailM, SailB (the sails on each
mast billow), Flag (waves), Wake (the ghost trail sways).

  idle    bobbing on the mist, rolling gently, sails breathing, flag waving, jaw chomping
  walk    pitching and rolling, sails full, wake swaying
  gallop  pitching hard into the chase, sails straining, jaw snapping
"""

import math

import numpy as np

from pirate_lib import Model, track, TAU

NAME = "GhostShip"
C = {"hull": (124, 66, 170), "hulldark": (78, 38, 114), "deck": (176, 118, 72), "deckdark": (130, 82, 48),
     "mast": (120, 78, 46), "sail": (110, 255, 226), "saildark": (60, 200, 190), "eye": (150, 255, 110),
     "mist": (160, 236, 255), "lamp": (255, 214, 80), "rope": (60, 44, 40), "iron": (52, 52, 64),
     "flag": (30, 28, 36), "mouth": (150, 20, 60)}

Y_BOT = 2.0   # bottom of the keel (the mist hangs below)
Y_DECK = 8.0
# hull sections, bow to stern: (z from, z to, half width at the rail)
SECTIONS = [(-12.0, -8.5, 2.4), (-8.5, -5.0, 3.6), (-5.0, 8.0, 4.2), (8.0, 12.0, 3.9)]


def build():
    m = Model(NAME, C)
    root = m.group("root", (0, 5.0, 0))
    p = []
    # ---------------------------------------------------------------- hull
    for k, (z0, z1, hw) in enumerate(SECTIONS):
        zc, L = (z0 + z1) / 2, z1 - z0
        lower_top = 4.4
        if k > 1:  # the bow's lower part (first two sections) is the jaw
            p.append(m.box(f"Keel{k + 1}", (0, (Y_BOT + lower_top) / 2, zc), (2 * hw - 2.0, lower_top - Y_BOT, L), "hulldark"))
        p.append(m.box(f"Hull{k + 1}", (0, (lower_top + Y_DECK) / 2, zc), (2 * hw, Y_DECK - lower_top, L), "hull"))
        p.append(m.box(f"Deck{k + 1}", (0, Y_DECK + 0.1, zc), (2 * hw - 0.6, 0.2, L - 0.1), "deck"))
        for s in (-1, 1):
            n = "LR"[s > 0]
            # plank lines along the side and a gold rail on top
            for j, y in enumerate((5.4, 6.7)):
                p.append(m.box(f"Plank{n}{k + 1}{j + 1}", (s * (hw + 0.03), y, zc), (0.1, 0.16, L), "hulldark"))
            p.append(m.box(f"Rail{n}{k + 1}", (s * (hw - 0.2), Y_DECK + 1.0, zc), (0.4, 0.3, L), "gold"))
            for j, z in enumerate(np.arange(z0 + 0.6, z1, 1.6)):
                p.append(m.box(f"Post{n}{k + 1}{j + 1}", (s * (hw - 0.2), Y_DECK + 0.5, z), (0.3, 0.8, 0.3), "golddark"))
    # gold band along the waterline, a bow point, the bowsprit and the skull figurehead
    for s in (-1, 1):
        n = "LR"[s > 0]
        p.append(m.box(f"Band{n}", (s * 4.23, 4.5, 1.5), (0.1, 0.35, 13.0), "gold"))
    p += [m.pyr("Prow", (0, 6.2, -12.0), (0, 0.2, -1), (1, 0, 0), 2.8, 2.4, 1.8, "hull"),
          m.seg("Bowsprit", (0, Y_DECK + 0.4, -11.5), (0, Y_DECK + 3.4, -17.5), 0.7, 0.7, "mast"),
          m.box("Skull", (0, 7.0, -14.0), (1.8, 1.6, 1.6), "white"),
          m.box("SkullJaw", (0, 5.95, -13.9), (1.2, 0.6, 1.2), "white"),
          m.box("SkullEyeL", (-0.45, 7.1, -14.82), (0.5, 0.5, 0.05), "flag"),
          m.box("SkullEyeR", (0.45, 7.1, -14.82), (0.5, 0.5, 0.05), "flag"),
          m.box("SkullNose", (0, 6.6, -14.82), (0.25, 0.3, 0.05), "flag")]

    # the face on the bow: glowing eyes under angry plank brows, a mouth full of teeth
    for s in (-1, 1):
        n = "LR"[s > 0]
        ez = -6.8
        p += [m.box(f"EyeRim{n}", (s * 3.62, 6.3, ez), (0.12, 3.4, 3.4), "hulldark"),
              m.box(f"Eye{n}", (s * 3.7, 6.3, ez), (0.12, 3.0, 3.0), "white"),
              m.box(f"EyePupil{n}", (s * 3.78, 6.1, ez - 0.5), (0.06, 1.5, 1.5), "pupil"),
              m.box(f"Brow{n}", (s * 3.85, 8.1, ez), (0.5, 0.6, 3.6), "hulldark",
                    np.array(m_rot("x", -s * 0 + 14 * 1))),
]
        for j, z in enumerate(np.linspace(-10.2, -5.0, 5)):
            hwz = 2.4 if z < -8.5 else 3.6
            p.append(m.pyr(f"Fang{n}{j + 1}", (s * (hwz - 0.4), 4.4, z), (0, -1, 0), (0, 0, 1), 0.75, 0.35, 0.25, "white"))
    for j, x in enumerate((-0.9, 0.9)):
        p.append(m.pyr(f"FangF{j + 1}", (x, 4.4, -11.6), (0, -1, 0), (1, 0, 0), 0.75, 0.35, 0.25, "white"))

    # cannons: three a side, black barrels through gold-rimmed ports
    for s in (-1, 1):
        n = "LR"[s > 0]
        for j, z in enumerate((-2.5, 1.5, 5.5)):
            p += [m.box(f"Port{n}{j + 1}", (s * 4.25, 6.05, z), (0.1, 1.3, 1.3), "gold"),
                  m.box(f"PortHole{n}{j + 1}", (s * 4.3, 6.05, z), (0.06, 0.9, 0.9), "flag"),
                  m.seg(f"Cannon{n}{j + 1}", (s * 3.9, 6.05, z), (s * 5.4, 6.05, z), 0.7, 0.7, "iron"),
                  m.box(f"Muzzle{n}{j + 1}", (s * 5.4, 6.05, z), (0.3, 0.9, 0.9), "iron")]

    # ---------------------------------------------------------------- stern castle
    p += [m.box("Castle", (0, Y_DECK + 1.3, 10.0), (7.4, 2.6, 4.0), "hull"),
          m.box("CastleDeck", (0, Y_DECK + 2.7, 10.0), (7.0, 0.2, 3.8), "deck"),
          m.box("CastleTrim", (0, Y_DECK + 2.55, 10.0), (7.6, 0.3, 4.2), "gold"),
          m.box("Stern", (0, 6.2, 12.05), (7.6, 3.6, 0.2), "hulldark")]
    for j, x in enumerate((-2.4, 0, 2.4)):
        p += [m.box(f"Glow_Window{j + 1}", (x, 6.6, 12.18), (1.3, 1.6, 0.1), "lamp"),
              m.box(f"WindowFrame{j + 1}", (x, 6.6, 12.13), (1.6, 1.9, 0.08), "gold")]
    for s in (-1, 1):
        n = "LR"[s > 0]
        p += [m.box(f"CastleRail{n}", (s * 3.4, Y_DECK + 3.4, 10.0), (0.35, 0.3, 4.0), "gold"),
              m.box(f"CastlePostF{n}", (s * 3.4, Y_DECK + 3.0, 8.2), (0.35, 0.9, 0.35), "golddark"),
              m.box(f"CastlePostB{n}", (s * 3.4, Y_DECK + 3.0, 11.8), (0.35, 0.9, 0.35), "golddark"),
              # a ghost lantern on a post at each back corner
              m.seg(f"LampPost{n}", (s * 3.4, Y_DECK + 3.4, 11.8), (s * 3.4, Y_DECK + 5.2, 11.8), 0.3, 0.3, "iron"),
              m.box(f"Glow_Lamp{n}", (s * 3.4, Y_DECK + 5.6, 11.8), (0.8, 1.0, 0.8), "lamp"),
              m.box(f"LampCap{n}", (s * 3.4, Y_DECK + 6.2, 11.8), (1.0, 0.25, 1.0), "iron")]
    # the ship's wheel on the castle deck: a hub, a rim of four bars and eight spoke handles
    wc = np.array([0, Y_DECK + 4.4, 8.6])
    p += [m.box("WheelPost", (0, Y_DECK + 3.4, 8.8), (0.5, 1.4, 0.5), "deckdark"),
          m.box("WheelHub", wc, (0.6, 0.6, 0.5), "gold")]
    for j in range(4):
        a = j * math.pi / 2
        c = wc + np.array([math.cos(a) * 1.1, math.sin(a) * 1.1, 0])
        p.append(m.box(f"WheelRim{j + 1}", c, (0.3 if j % 2 == 0 else 1.6, 1.6 if j % 2 == 0 else 0.3, 0.25), "deck"))
    # forecastle: a raised step at the bow with a bell
    p += [m.box("Forecastle", (0, Y_DECK + 0.6, -9.6), (5.6, 1.2, 4.6), "hull"),
          m.box("ForeDeck", (0, Y_DECK + 1.25, -9.6), (5.2, 0.15, 4.2), "deck"),
          m.box("BellPost", (0, Y_DECK + 2.3, -8.0), (0.3, 2.0, 0.3), "mast"),
          m.box("Bell", (0, Y_DECK + 2.9, -8.4), (0.8, 0.9, 0.8), "gold")]
    # barrels and a cannonball pile on deck
    for j, (x, z) in enumerate(((-2.9, 4.6), (-2.9, 6.0), (2.9, 5.4))):
        p += [m.box(f"Barrel{j + 1}", (x, Y_DECK + 0.8, z), (1.1, 1.4, 1.1), "deck"),
              m.box(f"BarrelHoop{j + 1}", (x, Y_DECK + 0.8, z), (1.2, 0.2, 1.2), "iron")]
    for j, (x, y, z) in enumerate(((2.6, 0.35, 2.6), (3.2, 0.35, 2.6), (2.9, 0.35, 3.2), (2.9, 0.85, 2.8))):
        p.append(m.box(f"Ball{j + 1}", (x, Y_DECK + y, z), (0.55, 0.55, 0.55), "iron"))

    # ---------------------------------------------------------------- masts, rigging
    masts = {"F": (-5.5, 13.0), "M": (0.0, 17.5), "B": (6.0, 12.0)}  # z, height above the deck
    for nm, (z, h) in masts.items():
        top = Y_DECK + h
        p += [m.seg(f"Mast{nm}", (0, Y_DECK, z), (0, top, z), 0.8, 0.8, "mast"),
              m.box(f"MastCap{nm}", (0, top + 0.2, z), (1.0, 0.4, 1.0), "gold")]
    # the crow's nest on the main mast
    cy = Y_DECK + 13.0
    p.append(m.box("NestFloor", (0, cy, 0), (2.6, 0.3, 2.6), "deckdark"))
    for s in (-1, 1):
        p += [m.box(f"NestX{'LR'[s > 0]}", (s * 1.2, cy + 0.6, 0), (0.25, 1.0, 2.6), "deck"),
              m.box(f"NestZ{'FB'[s > 0]}", (0, cy + 0.6, s * 1.2), (2.6, 1.0, 0.25), "deck")]
    p.append(m.box("NestRim", (0, cy + 1.15, 0), (2.8, 0.2, 2.8), "gold"))
    m.put(root, p)

    # sails: hung from yards on each mast, glowing ghost-cyan, billowing forward, tattered hems
    sails = {"F": [(-5.5, 11.5, 6.0, 4.4), (-5.5, 6.6, 7.0, 4.0)],
             "M": [(0.0, 16.4, 6.4, 4.0), (0.0, 11.2, 8.4, 5.6)],
             "B": [(6.0, 10.6, 6.0, 5.0)]}
    for nm, rows in sails.items():
        z = rows[0][0]
        bone = m.group(f"Sail{nm}", (0, Y_DECK + rows[0][1] + 0.4, z), root)
        q = []
        for r, (zz, ytop, w, hgt) in enumerate(rows):
            yt = Y_DECK + ytop
            q.append(m.box(f"Yard{nm}{r + 1}", (0, yt + 0.2, zz - 0.5), (w + 1.6, 0.45, 0.45), "mast"))
            # three vertical panels: the middle one bellies out forward
            pw = w / 3
            for c in range(3):
                x = (c - 1) * pw
                bulge = -0.55 if c == 1 else -0.25
                col = "sail" if c != 1 or r % 2 == 0 else "saildark"
                q.append(m.box(f"Glow_Sail{nm}{r + 1}{c + 1}", (x, yt - hgt / 2, zz - 0.6 + bulge), (pw, hgt, 0.4), col))
                # a tattered hem: one pyramid hanging from each panel's bottom
                q.append(m.pyr(f"Glow_Tatter{nm}{r + 1}{c + 1}", (x + (c - 1) * 0.3, yt - hgt, zz - 0.6 + bulge), (0, -1, 0),
                               (1, 0, 0), 0.9, pw * 0.35, 0.2, "saildark"))
            # ghost lanterns hanging from the lowest yard's ends
            if r == len(rows) - 1:
                for s in (-1, 1):
                    lx = s * (w / 2 + 0.6)
                    q += [m.box(f"Glow_Lantern{nm}{'LR'[s > 0]}", (lx, yt - 0.4, zz - 0.5), (0.7, 0.9, 0.7), "mist")]
        m.put(bone, q)
    # a white skull and crossbones on the lower mainsail's front
    sk = np.array([0, Y_DECK + 11.2 - 2.4, -0.6 - 0.55 - 0.23])
    skull = [m.box("SailSkull", sk + [0, 0.5, 0], (1.8, 1.6, 0.08), "white"),
             m.box("SailSkullJaw", sk + [0, -0.5, 0], (1.1, 0.6, 0.08), "white"),
             m.box("SailSkullEyeL", sk + [-0.45, 0.55, -0.05], (0.5, 0.5, 0.04), "flag"),
             m.box("SailSkullEyeR", sk + [0.45, 0.55, -0.05], (0.5, 0.5, 0.04), "flag"),
             m.box("SailBone1", sk + [0, -1.4, 0.02], (3.2, 0.4, 0.06), "white", m_rot("z", 30)),
             m.box("SailBone2", sk + [0, -1.4, 0.02], (3.2, 0.4, 0.06), "white", m_rot("z", -30))]
    m.put(m.nodes["SailM"], skull)

    # the Jolly Roger at the main mast's top
    ft = Y_DECK + 17.9
    flag = m.group("Flag", (0, ft, 0.0), root)
    m.put(flag, [m.seg("FlagPole", (0, ft - 0.2, 0), (0, ft + 2.2, 0), 0.25, 0.25, "mast"),
                 m.box("FlagCloth", (0, ft + 1.3, 1.6), (0.25, 1.8, 3.0), "flag"),
                 m.box("FlagSkullL", (-0.14, ft + 1.45, 1.6), (0.06, 0.8, 0.8), "white"),
                 m.box("FlagSkullR", (0.14, ft + 1.45, 1.6), (0.06, 0.8, 0.8), "white"),
                 m.box("FlagBonesL", (-0.14, ft + 0.75, 1.6), (0.06, 0.25, 1.4), "white"),
                 m.box("FlagBonesR", (0.14, ft + 0.75, 1.6), (0.06, 0.25, 1.4), "white")])

    # the jaw: the lower bow, with teeth pointing up
    jaw = m.group("Jaw", (0, 3.5, -5.0), root)
    j = [m.box("JawBow", (0, 2.7, -10.25), (4.4, 1.6, 3.5), "hulldark"),
         m.box("JawMid", (0, 2.7, -6.75), (6.8, 1.6, 3.5), "hulldark"),
         m.pyr("JawProw", (0, 2.7, -12.0), (0, 0, -1), (1, 0, 0), 1.6, 2.2, 0.9, "hulldark"),
         m.box("MouthBow", (0, 3.95, -10.25), (4.7, 0.9, 3.3), "mouth"),
         m.box("MouthMid", (0, 3.95, -6.75), (7.1, 0.9, 3.3), "mouth"),
         m.box("JawGold", (0, 2.0, -8.5), (4.2, 0.3, 6.8), "gold")]
    for s in (-1, 1):
        for jj, z in enumerate(np.linspace(-10.6, -5.4, 4)):
            hwz = 2.2 if z < -8.5 else 3.4
            j.append(m.pyr(f"Tusk{'LR'[s > 0]}{jj + 1}", (s * (hwz - 0.4), 3.5, z), (0, 1, 0), (0, 0, 1), 0.7, 0.3, 0.22, "white"))
    m.put(jaw, j)

    # ghost mist under the keel: glowing cyan puffs, and the wake trailing behind
    mist = []
    for k, (x, z, w) in enumerate(((0, -8, 3.0), (-1.6, -3, 3.4), (1.6, 1, 3.4), (-1.2, 5, 3.0), (1.2, 8.5, 3.0),
                                   (0, -1, 2.6), (0, 3.5, 2.6))):
        mist.append(m.box(f"Glow_Mist{k + 1}", (x, 1.0 + 0.15 * (k % 2), z), (w, 1.0, w), "mist"))
    m.put(root, mist)
    wake = m.group("Wake", (0, 2.0, 12.0), root)
    m.put(wake, [m.box(f"Glow_Wake{k + 1}", (0.6 * math.sin(k * 1.3), 1.5 + 0.35 * k, 13.2 + 2.2 * k),
                       (3.0 - 0.5 * k, 1.1 - 0.12 * k, 2.2), "mist") for k in range(3)])
    return m


def m_rot(axis, deg):
    from pirate_lib import R
    return R(axis, deg)


def animations():
    def anim(L, bob, roll, pitch, billow, flap, chomp, lean=0.0, n=16):
        return {"root": [track(L, lambda u: (lean + pitch * math.sin(TAU * u), 0, roll * math.sin(TAU * u + 0.8)), n),
                         track(L, lambda u: (0, bob * math.sin(TAU * u), 0), n, "position")],
                "SailF": [track(L, lambda u: (-billow * (1 + math.sin(TAU * u)) / 2, 0, 0), n)],
                "SailM": [track(L, lambda u: (-billow * (1 + math.sin(TAU * u - 0.6)) / 2, 0, 0), n)],
                "SailB": [track(L, lambda u: (-billow * (1 + math.sin(TAU * u - 1.2)) / 2, 0, 0), n)],
                "Flag": [track(L, lambda u: (0, flap * math.sin(TAU * u * 2), 0), n)],
                "Jaw": [track(L, lambda u: (chomp * max(0.0, math.sin(TAU * u * 2)) ** 2, 0, 0), n)],
                "Wake": [track(L, lambda u: (0, 8 * math.sin(TAU * u), 0), n)]}

    return {"idle": (3.0, anim(3.0, 0.4, 2, 1, 3, 14, 6)),
            "walk": (1.6, anim(1.6, 0.5, 3, 2.5, 6, 20, 8)),
            "gallop": (0.8, anim(0.8, 0.7, 4, 4, 9, 28, 14, lean=-3))}


if __name__ == "__main__":
    build().save(animations())
