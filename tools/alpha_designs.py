"""Alpha variants (QM, Nov 6): an existing animal, bigger and recoloured, about 10x rarer than
it (as the Boar and the Tundra's Elder Boar). The base's own design (tools/animal_designs.py),
its colours swapped one for one and the whole animal scaled; same bones and animations.

    python3 tools/alpha_designs.py
    python3 tools/bbmodel_to_luau.py designs/animals/AlphaRhino.bbmodel src/shared/Animals/AlphaRhinoModel.luau  (and the rest)

writes designs/animals/<Kind>.bbmodel for each below.
"""

import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import animal_designs as A  # noqa: E402

# kind: (base design, rarity, scale, { base colour: new colour })
ALPHAS = {
    "AlphaRhino": (A.rhino, "Epic", 1.4, {  # tinted red
        (150, 156, 170): (178, 128, 124), (112, 118, 134): (138, 90, 90), (84, 88, 102): (98, 60, 62),
        (60, 62, 74): (70, 40, 44), (240, 232, 208): (236, 214, 180),
    }),
    "AlphaFish": (A.fish, "Rare", 1.4, {  # yellow instead of blue
        (60, 132, 232): (250, 204, 48), (36, 88, 184): (228, 150, 24), (222, 240, 255): (255, 246, 206),
        (28, 40, 84): (110, 60, 20),
    }),
    "GoldenPig": (A.pig, "Uncommon", 2.0, {  # gold, 2x
        (246, 164, 184): (255, 204, 60), (250, 196, 208): (255, 228, 120), (176, 96, 116): (196, 138, 28),
        (196, 96, 126): (214, 150, 30),
    }),
}


def alpha(kind):
    design, rarity, k, swap = ALPHAS[kind]
    a = design()
    a.name, a.rarity = kind, rarity
    for p in a.parts:
        p.color = swap.get(tuple(p.color), p.color)
    a.scale(k)
    return a


def main(out=os.path.join(A.ROOT, "designs", "animals")):
    for kind in ALPHAS:
        a = alpha(kind)
        A.build_animal(a, out)
        print(f"{kind}: {len(a.parts)} parts, seat {a.meta['seat']}")


if __name__ == "__main__":
    main(*sys.argv[1:])
