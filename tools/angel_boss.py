"""The Seraph: World 2 Meadow's boss (QM, Oct 13: "an absolutely epic biblically accurate
angel"). A floating wheel-within-wheels: a big golden eye at the centre, three gold rings
around it, each covered in eyes on both faces, spinning on their own axes, and six white
wings (three pairs, up, out and down) spread behind it all. A glowing gold halo floats on top.

Run: python3 tools/angel_boss.py [out_dir] [--gif]

Built in Blockbench's ZYX Euler order so QM can edit it there. Every bone rests at 0:
the ring and feather tilts are baked into the cubes (single bones never rest turned).

Bones: root (the core, where it floats) -> neck (the big eye: looks about) ;
root -> Ring1 (in the XY plane, framing the eye: spins about Z), Ring2 (stands up,
leaning 20 degrees: turns about Y like a gyroscope), Ring3 (lies down, tilted 25 degrees
front-down: turns about Y, so it wobbles) ; root -> Halo ;
root -> WingL1..3 / WingR1..3 (top, middle, bottom pairs: flap about Z).

  idle    floats up and down, rings turning slowly, wings beating gently
  walk    rings faster, wings beating harder, leaning in
  gallop  rings whirling, big wing beats, leaning hard into the chase
"""

import json
import math
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import horse_rig  # noqa: E402

horse_rig.EULER = "ZYX"  # Blockbench's own order: QM edits it there
import snake_design as S  # noqa: E402
from horse_rig import write_animations  # noqa: E402
from partlib import render  # noqa: E402
from snake_rig import track  # noqa: E402
import animal_designs as A  # noqa: E402

S.SIZE = 1.0
ROOT = os.path.join(os.path.dirname(__file__), "..")
MODEL = os.path.join(ROOT, "designs", "bosses", "Seraph.bbmodel")
TAU = 2 * math.pi
BB = S.BB

COLORS = {"gold": (255, 194, 38), "deep": (222, 146, 24), "white": (255, 255, 255), "cream": (255, 244, 214),
          "black": (20, 20, 26), "iris": (70, 178, 255), "glow": (255, 226, 90), "tip": (255, 214, 120)}
TEX = {n: i for i, n in enumerate(COLORS)}

HOVER = 16.0  # the core's centre, before floor() sets the lowest point GAP over y = 0
GAP = 3.0
CORE = 7.0  # the gold core cube
EYE, IRIS, PUPIL = 6.4, 4.0, 2.0
# rings: (bone, radius, segments, band width (radial), band depth (along the normal),
# normal before the tilt, tilt (axis, degrees), eye every n segments)
RINGS = [("Ring1", 9.2, 24, 2.4, 1.0, (0, 0, 1), [], 2),
         ("Ring2", 11.8, 28, 2.4, 1.0, (1, 0, 0), [("z", 20.0), ("y", 55.0)], 2),
         ("Ring3", 14.4, 32, 2.4, 1.0, (0, 1, 0), [("x", 25.0)], 2)]
RING_EYE, RING_PUPIL = 2.0, 1.0
# wings: (pair, angle from +X in the XY plane, shoulder y offset, z, feather lengths)
WINGS = [(1, 50.0, 3.0, 16.0, (25, 23, 20, 17, 14)),
         (2, 6.0, 0.0, 16.8, (29, 27, 24, 20, 16)),
         (3, -40.0, -3.0, 17.6, (20, 18, 15, 12, 10))]
SHOULDER_X = 2.5
FEATHER_W, FEATHER_T = 4.4, 0.8
FAN = 9.0  # degrees between feathers
HALO_R, HALO_Y = 5.0, 15.5


def rot_to_zyx(M):
    """Blockbench's Euler (degrees) for rotation matrix M: M = Rz * Ry * Rx."""
    y = math.asin(max(-1.0, min(1.0, -M[2, 0])))
    if abs(math.cos(y)) > 1e-6:
        x = math.atan2(M[2, 1], M[2, 2])
        z = math.atan2(M[1, 0], M[0, 0])
    else:
        x, z = math.atan2(-M[1, 2], M[1, 1]), 0.0
    return [round(math.degrees(a), 3) for a in (x, y, z)]


def axis_rot(axis, deg):
    a = math.radians(deg)
    c, s = math.cos(a), math.sin(a)
    return {"x": np.array([[1, 0, 0], [0, c, -s], [0, s, c]]),
            "y": np.array([[c, 0, s], [0, 1, 0], [-s, 0, c]]),
            "z": np.array([[c, -s, 0], [s, c, 0], [0, 0, 1]])}[axis]


def box(name, center, size, tex, M=None):
    """A cube in studs centred on `center`, its own axes turned by M (local -> model)."""
    c = np.array(center, float) * BB
    h = np.array(size, float) * BB / 2
    rot = rot_to_zyx(M) if M is not None else [0, 0, 0]
    rot = [0.0 if abs(r) < 1e-3 else r for r in rot]
    return {"name": name, "type": "cube", "uuid": S.uid(), "box_uv": False, "autouv": 0, "color": 0,
            "from": [round(x, 4) for x in c - h], "to": [round(x, 4) for x in c + h],
            "origin": [round(x, 4) for x in c], "rotation": rot,
            "faces": {f: {"uv": [0, 0, 1, 1], "texture": tex} for f in ("north", "east", "south", "west", "up", "down")}}


def build():
    elements, groups = [], []

    def add_group(name, pivot, parent):
        g = S.group(name, pivot)
        groups.append(g)
        node = {"uuid": g["uuid"], "isOpen": True, "children": []}
        if parent is not None:
            parent["children"].append(node)
        return node

    def put(node, parts):
        for e in parts:
            elements.append(e)
            node["children"].append(e["uuid"])

    y0 = HOVER
    C = np.array([0, y0, 0.0])

    # the core: a gold block with a darker band round its middle
    root = add_group("root", (0, y0, 0), None)
    put(root, [box("Core", C, (CORE, CORE, CORE), TEX["gold"]),
               box("CoreBand", C, (CORE + 0.3, 1.2, CORE + 0.3), TEX["deep"])])
    # the big eye on its front
    neck = add_group("neck", (0, y0, -CORE / 2), root)
    z = -CORE / 2
    put(neck, [box("Eye", (0, y0, z - 0.1), (EYE, EYE, 0.2), TEX["white"]),
               box("Glow_iris", (0, y0, z - 0.25), (IRIS, IRIS, 0.2), TEX["iris"]),
               box("Pupil", (0, y0, z - 0.4), (PUPIL, PUPIL, 0.2), TEX["black"])])

    # the rings, full of eyes
    for bone, R, n, wid, dep, normal, tilt, every in RINGS:
        node = add_group(bone, (0, y0, 0), root)
        n0 = np.array(normal, float)
        # two in-plane axes for the untilted ring
        u = np.array([1.0, 0, 0]) if abs(n0[0]) < 0.9 else np.array([0, 1.0, 0])
        u = u - n0 * (u @ n0)
        u /= np.linalg.norm(u)
        v = np.cross(n0, u)
        T = np.eye(3)
        for ax, deg in tilt:
            T = axis_rot(ax, deg) @ T
        nn, uu, vv = T @ n0, T @ u, T @ v
        seg = TAU * R / n * 1.12
        parts = []
        for k in range(n):
            th = TAU * (k + 0.5) / n
            r = math.cos(th) * uu + math.sin(th) * vv  # outward
            t = -math.sin(th) * uu + math.cos(th) * vv  # along the ring
            M = np.column_stack([t, r, nn])  # local X along, Y out, Z through the ring
            p = C + R * r
            parts.append(box(f"{bone}Seg{k + 1}", p, (seg, wid, dep), TEX["gold" if k % 2 else "deep"], M))
            if k % every == 1:
                for side, sgn in (("F", -1), ("B", 1)):
                    q = p + sgn * nn * (dep / 2 + 0.1)
                    parts.append(box(f"Eye_{bone}_{k + 1}{side}", q, (RING_EYE, RING_EYE, 0.2), TEX["white"], M))
                    q2 = p + sgn * nn * (dep / 2 + 0.25)
                    parts.append(box(f"Pupil_{bone}_{k + 1}{side}", q2, (RING_PUPIL, RING_PUPIL, 0.2), TEX["black"], M))
        put(node, parts)

    # the halo: a glowing flat ring above
    halo = add_group("Halo", (0, y0 + HALO_Y, 0), root)
    n = 16
    hp = []
    for k in range(n):
        th = TAU * (k + 0.5) / n
        r = np.array([math.cos(th), 0, math.sin(th)])
        t = np.array([-math.sin(th), 0, math.cos(th)])
        M = np.column_stack([t, r, np.cross(t, r)])
        hp.append(box(f"Glow_halo{k + 1}", C + np.array([0, HALO_Y, 0]) + HALO_R * r,
                      (TAU * HALO_R / n * 1.15, 1.1, 0.8), TEX["glow"], M))
    put(halo, hp)

    # six wings: each a fan of long feathers in the XY plane behind the rings
    for pair, ang, dy, wz, lengths in WINGS:
        for side, sx in (("R", 1), ("L", -1)):
            sh = np.array([sx * SHOULDER_X, y0 + dy, wz])
            node = add_group(f"Wing{side}{pair}", sh, root)
            parts = []
            nf = len(lengths)
            for k, Lf in enumerate(lengths):
                # feathers fan out from the leading edge (k = 0, highest) downward
                fa = ang + FAN * (nf - 1) / 2 - FAN * k
                a = math.radians(fa) if sx > 0 else math.radians(180 - fa)
                d = np.array([math.cos(a), math.sin(a), 0])
                start = sh + np.array([0, 0, 0.12 * k])
                M = np.column_stack([d, np.cross([0, 0, 1.0], d), [0, 0, 1.0]])
                mid = start + d * Lf / 2
                tex = TEX["white"] if k % 2 == 0 else TEX["cream"]
                parts.append(box(f"Wing{side}{pair}F{k + 1}", mid, (Lf, FEATHER_W, FEATHER_T), tex, M))
                # a pale gold tip
                parts.append(box(f"Wing{side}{pair}T{k + 1}", start + d * (Lf + 0.9), (1.8, FEATHER_W * 0.8, FEATHER_T),
                                 TEX["tip"], M))
            # the covert: a stubby block over the feather roots
            a = math.radians(ang) if sx > 0 else math.radians(180 - ang)
            d = np.array([math.cos(a), math.sin(a), 0])
            M = np.column_stack([d, np.cross([0, 0, 1.0], d), [0, 0, 1.0]])
            parts.append(box(f"Wing{side}{pair}Covert", sh + d * 5.5 + np.array([0, 0, -0.5]),
                             (11, FEATHER_W * 2.2, 1.0), TEX["white"], M))
            put(node, parts)

    model = json.load(open(os.path.join(ROOT, "designs", "desert", "Snake.bbmodel")))
    model.update(name="Seraph", elements=elements, groups=groups, outliner=[root], animations=[],
                 textures=[S.solid_texture(n, col) for n, col in COLORS.items()])
    model.setdefault("meta", {})["format_version"] = "5.0"
    return model


def floor(model):
    """Shift everything so the lowest point floats GAP studs over y = 0; returns the shift (studs)."""
    lo = min(q[:, 1].min() for p in S.posed(model) for q in p.polys)
    d = (GAP - lo) * BB
    for e in model["elements"]:
        for k in ("from", "to", "origin"):
            if k in e:
                e[k][1] = round(e[k][1] + d, 4)
    for g in model["groups"]:
        g["origin"][1] = round(g["origin"][1] + d, 4)
    return GAP - lo


# ---------------------------------------------------------------- animations

def spin(L, axis, turns, n):
    """A whole number of turns about one axis over the loop, keyed every 360 / n * turns degrees."""
    i = "xyz".index(axis)

    def fn(u):
        v = [0.0, 0.0, 0.0]
        v[i] = 360.0 * turns * u
        return tuple(v)
    return track(L, fn, n, interp="linear")


def animations():
    # position keys are in Blockbench units (0.1 stud)
    L = 4.0
    idle = {"root": [track(L, lambda u: (0, 8 * math.sin(TAU * u * 2), 0), 16, "position")],
            "neck": [track(L, lambda u: (4 * math.sin(TAU * u * 2), 16 * math.sin(TAU * u), 0), 24)],
            "Ring1": [spin(L, "z", 1, 24)], "Ring2": [spin(L, "y", -1, 24)], "Ring3": [spin(L, "y", 1, 24)],
            "Halo": [track(L, lambda u: (0, 4 * math.sin(TAU * u * 2 + 0.6), 0), 16, "position")]}
    for pair, *_ in WINGS:  # a gentle beat, twice a loop
        for side, sx in (("R", 1), ("L", -1)):
            idle[f"Wing{side}{pair}"] = [track(L, lambda u, sx=sx, p=pair: (
                0, 0, sx * 12 * math.sin(TAU * 2 * u - 0.35 * (p - 1))), 32)]

    Lw = 2.0
    walk = {"root": [track(Lw, lambda u: (-8, 0, 0), 4), track(Lw, lambda u: (0, 6 * math.sin(TAU * u * 2), 0), 16, "position")],
            "neck": [track(Lw, lambda u: (0, 6 * math.sin(TAU * u), 0), 16)],
            "Ring1": [spin(Lw, "z", 1, 24)], "Ring2": [spin(Lw, "y", -1, 24)], "Ring3": [spin(Lw, "y", 1, 24)],
            "Halo": [track(Lw, lambda u: (0, 3 * math.sin(TAU * u * 2 + 0.6), 0), 16, "position")]}
    for pair, *_ in WINGS:
        for side, sx in (("R", 1), ("L", -1)):
            walk[f"Wing{side}{pair}"] = [track(Lw, lambda u, sx=sx, p=pair: (
                0, 0, sx * 20 * math.sin(TAU * 2 * u - 0.35 * (p - 1))), 32)]

    Lg = 1.0
    gallop = {"root": [track(Lg, lambda u: (-16, 0, 0), 4), track(Lg, lambda u: (0, 8 * math.sin(TAU * u * 2 - 1.2), 0), 16, "position")],
              "neck": [track(Lg, lambda u: (-4, 0, 0), 4)],
              "Ring1": [spin(Lg, "z", 1, 24)], "Ring2": [spin(Lg, "y", -1, 24)], "Ring3": [spin(Lg, "y", 1, 24)],
              "Halo": [track(Lg, lambda u: (0, 4 * math.sin(TAU * u * 2), 0), 16, "position")]}
    for pair, *_ in WINGS:
        for side, sx in (("R", 1), ("L", -1)):
            gallop[f"Wing{side}{pair}"] = [track(Lg, lambda u, sx=sx, p=pair: (
                0, 0, sx * (5 + 30 * math.sin(TAU * 2 * u - 0.35 * (p - 1)))), 32)]
    return {"idle": (L, idle), "walk": (Lw, walk), "gallop": (Lg, gallop)}


# ---------------------------------------------------------------- preview

CAMS = [dict(eye=(-58, 30, -80), target=(0, 18, 0)), dict(eye=(0, 22, -100), target=(0, 18, 0)),
        dict(eye=(90, 30, 40), target=(0, 16, 0)), dict(eye=(0, 110, 50), target=(0, 16, 0))]


def previews(m, out, gif=True):
    from horse_rig import pose
    hparts = pose(A.qm_horse("A"), None, 0)
    for p in hparts:
        p.polys = [q + np.array([30, 0, -10]) for q in p.polys]
    parts = S.posed(m)
    Wd, Ht = 640, 520
    sheet = Image.new("RGB", (Wd * 2, Ht * 2))
    for i, cam in enumerate(CAMS):
        ps = parts + (hparts if i == 0 else [])
        sheet.paste(render(ps, W=Wd, H=Ht, fov=40, **cam), ((i % 2) * Wd, (i // 2) * Ht))
    sheet.save(os.path.join(out, "Seraph.png"))
    big = render(parts, W=1100, H=900, fov=40, eye=(-40, 26, -88), target=(0, 18, 0))
    big.save(os.path.join(out, "Seraph_front.png"))
    if not gif:
        return
    Wd, Ht = 440, 360
    frames = []
    for name, label, n, loops in (("idle", "idle", 40, 1), ("walk", "walk", 20, 2), ("gallop", "chase", 12, 3)):
        anim = next(a for a in m["animations"] if a["name"] == name)
        for _ in range(loops):
            for k in range(n):
                ps = S.posed(m, anim, anim["length"] * k / n)
                im = Image.new("RGB", (Wd * 2, Ht))
                im.paste(render(ps, W=Wd, H=Ht, fov=40, **CAMS[1]), (0, 0))
                im.paste(render(ps, W=Wd, H=Ht, fov=40, **CAMS[2]), (Wd, 0))
                frames.append(A.label(im, [label] * 2))
    A.gif(os.path.join(out, "Seraph_anims.gif"), frames, fps=20)


def main(out="/mnt/project-files/animals/bosses"):
    os.makedirs(out, exist_ok=True)
    os.makedirs(os.path.dirname(MODEL), exist_ok=True)
    m = build()
    shift = floor(m)
    groups = {g["name"]: g for g in m["groups"]}
    write_animations(m, groups, animations())
    for path in (MODEL, os.path.join(out, "Seraph.bbmodel")):
        with open(path, "w") as f:
            json.dump(m, f, separators=(",", ":"))
    print("elements", len(m["elements"]), "bones", len(m["groups"]), "shift", round(shift, 3),
          "centre y", round(HOVER + shift, 3))
    previews(m, out, gif="--gif" in sys.argv)


if __name__ == "__main__":
    main(*[a for a in sys.argv[1:] if not a.startswith("--")])
