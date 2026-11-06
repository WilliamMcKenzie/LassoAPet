"""Zebra: World 1 Meadow's Uncommon (QM, Nov 6), the Horse variant like the Pinto
(tools/animal_designs.py pinto()): QM's Horse layout in white, black stripes as flush
slices through the body, neck and head (as the Kitten's, designs/desert/Kitten.bbmodel), a black muzzle, mane, back stripe and hooves, and a white tail with a black tuft.

Same bones and rules as every quadruped; walk is QM's horse walk, the gallop the shared leap.

    python3 tools/zebra_design.py

writes designs/animals/Zebra.bbmodel and renders to /mnt/project-files/animals/meadow/.
"""

import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import animal_designs as A  # noqa: E402
from animal_designs import Animal, horse_body  # noqa: E402

WHITE = (248, 248, 244)
BLACK = (40, 40, 46)
HOOF = (58, 58, 66)


def zebra():
    a = Animal("Zebra", "Uncommon")
    horse_body(a, WHITE, BLACK, HOOF)
    # stripes as flush slices through the body, neck and head (as the Kitten's), not plates
    for name in ("Body", "Neck", "Head"):
        a.remove(name)
    for i, (z0, z1, c) in enumerate(((-2.7, -1.7, WHITE), (-1.7, -1.2, BLACK), (-1.2, 0.0, WHITE), (0.0, 0.5, BLACK),
                                     (0.5, 1.7, WHITE), (1.7, 2.2, BLACK), (2.2, 3.3, WHITE))):
        a.box(f"Body{i + 1}", (-1.6, 3.5, z0), (1.6, 6.5, z1), c, "root")
    for i, (y0, y1, c) in enumerate(((5.1, 6.0, WHITE), (6.0, 6.4, BLACK), (6.4, 7.2, WHITE), (7.2, 7.6, BLACK), (7.6, 8.3, WHITE))):
        a.box(f"Neck{i + 1}", (-0.9, y0, -2.699), (0.9, y1, -1.099), c, "neck")
    for i, (z0, z1, c) in enumerate(((-3.9, -2.2, WHITE), (-2.2, -1.8, BLACK), (-1.8, -1.1, WHITE))):
        a.box(f"Head{i + 1}", (-1.1, 8.3, z0), (1.1, 10.5, z1), c, "neck")
    for p in a.parts:
        if p.name in ("Snout", "Bridge"):
            p.color = BLACK
        elif p.name == "Tail":
            p.color = WHITE
    return a


def main(out=os.path.join(A.ROOT, "designs", "animals")):
    a = zebra()
    A.build_animal(a, out)
    print(f"{a.name}: {len(a.parts)} parts")


if __name__ == "__main__":
    main(*sys.argv[1:])
