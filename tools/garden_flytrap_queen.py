"""Flytrap Queen: World 3 Garden boss, also a Legendary trophy pet like the Seraphs. Rebuilt Oct 15 from
QM's hand-edited Venus Flytrap (designs/garden/VenusFlytrap.bbmodel; QM: "the boss has to be more like
the new flytrap"): the same box bulb on four bent root legs, the same stem and trap, but bigger and with
three heads. The Queen's head (the biggest, magenta inside) on the middle stem wears a crown of magenta
pyramid petals with glowing gold tips; two smaller heads stand at her sides. The bulb is purple and
every pupil glows green (bosses glow). The heads chomp out of step as she charges.

Run: python3 tools/garden_flytrap_queen.py [--gif]
Bones (all rest as in QM's Flytrap): root -> LegFL/FR/HL/HR; HeadQ/HeadL/HeadR (stem) -> <h>Lobe
(lower lobe) and <h>Jaw (upper lobe, eye, brows).
"""

import copy
import json
import os
import sys

import numpy as np

import garden_lib as G
import snake_design as S
from garden_lib import Garden, track, sin, TAU

C = {"green": (52, 150, 52), "greendark": (24, 88, 40), "red": (220, 36, 140), "reddark": (130, 16, 90),
     "spike": (252, 240, 206), "brow": (16, 52, 24), "bulb": (110, 52, 130), "crown": (236, 60, 170),
     "crowndark": (170, 30, 120), "Glow": (255, 214, 60), "eyedark": (24, 18, 28), "glowgreen": (150, 255, 60)}
TRAP = os.path.join(G.ROOT, "designs", "garden", "VenusFlytrap.bbmodel")
COLOUR = {"eyewhite": "eyedark", "pupil": "glowgreen", "root": "greendark", "rootdark": "greendark", "leaf": "green"}
BODY = 1.7  # the Queen is QM's Flytrap at 1.7x


def clone(g, src, node, parent, scale, at, frm=(0, 0, 0), names=None):
    """Copy QM's bone `node` (with its parts and child bones) into g under `parent`, scaled about
    `frm` and moved to `at`; bones renamed by `names`, colours mapped into the Queen's palette."""
    names = names or {}
    frm, at = np.array(frm, float), np.array(at, float)
    tex = [t["name"] for t in src["textures"]]
    grp = next(x for x in src["groups"] if x["uuid"] == node["uuid"])
    P = lambda p: list(((np.array(p, float) / S.BB - frm) * scale + at) * S.BB)  # Blockbench units
    ng = g.group(names.get(grp["name"], grp["name"]), (np.array(grp["origin"]) / S.BB - frm) * scale + at, parent)
    g.groups[-1]["rotation"] = list(grp.get("rotation", [0, 0, 0]))
    for c in node["children"]:
        if isinstance(c, dict):
            clone(g, src, c, ng, scale, at, frm, names)
            continue
        e = copy.deepcopy(next(x for x in src["elements"] if x["uuid"] == c))
        e["uuid"] = S.uid()
        for k in ("from", "to", "origin"):
            if k in e and not (e["type"] == "mesh" and k == "origin"):
                e[k] = P(e[k])
        if e["type"] == "mesh":
            o = np.array(e["origin"], float)  # mesh vertices are relative to its origin
            e["vertices"] = {k: list(np.array(v, float) * scale) for k, v in e["vertices"].items()}
            e["origin"] = P(o)
        if e["type"] == "cube" and "inflate" in e:
            e["inflate"] = e["inflate"] * scale
        col = None
        for f in e["faces"].values():
            if f.get("texture") is not None:
                n = tex[f["texture"]]
                col = COLOUR.get(n, n)
                f["texture"] = g.tex[col]
        if e["name"].startswith("Pupil"):
            e["name"] = "Glow_" + e["name"]
        e["name"] = g._name(e["name"])
        g.put(ng, e)
    return ng


def build():
    src = json.load(open(TRAP))
    g = Garden("FlytrapQueen", C, group="bosses")
    out = src["outliner"][0]
    kids = {next(x for x in src["groups"] if x["uuid"] == c["uuid"])["name"]: c for c in out["children"] if isinstance(c, dict)}
    rg = next(x for x in src["groups"] if x["uuid"] == out["uuid"])
    root = g.group("root", np.array(rg["origin"]) / S.BB * BODY)
    for c in out["children"]:  # the bulb
        if isinstance(c, str):
            e = copy.deepcopy(next(x for x in src["elements"] if x["uuid"] == c))
            e["uuid"] = S.uid()
            for k in ("from", "to", "origin"):
                e[k] = list(np.array(e[k], float) * BODY)
            for f in e["faces"].values():
                f["texture"] = g.tex["bulb"]
            g.put(root, e)
    for leg in ("LegFL", "LegFR", "LegHL", "LegHR"):
        clone(g, src, kids[leg], root, BODY, (0, 0, 0))
    neck = kids["neck"]
    pivot = np.array(next(x for x in src["groups"] if x["name"] == "neck")["origin"]) / S.BB
    for h, scale, at in (("Q", BODY, pivot * BODY), ("L", 1.2, pivot * BODY + (-7.0, -2.2, 1.6)),
                         ("R", 1.2, pivot * BODY + (7.0, -2.2, 1.6))):
        clone(g, src, neck, root, scale, at, frm=pivot, names={"neck": "Head" + h, "group": h + "Lobe", "Jaw": h + "Jaw"})
    # the crown on the Queen's upper lobe, behind her eye (QM's Upper part: centre, pivot and 38 degree tilt)
    jaw = next(n for n in g.groups if n["name"] == "QJaw")
    jnode = next(n for n in _nodes(g.outliner) if n["uuid"] == jaw["uuid"])
    R = G.Rm(("x", 38))
    centre, origin = np.array([0, 13.40256, -4.685]), np.array([0, 13.40256, -4.335])
    Q = lambda p: (origin + R @ (centre + np.array(p, float) - origin) - pivot) * BODY + pivot * BODY
    up = np.array([0, 1.0, -0.15])  # the petals stand straight up
    g.box(jnode, "CrownBand", Q((0, 0.75, 2.0)) + (0, 1.0, 0), (5.6, 2.4, 1.6), "crowndark", R)
    for k in range(5):
        x = -2.2 + 4.4 * k / 4
        L = 5.0 if k in (0, 4) else (8.0 if k == 2 else 6.4)
        d = up + np.array([x * 0.15, 0, 0])
        b = Q((x / BODY, 1.0, 2.0)) + (0, 2.0, 0)
        g.pyr(jnode, "CrownPetal", b, d, L, 0.75, 0.55, "crown" if k % 2 == 0 else "crowndark")
        g.box(jnode, "Glow_CrownTip", b + d / np.linalg.norm(d) * (L - 0.1), (0.6, 0.6, 0.6), "Glow")
    # the side heads' stems reach out from the bulb's shoulders
    for s_ in (-1, 1):
        a = np.array([s_ * 2.6, pivot[1] * BODY - 0.4, pivot[2] * BODY + 1.0])
        bpt = np.array([s_ * 7.0, pivot[1] * BODY - 2.2, pivot[2] * BODY + 1.6])
        d = bpt - a
        g.box(root, "Arm", (a + bpt) / 2, (2.0, np.linalg.norm(d) + 1.0, 2.0), "green", G.frame(d))
    return g


def _nodes(nodes):
    for n in nodes:
        if isinstance(n, dict):
            yield n
            yield from _nodes(n["children"])


def animations(m):
    heads = (("Q", 0.0, 1.0), ("L", 0.33, 0.9), ("R", 0.66, 0.9))

    def charge(L, swing, lean, hop, chomp, sway, n=16):
        tr = {"root": [track(L, lambda u: (lean, 0, 3 * sin(TAU * u)), n),
                       track(L, lambda u: (0, hop * abs(sin(TAU * u)), 0), n, "position")]}
        for b, ph in (("LegFL", 0), ("LegHR", 0), ("LegFR", 0.5), ("LegHL", 0.5)):
            tr[b] = [track(L, lambda u, ph=ph: (swing * sin(TAU * (u + ph)), 0, 0), n)]
        for h, ph, k in heads:
            tr["Head" + h] = [track(L, lambda u, ph=ph, k=k: (-lean * 0.6 + k * 5 * sin(TAU * (u + ph)), k * sway * sin(TAU * (u + ph)), 0), n)]
            tr[h + "Jaw"] = [track(L, lambda u, ph=ph: (chomp * max(0, sin(TAU * (u + ph))) ** 2, 0, 0), n)]
        return tr

    L = 4.0
    idle = {"root": [track(L, lambda u: (0, 2 * sin(TAU * 2 * u), 0), 24, "position")]}
    for h, ph, k in heads:
        idle["Head" + h] = [track(L, lambda u, ph=ph, k=k: (k * 4 * sin(TAU * (u + ph)), k * 10 * sin(TAU * (u + ph)), 0), 24)]
        idle[h + "Jaw"] = [track(L, lambda u, ph=ph: (30 * max(0, sin(TAU * (2 * u + ph))) ** 8, 0, 0), 48)]
    return {"idle": (L, idle), "walk": (1.0, charge(1.0, 18, 0, 3, 20, 8)), "gallop": (0.6, charge(0.6, 30, 8, 8, 36, 12))}


if __name__ == "__main__":
    m = build().finish(animations)
    if "--gif" in sys.argv:
        G.gif(m, G.OUT + "/FlytrapQueen_anims.gif")
