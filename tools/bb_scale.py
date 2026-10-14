"""Scales a whole .bbmodel up or down: blocks, pivots and position keys (rotations stay).

Run: python3 tools/bb_scale.py in.bbmodel out.bbmodel K

Used where a model was drawn too small: the game sizes every animal to its tier
(Horse.luau tierSize), so a small model is blown up and its studs with it. Drawn
at about its game size (a size factor near the Horse's 1), its studs match the Horse's.
"""

import json
import sys


def scale(m, k):
    for e in m["elements"]:
        for key in ("from", "to", "origin"):
            if key in e:
                e[key] = [v * k for v in e[key]]
        if e.get("inflate"):
            e["inflate"] *= k
        if e.get("type") == "mesh":
            e["vertices"] = {n: [v * k for v in p] for n, p in e["vertices"].items()}
    for g in m.get("groups", []):
        g["origin"] = [v * k for v in g["origin"]]
    if "visible_box" in m:
        m["visible_box"] = [v * k for v in m["visible_box"]]
    for a in m.get("animations", []):
        for an in a.get("animators", {}).values():
            for kf in an.get("keyframes", []):
                if kf["channel"] == "position":
                    for p in kf["data_points"]:
                        for axis in "xyz":
                            p[axis] = float(p[axis]) * k
    return m


if __name__ == "__main__":
    src, out, k = sys.argv[1], sys.argv[2], float(sys.argv[3])
    m = scale(json.load(open(src)), k)
    with open(out, "w") as f:
        json.dump(m, f, separators=(",", ":"))
