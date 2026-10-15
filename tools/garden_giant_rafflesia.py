"""Giant Rafflesia: World 3 Garden boss (Oct 15), also a Legendary trophy pet like the Seraphs. Replaces
the Flytrap Queen (QM Oct 15: "use the rafflesia flower and make a giant stemmed flower. dont worry about
legs/movement anim it can just be a stem attached to the ground"). QM's own Rafflesia flower head
(designs/garden/RafflesiaBeast.bbmodel: five warty petals round a cream rim and a spiny well) at 1.1x,
on a tall curving stem growing out of a rosette of big leaves on the ground. No legs: the stem sways.

Run: python3 tools/garden_giant_rafflesia.py [--gif]
Bones: root -> Stem -> Flower (QM's head, its rest kept) -> Petal1..5.
"""

import json
import os
import sys

import numpy as np

import garden_lib as G
import garden_rafflesia as RB
from garden_lib import Garden, Rm, track, sin, TAU

C = dict(RB.C)
SRC = os.path.join(G.ROOT, "designs", "garden", "RafflesiaBeast.bbmodel")
K = 1.1  # the flower at 1.1x QM's
H = 32.0  # stem height
PIVOT = np.array([0, 1.0, 0])  # the Flower pivot above the stem top (set so the well sits on the stem)


def build():
    src = json.load(open(SRC))
    grp = {g["name"]: g for g in src["groups"]}
    On, Oh = np.array(grp["neck"]["origin"]) / 10, np.array(grp["head"]["origin"]) / 10
    rx_n, rx_h = grp["neck"]["rotation"][0], grp["head"]["rotation"][0]

    def node(nodes, name):
        for n in nodes:
            if isinstance(n, dict):
                if grp_by_uuid[n["uuid"]] == name:
                    return n
                r = node(n["children"], name)
                if r:
                    return r
    grp_by_uuid = {g["uuid"]: g["name"] for g in src["groups"]}

    g = Garden("GiantRafflesia", C, group="bosses")
    root = g.group("root", (0, 0, 0))
    # a rosette of big cupped leaves on the ground
    for k in range(6):
        a = TAU * (k + 0.5) / 6
        out = np.array([np.sin(a), 0, np.cos(a)])
        for half in G.cupped_leaf(out * 1.6 + (0, 0.5, 0), out + (0, 0.12, 0), (0, 1, 0), 11.0, 6.0, T=0.8, cup=1.5):
            g.hull(root, "Leaf", half, "vine")
    # the stem: a thick curving vine (mesh) up to the flower
    top = np.array([0, H, -2.0])
    stem = g.group("Stem", (0, 0.5, 0), root)
    path = [np.array([0, 0.0, 0]) + (0, H * u, -2.0 * u + 2.0 * sin(np.pi * u)) for u in np.linspace(0, 1, 11)]
    G.tube(g, stem, "Stem", path[:-1] + [path[-1] - (0, 2.5, 0)], list(np.linspace(2.6, 1.8, 11)), "vine", seg=8)
    for s, (y, ang) in ((-1, (11.0, 20)), (1, (18.0, -30))):  # two leaves up the stem
        d = np.array([s, 0.5, -0.3])
        for half in G.cupped_leaf((s * 1.2, y, 0.6), d, (0, 1, 0.2), 8.0, 4.4, T=0.6, cup=1.0):
            g.hull(stem, "StemLeaf", half, "mosslight")
    # QM's flower head, its pivot moved to the stem top; the neck's and head's rests (both about x) combine
    # into the Flower's, so it faces the way it does on QM's beast
    flower = G.clone(g, src, node(src["outliner"], "head"), stem, K, top + PIVOT, frm=Oh,
                     names={"head": "Flower"})
    fg = next(x for x in g.groups if x["uuid"] == flower["uuid"])
    fg["rotation"] = [rx_n + rx_h, 0, 0]
    return g


def animations(m):
    def sway(L, amp, nod, petals, n=24):
        tr = {"Stem": [track(L, lambda u: (amp * sin(TAU * u), 0, amp * 0.7 * sin(TAU * u + 1.3)), n)],
              "Flower": [track(L, lambda u: (nod * sin(TAU * u + 0.8), nod * 0.6 * sin(TAU * u), 0), n)]}
        for i in range(5):
            tr[f"Petal{i + 1}"] = [track(L, lambda u, i=i: (-petals * (0.5 + 0.5 * sin(TAU * u + i * 0.6)), 0, 0), n)]
        return tr
    return {"idle": (4.0, sway(4.0, 3, 5, 4)), "walk": (2.0, sway(2.0, 5, 8, 6)), "gallop": (1.2, sway(1.2, 8, 12, 10))}


if __name__ == "__main__":
    m = build().finish(animations)
    if "--gif" in sys.argv:
        G.gif(m, G.OUT + "/GiantRafflesia_anims.gif")
