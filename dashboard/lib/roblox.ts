import { mergeTotals, type Totals, type Snapshot } from './metrics';

export const UNIVERSE = '10768914077';
type Entry = { data: Totals | null; at: number };
const cache = new Map<string, Promise<Entry>>();
export class UpstreamError extends Error { constructor(message: string, public status: number) { super(message); } }
export async function readEntry(key: string, store: string, entry: string): Promise<Totals | null> {
  const hash = Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256',new TextEncoder().encode(key)))).map(b=>b.toString(16).padStart(2,'0')).join('');
  const cacheKey = `${hash}:${store}:${entry}`;
  const previous = cache.get(cacheKey);
  if (previous) { const hit=await previous; if (Date.now()-hit.at<30000) return hit.data; cache.delete(cacheKey); }
  const pending = (async () => {
    const url=new URL(`https://apis.roblox.com/datastores/v1/universes/${UNIVERSE}/standard-datastores/datastore/entries/entry`);
    url.search=new URLSearchParams({datastoreName:store,scope:'global',entryKey:entry}).toString();
    let res: Response;
    try { res=await fetch(url,{headers:{'x-api-key':key},signal:AbortSignal.timeout(12000)}); }
    catch { throw new UpstreamError('Roblox did not respond. Try again shortly.',502); }
    if (res.status===404) return {data:null,at:Date.now()};
    if (!res.ok) throw new UpstreamError(res.status===401 ? 'Roblox rejected this API key. It may have expired.' : res.status===403 ? `This key cannot read ${store}. Check experience, datastore read permissions, and IP restrictions.` : res.status===429 ? 'Roblox is rate limiting reads. Automatic refresh will retry.' : `Roblox returned ${res.status}. Try again shortly.`,res.status);
    const raw: unknown=await res.json();
    if (!raw || typeof raw!=='object' || Array.isArray(raw)) throw new UpstreamError(`Unexpected data in ${store}/${entry}.`,502);
    const data: Totals={};
    for (const [k,v] of Object.entries(raw)) if (typeof v==='number' && Number.isFinite(v)) data[k]=v;
    return {data,at:Date.now()};
  })();
  if (cache.size>256) cache.clear();
  cache.set(cacheKey,pending);
  try { return (await pending).data; } catch(e) { cache.delete(cacheKey); throw e; }
}

// The game spreads each total over SHARDS entries ("<entry>#0".."#9", one per server; see
// src/server/StatsStore.luau) besides the plain entry it wrote before Oct 18: a total is all of
// them merged (counts summed, "max:" fields the biggest). null when none of them exist.
export const SHARDS = 10;
export async function readTotals(key: string, store: string, entry: string): Promise<Totals | null> {
  const parts = await Promise.all([readEntry(key,store,entry), ...Array.from({length:SHARDS},(_,n)=>readEntry(key,store,`${entry}#${n}`))]);
  return parts.every(p=>p===null) ? null : mergeTotals(parts);
}
export async function snapshot(key: string, dates: string[]): Promise<Snapshot> {
  const result: Snapshot={days:[],funnels:[],worlds:null,online:null,fetchedAt:new Date().toISOString(),issues:[]};
  // Reject invalid credentials before fan-out; a missing date is a valid empty result.
  await readEntry(key,'SessionStatsShared',`v1d-${dates[dates.length-1]}`);
  const jobs = [
    ...dates.map(date=>({label:date,run:async()=>{result.days.push({date,data:await readTotals(key,'SessionStatsShared',`v1d-${date}`)});}})),
    ...[1,2,3].map(world=>({label:`World ${world} funnels`,run:async()=>{result.funnels.push({world,data:await readTotals(key,world===1?'SessionStats':`SessionStats_W${world}`,'v1-funnels')});}})),
    {label:'World progression',run:async()=>{result.worlds=await readTotals(key,'SessionStatsShared','v1-worlds');}},
  ];
  let cursor=0;
  await Promise.all(Array.from({length:4},async()=>{while(cursor<jobs.length){const job=jobs[cursor++];try{await job.run();}catch(e){result.issues.push(`${job.label}: ${e instanceof UpstreamError ? e.message : 'Read failed.'}`);}}}));
  try {
    const res=await fetch(`https://games.roblox.com/v1/games?universeIds=${UNIVERSE}`,{signal:AbortSignal.timeout(5000)});
    if(res.ok){const body=await res.json() as {data?:{id:number;playing:number}[]};const game=body.data?.find(g=>String(g.id)===UNIVERSE);result.online=typeof game?.playing==='number'?game.playing:null;}
  } catch { /* Online count is optional and separate from custom session telemetry. */ }
  result.days.sort((a,b)=>a.date.localeCompare(b.date));
  result.funnels.sort((a,b)=>a.world-b.world);
  result.fetchedAt=new Date().toISOString();
  return result;
}
