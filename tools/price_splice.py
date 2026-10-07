# Turns QM's "$100k" Unlock tundra art into "$150k": the first 0 becomes the "5" from
# the Desert button (same font, same size), the last 0 and the k slide left to close the gap.
import sys, numpy as np
from PIL import Image
from scipy import ndimage as nd

def load(p): return np.asarray(Image.open(p).convert('RGBA')).astype(float)

def fills(a, x0=1030, y0=150, y1=320):
    r,g,b=a[...,0],a[...,1],a[...,2]
    mx=np.maximum(np.maximum(r,g),b); mn=np.minimum(np.minimum(r,g),b)
    w=(mn>225)&(mx-mn<25)
    m=np.zeros_like(w); m[y0:y1, x0:]=w[y0:y1, x0:]
    lab,n=nd.label(m)
    comps=[]
    for i,s in enumerate(nd.find_objects(lab)):
        c=lab==i+1
        if c.sum()>1500 and s[0].stop-s[0].start<110: comps.append((s[1].start, c))
    comps.sort(key=lambda t:t[0])
    return comps

def regions(a, comps, R=16):
    # each glyph's pixels: within R of its fill and nearer it than any other glyph's fill
    d=np.stack([nd.distance_transform_edt(~c) for _,c in comps])
    near=d.argmin(0)
    r,g,b=a[...,0],a[...,1],a[...,2]
    mx=np.maximum(np.maximum(r,g),b); mn=np.minimum(np.minimum(r,g),b)
    ink=((mx<90)|((mn>225)&(mx-mn<30)))  # black outline or white/grey fill, not coin or sky
    out=[]
    for i in range(len(comps)):
        out.append((near==i)&(d[i]<=R)&(ink|(d[i]<=2)))
    return out

base_p, five_p, out_p = sys.argv[1:4]
A=load(base_p); D=load(five_p)
ca=fills(A); cd=fills(D)
print('base', [x for x,_ in ca], 'desert', [x for x,_ in cd])
ra=regions(A, ca); rd=regions(D, cd)
# base: $ 1 0 0 k ; desert: $ 5 0 0
erase=nd.binary_dilation(ra[2]|ra[3]|ra[4], iterations=2)&~nd.binary_dilation(ra[0]|ra[1], iterations=1)
out=A.copy()
# keep the button's rim and border: scanning in from the right edge, the border (black) then the rim (light)
H,W=erase.shape
lum=A[...,:3].max(2); low=A[...,:3].min(2)
for y in range(H):
    x=W-1
    while x>0 and A[y,x,3]<10: x-=1
    while x>0 and lum[y,x]<60: x-=1
    r0=x
    while x>r0-9 and low[y,x]>150: x-=1
    if x<W-60: erase[y,x+1:]=False
# background per row: median of the clean strip between the words and the price
strip=A[:, 965:1035, :3]
bg=np.median(strip, axis=1)
H,W=erase.shape
for x in range(W):
    col=erase[:,x]
    if not col.any(): continue
    for y in np.nonzero(col)[0]:
        # under the coin: carry the coin's colour down; elsewhere the sky
        yy=y-1
        while yy>0 and erase[yy,x]: yy-=1
        p=A[yy,x]
        if y-yy<20 and p[3]>200 and np.abs(p[:3]-bg[yy]).sum()>60: out[y,x,:3]=out[yy,x,:3]
        else: out[y,x,:3]=bg[y]
        out[y,x,3]=255
def stamp(src, mask, dx, dy):
    ys,xs=np.nonzero(mask)
    out[ys+dy, xs+dx]=src[ys,xs]
x5=ca[2][1]; # left of the first 0 in base
ys,xs=np.nonzero(ca[2][1]); top0=ys.min(); left0=xs.min()
ys5,xs5=np.nonzero(cd[1][1]); top5=ys5.min(); left5=xs5.min()
ysd0,_=np.nonzero(cd[2][1])
# align the 5 with the desert 0's top -> base 0's top
dy=top0-ysd0.min(); dx=left0-left5
w5=xs5.max()-left5+1
w0=xs.max()-left0+1
shift=-(w0-w5)
print('5 at', left5+dx, 'shift', shift, 'dy', dy)
stamp(A, ra[3], shift, 0)
stamp(A, ra[4], shift, 0)
stamp(D, rd[1], dx, dy)
# close pinholes where neighbouring outlines used to merge
ink=np.zeros_like(erase)
for m,sx,sy in ((ra[0],0,0),(ra[1],0,0),(ra[3],shift,0),(ra[4],shift,0)):
    ys,xs=np.nonzero(m); ink[ys+sy,xs+sx]=True
ys,xs=np.nonzero(rd[1]); ink[ys+dy,xs+dx]=True
holes=nd.binary_closing(ink, iterations=3)&~ink&erase
out[holes,:3]=0; out[holes,3]=255
print('holes filled', holes.sum())
Image.fromarray(out.clip(0,255).astype(np.uint8),'RGBA').save(out_p)
