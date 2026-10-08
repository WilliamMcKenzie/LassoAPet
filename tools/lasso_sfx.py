"""Synthesized lasso training SFX options (all original, no samples, free to upload to Roblox).

Run: python3 lasso_sfx.py [out_dir]   writes one 44.1 kHz 16-bit mono WAV per option.

Three moments: throw (rope leaves), catch (loop cinches on the neck), reward (+N popup).
Every sound is short, since training loops as fast as 4 throws a second.
"""

import math
import os
import sys
import wave

import numpy as np

SR = 44100
rng = np.random.default_rng(7)


def t(dur):
    return np.arange(int(SR * dur)) / SR


def env(n, attack, release, curve=3.0):
    """Linear attack, power-curve release, in seconds."""
    a = max(1, int(SR * attack))
    e = np.ones(n)
    e[:a] = np.linspace(0, 1, a)
    r = max(1, n - a)
    e[a:] = (1 - np.linspace(0, 1, r)) ** curve
    return e


def bandpass(x, f_lo, f_hi, q=1.2):
    """Time-varying biquad bandpass; f_lo/f_hi give the centre sweep from start to end."""
    n = len(x)
    fc = np.geomspace(f_lo, f_hi, n)
    y = np.zeros(n)
    x1 = x2 = y1 = y2 = 0.0
    for i in range(n):
        w = 2 * math.pi * fc[i] / SR
        al = math.sin(w) / (2 * q)
        cw = math.cos(w)
        a0 = 1 + al
        b0, b2 = al / a0, -al / a0
        a1, a2 = -2 * cw / a0, (1 - al) / a0
        yi = b0 * x[i] + b2 * x2 - a1 * y1 - a2 * y2
        x2, x1, y2, y1 = x1, x[i], y1, yi
        y[i] = yi
    return y


def lowpass(x, fc):
    a = math.exp(-2 * math.pi * fc / SR)
    y = np.zeros_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        acc = (1 - a) * v + a * acc
        y[i] = acc
    return y


def sweep(f0, f1, dur, shape="exp"):
    n = int(SR * dur)
    f = np.geomspace(f0, f1, n) if shape == "exp" else np.linspace(f0, f1, n)
    return np.sin(2 * math.pi * np.cumsum(f) / SR)


def noise(dur):
    return rng.uniform(-1, 1, int(SR * dur))


def tone(freqs, dur, decay, attack=0.002):
    tt = t(dur)
    out = np.zeros_like(tt)
    for f, amp in freqs:
        out += amp * np.sin(2 * math.pi * f * tt)
    return out * env(len(tt), attack, 1, 1) * np.exp(-tt / decay)


def mix(*parts):
    n = max(len(p[1]) + int(SR * p[0]) for p in parts)
    out = np.zeros(n)
    for start, sig in parts:
        s = int(SR * start)
        out[s:s + len(sig)] += sig
    return out


def norm(x, peak=0.89):
    x = x - x.mean()
    fade = min(len(x), int(SR * 0.004))
    x[-fade:] *= np.linspace(1, 0, fade)
    return x / (np.abs(x).max() + 1e-9) * peak


# ---------- throw ----------

def throw_whoosh():
    d = 0.24
    x = bandpass(noise(d), 500, 2600, q=1.6)
    return x * env(len(x), 0.09, 1, 2.2)


def throw_whip():
    d = 0.2
    body = bandpass(noise(d), 900, 4500, q=2.5) * env(int(SR * d), 0.12, 1, 4)
    crack = bandpass(noise(0.03), 3500, 3000, q=0.8) * env(int(SR * 0.03), 0.001, 1, 3) * 0.9
    return mix((0, body), (0.135, crack))


def throw_twirl():
    d = 0.3
    tt = t(d)
    x = bandpass(noise(d), 700, 1600, q=2.2)
    wob = 0.45 + 0.55 * (0.5 + 0.5 * np.sin(2 * math.pi * np.cumsum(np.linspace(10, 22, len(tt))) / SR))
    return x * wob * env(len(tt), 0.05, 1, 1.6)


def throw_fwip():
    d = 0.14
    s = sweep(300, 1500, d) * env(int(SR * d), 0.01, 1, 2)
    air = bandpass(noise(d), 1500, 5000, q=1.5) * env(int(SR * d), 0.02, 1, 2) * 0.6
    return s * 0.7 + air


# ---------- catch ----------

def catch_zip():
    """Rope runs through the honda: a fast rising ratchet, ending tight."""
    parts = []
    clicks = 9
    for k in range(clicks):
        start = 0.011 * k
        f = 1300 + 160 * k
        c = bandpass(noise(0.012), f, f, q=4) * env(int(SR * 0.012), 0.0005, 1, 3)
        parts.append((start, c * (0.6 + 0.05 * k)))
    end = tone([(520, 1), (1040, 0.3)], 0.08, 0.025) * 0.7
    parts.append((0.011 * clicks, end))
    return mix(*parts)


def catch_thwack():
    d = 0.16
    tt = t(d)
    thump = np.sin(2 * math.pi * np.cumsum(np.geomspace(190, 70, len(tt))) / SR) * np.exp(-tt / 0.045)
    snap = bandpass(noise(0.025), 2200, 1800, q=1) * env(int(SR * 0.025), 0.0005, 1, 3) * 0.9
    return mix((0, thump), (0, snap))


def catch_twang():
    """Rope goes taut: a plucked low string with a slight bend."""
    d = 0.32
    tt = t(d)
    f = 110 * (1 + 0.06 * np.exp(-tt / 0.03))
    ph = 2 * math.pi * np.cumsum(f) / SR
    s = sum(np.sin(h * ph) / h ** 1.2 for h in range(1, 7))
    s = lowpass(s, 2500) * np.exp(-tt / 0.09)
    click = bandpass(noise(0.01), 3000, 3000, q=1) * env(int(SR * 0.01), 0.0005, 1, 2) * 0.5
    return mix((0, s), (0, click))


def catch_tug():
    """Cartoon yank: quick boing up then down."""
    d = 0.18
    tt = t(d)
    f = 180 + 260 * np.sin(math.pi * np.clip(tt / 0.12, 0, 1))
    s = np.sin(2 * math.pi * np.cumsum(f) / SR) * env(len(tt), 0.004, 1, 2)
    return s + 0.25 * np.sin(2 * 2 * math.pi * np.cumsum(f) / SR) * env(len(tt), 0.004, 1, 2)


# ---------- reward ----------

def reward_pop():
    d = 0.09
    tt = t(d)
    s = np.sin(2 * math.pi * np.cumsum(np.geomspace(450, 1300, len(tt))) / SR) * env(len(tt), 0.002, 1, 2.5)
    return s


def reward_coin():
    a = tone([(988, 1), (1976, 0.25)], 0.07, 0.05)
    b = tone([(1319, 1), (2638, 0.3), (3957, 0.1)], 0.3, 0.09)
    return mix((0, a * 0.8), (0.065, b))


def reward_sparkle():
    notes = [1047, 1319, 1568, 2093]
    return mix(*[(0.035 * i, tone([(f, 1), (f * 2.01, 0.2)], 0.22, 0.06) * (0.8 + 0.07 * i)) for i, f in enumerate(notes)])


def reward_bloop():
    d = 0.16
    tt = t(d)
    f = 520 + 380 * (1 - np.exp(-tt / 0.03))
    s = np.sin(2 * math.pi * np.cumsum(f) / SR)
    s = s + 0.35 * np.sin(2 * 2 * math.pi * np.cumsum(f) / SR)
    return s * env(len(tt), 0.004, 1, 2) * (1 - 0.3 * np.sin(2 * math.pi * 28 * tt))


SOUNDS = {
    "throw_whoosh": throw_whoosh, "throw_whip": throw_whip, "throw_twirl": throw_twirl, "throw_fwip": throw_fwip,
    "catch_zip": catch_zip, "catch_thwack": catch_thwack, "catch_twang": catch_twang, "catch_tug": catch_tug,
    "reward_pop": reward_pop, "reward_coin": reward_coin, "reward_sparkle": reward_sparkle, "reward_bloop": reward_bloop,
}


def write(path, x):
    pcm = (np.clip(x, -1, 1) * 32767).astype("<i2")
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())


def main(out=os.path.dirname(os.path.abspath(__file__))):
    os.makedirs(out, exist_ok=True)
    for name, fn in SOUNDS.items():
        x = norm(fn())
        write(os.path.join(out, name + ".wav"), x)
        print(f"{name:16s} {len(x) / SR:.2f}s")


if __name__ == "__main__":
    main(*sys.argv[1:])
