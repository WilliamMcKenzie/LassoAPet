"""Zone 1 animals and their eggs, on QM's reworked horse rig.

Run: python3 tools/animal_designs.py [out_dir]

  Horse    Common     QM's Horse8 edit (hind legs kick back, back stripe) + leap gallop
  Pinto    Uncommon   the horse variant: white with brown patches
  Pig      Uncommon   round and pink, head on the body's front, curly tail
  Fish     Rare       big blue fish, no legs: flops along
  Rhino    Epic       bulky and low, head out front, two horns
  Unicorn  Legendary  white horse, rainbow mane and tail, gold horn and hooves

Rig rules (QM's): every block flush and axis-aligned, and every joint only
bends one way from rest so hidden faces never show:
  front legs  swing forward  (pivot top-back edge,  +X)
  hind legs   kick backward  (pivot top-front edge, -X)
  neck        bends forward  (pivot at the body's front-top edge, -X)
  tail        lifts back     (pivot at its top-front edge, -X)
  ears        fold back      (pivot at their front-bottom edge, +X)
The fish has its own bones: head and tail curl up from the body (a flop).

Animations: idle and walk are QM's (read from Horse8); gallop is a leap:
front legs reach forward and hind legs back while the animal is in the air.
"""

import copy
import json
import os
import sys
import uuid

import numpy as np
from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, os.path.dirname(__file__))
from partlib import Part, T, Rx, Ry, Rz, render, write_bbmodel  # noqa: E402
from horse_rig import pose, write_animations, num  # noqa: E402
import egg_designs as E  # noqa: E402

ROOT = os.path.join(os.path.dirname(__file__), "..")
QM_HORSE = os.path.join(ROOT, "designs", "horses", "Horse8_QM.bbmodel")
HORSE_EGG = os.path.join(ROOT, "designs", "eggs", "Egg6_PonyOcto.bbmodel")

WHITE = (248, 248, 244)
EYE_WHITE = (255, 255, 255)
PUPIL = (30, 30, 45)
PINK = (242, 150, 192)
HOOF = (74, 78, 102)
ORANGE = (226, 130, 50)
MANE = (92, 54, 34)
RAINBOW = [(236, 72, 72), (248, 150, 50), (250, 214, 60), (96, 200, 90), (70, 150, 236), (160, 100, 220)]

PLATE = 0.05  # how far patches and eyes stand off a face
LEGS = ("FL", "FR", "HL", "HR")


# ---------------------------------------------------------------- animations

def read_tracks(model, name):
    """An animation from a .bbmodel as (length, {bone: [track]}) for write_animations."""
    anim = next(a for a in model["animations"] if a["name"] == name)
    tracks = {}
    for a in anim["animators"].values():
        chans = {}
        for k in sorted(a.get("keyframes", []), key=lambda k: k["time"]):
            chans.setdefault(k["channel"], []).append(k)
        for ch, kfs in chans.items():
            tracks.setdefault(a["name"], []).append({
                "channel": ch, "interp": kfs[0]["interpolation"],
                "keys": [(k["time"], tuple(num(k["data_points"][0][c]) for c in "xyz")) for k in kfs]})
    return anim["length"], tracks


def rot_x(keys, interp="linear"):
    return {"channel": "rotation", "interp": interp, "keys": [(t, (v, 0, 0)) for t, v in keys]}


def rot_z(keys, interp="linear"):
    return {"channel": "rotation", "interp": interp, "keys": [(t, (0, 0, v)) for t, v in keys]}


def pos_y(keys, interp="catmullrom"):
    return {"channel": "position", "interp": interp, "keys": [(t, (0, v, 0)) for t, v in keys]}


def at(L, keys):
    """Keys given as (fraction of the loop, value) -> (seconds, value)."""
    return [(round(u * L, 4), v) for u, v in keys]


def leap(L=0.8, height=25, spread=55, pitch=8):
    """One leap per loop. u = 0 is mid-stride on the ground (squashed); takeoff
    at 0.15, top of the arc at 0.5, touchdown at 0.85. In the air the front legs
    reach forward and the hind legs back; on the ground they're straight.
    height is in Blockbench units (10 = 1 stud), angles in degrees."""
    h = height
    legs_front = at(L, [(0, 0), (0.15, 0), (0.27, spread), (0.73, spread), (0.85, 0), (1, 0)])
    legs_hind = [(t, -v) for t, v in legs_front]
    # hind legs leave a touch later and land a touch earlier than the front
    return (L, {
        "root": [
            # lifted a little at takeoff and touchdown so the pitched body keeps its hooves out of the ground
            pos_y(at(L, [(0, 0), (0.15, 5), (0.3, 0.67 * h + 2), (0.5, h), (0.7, 0.67 * h + 2), (0.85, 5), (1, 0)])),
            {"channel": "rotation", "interp": "catmullrom",
             "keys": [(t, (v, 0, 0)) for t, v in at(L, [(0, 0), (0.15, pitch), (0.5, 0), (0.85, -pitch), (1, 0)])]},
        ],
        "LegFL": [rot_x(legs_front)],
        "LegFR": [rot_x(at(L, [(0, 0), (0.17, 0), (0.29, spread), (0.75, spread), (0.87, 0), (1, 0)]))],
        "LegHL": [rot_x(legs_hind)],
        "LegHR": [rot_x([(t, -v) for t, v in at(L, [(0, 0), (0.13, 0), (0.25, spread), (0.71, spread), (0.83, 0), (1, 0)])])],
        "neck": [rot_x(at(L, [(0, -12), (0.2, -3), (0.5, -2), (0.8, -6), (1, -12)]), "catmullrom")],
        "Tail": [rot_x(at(L, [(0, -20), (0.3, -55), (0.6, -60), (0.9, -30), (1, -20)]), "catmullrom")],
        "EarL": [rot_x([(0, 35), (L, 35)])],
        "EarR": [rot_x([(0, 35), (L, 35)])],
    })


GALLOPS = {"A": dict(L=0.8, height=25, spread=55), "B": dict(L=0.55, height=12, spread=40)}


def quad_animations():
    qm = json.load(open(QM_HORSE))
    return {"idle": read_tracks(qm, "idle"), "walk": read_tracks(qm, "walk"), "gallop": leap(**GALLOPS["A"])}


def flop(L, height, curl, air_curl, pitch, fin):
    """Fish travel: curled up on the ground (head and tail lifted), snaps
    straight to launch, flies, lands and curls again. Head lifts with +X,
    tail with -X; pectoral fins flap up (L with -Z, R with +Z)."""
    head = at(L, [(0, curl), (0.12, curl), (0.18, 2), (0.5, air_curl), (0.82, 2), (0.88, curl * 0.6), (1, curl)])
    fin_keys = at(L, [(0, 0), (0.15, fin), (0.3, 0), (0.45, fin), (0.6, 0), (1, 0)])
    return (L, {
        "root": [
            pos_y(at(L, [(0, 0), (0.15, 0), (0.3, 0.67 * height), (0.5, height), (0.7, 0.67 * height), (0.85, 0), (1, 0)])),
            {"channel": "rotation", "interp": "catmullrom",
             "keys": [(t, (v, 0, 0)) for t, v in at(L, [(0, 0), (0.15, pitch), (0.5, 0), (0.85, -pitch), (1, 0)])]},
        ],
        "neck": [rot_x(head)],
        "Tail": [rot_x([(t, -v) for t, v in head])],
        "FinL": [rot_z([(t, -v) for t, v in fin_keys])],
        "FinR": [rot_z(fin_keys)],
    })


def fish_animations():
    L = 2.4
    idle = (L, {
        "neck": [rot_x([(0, 2), (1.2, 6), (L, 2)], "catmullrom")],
        "Tail": [rot_x([(0, -2), (0.9, -10), (1.1, -4), (1.3, -10), (L, -2)], "catmullrom")],
        "FinL": [rot_z([(0, 0), (0.6, -25), (1.2, 0), (1.8, -25), (L, 0)], "catmullrom")],
        "FinR": [rot_z([(0, 0), (0.6, 25), (1.2, 0), (1.8, 25), (L, 0)], "catmullrom")],
    })
    return {"idle": idle, "walk": flop(0.9, 10, 16, 4, 5, 30), "gallop": flop(0.8, 30, 28, 8, 10, 45)}


# ---------------------------------------------------------------- building blocks

class Animal:
    def __init__(self, name, rarity):
        self.name, self.rarity = name, rarity
        self.parts = []
        self.pivots = {}
        self.meta = {}
        self.bone_order = [("root", None), ("neck", "root"), ("EarL", "neck"), ("EarR", "neck"), ("Tail", "root")]
        self.bone_order += [("Leg" + leg, "root") for leg in LEGS]
        self.animations = quad_animations

    def box(self, name, lo, hi, color, bone):
        lo, hi = np.array(lo, float), np.array(hi, float)
        plain = name.startswith(("Eye", "Pupil", "Nostril", "Plain", "Mouth"))
        p = Part(name, hi - lo, T(*((lo + hi) / 2)), color, plain=plain)
        p.bone = bone
        self.parts.append(p)
        return p

    def wedge(self, name, lo, hi, color, bone, orient="up_front"):
        """up_front: tall at the back, slope faces forward (a plain WedgePart).
        up_back: tall at the front. down_back: flat top and front, slope faces
        down and back. down_front: flat top and back, slope faces down and forward."""
        lo, hi = np.array(lo, float), np.array(hi, float)
        R = {"up_front": np.eye(4), "up_back": Ry(180), "down_back": Rx(180), "down_front": Rz(180)}[orient]
        p = Part(name, hi - lo, T(*((lo + hi) / 2)) @ R, color, "Wedge")
        p.bone = bone
        self.parts.append(p)
        return p

    def tri(self, name, pts, z0, z1, color, bone):
        """Right-triangle prism, (x, y) points with the right angle first, extruded along z."""
        faces = [[(x, y, z0) for x, y in pts], [(x, y, z1) for x, y in pts[::-1]]]
        for a, b in ((0, 1), (1, 2), (2, 0)):
            faces.append([(pts[a][0], pts[a][1], z0), (pts[a][0], pts[a][1], z1),
                          (pts[b][0], pts[b][1], z1), (pts[b][0], pts[b][1], z0)])
        plain = "In" in name
        p = Part(name, (1, 1, 1), np.eye(4), color, "Poly", plain)
        p.polys = [np.array(f, float) for f in faces]
        p.bone = bone
        self.parts.append(p)
        return p

    def body(self, x, y0, y1, z0, z1, color, bands=None):
        """Body block; bands = [(z0, z1, color)] cut it into flush slices."""
        self.dims = dict(x=x, y0=y0, y1=y1, z0=z0, z1=z1)
        self.pivots["root"] = (0, (y0 + y1) / 2, (z0 + z1) / 2)
        if not bands:
            return self.box("Body", (-x, y0, z0), (x, y1, z1), color, "root")
        for i, (a, b, c) in enumerate(bands):
            self.box(f"Body{i + 1}", (-x, y0, a), (x, y1, b), c, "root")

    def legs(self, xin, xout, depth, hoof_h, color, hoof):
        """Four legs under the body, flush with its front, back and sides.
        Front legs pivot on their top-back edge (swing forward), hind legs on
        their top-front edge (kick back)."""
        d = self.dims
        y0 = d["y0"]
        for leg in LEGS:
            sx = -1 if leg[1] == "L" else 1
            front = leg[0] == "F"
            z0 = d["z0"] + 0.001 if front else d["z1"] - 0.001 - depth
            z1 = z0 + depth
            xa, xb = sorted((sx * xin, sx * xout))
            name = "Leg" + leg
            self.box(name, (xa, hoof_h, z0), (xb, y0, z1), color, name)
            self.box("Hoof" + leg, (xa, 0, z0), (xb, hoof_h, z1), hoof, name)
            self.pivots[name] = ((xa + xb) / 2, y0 - 0.025, z1 - 0.05 if front else z0 + 0.05)

    def tail(self, w, y_top, y_bot, depth, color, tip_color=None, tip_h=0.8, bands=None):
        d = self.dims
        z0, z1 = d["z1"], d["z1"] + depth
        tip = y_bot + tip_h
        if bands:
            for i, (a, b, c) in enumerate(bands):
                self.box(f"Tail{i + 1}" if i else "Tail", (-w, a, z0), (w, b, z1), c, "Tail")
        else:
            self.box("Tail", (-w, tip, z0), (w, y_top, z1), color, "Tail")
        self.wedge("TailTip", (-w, y_bot, z0), (w, tip, z1), tip_color or color, "Tail", "down_back")
        self.pivots["Tail"] = (0, y_top, z0)

    def eyes(self, x, y0, y1, z0, z1, bone="neck"):
        """White plates on both sides of the head, pupils looking forward."""
        py1 = y0 + (y1 - y0) * 0.7
        pz1 = z0 + (z1 - z0) * 0.5
        for side, sx in (("L", -1), ("R", 1)):
            xa, xb = sorted((sx * x, sx * (x + PLATE)))
            self.box("Eye" + side, (xa, y0, z0), (xb, y1, z1), EYE_WHITE, bone)
            pa, pb = sorted((sx * x, sx * (x + PLATE + 0.03)))
            self.box("Pupil" + side, (pa, y0 + (y1 - y0) * 0.1, z0), (pb, py1, pz1), PUPIL, bone)

    def upright_ears(self, cx, base, z0, z1, half, h, color, inner=PINK):
        """Horse ears: two right-triangle halves each, inner plate on the front."""
        for side, sx in (("L", -1), ("R", 1)):
            c = sx * cx
            bone = "Ear" + side
            for half_name, dx in (("A", -1), ("B", 1)):
                self.tri(f"Ear{side}{half_name}", [(c, base), (c + dx * half, base), (c, base + h)], z0, z1, color, bone)
                self.tri(f"Ear{side}In{half_name}", [(c, base + 0.08), (c + dx * half * 0.55, base + 0.08), (c, base + h * 0.69)],
                         z0 - 0.06, z0, inner, bone)
            self.pivots[bone] = (c, base, z0)

    def patch(self, name, face, a0, a1, b0, b1, color, bone="root", box=None):
        """Thin plate on a block face. face in L, R (a = z, b = y), T (a = x, b = z)."""
        (x0, y0, z0), (x1, y1, z1) = box
        if face == "L":
            return self.box(name, (x0 - PLATE, b0, a0), (x0, b1, a1), color, bone)
        if face == "R":
            return self.box(name, (x1, b0, a0), (x1 + PLATE, b1, a1), color, bone)
        if face == "T":
            return self.box(name, (a0, y1, b0), (a1, y1 + PLATE, b1), color, bone)
        raise ValueError(face)

    def bones(self):
        return [(n, p, self.pivots[n]) for n, p in self.bone_order]

    def scale(self, k):
        """Grow the whole animal about the ground origin."""
        for p in self.parts:
            if p.shape == "Poly":
                p.polys = [q * k for q in p.polys]
            else:
                p.size = p.size * k
                p.cf[:3, 3] *= k
        self.pivots = {n: tuple(np.array(v) * k) for n, v in self.pivots.items()}
        self.meta = {"seat": tuple(np.array(self.meta["seat"]) * k),
                     "neck_loop": {"center": tuple(np.array(self.meta["neck_loop"]["center"]) * k),
                                   "radius": self.meta["neck_loop"]["radius"] * k}}

    def remove(self, name):
        self.parts = [p for p in self.parts if p.name != name]


def horse_body(a, coat=ORANGE, mane=MANE, hoof=HOOF, ear_inner=PINK, cap=True, stripe=True, tail=True):
    """QM's Horse8 layout: the same numbers, rebuilt as parts so it can be recoloured.
    The mane is a strip down the back of the head (Cap) and a narrow wedge behind
    the neck; a stripe runs along the back into the tail."""
    a.body(1.6, 3.5, 6.5, -2.7, 3.3, coat)
    a.legs(0.5, 1.6, 1.1, 0.8, coat, hoof)
    a.box("Neck", (-0.9, 5.1, -2.699), (0.9, 8.3, -1.099), coat, "neck")
    a.box("Head", (-1.1, 8.3, -3.9), (1.1, 10.5, -1.1), coat, "neck")
    a.box("Snout", (-1.1, 8.3, -5.1), (1.1, 9.7, -3.9), coat, "neck")
    a.wedge("Bridge", (-1.1, 9.7, -5.1), (1.1, 10.5, -3.9), coat, "neck")
    for side, sx in (("L", -1), ("R", 1)):
        xa, xb = sorted((sx * 0.3, sx * 0.8))
        a.box("Nostril" + side, (xa, 8.9, -5.15), (xb, 9.2, -5.1), (70, 44, 36), "neck")
    a.eyes(1.1, 9.1, 10.1, -3.5, -2.5)
    a.upright_ears(0.75, 10.5, -1.5, -1.1, 0.35, 1.2, coat, ear_inner)
    a.pivots["neck"] = (0, 6.444, -2.7835)
    if cap:
        a.wedge("Mane", (-0.4, 5.3, -1.1), (0.4, 9.5, 0.1), mane, "neck", "up_back")
        a.box("Cap", (-0.4, 7.1, -2.3), (0.4, 11.1, -0.6), mane, "neck")
    if stripe:
        a.box("Stripe", (-0.4, 6.5, -1.8), (0.4, 7.2, 3.3), mane, "root")
    if tail:
        a.box("Tail", (-0.4, 4.3, 3.3), (0.4, 7.2, 4.1), mane, "Tail")
        a.wedge("TailTip", (-0.4, 3.5, 3.3), (0.4, 4.3, 4.1), mane, "Tail", "down_back")
    a.pivots["Tail"] = (0, 7.2, 3.3)
    a.meta = {"seat": (0, 7.3, 1), "neck_loop": {"center": (0, 7.4, -1.9), "radius": 1.35}}


# ---------------------------------------------------------------- the horse (QM's file)

def qm_horse(gallop="A"):
    """QM's Horse8 with two fixes and the leap gallop:
      - the tail block ran along the back into the tail; the part on the back is
        now its own Stripe on the root, so lifting the tail doesn't sink it into the body
      - the tail pivots on its top-front edge; LegHL's pivot matches LegHR's"""
    m = json.load(open(QM_HORSE))
    groups = {g["name"]: g for g in m["groups"]}
    tail = next(e for e in m["elements"] if e["name"] == "Tail")
    stripe = copy.deepcopy(tail)
    stripe.update(name="Stripe", uuid=str(uuid.uuid4()), to=[4, 72, 33])
    stripe["from"] = [-4, 65, -18]
    stripe["origin"] = [0, 68.5, 7.5]
    tail["from"] = [-4, 43, 33]
    tail["origin"] = [0, 57.5, 37]
    m["elements"].append(stripe)
    root = m["outliner"][0]
    body = next(e for e in m["elements"] if e["name"] == "Body")
    i = root["children"].index(body["uuid"])
    root["children"].insert(i + 1, stripe["uuid"])
    groups["Tail"]["origin"] = [0, 72, 33]
    groups["LegHL"]["origin"][2] = groups["LegHR"]["origin"][2]
    anims = {"idle": read_tracks(m, "idle"), "walk": read_tracks(m, "walk"), "gallop": leap(**GALLOPS[gallop])}
    write_animations(m, groups, anims)
    m["name"] = "Horse"
    return m


# ---------------------------------------------------------------- the others

def pinto():
    """The horse variant: white coat with big brown patches, dark mane."""
    a = Animal("Pinto", "Uncommon")
    brown, dark = (150, 84, 46), (70, 42, 30)
    horse_body(a, WHITE, dark, (60, 60, 72))
    body = ((-1.6, 3.5, -2.7), (1.6, 6.5, 3.3))
    for name, face, a0, a1, b0, b1 in (
            ("SpotL1", "L", -2.7, -0.7, 4.5, 6.5), ("SpotL2", "L", 0.8, 3.3, 3.5, 5.5),
            ("SpotR1", "R", -1.7, 0.8, 4.0, 6.5), ("SpotR2", "R", 2.0, 3.3, 5.0, 6.5),
            ("SpotT1", "T", -1.6, -0.4, 1.3, 3.3), ("SpotT2", "T", 0.4, 1.6, -2.7, -0.2)):
        a.patch(name, face, a0, a1, b0, b1, brown, box=body)
    # brown head and neck, white muzzle with a blaze running up the forehead
    for p in a.parts:
        if p.name in ("Head", "Neck"):
            p.color = brown
    a.box("Blaze", (-0.35, 10.5, -3.9), (0.35, 10.55, -2.3), WHITE, "neck")
    for p in a.parts:
        if p.name.startswith("Ear") and "In" not in p.name:
            p.color = brown
    return a


def pig():
    a = Animal("Pig", "Uncommon")
    pink, snout, hoof, dark = (246, 164, 184), (250, 196, 208), (176, 96, 116), (196, 96, 126)
    a.body(1.8, 2.2, 5.6, -2.8, 3.0, pink)
    a.legs(0.8, 1.8, 1.0, 0.5, pink, hoof)
    # the head sits on the body's front, top flush, a big snout on its face
    a.box("Head", (-1.5, 2.8, -5.0), (1.5, 5.6, -2.799), pink, "neck")
    a.box("Snout", (-0.8, 3.2, -5.6), (0.8, 4.4, -5.0), snout, "neck")
    for side, sx in (("L", -1), ("R", 1)):
        xa, xb = sorted((sx * 0.2, sx * 0.55))
        a.box("Nostril" + side, (xa, 3.55, -5.65), (xb, 4.05, -5.6), dark, "neck")
        # eyes on the face, above the snout
        xa, xb = sorted((sx * 0.55, sx * 1.15))
        a.box("Eye" + side, (xa, 4.5, -5.05), (xb, 5.3, -5.0), EYE_WHITE, "neck")
        pa, pb = sorted((sx * 0.55, sx * 0.9))
        a.box("Pupil" + side, (pa, 4.55, -5.08), (pb, 5.0, -5.05), PUPIL, "neck")
    a.upright_ears(0.95, 5.6, -4.0, -3.6, 0.45, 0.9, pink, dark)
    a.pivots["neck"] = (0, 5.55, -2.85)
    # curly tail: out, up, over
    a.box("Tail", (-0.2, 4.6, 3.0), (0.2, 5.0, 3.6), pink, "Tail")
    a.box("Tail2", (-0.2, 5.0, 3.2), (0.2, 5.6, 3.6), pink, "Tail")
    a.box("Tail3", (-0.2, 5.6, 3.0), (0.2, 6.0, 3.6), pink, "Tail")
    a.pivots["Tail"] = (0, 6.0, 3.0)
    a.meta = {"seat": (0, 6.4, 0.4), "neck_loop": {"center": (0, 4.2, -3.9), "radius": 1.9}}
    return a


def fish():
    """Big blue fish. No legs: the body is on the root, the head and the tail
    section curl up off the ground from the body's bottom edges."""
    a = Animal("Fish", "Rare")
    blue, dark, belly, mouth = (60, 132, 232), (36, 88, 184), (222, 240, 255), (28, 40, 84)
    a.bone_order = [("root", None), ("neck", "root"), ("Tail", "root"), ("FinL", "root"), ("FinR", "root")]
    a.animations = fish_animations
    y0 = 0.1
    # body: blue back, pale belly band
    a.box("Belly", (-1.4, y0, -2.0), (1.4, 1.3, 2.0), belly, "root")
    a.box("Body", (-1.4, 1.3, -2.0), (1.4, 4.0, 2.0), blue, "root")
    a.dims = dict(x=1.4, y0=y0, y1=4.0, z0=-2.0, z1=2.0)
    a.pivots["root"] = (0, 2.0, 0)
    # head (bone "neck" so the lasso and the rig code find it)
    a.box("HeadBelly", (-1.2, y0, -4.4), (1.2, 1.3, -2.0), belly, "neck")
    a.box("Head", (-1.2, 1.3, -4.4), (1.2, 3.6, -2.0), blue, "neck")
    a.box("Snout", (-0.9, 0.5, -5.2), (0.9, 2.9, -4.4), blue, "neck")
    a.box("Mouth", (-0.7, 1.2, -5.25), (0.7, 1.45, -5.2), mouth, "neck")
    a.eyes(1.2, 2.0, 3.1, -4.1, -3.0)
    a.pivots["neck"] = (0, y0, -2.0)
    # tail section with a fan tail fin and the dorsal fin on top
    a.box("TailBelly", (-1.0, 0.5, 2.0), (1.0, 1.3, 4.4), belly, "Tail")
    a.box("Tail", (-1.0, 1.3, 2.0), (1.0, 3.4, 4.4), blue, "Tail")
    a.box("FinRoot", (-0.25, 1.4, 4.4), (0.25, 2.3, 4.9), dark, "Tail")
    a.wedge("FinTop", (-0.25, 2.3, 4.4), (0.25, 4.3, 6.0), dark, "Tail")
    a.wedge("FinBottom", (-0.25, 0.4, 4.4), (0.25, 1.4, 5.6), dark, "Tail", "down_front")
    a.wedge("Dorsal", (-0.25, 3.4, 2.0), (0.25, 4.8, 3.9), dark, "Tail", "up_back")
    a.pivots["Tail"] = (0, y0, 2.0)
    # pectoral fins flap up from their inner bottom edge
    for side, sx in (("L", -1), ("R", 1)):
        xa, xb = sorted((sx * 1.4, sx * 2.3))
        a.box("Fin" + side, (xa, 1.0, -1.7), (xb, 1.3, -0.5), dark, "Fin" + side)
        a.pivots["Fin" + side] = (sx * 1.4, 1.0, -1.1)
    a.meta = {"seat": (0, 4.8, -0.4), "neck_loop": {"center": (0, 2.2, -2.6), "radius": 1.9}}
    a.scale(1.35)  # a big fish: about as long as the horse
    return a


def rhino():
    a = Animal("Rhino", "Epic")
    grey, dark, horn, hoof = (150, 156, 170), (112, 118, 134), (240, 232, 208), (84, 88, 102)
    bands = [(-3.2, -1.2, grey), (-1.2, -0.7, dark), (-0.7, 1.8, grey), (1.8, 2.3, dark), (2.3, 3.6, grey)]
    a.body(2.0, 2.8, 6.6, -3.2, 3.6, grey, bands)
    a.legs(0.6, 2.0, 1.4, 0.6, grey, hoof)
    a.box("Neck", (-1.5, 3.6, -4.2), (1.5, 6.2, -3.199), grey, "neck")
    a.box("Head", (-1.2, 3.4, -6.6), (1.2, 5.6, -4.2), grey, "neck")
    a.box("Snout", (-1.2, 3.4, -7.4), (1.2, 4.8, -6.6), grey, "neck")
    a.wedge("Bridge", (-1.2, 4.8, -7.4), (1.2, 5.6, -6.6), grey, "neck")
    for side, sx in (("L", -1), ("R", 1)):
        xa, xb = sorted((sx * 0.4, sx * 0.9))
        a.box("Nostril" + side, (xa, 3.9, -7.45), (xb, 4.2, -7.4), (60, 62, 74), "neck")
    a.box("HornBase", (-0.4, 5.6, -6.6), (0.4, 6.0, -5.6), horn, "neck")
    a.wedge("Horn", (-0.4, 6.0, -6.6), (0.4, 7.8, -5.6), horn, "neck")
    a.wedge("Horn2", (-0.3, 5.6, -5.2), (0.3, 6.6, -4.6), horn, "neck")
    a.eyes(1.2, 4.4, 5.2, -5.6, -4.8)
    a.upright_ears(0.95, 6.2, -3.9, -3.5, 0.35, 1.0, grey, (206, 150, 170))
    a.pivots["neck"] = (0, 6.2, -3.2)
    a.tail(0.3, 6.4, 4.0, 0.6, grey, dark, tip_h=0.8)
    a.meta = {"seat": (0, 7.4, 2.2), "neck_loop": {"center": (0, 5.2, -3.7), "radius": 1.9}}
    return a


def unicorn():
    a = Animal("Unicorn", "Legendary")
    white, gold = (252, 250, 255), (255, 200, 60)
    horse_body(a, white, RAINBOW[5], gold, PINK, cap=False, stripe=False, tail=False)
    # mane strip down the back of the head in rainbow bands, top to bottom
    for i, c in enumerate(RAINBOW):
        y1 = 11.1 - (4.0 / 6) * i
        a.box(f"Cap{i + 1}" if i else "Cap", (-0.4, y1 - 4.0 / 6, -2.3), (0.4, y1, -0.6), c, "neck")
    a.wedge("Mane", (-0.4, 5.3, -1.1), (0.4, 9.5, 0.1), RAINBOW[5], "neck", "up_back")
    # the back stripe and tail carry the rainbow on
    a.box("Stripe", (-0.4, 6.5, -1.8), (0.4, 7.2, 3.3), RAINBOW[5], "root")
    for i, c in enumerate(RAINBOW[:5]):
        y1 = 7.2 - 0.58 * i
        a.box(f"Tail{i + 1}" if i else "Tail", (-0.4, y1 - 0.58, 3.3), (0.4, y1, 4.1), c, "Tail")
    a.wedge("TailTip", (-0.4, 3.5, 3.3), (0.4, 4.3, 4.1), RAINBOW[5], "Tail", "down_back")
    for i, (w, y0, y1) in enumerate(((0.3, 10.5, 11.0), (0.2, 11.0, 11.6), (0.1, 11.6, 12.3))):
        a.box(f"Horn{i + 1}" if i else "Horn", (-w, y0, -3.3 - w), (w, y1, -3.3 + w), gold, "neck")
    return a


ANIMALS = [pinto, pig, fish, rhino, unicorn]


# ---------------------------------------------------------------- eggs

def octo_egg(colors, pieces=None, crack_layer=4):
    """Octo Stack egg like the horse's: 7 octagonal layers, black crack plates.
    colors: one per layer. pieces: {(layer, piece): color} to paint patches,
    piece in Mid, Front, Back, CornerLF, CornerRF, CornerLB, CornerRB."""
    egg = E.Egg()
    n = 7
    h = E.H / n
    crack = crack_layer * h
    widths = [E.snap(2 * E.radius((i + 0.5) * h)) for i in range(n)]
    for i in range(n):
        E.octo_layer(egg, i, i * h, (i + 1) * h, widths[i], colors[i], "top" if i >= crack_layer else "bottom")
    for (i, piece), c in (pieces or {}).items():
        for p in egg.parts:
            if p.name == f"L{i}{piece}":
                p.color = c
    inner = min(widths[crack_layer - 1], widths[crack_layer]) - 0.16
    E.octo_layer(egg, "InsideBottom", crack, crack + 0.02, inner, E.BLACK, "bottom")
    E.octo_layer(egg, "InsideTop", crack - 0.02, crack, inner, E.BLACK, "top")
    egg.widths, egg.h = widths, h
    return egg


def egg_block(egg, name, lo, hi, color, bone="top"):
    egg.block(name, lo, hi, color).bone = bone


def pony_ears(egg, color, inner, x0=0.35, h=0.7, dz=0.0):
    b = E.H - 0.05
    for side, sx in (("L", -1), ("R", 1)):
        c = sx * x0
        for half, d in (("A", -1), ("B", 1)):
            E.ear_half(egg, f"Ear{side}{half}", [(c, b), (c + d * 0.25, b), (c, b + h)], -0.15 + dz, 0.15 + dz, color)
            E.ear_half(egg, f"EarIn{side}{half}", [(c, b + 0.08), (c + d * 0.13, b + 0.08), (c, b + h * 0.64)],
                       -0.19 + dz, -0.15 + dz, inner)


def pinto_egg():
    brown, dark = (150, 84, 46), (70, 42, 30)
    egg = octo_egg([WHITE] * 7, {
        (1, "CornerLF"): brown, (2, "CornerLF"): brown, (2, "Front"): brown, (3, "CornerRB"): brown,
        (3, "Back"): brown, (4, "CornerRF"): brown, (5, "CornerRF"): brown, (5, "Mid"): brown, (6, "Back"): brown})
    pony_ears(egg, brown, PINK)
    egg_block(egg, "Tuft", (-0.15, E.H - 0.05, -0.05), (0.15, E.H + 0.3, 0.45), dark)
    return egg


def pig_egg():
    pink, snout, dark = (246, 164, 184), (250, 196, 208), (196, 96, 126)
    egg = octo_egg([snout, snout] + [pink] * 5)
    pony_ears(egg, pink, dark, x0=0.32, h=0.5)
    # snout on the front of the top shell
    front = -egg.widths[4] / 2
    y0, y1 = 4 * egg.h + 0.05, 5 * egg.h - 0.05
    egg_block(egg, "Snout", (-0.45, y0 - 0.05, front - 0.28), (0.45, y1 + 0.05, front), snout)
    for side, sx in (("L", -1), ("R", 1)):
        xa, xb = sorted((sx * 0.1, sx * 0.28))
        egg_block(egg, "Nostril" + side, (xa, y0 + 0.08, front - 0.31), (xb, y1 - 0.08, front - 0.28), dark)
    return egg


def fish_egg():
    blue, dark, belly = (60, 132, 232), (36, 88, 184), (222, 240, 255)
    egg = octo_egg([belly, belly] + [blue] * 5, {(3, "Mid"): dark, (5, "Front"): dark, (5, "Back"): dark})
    t = E.H - 0.05
    p = Part("Dorsal", (0.2, 0.7, 0.8), T(0, t + 0.35, 0.05) @ Ry(180), dark, "Wedge")
    p.bone = "top"
    egg.parts.append(p)
    # little side fins on the bottom shell
    y = 2 * egg.h
    w = egg.widths[2] / 2
    for side, sx in (("L", -1), ("R", 1)):
        xa, xb = sorted((sx * w, sx * (w + 0.35)))
        egg_block(egg, "Fin" + side, (xa, y, -0.3), (xb, y + 0.14, 0.2), dark, "bottom")
    return egg


def rhino_egg():
    grey, dark, horn = (150, 156, 170), (112, 118, 134), (240, 232, 208)
    egg = octo_egg([dark, grey, dark, grey, grey, dark, grey])
    t = E.H - 0.05
    w = egg.widths[6] / 2
    p = Part("Horn", (0.4, 0.75, 0.5), T(0, t + 0.375, -w + 0.25), horn, "Wedge")
    p.bone = "top"
    egg.parts.append(p)
    pony_ears(egg, grey, (206, 150, 170), x0=0.3, h=0.45, dz=0.3)
    return egg


def unicorn_egg():
    white, gold = (252, 250, 255), (255, 200, 60)
    egg = octo_egg([gold, white, white, gold, white, white, white])
    pony_ears(egg, white, PINK, x0=0.42, h=0.55)
    t = E.H - 0.05
    for i, (w, y0, y1) in enumerate(((0.18, 0, 0.35), (0.12, 0.35, 0.7), (0.06, 0.7, 1.1))):
        egg_block(egg, f"Horn{i + 1}" if i else "Horn", (-w, t + y0, -0.3 - w), (w, t + y1, -0.3 + w), gold)
    for i, c in enumerate(RAINBOW):
        z0 = -0.05 + 0.1 * i
        egg_block(egg, f"Tuft{i + 1}" if i else "Tuft", (-0.12, t, z0), (0.12, t + 0.55 - 0.06 * i, z0 + 0.1), c)
    return egg


EGGS = {"Pinto": pinto_egg, "Pig": pig_egg, "Fish": fish_egg, "Rhino": rhino_egg, "Unicorn": unicorn_egg}


# ---------------------------------------------------------------- export + previews

def build_animal(a, out):
    model, groups = write_bbmodel(a.parts, a.name, None, bones=a.bones())
    write_animations(model, groups, a.animations())
    with open(os.path.join(out, a.name + ".bbmodel"), "w") as f:
        json.dump(model, f, separators=(",", ":"))
    return model


def font(size):
    try:
        return ImageFont.truetype("DejaVuSans-Bold.ttf", size)
    except OSError:
        return ImageFont.load_default()


TILE_W, TILE_H = 300, 400
Q34 = dict(eye=(-19, 12, -21), target=(0, 5.2, -0.5), W=TILE_W, H=TILE_H, fov=36)
SIDE = dict(eye=(-30, 6, -1), target=(0, 5.2, -1), W=TILE_W, H=TILE_H, fov=34)


def anim_named(m, name):
    return next((x for x in m["animations"] if x["name"] == name), None) if name else None


def strip(models, anim_name=None, t=0.0, cam=Q34):
    """One tile per model, same camera and scale, so sizes compare.
    t is a fraction of each model's loop so different lengths stay in step."""
    tiles = []
    for m in models:
        anim = anim_named(m, anim_name)
        tiles.append(render(pose(m, anim, t * anim["length"] if anim else 0), **cam))
    im = Image.new("RGB", (cam["W"] * len(tiles), tiles[0].height))
    for i, tile in enumerate(tiles):
        im.paste(tile, (cam["W"] * i, 0))
    return im


def label(im, names, size=20):
    band = 36
    out = Image.new("RGB", (im.width, im.height + band), (255, 255, 255))
    out.paste(im, (0, band))
    d = ImageDraw.Draw(out)
    w = im.width / len(names)
    for i, text in enumerate(names):
        tw = d.textlength(text, font=font(size))
        d.text((w * i + (w - tw) / 2, 7), text, fill=(20, 20, 20), font=font(size))
    return out


def gif(path, frames, fps=20, hold=0):
    frames = frames + [frames[-1]] * hold
    frames[0].save(path, save_all=True, append_images=frames[1:], duration=int(1000 / fps), loop=0)


def main(out="designs/animals"):
    eggs_out = os.path.join(out, "eggs")
    os.makedirs(eggs_out, exist_ok=True)
    horse = qm_horse("A")
    with open(os.path.join(out, "Horse.bbmodel"), "w") as f:
        json.dump(horse, f, separators=(",", ":"))
    models, eggs, names, meta = [horse], [json.load(open(HORSE_EGG))], ["Horse · Common"], {}
    for fn in ANIMALS:
        a = fn()
        models.append(build_animal(a, out))
        names.append(f"{a.name} · {a.rarity}")
        meta[a.name] = dict(rarity=a.rarity, **a.meta)
        egg = EGGS[a.name]()
        eggs.append(E.build(egg, a.name + "Egg", eggs_out))
        print(f"{a.name}: {len(a.parts)} parts, egg {len(egg.parts)} parts")
    with open(os.path.join(out, "meta.json"), "w") as f:
        json.dump(meta, f, indent=1)

    label(strip(models), names).save(os.path.join(out, "lineup.png"))
    label(strip(models, cam=SIDE), names).save(os.path.join(out, "lineup_side.png"))
    small = (TILE_W * len(models) * 2 // 3, TILE_H * 2 // 3)
    for name, n in (("walk", 20), ("gallop", 16)):
        gif(os.path.join(out, name + ".gif"), [strip(models, name, i / n, SIDE).resize(small) for i in range(n)], fps=n / 0.9)
        print(name, "gif")

    # the two leap ideas side by side on the horse, from the side
    variants = [qm_horse(k) for k in GALLOPS]
    cam = dict(SIDE, W=420, H=380)
    frames = []
    for i in range(40):
        t = i / 20
        tiles = [render(pose(m, anim_named(m, "gallop"), t % anim_named(m, "gallop")["length"]), **cam) for m in variants]
        im = Image.new("RGB", (840, 380))
        for j, tl in enumerate(tiles):
            im.paste(tl, (420 * j, 0))
        frames.append(label(im, ["A: big leap", "B: quick bounds"]))
    gif(os.path.join(out, "gallop_variants.gif"), frames)

    ecam = dict(eye=(-6.5, 5.2, -7.5), target=(0, 1.9, 0), W=TILE_W, H=300, fov=34)
    label(strip(eggs, cam=ecam), [n.split(" ·")[0] + " Egg" for n in names]).save(os.path.join(eggs_out, "eggs.png"))
    esmall = (TILE_W * 4, 200)
    for name, length in (("twitch", 1.2), ("hatch", 2.0)):
        n = int(length * 20)
        gif(os.path.join(eggs_out, name + ".gif"), [strip(eggs, name, i / n, ecam).resize(esmall) for i in range(n)], hold=8)
    print("previews written")


if __name__ == "__main__":
    main(*sys.argv[1:])
