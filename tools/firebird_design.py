"""Firebird (QM Oct 11): a terror bird, orange with dark grey and black features, after
QM's reference (a big boxy head with a hooked beak full of teeth, stubby wings with
barred feathers, long legs ending in clawed feet). Static draft, no animations.

Run: python3 tools/firebird_design.py [out_dir]
writes Firebird.bbmodel, Firebird.png (three views) and Firebird_vs_horse.png to out_dir.

Two-legged like the Chicken: bones root, LegL/LegR, WingL/WingR, neck (head, beak,
jaw, crest) and Tail, so a run can be added later.
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
from horse_rig import pose  # noqa: E402
from partlib import render  # noqa: E402

ROOT = os.path.join(os.path.dirname(__file__), "..")
OUT = "/mnt/project-files/animals/firebird"

ORANGE = (255, 128, 32)
ORANGE_DARK = (232, 98, 22)  # the belly and under the wings
GREY = (64, 62, 70)  # beak, shins, feet, feather bars
BLACK = (34, 32, 38)  # crest, tail feathers, wing tips
MOUTH = (120, 34, 44)
TOOTH = (244, 236, 214)
CLAW = (232, 224, 204)
EYE = (255, 214, 60)  # a yellow eye, like the reference


def firebird():
    a = Conv("Firebird", "Epic", 1.0)
    a.pivots["root"] = (0, 6.0, 0)
    # long legs: an orange thigh, a thin dark shin, a dark foot with three toes and pale claws
    for side, sx in SIDES:
        leg = a.bone("Leg" + side, "root", (sx * 1.1, 5.6, 0.2))
        x0, x1 = X(sx, 0.5, 1.7)
        a.b("Thigh" + side, (x0, 4.0, -0.5), (x1, 5.8, 0.9), ORANGE, leg)
        x0, x1 = X(sx, 0.75, 1.45)
        a.b("Shin" + side, (x0, 0.5, -0.15), (x1, 4.0, 0.55), GREY, leg)
        a.b("Heel" + side, (x0, 0.0, 0.0), (x1, 0.5, 0.7), GREY, leg)
        for i, dx in enumerate((-0.45, 0.0, 0.45)):
            xc = sx * 1.1 + dx
            a.b(f"Toe{side}{i}", (xc - 0.18, 0.0, -1.2), (xc + 0.18, 0.4, 0.1), GREY, leg)
            a.pyr(f"Claw{side}{i}", (xc - 0.15, 0.05, -1.2), (xc + 0.15, 0.35, -1.2), "-z", 0.45, CLAW, leg)
    # body: a big orange box, a darker belly under it
    a.b("Body", (-1.8, 5.2, -2.6), (1.8, 8.6, 2.8), ORANGE, "root")
    a.b("Belly", (-1.5, 4.8, -2.2), (1.5, 5.2, 2.2), ORANGE_DARK, "root")
    # stubby wings hinged at the shoulder: orange with two dark grey feather bars and black tips
    for side, sx in SIDES:
        wing = a.bone("Wing" + side, "root", (sx * 1.8, 8.2, -1.2))
        x0, x1 = X(sx, 1.8, 2.3)
        a.b("Wing" + side, (x0, 6.0, -1.8), (x1, 8.4, 2.6), ORANGE, wing)
        x0, x1 = X(sx, 2.3, 2.45)
        a.b(f"WingBar{side}0", (x0, 6.6, -0.6), (x1, 7.0, 2.6), GREY, wing)
        a.b(f"WingBar{side}1", (x0, 7.4, 0.2), (x1, 7.8, 2.6), GREY, wing)
        x0, x1 = X(sx, 1.8, 2.3)
        a.b("WingTip" + side, (x0, 5.6, 2.6), (x1, 8.0, 3.6), BLACK, wing)
    # tail: a fan of black feathers out the back, tipped up
    tail = a.bone("Tail", "root", (0, 7.6, 2.8))
    for i, (x, h) in enumerate(((-1.0, 2.0), (0.0, 2.6), (1.0, 2.0))):
        a.b(f"Tail{i}", (x - 0.45, 6.8, 2.8), (x + 0.45, 6.8 + h, 4.0 + 0.3 * (i == 1)), BLACK, tail)
    # neck rising forward into a huge boxy head
    head = a.bone("neck", "root", (0, 8.0, -2.2))
    a.b("Neck", (-1.1, 7.6, -3.8), (1.1, 10.4, -1.6), ORANGE, head)
    a.b("Head", (-1.7, 9.2, -6.6), (1.7, 12.6, -2.6), ORANGE, head)
    # the hooked beak: dark grey, a top that curls down at the tip, a lower jaw, the mouth open between
    a.b("Beak", (-1.4, 10.6, -9.0), (1.4, 12.0, -6.6), GREY, head)
    a.b("BeakHook", (-1.2, 9.6, -9.6), (1.2, 11.6, -9.0), GREY, head)
    a.b("Jaw", (-1.3, 9.0, -8.6), (1.3, 9.7, -6.6), GREY, head)
    a.b("Mouth", (-1.3, 9.7, -6.9), (1.3, 10.6, -6.6), MOUTH, head)  # the back of the open mouth
    # a zigzag of teeth down from the beak and up from the jaw
    for i, z in enumerate((-8.4, -7.7, -7.0)):
        for side, sx in SIDES:
            x = sx * 1.05
            a.pyr(f"Tooth{side}{i}", (x - 0.22, 10.6, z - 0.22), (x + 0.22, 10.6, z + 0.22), "-y", 0.6, TOOTH, head)
            a.pyr(f"ToothLow{side}{i}", (x - 0.18, 9.7, z + 0.15), (x + 0.18, 9.7, z + 0.5), "+y", 0.45, TOOTH, head)
    # eyes on the head's sides, under heavy black brows, and a black crest of spikes down the back of the head
    for side, sx in SIDES:
        a.side_eye(side, sx, 1.7, 10.8, 11.9, -5.8, -4.5, head, eye=EYE)
        x0, x1 = X(sx, 0.7, 1.8)
        a.b("Brow" + side, (x0, 11.9, -6.2), (x1, 12.6, -4.3), BLACK, head)
    for i, (y, z, length) in enumerate(((12.6, -4.6, 1.6), (12.6, -3.4, 1.9), (11.6, -2.6, 1.6))):
        if i < 2:
            a.pyr(f"Spike{i}", (-0.35, y, z - 0.35), (0.35, y, z + 0.35), "+y", length, BLACK, head)
        else:
            a.pyr(f"Spike{i}", (-0.35, y - 0.35, -2.6), (0.35, y + 0.35, -2.6), "+z", length, BLACK, head)
    a.meta = {"seat": (0, 8.6, 0.8), "neck_loop": {"center": (0, 11, -4.6), "radius": 2.0}}
    return a


def main(out=OUT):
    os.makedirs(out, exist_ok=True)
    a, model, parts = C.build(firebird)
    model["meta"]["format_version"] = "5.0"
    path = os.path.join(out, "Firebird.bbmodel")
    with open(path, "w") as f:
        json.dump(model, f, separators=(",", ":"))
    for p in parts:
        if p.name.startswith(("Eye", "Pupil", "Tooth", "Claw", "Spike", "Mouth")):
            p.plain = True
    lo, hi = C.bounds(parts)
    c = (lo + hi) / 2
    r = np.linalg.norm(hi - lo) / 2
    T = 480
    sheet = Image.new("RGB", (T * 3, T))
    for i, v in enumerate(((-19, 8, -21), (-30, 4, 0), (19, 12, 21))):
        v = np.array(v, float)
        eye = c + v / np.linalg.norm(v) * r / np.tan(np.radians(17)) * 1.05
        sheet.paste(render(parts, eye=eye, target=c, W=T, H=T, fov=34), (i * T, 0))
    A.label(sheet, ["Firebird", "side", "back"], 22).save(os.path.join(out, "Firebird.png"))
    # beside the Horse, both at model size
    horse = json.load(open(os.path.join(ROOT, "designs", "animals", "Horse.bbmodel")))
    cam = dict(eye=(-30, 12, -30), target=(0, 6, 0), W=T, H=T, fov=36)
    pair = Image.new("RGB", (T * 2, T))
    pair.paste(render(pose(horse, None, 0), **cam), (0, 0))
    pair.paste(render(parts, **cam), (T, 0))
    A.label(pair, ["Horse", "Firebird"], 22).save(os.path.join(out, "Firebird_vs_horse.png"))
    print("wrote", path, len(parts), "parts")



# ---------------------------------------------------------------- animations (on QM's file)
JAW_OPEN = -28  # degrees the lower jaw drops at its widest (-X on this hinge: its front goes down)


def add_jaw(m):
    """A Jaw bone under the neck, hinged at the back of the lower jaw, holding the jaw
    and its teeth (QM's file has them on the neck)."""
    from horse_rig import group
    if any(g["name"] == "Jaw" for g in m["groups"]):
        return
    jaw = next(e for e in m["elements"] if e["name"] == "Jaw")
    hinge = (0, jaw["to"][1], jaw["to"][2])  # top-back edge
    g = group("Jaw", hinge)
    m["groups"].append(g)
    moving = {e["uuid"] for e in m["elements"] if e["name"] == "Jaw" or e["name"].startswith("ToothLow")}
    neck = next(x for x in m["groups"] if x["name"] == "neck")

    def walk(node):
        if isinstance(node, str):
            return None
        if node["uuid"] == neck["uuid"]:
            return node
        for c in node["children"]:
            r = walk(c)
            if r:
                return r
        return None

    node = next(n for n in (walk(r) for r in m["outliner"]) if n)
    node["children"] = [c for c in node["children"] if c not in moving]
    node["children"].append({"uuid": g["uuid"], "isOpen": True, "children": sorted(moving)})


def animations(m):
    import math
    from snake_rig import track
    from snow_rig import bump, grounded
    s, TAU = math.sin, 2 * math.pi
    feet = {e["name"] for e in m["elements"] if e["name"].startswith(("Toe", "Heel", "Claw"))}

    def run(L, stride, lean, flap, bob, snap, hop, jaw, n=16):
        # a bird's run (as the Chicken's, +X leans nose-down): legs swing in turn, the
        # body leans in, the head thrusts forward twice a stride, wings and tail flap
        tr = {"root": [track(L, lambda u: (lean, 0, 2 * s(TAU * u)), n)]}
        for side, ph in (("L", 0.0), ("R", 0.5)):
            tr["Leg" + side] = [track(L, lambda u, ph=ph: (-lean + stride * s(TAU * (u + ph)), 0, 0), n)]
            sx = -1 if side == "L" else 1
            tr["Wing" + side] = [track(L, lambda u, sx=sx: (0, 0, sx * flap * (0.4 + 0.6 * abs(s(TAU * u)))), n)]
        tr["neck"] = [track(L, lambda u: (-lean * 0.6 + snap * s(2 * TAU * u), 0, 0), n),
                      track(L, lambda u: (0, 0, -bob * (0.5 + 0.5 * s(2 * TAU * u))), n, "position")]
        tr["Tail"] = [track(L, lambda u: (-6 - 6 * s(2 * TAU * u), 0, 0), n)]
        tr["Jaw"] = [track(L, lambda u: (jaw * (0.5 + 0.5 * s(2 * TAU * u + 1.0)), 0, 0), n)]  # chomps twice a stride
        tr["root"] = grounded(m, L, tr, feet, n, extra=lambda u: hop * abs(s(TAU * u)))
        return L, tr

    out = {}
    # idle: looks about, a snap of the beak at the air, wings ruffle once
    L = 3.2
    out["idle"] = (L, {
        "neck": [track(L, lambda u: (16 * bump(u, 0.6, 0.05) - 8 * bump(u, 0.68, 0.05), 25 * s(TAU * u), 0), 48)],
        "WingL": [track(L, lambda u: (0, 0, -25 * bump(u, 0.3, 0.06)), 32)],
        "WingR": [track(L, lambda u: (0, 0, 25 * bump(u, 0.3, 0.06)), 32)],
        "Tail": [track(L, lambda u: (-10 * bump(u, 0.3, 0.08), 0, 0), 32)],
        # the jaw hangs a little open, gapes wide just before the snap and claps shut on it
        "Jaw": [track(L, lambda u: (JAW_OPEN * (0.15 + 0.85 * bump(u, 0.55, 0.06) - 0.15 * bump(u, 0.62, 0.04)), 0, 0), 64)],
    })
    out["walk"] = run(0.8, stride=28, lean=4, flap=6, bob=4, snap=4, hop=0, jaw=JAW_OPEN * 0.3)
    out["gallop"] = run(0.4, stride=45, lean=16, flap=45, bob=6, snap=6, hop=8, jaw=JAW_OPEN)
    return out


def animate(src, dst, out=OUT):
    """Write idle, walk and gallop into QM's file (src) as dst, with preview GIFs."""
    import horse_rig
    horse_rig.EULER = "ZYX"  # QM's hand-made file
    from horse_rig import write_animations
    from snow_rig import group_ids, posed
    m = json.load(open(src))
    m["animations"] = []
    add_jaw(m)
    write_animations(m, group_ids(m), animations(m))
    with open(dst, "w") as f:
        json.dump(m, f, separators=(",", ":"))
    T = 420
    cams = [dict(eye=(-28, 14, -30), target=(0, 6, -1), W=T, H=T, fov=38), dict(eye=(-40, 7, -1), target=(0, 6, -1), W=T, H=T, fov=36)]

    def frame(name, t):
        anim = next(x for x in m["animations"] if x["name"] == name)
        ps = posed(m, anim, t)
        for p in ps:
            if p.name.startswith(("Eye", "Pupil", "Tooth", "Claw", "Spike", "Mouth")):
                p.plain = True
        im = Image.new("RGB", (T * 2, T))
        for i, c in enumerate(cams):
            im.paste(render(ps, **c), (i * T, 0))
        return A.label(im, [name, ""], 22)

    for name, n in (("idle", 24), ("walk", 14), ("gallop", 12)):
        L = next(x for x in m["animations"] if x["name"] == name)["length"]
        A.gif(os.path.join(out, f"Firebird_{name}.gif"), [frame(name, L * i / n) for i in range(n)], fps=n / L)

if __name__ == "__main__":
    if sys.argv[1:2] == ["animate"]:
        animate(*sys.argv[2:])
    else:
        main(*sys.argv[1:])
