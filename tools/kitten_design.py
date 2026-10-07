"""Kitten: an Uncommon Desert animal in the Meadow animals' style (QM, Oct 7).

Run: python3 tools/kitten_design.py [out_dir]          takes A-C
     python3 tools/kitten_design.py ginger [out_dir]   takes D-E, from QM's reference picture

Three takes for QM to pick from (same build, different coat):
  A  Sand cat  sandy tan, cream muzzle and paws, dark ear tips and tail rings
  B  Ginger    orange tabby with darker stripes across its back and tail
  C  Siamese   cream with dark brown ears, mask, paws and tail

Built like the Bunny and the Pig: one body block, the head on the body's
front (raised), Horse googly eyes on the head's sides. Kitten tweaks: pointed
ears from real triangular prisms (pink prisms inside, no plates), a small
muzzle with a pink nose, slim legs with light paws, and a tail that stands
straight up. Same bones as every quadruped (root, neck, EarL, EarR, Tail,
Leg*) and the same rules: front legs swing forward, hind legs kick back, ears
fold back. Walk is QM's horse walk, the gallop the shared leap (a pounce).
"""

import json
import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import animal_designs as A  # noqa: E402
from animal_designs import Animal, EYE_WHITE, PINK, PUPIL, quad_animations  # noqa: E402

TAKES = {
    "A": dict(label="Sand cat", coat=(226, 186, 128), light=(252, 240, 214), dark=(120, 84, 52)),
    "B": dict(label="Ginger", coat=(240, 146, 60), light=(255, 236, 210), dark=(196, 96, 30), stripes=True),
    "C": dict(label="Siamese", coat=(246, 232, 204), light=(246, 232, 204), dark=(92, 62, 48), points=True),
}
NOSE = (240, 110, 150)


def kitten(take="A"):
    t = TAKES[take]
    coat, light, dark = t["coat"], t["light"], t["dark"]
    points = t.get("points")
    a = Animal("Kitten", "Uncommon")
    # body: the Bunny's size, slimmer; the ginger gets stripes across its back
    bands = None
    if t.get("stripes"):
        bands = [(-2.2, -1.2, coat), (-1.2, -0.7, dark), (-0.7, 0.5, coat), (0.5, 1.0, dark), (1.0, 2.0, coat), (2.0, 2.5, dark), (2.5, 3.0, coat)]
    a.body(1.4, 1.8, 4.4, -2.2, 3.0, coat, bands)
    d = a.dims
    paw = dark if points else light
    for leg in ("FL", "FR", "HL", "HR"):
        sx = -1 if leg[1] == "L" else 1
        front = leg[0] == "F"
        xa, xb = sorted((sx * 0.5, sx * 1.3))
        z0 = d["z0"] + 0.001 if front else d["z1"] - 0.001 - 0.9
        z1 = z0 + 0.9
        name = "Leg" + leg
        a.box(name, (xa, 0.4, z0), (xb, d["y0"], z1), coat, name)
        a.box("Hoof" + leg, (xa, 0, z0), (xb, 0.4, z1), paw, name)
        a.pivots[name] = ((xa + xb) / 2, d["y0"] - 0.025, z1 - 0.05 if front else z0 + 0.05)
    # head on the body's front, raised above it; the Siamese's face is its dark front slice
    head = dark if points else coat
    if points:
        a.box("Head", (-1.4, 3.4, -4.0), (1.4, 6.0, -2.199), coat, "neck")
        a.box("Mask", (-1.4, 3.4, -4.6), (1.4, 6.0, -4.0), dark, "neck")
    else:
        a.box("Head", (-1.4, 3.4, -4.6), (1.4, 6.0, -2.199), coat, "neck")
    a.box("Muzzle", (-0.7, 3.4, -5.1), (0.7, 4.2, -4.6), light if not points else dark, "neck")
    a.box("Nose", (-0.25, 3.95, -5.25), (0.25, 4.3, -5.1), NOSE, "neck")
    a.eyes(1.4, 4.5, 5.5, -4.3, -3.3)
    a.pivots["neck"] = (0, 4.4, -2.25)
    # pointed ears: two triangular-prism halves meeting at the tip, a smaller
    # pink pair set into the front, dark tips on the plain coats
    for side, sx in (("L", -1), ("R", 1)):
        bone = "Ear" + side
        c = sx * 0.85
        for half, dx in (("A", -1), ("B", 1)):
            a.tri(f"{bone}{half}", [(c, 6.0), (c + dx * 0.55, 6.0), (c, 7.5)], -3.6, -3.1, head, bone)
            a.tri(f"{bone}In{half}", [(c, 6.0), (c + dx * 0.33, 6.0), (c, 6.9)], -3.7, -3.6, PINK, bone)
            if not points:
                a.tri(f"{bone}Tip{half}", [(c, 7.05), (c + dx * 0.165, 7.05), (c, 7.5)], -3.62, -3.08, dark, bone)
        a.pivots[bone] = (c, 6.0, -3.7)
    # tail stands straight up off the rump, rings near the tip
    tail = dark if points else coat
    a.box("Tail", (-0.3, 4.4, 3.0), (0.3, 6.6, 3.6), tail, "Tail")
    a.box("TailBase", (-0.3, 3.8, 3.0), (0.3, 4.4, 3.6), tail, "Tail")
    if not points:
        for i, y in enumerate((5.6, 6.6)):
            a.box(f"TailRing{i + 1}", (-0.3, y, 3.0), (0.3, y + 0.4, 3.6), dark, "Tail")
    a.pivots["Tail"] = (0, 4.4, 3.0)
    a.meta = {"seat": (0, 5.2, 0.8), "neck_loop": {"center": (0, 4.6, -3.4), "radius": 1.8}}
    a.animations = quad_animations
    return a


WHITE = (255, 250, 242)


def ginger(tail_up=True):
    """QM's reference (Oct 7): a chibi ginger tabby, big head with front-facing
    eyes (like the Pig's), white muzzle, chest and paws, stripes across the
    forehead and back, big pink-lined ears, a striped tail with a white tip."""
    coat, dark = (244, 150, 58), (204, 104, 34)
    a = Animal("Kitten", "Uncommon")
    x, y0, y1, z0, z1 = 1.4, 1.8, 4.2, -2.2, 3.0
    a.dims = dict(x=x, y0=y0, y1=y1, z0=z0, z1=z1)
    a.pivots["root"] = (0, (y0 + y1) / 2, (z0 + z1) / 2)
    # white chest on the front, then coat and dark stripes in slices
    a.box("Chest", (-x, y0, z0), (x, y1, -1.4), WHITE, "root")
    for i, (za, zb, c) in enumerate(((-1.4, -0.6, coat), (-0.6, -0.1, dark), (-0.1, 0.8, coat), (0.8, 1.3, dark),
                                     (1.3, 2.2, coat), (2.2, 2.6, dark), (2.6, z1, coat))):
        a.box(f"Body{i + 1}", (-x, y0, za), (x, y1, zb), c, "root")
    for leg in ("FL", "FR", "HL", "HR"):
        sx = -1 if leg[1] == "L" else 1
        front = leg[0] == "F"
        xa, xb = sorted((sx * 0.45, sx * 1.35))
        za = z0 + 0.001 if front else z1 - 0.001 - 1.0
        zb = za + 1.0
        name = "Leg" + leg
        a.box(name, (xa, 0.5, za), (xb, y0, zb), coat, name)
        a.box("Hoof" + leg, (xa, 0, za), (xb, 0.5, zb), WHITE, name)
        a.pivots[name] = ((xa + xb) / 2, y0 - 0.025, zb - 0.05 if front else za + 0.05)
    # the big head, its top in stripes running back from the forehead
    hx, hy0, hy1, hz0, hz1 = 1.8, 3.0, 6.2, -5.0, -1.999
    a.box("Head", (-hx, hy0, hz0), (hx, hy1 - 0.5, hz1), coat, "neck")
    edges = [-hx, -1.0, -0.6, -0.2, 0.2, 0.6, 1.0, hx]
    for i in range(len(edges) - 1):
        a.box(f"Crown{i + 1}", (edges[i], hy1 - 0.5, hz0), (edges[i + 1], hy1, hz1), dark if i % 2 else coat, "neck")
    a.box("Muzzle", (-1.0, hy0, -5.6), (1.0, 4.3, hz0), WHITE, "neck")
    a.box("Nose", (-0.3, 3.9, -5.75), (0.3, 4.3, -5.6), NOSE, "neck")
    # Horse googly eyes, on the face like the Pig's, pupils toward the middle
    for side, sx in (("L", -1), ("R", 1)):
        xa, xb = sorted((sx * 0.35, sx * 1.35))
        a.box("Eye" + side, (xa, 4.5, hz0 - 0.05), (xb, 5.5, hz0), EYE_WHITE, "neck")
        pa, pb = sorted((sx * 0.4, sx * 0.9))
        a.box("Pupil" + side, (pa, 4.55, hz0 - 0.08), (pb, 5.15, hz0 - 0.05), PUPIL, "neck")
    a.pivots["neck"] = (0, 4.2, -2.05)
    # big pointed ears: two prism halves meeting at the tip, pink pair inside
    for side, sx in (("L", -1), ("R", 1)):
        bone = "Ear" + side
        c = sx * 1.1
        for half, dx in (("A", -1), ("B", 1)):
            a.tri(f"{bone}{half}", [(c, hy1), (c + dx * 0.7, hy1), (c, hy1 + 1.9)], -4.0, -3.4, coat, bone)
            a.tri(f"{bone}In{half}", [(c, hy1), (c + dx * 0.45, hy1), (c, hy1 + 1.25)], -4.1, -4.0, PINK, bone)
        a.pivots[bone] = (c, hy1, -4.1)
    # tail off the rump: straight up, or out and up at the tip; a dark ring, a white tip
    if tail_up:
        parts = [("Tail", (-0.35, 3.6, z1), (0.35, 4.2, 3.7), coat),
                 ("Tail2", (-0.35, 4.2, 3.0), (0.35, 5.2, 3.7), coat),
                 ("TailRing", (-0.35, 5.2, 3.0), (0.35, 5.6, 3.7), dark),
                 ("Tail3", (-0.35, 5.6, 3.0), (0.35, 6.4, 3.7), coat),
                 ("TailTip", (-0.35, 6.4, 3.0), (0.35, 7.2, 3.7), WHITE)]
    else:
        parts = [("Tail", (-0.35, 3.4, z1), (0.35, 4.1, 4.2), coat),
                 ("TailRing", (-0.35, 3.4, 4.2), (0.35, 4.1, 4.6), dark),
                 ("Tail2", (-0.35, 3.4, 4.6), (0.35, 4.1, 5.4), coat),
                 ("TailTip", (-0.35, 4.1, 4.7), (0.35, 5.3, 5.4), WHITE)]
    for name, lo, hi, c in parts:
        a.box(name, lo, hi, c, "Tail")
    a.pivots["Tail"] = (0, 4.2, z1)
    a.meta = {"seat": (0, 5.0, 0.9), "neck_loop": {"center": (0, 4.6, -3.5), "radius": 2.1}}
    a.animations = quad_animations
    return a


def main_ginger(out="/mnt/project-files/animals/kitten"):
    takes = [("D", "D: Ginger, tail up", ginger(True)), ("E", "E: Ginger, tail out", ginger(False))]
    models, names = [], []
    for k, label, a in takes:
        a.name = f"Kitten_{k}"
        m = A.build_animal(a, out)
        m["meta"]["format_version"] = "5.0"
        with open(os.path.join(out, a.name + ".bbmodel"), "w") as f:
            json.dump(m, f, separators=(",", ":"))
        with open(os.path.join(out, a.name + "_meta.json"), "w") as f:
            json.dump(dict(rarity=a.rarity, **a.meta), f, indent=1)
        models.append(m)
        names.append(label)
        print(a.name, len(a.parts), "parts")
    close = dict(eye=(-13, 8, -18), target=(0, 3.9, -1.0), W=460, H=460, fov=34)
    back = dict(eye=(-14, 9, 15), target=(0, 3.9, 0.5), W=460, H=460, fov=34)
    rows = [A.label(A.strip(models, cam=close), names, 24), A.label(A.strip(models, cam=back), [""] * 2, 24)]
    im = Image.new("RGB", (rows[0].width * 2, rows[0].height), (255, 255, 255))
    im.paste(rows[0], (0, 0))
    im.paste(rows[1], (rows[0].width, 0))
    im.save(os.path.join(out, "kitten_ginger.png"))
    root = os.path.join(A.ROOT, "designs", "animals")
    line = [json.load(open(os.path.join(root, n + ".bbmodel"))) for n in ("Horse", "Bunny")] + models
    A.label(A.strip(line), ["Horse", "Bunny"] + names, 18).save(os.path.join(out, "kitten_ginger_lineup.png"))
    side = dict(eye=(-24, 5, -1), target=(0, 4.2, -0.8), W=420, H=420, fov=34)
    n = 16
    frames = [A.label(A.strip(models, "gallop", i / n, side), names, 22).resize((640, 330)) for i in range(n)]
    A.gif(os.path.join(out, "kitten_ginger_gallop.gif"), frames, fps=n / 0.8)


def main(out="/mnt/project-files/animals/kitten"):
    os.makedirs(out, exist_ok=True)
    root = os.path.join(A.ROOT, "designs")
    horse = json.load(open(os.path.join(root, "animals", "Horse.bbmodel")))
    bunny = json.load(open(os.path.join(root, "animals", "Bunny.bbmodel")))
    cats, names = [], []
    for k, t in TAKES.items():
        a = kitten(k)
        a.name = f"Kitten_{k}"
        m = A.build_animal(a, out)
        m["meta"]["format_version"] = "5.0"
        with open(os.path.join(out, a.name + ".bbmodel"), "w") as f:
            json.dump(m, f, separators=(",", ":"))
        with open(os.path.join(out, a.name + "_meta.json"), "w") as f:
            json.dump(dict(rarity=a.rarity, **a.meta), f, indent=1)
        cats.append(m)
        names.append(f"{k}: {t['label']}")
        print(a.name, len(a.parts), "parts")

    close = dict(eye=(-15, 9, -17), target=(0, 3.8, -0.8), W=420, H=420, fov=34)
    side = dict(eye=(-24, 5, -1), target=(0, 4.2, -0.8), W=420, H=420, fov=34)
    rows = [A.label(A.strip(cats, cam=close), names, 24), A.label(A.strip(cats, cam=side), [""] * 3, 24)]
    im = Image.new("RGB", (rows[0].width, rows[0].height + rows[1].height), (255, 255, 255))
    im.paste(rows[0], (0, 0))
    im.paste(rows[1], (0, rows[0].height))
    im.save(os.path.join(out, "kitten_takes.png"))
    A.label(A.strip([horse, bunny] + cats), ["Horse", "Bunny"] + names).save(os.path.join(out, "kitten_lineup.png"))
    n = 16
    frames = [A.label(A.strip(cats, "gallop", i / n, side), names, 24).resize((840, 312)) for i in range(n)]
    A.gif(os.path.join(out, "kitten_gallop.gif"), frames, fps=n / 0.8)
    print("written to", out)


if __name__ == "__main__":
    if sys.argv[1:2] == ["ginger"]:
        main_ginger(*sys.argv[2:])
    else:
        main(*sys.argv[1:])
