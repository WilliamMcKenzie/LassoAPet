"""T-Rex: an XL (tier 4) animal, big and epic (QM, Oct 7).

Run: python3 tools/trex_design.py [out_dir]   takes A-C, renders and GIFs

Three takes for QM to pick from (same build, different coat and extras):
  A  Jungle   green, pale belly, dark stripes across the back and tail
  B  Lava     red with black stripes, orange belly, black spikes down the back
  C  Royal    purple, gold belly, a gold crown and gold claws

Built from flush blocks in the Meadow animals' style: a level body, a big
boxy head on the body's front with a lower jaw that opens (Jaw bone), real
block teeth, brow ridges and the Horse googly eyes on the head's sides. Two
huge legs on the body's flanks (LegHL, LegHR) and two tiny arms on the
chest (LegFL, LegFR, so it keeps the quadrupeds' bone names); a long tail
in tapering segments. Walk is a heavy stomp, the gallop a charge with the
jaw open in a roar.
"""

import json
import tempfile
import math
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import animal_designs as A  # noqa: E402
from animal_designs import Animal, at, pos_y, rot_x  # noqa: E402
from horse_rig import pose  # noqa: E402
from partlib import render  # noqa: E402

TOOTH = (252, 250, 236)
MOUTH = (150, 40, 50)
GOLD = (250, 200, 50)

TAKES = {
    "A": dict(label="Jungle", coat=(96, 172, 70), belly=(214, 226, 140), dark=(52, 110, 50), claw=(70, 70, 80)),
    "B": dict(label="Lava", coat=(214, 60, 46), belly=(255, 160, 50), dark=(46, 36, 44), claw=(46, 36, 44), spikes=True),
    "C": dict(label="Royal", coat=(132, 82, 214), belly=(250, 200, 50), dark=(88, 50, 160), claw=GOLD, crown=True),
}


def rot_y(keys, interp="catmullrom"):
    return {"channel": "rotation", "interp": interp, "keys": [(t, (0, v, 0)) for t, v in keys]}


def rot_xz(keys, interp="catmullrom"):
    return {"channel": "rotation", "interp": interp, "keys": [(t, (x, 0, z)) for t, (x, z) in keys]}


def trex(take="A"):
    t = TAKES[take]
    coat, belly, dark, claw = t["coat"], t["belly"], t["dark"], t["claw"]
    a = Animal("TRex", "Legendary")
    a.bone_order = [b for b in a.bone_order if not b[0].startswith("Ear")] + [("Jaw", "neck")]

    # body: level, a pale belly underneath, dark stripes across the back
    x, y0, y1, z0, z1 = 1.9, 4.2, 7.4, -2.6, 2.8
    a.dims = dict(x=x, y0=y0, y1=y1, z0=z0, z1=z1)
    a.pivots["root"] = (0, (y0 + y1) / 2, (z0 + z1) / 2)
    a.box("Belly", (-x, y0, z0), (x, 5.0, z1), belly, "root")
    a.box("Body", (-x, 5.0, z0), (x, y1 - 0.4, z1), coat, "root")
    cuts = [z0, -1.6, -1.0, 0.2, 0.8, 2.0, 2.4, z1]
    for i in range(len(cuts) - 1):
        a.box(f"Back{i + 1}", (-x, y1 - 0.4, cuts[i]), (x, y1, cuts[i + 1]), dark if i % 2 else coat, "root")
    if t.get("spikes"):
        for i, z in enumerate((-1.9, -0.4, 1.1)):
            a.wedge(f"Spike{i + 1}", (-0.35, y1, z), (0.35, y1 + 0.9, z + 0.9), dark, "root", "up_back")

    # neck and head: the neck bone pivots at the body's front-top edge
    a.box("Neck", (-1.4, 5.4, -4.0), (1.4, 8.0, z0 + 0.001), coat, "neck")
    hx, hy0, hy1, hz0, hz1 = 1.75, 7.0, 9.8, -8.6, -3.0
    a.box("Head", (-hx, hy0, hz0), (hx, hy1 - 0.4, hz1), coat, "neck")
    a.box("HeadTop", (-hx, hy1 - 0.4, hz0), (hx, hy1, -6.6), coat, "neck")
    a.box("HeadStripe", (-hx, hy1 - 0.4, -6.6), (hx, hy1, -5.8), dark, "neck")
    a.box("HeadBack", (-hx, hy1 - 0.4, -5.8), (hx, hy1, hz1), coat, "neck")
    # brow ridges over the eyes, nostrils on the snout's top front
    for side, sx in (("L", -1), ("R", 1)):
        xa, xb = sorted((sx * 0.9, sx * (hx + 0.15)))
        a.box("Brow" + side, (xa, hy1, -5.9), (xb, hy1 + 0.45, -4.4), dark, "neck")
        na, nb = sorted((sx * 0.5, sx * 1.0))
        a.box("Nostril" + side, (na, hy1 - 0.25, hz0 - 0.001), (nb, hy1 + 0.05, hz0 + 0.5), dark, "neck")
    a.eyes(hx, 8.0, 9.2, -5.7, -4.5)
    # upper teeth: real blocks hanging under the upper jaw's front and sides
    for i, tx in enumerate((-1.35, -0.45, 0.45, 1.35)):
        a.box(f"Tooth{i + 1}", (tx - 0.2, hy0 - 0.45, hz0 + 0.05), (tx + 0.2, hy0, hz0 + 0.45), TOOTH, "neck")
    for side, sx in (("L", -1), ("R", 1)):
        for i, tz in enumerate((-7.6, -6.6, -5.6)):
            xa, xb = sorted((sx * (hx - 0.4), sx * (hx - 0.05)))
            a.box(f"ToothS{side}{i + 1}", (xa, hy0 - 0.45, tz), (xb, hy0, tz + 0.4), TOOTH, "neck")
    if t.get("crown"):
        a.box("Crown", (-1.2, hy1, -5.4), (1.2, hy1 + 0.5, -3.4), GOLD, "neck")
        for i, cx in enumerate((-1.2, -0.2, 0.8)):
            a.box(f"CrownPt{i + 1}", (cx, hy1 + 0.5, -5.4), (cx + 0.4, hy1 + 1.2, -3.4), GOLD, "neck")
    a.pivots["neck"] = (0, 7.0, z0 - 0.05)

    # lower jaw: hinged at the head's back-bottom, opens with -X (its tip drops)
    jx = hx - 0.15
    a.box("Jaw", (-jx, 6.1, hz0 + 0.3), (jx, 6.6, hz1 - 0.2), coat, "Jaw")
    a.box("JawIn", (-jx, 6.6, hz0 + 0.3), (jx, 7.0, hz1 - 0.2), MOUTH, "Jaw")
    a.box("Chin", (-jx, 5.8, hz0 + 0.3), (jx, 6.1, hz1 - 0.6), belly, "Jaw")
    for i, tx in enumerate((-1.1, 1.1)):
        a.box(f"ToothLow{i + 1}", (tx - 0.2, 7.0, hz0 + 0.35), (tx + 0.2, 7.35, hz0 + 0.7), TOOTH, "Jaw")
    a.pivots["Jaw"] = (0, 6.6, hz1 - 0.3)

    # big legs on the body's flanks: thigh, shin, a three-toed foot with claws.
    # They pivot at the hip, high on the flank, so the thigh's top stays against the body.
    for side, sx in (("L", -1), ("R", 1)):
        name = "Leg" + ("HL" if side == "L" else "HR")
        xa, xb = sorted((sx * x, sx * (x + 1.4)))
        sa, sb = sorted((sx * (x + 0.2), sx * (x + 1.2)))
        a.box("Thigh" + side, (xa, 2.6, -1.0), (xb, 6.8, 2.4), coat, name)
        a.box("Shin" + side, (sa, 0.7, 0.5), (sb, 2.6, 1.9), coat, name)
        a.box("Foot" + side, (sa, 0, -1.0), (sb, 0.7, 2.1), dark, name)
        for i, f in enumerate((0.0, 0.32, 0.64)):
            ca = min(sa, sb) + f
            a.box(f"Claw{side}{i + 1}", (ca + 0.03, 0, -1.45), (ca + 0.23, 0.4, -1.0), claw, name)
        a.pivots[name] = ((xa + xb) / 2, 5.6, 0.7)

    # tiny arms on the chest: upper arm down, forearm forward, two claws
    for side, sx in (("L", -1), ("R", 1)):
        name = "Leg" + ("FL" if side == "L" else "FR")
        xa, xb = sorted((sx * 0.8, sx * 1.5))
        a.box("Arm" + side, (xa, 4.0, z0 - 0.7), (xb, 5.5, z0 - 0.001), coat, name)
        a.box("Fore" + side, (xa, 4.0, z0 - 1.6), (xb, 4.55, z0 - 0.7), coat, name)
        for i, f in enumerate((0.05, 0.35)):
            ca = min(xa, xb) + f
            a.box(f"Hand{side}{i + 1}", (ca, 3.65, z0 - 1.75), (ca + 0.25, 4.0, z0 - 1.4), claw, name)
        a.pivots[name] = ((xa + xb) / 2, 5.3, z0 - 0.3)

    # tail: tapering segments back from the rump, stripes on the top
    segs = [(z1, 5.8, 1.7, 4.4, 7.2), (5.8, 8.6, 1.25, 4.8, 6.9), (8.6, 10.9, 0.85, 5.2, 6.6), (10.9, 12.6, 0.45, 5.6, 6.3)]
    for i, (za, zb, w, ya, yb) in enumerate(segs):
        a.box(f"Tail{i + 1}" if i else "Tail", (-w, ya, za), (w, yb, zb), dark if i == 3 else coat, "Tail")
        if i < 3:
            a.box(f"TailBand{i + 1}", (-w - 0.001, ya + 0.001, zb - 0.6), (w + 0.001, yb + 0.001, zb), dark, "Tail")
    if t.get("spikes"):
        for i, (z, w) in enumerate(((3.6, 0.3), (6.4, 0.25))):
            ytop = segs[0][4] if i == 0 else segs[1][4]
            a.wedge(f"TailSpike{i + 1}", (-w, ytop, z), (w, ytop + 0.7, z + 0.7), dark, "Tail", "up_back")
    a.pivots["Tail"] = (0, 5.8, z1)

    a.meta = {"seat": (0, 7.4, 0.6), "neck_loop": {"center": (0, 8.4, -5.8), "radius": 2.6}}
    a.animations = animations
    return a


def animations():
    # idle: slow breath, head looks round, the jaw snaps open once, tail sways
    L = 3.0
    idle = (L, {
        "root": [pos_y([(0, 0), (1.5, 1.5), (3.0, 0)])],
        "neck": [rot_y([(0, 0), (0.8, 10), (1.6, 10), (2.3, -6), (3.0, 0)])],
        "Jaw": [rot_x([(0, 0), (1.9, 0), (2.05, -28), (2.4, -28), (2.6, 0), (3.0, 0)], "catmullrom")],
        "Tail": [rot_y([(0, -6), (1.5, 6), (3.0, -6)])],
        "LegFL": [rot_x([(0, 0), (0.75, 15), (1.5, 0), (2.25, 15), (3.0, 0)], "catmullrom")],
        "LegFR": [rot_x([(0, 15), (0.75, 0), (1.5, 15), (2.25, 0), (3.0, 15)], "catmullrom")],
    })
    return {"idle": idle, "walk": stride(1.1, 24, 4, 6, 0), "gallop": stride(0.6, 34, 12, 10, 26)}


def stride(L, swing, bob, sway, jaw):
    """Two-legged stride: legs swing (+X forward) back and forth, out of step. The body
    dips while the legs are spread (the planted foot stays on the floor) and
    rolls onto the planted leg; the tail and head swing against the roll."""
    legL = at(L, [(0, swing), (0.25, 0), (0.5, -swing), (0.75, 0), (1, swing)])
    legR = at(L, [(0, -swing), (0.25, 0), (0.5, swing), (0.75, 0), (1, -swing)])
    lean = 5 if jaw else 0  # the charge leans nose-down
    dip = -56 * (1 - math.cos(math.radians(swing)))  # hip 5.6 studs (56 units) up
    return (L, {
        "root": [
            pos_y(at(L, [(0, dip), (0.25, bob), (0.5, dip), (0.75, bob), (1, dip)])),
            rot_xz(at(L, [(0, (-lean, -3)), (0.5, (-lean, 3)), (1, (-lean, -3))])),
        ],
        "LegHL": [rot_x(legL, "catmullrom")],
        "LegHR": [rot_x(legR, "catmullrom")],
        "LegFL": [rot_x(at(L, [(0, 30), (0.5, 5), (1, 30)]), "catmullrom")],
        "LegFR": [rot_x(at(L, [(0, 5), (0.5, 30), (1, 5)]), "catmullrom")],
        "neck": [rot_xz(at(L, [(0, (-4, 2)), (0.25, (2, 0)), (0.5, (-4, -2)), (0.75, (2, 0)), (1, (-4, 2))]))],
        "Jaw": [rot_x(at(L, [(0, -jaw), (0.5, -jaw * 0.8), (1, -jaw)]), "catmullrom")],
        "Tail": [rot_y(at(L, [(0, sway), (0.5, -sway), (1, sway)]))],
    })


def game_size(m):
    """Size the way Config does it: sqrt of the two biggest sides of the model box."""
    pts = []
    for e in m["elements"]:
        if "from" in e:
            pts += [e["from"], e["to"]]
        elif "vertices" in e:
            o = e.get("origin", [0, 0, 0])
            pts += [[o[i] + v[i] for i in range(3)] for v in e["vertices"].values()]
    p = np.array(pts, float) / 10
    s = sorted(p.max(0) - p.min(0))
    return (s[1] * s[2]) ** 0.5


def main(out="/mnt/project-files/animals/trex"):
    os.makedirs(out, exist_ok=True)
    scratch = tempfile.mkdtemp()
    root = os.path.join(A.ROOT, "designs", "animals")
    horse = json.load(open(os.path.join(root, "Horse.bbmodel")))
    rexes, names = [], []
    for k, t in TAKES.items():
        a = trex(k)
        a.name = f"TRex_{k}"
        m = A.build_animal(a, out)
        m["meta"]["format_version"] = "5.0"
        with open(os.path.join(out, a.name + ".bbmodel"), "w") as f:
            json.dump(m, f, separators=(",", ":"))
        with open(os.path.join(out, a.name + "_meta.json"), "w") as f:
            json.dump(dict(rarity=a.rarity, **a.meta), f, indent=1)
        rexes.append(m)
        names.append(f"{k}: {t['label']}")
        print(a.name, len(a.parts), "parts, size", round(game_size(m), 2))

    # lineup: the Horse beside each T-Rex at their in-game sizes (tier 1 = 10.4 studs, tier 4 = 10.4 x 1.6^3)
    k = (10.4 * 1.6 ** 3 / game_size(rexes[0])) / (10.4 / game_size(horse))
    horse_parts = pose(horse, None, 0)
    for q in horse_parts:
        q.polys = [poly + np.array([14.0, 0, -30.0]) for poly in q.polys]
    wide = dict(eye=(-72, 34, -78), target=(2, 14, -6), W=640, H=560, fov=40, fog=False)
    tiles = []
    for key in TAKES:
        a = trex(key)
        a.name = f"TRex_{key}_xl"
        a.scale(k)
        big = A.build_animal(a, scratch)
        tiles.append(render(pose(big, None, 0) + horse_parts, **wide))
    im = Image.new("RGB", (640 * 3, 560))
    for i, tile in enumerate(tiles):
        im.paste(tile, (640 * i, 0))
    A.label(im, [f"{n} (XL, in-game size) next to the Horse" for n in names], 22).save(os.path.join(out, "trex_size.png"))

    close = dict(eye=(-22, 14, -24), target=(0, 5.6, -1.5), W=460, H=460, fov=40)
    side = dict(eye=(-34, 7, 0), target=(0, 5.2, 1.5), W=460, H=460, fov=40)
    rows = [A.label(A.strip(rexes, cam=close), names, 24), A.label(A.strip(rexes, cam=side), [""] * 3, 24)]
    im = Image.new("RGB", (rows[0].width, rows[0].height + rows[1].height), (255, 255, 255))
    im.paste(rows[0], (0, 0))
    im.paste(rows[1], (0, rows[0].height))
    im.save(os.path.join(out, "trex_takes.png"))
    n = 16
    for anim, length in (("gallop", 0.6), ("walk", 1.1)):
        frames = [A.label(A.strip(rexes, anim, i / n, close), names, 24).resize((900, 336)) for i in range(n)]
        A.gif(os.path.join(out, f"trex_{anim}.gif"), frames, fps=n / length)
    print("written to", out)


if __name__ == "__main__":
    main(*sys.argv[1:])
