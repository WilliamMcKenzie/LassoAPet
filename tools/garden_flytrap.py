"""DON'T RERUN for the Venus Flytrap: QM edited designs/garden/VenusFlytrap.bbmodel by hand in Blockbench (Oct 15), which
is now the source; build() would overwrite it. Convert that file instead. build_trap() still serves the Flytrap Queen.

Venus Flytrap: World 3 Garden Epic (draft, Oct 14). A walking flytrap: a fat bulb body wrapped
in a rosette of big leaves, scuttling on four gnarled root legs, a thick stem curving up and forward
to a huge trap head. The trap is two green lobes, wide open, blood-red inside, ringed with long
cream spikes; googly eyes sit on top of the upper lobe under a dark brow. Ridden on the bulb.
It chomps: the upper lobe snaps shut and opens again.

Run: python3 tools/garden_flytrap.py [--gif]
Bones (all rest 0): root -> neck (stem + lower lobe) -> Jaw (upper lobe); LegFL/FR/HL/HR.

build_trap() is shared with the Flytrap Queen boss (tools/garden_flytrap_queen.py).
"""

import sys

import numpy as np

import garden_lib as G
from garden_lib import Garden, Rm, track, sin, TAU

C = {"green": (78, 186, 50), "greendark": (34, 120, 40), "red": (214, 30, 52), "reddark": (140, 14, 40),
     "spike": (252, 240, 200), "root": (118, 76, 46), "rootdark": (78, 50, 34), "leaf": (110, 210, 60),
     "brow": (24, 70, 30)}


def build_trap(g, node, jaw_parent, hinge, size, open_deg, name="", eyes=True, glow=None, white="eyewhite"):
    """A trap head hinged at `hinge` (its back edge), facing -Z: lower lobe on `node`, upper lobe on a
    new bone '<name>Jaw' (rest 0, its opening baked in). size = (width, length, lobe thickness)."""
    w, L, t = size
    h = np.array(hinge, float)
    # lower lobe: a dish, red inside, spikes up round the rim
    g.box(node, name + "Lobe", h + (0, -t / 2, -L / 2), (w, t, L), "green")
    g.box(node, name + "LobeTip", h + (0, -t / 2 + 0.1, -L - 0.3), (w * 0.7, t * 0.8, 0.6), "green")
    g.box(node, name + "Inside", h + (0, 0.05, -L / 2 - 0.1), (w - 0.8, 0.3, L - 0.6), "red")
    g.box(node, name + "InsideDeep", h + (0, 0.12, -L / 2 - 0.1), (w * 0.4, 0.3, L * 0.6), "reddark")
    g.box(node, name + "Belly", h + (0, -t - 0.25, -L / 2 + 0.2), (w * 0.75, 0.5, L * 0.75), "greendark")
    spikes(g, node, name + "SpikeLow", h, w, L, +1, t)
    jaw = g.group(name + "Jaw", h, jaw_parent)
    M = Rm(("x", open_deg))  # opens up about the hinge

    def P(p):
        return h + M @ np.array(p, float)
    g.box(jaw, name + "Upper", P((0, t / 2, -L / 2)), (w, t, L), "green", M)
    g.box(jaw, name + "UpperTip", P((0, t / 2 - 0.1, -L - 0.3)), (w * 0.7, t * 0.8, 0.6), "green", M)
    g.box(jaw, name + "UpperIn", P((0, -0.05, -L / 2 - 0.1)), (w - 0.8, 0.3, L - 0.6), "red", M)
    g.box(jaw, name + "UpperInDeep", P((0, -0.12, -L / 2 - 0.1)), (w * 0.4, 0.3, L * 0.6), "reddark", M)
    g.box(jaw, name + "UpperTop", P((0, t + 0.25, -L / 2 + 0.2)), (w * 0.75, 0.5, L * 0.75), "greendark", M)
    spikes(g, jaw, name + "SpikeUp", h, w, L, -1, t, M)
    if eyes:
        es = w * 0.3
        for side, s in (("L", -1), ("R", 1)):
            base = P((s * w * 0.22, t + 0.5 + es * 0.45, -L * 0.62))
            g.box(jaw, name + "EyeStalk" + side, P((s * w * 0.22, t + 0.4, -L * 0.55)), (es * 1.1, 0.8, es * 1.1), "green", M)
            g.eye(jaw, name + side, base + M @ np.array([0, 0, -es * 0.56]), es, normal=M @ np.array([0, 0.25, -1.0]),
                  look=(0, -0.1), glow=glow, white=white)
            g.box(jaw, name + "Brow" + side, P((s * w * 0.22, t + 0.6 + es * 1.05, -L * 0.62 - es * 0.5)),
                  (es * 1.3, 0.4, 0.5), "brow", M @ Rm(("z", s * 16)))
    return jaw


def spikes(g, node, name, h, w, L, up, t, M=None):
    """Long cream spikes round a lobe's rim (front and both sides), pointing up (+1) or down (-1)."""
    M = np.eye(3) if M is None else M
    pts = []
    n_side = max(3, int(L / 1.8))
    for k in range(n_side):
        z = -L * (0.12 + 0.8 * k / (n_side - 1))
        for s in (-1, 1):
            pts.append(((s * w / 2, 0, z), (s * 0.5, up, 0)))
    n_front = max(2, int(w / 2.0))
    for k in range(n_front):
        x = -w * 0.35 + w * 0.7 * k / (n_front - 1)
        pts.append(((x, 0, -L - 0.4), (0, up, -0.45)))
    for p, d in pts:
        g.pyr(node, name, h + M @ np.array(p, float), M @ np.array(d, float), 1.4 * t, 0.22, 0.22, "spike")


def build():
    g = Garden("VenusFlytrap", C)
    y0 = 4.0
    root = g.group("root", (0, y0, 0))
    # bulb body and a rosette of leaves round it
    g.box(root, "Bulb", (0, y0, 0.8), (5.0, 3.6, 5.0), "greendark")
    g.box(root, "BulbTop", (0, y0 + 2.0, 0.8), (3.8, 0.6, 3.8), "green")
    for k, ang in enumerate(range(0, 360, 45)):
        a = np.radians(ang)
        g.box(root, "Leaf", (2.9 * np.sin(a), y0 - 0.4, 0.8 + 2.9 * np.cos(a)), (2.0, 0.5, 3.4),
              "leaf" if k % 2 else "green", Rm(("y", ang), ("x", 22)))
    # root legs: two segments, out then down
    for nm, (x, z) in (("FL", (-1, -1)), ("FR", (1, -1)), ("HL", (-1, 1)), ("HR", (1, 1))):
        p = np.array([x * 1.6, y0 - 1.2, 0.8 + z * 1.6])
        leg = g.group("Leg" + nm, p, root)
        out = np.array([x, 0.5, z]) / np.linalg.norm([x, 0.5, z])
        g.box(leg, "Leg" + nm, p + out * 1.4, (1.1, 2.8, 1.1), "root", G.frame(out))
        knee = p + out * 2.8
        g.box(leg, "Shin" + nm, knee + (x * 0.2, -knee[1] / 2, z * 0.2), (1.0, knee[1] + 0.2, 1.0), "rootdark")
        g.box(leg, "Toe" + nm, (knee[0] + x * 0.6, 0.3, knee[2] + z * 0.6), (1.4, 0.6, 1.4), "rootdark")
    # stem: three segments curving up and forward
    neck = g.group("neck", (0, y0 + 1.6, -0.6), root)
    for k, (c, sz, tilt) in enumerate((((0, y0 + 3.2, -0.6), (1.8, 3.0, 1.8), -8), ((0, y0 + 5.6, -1.3), (1.6, 2.6, 1.6), -24),
                                       ((0, y0 + 7.4, -2.6), (1.5, 2.0, 1.5), -50))):
        g.box(neck, "Stem", c, sz, "green" if k % 2 == 0 else "greendark", Rm(("x", tilt)))
    g.box(neck, "StemLeafL", (-1.4, y0 + 4.2, -0.8), (2.2, 0.4, 1.2), "leaf", Rm(("z", 25)))
    g.box(neck, "StemLeafR", (1.4, y0 + 5.4, -1.3), (2.2, 0.4, 1.2), "leaf", Rm(("z", -25)))
    build_trap(g, neck, neck, (0, y0 + 8.2, -2.2), (6.0, 6.2, 1.0), 38)
    return g


def animations(m):
    def scuttle(L, swing, lean, hop, chomp, n=16):
        tr = {"root": [track(L, lambda u: (lean, 0, 3 * sin(TAU * u)), n),
                       track(L, lambda u: (0, hop * abs(sin(TAU * u)), 0), n, "position")],
              "neck": [track(L, lambda u: (-lean + 5 * sin(TAU * 2 * u), 6 * sin(TAU * u), 0), n)],
              "Jaw": [track(L, lambda u: (chomp * max(0, sin(TAU * u)) ** 2, 0, 0), n)]}
        for b, ph in (("LegFL", 0), ("LegHR", 0), ("LegFR", 0.5), ("LegHL", 0.5)):
            tr[b] = [track(L, lambda u, ph=ph: (swing * sin(TAU * (u + ph)), 0, 0), n)]
        return tr

    L = 3.0
    idle = {"neck": [track(L, lambda u: (4 * sin(TAU * u), 12 * sin(TAU * u), 3 * sin(TAU * u + 1)), 24)],
            "Jaw": [track(L, lambda u: (32 * max(0, sin(TAU * u * 2 - 1)) ** 6, 0, 0), 48)],
            "root": [track(L, lambda u: (0, 1.5 * sin(TAU * 2 * u), 0), 24, "position")]}
    return {"idle": (L, idle), "walk": (0.7, scuttle(0.7, 20, 0, 3, 18)), "gallop": (0.45, scuttle(0.45, 34, 8, 8, 34))}


if __name__ == "__main__":
    m = build().finish(animations)
    if "--gif" in sys.argv:
        G.gif(m, G.OUT + "/VenusFlytrap_anims.gif")
