"""Morbol (QM Oct 11): "design a Morbol from FFXIV ... Using spikes for a lot of the
tentacle stuff", from QM's reference: a round plant monster that is nearly all mouth (a
huge gaping maw, rows of fangs, strings of drool), a crown of curling horn spikes round
the top and sides, thick tentacles hanging under it and long thin ones splayed on the floor.

Kids' version: bright moss green, darker green spikes and tentacles, pink gums, ivory
fangs, googly eyes peeking over the mouth. Every tentacle is a chain of tapering spike
pieces (frustums and a pyramid tip, meshes), bending a little at each joint.
Static draft (bones root, Jaw, Tent*, Foot*), no animations yet.

Run from the repo root: python3 tools/morbol_design.py
Writes Morbol.bbmodel, Morbol.png and Morbol_vs_horse.png in /mnt/project-files/animals/morbol/.
"""

import json
import math
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import animal_designs as A  # noqa: E402
import convert_designs as C  # noqa: E402
from convert_designs import Conv  # noqa: E402
from horse_rig import pose  # noqa: E402
from partlib import Part, render  # noqa: E402

ROOT = os.path.join(os.path.dirname(__file__), "..")
OUT = "/mnt/project-files/animals/morbol"

MOSS = (132, 186, 64)
MOSS_DARK = (100, 152, 48)
SPIKE = (78, 120, 40)
SPIKE_TIP = (196, 214, 120)
GUM = (240, 118, 132)
MAW = (92, 24, 44)
TOOTH = (252, 246, 222)
DROOL = (214, 240, 236)


def frame(d):
    d = np.asarray(d, float) / np.linalg.norm(d)
    a = np.array([0, 1.0, 0]) if abs(d[1]) < 0.9 else np.array([1.0, 0, 0])
    u = np.cross(d, a)
    u /= np.linalg.norm(u)
    return d, u, np.cross(d, u)


def poly(a, name, faces, color, bone):
    p = Part(name, (1, 1, 1), np.eye(4), color, "Poly")
    p.polys = [np.array(f, float) for f in faces]
    p.bone = bone
    a.parts.append(p)


def chain(a, name, base, dirs, lengths, w0, color, bone, tip=None):
    """A tentacle/horn: one tapering square segment per (dir, length), the last a point."""
    p, w = np.array(base, float), w0
    n = len(dirs)
    for i, (d, L) in enumerate(zip(dirs, lengths)):
        d, u, v = frame(d)
        q0 = [p - u * w - v * w, p + u * w - v * w, p + u * w + v * w, p - u * w + v * w]
        p1 = p + d * L
        col = tip if (tip and i == n - 1) else color
        if i == n - 1:
            poly(a, f"{name}_{i}", [q0[::-1]] + [[q0[j], q0[(j + 1) % 4], p1] for j in range(4)], col, bone)
        else:
            w1 = w * (1 - 0.6 / n)
            q1 = [p1 - u * w1 - v * w1, p1 + u * w1 - v * w1, p1 + u * w1 + v * w1, p1 - u * w1 + v * w1]
            poly(a, f"{name}_{i}", [q0[::-1], q1] + [[q0[j], q0[(j + 1) % 4], q1[(j + 1) % 4], q1[j]] for j in range(4)], col, bone)
            w = w1
        p = p1


def bend(d, axis, deg, n):
    """n directions starting at d, each turned a further deg about axis (Rodrigues)."""
    out, d = [], np.asarray(d, float) / np.linalg.norm(d)
    k = np.asarray(axis, float) / np.linalg.norm(axis)
    t = math.radians(deg)
    for _ in range(n):
        out.append(d)
        d = d * math.cos(t) + np.cross(k, d) * math.sin(t) + k * np.dot(k, d) * (1 - math.cos(t))
    return out


def morbol():
    a = Conv("Morbol", "Epic", 1.0)
    a.pivots["root"] = (0, 7.0, 0)
    # body: a rounded blob, stacked slabs so it reads round from every side
    for name, w, y0, y1, d in (("Base", 3.6, 3.4, 4.4, 3.4), ("Low", 4.6, 4.2, 5.4, 4.4), ("Mid", 5.0, 5.2, 9.4, 4.8),
                               ("High", 4.6, 9.2, 10.4, 4.4), ("Top", 3.6, 10.2, 11.0, 3.4)):
        a.b("Body" + name, (-w, y0, -d), (w, y1, d), MOSS, "root")
    # lumps on the body (darker moss, like the reference's warty hide)
    for i, (x, y, z, s) in enumerate(((-3.8, 9.8, 2.0, 0.9), (3.2, 10.2, -1.0, 0.8), (-5.0, 6.6, 2.4, 0.8), (5.0, 7.6, 1.6, 0.9),
                                      (0.8, 10.8, 2.2, 0.8), (-1.6, 4.0, 3.0, 0.7), (2.6, 4.2, 2.6, 0.7))):
        a.b(f"Lump{i}", (x - s, y - s * 0.7, z - s), (x + s, y + s * 0.7, z + s), MOSS_DARK, "root")
    # the maw: nearly the whole front, a dark hollow ringed with pink gums
    a.b("Maw", (-3.9, 5.6, -5.0), (3.9, 9.0, -4.6), MAW, "root")
    a.b("GumTop", (-4.4, 8.9, -5.2), (4.4, 9.6, -4.4), GUM, "root")
    a.b("GumL", (-4.6, 5.6, -5.2), (-3.8, 9.0, -4.4), GUM, "root")
    a.b("GumR", (3.8, 5.6, -5.2), (4.6, 9.0, -4.4), GUM, "root")
    a.b("Tongue", (-2.6, 5.6, -4.9), (2.6, 6.2, -3.0), GUM, "Jaw")
    a.b("GumBottom", (-4.4, 4.9, -5.2), (4.4, 5.7, -4.4), GUM, "Jaw")
    a.b("LipTop", (-4.8, 9.5, -5.6), (4.8, 10.1, -4.2), MOSS, "root")
    a.b("LipBottom", (-4.8, 4.4, -5.6), (4.8, 5.0, -4.2), MOSS, "Jaw")
    a.bone("Jaw", "root", (0, 5.4, -1.0))
    # fangs: big ones down from the top gum, up from the bottom, small ones between
    xs = np.linspace(-3.5, 3.5, 9)
    for i, x in enumerate(xs):
        big = i % 2 == 0
        w = 0.32 if big else 0.22
        a.pyr(f"FangTop{i}", (x - w, 8.9, -5.1 - w), (x + w, 8.9, -5.1 + w), "-y", 1.1 if big else 0.7, TOOTH, "root")
    for i, x in enumerate(xs[:-1] + 0.44):
        big = i % 2 == 1
        w = 0.3 if big else 0.22
        a.pyr(f"FangBottom{i}", (x - w, 5.7, -5.1 - w), (x + w, 5.7, -5.1 + w), "+y", 0.95 if big else 0.6, TOOTH, "Jaw")
    # strings of drool across the maw
    for i, (x, y0, y1) in enumerate(((-2.4, 5.8, 8.8), (-0.6, 6.4, 8.8), (1.0, 5.8, 8.8), (2.6, 6.8, 8.8))):
        a.b(f"Drool{i}", (x - 0.08, y0, -4.95), (x + 0.08, y1, -4.75), DROOL, "root")
    # googly eyes peeking over the top lip
    for side, sx in (("L", -1), ("R", 1)):
        x0, x1 = sorted((sx * 1.2, sx * 2.8))
        a.b("EyeBump" + side, (x0 - 0.2, 10.0, -4.4), (x1 + 0.2, 11.6, -3.0), MOSS, "root")
        a.front_eye(side, x0, x1, 10.1, 11.5, -4.4, "root")
    # crown of curling horn spikes round the top and sides, curling outward
    k = 0
    for ring, (y, r, n, L, w, up) in enumerate(((10.6, 3.6, 9, 1.6, 0.55, 0.9), (8.6, 4.9, 12, 1.4, 0.5, 0.35),
                                                (6.2, 4.9, 12, 1.2, 0.45, 0.0))):
        for j in range(n):
            t = math.radians(360 * j / n + (15 if ring == 1 else 0))
            out = np.array([math.sin(t), 0, -math.cos(t)])
            if ring > 0 and out[2] < -0.75:
                continue  # leave the maw clear
            d0 = out * (1 - up) + np.array([0, up + 0.25, 0])
            base = np.array([0, y, 0]) + out * r
            up_ = np.array([0, 1.0, 0])
            axis = np.cross(up_, out) if ring == 0 else np.cross(out, up_)  # top ring curls outward, side rings curl up
            dirs = bend(d0, axis, 14, 4)
            chain(a, f"Horn{k}", base, dirs, [L] * 4, w, SPIKE, "root", tip=SPIKE_TIP)
            k += 1
    # thick tentacles hanging under the body, curling at the ends
    for i in range(7):
        t = math.radians(360 * i / 7 + 25)
        out = np.array([math.sin(t), 0, -math.cos(t)])
        base = np.array([0, 4.0, 0]) + out * 2.4
        bone = a.bone(f"Tent{i}", "root", tuple(base))
        d0 = np.array([0, -1.0, 0]) + out * 0.25
        dirs = bend(d0, np.cross([0, 1.0, 0], out), -26, 4)
        chain(a, f"Tent{i}", base, dirs, [1.2, 1.1, 1.0, 1.4], 0.75, MOSS_DARK, bone, tip=SPIKE)
    # long thin feet tentacles splayed on the floor
    for i in range(6):
        t = math.radians(360 * i / 6 + 30)
        out = np.array([math.sin(t), 0, -math.cos(t)])
        base = np.array([0, 3.4, 0]) + out * 1.6
        bone = a.bone(f"Foot{i}", "root", tuple(base))
        d0 = out * 0.5 + np.array([0, -1.0, 0])
        dirs = bend(d0, np.cross(out, [0, 1.0, 0]), 17, 7)
        chain(a, f"Foot{i}", base, dirs, [1.0, 1.2, 1.5, 1.8, 2.0, 2.2, 2.2], 0.5, SPIKE, bone)
    a.meta = {"seat": (0, 11.0, 0.8), "neck_loop": {"center": (0, 8.0, 0), "radius": 5.2}}
    return a


def main(out=OUT):
    os.makedirs(out, exist_ok=True)
    a, model, parts = C.build(morbol)
    model["meta"]["format_version"] = "5.0"
    path = os.path.join(out, "Morbol.bbmodel")
    with open(path, "w") as f:
        json.dump(model, f, separators=(",", ":"))
    for p in parts:
        if p.name.startswith(("Eye", "Pupil")):
            p.plain = True
    lo, hi = C.bounds(parts)
    c = (lo + hi) / 2
    r = np.linalg.norm(hi - lo) / 2
    T = 480
    sheet = Image.new("RGB", (T * 3, T))
    for i, v in enumerate(((-14, 6, -24), (-30, 4, 0), (19, 16, 21))):
        v = np.array(v, float)
        eye = c + v / np.linalg.norm(v) * r / np.tan(np.radians(17)) * 1.0
        sheet.paste(render(parts, eye=eye, target=c, W=T, H=T, fov=34), (i * T, 0))
    A.label(sheet, ["Morbol", "side", "back"], 22).save(os.path.join(out, "Morbol.png"))
    horse = json.load(open(os.path.join(ROOT, "designs", "animals", "Horse.bbmodel")))
    cam = dict(eye=(-40, 16, -40), target=(0, 6, 0), W=T, H=T, fov=36)
    pair = Image.new("RGB", (T * 2, T))
    pair.paste(render(pose(horse, None, 0), **cam), (0, 0))
    pair.paste(render(parts, **cam), (T, 0))
    A.label(pair, ["Horse", "Morbol"], 22).save(os.path.join(out, "Morbol_vs_horse.png"))
    print("wrote", path, len(parts), "parts")


if __name__ == "__main__":
    main()
