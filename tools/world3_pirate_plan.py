import json, math, random
random.seed(14)
d=json.load(open('w3map.json'))
rows=d['rows']  # rows[i] = z 4+8i, col j = x -212+8j
def cell(x,z):
    j=round((x+212)/8); i=round((z-4)/8)
    if 0<=i<len(rows) and 0<=j<len(rows[0]): return rows[i][j]
    return '#'
def inpen(x,z,m):
    for cx,cz,sx,sz,lx,lz,spx,spz in d['pens']:
        dx,dz=x-cx,z-cz
        # local axes: look (lx,lz), right (-lz,lx)
        a=dx*lx+dz*lz; b=dx*(-lz)+dz*lx
        if abs(a)<sz/2+m and abs(b)<sx/2+m: return True
    return False
def seg_dist(px,pz,ax,az,bx,bz):
    vx,vz=bx-ax,bz-az; t=max(0,min(1,((px-ax)*vx+(pz-az)*vz)/(vx*vx+vz*vz)))
    return math.hypot(px-ax-t*vx,pz-az-t*vz)
HUB=(0,120)
def onpath(x,z,m):
    for p in d['pens']:
        if seg_dist(x,z,p[6],p[7],*HUB)<m: return True
    if seg_dist(x,z,0,0,*HUB)<m+8: return True   # spawn / start line to the middle
    for name,px,pz in d['portal']:
        if name=='PortalGate' and math.hypot(x-px,z-pz)<30: return True
    if seg_dist(x,z,-76,29,*HUB)<m: return True  # the portal's walk
    return False
def wallok(x,z,m): return abs(x)<216-m and z<320-m and z>m
def land(x,z): return cell(x,z) in 'Sw'
def nearwater(x,z,r=8):
    best=None
    for a in range(0,360,30):
        wx,wz=x+r*math.cos(math.radians(a)),z+r*math.sin(math.radians(a))
        if cell(wx,wz)=='~': best=a; break
    return best
out=[]
# --- palms: sand at the water's edge
cands=[]
for i,r in enumerate(rows):
    for j,ch in enumerate(r):
        x,z=-212+8*j,4+8*i
        if ch in 'Sw' and wallok(x,z,8) and not inpen(x,z,8) and not onpath(x,z,16):
            a=nearwater(x,z,10)
            if a is not None: cands.append((x,z,a))
random.shuffle(cands)
palms=[]
for x,z,a in cands:
    if all(math.hypot(x-p[0],z-p[1])>34 for p in palms): palms.append((x,z,a))
palms=palms[:14]
for k,(x,z,a) in enumerate(palms):
    big = k%3!=2
    out.append(dict(item='PalmTree' if big else 'PalmTreeSmall',x=x,z=z,yaw=random.uniform(0,360),lean=10,leanTo=a,y=-0.4))
    if not big or k%4==0:  # a small one or two beside it
        for n in range(1 if big else 2):
            for _ in range(20):
                ang=random.uniform(0,2*math.pi); dd=random.uniform(7,11)
                sx,sz=x+dd*math.cos(ang),z+dd*math.sin(ang)
                if land(sx,sz) and wallok(sx,sz,6) and not inpen(sx,sz,6) and not onpath(sx,sz,12):
                    out.append(dict(item='PalmTreeSmall',x=sx,z=sz,yaw=random.uniform(0,360),lean=12,leanTo=math.degrees(math.atan2(sz-z,sx-x)),y=-0.4)); break
# --- crate and barrel piles
PILES=[[('CrateStack',0,0,0),('Barrel',6.5,-2,0),('Crate',-6,1.5,20)],
       [('BarrelGroup',0,0,0),('Crate',5.5,-3,10)],
       [('Crate',0,0,0),('Crate',4.4,0.5,15),('Barrel',2,4.5,0),('Barrel',-2.5,4,0)],
       [('CrateStack',0,0,90),('BarrelGroup',7.5,1,0)]]
def pile_ok(x,z):
    return all(land(x+dx,z+dz) for dx in (-6,0,6) for dz in (-6,0,6)) and wallok(x,z,6) and not inpen(x,z,5) and not onpath(x,z,14)
spots=[]
# near the portal, by pen back corners, by the walls
want=[(-104,44),(-50,56)]
for cx,cz,sx,sz,lx,lz,spx,spz in d['pens']:
    for sb in (-1,1):
        # back corner: far from the gate (gate faces look dir), outside the pen
        bx=cx - lx*(sz/2+8) + (-lz)*sb*(sx/2+8); bz=cz - lz*(sz/2+8) + lx*sb*(sx/2+8)
        want.append((bx,bz))
want += [(-200,200),(200,200),(-60,312),(60,312),(-200,120),(200,40)]
for wx,wz in want:
    best=None
    for r in range(0,40,4):
        for a in range(0,360,30):
            x,z=wx+r*math.cos(math.radians(a)),wz+r*math.sin(math.radians(a))
            if pile_ok(x,z) and all(math.hypot(x-s[0],z-s[1])>40 for s in spots) and all(math.hypot(x-o['x'],z-o['z'])>9 for o in out):
                best=(x,z); break
        if best: break
    if best: spots.append(best)
for k,(x,z) in enumerate(spots[:8]):
    rot=random.uniform(0,360)
    for item,dx,dz,yy in PILES[k%len(PILES)]:
        c,s=math.cos(math.radians(rot)),math.sin(math.radians(rot))
        out.append(dict(item=item,x=x+dx*c-dz*s,z=z+dx*s+dz*c,yaw=rot+yy,y=0))
# --- the ship: all water under it, out of the pens, nearest the spawn's view
best=None
for i in range(len(rows)):
    for j in range(len(rows[0])):
        x,z=-212+8*j,4+8*i
        for yaw in (0,30,60,90,120,150):
            c,s=math.cos(math.radians(yaw)),math.sin(math.radians(yaw))
            ok=True
            for u in range(-26,27,4):
                for v in range(-10,11,4):
                    px,pz=x+v*c+u*s, z-v*s+u*c
                    if cell(px,pz)!='~' or inpen(px,pz,2) or not wallok(px,pz,4): ok=False; break
                if not ok: break
            if ok:
                dist=math.hypot(x,z-20); ahead=(z-20)/max(dist,1)
                score=dist*(1.6-ahead)
                if best is None or score<best[0]: best=(score,x,z,yaw)
print('ship',best)
if best: out.append(dict(item='PirateShip',x=best[1],z=best[2],yaw=best[3]+180,y=-4))
json.dump(out,open('pirate_place.json','w'))
from collections import Counter
print(len(out),Counter(o['item'] for o in out),'piles',len(spots))
