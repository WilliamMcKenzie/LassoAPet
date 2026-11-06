# usage: python3 lu.py file.luau [Edit|Client|Server]  (studio id from STUDIO env, else this game's open place, else the first listed)
import json,subprocess,sys,os,time
p=subprocess.Popen(['/Applications/RobloxStudio.app/Contents/MacOS/StudioMCP','--stdio'],stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=subprocess.DEVNULL,text=True)
def send(m): p.stdin.write(json.dumps(m)+'\n'); p.stdin.flush()
def recv(i):
  while True:
    m=json.loads(p.stdout.readline())
    if m.get('id')==i: return m
def call(i,name,args):
  send({"jsonrpc":"2.0","id":i,"method":"tools/call","params":{"name":name,"arguments":args}})
  r=recv(i); outs=[]
  for c in r.get('result',{}).get('content',[]):
    if c.get('type')=='image':
      import base64; fn=os.environ.get('OUT','shot.png'); open(fn,'wb').write(base64.b64decode(c['data'])); outs.append('image -> '+fn)
    else: outs.append(c.get('text',str(c)))
  return "\n".join(outs) + (str(r['error']) if 'error' in r else '')
send({"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"cc","version":"1"}}}); recv(1)
send({"jsonrpc":"2.0","method":"notifications/initialized"})
# (QM, Nov 6: a save should reach Studio in about a second) asks for the open Studios until
# they're there (the one in STUDIO, if set), instead of always waiting 4 seconds
def listed():
  t0=time.time(); n=100; want=os.environ.get('STUDIO')
  while True:
    n+=1
    try: s=json.loads(call(n,'list_roblox_studios',{})).get('studios',[])
    except Exception: s=[]
    if s and (not want or any(x.get('id')==want for x in s)): return s
    if time.time()-t0>8: return s
    time.sleep(0.1)
STUDIOS=listed()
def pick():
  # (QM, Nov 6: with Fight to Steal an Egg open too, "first listed" could be the wrong game)
  # this repo's place, by its PlaceIds in Config.Places, else the first listed
  studios=STUDIOS
  import re
  cfg=open(os.path.join(os.path.dirname(os.path.abspath(__file__)),'..','..','src','shared','Config.luau')).read()
  m=re.search(r'Config\.Places = \{([^}]*)\}',cfg); ids=re.findall(r'\d+',m.group(1)) if m else []
  for s in studios:
    if any(i in json.dumps(s) for i in ids): return s['id']
  return studios[0]['id']
sid=os.environ.get('STUDIO') or pick()
if sys.argv[1]=='--tool':
  a=json.loads(sys.argv[3]) if len(sys.argv)>3 else {}; a['studio_id']=sid; print(call(3,sys.argv[2],a))
else:
  print(call(3,'execute_luau',{"code":open(sys.argv[1]).read(),"datamodel_type":sys.argv[2] if len(sys.argv)>2 else "Edit","studio_id":sid}))
p.kill()
