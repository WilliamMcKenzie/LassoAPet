"""Elephant: World 1 Meadow animal (QM, Nov 6: "just use the war elephant but take its armor
off"). QM's War Elephant (designs/godlands/WarElephant.bbmodel) with its plate armour, trim,
skirts and spikes taken off: the bare grey elephant with its ears, trunk and tusks, same
bones and animations.

    python3 tools/elephant_design.py
    python3 tools/bbmodel_to_luau.py --zyx designs/animals/Elephant.bbmodel src/shared/Animals/ElephantModel.luau
"""

import json
import os

ROOT = os.path.join(os.path.dirname(__file__), "..")
ARMOUR = ("BackPlate", "BackTrim", "HeadPlate", "HeadRidge", "HeadSpike", "SideSpike", "Skirt", "Spine", "TuskSpike")


def strip(node, gone):
    if isinstance(node, dict):
        node["children"] = [strip(c, gone) for c in node.get("children", []) if not (isinstance(c, str) and c in gone)]
    return node


def main():
    m = json.load(open(os.path.join(ROOT, "designs", "godlands", "WarElephant.bbmodel")))
    gone = {e["uuid"] for e in m["elements"] if e["name"].startswith(ARMOUR)}
    m["elements"] = [e for e in m["elements"] if e["uuid"] not in gone]
    m["outliner"] = [strip(n, gone) for n in m["outliner"] if not (isinstance(n, str) and n in gone)]
    m["name"] = "Elephant"
    with open(os.path.join(ROOT, "designs", "animals", "Elephant.bbmodel"), "w") as f:
        json.dump(m, f, separators=(",", ":"))
    print("Elephant:", len(m["elements"]), "elements,", len(gone), "armour removed")


if __name__ == "__main__":
    main()
