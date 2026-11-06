"""Builds the map editor (QM, Nov 6) into one self-contained page: editor.html with the
palette (maps/world1.palette.json: Config's biome colours and the objects' outlines, from
export.py) and maps/world1.map baked in.

Run: python3 tools/mapeditor/build.py     -> tools/mapeditor/MapEditor.html (git-ignored)
"""

import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from mapfile import MAP, PALETTE  # noqa: E402

OUT = os.path.join(HERE, "MapEditor.html")


def main():
    pal = json.load(open(PALETTE))
    bundle = {"palette": pal["palette"], "items": pal.get("items", []), "map": open(MAP).read()}
    page = open(os.path.join(HERE, "editor.html")).read()
    blob = json.dumps(bundle, separators=(",", ":")).replace("</", "<\\/")
    page = page.replace("/*BUNDLE*/null", blob)
    open(OUT, "w").write(page)
    print("wrote", os.path.relpath(OUT), "(%d KB)" % (len(page) // 1024))
    return OUT


if __name__ == "__main__":
    main()
