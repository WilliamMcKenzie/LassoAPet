"""Treasure Turtle's shell as a tortoise's (QM, Oct 15: "not so round, make it more like
diamonds, like a real tortoise"). Swaps the smooth green SmoothShell in QM's
designs/world3/pirate/TreasureTurtle.bbmodel for a faceted dark-green dome covered in raised
diamond scutes (low pyramids, a gap between them so the dark seams show), and a ring of
triangle scutes along the rim. The sand island dome on top is left as it is.

Run once: python3 tools/pirate_turtle_shell.py
Convert: python3 tools/bbmodel_to_luau.py --zyx --meshes assets/meshes/TreasureTurtle designs/world3/pirate/TreasureTurtle.bbmodel src/shared/Animals/TreasureTurtleModel.luau
"""

import json
import math
import uuid

import numpy as np

import garden_lib as G

PATH = "designs/world3/pirate/TreasureTurtle.bbmodel"
SHELL, SHELLDARK = 7, 8  # texture indices
N = 8  # scutes around
# the old smooth shell's profile (Blockbench units): y, half-width x, half-length z
RIM = (30.8, 50.0, 60.0)
RINGS = [(34.0, 50.0, 60.0), (45.0, 48.0, 57.6), (55.0, 41.0, 49.2), (63.0, 31.0, 37.2)]
GAP = 0.14  # each scute's corners pulled in toward its centre (the seams)
RAISE = 0.35  # how far a scute's peak stands off the dome, x its size


def ring(k, a):
    y, rx, rz = RINGS[k]
    return np.array([rx * math.sin(a), y, -rz * math.cos(a)])


def mesh(name, pts, tex):
    keys, v, faces = {}, {}, {}
    for i, t in enumerate(G.hull_tris(pts)):
        vs = []
        for q in t:
            k = tuple(np.round(q, 4))
            if k not in keys:
                keys[k] = f"v{len(keys)}"
                v[keys[k]] = [round(float(x), 4) for x in q]
            vs.append(keys[k])
        faces[f"f{i}"] = {"texture": tex, "vertices": vs, "uv": {q: [0, 0] for q in vs}}
    return {"name": name, "type": "mesh", "uuid": str(uuid.uuid4()), "color": 0, "origin": [0, 0, 0],
            "rotation": [0, 0, 0], "visibility": True, "export": True, "vertices": v, "faces": faces}


def scute(name, corners):
    """A low pyramid on the dome: the corners pulled in, a peak raised along its outward normal."""
    corners = np.array(corners)
    c = corners.mean(0)
    n = c - np.array([0, RIM[0], 0])
    n /= np.linalg.norm(n)
    size = max(np.linalg.norm(p - c) for p in corners)
    base = [c + (p - c) * (1 - GAP) for p in corners]
    return mesh(name, base + [c + n * size * RAISE], SHELL)


def build():
    h = math.pi / N
    out = []
    # the dark dome under the scutes (shows in the seams)
    pts = [np.array([RIM[1] * math.sin(a), RIM[0], -RIM[2] * math.cos(a)]) for a in np.arange(2 * N) * h]
    pts += [ring(k, a) * np.array([0.97, 1, 0.97]) for k in range(len(RINGS)) for a in np.arange(2 * N) * h]
    out.append(mesh("ShellBase", pts, SHELLDARK))
    i = 0
    for k in range(len(RINGS) - 2):  # the diamonds: bottom on ring k, sides on k+1, top on k+2
        for j in range(N):
            a = 2 * h * j + (k % 2) * h
            i += 1
            out.append(scute(f"Scute{i}", [ring(k, a), ring(k + 1, a - h), ring(k + 2, a), ring(k + 1, a + h)]))
    for j in range(N):  # the rim's triangles, between the bottom diamonds
        a = 2 * h * j
        out.append(scute(f"Rim{j + 1}", [ring(0, a), ring(1, a + h), ring(0, a + 2 * h)]))
    return out


def main():
    d = json.load(open(PATH))
    old = next(e for e in d["elements"] if e["type"] == "mesh" and e["name"] == "SmoothShell"
               and next(iter(e["faces"].values()))["texture"] == SHELL)
    new = build()
    d["elements"] = [e for e in d["elements"] if e is not old] + new

    def swap(children):
        for n, c in enumerate(children):
            if c == old["uuid"]:
                children[n:n + 1] = [e["uuid"] for e in new]
                return True
            if isinstance(c, dict) and swap(c["children"]):
                return True
    assert swap(d["outliner"])
    json.dump(d, open(PATH, "w"))
    print(len(new), "pieces")


if __name__ == "__main__":
    main()
