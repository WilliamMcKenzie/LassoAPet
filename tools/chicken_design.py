"""Giant Chicken: a Meadow animal that looks like the Minecraft chicken (QM Oct 10:
"very simple and dumb"), in our studded-block style.

Run: python3 tools/chicken_design.py [out_dir]    the takes, previews and run loops

Two takes on the same build:
  A  Classic   the Minecraft chicken as is: white box body, tall box head,
               yellow beak, red wattle, little wing slabs, stick legs, no tail
  B  Farm      A plus a red comb on top and a stubby white tail block

Built like the Penguin (two legs, two wings): bones root, neck (head, beak,
wattle), WingL/WingR, LegL/LegR (+ Tail on take B). Horse googly eyes on the
head's sides. No LegFL, so its run kicks up no dust. Animations: idle (pecks
and looks about), walk (a strut with the head bobbing back and forth) and
gallop (a frantic run, wings flapping, leaning forward).
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
from convert_designs import Conv, SIDES, X  # noqa: E402
from horse_rig import write_animations, pose  # noqa: E402
from partlib import render  # noqa: E402
from snake_rig import track  # noqa: E402
from snow_rig import group_ids, grounded, posed, as_anim, bump  # noqa: E402

ROOT = os.path.join(os.path.dirname(__file__), "..")
OUT = "/mnt/project-files/animals/chicken"
TAU = 2 * math.pi

COL = dict(white=(250, 250, 246), wing=(230, 230, 224), beak=(255, 196, 40),
           wattle=(232, 44, 52), leg=(255, 168, 36))
TAKES = {"A": "Classic", "B": "Farm"}


def chicken(take="A"):
    c = COL
    a = Conv("Chicken", "Rare", 1.0)
    a.pivots["root"] = (0, 4.8, 0)
    # legs: thin sticks under the middle of the body, flat feet with a toe poking forward
    for side, sx in SIDES:
        leg = a.bone("Leg" + side, "root", (sx * 0.9, 3.0, 0))
        x0, x1 = X(sx, 0.6, 1.2)
        a.b("Leg" + side, (x0, 0.4, -0.3), (x1, 3.0, 0.3), c["leg"], leg)
        x0, x1 = X(sx, 0.3, 1.5)
        a.b("Foot" + side, (x0, 0, -0.9), (x1, 0.4, 0.3), c["leg"], leg)
        x0, x1 = X(sx, 0.6, 1.2)
        a.b("Toe" + side, (x0, 0, -1.5), (x1, 0.4, -0.9), c["leg"], leg)
    # body: one white box
    a.b("Body", (-1.8, 3.0, -2.4), (1.8, 6.6, 2.4), c["white"], "root")
    # wings: slabs on the body's sides, hinged at the top
    for side, sx in SIDES:
        wing = a.bone("Wing" + side, "root", (sx * 1.8, 6.6, 0))
        x0, x1 = X(sx, 1.8, 2.4)
        a.b("Wing" + side, (x0, 4.2, -1.8), (x1, 6.6, 1.8), c["wing"], wing)
    # head: a tall box out the front, the beak and the red wattle on its face
    head = a.bone("neck", "root", (0, 5.4, -2.4))
    a.b("Head", (-1.2, 5.4, -4.2), (1.2, 9.0, -2.1), c["white"], head)
    a.b("Beak", (-1.2, 6.6, -5.4), (1.2, 7.8, -4.2), c["beak"], head)
    a.b("Wattle", (-0.6, 5.4, -4.8), (0.6, 6.6, -4.2), c["wattle"], head)
    for side, sx in SIDES:
        a.side_eye(side, sx, 1.2, 7.8, 8.8, -4.0, -3.0, head)
    if take == "B":
        a.b("Comb", (-0.3, 9.0, -3.9), (0.3, 9.9, -2.4), c["wattle"], head)
        a.b("CombTop", (-0.3, 9.9, -3.6), (0.3, 10.5, -3.0), c["wattle"], head)
        tail = a.bone("Tail", "root", (0, 6.0, 2.4))
        a.b("Tail", (-1.2, 5.4, 2.4), (1.2, 7.8, 3.3), c["white"], tail)
    a.meta = {"seat": (0, 7.4, 0.6), "neck_loop": {"center": (0, 7.2, -3.2), "radius": 1.9}}
    return a


FEET = {"FootL", "FootR", "ToeL", "ToeR"}


def animations(m, tail=False):
    s = math.sin
    out = {}

    def run(L, stride, lean, flap, flap_rate, head_bob, hop, n=16):
        tr = {"root": [track(L, lambda u: (lean, 0, 3 * s(TAU * u)), n)]}
        for side, ph in (("L", 0.0), ("R", 0.5)):
            tr["Leg" + side] = [track(L, lambda u, ph=ph: (-lean + stride * s(TAU * (u + ph)), 0, 0), n)]
            sx = -1 if side == "L" else 1
            tr["Wing" + side] = [track(L, lambda u, sx=sx: (0, 0, sx * flap * (0.5 + 0.5 * s(TAU * flap_rate * u))), n)]
        # the dumb head bob: the head thrusts forward and snaps back, twice a stride
        tr["neck"] = [track(L, lambda u: (-lean * 0.7, 0, 0), n),
                      track(L, lambda u: (0, 0, -head_bob * (0.5 + 0.5 * s(2 * TAU * u))), n, "position")]
        if tail:
            tr["Tail"] = [track(L, lambda u: (8 * s(2 * TAU * u), 0, 0), n)]
        tr["root"] = grounded(m, L, tr, FEET, n, extra=lambda u: hop * abs(s(TAU * u)))
        return L, tr

    # idle: looks about, pecks the ground now and then
    L = 3.0
    idle = {"neck": [track(L, lambda u: (-55 * bump(u, 0.55, 0.06) - 55 * bump(u, 0.7, 0.06), 30 * s(TAU * u), 0), 48)],
            "WingL": [track(L, lambda u: (0, 0, -18 * bump(u, 0.25, 0.05)), 32)],
            "WingR": [track(L, lambda u: (0, 0, 18 * bump(u, 0.25, 0.05)), 32)]}
    if tail:
        idle["Tail"] = [track(L, lambda u: (0, 10 * s(2 * TAU * u), 0), 12)]
    out["idle"] = (L, idle)
    out["walk"] = run(0.7, stride=30, lean=0, flap=8, flap_rate=1, head_bob=6, hop=0)
    out["gallop"] = run(0.36, stride=50, lean=14, flap=70, flap_rate=2, head_bob=8, hop=6)
    return out


def build(take):
    a, model, parts = C.build(lambda: chicken(take))
    write_animations(model, group_ids(model), animations(model, tail=take == "B"))
    model["meta"]["format_version"] = "5.0"
    a.name = f"Chicken_{take}"
    return a, model, parts


def frame(model, anim, t, cam):
    ps = posed(model, next(x for x in model["animations"] if x["name"] == anim) if anim else None, t)
    for p in ps:
        if p.name.startswith(C.PLAIN):
            p.plain = True
    return render(ps, **cam)


def sheet(ims):
    im = Image.new("RGB", (sum(i.width for i in ims), ims[0].height), (255, 255, 255))
    x = 0
    for i in ims:
        im.paste(i, (x, 0))
        x += i.width
    return im


def main(out=OUT):
    os.makedirs(out, exist_ok=True)
    built = {k: build(k) for k in TAKES}
    for k, (a, model, parts) in built.items():
        with open(os.path.join(out, a.name + ".bbmodel"), "w") as f:
            json.dump(model, f, separators=(",", ":"))
        print(a.name, len(parts), "parts")

    W = 420
    close = dict(eye=(-16, 11, -18), target=(0, 5.0, -0.8), W=W, H=W, fov=36)
    side = dict(eye=(-26, 5, -1), target=(0, 5.2, -0.8), W=W, H=W, fov=34)
    back = dict(eye=(14, 12, 18), target=(0, 5.0, 0), W=W, H=W, fov=36)
    rows = []
    for k, (a, model, parts) in built.items():
        rows.append(A.label(sheet([frame(model, None, 0, c) for c in (close, side, back)]),
                            [f"{k}: {TAKES[k]}", "side", "back"], 22))
    im = Image.new("RGB", (rows[0].width, sum(r.height for r in rows)), (255, 255, 255))
    y = 0
    for r in rows:
        im.paste(r, (0, y))
        y += r.height
    im.save(os.path.join(out, "chicken_takes.png"))

    # beside the Meadow herd, at design size (the game sizes it by its tier)
    horse = json.load(open(os.path.join(ROOT, "designs", "animals", "Horse.bbmodel")))
    pig = json.load(open(os.path.join(ROOT, "designs", "animals", "Pig.bbmodel")))
    tiles = [render(pose(horse, None, 0), **A.Q34), render(pose(pig, None, 0), **A.Q34)]
    tiles += [frame(m, None, 0, A.Q34) for _, m, _ in built.values()]
    A.label(sheet(tiles), ["Horse", "Pig"] + [f"Chicken {k}" for k in TAKES]).save(os.path.join(out, "chicken_lineup.png"))

    # loops
    for name, n in (("gallop", 16), ("walk", 14), ("idle", 30)):
        frames = []
        for i in range(n):
            ims = []
            for k, (a, model, parts) in built.items():
                L = next(x for x in model["animations"] if x["name"] == name)["length"]
                ims.append(frame(model, name, L * i / n, side))
            frames.append(A.label(sheet(ims), [f"{k}: {TAKES[k]}" for k in TAKES], 22))
        L = next(x for x in built["A"][1]["animations"] if x["name"] == name)["length"]
        A.gif(os.path.join(out, f"chicken_{name}.gif"), frames, fps=n / L)
    print("written to", out)


if __name__ == "__main__":
    main(*sys.argv[1:])
