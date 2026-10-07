"""Kitten: an Uncommon Desert animal in the Meadow animals' style (QM, Oct 7).

Run: python3 tools/kitten_design.py [out_dir]

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
from animal_designs import Animal, PINK, quad_animations  # noqa: E402

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
    main(*sys.argv[1:])
