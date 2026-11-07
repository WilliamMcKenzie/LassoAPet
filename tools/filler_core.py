"""Building blocks and contact sheets for the per-biome luck-padding animals
(QM, Nov 7: about 15 per biome, 10 common and 5 rarer ones incl. a titan, in the
Meadow/Desert/Tundra style: few blocks, chunky bodies, eyes on the sides, points
and spikes as pyramids).

Static first drafts for QM to pick from: no animations, every part on the root
bone except the head (neck). Biome rosters live in tools/filler_<biome>.py;
tools/filler_designs.py renders them.
"""

import os
import sys

import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(__file__))
import partlib  # noqa: E402
from partlib import Part, look_at, part_faces, render, write_bbmodel  # noqa: E402
import animal_designs as A  # noqa: E402
from animal_designs import Animal, PUPIL  # noqa: E402
from bbmodel_to_luau import PLAIN  # noqa: E402

ROOT = os.path.join(os.path.dirname(__file__), "..")
MODELS = os.path.join(ROOT, "designs", "filler")

# eye colours
RED_EYE = (220, 40, 40)
GOLD_EYE = (240, 190, 40)
ICE_EYE = (90, 200, 250)
GLOW_EYE = (255, 150, 30)


class F(Animal):
    """An Animal with a few shorthands. `rare` marks the 5 rarer ones per biome;
    `role` is a short note for the sheet (flyer, burrower, titan...)."""

    def __init__(self, name, role="", rare=False):
        super().__init__(name, "Rare" if rare else "Common")
        self.role, self.rare = role, rare
        self.pivots = {"root": (0, 0, 0)}
        self.label = None  # display name (defaults to the class name split)

    # boxes ------------------------------------------------------------
    def B(self, name, x0, x1, y0, y1, z0, z1, c, bone="root"):
        return self.box(name, (x0, y0, z0), (x1, y1, z1), c, bone)

    def S(self, name, x0, x1, y0, y1, z0, z1, c, bone="root"):
        """A mirrored pair: x0..x1 given for the right (+x) side."""
        self.box(name + "L", (-x1, y0, z0), (-x0, y1, z1), c, bone)
        self.box(name + "R", (x0, y0, z0), (x1, y1, z1), c, bone)

    def C(self, name, w, y0, y1, z0, z1, c, bone="root"):
        """A centred box, half width w."""
        return self.box(name, (-w, y0, z0), (w, y1, z1), c, bone)

    def W(self, name, x0, x1, y0, y1, z0, z1, c, orient="up_front", bone="root"):
        return self.wedge(name, (x0, y0, z0), (x1, y1, z1), c, bone, orient)

    # pyramids ---------------------------------------------------------
    def P(self, name, x0, x1, y0, y1, z0, z1, axis, length, c, bone="root"):
        """Square pyramid on one face of a box footprint; the footprint's extent
        along `axis` is ignored (it stands on lo or hi of that axis, by sign)."""
        lo, hi = np.array([x0, y0, z0], float), np.array([x1, y1, z1], float)
        k = "xyz".index(axis[1])
        s = 1 if axis[0] == "+" else -1
        base = hi[k] if s > 0 else lo[k]
        lo[k] = hi[k] = base
        c0 = (lo + hi) / 2
        apex = c0.copy()
        apex[k] = base + s * length
        u, v = [i for i in range(3) if i != k]
        corners = []
        for du, dv in ((0, 0), (1, 0), (1, 1), (0, 1)):
            p = lo.copy()
            p[u] = hi[u] if du else lo[u]
            p[v] = hi[v] if dv else lo[v]
            corners.append(p)
        polys = [np.array(corners)] + [np.array([corners[i], corners[(i + 1) % 4], apex]) for i in range(4)]
        p = Part(name, (1, 1, 1), np.eye(4), c, "Poly")
        p.polys = polys
        p.bone = bone
        self.parts.append(p)
        return p

    def SP(self, name, x0, x1, y0, y1, z0, z1, axis, length, c, bone="root"):
        """Mirrored pyramids (right side given); an x axis flips for the left."""
        la = axis if axis[1] != "x" else ("-x" if axis[0] == "+" else "+x")
        self.P(name + "L", -x1, -x0, y0, y1, z0, z1, la, length, c, bone)
        self.P(name + "R", x0, x1, y0, y1, z0, z1, axis, length, c, bone)

    def spikes(self, name, xs, y, zs, size, length, c, axis="+y", bone="root"):
        """A row/grid of pyramids standing on y (top face) at (x, z) centres."""
        i = 0
        for x in xs:
            for z in zs:
                i += 1
                h = size / 2
                self.P(f"{name}{i}", x - h, x + h, y, y, z - h, z + h, axis, length, c, bone)

    # faces ------------------------------------------------------------
    def eyes2(self, x, y0, y1, z0, z1, pupil=PUPIL, bone="neck"):
        """Standard side eyes (white plate, pupil looking forward)."""
        self.eyes(x, y0, y1, z0, z1, bone)
        for p in self.parts[-4:]:
            if p.name.startswith("Pupil"):
                p.color = pupil

    def nose(self, x, y0, y1, z, c, bone="neck"):
        self.box("PlainNose", (-x, y0, z - 0.05), (x, y1, z), c, bone)

    def bones(self):
        used = []
        for p in self.parts:
            b = getattr(p, "bone", "root")
            if b != "root" and b not in used:
                used.append(b)
        return [("root", None, (0, 0, 0))] + [(b, "root", self.pivots.get(b, (0, 0, 0))) for b in used]


def grow(a, k):
    """Scale the whole animal about the ground origin."""
    for p in a.parts:
        if p.shape == "Poly":
            p.polys = [q * k for q in p.polys]
        else:
            p.size = p.size * k
            p.cf[:3, 3] *= k
    a.pivots = {n: tuple(np.array(v) * k) for n, v in a.pivots.items()}


def lift(a, dy):
    for p in a.parts:
        if p.shape == "Poly":
            p.polys = [q + np.array([0, dy, 0]) for q in p.polys]
        else:
            p.cf[1, 3] += dy


# ---------------------------------------------------------------- templates

def quad(a, coat, w, y0, y1, z0, z1, *, legw=None, legd=None, foot=None, foot_h=None, bands=None,
         belly=None, belly_h=None, hw=None, hh=None, hl=None, hy=None, hc=None, neck=None,
         snout=None, snout_c=None, nose_c=None, eye=None, pupil=PUPIL, ears=None, ear_c=None, ear_in=None,
         tail=None, tail_c=None, legs=True):
    """Chunky four-legged animal, front = -z. Returns the head box as
    dict(x=hw, y0, y1, z0 (front), z1 (back)) so callers can add horns etc.
      neck=(nw, nd): a neck column from the body's front top up into the head.
      snout=(sw, sh, sl): a box in front of the head, bottom flush with the head's.
      ears=('up', half, h) | ('round', s) | ('flop', l) | ('side', l)
      tail=('stub', s) | ('long', length, thick) | ('up', height, thick) | ('rope', length)"""
    legw = legw or w * 0.5
    legd = legd or min(1.2, (z1 - z0) * 0.22)
    foot_h = foot_h if foot_h is not None else min(0.5, y0 * 0.2)
    foot = foot or tuple(int(c * 0.6) for c in coat)
    hc = hc or coat
    # body (optional pale belly slice; optional z bands)
    yb = y0 + (belly_h or 0) if belly else y0
    if belly:
        a.C("Belly", w, y0, yb, z0, z1, belly)
    if bands:
        for i, (za, zb, c) in enumerate(bands):
            a.C(f"Body{i + 1}", w, yb, y1, za, zb, c)
    else:
        a.C("Body", w, yb, y1, z0, z1, coat)
    a.dims = dict(x=w, y0=y0, y1=y1, z0=z0, z1=z1)
    if legs and y0 > 0.05:
        for leg in ("FL", "FR", "HL", "HR"):
            sx = -1 if leg[1] == "L" else 1
            za = z0 + 0.001 if leg[0] == "F" else z1 - 0.001 - legd
            xa, xb = sorted((sx * (w - legw), sx * w))
            a.box("Leg" + leg, (xa, foot_h, za), (xb, y0, za + legd), coat, "root")
            if foot_h > 0:
                a.box("Foot" + leg, (xa, 0, za), (xb, foot_h, za + legd), foot, "root")
    # head
    hw = hw or w * 0.75
    hh = hh or (y1 - y0) * 0.8
    hl = hl or hh * 0.9
    if neck:
        nw, nd = neck
        hy = hy if hy is not None else y1 + 1.0
        hz1 = z0 + nd
        a.C("Neck", nw, y1 - min(1.0, (y1 - y0) * 0.5), hy + hh * 0.5, z0 + 0.001, z0 + nd, coat, "neck")
    else:
        hy = hy if hy is not None else y1 - hh * 0.75
        hz1 = z0 + 0.001
    hz0 = hz1 - hl
    a.C("Head", hw, hy, hy + hh, hz0, hz1, hc, "neck")
    a.pivots["neck"] = (0, hy, hz1)
    front = hz0
    if snout:
        sw, sh, sl = snout
        a.C("Snout", sw, hy, hy + sh, hz0 - sl, hz0, snout_c or hc, "neck")
        front = hz0 - sl
        if nose_c:
            a.nose(min(sw * 0.6, 0.6), hy + sh * 0.55, hy + sh * 0.95, front, nose_c)
    elif nose_c:
        a.nose(min(hw * 0.35, 0.5), hy + hh * 0.35, hy + hh * 0.6, hz0, nose_c)
    e = eye or min(hh, hl) * 0.3
    ey = hy + hh * 0.5
    ez = hz0 + hl * 0.12
    a.eyes2(hw, ey, ey + e, ez, ez + e * 0.9, pupil)
    ear_c = ear_c or hc
    top = hy + hh
    if ears:
        kind = ears[0]
        if kind == "up":
            _, half, h = ears
            a.upright_ears(hw * 0.55, top, hz1 - hl * 0.55, hz1 - hl * 0.55 + max(0.3, half * 0.6), half, h, ear_c,
                           ear_in or tuple(min(255, int(c * 1.15) + 30) for c in ear_c))
        elif kind == "round":
            s = ears[1]
            a.S("Ear", hw * 0.45, hw * 0.45 + s, top, top + s * 0.8, hz1 - hl * 0.6, hz1 - hl * 0.6 + s * 0.5, ear_c, "neck")
        elif kind == "flop":
            l = ears[1]
            a.S("Ear", hw, hw + 0.3, top - l, top - 0.1, hz1 - hl * 0.6, hz1 - hl * 0.6 + l * 0.6, ear_c, "neck")
        elif kind == "side":
            l = ears[1]
            a.S("Ear", hw, hw + l, top - hh * 0.3, top - hh * 0.3 + 0.45, hz1 - hl * 0.55, hz1 - hl * 0.55 + 0.6, ear_c, "neck")
    tail_c = tail_c or coat
    if tail:
        kind = tail[0]
        if kind == "stub":
            s = tail[1]
            a.C("Tail", s / 2, y1 - s * 1.2, y1 - s * 0.2, z1, z1 + s * 0.6, tail_c)
        elif kind == "long":
            _, ln, th = tail
            a.C("Tail", th / 2, y1 - th * 1.3, y1 - th * 0.3, z1, z1 + ln, tail_c)
        elif kind == "up":
            _, ht, th = tail
            a.C("Tail", th / 2, y1 - th, y1 - th + ht, z1, z1 + th, tail_c)
        elif kind == "rope":
            ln = tail[1]
            a.C("Tail", 0.15, y1 - ln, y1 - 0.1, z1, z1 + 0.3, tail_c)
            a.C("TailTip", 0.25, y1 - ln - 0.6, y1 - ln, z1 - 0.05, z1 + 0.35, tuple(int(c * 0.6) for c in tail_c))
    return dict(x=hw, y0=hy, y1=hy + hh, z0=front, hz0=hz0, z1=hz1)


def bird(a, c, *, w, leg_h, bh, z0, z1, hw, hh, hl, beak_c, beak_l, leg_c=(240, 160, 50), head_y=None,
         head_dz=0.0, wing_c=None, belly=None, fly=0.0, span=0.0, chord=None, tail_l=1.0, tail_c=None,
         pupil=PUPIL, beak_w=None):
    """Bird: body on two thin legs (none when flying), head on the front top,
    pyramid beak. span > 0 spreads the wings; fly lifts the bird off the ground."""
    y0 = leg_h
    wing_c = wing_c or tuple(int(x * 0.82) for x in c)
    if belly:
        a.C("Belly", w, y0, y0 + bh * 0.4, z0, z1, belly)
        a.C("Body", w, y0 + bh * 0.4, y0 + bh, z0, z1, c)
    else:
        a.C("Body", w, y0, y0 + bh, z0, z1, c)
    if not fly:
        lw = max(0.18, w * 0.16)
        zc = (z0 + z1) / 2
        for side, sx in (("L", -1), ("R", 1)):
            xc = sx * w * 0.45
            a.box("Leg" + side, (xc - lw, 0.25, zc - lw), (xc + lw, y0, zc + lw), leg_c, "root")
            a.box("Foot" + side, (xc - lw * 1.8, 0, zc - lw * 4), (xc + lw * 1.8, 0.25, zc + lw), leg_c, "root")
    hy = head_y if head_y is not None else y0 + bh * 0.55
    hz1 = z0 + hl * 0.55 + head_dz
    hz0 = hz1 - hl
    a.C("Head", hw, hy, hy + hh, hz0, hz1, c, "neck")
    bw = beak_w or hw * 0.45
    a.P("Beak", -bw, bw, hy + hh * 0.2, hy + hh * 0.2 + bw * 1.4, hz0, hz0, "-z", beak_l, beak_c, "neck")
    e = min(hh, hl) * 0.32
    a.eyes2(hw, hy + hh * 0.5, hy + hh * 0.5 + e, hz0 + hl * 0.15, hz0 + hl * 0.15 + e * 0.9, pupil)
    ch = chord or (z1 - z0) * 0.7
    if span > 0:
        top = y0 + bh * 0.85
        a.S("Wing", w, w + span * 0.6, top - 0.4, top, z0 + 0.3, z0 + 0.3 + ch, wing_c)
        a.SP("WingTip", w + span * 0.6, w + span * 0.6, top - 0.4, top, z0 + 0.3, z0 + 0.3 + ch, "+x", span * 0.4, wing_c)
    else:
        a.S("Wing", w, w + 0.3, y0 + bh * 0.25, y0 + bh * 0.85, z0 + 0.4, z1 + 0.3, wing_c)
    if tail_l:
        a.W("Tail", -w * 0.7, w * 0.7, y0 + bh * 0.5, y0 + bh * 0.85, z1, z1 + tail_l, tail_c or wing_c, "down_back")
    if fly:
        lift(a, fly)


def fish(a, c, *, w, h, z0, z1, belly=None, fin_c=None, hl=None, fin_h=None, y0=0.4, pupil=PUPIL, mouth=None,
         dorsal=True, tail_w=None):
    """Swimmer flopping on land like the Fish: body with a pale belly slice,
    head, fan tail fin of two wedges, dorsal wedge, side fins."""
    fin_c = fin_c or tuple(int(x * 0.75) for x in c)
    hl = hl or (z1 - z0) * 0.35
    zh = z0 + hl
    bh = h * 0.35 if belly else 0
    if belly:
        a.C("Belly", w, y0, y0 + bh, zh, z1, belly)
        a.C("HeadBelly", w * 0.9, y0, y0 + bh, z0, zh, belly, "neck")
    a.C("Body", w, y0 + bh, y0 + h, zh, z1, c)
    a.C("Head", w * 0.9, y0 + bh, y0 + h * 0.92, z0, zh, c, "neck")
    if mouth:
        a.B("Mouth", -w * 0.5, w * 0.5, y0 + h * 0.3, y0 + h * 0.4, z0 - 0.05, z0, mouth, "neck")
    e = h * 0.25
    a.eyes2(w * 0.9, y0 + h * 0.5, y0 + h * 0.5 + e, z0 + hl * 0.2, z0 + hl * 0.2 + e, pupil)
    tw = tail_w or 0.25
    fh = fin_h or h * 0.6
    a.C("TailRoot", w * 0.6, y0 + h * 0.3, y0 + h * 0.7, z1, z1 + 0.6, c)
    a.W("FinTop", -tw, tw, y0 + h * 0.5, y0 + h * 0.5 + fh, z1 + 0.6, z1 + 0.6 + fh * 0.8, fin_c)
    a.W("FinBottom", -tw, tw, y0 + h * 0.5 - fh * 0.7, y0 + h * 0.5, z1 + 0.6, z1 + 0.6 + fh * 0.7, fin_c, "down_front")
    if dorsal:
        a.W("Dorsal", -0.25, 0.25, y0 + h, y0 + h + h * 0.4, zh + 0.3, zh + 0.3 + (z1 - zh) * 0.5, fin_c, "up_back")
    a.S("Fin", w, w + h * 0.3, y0 + bh, y0 + bh + 0.3, zh + 0.2, zh + 0.2 + h * 0.4, fin_c)


def mound(a, r, h, c, c2=None, z=0.0):
    """A stepped dirt mound something is burrowing out of."""
    c2 = c2 or tuple(int(x * 0.88) for x in c)
    a.B("Mound", -r, r, 0, h * 0.5, z - r, z + r, c)
    a.B("Mound2", -r * 0.7, r * 0.7, h * 0.5, h, z - r * 0.7, z + r * 0.7, c2)


def bug(a, segs, *, leg_c, leg_h=0.8, leg_out=1.0, leg_t=0.25, antenna=None, ant_c=None, legs=(0, 1, 2)):
    """Insect: segs = [(name, w, y0, y1, z0, z1, colour)] front to back, the
    first is the head. Six legs (an out-and-down L each) on the segments in `legs`."""
    for name, w, y0, y1, z0, z1, c in segs:
        a.C(name, w, y0, y1, z0, z1, c, "neck" if name == "Head" else "root")
    mid = segs[1] if len(segs) > 1 else segs[0]
    _, w, y0, y1, z0, z1, _ = mid
    zs = np.linspace(z0 + leg_t, z1 - leg_t, 3)
    for i, zc in enumerate(zs):
        if i not in legs:
            continue
        a.S(f"Leg{i}", w, w + leg_out, y0 + leg_t * 0.2, y0 + leg_t * 1.2, zc - leg_t / 2, zc + leg_t / 2, leg_c)
        a.S(f"Shin{i}", w + leg_out - leg_t, w + leg_out, 0, y0 + leg_t * 0.2, zc - leg_t / 2, zc + leg_t / 2, leg_c)
    if antenna:
        _, hw, hy0, hy1, hz0, hz1, _ = segs[0]
        ln = antenna
        a.S("Antenna", hw * 0.3, hw * 0.3 + 0.15, hy1, hy1 + ln, hz0 + 0.1, hz0 + 0.25, ant_c or leg_c, "neck")


# ---------------------------------------------------------------- build + render

def build(fn):
    a = fn()
    model, _ = write_bbmodel(a.parts, a.name, None, bones=a.bones())
    for p in a.parts:
        if p.name.startswith(PLAIN):
            p.plain = True
        if p.name.startswith("Glow"):
            p.neon = True
    return a, model


def points(parts):
    return np.concatenate([np.concatenate([w for w, _ in part_faces(p)]) for p in parts])


def bounds(parts):
    pts = points(parts)
    return pts.min(0), pts.max(0)


def size_class(a):
    lo, hi = bounds(a.parts)
    s = max(hi[1], hi[2] - lo[2], (hi[0] - lo[0]) * 0.8)
    for lim, name in ((4.5, "Tiny"), (7.5, "Small"), (12.5, "Medium"), (20, "Large"), (45, "Huge")):
        if s < lim:
            return name
    return "Titan"


def display(a):
    if a.label:
        return a.label
    out = ""
    for ch in a.name:
        if ch.isupper() and out:
            out += " "
        out += ch
    return out


Q34 = np.array([-19, 12, -21], float) / np.linalg.norm([-19, 12, -21])


def tile(parts, W, H, fov=30):
    lo, hi = bounds(parts)
    c = (lo + hi) / 2
    # fit the bounding sphere-ish: project the corners and back off until they fit
    dist = np.linalg.norm(hi - lo) / 2 / np.tan(np.radians(fov) / 2) * 1.05
    for _ in range(3):
        eye = c + Q34 * dist
        e, r, u, f = look_at(eye, c)
        focal = (H / 2) / np.tan(np.radians(fov) / 2)
        d = points(parts) - e
        xs = focal * (d @ r) / (d @ f)
        ys = focal * (d @ u) / (d @ f)
        k = max(np.abs(xs).max() / (W / 2 - 14), np.abs(ys).max() / (H / 2 - 12))
        dist *= k
    return render(parts, eye=c + Q34 * dist, target=c, W=W, H=H, fov=fov)


def set_ground(g1, g2):
    partlib.GROUND = np.array(g1, float)
    partlib.GROUND2 = np.array(g2, float)


def sheet(title, fns, path, ground):
    """5 x 3 grid of close-ups, then every animal plus the Horse in one row at true scale."""
    set_ground(*ground)
    built = [build(fn) for fn in fns]
    TW, TH, band = 380, 300, 46
    cols = 5
    rows = (len(built) + cols - 1) // cols
    fnt, small = A.font(19), A.font(14)
    grid = Image.new("RGB", (TW * cols, (TH + band) * rows), (255, 255, 255))
    d = ImageDraw.Draw(grid)
    for i, (a, _) in enumerate(built):
        x, y = (i % cols) * TW, (i // cols) * (TH + band)
        grid.paste(tile(a.parts, TW, TH), (x, y + band))
        name = display(a) + ("  ★" if a.rare else "")
        sub = f"{'Rare' if a.rare else 'Common'} · {size_class(a)}" + (f" · {a.role}" if a.role else "") + f" · {len(a.parts)} parts"
        for row, (text, fo, col) in enumerate(((name, fnt, (20, 20, 20) if not a.rare else (170, 90, 0)), (sub, small, (90, 90, 90)))):
            tw = d.textlength(text, font=fo)
            d.text((x + (TW - tw) / 2, y + 4 + row * 23), text, fill=col, font=fo)
        d.line([(x, y), (x, y + TH + band)], fill=(255, 255, 255), width=2)
    # true-scale row: horse first, then smallest to largest
    horse = A.qm_horse("A")
    from horse_rig import pose
    hparts = pose(horse, None, 0)
    items = [("Horse", hparts)] + sorted(((display(a), a.parts) for a, _ in built),
                                         key=lambda t: (bounds(t[1])[1] - bounds(t[1])[0]).max())
    scene, xs = [], []
    z = 0
    gap = 3.0
    for name, parts in items:  # side by side along z, all facing -z (screen left)
        lo, hi = bounds(parts)
        dz = z - lo[2]
        dx = -(lo[0] + hi[0]) / 2
        for p in parts:
            q = Part(p.name, p.size, p.cf.copy(), p.color, p.shape, p.plain)
            if p.shape == "Poly":
                q.polys = [w + np.array([dx, 0, dz]) for w in p.polys]
            else:
                q.cf[0, 3] += dx
                q.cf[2, 3] += dz
            scene.append(q)
        xs.append((name, z + (hi[2] - lo[2]) / 2, hi[1]))
        z += hi[2] - lo[2] + gap
    total = z - gap
    tallest = max(h for _, _, h in xs)
    SW = grid.width
    SH = int(np.clip(SW * (tallest + 8) / (total + 6), 240, 720))
    fov = 10
    c = np.array([0, tallest / 2, total / 2])
    view = np.array([-1.0, 0.12, 0])
    view /= np.linalg.norm(view)
    focal = (SH / 2) / np.tan(np.radians(fov) / 2)
    dist = focal * (total / 2 + 3) / (SW / 2 - 10)
    strip = render(scene, eye=c + view * dist, target=c, W=SW, H=SH, fov=fov, outline=True)
    ds = ImageDraw.Draw(strip)
    e, r, u, f = look_at(c + view * dist, c)
    for i, (name, cz, top) in enumerate(xs):
        pt = np.array([0, top + 0.6, cz]) - e
        sx = SW / 2 + focal * (pt @ r) / (pt @ f)
        sy = SH / 2 - focal * (pt @ u) / (pt @ f)
        tw = ds.textlength(name, font=small)
        ds.text((sx - tw / 2, max(2, sy - 18 - (i % 2) * 16)), name, fill=(20, 20, 20), font=small)
    head = Image.new("RGB", (SW, 50), (255, 255, 255))
    dh = ImageDraw.Draw(head)
    dh.text((14, 10), title, fill=(20, 20, 20), font=A.font(26))
    cap = Image.new("RGB", (SW, 30), (255, 255, 255))
    ImageDraw.Draw(cap).text((14, 6), "True scale from the side, with the Horse for size (smallest to largest):", fill=(60, 60, 60), font=small)
    out = Image.new("RGB", (SW, head.height + grid.height + cap.height + strip.height), (255, 255, 255))
    yy = 0
    for im in (head, grid, cap, strip):
        out.paste(im, (0, yy))
        yy += im.height
    out.save(path)
    return built
