import { env } from 'cloudflare:workers';
import { getChatGPTUser } from '@/app/chatgpt-auth';
import { dateRange } from '@/lib/metrics';
import { snapshot, UpstreamError } from '@/lib/roblox';

export async function GET(request: Request) {
  const headers={'Cache-Control':'private, no-store'};
  if (!await getChatGPTUser()) return Response.json({error:'Sign in to view this private dashboard.'},{status:401,headers});
  const key=env.ROBLOX_OPEN_CLOUD_API_KEY;
  if(!key) return Response.json({error:'The Roblox connection is not configured yet.',setup:true},{status:503,headers});
  const url=new URL(request.url);
  let dates: string[];
  try {dates=dateRange(url.searchParams.get('start')||'',url.searchParams.get('end')||'');}
  catch(e){return Response.json({error:(e as Error).message},{status:400,headers});}
  try {return Response.json(await snapshot(key,dates),{headers});}
  catch(e){return Response.json({error:e instanceof UpstreamError?e.message:'Unable to load analytics.',setup:false},{status:e instanceof UpstreamError&&[401,403].includes(e.status)?502:503,headers});}
}
