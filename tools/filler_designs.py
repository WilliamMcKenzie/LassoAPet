"""Per-biome luck-padding animals: contact sheets and draft models (QM, Nov 7).

Run: python3 tools/filler_designs.py [biome ...]   (default: all)
Writes /mnt/project-files/animals/filler/<Biome>.png and designs/filler/<biome>/<Name>.bbmodel.
"""

import importlib
import json
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import filler_core as C  # noqa: E402

BIOMES = ["Meadow", "Desert", "Tundra", "Volcano", "Dungeon", "Forest", "Castle", "Ocean"]
OUT = "/mnt/project-files/animals/filler"


def main(names):
    os.makedirs(OUT, exist_ok=True)
    for biome in names or BIOMES:
        mod = importlib.import_module("filler_" + biome.lower())
        built = C.sheet(f"{biome}: 10 common + 5 rare (★)", mod.COMMON + mod.RARE,
                        os.path.join(OUT, biome + ".png"), mod.GROUND)
        d = os.path.join(C.MODELS, biome.lower())
        os.makedirs(d, exist_ok=True)
        for a, model in built:
            with open(os.path.join(d, a.name + ".bbmodel"), "w") as f:
                json.dump(model, f, separators=(",", ":"))
        print(biome, [(a.name, len(a.parts)) for a, _ in built])


if __name__ == "__main__":
    main(sys.argv[1:])
