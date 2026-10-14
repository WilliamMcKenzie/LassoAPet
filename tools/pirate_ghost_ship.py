"""Ghost Ship: World 3 Pirate Cove's giga rare (Oct 14; about 1 in 1000). QM (Oct 14): "use the actual
ship mesh as a base", so it is the Pirate Cove's pirate ship prop (tools/pirate_meshes.py ship(),
the big ship in the lagoon) at 0.6x, every convex piece a low-poly mesh, recoloured haunted: a
purple hull with a gold stripe, glowing ghost-cyan sails, a black Jolly Roger. It's alive: big
white googly plate eyes on the bow under angry brows, a wide red mouth of pyramid teeth along
the bow, and a lower jaw that chomps. It sails over the sand on glowing ghost mist with a wake
trailing behind. You ride on the deck behind the mainmast.

Run: python3 tools/pirate_ghost_ship.py [--gif]
Convert: python3 tools/bbmodel_to_luau.py --zyx --meshes assets/meshes/GhostShip designs/world3/pirate/GhostShip.bbmodel src/shared/Animals/GhostShipModel.luau

Bones: root (hull, deck, masts) -> Jaw (under the bow), SailF, SailM (each mast's sails
billow), Flag (waves), Wake (the ghost trail sways).

  idle    bobbing on the mist, rolling gently, sails breathing, flag waving, jaw chomping
  walk    pitching and rolling, sails full, wake swaying
  gallop  pitching hard into the chase, sails straining, jaw snapping
"""

import math

import numpy as np

from pirate_lib import Model, track, TAU, R
import pirate_meshes as PM

NAME = "GhostShip"
C = {"hull": (124, 66, 170), "hulldark": (78, 38, 114), "deck": (176, 118, 72), "rail": (78, 38, 114),
     "mast": (120, 78, 46), "sail": (110, 255, 226), "mist": (160, 236, 255), "flag": (30, 28, 36),
     "mouth": (196, 30, 70)}
# the prop's pieces -> this ship's colours (and which bone they ride on)
COLOURS = {"Hull": "hull", "Stripe": "gold", "Deck": "deck", "Rails": "rail", "Ports": "flag",
           "Masts": "mast", "Sails": "sail", "Flag": "flag", "Crossbones": "white"}
K = 0.6    # the prop's size -> the pet's
LIFT = 1.4  # the keel floats this high over the mist
MAIN_Z, FORE_Z = -2.0, -12.5  # the prop's mast positions


def at(p):
    """A point on the prop -> on the ship."""
    p = np.asarray(p, float)
    return p * K + np.array([0, LIFT, 0])


def side(z, y):
    """The hull's outer side at the prop's (z, y): its x and outward normal (for the right side)."""
    x = PM.width_at(z, y)
    dxdy = (PM.width_at(z, y + 0.1) - x) / 0.1
    dxdz = (PM.width_at(z + 0.1, y) - x) / 0.1
    n = np.array([1.0, -dxdy, -dxdz])
    return x, n / np.linalg.norm(n)


def plate_rot(n):
    """A rotation turning a plate's +x face to point along n (y kept up)."""
    x = n / np.linalg.norm(n)
    z = np.cross(x, [0, 1.0, 0])
    z /= np.linalg.norm(z)
    y = np.cross(z, x)
    return np.stack([x, y, z], 1)


def build():
    m = Model(NAME, C)
    root = m.group("root", tuple(at((0, 5.0, 0))))
    pieces = PM.ship(np.random.default_rng(4))  # the same seed as the prop
    sail_f = m.group("SailF", tuple(at((0, 22.0, FORE_Z))), root)
    sail_m = m.group("SailM", tuple(at((0, 31.0, MAIN_Z))), root)
    flag = m.group("Flag", tuple(at((0, 34.5, -1.6))), root)
    for label, _, sets in pieces:
        col = COLOURS[label]
        for i, pts in enumerate(sets):
            pts = at(pts)
            name = ("Glow_" if label == "Sails" else "") + f"{label}{i + 1}"
            node = root
            if label == "Sails" and len(sets[i]) > 6:  # the four square sails (the jib stays put)
                node = sail_m if abs(np.mean(sets[i][:, 2]) - MAIN_Z) < 2 else sail_f
            elif label in ("Flag", "Crossbones"):
                node = flag
            m.put(node, [m.hull(name, pts, col)])

    # the face on the bow: big googly plate eyes under angry brows
    face = []
    for s in (-1, 1):
        n = "LR"[s > 0]
        z, y = -15.0, 5.7
        x, nrm = side(z, y)
        nrm = nrm * np.array([s, 1, 1])
        c = at((s * x, y, z))
        Rm = plate_rot(nrm)
        size = 2.9
        face += [m.box(f"Eye{n}", c + nrm * 0.18, (0.12, size, size), "white", Rm),
                 m.box(f"EyePupil{n}", c + nrm * 0.26 + Rm @ np.array([0, -0.15, -0.35]) * size, (0.06, size * 0.5, size * 0.5), "pupil", Rm),
                 m.box(f"Brow{n}", c + nrm * 0.3 + Rm @ np.array([0, 0.6 * size, 0]), (0.4, 0.5, size * 1.2), "hulldark",
                       Rm @ R("x", -s * 18))]
        # the mouth: a red slot along the bow's side at the waterline, teeth hanging into it
        zm = np.linspace(-16.5, -9.5, 4)
        for j, zz in enumerate(zm):
            xm, nm_ = side(zz, 2.9)
            nm_ = nm_ * np.array([s, 1, 1])
            cm = at((s * xm, 2.9, zz))
            face.append(m.box(f"Mouth{n}{j + 1}", cm + nm_ * 0.03, (0.1, 1.2, 7.0 * K / 3 + 0.4), "mouth", plate_rot(nm_)))
            face.append(m.pyr(f"Fang{n}{j + 1}", cm + nm_ * 0.1 + np.array([0, 0.45, 0]), (0, -1, 0), (0, 0, 1), 0.6, 0.3, 0.12, "white"))
    m.put(root, face)

    # the jaw: a dark lower bow under the forefoot, teeth pointing up, hinged at its back
    jaw = m.group("Jaw", tuple(at((0, 2.0, -9.0))), root)
    jl = [at((s * PM.width_at(z, 2.6) * 0.95, y, z)) for z in (-19.5, -15.0, -9.5) for s in (-1, 1) for y in (0.6, 2.6)]
    j = [m.hull("JawHull", jl, "hulldark")]
    for s in (-1, 1):
        for jj, z in enumerate((-17.0, -14.0, -11.0)):
            x = PM.width_at(z, 2.6) * 0.75
            j.append(m.pyr(f"Tusk{'LR'[s > 0]}{jj + 1}", at((s * x, 2.6, z)), (0, 1, 0), (0, 0, 1), 0.6, 0.25, 0.2, "white"))
    m.put(jaw, j)

    # ghost mist under the keel, and the wake trailing behind
    mist = []
    for k, (x, z, w) in enumerate(((0, -9, 3.0), (-1.4, -4, 3.4), (1.4, 0, 3.4), (-1.0, 4.5, 3.2), (1.0, 8.5, 3.0))):
        mist.append(m.box(f"Glow_Mist{k + 1}", (x, 0.6 + 0.15 * (k % 2), z), (w, 1.0, w), "mist"))
    m.put(root, mist)
    wake = m.group("Wake", (0, 1.5, 10.5), root)
    m.put(wake, [m.box(f"Glow_Wake{k + 1}", (0.6 * math.sin(k * 1.3), 1.0 + 0.35 * k, 11.5 + 2.2 * k),
                       (3.0 - 0.5 * k, 1.1 - 0.12 * k, 2.2), "mist") for k in range(3)])
    return m


def animations():
    def anim(L, bob, roll, pitch, billow, flap, chomp, lean=0.0, n=16):
        return {"root": [track(L, lambda u: (lean + pitch * math.sin(TAU * u), 0, roll * math.sin(TAU * u + 0.8)), n),
                         track(L, lambda u: (0, bob * math.sin(TAU * u), 0), n, "position")],
                "SailF": [track(L, lambda u: (-billow * (1 + math.sin(TAU * u)) / 2, 0, 0), n)],
                "SailM": [track(L, lambda u: (-billow * (1 + math.sin(TAU * u - 0.6)) / 2, 0, 0), n)],
                "Flag": [track(L, lambda u: (0, flap * math.sin(TAU * u * 2), 0), n)],
                "Jaw": [track(L, lambda u: (chomp * max(0.0, math.sin(TAU * u * 2)) ** 2, 0, 0), n)],
                "Wake": [track(L, lambda u: (0, 8 * math.sin(TAU * u), 0), n)]}

    return {"idle": (3.0, anim(3.0, 0.4, 2, 1, 3, 14, 6)),
            "walk": (1.6, anim(1.6, 0.5, 3, 2.5, 6, 20, 8)),
            "gallop": (0.8, anim(0.8, 0.7, 4, 4, 9, 28, 14, lean=-3))}


if __name__ == "__main__":
    build().save(animations())
