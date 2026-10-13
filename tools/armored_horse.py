"""Armored Horse: QM's default horse (Horse9_Leap) with #907D72 stone plating on its
head and a Loong-style saddle (dark leather seat with a tall back, red blanket with
gold trim), keeping the horse's exact shape, bones and animations.

    python3 tools/armored_horse.py

writes designs/horses/ArmoredHorse.bbmodel. Units are Blockbench's (0.1 stud).
"""

import copy
import uuid

import horse_variants as HV

STONE = (0x90, 0x7D, 0x72)
STONE_DARK = (112, 96, 87)
LEATHER = (52, 34, 26)
CUSHION = (128, 110, 98)
RED = (170, 32, 38)
GOLD = (240, 190, 24)

PATCHES = [
    # Stone chamfron: top of the head (split round the forelock), cheeks, a ridge and rivets.
    ("PlateTop", "neck", (-12, 105, -40), (12, 107, -24), STONE),
    ("PlateTopL", "neck", (-12, 105, -24), (-4, 107, -16), STONE),
    ("PlateTopR", "neck", (4, 105, -24), (12, 107, -16), STONE),
    ("PlateRidge", "neck", (-2, 107, -38), (2, 109.5, -26), STONE_DARK),
    ("CheekL", "neck", (-12, 83, -38), (-11, 90, -24), STONE),
    ("CheekR", "neck", (11, 83, -38), (12, 90, -24), STONE),
    ("RivetL1", "neck", (-12.5, 85, -36), (-12, 87, -34), STONE_DARK),
    ("RivetL2", "neck", (-12.5, 85, -28), (-12, 87, -26), STONE_DARK),
    ("RivetR1", "neck", (12, 85, -36), (12.5, 87, -34), STONE_DARK),
    ("RivetR2", "neck", (12, 85, -28), (12.5, 87, -26), STONE_DARK),
    # Saddle: red blanket over the back with gold trim, leather seat, cushion,
    # a low front with a horn and a tall back like the Loong's.
    ("Blanket", "root", (-17, 48, 0), (17, 66, 24), RED),
    ("BlanketTrim", "root", (-17.5, 47, -0.5), (17.5, 49, 24.5), GOLD),
    ("Seat", "root", (-12, 65, 1), (12, 73, 23), LEATHER),
    ("Cushion", "root", (-9, 73, 5), (9, 74, 19), CUSHION),
    ("Pommel", "root", (-10, 73, 1), (10, 80, 5), LEATHER),
    ("Horn", "root", (-2.5, 80, 1.5), (2.5, 83.5, 4.5), GOLD),
    ("Cantle", "root", (-12, 73, 19), (12, 86, 23), LEATHER),
    ("CantleTrim", "root", (-12.5, 84, 18.5), (12.5, 86.5, 23.5), GOLD),
]


def add_nose_plate(path):
    """A stone wedge over the Bridge slope, 1 wider each side and ~1 thicker."""
    import json
    model = json.load(open(path))
    bridge = next(e for e in model["elements"] if e["name"] == "Bridge")
    plate = copy.deepcopy(bridge)
    plate.update(name="PlateNose", uuid=str(uuid.uuid4()))
    plate["vertices"] = {"v0": [-12, 97, -38], "v1": [-12, 97, -52.5], "v2": [12, 97, -52.5],
                         "v3": [12, 97, -38], "v4": [12, 107, -38], "v5": [-12, 107, -38]}
    head = next(e for e in model["elements"] if e["name"] == "PlateTop")
    for f in plate["faces"].values():  # same palette cell as the other stone plates
        f["uv"] = {k: [head["faces"]["north"]["uv"][0] + 0.5, head["faces"]["north"]["uv"][1] + 0.5] for k in f["uv"]}
    model["elements"].append(plate)
    groups = {g["uuid"]: g for g in model["groups"]}
    HV.find_group(model["outliner"], "neck", groups)["children"].append(plate["uuid"])
    json.dump(model, open(path, "w"), indent=1)


if __name__ == "__main__":
    HV.make("ArmoredHorse", {"colors": {}, "patches": PATCHES})
    add_nose_plate(f"{HV.REPO}/designs/horses/ArmoredHorse.bbmodel")
