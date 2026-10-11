"""Volcano Tortoise (QM Oct 10): a lava-biome tortoise with a volcano growing out of its
shell, and a beak that is a downward-facing triangular prism. Static draft, no animations.

Run: python3 tools/tortoise_design.py [out_dir]
writes VolcanoTortoise.bbmodel and VolcanoTortoise.png (three views) to out_dir.

Quadruped bones like the Boar (root, LegFL/FR/HL/HR, neck, Tail) so a walk can be added
later. The stepped shell sits low over four stumpy legs; on top a stepped stone cone with a
crater of lava (Glow parts are Neon in game) and lava running down its sides.
"""

import json
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import animal_designs as A  # noqa: E402
import convert_designs as C  # noqa: E402
from convert_designs import Conv, SIDES, X  # noqa: E402
from partlib import Part, render  # noqa: E402

OUT = "/mnt/project-files/animals/tortoise"

SKIN = (178, 150, 102)  # dusty olive tan
SKIN_DARK = (150, 122, 82)
SHELL = (122, 66, 44)  # deep reddish brown, darker than the biome floor
SHELL_RIM = (92, 50, 36)
SCUTE = (148, 84, 54)
ROCK = (112, 96, 90)  # the volcano: warm grey stone
ROCK_DARK = (92, 78, 74)
LAVA = (255, 116, 24)
LAVA_HOT = (255, 186, 60)
BEAK = (236, 200, 120)
NAIL = (236, 214, 170)


def prism_x(a, name, pts, x0, x1, color, bone):
    """Triangle in (z, y) extruded along x: a wedge seen from the side."""
    faces = [[(x0, y, z) for z, y in pts], [(x1, y, z) for z, y in pts[::-1]]]
    for i, j in ((0, 1), (1, 2), (2, 0)):
        (za, ya), (zb, yb) = pts[i], pts[j]
        faces.append([(x0, ya, za), (x0, yb, zb), (x1, yb, zb), (x1, ya, za)])
    p = Part(name, (1, 1, 1), np.eye(4), color, "Poly")
    p.polys = [np.array(f, float) for f in faces]
    p.bone = bone
    a.parts.append(p)


def tortoise():
    a = Conv("VolcanoTortoise", "Rare", 1.0)
    a.pivots["root"] = (0, 3.0, 0)
    # four stumpy elephant legs with pale nails
    for fb, z in (("F", -2.2), ("H", 2.2)):
        for side, sx in SIDES:
            leg = a.bone(f"Leg{fb}{side}", "root", (sx * 2.2, 2.2, z))
            x0, x1 = X(sx, 1.5, 2.9)
            a.b(f"Leg{fb}{side}", (x0, 0, z - 0.7), (x1, 2.4, z + 0.7), SKIN, leg)
            for i, dx in enumerate((-0.4, 0.4)):
                xc = sx * 2.2 + dx
                a.b(f"Plain_Nail{fb}{side}{i}", (xc - 0.2, 0, z - 0.85), (xc + 0.2, 0.4, z - 0.7), NAIL, leg)
    # plastron (belly) and the shell: a dark rim then two stepped tiers
    a.b("Belly", (-2.6, 1.6, -3.0), (2.6, 2.2, 3.0), SKIN_DARK, "root")
    a.b("ShellRim", (-3.4, 2.2, -3.8), (3.4, 2.8, 3.8), SHELL_RIM, "root")
    a.b("Shell", (-3.1, 2.8, -3.5), (3.1, 4.4, 3.5), SHELL, "root")
    a.b("ShellTop", (-2.4, 4.4, -2.8), (2.4, 5.2, 2.8), SHELL, "root")
    # raised scutes (real depth) round the shell's sides
    for side, sx in SIDES:
        for i, z in enumerate((-2.2, 0.0, 2.2)):
            x0, x1 = X(sx, 3.1, 3.25)
            a.b(f"ScuteS{side}{i}", (x0, 3.1, z - 0.8), (x1, 4.1, z + 0.8), SCUTE, "root")
    for fb, zz in (("F", -3.5), ("B", 3.5)):
        for i, x in enumerate((-1.8, 0.0, 1.8)):
            z0, z1 = (zz - 0.15, zz) if fb == "F" else (zz, zz + 0.15)
            if fb == "F" and x == 0.0:
                continue  # the head comes out there
            a.b(f"Scute{fb}{i}", (x - 0.7, 3.1, z0), (x + 0.7, 4.1, z1), SCUTE, "root")
    # the volcano: stepped stone cone with a lava crater
    a.b("Volcano0", (-1.9, 5.2, -1.9), (1.9, 6.2, 1.9), ROCK, "root")
    a.b("Volcano1", (-1.5, 6.2, -1.5), (1.5, 7.2, 1.5), ROCK, "root")
    a.b("Volcano2", (-1.2, 7.2, -1.2), (1.2, 8.0, 1.2), ROCK_DARK, "root")
    # crater rim: four blocks round a lava pool sunk into the top
    for i, (lo, hi) in enumerate((((-1.2, -1.2), (1.2, -0.7)), ((-1.2, 0.7), (1.2, 1.2)),
                                  ((-1.2, -0.7), (-0.7, 0.7)), ((0.7, -0.7), (1.2, 0.7)))):
        a.b(f"Rim{i}", (lo[0], 8.0, lo[1]), (hi[0], 8.5, hi[1]), ROCK_DARK, "root")
    a.b("GlowCrater", (-0.7, 7.9, -0.7), (0.7, 8.4, 0.7), LAVA_HOT, "root")
    # lava running down the cone's sides (each run steps out with the cone)
    for i, (x, z, nx, nz) in enumerate(((0.5, -1, 0, -1), (-0.6, 1, 0, 1), (-1, -0.3, -1, 0), (1, 0.6, 1, 0))):
        for j, (h, y0, y1) in enumerate(((1.2, 7.2, 8.4), (1.5, 6.2, 7.6), (1.9, 5.2, 6.4))):
            w = 0.3 if j < 2 else 0.4
            cx, cz = (nx * h if nx else x), (nz * h if nz else z)
            d = 0.12
            lo = (cx - (d if nx else w) + (d * nx if nx else 0), y0 - (0.2 if j == 2 else 0), cz - (d if nz else w) + (d * nz if nz else 0))
            hi = (cx + (d if nx else w) + (d * nx if nx else 0), y1, cz + (d if nz else w) + (d * nz if nz else 0))
            a.b(f"GlowLava{i}{j}", lo, hi, LAVA, "root")
    # head on a short neck, poking out of the front of the shell
    head = a.bone("neck", "root", (0, 3.2, -3.5))
    a.b("Neck", (-0.9, 2.4, -4.6), (0.9, 3.8, -3.3), SKIN, head)
    a.b("Head", (-1.2, 2.6, -6.4), (1.2, 4.6, -4.4), SKIN, head)
    # the beak: a downward-facing triangular prism hooked over the front of the head
    prism_x(a, "Beak", [(-6.2, 3.8), (-6.9, 3.8), (-6.55, 2.4)], -0.8, 0.8, BEAK, head)
    for side, sx in SIDES:
        a.side_eye(side, sx, 1.2, 3.6, 4.4, -6.0, -5.1, head)
    a.b("BrowL", (-1.25, 4.4, -6.15), (-0.2, 4.75, -5.6), SKIN_DARK, head)
    a.b("BrowR", (0.2, 4.4, -6.15), (1.25, 4.75, -5.6), SKIN_DARK, head)
    tail = a.bone("Tail", "root", (0, 2.6, 3.6))
    a.b("Tail", (-0.4, 2.0, 3.6), (0.4, 2.8, 4.6), SKIN, tail)
    a.meta = {"seat": (0, 5.2, 1.6), "neck_loop": {"center": (0, 3.6, -4.9), "radius": 1.6}}
    return a


def main(out=OUT):
    os.makedirs(out, exist_ok=True)
    a, model, parts = C.build(tortoise)
    model["meta"]["format_version"] = "5.0"
    path = os.path.join(out, "VolcanoTortoise.bbmodel")
    with open(path, "w") as f:
        json.dump(model, f, separators=(",", ":"))
    for p in parts:
        if p.name.startswith(("Eye", "Pupil", "Plain")):
            p.plain = True
        if p.name.startswith("Glow"):
            p.neon = True
    lo, hi = C.bounds(parts)
    c = (lo + hi) / 2
    r = np.linalg.norm(hi - lo) / 2
    T = 480
    ims = []
    for v in ((-19, 10, -21), (-30, 4, 0), (19, 14, 21)):
        v = np.array(v, float)
        eye = c + v / np.linalg.norm(v) * r / np.tan(np.radians(17)) * 1.05
        ims.append(render(parts, eye=eye, target=c, W=T, H=T, fov=34))
    sheet = Image.new("RGB", (T * 3, T))
    for i, im in enumerate(ims):
        sheet.paste(im, (i * T, 0))
    A.label(sheet, ["Volcano Tortoise", "side", "back"], 22).save(os.path.join(out, "VolcanoTortoise.png"))
    print("wrote", path, len(parts), "parts")



# ---------------------------------------------------------------- animations (on QM's file)
FEET = ("LegFL", "LegFR", "LegHL", "LegHR")


def animations(m):
    import math
    from snake_rig import track
    from snow_rig import bump, grounded
    s, TAU = math.sin, 2 * math.pi
    feet = {e["name"] for e in m["elements"] if e["name"].startswith(FEET) or e["name"].startswith("Plain_Nail")}

    def run(L, stride, sway, bob, nod, n=16):
        # diagonal pairs step together (front left with hind right), the shell rocks
        # side to side over the planted pair, the head nods with each step
        tr = {"root": [track(L, lambda u: (0, 0, sway * s(TAU * u)), n)]}
        for leg, ph in (("LegFL", 0.0), ("LegHR", 0.0), ("LegFR", 0.5), ("LegHL", 0.5)):
            tr[leg] = [track(L, lambda u, ph=ph: (stride * s(TAU * (u + ph)), 0, 0), n)]
        tr["neck"] = [track(L, lambda u: (nod * s(2 * TAU * u), 4 * s(TAU * u), 0), n)]
        tr["root"] = grounded(m, L, tr, feet, n, extra=lambda u: bob * abs(s(TAU * u)))
        return L, tr

    out = {}
    # idle: slow breathing, looks left and right, and a slow blink of a nod
    L = 4.0
    out["idle"] = (L, {
        "neck": [track(L, lambda u: (6 * bump(u, 0.75, 0.1), 22 * s(TAU * u), 0), 32)],
        "root": [track(L, lambda u: (0, 0.3 + 0.3 * s(2 * TAU * u), 0), 16, "position")],
    })
    out["walk"] = run(1.2, stride=22, sway=3, bob=0.5, nod=4)
    out["gallop"] = run(0.6, stride=34, sway=5, bob=2.0, nod=8)
    return out


def animate(src, dst, out=OUT):
    """Write idle, walk and gallop into QM's file (src) as dst, with preview GIFs."""
    import horse_rig
    horse_rig.EULER = "ZYX"  # QM's hand-made file (rotated brows)
    from horse_rig import write_animations
    from snow_rig import group_ids, posed
    m = json.load(open(src))
    m["animations"] = []
    write_animations(m, group_ids(m), animations(m))
    with open(dst, "w") as f:
        json.dump(m, f, separators=(",", ":"))
    T = 420
    cams = [dict(eye=(-28, 14, -30), target=(0, 4, 0), W=T, H=T, fov=36), dict(eye=(-40, 6, -1), target=(0, 4, 0), W=T, H=T, fov=34)]

    def frame(name, t):
        anim = next(x for x in m["animations"] if x["name"] == name)
        ps = posed(m, anim, t)
        for p in ps:
            if p.name.startswith(("Eye", "Pupil", "Plain")):
                p.plain = True
            if p.name.startswith("Glow"):
                p.neon = True
        im = Image.new("RGB", (T * 2, T))
        for i, c in enumerate(cams):
            im.paste(render(ps, **c), (i * T, 0))
        return A.label(im, [name, ""], 22)

    for name, n in (("idle", 24), ("walk", 16), ("gallop", 12)):
        L = next(x for x in m["animations"] if x["name"] == name)["length"]
        A.gif(os.path.join(out, f"VolcanoTortoise_{name}.gif"), [frame(name, L * i / n) for i in range(n)], fps=n / L)

if __name__ == "__main__":
    if sys.argv[1:2] == ["animate"]:
        animate(*sys.argv[2:])
    else:
        main(*sys.argv[1:])
