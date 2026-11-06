"""Zebra: World 1 Meadow's Uncommon (QM, Nov 6), the Horse variant like the Pinto
(tools/animal_designs.py pinto()): QM's Horse layout in white, three black stripes down
each side, one behind each eye, a black muzzle, mane, back stripe and hooves, and a white tail with a black tuft.

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
    body = ((-1.6, 3.5, -2.7), (1.6, 6.5, 3.3))
    # three stripes down each side, one behind each eye
    for i, (z0, z1, b0) in enumerate(((-1.8, -1.1, 3.9), (0.0, 0.7, 3.5), (1.8, 2.5, 3.9))):
        a.patch(f"StripeL{i + 1}", "L", z0, z1, b0, 6.5, BLACK, box=body)
        a.patch(f"StripeR{i + 1}", "R", z0, z1, b0, 6.5, BLACK, box=body)
    head = ((-1.1, 8.3, -3.9), (1.1, 10.5, -1.1))
    a.patch("HeadStripeL", "L", -2.1, -1.6, 8.3, 10.5, BLACK, "neck", box=head)
    a.patch("HeadStripeR", "R", -2.1, -1.6, 8.3, 10.5, BLACK, "neck", box=head)
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
