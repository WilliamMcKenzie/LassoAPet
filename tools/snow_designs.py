"""Snow biome animals (first drafts, static models for QM to vet).

Run: python3 tools/snow_designs.py [out_dir]        the lineup + every model
     python3 tools/snow_designs.py one <name>        one close render + its model

  Snowman    Rare       three stacked snow blocks, coal eyes, carrot nose, stick arms
  Penguin    Uncommon   black back, white belly and face, orange beak and feet
  WhiteWolf  Rare       white wolf, grey saddle and tail tip, icy-blue eyes
  PolarBear  Epic       chunky white bear, black nose, dark claws
  Troll      Epic       blue, bulky, red eye + scarred white eye, tusks, white ponytail,
                        spiked wooden club (its own Bat bone)
  IceDragon  Legendary  cyan scale panels with white fur rings between, spread wings,
                        QM's sand-snake head recoloured cyan with red eyes

Same blocks as tools/animal_designs.py: flush, axis-aligned, every bone at 0 in
the rest pose; slopes only from wedges and pyramids. Every detail is a block
with depth: the only thin plates are the standard eyes (white plate, pupil set
PUPIL_BACK back from its front edge). Models go to designs/snow/<Name>.bbmodel.
Bones and animations come after QM vets the shapes.
"""

import json
import os
import shutil
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
from partlib import Part, look_at, part_faces, render, write_bbmodel  # noqa: E402
import animal_designs as A  # noqa: E402
from animal_designs import Animal, EYE_WHITE, PUPIL, PLATE, PUPIL_BACK  # noqa: E402
from horse_rig import pose  # noqa: E402
from snake_design import posed, solid_texture  # noqa: E402

ROOT = os.path.join(os.path.dirname(__file__), "..")
MODELS = os.path.join(ROOT, "designs", "snow")
SNAKE_HEAD = os.path.join(ROOT, "designs", "desert", "SnakeHead_QM.bbmodel")
OUT = "/mnt/project-files/animals/snow"
BB = 10  # Blockbench units per stud

SNOW = (246, 249, 255)
COAL = (40, 42, 52)
CARROT = (250, 132, 40)
STICK = (124, 82, 48)


def X(sx, a0, a1):
    """x extent mirrored to one side (sx = -1 left, +1 right), low to high."""
    return tuple(sorted((sx * a0, sx * a1)))


SIDES = (("L", -1), ("R", 1))


def pyramid(a, name, base_lo, base_hi, axis, length, color, bone):
    """Square pyramid standing on one face of a box footprint.
    base_lo/base_hi: the base rectangle (a box with zero size along `axis`);
    axis: '+x', '-x', '+y', '-y', '+z', '-z', the way the point sticks out."""
    lo, hi = np.array(base_lo, float), np.array(base_hi, float)
    k = "xyz".index(axis[1])
    s = 1 if axis[0] == "+" else -1
    c = (lo + hi) / 2
    apex = c.copy()
    apex[k] = lo[k] + s * length
    u, v = [i for i in range(3) if i != k]
    corners = []
    for du, dv in ((0, 0), (1, 0), (1, 1), (0, 1)):
        p = lo.copy()
        p[u] = hi[u] if du else lo[u]
        p[v] = hi[v] if dv else lo[v]
        corners.append(p)
    polys = [np.array(corners)] + [np.array([corners[i], corners[(i + 1) % 4], apex]) for i in range(4)]
    p = Part(name, (1, 1, 1), np.eye(4), color, "Poly")
    p.polys = polys
    p.bone = bone
    a.parts.append(p)
    return p


def front_eye(a, name_side, x0, x1, y0, y1, z, bone, pupil=PUPIL, pupil_frac=0.62, look=0.0):
    """A standard eye on a front (-z) face, as on the pig: white plate, pupil plate
    on it, the pupil set PUPIL_BACK in from the plate's bottom edge.
    pupil=None leaves a plain white eye."""
    a.box("Eye" + name_side, (x0, y0, z - PLATE), (x1, y1, z), EYE_WHITE, bone)
    if pupil is None:
        return
    w = (x1 - x0) * pupil_frac
    cx = (x0 + x1) / 2 + look
    a.box("Pupil" + name_side, (cx - w / 2, y0 + PUPIL_BACK, z - PLATE - 0.03), (cx + w / 2, y1 - (y1 - y0) * 0.22, z - PLATE),
          pupil, bone)


def side_eyes(a, x, y0, y1, z0, z1, pupil=PUPIL, bone="neck"):
    """animal_designs' eyes (side plates, pupils looking forward) with a pupil colour."""
    a.eyes(x, y0, y1, z0, z1, bone)
    for p in a.parts[-4:]:
        if p.name.startswith("Pupil"):
            p.color = pupil


def pointed_ears(a, cx, base, z0, z1, half, h, color, inner, bone_prefix="Ear"):
    """Pointed ears: two right-triangle prisms each, an inner prism 0.15 deep on the front."""
    for side, sx in SIDES:
        c = sx * cx
        bone = bone_prefix + side
        for half_name, dx in (("A", -1), ("B", 1)):
            a.tri(f"Ear{side}{half_name}", [(c, base), (c + dx * half, base), (c, base + h)], z0, z1, color, bone)
            a.tri(f"Ear{side}In{half_name}", [(c, base + 0.1), (c + dx * half * 0.55, base + 0.1), (c, base + h * 0.66)],
                  z0 - 0.15, z0, inner, bone)
        a.pivots[bone] = (c, base, z0)


# ---------------------------------------------------------------- snowman

def snowman():
    a = Animal("Snowman", "Rare")
    a.bone_order = [("root", None), ("Mid", "root"), ("neck", "Mid"), ("ArmL", "Mid"), ("ArmR", "Mid")]
    shade = (228, 238, 252)  # the middle block a touch bluer so the stack reads
    a.box("Bottom", (-2.5, 0, -2.3), (2.5, 4.2, 2.3), SNOW, "root")
    a.box("Middle", (-1.9, 4.2, -1.75), (1.9, 7.3, 1.75), shade, "Mid")
    a.box("Head", (-1.5, 7.3, -1.4), (1.5, 10.1, 1.4), SNOW, "neck")
    # coal eyes: lumps 0.3 deep, half sunk into the snow
    for side, sx in SIDES:
        x0, x1 = X(sx, 0.4, 0.95)
        a.box("Coal" + side, (x0, 8.75, -1.6), (x1, 9.3, -1.3), COAL, "neck")
    # carrot nose: a block and a pyramid tip, pointing forward
    a.box("Carrot", (-0.3, 7.95, -2.3), (0.3, 8.55, -1.35), CARROT, "neck")
    pyramid(a, "CarrotTip", (-0.3, 7.95, -2.3), (0.3, 8.55, -2.3), "-z", 0.9, CARROT, "neck")
    # two coal buttons on the middle
    for i, y in enumerate((5.0, 6.2)):
        a.box(f"Button{i + 1}", (-0.28, y, -1.95), (0.28, y + 0.55, -1.6), COAL, "Mid")
    # stick arms: out from the sides, a twig up at the end, a short twig on top
    for side, sx in SIDES:
        bone = "Arm" + side
        x0, x1 = X(sx, 1.9, 4.5)
        a.box("Stick" + side, (x0, 6.1, -0.2), (x1, 6.5, 0.2), STICK, bone)
        x0, x1 = X(sx, 4.1, 4.5)
        a.box("Twig" + side, (x0, 6.5, -0.2), (x1, 7.7, 0.2), STICK, bone)
        x0, x1 = X(sx, 3.0, 3.35)
        a.box("Twig2" + side, (x0, 6.5, -0.2), (x1, 7.1, 0.2), STICK, bone)
        a.pivots[bone] = (sx * 1.9, 6.3, 0)
    a.pivots.update(root=(0, 2.1, 0), Mid=(0, 4.2, 0), neck=(0, 7.3, 0))
    a.meta = {"seat": (0, 10.1, 0), "neck_loop": {"center": (0, 8.7, 0), "radius": 1.9}}
    return a


# ---------------------------------------------------------------- penguin

def penguin():
    a = Animal("Penguin", "Uncommon")
    black, white, orange = (44, 50, 66), (250, 250, 250), (255, 150, 30)
    a.bone_order = [("root", None), ("neck", "root"), ("WingL", "root"), ("WingR", "root"),
                    ("LegL", "root"), ("LegR", "root"), ("Tail", "root")]
    # feet: flat orange blocks poking out in front
    for side, sx in SIDES:
        x0, x1 = X(sx, 0.3, 1.5)
        a.box("Foot" + side, (x0, 0, -2.5), (x1, 0.6, 0.4), orange, "Leg" + side)
        a.pivots["Leg" + side] = (sx * 0.9, 0.6, -0.5)
    # body: black, a white belly block standing proud of the front
    a.box("Body", (-2.0, 0.6, -1.4), (2.0, 6.4, 1.8), black, "root")
    a.box("Belly", (-1.5, 0.9, -2.0), (1.5, 5.9, -1.4), white, "root")
    # head: black, white face block, orange beak
    a.box("Head", (-1.6, 6.4, -1.6), (1.6, 9.2, 1.3), black, "neck")
    a.box("Face", (-1.15, 6.6, -1.9), (1.15, 8.7, -1.6), white, "neck")
    a.box("Beak", (-0.45, 6.95, -2.8), (0.45, 7.45, -1.9), orange, "neck")
    for side, sx in SIDES:
        x0, x1 = X(sx, 0.3, 0.9)
        front_eye(a, side, x0, x1, 7.6, 8.35, -1.9, "neck")
    # flippers hang at the sides
    for side, sx in SIDES:
        x0, x1 = X(sx, 2.0, 2.4)
        a.box("Flipper" + side, (x0, 2.4, -0.7), (x1, 5.8, 0.9), black, "Wing" + side)
        a.pivots["Wing" + side] = (sx * 2.0, 5.8, 0.1)
    a.wedge("Tail", (-0.7, 0.6, 1.8), (0.7, 1.4, 2.7), black, "Tail", "down_back")
    a.pivots.update(root=(0, 3.5, 0.2), neck=(0, 6.4, -0.1), Tail=(0, 1.4, 1.8))
    a.meta = {"seat": (0, 9.2, -0.15), "neck_loop": {"center": (0, 7.6, -0.15), "radius": 1.9}}
    return a


# ---------------------------------------------------------------- white wolf

def white_wolf():
    a = Animal("WhiteWolf", "Rare")
    white, grey, paw, nose, ice = (242, 245, 250), (180, 192, 212), (204, 214, 228), (46, 52, 70), (40, 170, 240)
    a.bone_order = [("root", None), ("neck", "root"), ("EarL", "neck"), ("EarR", "neck"), ("Jaw", "neck"),
                    ("Tail", "root")] + [("Leg" + leg, "root") for leg in A.LEGS]
    a.body(1.8, 3.3, 6.8, -3.8, 3.6, white)
    a.legs(0.45, 1.8, 1.3, 0.7, white, paw)
    # grey saddle down the back, standing proud of it
    a.box("Saddle", (-1.1, 6.8, -2.4), (1.1, 7.2, 3.6), grey, "root")
    # thick neck out of the chest, head forward, long snout, black nose
    a.box("Neck", (-1.4, 4.9, -4.9), (1.4, 8.2, -3.799), white, "neck")
    a.box("Head", (-1.55, 7.2, -6.7), (1.55, 9.8, -4.1), white, "neck")
    a.box("Snout", (-0.9, 7.2, -8.7), (0.9, 8.5, -6.7), white, "neck")
    a.box("Jaw", (-0.8, 6.7, -8.3), (0.8, 7.2, -5.2), paw, "Jaw")
    a.box("Nose", (-0.45, 7.9, -8.95), (0.45, 8.65, -8.5), nose, "neck")
    side_eyes(a, 1.55, 8.3, 9.2, -6.5, -5.6, ice)
    pointed_ears(a, 0.85, 9.8, -5.1, -4.6, 0.5, 1.3, white, grey)
    # bushy tail: back and down in two steps, grey tip
    a.box("Tail", (-0.65, 5.4, 3.6), (0.65, 6.7, 5.1), white, "Tail")
    a.box("Tail2", (-0.7, 4.1, 4.9), (0.7, 6.1, 6.3), white, "Tail")
    a.wedge("TailTip", (-0.7, 3.1, 4.9), (0.7, 4.1, 6.3), grey, "Tail", "down_back")
    a.pivots.update(neck=(0, 6.8, -3.85), Jaw=(0, 6.95, -5.2), Tail=(0, 6.7, 3.6))
    a.meta = {"seat": (0, 7.2, 0.4), "neck_loop": {"center": (0, 7.0, -4.3), "radius": 1.7}}
    a.meta_scale = 1.1
    return a


# ---------------------------------------------------------------- polar bear

def polar_bear(armor=False):
    """Hunched brute after QM's figure: a chest pitched up into a big shoulder
    hump, the head thrust forward below it, heavy splayed forelegs with blue
    claws, small hind legs. Every block is axis-aligned inside its bone; the
    pose comes from the bones' rest rotations (a.rest).
    QM edited the result (dark eyes with a white glint): designs/snow/PolarBear.bbmodel
    is now QM's file and the source of truth, so don't overwrite it from here."""
    a = Animal("PolarBear", "Epic")
    fur, shade, belly = (250, 251, 248), (224, 232, 240), (236, 242, 248)
    nose, claw, pad = (34, 36, 48), (46, 150, 196), (96, 104, 124)
    a.bone_order = [("root", None), ("Chest", "root"), ("Hump", "Chest"), ("neck", "Chest"),
                    ("Tail", "root")] + [("Leg" + leg, "root") for leg in A.LEGS]
    a.rest = {}
    # hips (root): the low back end
    a.box("Hips", (-2.9, 5.4, 1.0), (2.9, 10.2, 8.4), fur, "root")
    a.box("HipsUnder", (-2.5, 4.8, 1.6), (2.5, 5.4, 7.6), shade, "root")
    a.pivots["root"] = (0, 7.8, 4.7)
    # chest: much bigger than the hips, pitched up so the back climbs to the hump
    a.box("Chest", (-3.7, 5.2, -6.2), (3.7, 12.6, 1.8), fur, "Chest")
    a.box("Belly", (-3.1, 4.6, -5.4), (3.1, 5.2, 1.0), belly, "Chest")
    a.box("Ruff", (-3.0, 5.4, -7.4), (3.0, 10.0, -6.2), belly, "Chest")  # the fur bib under the head
    a.pivots["Chest"] = (0, 8.0, 1.4)
    a.rest["Chest"] = (12, 0, 0)
    # hump: a slab over the shoulders, tipped back against the chest's pitch
    a.box("Hump", (-3.2, 12.6, -4.6), (3.2, 14.2, 1.0), fur, "Hump")
    a.box("HumpTop", (-2.4, 14.2, -3.6), (2.4, 14.8, 0.2), shade, "Hump")
    a.pivots["Hump"] = (0, 12.6, 1.0)
    a.rest["Hump"] = (-6, 0, 0)
    # head: low and thrust forward from the chest's front, nose dipped
    a.box("Head", (-2.3, 7.4, -10.4), (2.3, 11.4, -6.2), fur, "neck")
    a.box("Brow", (-2.3, 10.6, -10.8), (2.3, 11.4, -10.4), shade, "neck")
    a.box("Snout", (-1.4, 7.4, -12.8), (1.4, 9.8, -10.4), fur, "neck")
    a.box("Jaw", (-1.2, 6.8, -12.2), (1.2, 7.4, -8.0), shade, "neck")
    a.box("Nose", (-0.7, 9.0, -13.1), (0.7, 10.0, -12.6), nose, "neck")
    side_eyes(a, 2.3, 9.3, 10.4, -10.0, -9.0)
    for side, sx in SIDES:
        x0, x1 = X(sx, 1.0, 2.2)
        a.box("Ear" + side, (x0, 11.4, -7.8), (x1, 12.4, -6.8), fur, "neck")
        x0, x1 = X(sx, 2.3, 2.9)
        a.box("Cheek" + side, (x0, 7.4, -9.6), (x1, 9.6, -6.6), fur, "neck")  # jowl fur sticking out
    a.pivots["neck"] = (0, 8.6, -6.2)
    a.rest["neck"] = (-16, 0, 0)
    # forelegs: a big shoulder, a thick arm reaching forward, huge paws with blue claws
    for side, sx in SIDES:
        leg = "LegF" + side
        x0, x1 = X(sx, 2.4, 5.4)
        a.box("Shoulder" + side, (x0, 8.0, -5.8), (x1, 11.6, -1.2), fur, leg)
        x0, x1 = X(sx, 2.8, 5.0)
        a.box("Arm" + side, (x0, 3.4, -5.0), (x1, 8.0, -2.0), fur, leg)
        x0, x1 = X(sx, 2.5, 5.3)
        a.box("Wrist" + side, (x0, 1.3, -5.4), (x1, 3.4, -1.7), shade, leg)
        x0, x1 = X(sx, 2.1, 5.7)
        a.box("Paw" + side, (x0, 0, -6.6), (x1, 1.3, -1.5), fur, leg)
        for i, xc in enumerate((2.7, 3.9, 5.1)):
            x0, x1 = X(sx, xc - 0.35, xc + 0.35)
            pyramid(a, f"ClawF{side}{i}", (x0, 0.1, -6.6), (x1, 0.9, -6.6), "-z", 0.9, claw, leg)
        a.pivots[leg] = (sx * 3.9, 10.8, -1.6)
        a.rest[leg] = (8, 0, sx * 5)
        # hind legs: a round haunch over a short shin, set wide, feet turned out
        leg = "LegH" + side
        x0, x1 = X(sx, 1.0, 3.5)
        a.box("Haunch" + side, (x0, 4.0, 3.6), (x1, 8.6, 8.4), fur, leg)
        x0, x1 = X(sx, 1.3, 3.2)
        a.box("Shin" + side, (x0, 1.1, 4.6), (x1, 4.0, 7.6), shade, leg)
        x0, x1 = X(sx, 1.0, 3.5)
        a.box("Foot" + side, (x0, 0, 3.4), (x1, 1.1, 7.8), fur, leg)
        for i, xc in enumerate((1.5, 2.25, 3.0)):
            x0, x1 = X(sx, xc - 0.25, xc + 0.25)
            pyramid(a, f"ClawH{side}{i}", (x0, 0.1, 3.4), (x1, 0.7, 3.4), "-z", 0.6, claw, leg)
        a.pivots[leg] = (sx * 2.25, 8.0, 4.0)
        a.rest[leg] = (-6, sx * -8, 0)
    a.box("Tail", (-0.7, 8.4, 8.4), (0.7, 9.8, 9.2), fur, "Tail")
    a.pivots["Tail"] = (0, 9.8, 8.4)
    a.rest["Tail"] = (20, 0, 0)
    if armor:
        gold, steel, gem = (232, 180, 64), (150, 160, 176), (40, 150, 196)
        # one pauldron on the left shoulder, a strap across the chest
        a.box("PauldronL", (-5.8, 11.6, -6.2), (-2.2, 12.4, -0.8), gold, "LegFL")
        a.box("PauldronLSide", (-5.8, 9.0, -6.2), (-5.4, 11.6, -0.8), gold, "LegFL")
        a.box("PauldronLSteel", (-5.9, 9.6, -5.4), (-5.8, 11.2, -1.6), steel, "LegFL")
        a.box("GemL", (-6.3, 9.9, -4.2), (-5.9, 10.9, -2.8), gem, "LegFL")
        a.box("Strap", (-3.8, 6.0, -6.4), (3.8, 7.2, -5.2), steel, "Chest")
        a.box("StrapGem", (-0.7, 5.8, -6.8), (0.7, 7.4, -6.4), gem, "Chest")
    a.meta = {"seat": (0, 13.4, -1.0), "neck_loop": {"center": (0, 9.0, -8.4), "radius": 2.8}}
    a.meta_scale = 0.85  # about 1.2x the first draft (QM: large)
    return a


def polar_bear_armor():
    return polar_bear(armor=True)


# ---------------------------------------------------------------- troll

def troll():
    a = Animal("Troll", "Epic")
    skin, dark, hair, eye_red = (72, 148, 232), (48, 108, 196), (250, 250, 252), (232, 36, 44)
    shorts, belt, tusk, scar = (132, 86, 50), (92, 58, 36), (252, 246, 226), (246, 132, 178)
    wood, wood_dark, spike = (156, 100, 52), (116, 72, 38), (206, 212, 222)
    a.bone_order = [("root", None), ("neck", "root"), ("Jaw", "neck"), ("Ponytail", "neck"),
                    ("ArmL", "root"), ("ArmR", "root"), ("Bat", "ArmR"), ("LegL", "root"), ("LegR", "root")]
    # short thick legs with big dark feet
    for side, sx in SIDES:
        bone = "Leg" + side
        x0, x1 = X(sx, 0.45, 2.15)
        a.box("Leg" + side, (x0, 0.9, -0.9), (x1, 4.4, 0.9), skin, bone)
        a.box("Foot" + side, (x0, 0, -1.7), (x1, 0.9, 0.9), dark, bone)
        a.pivots[bone] = (sx * 1.3, 4.4, 0)
    # shorts with a belt, a round belly, a huge chest
    a.box("Shorts", (-2.5, 3.9, -1.3), (2.5, 5.6, 1.3), shorts, "root")
    a.box("Belt", (-2.6, 5.6, -1.4), (2.6, 6.1, 1.4), belt, "root")
    a.box("Belly", (-2.8, 6.1, -1.8), (2.8, 8.4, 1.5), skin, "root")
    a.box("Chest", (-3.5, 8.4, -2.0), (3.5, 11.5, 1.8), skin, "root")
    # head sits forward on the chest (a hunch, but straight)
    a.box("Head", (-2.0, 11.5, -2.4), (2.0, 15.2, 0.8), skin, "neck")
    a.box("Nose", (-0.45, 13.0, -2.9), (0.45, 13.8, -2.4), dark, "neck")
    # underbite: the lower jaw juts out past the face; two tusks stand up off it
    a.box("Jaw", (-2.1, 11.5, -2.85), (2.1, 12.6, 0.4), skin, "Jaw")
    for side, sx in SIDES:
        x0, x1 = X(sx, 1.15, 1.55)
        a.box("Tusk" + side, (x0, 12.6, -2.85), (x1, 12.95, -2.45), tusk, "Jaw")
        pyramid(a, "TuskTip" + side, (x0, 12.95, -2.85), (x1, 12.95, -2.45), "+y", 0.5, tusk, "Jaw")
    # eyes: his left is a white scarred eye, his right is red
    x0, x1 = X(-1, 0.55, 1.5)
    front_eye(a, "L", x0, x1, 13.75, 14.6, -2.4, "neck", pupil=None)
    x0, x1 = X(1, 0.55, 1.5)
    front_eye(a, "R", x0, x1, 13.75, 14.6, -2.4, "neck", pupil=eye_red, pupil_frac=0.6)
    # the scar: a pink block line running up and down through the skin over and
    # under the white eye, standing 0.12 off the face
    xs = -1.025
    a.box("Scar", (xs - 0.14, 14.6, -2.52), (xs + 0.14, 15.2, -2.4), scar, "neck")
    a.box("Scar2", (xs - 0.14, 13.0, -2.52), (xs + 0.14, 13.75, -2.4), scar, "neck")
    # white hair on top, tied back into a ponytail
    a.box("Hair", (-2.1, 15.2, -1.9), (2.1, 15.8, 1.0), hair, "neck")
    a.box("HairBack", (-2.1, 13.6, 0.8), (2.1, 15.8, 1.25), hair, "neck")
    a.box("Tie", (-0.5, 14.2, 1.25), (0.5, 15.0, 1.65), belt, "Ponytail")
    a.box("Ponytail", (-0.55, 11.6, 1.65), (0.55, 15.1, 2.35), hair, "Ponytail")
    # arms: huge shoulders, arms down; the right forearm comes forward to hold the club up
    for side, sx in SIDES:
        bone = "Arm" + side
        x0, x1 = X(sx, 3.5, 5.6)
        a.box("Shoulder" + side, (x0, 9.4, -1.3), (x1, 11.9, 1.3), skin, bone)
        x0, x1 = X(sx, 3.7, 5.4)
        a.box("UpperArm" + side, (x0, 7.2, -1.0), (x1, 9.4, 1.0), skin, bone)
        a.pivots[bone] = (sx * 4.5, 10.9, 0)
    x0, x1 = X(-1, 3.6, 5.5)
    a.box("FistL", (x0, 5.0, -1.1), (x1, 7.2, 1.1), skin, "ArmL")
    a.box("ForearmR", (3.7, 7.2, -3.0), (5.4, 8.8, -1.0), skin, "ArmR")
    a.box("FistR", (3.6, 7.0, -4.8), (5.5, 9.0, -2.9), skin, "ArmR")
    # the club: a handle through the fist, a thick head on top with grey spikes
    cx, cz = 4.55, -3.85
    a.box("BatHandle", (cx - 0.4, 5.9, cz - 0.4), (cx + 0.4, 11.4, cz + 0.4), wood_dark, "Bat")
    a.box("BatHead", (cx - 0.95, 11.4, cz - 0.95), (cx + 0.95, 15.6, cz + 0.95), wood, "Bat")
    a.box("BatCap", (cx - 0.7, 15.6, cz - 0.7), (cx + 0.7, 16.0, cz + 0.7), wood, "Bat")
    n = 0
    for y in (12.4, 14.4):
        for axis in ("-x", "+x", "-z", "+z"):
            s = -0.95 if axis[0] == "-" else 0.95
            off = 0.35 if y > 13 else -0.35  # stagger the two rings a little
            if axis[1] == "x":
                lo, hi = (cx + s, y - 0.3, cz + off - 0.3), (cx + s, y + 0.3, cz + off + 0.3)
            else:
                lo, hi = (cx + off - 0.3, y - 0.3, cz + s), (cx + off + 0.3, y + 0.3, cz + s)
            pyramid(a, f"Spike{n}", lo, hi, axis, 0.7, spike, "Bat")
            n += 1
    a.pivots.update(root=(0, 7.0, 0), neck=(0, 11.5, -0.6), Jaw=(0, 12.05, 0.4), Ponytail=(0, 14.6, 1.25),
                    Bat=(cx, 8.0, cz))
    a.meta = {"seat": (0, 11.5, 0.6), "neck_loop": {"center": (0, 13.3, -0.8), "radius": 2.6}}
    a.meta_scale = 1.05
    return a


# ---------------------------------------------------------------- ice dragon

DRAGON = dict(cyan=(56, 206, 238), fur=(252, 253, 255), wing=(186, 236, 250), claw=(236, 246, 255))
HEAD_TEX = {"cyan": (56, 206, 238), "white": (252, 253, 255), "mouth": (238, 104, 146), "nostril": (26, 70, 110),
            "eye": (255, 255, 255), "red": (236, 30, 40), "pupil": (30, 30, 45), "ivory": (250, 248, 238),
            "ice": (206, 244, 255)}
HEAD_PARTS = [  # QM's snake head parts by name prefix -> colour
    (("Cranium", "Long_box_muzzle", "Cheek_L", "Cheek_R", "Chin", "Jaw_rim"), "cyan"),
    (("Jaw_floor",), "white"),
    (("Lower_mouth", "Mouth_roof"), "mouth"),
    (("Nostril",), "nostril"),
    (("Eye_white",), "eye"),
    (("Amber_iris",), "red"),
    (("Slit_pupil",), "pupil"),
    (("Upper_tooth", "Lower_tooth"), "ivory"),
    (("Forehead_crest", "Cheek_spike", "Swept_horn", "Heavy_brow"), "ice"),
]
DRAGON_HEAD_SCALE = 4.2  # QM's head is modelled small: this makes it ~7 studs long


def ice_dragon():
    """Body, legs, tail and wings as blocks. The head is grafted on from QM's
    snake head in dragon_model()."""
    a = Animal("IceDragon", "Legendary")
    c = DRAGON
    a.bone_order = [("root", None), ("NeckBase", "root"), ("neck", "NeckBase"), ("Tail", "root"), ("Tail2", "Tail"),
                    ("Tail3", "Tail2"), ("WingL", "root"), ("WingR", "root")] + [("Leg" + leg, "root") for leg in A.LEGS]

    def ring(name, z0, z1, hw, y0, y1, bone, out=0.25):
        """White fur block between two scale panels, standing out of them all round."""
        a.box(name, (-hw - out, y0 - out, z0), (hw + out, y1 + out, z1), c["fur"], bone)

    # torso: cyan scale panels with thick fur rings between
    hw, y0, y1 = 3.3, 4.6, 9.9
    ym = (y0 + y1) / 2
    a.dims = dict(x=hw, y0=y0, y1=y1, z0=-5.4, z1=5.4)
    for i, (z0, z1) in enumerate(((-5.4, -2.7), (-1.8, 0.9), (1.8, 5.4))):
        a.box(f"Body{i + 1}", (-hw, y0, z0), (hw, y1, z1), c["cyan"], "root")
    ring("Fur1", -2.7, -1.8, hw, y0, y1, "root", 0.3)
    ring("Fur2", 0.9, 1.8, hw, y0, y1, "root", 0.3)
    a.pivots["root"] = (0, ym, 0)
    # four thick legs, white claws
    a.legs(0.8, 3.3, 2.6, 0.9, c["cyan"], c["cyan"])
    for leg in A.LEGS:
        sx = -1 if leg[1] == "L" else 1
        z = -5.4 if leg[0] == "F" else 5.4 - 2.6
        for i, xc in enumerate((1.3, 2.05, 2.8)):
            x0, x1 = X(sx, xc - 0.25, xc + 0.25)
            pyramid(a, f"Claw{leg}{i}", (x0, 0, z), (x1, 0.55, z), "-z", 0.7, c["claw"], "Leg" + leg)
    # neck: two panels straight out front, a fur ring at the joint
    nh, ny0, ny1 = 2.1, ym - 1.9, ym + 1.9
    a.box("Neck1", (-nh, ny0, -8.4), (nh, ny1, -5.4), c["cyan"], "NeckBase")
    ring("NeckFur1", -9.2, -8.4, nh, ny0, ny1, "neck", 0.25)
    a.box("Neck2", (-nh, ny0, -12.0), (nh, ny1, -9.2), c["cyan"], "neck")
    a.pivots.update(NeckBase=(0, ym, -5.4), neck=(0, ym, -8.4))
    a.neck_front = (0, ym, -12.0)
    # tail: straight back, stepping down, fur rings, an ice spike at the end
    segs = [("Tail", 5.4, 9.0, 2.4, ym - 1.6, ym + 1.6), ("Tail2", 9.8, 13.2, 1.7, ym - 1.1, ym + 1.1),
            ("Tail3", 13.9, 16.8, 1.1, ym - 0.75, ym + 0.75)]
    for i, (name, z0, z1, thw, ty0, ty1) in enumerate(segs):
        a.box(name, (-thw, ty0, z0), (thw, ty1, z1), c["cyan"], name)
        if i < 2:
            nxt = segs[i + 1]
            ring(f"TailFur{i + 1}", z1, nxt[1], nxt[3], nxt[4], nxt[5], nxt[0], 0.25)
    pyramid(a, "TailSpike", (-1.1, ym - 0.75, 16.8), (1.1, ym + 0.75, 16.8), "+z", 2.2, c["fur"], "Tail3")
    a.pivots.update(Tail=(0, ym, 5.4), Tail2=(0, ym, 9.0), Tail3=(0, ym, 13.2))
    # back spikes along the spine: small white pyramids on the fur rings
    for i, (z0, z1) in enumerate(((-2.6, -1.9), (1.0, 1.7))):
        pyramid(a, f"BackSpike{i + 1}", (-0.35, y1 + 0.3, z0), (0.35, y1 + 0.3, z1), "+y", 1.2, c["fur"], "root")
    # wings spread flat: a leading arm, three fingers running back, stepped ice panels between
    for side, sx in SIDES:
        bone = "Wing" + side
        wy0, wy1 = y1 - 0.9, y1 - 0.1
        x0, x1 = X(sx, hw, 11.2)
        a.box("WingArm" + side, (x0, wy0, -4.6), (x1, wy1, -3.6), c["cyan"], bone)
        prev = hw
        for i, (fx, back) in enumerate(((5.6, 4.4), (8.0, 2.8), (10.4, 1.0))):
            x0, x1 = X(sx, fx - 0.3, fx + 0.3)
            a.box(f"Finger{i + 1}" + side, (x0, wy0 + 0.1, -3.6), (x1, wy1 - 0.1, back), c["cyan"], bone)
            x0, x1 = X(sx, prev, fx - 0.3)
            a.box(f"Web{i + 1}" + side, (x0, wy0 + 0.25, -3.6), (x1, wy1 - 0.25, back - 0.6), c["wing"], bone)
            prev = fx + 0.3
        x0, x1 = X(sx, prev, 11.2)
        a.box("Web4" + side, (x0, wy0 + 0.25, -3.6), (x1, wy1 - 0.25, -1.4), c["wing"], bone)
        x0, x1 = X(sx, 10.6, 11.2)
        pyramid(a, "WingClaw" + side, (x0, wy1, -4.4), (x1, wy1, -3.8), "+y", 0.8, c["claw"], bone)
        a.pivots[bone] = (sx * hw, wy0 + 0.4, -4.1)
    a.meta = {"seat": (0, y1, 0.2), "neck_loop": {"center": (0, ym, -7.0), "radius": 2.7}}
    a.meta_scale = 1.1
    return a


def dragon_head(back, k=DRAGON_HEAD_SCALE):
    """QM's snake head (designs/desert/SnakeHead_QM.bbmodel), scaled k and
    recoloured, its Head group origin (the back of the skull) at `back` (studs).
    Returns (elements, groups, outliner node) with textures numbered from 1."""
    m = json.load(open(SNAKE_HEAD))
    src = np.array(next(g for g in m["groups"] if g["name"] == "Head")["origin"], float)
    off = np.array(back, float) * BB - src * k

    def mv(v):
        return [round(float(c), 4) for c in np.array(v, float) * k + off]

    for e in m["elements"]:
        for key in ("from", "to", "origin"):
            if key in e:
                e[key] = mv(e[key])
        if "vertices" in e:
            e["vertices"] = {n: [round(c * k, 4) for c in v] for n, v in e["vertices"].items()}
        for prefixes, color in HEAD_PARTS:
            if e["name"].startswith(prefixes):
                for f in e["faces"].values():
                    f["texture"] = 1 + list(HEAD_TEX).index(color)
                break
        else:
            raise ValueError("no colour for head part " + e["name"])
    for g in m["groups"]:
        g["origin"] = mv(g["origin"])
    textures = [solid_texture(n, rgb) for n, rgb in HEAD_TEX.items()]
    return m["elements"], m["groups"], m["outliner"][0], textures


def dragon_model(a):
    """The dragon's .bbmodel: body blocks from write_bbmodel, QM's head grafted onto the neck."""
    model, groups = write_bbmodel(a.parts, a.name, None, bones=a.bones())
    elements, hgroups, node, textures = dragon_head(a.neck_front, DRAGON_HEAD_SCALE * getattr(a, "meta_scale", 1))
    model["elements"] += elements
    model["groups"] += hgroups
    model["textures"] += textures

    def find(nodes, uid):
        for n in nodes:
            if isinstance(n, dict):
                if n["uuid"] == uid:
                    return n
                hit = find(n["children"], uid)
                if hit:
                    return hit

    find(model["outliner"], groups["neck"]["uuid"])["children"].append(node)
    return model


# ---------------------------------------------------------------- ice wyvern

WYV = dict(cyan=(56, 206, 238), plate=(30, 164, 214), fur=(252, 253, 255), belly=(196, 240, 252),
           wing=(170, 228, 248), spar=(236, 246, 255), horn=(206, 236, 252), eye=(236, 44, 64), slit=(40, 12, 24))


WYVERN_HEAD_SCALE = 4.4  # QM's snake head at about the old wyvern head's size
HEAD_DROP = ("Swept_horn",)  # the snake's own horns: the wyvern gets antlers instead


def ice_wyvern():
    """QM's wyvern (designs/snow/refs/ivory_wyvern_1.bbmodel) translated into our
    blocks: a small torso pitched up, an S-curved two-piece neck, a long three-piece
    tail curling up at an ice spike, crouched digitigrade legs, and wing-arms half
    spread. Scale panels are cyan with white fur rings at every joint; the
    reference's flat fins and horns become block spikes and pyramids. Every block
    is axis-aligned inside its bone; the pose is all bone rest rotations."""
    c = WYV
    a = Animal("IceWyvern", "Legendary")
    a.rest = {}
    order = [("root", None)]

    def bone(name, parent, pivot, rest=(0, 0, 0)):
        order.append((name, parent))
        a.pivots[name] = pivot
        if any(rest):
            a.rest[name] = rest

    def ring(name, z0, z1, hw, y0, y1, b, out=0.3):
        a.box(name, (-hw - out, y0 - out, z0), (hw + out, y1 + out, z1), c["fur"], b)

    def spikes(name, zs, y, b, h=1.0, w=0.8):
        for i, z in enumerate(zs):
            pyramid(a, f"Spike{name}{i}", (-w / 2, y, z - w / 2), (w / 2, y, z + w / 2), "+y", h, c["horn"], b)

    # torso: the root, pitched up at the chest
    a.pivots["root"] = (0, 8.0, 0)
    a.rest["root"] = (10, 0, 0)
    a.box("Torso", (-2.6, 6.0, -4.5), (2.6, 10.6, 4.0), c["cyan"], "root")
    a.box("Belly", (-2.0, 5.5, -4.0), (2.0, 6.0, 3.4), c["belly"], "root")
    a.box("BackPlate", (-1.8, 10.6, -3.6), (1.8, 11.2, 3.2), c["plate"], "root")
    spikes("Back", (-2.2, 0.0, 2.2), 11.2, "root", 1.2)
    # neck: two pieces bending up then forward
    bone("neck", "root", (0, 8.8, -4.5), (38, 0, 0))
    ring("NeckRing0", -5.0, -4.2, 1.9, 7.2, 10.4, "neck", 0.25)
    a.box("Neck1", (-1.6, 7.4, -10.0), (1.6, 10.2, -4.2), c["cyan"], "neck")
    a.box("Neck1Belly", (-1.1, 6.9, -9.6), (1.1, 7.4, -4.6), c["belly"], "neck")
    spikes("Neck1", (-8.0, -6.0), 10.2, "neck", 0.9, 0.7)
    bone("Neck2", "neck", (0, 8.8, -10.0), (-22, 0, 0))
    ring("NeckRing1", -10.6, -9.8, 1.5, 7.5, 10.1, "Neck2", 0.25)
    a.box("Neck2", (-1.3, 7.6, -15.0), (1.3, 10.0, -10.0), c["cyan"], "Neck2")
    a.box("Neck2Belly", (-0.9, 7.1, -14.6), (0.9, 7.6, -10.4), c["belly"], "Neck2")
    spikes("Neck2", (-13.4, -11.6), 10.0, "Neck2", 0.8, 0.6)
    # head: QM's sand-snake head (grafted in rest_model), with reindeer antlers
    # and tusks coming forward from the sides of the mouth instead of its horns
    bone("Head", "Neck2", (0, 8.8, -15.0), (-26, 0, 0))
    a.head_graft = ((0, 8.8, -15.0), WYVERN_HEAD_SCALE)
    for side, sx in SIDES:
        an = "Antler" + side
        bone(an, "Head", (sx * 1.3, 10.6, -16.6), (-18, 0, sx * -22))
        x0, x1 = X(sx, 1.0, 1.6)
        a.box(an + "Base", (x0, 10.4, -16.9), (x1, 12.4, -16.3), c["horn"], an)
        a.box(an + "Beam", (x0, 11.8, -16.3), (x1, 12.4, -14.4), c["horn"], an)  # the main beam sweeps back
        a.box(an + "Up", (x0, 12.4, -15.0), (x1, 14.6, -14.4), c["horn"], an)  # and up
        a.box(an + "Top", (x0, 14.0, -16.2), (x1, 14.6, -15.0), c["horn"], an)
        pyramid(a, f"Spike{an}Top", (x0, 14.0, -16.2), (x1, 14.6, -16.2), "-z", 0.8, c["spar"], an)
        # tines pointing forward off the beam
        for k, (y, z) in enumerate(((11.8, -16.3), (13.0, -15.0))):
            a.box(f"{an}Tine{k}", (x0, y, z - 1.0), (x1, y + 0.6, z), c["horn"], an)
            pyramid(a, f"Spike{an}Tine{k}", (x0, y, z - 1.0), (x1, y + 0.6, z - 1.0), "-z", 0.7, c["spar"], an)
        # tusk: out of the mouth's side, pointing forward and a little up
        tk = "Tusk" + side
        bone(tk, "Head", (sx * 2.0, 7.9, -19.4), (14, sx * -8, 0))
        x0, x1 = X(sx, 1.7, 2.35)
        a.box(tk + "Base", (x0, 7.6, -20.4), (x1, 8.25, -18.8), c["spar"], tk)
        pyramid(a, f"{tk}Tip", (x0, 7.6, -20.4), (x1, 8.25, -20.4), "-z", 1.6, c["spar"], tk)
    # tail: three pieces, dipping then curling up to an ice spike
    bone("Tail", "root", (0, 8.4, 4.0), (-14, 0, 0))
    ring("TailRing0", 3.8, 4.6, 1.8, 7.2, 9.8, "Tail", 0.25)
    a.box("Tail1", (-1.6, 7.2, 4.6), (1.6, 9.8, 10.6), c["cyan"], "Tail")
    spikes("Tail1", (6.4, 8.8), 9.8, "Tail", 0.9, 0.7)
    bone("Tail2", "Tail", (0, 8.5, 10.6), (22, 0, 0))
    ring("TailRing1", 10.4, 11.2, 1.3, 7.5, 9.5, "Tail2", 0.25)
    a.box("Tail2", (-1.2, 7.6, 11.2), (1.2, 9.4, 17.0), c["cyan"], "Tail2")
    spikes("Tail2", (13.0, 15.2), 9.4, "Tail2", 0.8, 0.6)
    bone("Tail3", "Tail2", (0, 8.5, 17.0), (-28, 0, 0))
    ring("TailRing2", 16.8, 17.5, 0.9, 7.8, 9.2, "Tail3", 0.2)
    a.box("Tail3", (-0.8, 7.9, 17.5), (0.8, 9.1, 22.5), c["cyan"], "Tail3")
    a.box("TailFin", (-0.3, 9.1, 18.5), (0.3, 10.3, 22.0), c["horn"], "Tail3")
    pyramid(a, "SpikeTailTip", (-0.8, 7.9, 22.5), (0.8, 9.1, 22.5), "+z", 2.4, c["spar"], "Tail3")
    # legs: crouched and digitigrade, thigh forward, shin back, long foot, three white claws
    for side, sx in SIDES:
        th = "LegH" + side
        bone(th, "root", (sx * 2.3, 7.4, 2.0), (34, 0, sx * 4))
        x0, x1 = X(sx, 1.4, 3.8)
        a.box("Thigh" + side, (x0, 2.8, 0.4), (x1, 8.4, 3.8), c["cyan"], th)
        sh = "Shin" + side
        bone(sh, th, (sx * 2.6, 3.4, 2.0), (-70, 0, 0))
        x0, x1 = X(sx, 1.9, 3.3)
        a.box("Shin" + side, (x0, -1.4, 1.3), (x1, 3.4, 2.7), c["cyan"], sh)
        ring("Ankle" + side, 1.4, 2.6, 0, -1.4, -0.8, sh, 0.25)
        a.parts[-1].cf[0, 3] = sx * 2.6
        a.parts[-1].size[0] = 1.9
        ft = "Foot" + side
        bone(ft, sh, (sx * 2.6, -1.2, 2.0), (36, 0, 0))
        x0, x1 = X(sx, 1.8, 3.4)
        a.box("Foot" + side, (x0, -1.9, -1.6), (x1, -0.7, 2.6), c["cyan"], ft)
        for i, xc in enumerate((2.0, 2.6, 3.2)):
            x0, x1 = X(sx, xc - 0.22, xc + 0.22)
            pyramid(a, f"Claw{side}{i}", (x0, -1.9, -1.6), (x1, -1.1, -1.6), "-z", 1.0, c["spar"], ft)
    # wings (QM 23:52): wide and built to fold, six pieces each. The arm carries the
    # inner membrane; the hand carries the thumb; the spar along the outer edge
    # carries the outer membrane, so the hand folds against the arm and the spar
    # folds against the hand.
    for side, sx in SIDES:
        w = "Wing" + side
        bone(w, "root", (sx * 2.4, 10.0, -2.4), (0, sx * -12, sx * 20))
        x0, x1 = X(sx, 2.2, 11.5)
        a.box("WingArm" + side, (x0, 9.3, -3.2), (x1, 10.7, -1.6), c["cyan"], w)
        x0, x1 = X(sx, 2.4, 11.5)
        a.box("WingSkinIn" + side, (x0, 9.75, -1.6), (x1, 10.25, 7.5), c["wing"], w)
        wh = "WingHand" + side
        bone(wh, w, (sx * 11.5, 10.0, -2.4), (0, sx * -10, sx * -6))
        x0, x1 = X(sx, 11.2, 21.5)
        a.box("WingHand" + side, (x0, 9.4, -3.0), (x1, 10.6, -1.8), c["cyan"], wh)
        x0, x1 = X(sx, 20.6, 21.4)
        pyramid(a, f"WingThumb{side}", (x0, 9.5, -3.0), (x1, 10.5, -3.0), "-z", 1.8, c["spar"], wh)
        ws = "WingSpar" + side
        bone(ws, wh, (sx * 21.2, 10.0, -2.4))
        x0, x1 = X(sx, 20.8, 21.6)
        a.box("WingSpar" + side, (x0, 9.6, -1.8), (x1, 10.4, 13.0), c["spar"], ws)
        x0, x1 = X(sx, 11.5, 20.8)
        a.box("WingSkinOut" + side, (x0, 9.75, -1.8), (x1, 10.25, 11.0), c["wing"], ws)
    a.bone_order = order
    a.meta = {"seat": (0, 11.2, 0.4), "neck_loop": {"center": (0, 8.8, -8.0), "radius": 2.2}}
    a.meta_scale = 0.9  # XL: about 20 studs tall and 40 long, the biggest pet
    return a


# ---------------------------------------------------------------- build + render

CREATURES = [snowman, penguin, white_wolf, polar_bear, troll, ice_dragon, ice_wyvern]
PLAIN = ("Eye", "Pupil", "Nostril", "Plain", "Mouth", "Amber", "Slit", "Upper_tooth", "Lower_tooth", "Scar",
         "Coal", "Button", "Claw", "Spike", "Tusk", "Carrot", "Nose", "Tie")


def scaled(a):
    k = getattr(a, "meta_scale", 1)
    if k != 1:
        a.scale(k)
        if hasattr(a, "neck_front"):
            a.neck_front = tuple(np.array(a.neck_front) * k)
        if getattr(a, "head_graft", None):
            back, hk = a.head_graft
            a.head_graft = (tuple(np.array(back) * k), hk * k)
    return a


def build(fn):
    """(animal, model dict, parts to render) for one builder."""
    a = scaled(fn())
    if fn is ice_dragon:
        model = dragon_model(a)
        parts = posed(model)
    elif getattr(a, "rest", None):
        model, parts = rest_model(a)
        drop = min(q[:, 1].min() for p in parts for q in p.polys)
        if abs(drop) > 0.01:  # stand the posed model on the ground
            lift(a, -drop)
            model, parts = rest_model(a)
    else:
        model, _ = write_bbmodel(a.parts, a.name, None, bones=a.bones())
        parts = a.parts
    for p in parts:
        if p.name.startswith(PLAIN):
            p.plain = True
    return a, model, parts


def qm_wyvern_wings():
    """QM's IceWyvern.bbmodel (their antlers, tusks and teeth) with its wing
    groups swapped for the ones ice_wyvern() builds. Same frame: QM kept the body."""
    path = os.path.join(MODELS, "IceWyvern.bbmodel")
    qm = json.load(open(path))
    a, model, _ = build(ice_wyvern)
    wings = [g for g in model["groups"] if g["name"].startswith("Wing")]
    gm = {g["uuid"]: g for g in model["groups"]}
    old = {g["uuid"] for g in qm["groups"] if g["name"].startswith("Wing")}

    def members(node):
        out = []
        for c in node["children"]:
            out += members(c) if isinstance(c, dict) else [c]
        return out

    qroot = qm["outliner"][0]
    drop = set()
    for n in qroot["children"]:
        if isinstance(n, dict) and n["uuid"] in old:
            drop |= set(members(n))
    qroot["children"] = [n for n in qroot["children"] if not (isinstance(n, dict) and n["uuid"] in old)]
    qm["elements"] = [e for e in qm["elements"] if e["uuid"] not in drop]
    qm["groups"] = [g for g in qm["groups"] if g["uuid"] not in old]
    # the new wing elements use the builder's palette texture: add it as one more texture
    tex = len(qm["textures"])
    palette = dict(model["textures"][0], uuid=str(__import__("uuid").uuid4()), name="wings.png", id=str(tex))
    qm["textures"].append(palette)
    new = set()
    for n in model["outliner"][0]["children"]:
        if isinstance(n, dict) and gm[n["uuid"]]["name"] in ("WingL", "WingR"):
            qroot["children"].append(n)
            new |= set(members(n))
    for e in model["elements"]:
        if e["uuid"] in new:
            for f in e["faces"].values():
                f["texture"] = tex
            qm["elements"].append(e)
    qm["groups"] += wings
    with open(path, "w") as f:
        json.dump(qm, f, separators=(",", ":"))
    return qm


def rest_model(a):
    """The .bbmodel with the bones' rest rotations, and its posed parts."""
    model, groups = write_bbmodel(a.parts, a.name, None, bones=a.bones())
    for bone, r in a.rest.items():
        groups[bone]["rotation"] = list(r)
    if getattr(a, "head_graft", None):
        graft_head(model, groups["Head"], *a.head_graft)
    return model, posed(model)


def graft_head(model, parent, back, k):
    """QM's snake head, minus HEAD_DROP parts, into group `parent`, the back of its skull at `back`."""
    elements, hgroups, node, textures = dragon_head(back, k)
    drop = {e["uuid"] for e in elements if e["name"].startswith(HEAD_DROP)}

    def prune(n):
        n["children"] = [prune(c) if isinstance(c, dict) else c for c in n["children"]
                         if isinstance(c, dict) or c not in drop]
        return n

    model["elements"] += [e for e in elements if e["uuid"] not in drop]
    model["groups"] += hgroups
    model["textures"] += textures

    def find(nodes, uid):
        for n in nodes:
            if isinstance(n, dict):
                if n["uuid"] == uid:
                    return n
                hit = find(n["children"], uid)
                if hit:
                    return hit

    find(model["outliner"], parent["uuid"])["children"].append(prune(node))


def lift(a, dy):
    for p in a.parts:
        if p.shape == "Poly":
            p.polys = [q + np.array([0, dy, 0]) for q in p.polys]
        else:
            p.cf[1, 3] += dy
    a.pivots = {n: (v[0], v[1] + dy, v[2]) for n, v in a.pivots.items()}
    if getattr(a, "head_graft", None):
        (x, y, z), k = a.head_graft
        a.head_graft = ((x, y + dy, z), k)
    if a.meta:
        a.meta["seat"] = (a.meta["seat"][0], a.meta["seat"][1] + dy, a.meta["seat"][2])


ANIMATED = {"Penguin", "Snowman", "PolarBear", "IceWyvern"}  # in game, animated by tools/snow_rig.py


def save_model(a, model):
    os.makedirs(MODELS, exist_ok=True)
    path = os.path.join(MODELS, a.name + ".bbmodel")
    if a.name in ANIMATED and "--force" not in sys.argv:
        return path  # keep the animated file (rerun with --force, then snow_rig.py and the converter)
    with open(path, "w") as f:
        json.dump(model, f, separators=(",", ":"))
    return path


def points(parts):
    return np.concatenate([np.concatenate([w for w, _ in part_faces(p)]) for p in parts])


def bounds(parts):
    pts = points(parts)
    return pts.min(0), pts.max(0)


QM_FILES = {"PolarBear", "IceWyvern", "Penguin", "Snowman"}  # Penguin and Snowman come from tools/refine_designs.py; IceWyvern is QM's file too, but its wings come from here (qm_wyvern_wings)
NAMES = {"WhiteWolf": "White Wolf", "PolarBear": "Polar Bear", "IceDragon": "Ice Dragon", "IceWyvern": "Ice Wyvern"}
Q34_DIR = np.array([-19, 12, -21], float) / np.linalg.norm([-19, 12, -21])


def lineup(out):
    horse = A.qm_horse("A")
    tiles = [("Horse · for size", pose(horse, None, 0))]
    for fn in CREATURES:
        a, model, parts = build(fn)
        save_model(a, model)
        tiles.append((f"{NAMES.get(a.name, a.name)} · {a.rarity}", parts))
        print(a.name, len(a.parts), "parts")
    H, fov, dist, ty = 460, 30, 62, 7.0
    ims = []
    for name, parts in tiles:
        lo, hi = bounds(parts)
        cx, cz = (lo[0] + hi[0]) / 2, (lo[2] + hi[2]) / 2
        target = np.array([cx, ty, cz])
        eye = target + Q34_DIR * dist
        # width: the projected x extent of the bounding box, plus a margin
        e, r, u, f = look_at(eye, target)
        focal = (H / 2) / np.tan(np.radians(fov) / 2)
        d = points(parts) - e
        xs = focal * (d @ r) / (d @ f)
        W = int(max(150, 2 * max(abs(xs.min()), abs(xs.max())) + 24))
        ims.append((name, render(parts, eye=eye, target=target, W=W, H=H, fov=fov)))
    sheet = Image.new("RGB", (sum(im.width for _, im in ims), H))
    x = 0
    for _, im in ims:
        sheet.paste(im, (x, 0))
        x += im.width
    if sheet.width > 1600:  # keep it modest: shrink the whole strip, sizes still compare
        k = 1600 / sheet.width
        sheet = sheet.resize((1600, round(H * k)), Image.LANCZOS)
        ims = [(n, im.resize((round(im.width * k), sheet.height))) for n, im in ims]
    labelled = label_tiles(sheet, ims)
    path = os.path.join(out, "snow_lineup.png")
    labelled.save(path)
    print("wrote", path, labelled.size)


def label_tiles(sheet, ims, size=16):
    """Two-line labels (name, then rarity) over tiles of different widths."""
    from PIL import ImageDraw
    band = 48
    out = Image.new("RGB", (sheet.width, sheet.height + band), (255, 255, 255))
    out.paste(sheet, (0, band))
    d = ImageDraw.Draw(out)
    x = 0
    for name, im in ims:
        for row, text in enumerate(name.split(" · ")):
            tw = d.textlength(text, font=A.font(size))
            d.text((x + (im.width - tw) / 2, 5 + row * 21), text, fill=(20, 20, 20), font=A.font(size))
        x += im.width
    return out


def one(name, out):
    """Close look at one animal: 3/4 front, side, 3/4 back, front."""
    fn = next(f for f in CREATURES if f.__name__.replace("_", "") == name.lower().replace("_", ""))
    a, model, parts = build(fn)
    if a.name in QM_FILES:  # QM's own edit is the source of truth: render it, don't overwrite it
        model = json.load(open(os.path.join(MODELS, a.name + ".bbmodel")))
        parts = posed(model)
        for p in parts:
            if p.name.startswith(PLAIN):
                p.plain = True
    path = save_model(a, model)
    shutil.copy(path, os.path.join(out, a.name + ".bbmodel"))  # next to the renders for QM
    print("wrote", path)
    lo, hi = bounds(parts)
    c = (lo + hi) / 2
    radius = np.linalg.norm(hi - lo) / 2
    W, H, fov = 420, 420, 34
    dist = radius / np.tan(np.radians(fov) / 2) * 0.97
    views = [(-19, 12, -21), (-1, 0.15, -0.02), (17, 11, 20), (-0.12, 0.2, -1)]
    sheet = Image.new("RGB", (W * len(views), H))
    for i, v in enumerate(views):
        v = np.array(v, float) / np.linalg.norm(v)
        sheet.paste(render(parts, eye=c + v * dist, target=c, W=W, H=H, fov=fov), (i * W, 0))
    path = os.path.join(out, f"{a.name}.png")
    A.label(sheet, [f"{NAMES.get(a.name, a.name)} · {a.rarity}", "side", "back", "front"], 18).save(path)
    print("wrote", path)


if __name__ == "__main__":
    args = sys.argv[1:]
    os.makedirs(OUT, exist_ok=True)
    if args and args[0] == "one":
        one(args[1], args[2] if len(args) > 2 else OUT)
    else:
        target = args[0] if args else OUT
        os.makedirs(target, exist_ok=True)
        lineup(target)
        for fn in CREATURES:
            one(fn.__name__, target)
