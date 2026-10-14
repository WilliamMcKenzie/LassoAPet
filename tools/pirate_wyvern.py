"""Jolly Roger Wyvern: World 3 Pirate Cove's second giga rare (Oct 14; about 1 in 1000). (A Kraken was
the first idea, but World 1's Ocean already has one.) A cursed skeleton sea dragon whose wings
are tattered black pirate sails: a bone skull with backswept pyramid horns, a jaw of pyramid
teeth and glowing green eyes; a long spine of vertebrae with pyramid spikes, a ribcage round a
glowing green cursed heart; bony hind legs with claws; huge wings of bone fingers spanned by
black sail cloth with a white skull and crossbones on each, tattered pyramid hems; a gold
hoop on one horn, and a tail that ends in a gold anchor. A red saddle with gold trim sits
between its shoulders, where you ride.

Run: python3 tools/pirate_wyvern.py [--gif]

Bones: root (ribcage, spine, saddle) -> neck -> Jaw; root -> WingL -> WingL2, WingR ->
WingR2 (flap about Z); root -> Tail -> Tail2 -> Tail3 (anchor); root -> LegL, LegR.

  idle    hovers, slow deep wingbeats, the tail swinging the anchor, jaw clacking
  walk    steady beats, head forward, tail streaming
  gallop  fast hard beats, diving into the chase, jaw snapping
"""

import math

import numpy as np

from pirate_lib import Model, track, TAU

NAME = "JollyRogerWyvern"
C = {"bone": (248, 242, 222), "bonedark": (196, 182, 156), "sail": (36, 32, 48), "saildark": (24, 20, 32),
     "curse": (90, 255, 130), "saddle": (210, 36, 52), "socket": (30, 26, 36)}


def lerp_path(pts, x, axis=0):
    """Interpolate a polyline (sorted along `axis` by |value|) at |coordinate| x; returns the point."""
    pts = [np.array(p, float) for p in pts]
    for a, b in zip(pts, pts[1:]):
        xa, xb = abs(a[axis]), abs(b[axis])
        if min(xa, xb) - 1e-6 <= x <= max(xa, xb) + 1e-6 and abs(xb - xa) > 1e-6:
            t = (x - xa) / (xb - xa)
            return a + (b - a) * t
    return pts[-1] if x > abs(pts[-1][axis]) else pts[0]


def build():
    m = Model(NAME, C)
    y0 = 7.0
    root = m.group("root", (0, y0, 0))
    p = []
    # spine: one thick backbone with four spikes
    p.append(m.box("Spine", (0, y0 + 1.1, 0), (1.6, 1.3, 8.4), "bone"))
    for k, z in enumerate((-2.8, -0.9, 1.0, 2.9)):
        p.append(m.pyr(f"Spike{k + 1}", (0, y0 + 1.7, z), (0, 1, 0.35), (0, 0, 1), 1.2, 0.45, 0.3, "bonedark"))
    # ribcage: four pairs of thick ribs arcing down to a sternum, the cursed heart glowing inside
    for k, z in enumerate(np.linspace(-2.8, 1.6, 4)):
        for s in (-1, 1):
            n = "LR"[s > 0]
            a = np.array([s * 0.6, y0 + 1.0, z])
            b = np.array([s * 3.0, y0 + 0.0, z + 0.3])
            d = np.array([s * 0.7, y0 - 2.3, z + 0.5])
            p += [m.seg(f"Rib{n}{k + 1}A", a, b, 0.85, 0.85, "bone"),
                  m.seg(f"Rib{n}{k + 1}B", b, d, 0.85, 0.85, "bone")]
    p += [m.box("Sternum", (0, y0 - 2.2, -0.4), (1.4, 0.5, 5.2), "bonedark"),
          m.box("Glow_Heart", (0, y0 - 0.4, -0.6), (2.6, 2.4, 2.4), "curse"),
          m.box("Glow_HeartCore", (0, y0 - 0.4, -0.6), (1.2, 2.6, 1.2), "curse"),
          m.box("Pelvis", (0, y0 + 0.4, 3.9), (3.2, 1.4, 1.8), "bone"),
          m.box("PelvisLow", (0, y0 - 0.5, 4.3), (2.2, 0.8, 1.2), "bonedark"),
          m.box("Shoulders", (0, y0 + 0.9, -3.3), (3.4, 1.0, 1.4), "bone")]
    # saddle between the shoulders: red with a gold rim, a gold pommel and cantle
    sy = y0 + 1.75
    p += [m.box("Saddle", (0, sy, -1.4), (2.6, 0.5, 3.0), "saddle"),
          m.box("SaddleRim", (0, sy - 0.25, -1.4), (2.9, 0.25, 3.3), "gold"),
          m.box("Pommel", (0, sy + 0.5, -2.8), (1.2, 0.6, 0.4), "gold"),
          m.box("Cantle", (0, sy + 0.45, 0.0), (2.0, 0.5, 0.4), "gold"),
          m.box("SaddleFlapL", (-1.45, sy - 0.8, -1.4), (0.2, 1.2, 2.2), "saddle"),
          m.box("SaddleFlapR", (1.45, sy - 0.8, -1.4), (0.2, 1.2, 2.2), "saddle")]
    m.put(root, p)

    # neck: vertebrae rising forward to the skull
    nb = np.array([0, y0 + 1.0, -3.9])
    neck = m.group("neck", tuple(nb), root)
    pts = [nb, nb + [0, 1.6, -2.6], nb + [0, 4.4, -5.0]]
    h = []
    for k, (a, b) in enumerate(zip(pts, pts[1:])):
        h += [m.seg(f"NeckBone{k + 1}", a, b, 1.4, 1.4, "bone"),
              m.pyr(f"NeckSpike{k + 1}", (a + b) / 2 + [0, 0.65, 0], (0, 1, 0.5), (0, 0, 1), 0.9, 0.35, 0.25, "bonedark")]
    hc = pts[-1] + np.array([0, 0.6, -1.4])
    h += [m.box("Cranium", hc, (2.8, 2.2, 2.8), "bone"),
          m.box("Brow", hc + [0, 0.95, -1.0], (3.0, 0.5, 0.9), "bonedark"),
          m.box("Snout", hc + [0, -0.2, -3.0], (2.0, 1.3, 3.4), "bone"),
          m.box("SnoutTop", hc + [0, 0.5, -2.8], (1.4, 0.3, 3.0), "bonedark"),
          m.box("NostrilL", hc + [-0.45, 0.6, -4.5], (0.35, 0.06, 0.35), "socket"),
          m.box("NostrilR", hc + [0.45, 0.6, -4.5], (0.35, 0.06, 0.35), "socket")]
    for s in (-1, 1):
        n = "LR"[s > 0]
        # white plate eyes with pupils, set in dark sockets
        h += [m.box(f"Socket{n}", hc + [s * 1.42, 0.2, -0.5], (0.1, 1.7, 1.7), "socket"),
              m.box(f"Eye{n}", hc + [s * 1.5, 0.2, -0.5], (0.08, 1.4, 1.4), "white"),
              m.box(f"Pupil{n}", hc + [s * 1.56, 0.15, -0.75], (0.05, 0.7, 0.7), "pupil"),
              # horns sweeping back, a smaller one under each
              m.pyr(f"Horn{n}", hc + [s * 0.9, 1.0, 0.8], (s * 0.35, 0.45, 1), (1, 0, 0), 3.2, 0.45, 0.45, "bonedark"),
              m.pyr(f"Horn2{n}", hc + [s * 1.3, 0.2, 1.0], (s * 0.5, 0.0, 1), (0, 1, 0), 1.8, 0.3, 0.3, "bonedark")]
        # upper teeth along the snout
        for j, z in enumerate((-2.2, -3.8)):
            h.append(m.pyr(f"ToothU{n}{j + 1}", hc + [s * 0.75, -0.85, z], (0, -1, 0), (0, 0, 1), 0.7, 0.25, 0.2, "white"))
    # a gold hoop on the left horn
    hx = hc + np.array([-1.35, 1.65, 1.9])
    h += [m.box("HoopA", hx + [0, 0.35, 0], (0.16, 0.14, 0.6), "gold"), m.box("HoopB", hx + [0, -0.35, 0], (0.16, 0.14, 0.6), "gold"),
          m.box("HoopC", hx + [0, 0, -0.3], (0.16, 0.6, 0.14), "gold"), m.box("HoopD", hx + [0, 0, 0.3], (0.16, 0.6, 0.14), "gold")]
    m.put(neck, h)
    jaw = m.group("Jaw", tuple(hc + [0, -0.8, 0.6]), neck)
    j = [m.box("JawBone", hc + [0, -1.25, -2.0], (1.9, 0.6, 4.4), "bone"),
         m.box("Chin", hc + [0, -1.45, -4.0], (1.5, 0.5, 0.6), "bonedark")]
    for s in (-1, 1):
        for jj, z in enumerate((-2.0, -2.8)):
            j.append(m.pyr(f"ToothD{'LR'[s > 0]}{jj + 1}", hc + [s * 0.65, -0.95, z], (0, 1, 0), (0, 0, 1), 0.5, 0.17, 0.15, "white"))
    m.put(jaw, j)

    # wings: bone arm and three fingers, black sail cloth between, skull and crossbones on top
    for s in (-1, 1):
        n = "LR"[s > 0]
        sh = np.array([s * 1.6, y0 + 1.1, -2.6])
        el = np.array([s * 5.2, y0 + 2.0, -1.6])
        wr = np.array([s * 7.8, y0 + 2.3, -2.6])
        tips = [np.array([s * 14.2, y0 + 1.5, -1.6]), np.array([s * 12.6, y0 + 1.2, 3.4]), np.array([s * 9.4, y0 + 1.0, 5.6])]
        lead = [sh, el, wr, tips[0]]
        trail = [np.array([s * 1.6, y0 + 0.9, 4.2]), tips[2], tips[1], tips[0]]
        w1 = m.group(f"Wing{n}", tuple(sh), root)
        w2 = m.group(f"Wing{n}2", tuple(el), w1)
        a1 = [m.seg(f"Humerus{n}", sh, el, 1.1, 1.1, "bone"), m.box(f"Elbow{n}", el, (1.0, 1.0, 1.0), "bonedark")]
        a2 = [m.seg(f"Forearm{n}", el, wr, 1.0, 1.0, "bone"), m.box(f"Wrist{n}", wr, (0.95, 0.95, 0.95), "bonedark"),
              m.pyr(f"Thumb{n}", wr + [0, 0.3, -0.3], (s * 0.3, 0.6, -1), (1, 0, 0), 1.3, 0.25, 0.25, "bonedark")]
        for k, t in enumerate(tips):
            a2 += [m.seg(f"Finger{n}{k + 1}", wr, t, 0.7, 0.7, "bone"),
                   m.pyr(f"Claw{n}{k + 1}", t, t - wr, (0, 1, 0), 0.9, 0.22, 0.22, "bonedark")]
        # the sail cloth: strips across the wing between the leading and trailing edges
        xs = np.arange(1.9, 13.9, 1.3)
        for k, x in enumerate(xs):
            L = lerp_path(lead, x)
            T = lerp_path(trail, x)
            z0, z1 = L[2] + 0.35, T[2]
            if z1 - z0 < 0.4:
                continue
            y = (L[1] + T[1]) / 2 - 0.15
            col = "sail" if k % 2 == 0 else "saildark"
            strip = m.box(f"Sail{n}{k + 1}", (s * x, y, (z0 + z1) / 2), (1.32, 0.35, z1 - z0), col)
            (a1 if x < 5.2 else a2).append(strip)
            # tattered hem: a pyramid hanging back off every other strip
            if k % 2 == 1 and x > 2.5:
                (a1 if x < 5.2 else a2).append(m.pyr(f"Tatter{n}{k + 1}", (s * x, y, z1), (0, -0.25, 1), (1, 0, 0), 1.0, 0.55, 0.15, col))
        # skull and crossbones painted on the sail's top (raised white blocks)
        sk = np.array([s * 8.4, y0 + 1.95, 1.4])
        a2 += [m.box(f"SkullW{n}", sk, (1.8, 0.1, 1.6), "white"),
               m.box(f"SkullJawW{n}", sk + [0, 0, 1.05], (1.1, 0.1, 0.6), "white"),
               m.box(f"SkullEyeLW{n}", sk + [-0.42, 0.05, -0.1], (0.5, 0.06, 0.5), "socket"),
               m.box(f"SkullEyeRW{n}", sk + [0.42, 0.05, -0.1], (0.5, 0.06, 0.5), "socket"),
               m.box(f"CrossA{n}", sk + [0, -0.02, 2.0], (3.2, 0.1, 0.4), "white", m_rot("y", 32)),
               m.box(f"CrossB{n}", sk + [0, -0.02, 2.0], (3.2, 0.1, 0.4), "white", m_rot("y", -32))]
        m.put(w1, a1)
        m.put(w2, a2)

    # tail: three bones of vertebrae, ending in a gold anchor
    def tail_bone(name, a, b, parent, nverts, size):
        node = m.group(name, tuple(a), parent)
        q = []
        for k in range(nverts):
            c = a + (b - a) * (k + 0.5) / nverts
            q += [m.box(f"{name}Vert{k + 1}", c, (size, size * 0.85, (np.linalg.norm(b - a) / nverts) * 1.02), "bone"),
                  m.pyr(f"{name}Spike{k + 1}", c + [0, size * 0.42, 0], (0, 1, 0.5), (0, 0, 1), 0.5 * size + 0.2, 0.22, 0.15, "bonedark")]
        m.put(node, q)
        return node

    t0, t1, t2, t3 = (np.array([0, y0 + 0.4, 4.8]), np.array([0, y0 + 0.2, 8.4]), np.array([0, y0 - 0.2, 11.6]),
                      np.array([0, y0 - 0.8, 14.2]))
    tb1 = tail_bone("Tail", t0, t1, root, 1, 1.5)
    tb2 = tail_bone("Tail2", t1, t2, tb1, 1, 1.25)
    tb3 = tail_bone("Tail3", t2, t3, tb2, 1, 1.0)
    ac = t3 + np.array([0, -0.6, 0.6])
    m.put(tb3, [m.box("AnchorRing", t3 + [0, 0, 0.1], (0.3, 0.9, 0.9), "gold"),
                m.seg("AnchorShank", t3 + [0, -0.2, 0.3], ac + [0, -2.4, 0.6], 0.55, 0.55, "gold"),
                m.box("AnchorBar", ac + [0, -0.6, 0.3], (2.8, 0.45, 0.45), "gold"),
                m.box("AnchorCrown", ac + [0, -2.6, 0.65], (3.2, 0.55, 0.55), "golddark"),
                m.pyr("AnchorFlukeL", ac + [-1.5, -2.6, 0.65], (-0.4, 1, 0), (0, 0, 1), 1.6, 0.4, 0.3, "gold"),
                m.pyr("AnchorFlukeR", ac + [1.5, -2.6, 0.65], (0.4, 1, 0), (0, 0, 1), 1.6, 0.4, 0.3, "gold")])

    # hind legs, tucked back under the hips
    for s in (-1, 1):
        n = "LR"[s > 0]
        hip = np.array([s * 1.5, y0 - 0.1, 3.9])
        leg = m.group(f"Leg{n}", tuple(hip), root)
        kn = hip + np.array([s * 0.5, -1.4, -1.0])
        an = kn + np.array([0, -1.2, 1.6])
        ft = an + np.array([0, -0.3, 0.9])
        q = [m.box(f"Hip{n}", hip, (1.0, 1.0, 1.0), "bonedark"),
             m.seg(f"Femur{n}", hip, kn, 0.65, 0.65, "bone"), m.box(f"Knee{n}", kn, (0.8, 0.8, 0.8), "bonedark"),
             m.seg(f"Shin{n}", kn, an, 0.55, 0.55, "bone"), m.seg(f"Foot{n}", an, ft, 0.6, 0.45, "bone")]
        for k, dx in enumerate((-0.3, 0, 0.3)):
            q.append(m.pyr(f"Talon{n}{k + 1}", ft + [dx, 0, 0.1], (dx, -0.6, 1), (1, 0, 0), 0.8, 0.12, 0.12, "bonedark"))
        m.put(leg, q)
    return m


def m_rot(axis, deg):
    from pirate_lib import R
    return R(axis, deg)


def animations():
    def flap(L, amp, amp2, bias=0.0, n=16):
        tr = {}
        for s, nm in ((-1, "L"), (1, "R")):
            tr[f"Wing{nm}"] = [track(L, lambda u, s=s: (0, 0, -s * (bias + amp * math.sin(TAU * u))), n)]
            tr[f"Wing{nm}2"] = [track(L, lambda u, s=s: (0, 0, -s * amp2 * math.sin(TAU * u - 0.9)), n)]
        return tr

    def body(L, bob, lean, tail, jaw, n=16):
        return {"root": [track(L, lambda u: (lean, 0, 0), 4), track(L, lambda u: (0, bob * math.sin(TAU * u - 1.4), 0), n, "position")],
                "neck": [track(L, lambda u: (-lean * 0.5 + 3 * math.sin(TAU * u - 0.5), 0, 0), n)],
                "Jaw": [track(L, lambda u: (jaw * max(0.0, math.sin(TAU * u * 2)) ** 2, 0, 0), n)],
                "Tail": [track(L, lambda u: (tail * 0.3 * math.sin(TAU * u - 1), tail * math.sin(TAU * u - 1), 0), n)],
                "Tail2": [track(L, lambda u: (0, tail * math.sin(TAU * u - 1.8), 0), n)],
                "Tail3": [track(L, lambda u: (0, tail * 1.2 * math.sin(TAU * u - 2.6), 0), n)],
                "LegL": [track(L, lambda u: (20 + 4 * math.sin(TAU * u), 0, 0), n)],
                "LegR": [track(L, lambda u: (20 + 4 * math.sin(TAU * u + 0.5), 0, 0), n)]}

    return {"idle": (1.6, {**flap(1.6, 30, 16, 4), **body(1.6, 0.8, 0, 8, 14)}),
            "walk": (0.9, {**flap(0.9, 36, 20, 2), **body(0.9, 0.9, -4, 10, 8)}),
            "gallop": (0.5, {**flap(0.5, 44, 26, 0), **body(0.5, 1.1, -10, 12, 20)})}


if __name__ == "__main__":
    build().save(animations())
