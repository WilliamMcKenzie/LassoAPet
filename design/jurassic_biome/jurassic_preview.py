"""Previews of the Jurassic (QM, Oct 11) as it'll show in game, after tools/funnel.luau:
the floor, walls and ribcage of tools/jurassic.py with the plants and rocks of
tools/biome_rocks.py. Run: python3 design/jurassic_biome/jurassic_preview.py"""
import importlib.util
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, "..", "..")
sys.path.insert(0, os.path.join(ROOT, "tools"))
import jurassic as JU  # noqa: E402

_spec = importlib.util.spec_from_file_location("volcano_preview", os.path.join(ROOT, "design", "volcano", "volcano_preview.py"))
VP = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(VP)

OUT = "/mnt/project-files/design/jurassic_biome"
COL = {"Ground": [(78, 140, 40), (86, 152, 44)], "Trail": [(150, 104, 64), (162, 114, 70)]}
WALL = [(150, 102, 62), (164, 114, 70)]


def scene(z_hi, z_lo, ribs=False):
    parts = VP.floor(JU.layout(), JU.KINDS, JU.TOP, lambda n, z: COL[n], z_hi, z_lo, lambda z: WALL)
    parts += VP.rocks("Jurassic", z_lo, z_hi)
    if ribs:
        parts += [p for p in JU.ribcage() if z_lo - 40 <= p.cf[2, 3] <= z_hi + 40]
    return parts, [], []


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    z = JU.Z_START - 1500
    a = VP.shot(*scene(z + 40, z - 340), eye=(0, 110, z + 70), target=(0, 0, z - 170))
    zr = JU.RIB_Z0 + 160
    b = VP.shot(*scene(zr + 40, zr - 420, ribs=True), eye=(0, 70, zr + 60), target=(0, 40, zr - 220), fov=62)
    VP.sheet([(a, "Jurassic: riding through (jungle grass, dirt trail, plants and brown rocks by the walls)"),
              (b, "The giant ribcage halfway along")], os.path.join(OUT, "jurassic_in_game.png"))
    print("wrote", OUT)
