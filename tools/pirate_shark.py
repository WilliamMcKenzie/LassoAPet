"""Eyepatch Shark: World 3 Pirate Cove's Epic (Oct 14). A land shark that swims through the air just
above the sand: a chunky blue shark with a white belly, gill slits, a tall dorsal fin, wide
pectoral fins and a big two-lobed tail. It's a pirate: a black eyepatch over its right eye on a
strap round its head, a red bandana with white dots knotted behind, a scar over the left eye,
and a huge grin full of white pyramid teeth (the lower jaw opens). You ride behind the dorsal fin.

Run: python3 tools/pirate_shark.py [--gif]

Bones: root (head and front body) -> Jaw; root -> FinL, FinR; root -> Body2 -> Tail.

  idle    hovers, tail swaying slowly, jaw chomping now and then
  walk    swims: the body waves, tail sweeping, fins rowing
  gallop  fast swim: big tail sweeps, jaw snapping, leaning in
"""

import math

import numpy as np

from pirate_lib import Model, track, TAU

NAME = "EyepatchShark"
C = {"shark": (82, 146, 214), "sharkdark": (50, 98, 164), "belly": (242, 246, 252), "mouth": (196, 36, 64),
     "gum": (240, 110, 130), "red": (232, 36, 48), "scar": (240, 170, 170)}


def build():
    m = Model(NAME, C)
    y0 = 3.6
    root = m.group("root", (0, y0, -2.0))
    W, H = 5.0, 4.6
    p = [m.box("Front", (0, y0 + 0.3, -2.1), (W, H - 0.6, 4.2), "shark"),
         m.box("FrontTop", (0, y0 + 2.4, -2.4), (W - 1.0, 0.4, 3.6), "shark"),
         m.box("FrontBelly", (0, y0 - 1.75, -1.9), (W - 0.6, 0.3, 3.6), "belly"),
         m.box("Head", (0, y0 + 0.8, -6.3), (W - 0.3, 3.0, 4.2), "shark"),
         m.box("HeadTop", (0, y0 + 2.45, -6.0), (W - 1.4, 0.4, 3.4), "shark"),
         m.box("Nose", (0, y0 + 1.0, -8.75), (W - 1.4, 2.4, 0.9), "shark"),
         m.box("NostrilL", (-0.7, y0 + 1.5, -9.22), (0.3, 0.2, 0.06), "sharkdark"),
         m.box("NostrilR", (0.7, y0 + 1.5, -9.22), (0.3, 0.2, 0.06), "sharkdark"),
         # the open mouth: a dark red cavity between the head and the lower jaw
         m.box("Mouth", (0, y0 - 1.15, -6.3), (W - 1.0, 0.9, 3.8), "mouth")]
    # upper teeth: pyramids hanging down along the front and both sides of the mouth
    mz = -6.4
    for k, x in enumerate(np.linspace(-1.7, 1.7, 5)):
        p.append(m.pyr(f"ToothU{k + 1}", (x, y0 - 0.7, -8.0), (0, -1, 0), (1, 0, 0), 0.9, 0.32, 0.26, "white"))
    for s in (-1, 1):
        n = "LR"[s > 0]
        for k, z in enumerate((-7.0, -6.0, -5.0)):
            p.append(m.pyr(f"ToothU{n}{k + 1}", (s * 2.0, y0 - 0.7, z), (0, -1, 0), (0, 0, 1), 0.8, 0.3, 0.24, "white"))
        # gill slits: three dark ridges on each side behind the head
        for k, z in enumerate((-3.4, -2.7, -2.0)):
            p.append(m.box(f"Gill{n}{k + 1}", (s * (W / 2 + 0.02), y0 + 0.2, z), (0.1, 1.8, 0.22), "sharkdark"))
    # the eyes: a googly eye on the left under a pink scar; an eyepatch on the right
    ey, ez = y0 + 1.3, -6.6
    p += m.eye("EyeL", (-(W / 2 - 0.1), ey, ez), -1, size=1.6, look=(0, 0, -1))
    p += [m.box("Scar", (-(W / 2 - 0.1), ey + 1.0, ez), (0.08, 0.25, 1.8), "scar")]
    p += [m.box("Patch", ((W / 2 - 0.05), ey, ez), (0.25, 1.6, 1.6), "black"),
          m.seg("StrapR", ((W / 2 - 0.05), ey + 0.7, ez + 0.4), ((W / 2 - 0.5), y0 + 2.6, ez + 1.5), 0.25, 0.3, "black"),
          m.box("StrapTop", (0, y0 + 2.7, ez + 1.6), (W - 1.3, 0.12, 0.3), "black"),
          m.seg("StrapL", (-(W / 2 - 0.5), y0 + 2.6, ez + 1.5), (-(W / 2 - 0.05), ey - 0.2, ez + 1.9), 0.25, 0.3, "black")]
    # bandana: a red band behind the head with white dots and a knot on top
    bz = -3.6
    p += [m.box("Bandana", (0, y0 + 0.9, bz), (W + 0.2, 2.6, 1.6), "red"),
          m.box("BandanaTop", (0, y0 + 2.7, bz), (W - 0.8, 0.6, 1.6), "red"),
          m.box("Knot", (0, y0 + 3.1, bz + 0.9), (1.0, 0.8, 0.8), "red")]
    for s in (-1, 1):
        p.append(m.box(f"Dot{'LR'[s > 0]}", (s * (W / 2 + 0.12), y0 + 1.0, bz), (0.06, 0.45, 0.45), "white"))
    # dorsal fin: a tall pyramid raked back
    p += [m.box("DorsalBase", (0, y0 + 2.9, -0.4), (0.8, 1.0, 2.6), "shark"),
          m.pyr("Dorsal", (0, y0 + 3.3, -0.2), (0, 1, 0.7), (0, 0, 1), 3.4, 1.3, 0.4, "shark")]
    m.put(root, p)

    # lower jaw: hinged at the back of the mouth; teeth pointing up, set between the upper ones
    jaw = m.group("Jaw", (0, y0 - 1.6, -4.4), root)
    j = [m.box("JawBox", (0, y0 - 2.0, -6.4), (W - 0.6, 0.8, 4.2), "shark"),
         m.box("JawBelly", (0, y0 - 2.45, -6.2), (W - 1.2, 0.2, 3.6), "belly"),
         m.box("Tongue", (0, y0 - 1.55, -5.6), (W - 2.4, 0.2, 2.2), "gum")]
    for k, x in enumerate(np.linspace(-1.3, 1.3, 4)):
        j.append(m.pyr(f"ToothD{k + 1}", (x, y0 - 1.6, -8.1), (0, 1, 0), (1, 0, 0), 0.7, 0.3, 0.24, "white"))
    for s in (-1, 1):
        for k, z in enumerate((-6.5, -5.5)):
            j.append(m.pyr(f"ToothD{'LR'[s > 0]}{k + 1}", (s * 1.95, y0 - 1.6, z), (0, 1, 0), (0, 0, 1), 0.65, 0.28, 0.22, "white"))
    m.put(jaw, j)

    # pectoral fins: wide fins swept back and down
    for s in (-1, 1):
        n = "LR"[s > 0]
        sh = np.array([s * (W / 2 - 0.2), y0 - 1.0, -2.6])
        fin = m.group(f"Fin{n}", tuple(sh), root)
        tip = sh + np.array([s * 3.4, -1.6, 2.0])
        m.put(fin, [m.seg(f"Fin{n}A", sh, tip, 2.2, 0.55, "shark", up=(0, 1, 0)),
                    m.seg(f"Fin{n}B", sh + [0, -0.05, 0.9], tip + [0, -0.05, 0.6], 1.2, 0.5, "sharkdark", up=(0, 1, 0))])

    # the back half: Body2 (tapering) then Tail (narrow stalk and the two-lobed fin)
    body2 = m.group("Body2", (0, y0 + 0.2, 0.0), root)
    m.put(body2, [m.box("Mid", (0, y0 + 0.3, 2.2), (W - 0.8, H - 1.0, 4.4), "shark"),
                  m.box("MidBelly", (0, y0 - 1.25, 2.2), (W - 1.4, 0.4, 4.0), "belly"),
                  m.box("MidTop", (0, y0 + 2.0, 1.6), (W - 1.8, 0.5, 3.0), "shark"),
                  m.pyr("Fin2", (0, y0 + 1.9, 3.6), (0, 1, 0.8), (0, 0, 1), 1.2, 0.5, 0.25, "shark")]
           + [m.pyr(f"Pelvic{'LR'[s > 0]}", (s * 1.6, y0 - 1.3, 3.2), (s * 0.6, -0.7, 0.8), (0, 0, 1), 1.4, 0.5, 0.2, "sharkdark")
              for s in (-1, 1)])
    tail = m.group("Tail", (0, y0 + 0.3, 4.4), body2)
    m.put(tail, [m.box("Stalk", (0, y0 + 0.4, 5.8), (2.4, 2.4, 3.0), "shark"),
                 m.box("StalkBelly", (0, y0 - 0.85, 5.6), (1.8, 0.3, 2.4), "belly"),
                 m.box("TailHub", (0, y0 + 0.5, 7.6), (1.0, 2.2, 1.2), "sharkdark"),
                 m.seg("LobeUp", (0, y0 + 1.2, 7.4), (0, y0 + 5.0, 10.0), 0.7, 2.0, "shark", up=(0, 0, 1)),
                 m.pyr("LobeUpTip", (0, y0 + 5.0, 10.0), (0, 0.6, 1), (0, 1, 0), 1.5, 1.0, 0.35, "shark"),
                 m.seg("LobeDown", (0, y0 - 0.2, 7.4), (0, y0 - 2.6, 9.4), 0.7, 1.7, "shark", up=(0, 0, 1)),
                 m.pyr("LobeDownTip", (0, y0 - 2.6, 9.4), (0, -0.5, 1), (0, 1, 0), 1.2, 0.85, 0.35, "shark")])
    return m


def animations():
    def swim(L, amp, fin, jaw, lean=0.0, n=16):
        return {"root": [track(L, lambda u: (lean, amp * 0.25 * math.sin(TAU * u), 0), n),
                         track(L, lambda u: (0, 0.3 * math.sin(TAU * u * 2), 0), n, "position")],
                "Body2": [track(L, lambda u: (0, -amp * 0.6 * math.sin(TAU * u - 1.0), 0), n)],
                "Tail": [track(L, lambda u: (0, -amp * math.sin(TAU * u - 2.0), 0), n)],
                "FinL": [track(L, lambda u: (0, 0, fin * math.sin(TAU * u)), n)],
                "FinR": [track(L, lambda u: (0, 0, -fin * math.sin(TAU * u)), n)],
                "Jaw": [track(L, lambda u: (jaw * max(0.0, math.sin(TAU * u * (2 if L < 1 else 1))) ** 2, 0, 0), n)]}

    L = 2.4
    idle = swim(L, 10, 8, 0)
    idle["Jaw"] = [track(L, lambda u: (18 * max(0.0, math.sin(TAU * 2 * u)) ** 8, 0, 0), 24)]
    return {"idle": (L, idle), "walk": (0.9, swim(0.9, 18, 14, 6)), "gallop": (0.45, swim(0.45, 26, 20, 16, lean=-5))}


if __name__ == "__main__":
    build().save(animations())
