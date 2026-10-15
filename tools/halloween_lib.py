"""Shared bits for the Halloween world's animals (tools/halloween_*.py), on top of the Garden
builder (tools/garden_lib.py): same blocks, pyramids, hulls and googly plate eyes, but saved to
designs/halloween/ and rendered to /mnt/project-files/halloween/animals/.

    g = Spooky("BlackCat", {...})
    ...
    g.finish(quad_anims())

Convert with bbmodel_to_luau.py --zyx (and --meshes if it has hulls).
"""

import os

import numpy as np

import garden_lib as G
from garden_lib import Garden, Rm, track, sin, TAU  # noqa: F401

OUT = "/mnt/project-files/halloween/animals"


class Spooky(Garden):
    def __init__(self, name, colors):
        super().__init__(name, colors, group="halloween")

    def finish(self, anims=None, gap=0.0, out=OUT, lineup_cam=None):
        return super().finish(anims, gap, out, lineup_cam)

    def leg(self, root, name, hip, length, w, col, foot=None, foot_col=None, foot_len=None):
        """A straight block leg hanging from hip to the ground (a bone at the hip), with an
        optional wider foot block."""
        hip = np.array(hip, float)
        b = self.group("Leg" + name, hip, root)
        self.box(b, "Leg" + name, (hip[0], hip[1] - length / 2, hip[2]), (w, length, w), col)
        if foot:
            fl = foot_len or foot * 1.1
            self.box(b, "Foot" + name, (hip[0], hip[1] - length + foot * 0.25, hip[2] - (fl - w) / 2),
                     (foot, foot * 0.5, fl), foot_col or col)
        return b


def quad_anims(swing=(24, 42), lean=-4, hop=(2, 8), tail="Tail", head="neck", idle_head=10, gait="trot",
               extra=None):
    """Four-legged idle/walk/gallop on bones root, neck, Tail, LegFL/FR/HL/HR (the Lion's).
    gait 'bound' puts the hind pair a quarter step behind in the gallop (cats, wolves)."""
    def run(L, sw, ln, hp, gallop, n=16):
        tr = {"root": [track(L, lambda u: (ln + 3 * sin(TAU * u), 0, 0), n),
                       track(L, lambda u: (0, hp * abs(sin(TAU * u)), 0), n, "position")],
              head: [track(L, lambda u: (-ln - 4 * sin(TAU * u), 0, 0), n)]}
        if tail:
            tr[tail] = [track(L, lambda u: (10 + 10 * sin(TAU * u), 12 * sin(TAU * u), 0), n)]
        bound = gallop and gait == "bound"
        for b, ph in (("LegFL", 0), ("LegHR", 0.25 if bound else 0.0), ("LegFR", 0.5 if not bound else 0.1),
                      ("LegHL", 0.75 if not bound else 0.35)):
            tr[b] = [track(L, lambda u, ph=ph: (sw * sin(TAU * (u + ph)), 0, 0), n)]
        if extra:
            tr.update(extra(L, gallop))
        return tr

    def anims(m):
        L = 3.0
        idle = {head: [track(L, lambda u: (3 * sin(TAU * u), idle_head * sin(TAU * u), 4 * sin(TAU * u + 1)), 24)],
                "root": [track(L, lambda u: (0, 1.2 * sin(TAU * 2 * u), 0), 24, "position")]}
        if tail:
            idle[tail] = [track(L, lambda u: (10, 25 * sin(TAU * u), 0), 24)]
        return {"idle": (L, idle), "walk": (0.8, run(0.8, swing[0], 0, hop[0], False)),
                "gallop": (0.45, run(0.45, swing[1], lean, hop[1], True))}
    return anims


def gif(m, name):
    G.gif(m, os.path.join(OUT, name + "_anims.gif"))
