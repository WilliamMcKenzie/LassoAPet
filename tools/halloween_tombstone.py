"""Tombstone Crawler: Halloween Soul Valley Uncommon (draft, Oct 15). A grave that got up and walked:
a grey tombstone with a round top (a faceted mesh: it's curved), a dark "RIP" plaque in front,
moss on its shoulders, four stubby stone legs and googly eyes on its sides.

Run: python3 tools/halloween_tombstone.py [--gif]
Bones (all rest 0): root -> LegFL/FR/HL/HR.
"""

import sys

import garden_lib as G
import halloween_lib as H
from halloween_lib import Spooky

C = {"stone": (170, 182, 190), "stonedark": (112, 124, 136), "moss": (90, 200, 120), "plaque": (60, 72, 86),
     "letters": (230, 240, 236)}


def build():
    g = Spooky("TombstoneCrawler", C)
    y0 = 2.2
    root = g.group("root", (0, y0, 0))
    g.box(root, "Slab", (0, y0 + 2.6, 0), (5.0, 5.2, 2.4), "stone")
    g.hull(root, "Top", G.ellipsoid((0, y0 + 5.2, 0), (2.5, 1.9, 1.2), seg=10, rings=4, cut=0), "stone")
    g.box(root, "Base", (0, y0 + 0.2, 0), (5.6, 1.0, 3.0), "stonedark")
    g.box(root, "Plaque", (0, y0 + 3.6, -1.25), (3.2, 1.6, 0.2), "plaque")
    g.box(root, "Letters", (0, y0 + 3.6, -1.38), (2.4, 0.5, 0.1), "letters")
    for side, s in (("L", -1), ("R", 1)):
        g.box(root, "Moss" + side, (s * 1.8, y0 + 5.0, 0), (1.6, 0.6, 2.6), "moss")
        g.eye(root, side, (s * 2.55, y0 + 4.3, -0.2), 1.1, normal=(s, 0, 0))
    for nm, (x, z) in (("FL", (-1, -1.0)), ("FR", (1, -1.0)), ("HL", (-1, 1.0)), ("HR", (1, 1.0))):
        g.leg(root, nm, (x * 1.9, y0, z), y0, 1.3, "stonedark", foot=1.6, foot_col="stonedark")
    return g


if __name__ == "__main__":
    m = build().finish(H.quad_anims(swing=(24, 40), hop=(1.5, 4), tail=None, head=None))
    if "--gif" in sys.argv:
        H.gif(m, "TombstoneCrawler")
