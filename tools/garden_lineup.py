"""One lineup image of the Garden animals next to the Horse, for review.

Run: python3 tools/garden_lineup.py  ->  /mnt/project-files/world3/garden/renders/Garden_lineup.png
Row 1: the six standard animals; row 2: the giga rares and the boss (model size, before any in-game scale).
"""

import json
import os

import numpy as np
from PIL import Image

import garden_lib as G
import animal_designs as A
from horse_rig import pose
from partlib import render

ROWS = [[("Horse (for size)", None), ("Ladybug - Uncommon", "garden/Ladybug"), ("Bumblebee - Uncommon", "garden/Bumblebee"),
         ("Toadstool Frog - Rare", "garden/ToadstoolFrog"), ("Vine Monster - Rare", "garden/VineMonster"),
         ("Venus Flytrap - Epic", "garden/VenusFlytrap"), ("Sunflower Lion - Legendary", "garden/SunflowerLion")],
        [("Horse (for size)", None), ("Rafflesia Beast - giga rare", "garden/RafflesiaBeast"),
         ("Ancient Treant - giga rare", "garden/AncientTreant"), ("Flytrap Queen - boss", "bosses/FlytrapQueen")]]


def parts_for(path):
    if path is None:
        return pose(A.qm_horse("A"), None, 0)
    return G.posed(json.load(open(os.path.join(G.ROOT, "designs", path + ".bbmodel"))))


def row(items, W, H, dist, ty):
    out = Image.new("RGB", (W * len(items), H))
    for i, (_, path) in enumerate(items):
        ps = parts_for(path)
        lo, hi = G.bounds(ps)
        c = np.array([(lo[0] + hi[0]) / 2, ty, (lo[2] + hi[2]) / 2])
        v = np.array([-0.55, 0.3, -1.0])
        out.paste(render(ps, eye=c + v / np.linalg.norm(v) * dist, target=c, W=W, H=H, fov=30), (i * W, 0))
    return A.label(out, [n for n, _ in items], 18)


def main():
    r1 = row(ROWS[0], 340, 360, 48, 7)
    r2 = row(ROWS[1], 595, 520, 88, 15.5)
    out = Image.new("RGB", (max(r1.width, r2.width), r1.height + r2.height), (255, 255, 255))
    out.paste(r1, (0, 0))
    out.paste(r2, (0, r1.height))
    path = os.path.join(G.OUT, "renders", "Garden_lineup.png")
    out.save(path)
    print(path, out.size)


if __name__ == "__main__":
    main()
