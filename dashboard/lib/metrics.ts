export type Totals = Record<string, number>;
export type Snapshot = { days: { date: string; data: Totals | null }[]; funnels: { world: number; data: Totals | null }[]; worlds: Totals | null; online: number | null; fetchedAt: string; issues: string[] };
export const SEGMENTS = { all: 'All players', new: 'New players', ret: 'Returning players', pc: 'Desktop', phone: 'Phone', tablet: 'Tablet', console: 'Console' };
export type Segment = keyof typeof SEGMENTS;
export const BIOMES = [['Meadow', 'Desert', 'Tundra', 'Ocean', 'Volcano', 'Jurassic'], ['Meadow', 'Crimson Lands', 'Crystal Cavern', 'Woodland Maze', 'Temple', 'Tomb']];
export const FUNNELS = [
  { name: '[V1] Tutorial', steps: ['New profile loaded', 'Intro finished', 'Starter pet ready', 'Crossed start line', 'First animal awarded', 'Tutorial finished'] },
  { name: '[V1] First Session Loop', steps: ['New profile loaded', 'Tutorial finished', 'Ride started', 'Reward received', 'Another ride started', 'Another reward received'] },
  { name: '[V1] World 1 Biomes', steps: ['First arrival', ...BIOMES[0]] },
  { name: '[V1] World 2 Biomes', steps: ['First arrival', ...BIOMES[1]] },
  { name: '[V1] Quest Claims', steps: ['Has unfinished quests', 'Has claimable quest', 'Claimed 1 quest', 'Claimed 2 quests', 'Claimed 3 quests'] },
  { name: '[V1] Quest Progress', steps: ['Current quest', 'Ready to claim', 'Claimed'] },
];
export const QUESTS: Record<number, Record<string, string>> = {
  1: {101:'Reach Meadow',102:'Reach Desert',103:'Reach Tundra',104:'Reach Ocean',105:'Reach Volcano',106:'Reach Jurassic',201:'Lasso 3 animals',202:'Merge 3 animals',203:'Collect 10 animals',204:'Lasso 4 Snowmen',205:'Lasso 3 King Crabs',206:'Lasso 2 Lava Whales',207:'Lasso Bone Rex',301:'Invite a friend'},
  2: {101:'Reach Meadow',102:'Reach Crimson Lands',103:'Reach Crystal Cavern',104:'Reach Woodland Maze',105:'Reach Temple',106:'Reach Tomb',201:'Merge 3 animals',202:'Lasso 10 Lions',203:'Lasso 3 Kitsunes'},
};
export function mergeTotals(items: (Totals | null)[]): Totals {
  const total: Totals = {};
  for (const item of items) for (const [k, v] of Object.entries(item || {})) {
    total[k] = k.startsWith('max:') ? Math.max(total[k] || 0, v) : (total[k] || 0) + v;
  }
  return total;
}
export function reader(data: Totals, seg: Segment = 'all') {
  const c = (name: string) => data[`${seg}|c:${name}`] || 0;
  const n = (name: string) => data[`${seg}|n:${name}`] || 0;
  const mean = (name: string) => n(name) ? (data[`${seg}|s:${name}`] || 0) / n(name) : null;
  const p = (name: string, percentile: number) => {
    const prefix = `${seg}|h:${name}:`;
    const buckets = Object.entries(data).filter(([k,v]) => k.startsWith(prefix) && v > 0)
      .map(([k,v]) => [Number(k.slice(prefix.length)), v]).filter(([b]) => Number.isFinite(b)).sort((a,b) => a[0]-b[0]);
    const total = buckets.reduce((sum, [,v]) => sum+v, 0);
    if (!total) return null;
    let seen = 0;
    for (const [b,v] of buckets) { seen+=v; if (seen >= percentile*total) return b===0 ? 0.5 : 1.2**(b-0.5); }
    return null;
  };
  return { c, n, mean, p };
}
export const ratio = (n: number, d: number) => d > 0 ? n/d*100 : null;
export const fmt = (n: number | null | undefined, digits=0) => n == null ? '—' : n.toLocaleString('en-US',{maximumFractionDigits:digits});
export const pct = (n: number | null) => n === null ? '—' : `${fmt(n,1)}%`;
export const mins = (n: number | null) => n === null ? '—' : `${fmt(n/60,1)}m`;
export function dateRange(start: string, end: string): string[] {
  if (![start,end].every(v => /^\d{4}-\d{2}-\d{2}$/.test(v) && Number.isFinite(Date.parse(v)) && new Date(v).toISOString().slice(0,10)===v)) throw new Error('Choose valid UTC dates.');
  const count = (Date.parse(end)-Date.parse(start))/86400000+1;
  if (count<1 || count>31) throw new Error('Choose a range of 1–31 days.');
  if (end>new Date().toISOString().slice(0,10)) throw new Error('The end date cannot be in the future.');
  return Array.from({length:count},(_,i)=>new Date(Date.parse(start)+i*86400000).toISOString().slice(0,10));
}
