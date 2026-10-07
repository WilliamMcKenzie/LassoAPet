# Redraws the price on an Upgrade Pen button (QM's art) from glyphs cut out of the
# other buttons: same FredokaOne size on all of them. Every glyph's fill is a white
# blob; its black outline is everything within STROKE of it that's nearer it than
# any other glyph. The old price is painted over with the button's own background
# (each row's median, so the gradient carries on; under the coin, the coin carries
# down), the button's border and rim are kept, then the new glyphs are stamped in,
# centred where the old price was.
#   python3 tools/price_splice.py BUTTON.png '$150m' OUT.png [--library DIR]
# The library is assets/ui: "1" from git's $100k Tundra button, "5" from the Desert's.
import sys, subprocess, io, numpy as np
from PIL import Image
from scipy import ndimage as nd

R = 16
GAP = {('$', '*'): 5, ('*', 'm'): 9, ('*', 'k'): 9, ('*', '*'): 7, ('1', '*'): 8}

def load(p):
    if isinstance(p, bytes):
        return np.asarray(Image.open(io.BytesIO(p)).convert('RGBA')).astype(float)
    return np.asarray(Image.open(p).convert('RGBA')).astype(float)

def ink_of(a):
    mx = a[..., :3].max(2); mn = a[..., :3].min(2)
    return (mx < 90) | ((mn > 225) & (mx - mn < 30))

def glyphs(a, x0=1045, y0=150, y1=320):
    mx = a[..., :3].max(2); mn = a[..., :3].min(2)
    w = (mn > 225) & (mx - mn < 25)
    m = np.zeros_like(w); m[y0:y1, x0:] = w[y0:y1, x0:]
    lab, n = nd.label(m)
    comps = []
    for i, s in enumerate(nd.find_objects(lab)):
        c = lab == i + 1
        if c.sum() > 1500 and s[0].stop - s[0].start < 110 and s[1].start >= x0:
            comps.append(c)
    comps.sort(key=lambda c: np.nonzero(c)[1].min())
    d = np.stack([nd.distance_transform_edt(~c) for c in comps])
    near = d.argmin(0); ink = ink_of(a)
    out = []
    for i, c in enumerate(comps):
        reg = (near == i) & (d[i] <= R) & (ink | (d[i] <= 2))
        ys, xs = np.nonzero(c)
        out.append(dict(src=a, mask=reg, left=xs.min(), right=xs.max(), top=ys.min()))
    return out

def gap(p, q):
    for k in ((p, q), (p, '*'), ('*', q), ('*', '*')):
        if k in GAP: return GAP[k]

def main():
    base_p, text, out_p = sys.argv[1:4]
    A = load(base_p)
    old = glyphs(A)
    zero_top = min(g['top'] for g in old[1:] if g['mask'].sum() > 0 and (g['right'] - g['left']) in range(60, 72))
    lib = {'$': (old[0], 0)}
    for g in old[1:]:
        w = g['right'] - g['left']
        if w > 85: lib.setdefault('m', (g, g['top'] - zero_top))
        elif 52 <= w <= 60 and g['top'] < zero_top: lib.setdefault('k', (g, g['top'] - zero_top))
    t100 = glyphs(load(subprocess.check_output(['git', 'show', '8c3e140:assets/ui/UpgradePenTundra.png'])))
    lib.setdefault('1', (t100[1], t100[1]['top'] - t100[2]['top']))
    lib.setdefault('k', (t100[4], t100[4]['top'] - t100[2]['top']))
    des = glyphs(load('assets/ui/UpgradePenDesert.png'))
    lib.setdefault('5', (des[1], des[1]['top'] - des[2]['top']))
    lib.setdefault('0', (des[2], 0))
    # layout, centred on the old price
    widths = [lib[c][0]['right'] - lib[c][0]['left'] + 1 for c in text]
    total = sum(widths) + sum(gap(text[i], text[i + 1]) for i in range(len(text) - 1))
    old_l, old_r = old[0]['left'], max(g['right'] for g in old)
    x = int(round((old_l + old_r + 1 - total) / 2))
    out = A.copy(); H, W = A.shape[:2]
    erase = np.zeros((H, W), bool)
    for g in old: erase |= g['mask']
    erase = nd.binary_dilation(erase, iterations=2)
    erase[:, :old_l - R - 2] = False
    # each row's background: the median of everything well clear of any lettering
    mx = A[..., :3].max(2); mn = A[..., :3].min(2)
    clear = nd.distance_transform_edt(~((mn > 225) & (mx - mn < 25))) > R + 4
    bg = np.zeros((H, 3))
    for y in range(H):
        sl = slice(400, old_l - R - 2)
        keep = clear[y, sl] & (A[y, sl, 3] > 200)
        bg[y] = np.median(A[y, sl][keep, :3], axis=0) if keep.any() else A[y, sl, :3].mean(0)
    for xc in range(W):
        for y in np.nonzero(erase[:, xc])[0]:
            yy = y - 1
            while yy > 0 and erase[yy, xc]: yy -= 1
            p = A[yy, xc]
            if y - yy < 20 and p[3] > 200 and np.abs(p[:3] - bg[yy]).sum() > 60:
                out[y, xc, :3] = out[yy, xc, :3]
            else:
                out[y, xc, :3] = bg[y]
            out[y, xc, 3] = 255
    # the button's right end is its left end mirrored: put its border and rim back
    # (and nothing past it) wherever the old price covered them
    row = np.nonzero(A[120, :, 3] > 128)[0]
    C = row.min() + row.max()
    for y in np.nonzero(erase.any(1))[0]:
        L = np.nonzero(A[y, :, 3] > 128)[0].min()
        for xc in np.nonzero(erase[y])[0]:
            if xc >= C - L - 24:
                out[y, xc] = A[y, C - xc] if C - xc >= 0 else 0
    newink = np.zeros((H, W), bool)
    for i, c in enumerate(text):
        g, dtop = lib[c]
        ys, xs = np.nonzero(g['mask'])
        dx = x - g['left']; dy = (zero_top + dtop) - g['top']
        ok = (ys + dy >= 0) & (ys + dy < H) & (xs + dx < W)
        out[ys[ok] + dy, xs[ok] + dx] = g['src'][ys[ok], xs[ok]]
        newink[ys[ok] + dy, xs[ok] + dx] = True
        x += widths[i] + (gap(c, text[i + 1]) if i + 1 < len(text) else 0)
    # close pinholes where neighbouring outlines used to merge
    holes = nd.binary_closing(newink, iterations=3) & ~newink & erase
    out[holes, :3] = 0; out[holes, 3] = 255
    Image.fromarray(out.clip(0, 255).astype(np.uint8), 'RGBA').save(out_p)

if __name__ == '__main__':
    main()
