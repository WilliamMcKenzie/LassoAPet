"""Four companions (QM, Oct 14) from QM's pixel-art sheet: Mammoth, Snail, Hula and Tortoise.
Every one wears the same saddle: a maroon blanket with a darker hem, a gold gem on each
side, a dark seat with a tan pommel in front and a tan cantle behind.

Built in the sheet's pixels (front is -z) and scaled to studs at the end, like the Buffalo.
Bones follow the quadrupeds (root, neck, Tail, Leg*); the Snail has root and neck only.
Model only for now (no animations): QM critiques the lineup first.

    python3 tools/companions.py

writes designs/world3/<Name>.bbmodel and renders to /mnt/project-files/world3/renders/.
"""

import json
import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import animal_designs as A  # noqa: E402
from animal_designs import Animal  # noqa: E402
from partlib import render, write_bbmodel  # noqa: E402
from horse_rig import pose  # noqa: E402
import horse_rig  # noqa: E402
import snake_design as SD  # noqa: E402

horse_rig.EULER = "ZYX"  # the War Elephant and Firebird are QM's files, converted with --zyx

PX = 0.75  # studs per pixel of QM's sheet

# the saddle, shared by all four
BLANKET = (104, 44, 30)
HEM = (66, 20, 14)
SEAT = (58, 17, 12)
TAN = (164, 115, 75)
GOLD = (210, 182, 70)


def saddle(a, half, y_top, y_hem, z0, z1, seat_half):
    """Blanket over the back from z0 to z1, hanging down to y_hem, seat on top."""
    a.box("Blanket", (-half, y_hem + 0.6, z0), (half, y_top, z1), BLANKET, "root")
    a.box("Hem", (-half - 0.05, y_hem, z0 - 0.05), (half + 0.05, y_hem + 0.6, z1 + 0.05), HEM, "root")
    zm = (z0 + z1) / 2
    for side, sx in (("L", -1), ("R", 1)):
        xa, xb = sorted((sx * half, sx * (half + A.PLATE)))
        gy = (y_hem + 0.6 + y_top) / 2
        a.box("Gem" + side, (xa, gy - 0.6, zm - 0.6), (xb, gy + 0.6, zm + 0.6), GOLD, "root")
    a.box("Seat", (-seat_half, y_top, z0 + 0.5), (seat_half, y_top + 0.6, z1 - 0.5), SEAT, "root")
    a.box("Pommel", (-0.8, y_top, z0 + 0.2), (0.8, y_top + 1.5, z0 + 0.9), TAN, "root")
    a.box("Cantle", (-seat_half, y_top + 0.6, z1 - 1.1), (seat_half, y_top + 1.2, z1 - 0.4), TAN, "root")
    a.meta = {"seat": (0, y_top + 0.6, zm), "neck_loop": a.meta.get("neck_loop")}


# ---------------------------------------------------------------- Mammoth

COAT = (84, 56, 42)
COAT_DARK = (64, 39, 29)
SPECK = (116, 86, 66)
TUSK = (226, 222, 208)
TRUNK_TIP = (150, 144, 134)
NAIL = (200, 194, 180)


def mammoth():
    a = Animal("Mammoth", "Legendary")
    a.box("Body", (-4.5, 3, 6), (4.5, 10, 16.5), COAT, "root")
    a.box("Hump", (-4.3, 10, 6), (4.3, 11.2, 9.6), COAT, "root")
    for i, (y, z) in enumerate(((8.2, 13.8), (5.2, 9.6), (4.4, 14.6))):
        for side, sx in (("L", -1), ("R", 1)):
            xa, xb = sorted((sx * 4.5, sx * (4.5 + A.PLATE)))
            a.box(f"Speck{i}{side}", (xa, y, z), (xb, y + 1, z + 1), SPECK, "root")
    a.pivots["root"] = (0, 6.5, 11)
    # big dark head, taller than the back
    a.box("Head", (-3.6, 5, 0.5), (3.6, 13.5, 6.5), COAT_DARK, "neck")
    a.box("Crown", (-3, 13.5, 1.2), (3, 14.3, 5.6), COAT_DARK, "neck")
    for side, sx in (("L", -1), ("R", 1)):
        xa, xb = sorted((sx * 3.6, sx * (3.6 + A.PLATE)))
        a.box("Speck3" + side, (xa, 7, 2.5), (xb, 8, 3.5), SPECK, "neck")
    a.eyes(3.6, 10.5, 12, 1.2, 2.6)
    # trunk down the front of the head, curling forward to a grey tip
    a.box("Trunk", (-1.2, 2, -0.3), (1.2, 5.5, 1.6), COAT_DARK, "neck")
    a.box("TrunkCurl", (-1.2, 1, -2.4), (1.2, 2.6, 1.6), COAT_DARK, "neck")
    a.box("TrunkTip", (-1.1, 2.6, -2.4), (1.1, 3.8, -1.1), TRUNK_TIP, "neck")
    # tusks: down out of the jaw, forward, then the tip up
    for side, sx in (("L", -1), ("R", 1)):
        xa, xb = sorted((sx * 1.6, sx * 2.8))
        a.box("Tusk" + side, (xa, 2.4, 1.0), (xb, 5.2, 2.2), TUSK, "neck")
        a.box("TuskFwd" + side, (xa, 2.4, -1.4), (xb, 3.6, 1.0), TUSK, "neck")
        a.box("TuskTip" + side, (xa, 3.6, -1.4), (xb, 5.0, -0.3), TUSK, "neck")
    a.pivots["neck"] = (0, 9, 6)
    for side in ("L", "R"):
        a.pivots["Ear" + side] = a.pivots["neck"]
    # legs with pale toenails
    for leg in A.LEGS:
        sx = -1 if leg[1] == "L" else 1
        front = leg[0] == "F"
        xa, xb = sorted((sx * 1.2, sx * 4.3))
        za, zb = (6.5, 9.5) if front else (12.8, 15.8)
        a.box("Leg" + leg, (xa, 0, za), (xb, 3.001, zb), COAT_DARK, "Leg" + leg)
        na, nb = sorted((sx * 1.6, sx * 3.9))
        a.box("Nail" + leg, (na, 0, za - 0.1), (nb, 0.8, za + 0.4), NAIL, "Leg" + leg)
        a.pivots["Leg" + leg] = ((xa + xb) / 2, 3, zb - 0.1 if front else za + 0.1)
    # short tail with a dark tuft
    a.box("Tail", (-0.6, 7.4, 16.5), (0.6, 9.2, 17.4), COAT, "Tail")
    a.box("TailTuft", (-0.8, 6.2, 16.4), (0.8, 7.4, 17.6), COAT_DARK, "Tail")
    a.pivots["Tail"] = (0, 9.2, 16.5)
    a.meta = {"neck_loop": {"center": (0, 9, 3.5), "radius": 5.5}}
    saddle(a, 4.75, 10.2, 6.6, 9.8, 14.4, 2.6)
    a.scale(PX)
    return a


# ---------------------------------------------------------------- Snail

SLIME = (85, 178, 77)
SLIME_DARK = (64, 140, 82)
SHELL = (220, 199, 137)
SHELL_BAND = (184, 144, 77)


def snail():
    a = Animal("Snail", "Rare")
    a.bone_order = [("root", None), ("neck", "root")]
    a.box("Foot", (-2.2, 0.6, 0), (2.2, 2.2, 14), SLIME, "root")
    a.box("Sole", (-2.25, 0, -0.05), (2.25, 0.6, 14.05), SLIME_DARK, "root")
    a.pivots["root"] = (0, 4, 8)
    # head and neck rising out of the front of the foot, two eye stalks
    a.box("Head", (-1.9, 2.2, 0.2), (1.9, 7, 4.2), SLIME, "neck")
    a.box("Chin", (-1.95, 2.2, 0.15), (1.95, 3.6, 2.4), SLIME_DARK, "neck")
    for side, sx in (("L", -1), ("R", 1)):
        xa, xb = sorted((sx * 0.6, sx * 1.4))
        a.box("Stalk" + side, (xa, 7, 1.0), (xb, 8.6, 1.8), SLIME, "neck")
        ea, eb = sorted((sx * 0.3, sx * 1.7))
        a.box("Eye" + side, (ea, 8.6, 0.7), (eb, 10, 2.1), A.EYE_WHITE, "neck")
        pa, pb = sorted((sx * 0.6, sx * 1.4))
        a.box("Pupil" + side, (pa, 8.8, 0.65), (pb, 9.6, 0.7), A.PUPIL, "neck")
    a.pivots["neck"] = (0, 3, 3.5)
    # shell: tan with a darker spiral band on each side
    a.box("Shell", (-2.6, 2.2, 4.4), (2.6, 10.2, 13.6), SHELL, "root")
    for side, sx in (("L", -1), ("R", 1)):
        xa, xb = sorted((sx * 2.6, sx * (2.6 + A.PLATE)))
        a.box("Band" + side, (xa, 3.2, 5.4), (xb, 9.2, 12.6), SHELL_BAND, "root")
        xa, xb = sorted((sx * 2.6, sx * (2.6 + 2 * A.PLATE)))
        a.box("Swirl" + side, (xa, 4.2, 6.4), (xb, 8.2, 11.6), SHELL, "root")
    a.meta = {"neck_loop": {"center": (0, 5, 2.2), "radius": 3}}
    saddle(a, 2.75, 10.4, 6.2, 7.2, 11.2, 1.7)
    a.scale(PX)
    return a


# ---------------------------------------------------------------- Hula

HIDE = (140, 84, 44)
HIDE_DARK = (98, 45, 22)
HIDE_LIGHT = (186, 138, 82)
BELLY = (62, 22, 12)
ANTLER = (214, 184, 92)
ANTLER_TIP = (164, 116, 54)
HOOF = (120, 122, 128)


def hula():
    a = Animal("Hula", "Epic")
    a.box("Body", (-2.2, 4.6, 3), (2.2, 7.4, 10.6), HIDE, "root")
    a.box("Belly", (-2.25, 4, 2.95), (2.25, 4.6, 10.65), BELLY, "root")
    for i, z in enumerate((4.0, 9.4)):
        a.box(f"Speck{i}", (-1.2, 7.4, z), (1.2, 7.4 + A.PLATE, z + 0.9), HIDE_LIGHT, "root")
    a.pivots["root"] = (0, 6, 7)
    # long neck up from the front of the body, deer head with a dark snout
    a.box("Neck", (-1.3, 7.4, 2.4), (1.3, 12, 5.0), HIDE_DARK, "neck")
    a.box("Head", (-1.6, 12, 0), (1.6, 14.6, 4.2), HIDE, "neck")
    a.box("Snout", (-1.2, 12, -1.8), (1.2, 13.8, 0.001), HIDE_DARK, "neck")
    a.eyes(1.6, 12.9, 14, 0.4, 1.6)
    for side, sx in (("L", -1), ("R", 1)):
        # small antler nub and an ear swept back, both gold with tan tips
        xa, xb = sorted((sx * 0.4, sx * 1.1))
        a.box("Antler" + side, (xa, 14.6, 1.8), (xb, 15.6, 2.5), ANTLER, "neck")
        a.box("AntlerTip" + side, (xa, 15.6, 2.0), (xb, 16.6, 3.0), ANTLER_TIP, "neck")
        ea, eb = sorted((sx * 1.6, sx * 2.6))
        bone = "Ear" + side
        a.box(bone, (ea, 13.6, 2.8), (eb, 14.4, 4.6), ANTLER, bone)
        a.box(bone + "Tip", (ea, 13.6, 4.6), (eb, 14.4, 5.4), ANTLER_TIP, bone)
        a.pivots[bone] = ((ea + eb) / 2, 14, 2.8)
    a.pivots["neck"] = (0, 7.4, 3.7)
    # thin legs, light hind legs, grey hooves with a toe forward
    for leg in A.LEGS:
        sx = -1 if leg[1] == "L" else 1
        front = leg[0] == "F"
        xa, xb = sorted((sx * 0.6, sx * 1.6))
        za, zb = (3.4, 4.4) if front else (8.8, 9.8)
        a.box("Leg" + leg, (xa, 0.8, za), (xb, 4.001, zb), HIDE_DARK if front else HIDE_LIGHT, "Leg" + leg)
        a.box("Hoof" + leg, (xa - 0.05 * sx, 0, za - 0.6), (xb + 0.05 * sx, 0.8, zb), HOOF, "Leg" + leg)
        a.pivots["Leg" + leg] = ((xa + xb) / 2, 4, zb - 0.1 if front else za + 0.1)
    # tail out the back then straight up
    a.box("Tail", (-0.6, 5.8, 10.6), (0.6, 6.8, 12.2), HIDE, "Tail")
    a.box("TailUp", (-0.6, 6.8, 11.2), (0.6, 9.2, 12.2), HIDE_DARK, "Tail")
    a.pivots["Tail"] = (0, 6.3, 10.6)
    a.meta = {"neck_loop": {"center": (0, 10, 3.7), "radius": 2.5}}
    saddle(a, 2.35, 7.4, 4.6, 5.4, 9.0, 1.6)
    a.scale(PX)
    return a


# ---------------------------------------------------------------- Tortoise

SKIN = (168, 162, 132)
SKIN_DARK = (114, 100, 82)
RIM = (207, 224, 176)
SHELL_G = (97, 155, 75)
SHELL_TOP = (154, 203, 115)
SCUTE = (59, 110, 59)
TAIL = (80, 62, 52)


def tortoise():
    a = Animal("Tortoise", "Rare")
    a.box("Belly", (-3.8, 1.6, 4), (3.8, 3, 15), SKIN, "root")
    a.box("Rim", (-4.8, 3, 3.6), (4.8, 4, 15.6), RIM, "root")
    a.box("Shell", (-4.4, 4, 4.2), (4.4, 7, 15.0), SHELL_G, "root")
    a.box("ShellTop", (-3.3, 7, 5.2), (3.3, 8, 14.0), SHELL_TOP, "root")
    for side, sx in (("L", -1), ("R", 1)):
        xa, xb = sorted((sx * 4.4, sx * (4.4 + A.PLATE)))
        for i, z in enumerate((5.2, 12.6)):
            a.box(f"Scute{i}{side}", (xa, 4.6, z), (xb, 6.4, z + 1.8), SCUTE, "root")
        # pale spikes in a row each side of the saddle
        for i, z in enumerate((5.8, 12.4)):
            a.box(f"Spike{i}{side}", (sx * 2.4 - 0.7, 8, z), (sx * 2.4 + 0.7, 10, z + 1.2), RIM, "root")
    a.box("Spike2", (-0.7, 8, 13.4), (0.7, 10.6, 14.0), RIM, "root")
    a.pivots["root"] = (0, 4.5, 9.5)
    # neck and big blocky head held high at the front
    a.box("Neck", (-1.6, 3.2, 2.6), (1.6, 6.4, 5.0), SKIN, "neck")
    a.box("Head", (-2.3, 5.2, -0.4), (2.3, 8.8, 4.0), SKIN, "neck")
    a.box("Snout", (-2.35, 5.2, -0.45), (2.35, 6.4, 0.6), SKIN_DARK, "neck")
    a.eyes(2.3, 6.8, 8.0, 0.6, 1.8)
    a.pivots["neck"] = (0, 4.8, 4.4)
    for side in ("L", "R"):
        a.pivots["Ear" + side] = a.pivots["neck"]
    # stumpy legs with dark feet
    for leg in A.LEGS:
        sx = -1 if leg[1] == "L" else 1
        front = leg[0] == "F"
        xa, xb = sorted((sx * 1.6, sx * 4.2))
        za, zb = (5.0, 7.8) if front else (11.6, 14.4)
        a.box("Leg" + leg, (xa, 0.7, za), (xb, 3.001, zb), SKIN, "Leg" + leg)
        a.box("Foot" + leg, (xa - 0.05 * sx, 0, za - 0.05), (xb + 0.05 * sx, 0.7, zb + 0.05), SKIN_DARK, "Leg" + leg)
        a.pivots["Leg" + leg] = ((xa + xb) / 2, 3, zb - 0.1 if front else za + 0.1)
    a.box("Tail", (-0.7, 2.2, 15), (0.7, 3.4, 17), TAIL, "Tail")
    a.pivots["Tail"] = (0, 2.8, 15)
    a.meta = {"neck_loop": {"center": (0, 6.6, 2), "radius": 3}}
    saddle(a, 3.45, 8.0, 5.4, 7.6, 11.4, 2.4)
    a.scale(PX)
    return a


# ---------------------------------------------------------------- reskins of QM's models
# QM (Oct 14): the Mammoth is the War Elephant without its armour, the Hula is the Firebird,
# both recoloured to the sheet. Same bones and animations as the originals; the extra
# pieces are plain boxes in Blockbench units (10 per stud).


def reskin(src, name, colors, recolor, drop, add, resize=(), rename=()):
    """Load src, put `colors` on free palette cells, repaint elements (by name in recolor,
    else by old colour), drop elements whose names start with `drop`, resize/rename some,
    and add boxes: add = [(group, name, lo, hi, color key)]."""
    import base64
    import io
    m = json.load(open(src))
    t = m["textures"][0]
    head, data = t["source"].split(",", 1)
    im = Image.open(io.BytesIO(base64.b64decode(data))).convert("RGBA")
    old = im.copy()
    free = [(x, y) for y in range(0, 16, 2) for x in range(0, 16, 2)
            if all(im.getpixel((x + dx, y + dy))[3] == 0 for dx in (0, 1) for dy in (0, 1))]
    uv = {}
    for (k, c), (x, y) in zip(colors.items(), free):
        for dx in (0, 1):
            for dy in (0, 1):
                im.putpixel((x + dx, y + dy), (*c, 255))
        uv[k] = [x + 1, y + 1]
    assert len(uv) == len(colors), "palette full"
    buf = io.BytesIO()
    im.save(buf, "PNG")
    t["source"] = head + "," + base64.b64encode(buf.getvalue()).decode()
    m["name"] = name

    def paint(e, key):
        u = uv[key]
        for f in e["faces"].values():
            if e.get("type") == "mesh":
                f["uv"] = {k: u for k in f["uv"]}
            else:
                f["uv"] = [u[0] - 0.5, u[1] - 0.5, u[0] + 0.5, u[1] + 0.5]

    gone = set()
    for e in m["elements"]:
        if e["name"].startswith(drop):
            gone.add(e["uuid"])
            continue
        f = next(iter(e["faces"].values()))["uv"]
        u, v = f[:2] if isinstance(f, list) else next(iter(f.values()))
        c = old.getpixel((int(u), int(v)))[:3]
        key = next((k for n, k in recolor if isinstance(n, str) and e["name"].startswith(n)), None) or recolor_by_color(recolor, c)
        if key:
            paint(e, key)
        for n, lo, hi in resize:
            if e["name"] == n:
                e["from"], e["to"] = list(lo), list(hi)
        for a, b in rename:
            if e["name"] == a:
                e["name"] = b
    gname = {g["uuid"]: g["name"] for g in m["groups"]}
    new = {}
    for g, n, lo, hi, key in add:
        assert g in gname.values(), g
        new.setdefault(g, []).append({"name": n, "type": "cube", "uuid": SD.uid(), "from": list(lo), "to": list(hi),
                                      "origin": [0, 0, 0], "rotation": [0, 0, 0], "color": 0, "autouv": 0,
                                      "faces": {k: {"uv": [uv[key][0] - 0.5, uv[key][1] - 0.5, uv[key][0] + 0.5, uv[key][1] + 0.5],
                                                    "texture": 0} for k in ("north", "east", "south", "west", "up", "down")}})

    def fix(nodes):
        out = []
        for n in nodes:
            if isinstance(n, dict):
                n["children"] = fix(n["children"]) + [e["uuid"] for e in new.get(gname[n["uuid"]], [])]
                out.append(n)
            elif n not in gone:
                out.append(n)
        return out
    m["outliner"] = fix(m["outliner"])
    m["elements"] = [e for e in m["elements"] if e["uuid"] not in gone] + [e for v in new.values() for e in v]
    return m


def recolor_by_color(recolor, c):
    return next((k for n, k in recolor if n == c), None)


SADDLE_COLORS = {"blanket": BLANKET, "hem": HEM, "seat": SEAT, "tan": TAN, "gold": GOLD}


def saddle_boxes(half, y_top, y_hem, z0, z1, seat_half, k=10):
    """saddle() in Blockbench units, for the reskins."""
    zm, gy = (z0 + z1) / 2, (y_hem + 6 + y_top) / 2
    out = [("root", "Blanket", (-half, y_hem + 6, z0), (half, y_top, z1), "blanket"),
           ("root", "Hem", (-half - 0.5, y_hem, z0 - 0.5), (half + 0.5, y_hem + 6, z1 + 0.5), "hem"),
           ("root", "Seat", (-seat_half, y_top, z0 + 5), (seat_half, y_top + 6, z1 - 5), "seat"),
           ("root", "Pommel", (-8, y_top, z0 + 2), (8, y_top + 15, z0 + 9), "tan"),
           ("root", "Cantle", (-seat_half, y_top + 6, z1 - 11), (seat_half, y_top + 12, z1 - 4), "tan")]
    for side, sx in (("L", -1), ("R", 1)):
        xa, xb = sorted((sx * half, sx * (half + 0.5)))
        out.append(("root", "Gem" + side, (xa, gy - 6, zm - 6), (xb, gy + 6, zm + 6), "gold"))
    return out


def mammoth_reskin():
    src = os.path.join(A.ROOT, "designs", "godlands", "WarElephant.bbmodel")
    colors = dict(coat=COAT, coat_dark=COAT_DARK, speck=SPECK, tusk=TUSK, tip=TRUNK_TIP, nail=NAIL, **SADDLE_COLORS)
    recolor = [("Head", "coat_dark"), ("Trunk", "coat_dark"), ("Ear", "coat_dark"), ("Tusk", "tusk"),
               ((156, 152, 166), "coat"), ((60, 56, 64), "coat_dark"), ((226, 218, 198), "nail")]
    drop = ("HeadPlate", "HeadRidge", "BackPlate", "BackTrim", "Skirt", "Spine", "SideSpike", "EarLLobe", "EarRLobe")
    # small mammoth ears (the elephant's are huge)
    resize = [("EarL", (-19, 58, -48), (-16, 74, -34)), ("EarR", (16, 58, -48), (19, 74, -34))]
    add = [("neck", "Crown", (-14, 82, -62), (14, 88, -38), "coat_dark"),
           ("root", "Hump", (-20, 76, -30), (20, 82, -8), "coat"),
           ("neck", "TrunkTip", (-5.5, 22, -84), (5.5, 30, -76), "tip")]
    for side, sx in (("L", -1), ("R", 1)):
        xa, xb = sorted((sx * 22, sx * 22.5))
        for i, (y, z) in enumerate(((62, 28), (40, -22), (36, 30))):
            add.append(("root", f"Speck{i}{side}", (xa, y, z), (xb, y + 6, z + 6), "speck"))
        xa, xb = sorted((sx * 16, sx * 16.5))
        add.append(("neck", "Speck3" + side, (xa, 56, -48), (xb, 62, -42), "speck"))
    add += saddle_boxes(22.5, 77, 50, -6, 30, 13)
    # the War Elephant has two elements named TuskL and EarL: name the right ones properly
    m = reskin(src, "Mammoth", colors, recolor, drop, add, resize)
    for e in m["elements"]:
        if e["name"] in ("TuskL", "EarL", "TuskTipL") and e.get("from", [0])[0] > 0:
            e["name"] = e["name"][:-1] + "R"
    return m


def hula_reskin():
    src = os.path.join(A.ROOT, "designs", "volcano", "Firebird.bbmodel")
    colors = dict(hide=HIDE, hide_dark=HIDE_DARK, hide_light=HIDE_LIGHT, antler=ANTLER, antler_tip=ANTLER_TIP,
                  hoof=HOOF, claw=(170, 172, 176), white=A.EYE_WHITE, **SADDLE_COLORS)
    recolor = [("Thigh", "hide_dark"), ("Shin", "hide_light"), ("Heel", "hoof"), ("Toe", "hoof"), ("Claw", "claw"),
               ("Belly", "hide_dark"), ("Neck", "hide_dark"), ("Eye", "white"),
               ("Tail1", "hide_dark"), ((255, 128, 32), "hide")]
    drop = ("Wing", "Tail0", "Tail2", "Spike")  # keeps the Firebird's beak, jaw, teeth and brows (QM)
    resize = [("Tail1", (-5, 76, 28), (5, 108, 38))]  # one tail sticking straight up
    rename = []
    add = []
    for side, sx in (("L", -1), ("R", 1)):
        xa, xb = sorted((sx * 4, sx * 10))
        add.append(("neck", "Antler" + side, (xa, 126, -46), (xb, 136, -40), "antler"))
        add.append(("neck", "AntlerTip" + side, (xa, 136, -44), (xb, 146, -34), "antler_tip"))
        ea, eb = sorted((sx * 14, sx * 22))
        add.append(("neck", "Ear" + side, (ea, 114, -40), (eb, 121, -24), "antler"))
        add.append(("neck", "EarTip" + side, (ea, 114, -24), (eb, 121, -17), "antler_tip"))
        add.append(("root", "Speck" + side, (sx * 6 - 4, 86, -6 + 18 * (sx > 0)), (sx * 6 + 4, 86.5, 2 + 18 * (sx > 0)), "hide_light"))
    add += saddle_boxes(18.5, 87, 64, -14, 18, 12)
    return reskin(src, "Hula", colors, recolor, drop, add, resize, rename)


ANIMALS = (mammoth, snail, hula, tortoise)
RESKINS = {"Mammoth": mammoth_reskin, "Hula": hula_reskin}

S = 420
Q34 = dict(eye=(-30, 17, -28), target=(0, 5, 6), W=S, H=S, fov=34)
FRONT = dict(eye=(-6, 8, -26), target=(0, 4.5, 6), W=S, H=S, fov=34)
SIDE = dict(eye=(-40, 6, 6), target=(0, 5, 6), W=S, H=S, fov=34)
BACK = dict(eye=(20, 14, 34), target=(0, 4.5, 6), W=S, H=S, fov=34)


def framed(parts, cam, z_mid):
    """The camera moved along z so the animal's middle is where the drafts' middle was."""
    dz = z_mid - cam["target"][2]
    return dict(cam, eye=(cam["eye"][0], cam["eye"][1], cam["eye"][2] + dz),
                target=(cam["target"][0], cam["target"][1], cam["target"][2] + dz))


def z_mid(parts):
    zs = []
    for p in parts:
        if p.shape == "Poly":
            zs += [v[2] for q in p.polys for v in q]
        else:
            zs += [p.cf[2, 3] - p.size[2] / 2, p.cf[2, 3] + p.size[2] / 2]
    return (min(zs) + max(zs)) / 2


def tiles(parts, cams):
    im = Image.new("RGB", (S * len(cams), S))
    zm = z_mid(parts)
    for i, c in enumerate(cams):
        im.paste(render(parts, **framed(parts, c, zm)), (S * i, 0))
    return im


def main(out=os.path.join(A.ROOT, "designs", "world3"), shots="/mnt/project-files/world3/renders"):
    os.makedirs(out, exist_ok=True)
    os.makedirs(shots, exist_ok=True)
    horse = pose(json.load(open(os.path.join(A.ROOT, "designs", "animals", "Horse.bbmodel"))), None, 0)
    rows, names = [], []
    for fn in ANIMALS:
        a = fn()
        if a.name in RESKINS:
            model = RESKINS[a.name]()
            parts = SD.posed(model)
        else:
            model, _ = write_bbmodel(a.parts, a.name, None, bones=a.bones())
            model["lasso_meta"] = a.meta
            parts = a.parts
        json.dump(model, open(os.path.join(out, a.name + ".bbmodel"), "w"), separators=(",", ":"))
        print(f"{a.name}: {len(model['elements'])} parts")
        im = A.label(tiles(parts, (Q34, FRONT, SIDE, BACK)), [a.name, "Front", "Side", "Back"])
        im.save(os.path.join(shots, a.name + ".png"))
        rows.append(parts)
        names.append(a.name)
    # one lineup: horse for size, then the four, 3/4 view on top and side view below
    lineup = Image.new("RGB", (S * 5, S * 2))
    for i, parts in enumerate([horse] + rows):
        zm = z_mid(parts)
        lineup.paste(render(parts, **framed(parts, Q34, zm)), (S * i, 0))
        lineup.paste(render(parts, **framed(parts, SIDE, zm)), (S * i, S))
    A.label(lineup, ["Horse (for size)"] + names).save(os.path.join(shots, "Companions_lineup.png"))


if __name__ == "__main__":
    main(*sys.argv[1:])
