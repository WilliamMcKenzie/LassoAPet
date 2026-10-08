"""A basic wooden chair to sit in while lassoing the training dummy (QM, Oct 8).

Run: python3 tools/chair_design.py [out_dir]   preview renders
     python3 tools/chair_design.py game        designs/props/TrainingChair.bbmodel and
                                               src/shared/Props/TrainingChairModel.luau

Studded blocks in the training dummy's wood colours: four legs, a plank seat,
two back posts with three slats. Faces -Z (the sitter looks -Z), feet on Y = 0.
One static bone, so Rig builds it like the dummy.
"""

import json
import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import animal_designs as A  # noqa: E402
from animal_designs import Animal  # noqa: E402
from partlib import render  # noqa: E402

WOOD = (166, 108, 62)
WOOD_DARK = (122, 78, 44)
WOOD_LIGHT = (196, 136, 80)

W, D = 1.6, 1.5  # half width and half depth of the seat
SEAT_Y0, SEAT_Y1 = 1.8, 2.3  # seat plank bottom and top
LEG = 0.5
BACK_TOP = 6.0


def chair():
    a = Animal("TrainingChair", "Common")
    a.pivots = {"root": (0, 0, 0)}
    a.bone_order = [("root", None)]
    # legs, flush with the seat's corners
    for name, (sx, sz) in {"LegFL": (-1, -1), "LegFR": (1, -1), "LegBL": (-1, 1), "LegBR": (1, 1)}.items():
        x0, z0 = (-W if sx < 0 else W - LEG), (-D if sz < 0 else D - LEG)
        a.box(name, (x0, 0, z0), (x0 + LEG, SEAT_Y0, z0 + LEG), WOOD_DARK, "root")
    # a rail between the legs on each side, low down
    for s, sx in (("L", -1), ("R", 1)):
        x0 = -W + 0.1 if sx < 0 else W - LEG + 0.1
        a.box("Rail" + s, (x0, 0.5, -D + LEG), (x0 + 0.3, 0.8, D - LEG), WOOD_DARK, "root")
    a.box("Seat", (-W, SEAT_Y0, -D), (W, SEAT_Y1, D), WOOD_LIGHT, "root")
    # back: two posts carry on up from the back legs, three slats between them
    for s, sx in (("L", -1), ("R", 1)):
        x0 = -W if sx < 0 else W - LEG
        a.box("Post" + s, (x0, SEAT_Y1, D - LEG), (x0 + LEG, BACK_TOP, D), WOOD_DARK, "root")
    for i, y in enumerate((3.2, 4.2, 5.2)):
        a.box(f"Slat{i + 1}", (-W + LEG, y, D - 0.4), (W - LEG, y + 0.6, D - 0.1), WOOD, "root")
    a.box("TopRail", (-W, BACK_TOP, D - LEG), (W, BACK_TOP + 0.5, D), WOOD, "root")
    a.animations = lambda: {}
    return a


def main(out="/mnt/project-files/design/chair"):
    os.makedirs(out, exist_ok=True)
    a = chair()
    q34 = dict(eye=(-9, 7, -10), target=(0, 2.8, 0), W=420, H=420, fov=38, outline=False)
    back = dict(eye=(8, 7, 10), target=(0, 2.8, 0), W=420, H=420, fov=38, outline=False)
    im = Image.new("RGB", (840, 420))
    im.paste(render(a.parts, **q34), (0, 0))
    im.paste(render(a.parts, **back), (420, 0))
    im.save(os.path.join(out, "chair.png"))
    print(len(a.parts), "parts; written to", out)


def game():
    import bbmodel_to_luau
    a = chair()
    model, _ = A.write_bbmodel(a.parts, a.name, None, bones=a.bones())
    model["animations"] = []
    model["meta"]["format_version"] = "5.0"
    os.makedirs(os.path.join("designs", "props"), exist_ok=True)
    path = os.path.join("designs", "props", "TrainingChair.bbmodel")
    with open(path, "w") as f:
        json.dump(model, f, separators=(",", ":"))
    bbmodel_to_luau.main(path, os.path.join("src", "shared", "Props", "TrainingChairModel.luau"))


if __name__ == "__main__":
    if sys.argv[1:2] == ["game"]:
        game()
    else:
        main(*sys.argv[1:])
