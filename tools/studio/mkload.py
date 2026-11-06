# Writes load.luau: syncs src/ into the open place (Rojo layout of default.project.json).
# usage: mkload.py out.luau [src/path.luau ...]   (only those files, if any are named: Lasso's
# src/ is too big to send whole on every map save)
import os,sys
P=os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)),'..','..'))
ONLY=set(sys.argv[2:])
roots=[('src/shared','game.ReplicatedStorage','Shared'),('src/server','game.ServerScriptService','Server'),('src/client','game.StarterPlayer.StarterPlayerScripts','Client')]
# (a Source of 200,000+ chars can't be set directly: those go through ScriptEditorService)
out=['local function set(s,src) if #src<200000 then s.Source=src else game:GetService("ScriptEditorService"):UpdateSourceAsync(s,function() return src end) end end','local function folder(parent,name,class) local f=parent:FindFirstChild(name) if f and f.ClassName~=class then f:Destroy() f=nil end if not f then f=Instance.new(class) f.Name=name f.Parent=parent end return f end','local n=0']
def lit(s):
    k=0
    while ']'+'='*k+']' in s: k+=1
    return '['+'='*k+'['+s+']'+'='*k+']'
def walk(d,parentExpr,name,depth):
    init=[f for f in os.listdir(d) if f.startswith('init.')]
    cls='Folder'; src=None
    if init:
        f=init[0]; cls='Script' if '.server.' in f else 'LocalScript' if '.client.' in f else 'ModuleScript'; src=open(os.path.join(d,f)).read()
    v=f'v{depth}'
    out.append(f'local {v}=folder({parentExpr},"{name}","{cls}")')
    if src is not None: out.append(f'set({v},{lit(src)}) n+=1')
    for f in sorted(os.listdir(d)):
        p=os.path.join(d,f)
        if os.path.isdir(p): walk(p,v,f,depth+1)
        elif f.endswith('.luau') and not f.startswith('init.') and (not ONLY or os.path.relpath(p,P) in ONLY):
            base=f[:-5]; c='ModuleScript'
            if base.endswith('.server'): base=base[:-7]; c='Script'
            elif base.endswith('.client'): base=base[:-7]; c='LocalScript'
            out.append(f'do local s=folder({v},"{base}","{c}") set(s,{lit(open(p).read())}) n+=1 end')
for d,parent,name in roots: walk(os.path.join(P,d),parent,name,0)
out.append('return "loaded "..n')
open(sys.argv[1],'w').write('\n'.join(out))
