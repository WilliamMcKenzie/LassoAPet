"""Zebra: World 1 Meadow's Uncommon (QM, Nov 6), the Horse variant like the Pinto
(tools/animal_designs.py pinto()): QM's Horse layout in white, black stripes down both
sides and over the back, rings round the neck and legs, stripes on the head, a black
muzzle, mane, back stripe and hooves, and a white tail with a black tuft.

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
    # stripes down both sides (alternately long and short) and on over the back
    for i, (z0, z1, b0) in enumerate(((-2.3, -1.8, 4.0), (-1.2, -0.7, 3.6), (-0.1, 0.4, 4.2),
                                      (1.0, 1.5, 3.6), (2.1, 2.6, 4.0))):
        a.patch(f"StripeL{i + 1}", "L", z0, z1, b0, 6.5, BLACK, box=body)
        a.patch(f"StripeR{i + 1}", "R", z0, z1, b0, 6.5, BLACK, box=body)
        a.patch(f"StripeT{i + 1}", "T", -1.6, 1.6, z0, z1, BLACK, box=body)
    # rump stripes running back along the haunches
    for side, face in (("L", "L"), ("R", "R")):
        a.patch(f"Rump{side}", face, 2.9, 3.3, 4.6, 5.0, BLACK, box=body)
    # rings round the neck and legs, a touch bigger than the block they wrap
    for i, y in enumerate((5.7, 6.7, 7.7)):
        a.box(f"NeckStripe{i + 1}", (-0.92, y, -2.72), (0.92, y + 0.4, -1.08), BLACK, "neck")
    for leg in A.LEGS:
        sx = -1 if leg[1] == "L" else 1
        front = leg[0] == "F"
        xa, xb = sorted((sx * 0.5, sx * 1.6))
        z0 = -2.7 + 0.001 if front else 3.3 - 0.001 - 1.1
        for i, y in enumerate((1.4, 2.4)):
            a.box(f"LegStripe{leg}{i + 1}", (xa - 0.02, y, z0 - 0.02), (xb + 0.02, y + 0.35, z0 + 1.12), BLACK, "Leg" + leg)
    # head: stripes behind the eyes and over the forehead, a black muzzle
    head = ((-1.1, 8.3, -3.9), (1.1, 10.5, -1.1))
    for i, (z0, z1) in enumerate(((-2.2, -1.85), (-1.6, -1.25))):
        a.patch(f"HeadStripeL{i + 1}", "L", z0, z1, 8.3, 10.5, BLACK, "neck", box=head)
        a.patch(f"HeadStripeR{i + 1}", "R", z0, z1, 8.3, 10.5, BLACK, "neck", box=head)
    for i, (z0, z1) in enumerate(((-3.7, -3.4), (-3.1, -2.8))):
        a.patch(f"BrowStripe{i + 1}", "T", -1.1, 1.1, z0, z1, BLACK, "neck", box=head)
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
