# Analytics V1 spec

## 1. Native Roblox funnels

- **Reset:** stop logging old funnels; preserve historical data and gameplay saves. Prefix replacements with `[V1]`; increment when definitions change, separately from game builds.
- **Shared implementation:** one server-side recorder updates our stored stats and calls `AnalyticsService:LogFunnelStepEvent`; define gameplay triggers once.
- **`[V1] Tutorial`:** new profile loaded → intro finished → starter pet ready → ride crossed start → first animal awarded → tutorial finished/control restored. New World 1 players, first session only.
- **`[V1] First Session Loop`:** new profile loaded → tutorial finished → voluntary ride started → reward received → another ride started → another reward received. First session only; exclude tutorial retries.
- **`[V1] World 1 Biomes`:** first arrival → Meadow → Desert → Tundra → Ocean → Volcano → Jurassic. Enroll first-time World 1 arrivals after V1; continue across visits.
- **`[V1] World 2 Biomes`:** first arrival → Meadow → Crimson Lands → Crystal Cavern → Woodland Maze → Temple → Tomb. Same rules; denominator is first-time World 2 arrivals.
- **`[V1] Quest Claims`:** has unfinished quests → has a claimable quest → claimed ≥1 → claimed ≥2 → claimed ≥3. Once per session/world; include returning players, exclude players with all quests finished.
- **`[V1] Quest Progress`:** quest becomes current/eligible → ready to claim → claimed. One persistent instance per player/world/quest; enroll existing current quests, never backfill past claims.
- **IDs/filters:** session IDs for session funnels; stable player/world or player/world/quest IDs for persistent funnels. Persist once-only progress. Custom fields: entry build, new/returning cohort, world/quest key; use native device filters.
- **Correctness:** run start = crossing start line; reward = server award. Confirm lasso landings and actual boss appearances. Keep optional actions and independent quest lines outside ordered funnels because [Roblox fills skipped steps](https://create.roblox.com/docs/production/analytics/funnel-events#skipped-steps).

## 2. `/stats` and dashboard data

- **Shared data:** both read our own cross-server aggregates, flushed roughly every 60 seconds. Show reporting window, build, last update, and sample counts.
- **Funnel reporting:** all six funnels, observed counts, % of base, conversion between prerequisites, and pending versus completed-session non-completion; include named quest breakdowns.
- **Startup/tutorial:** joins, profile/client readiness, load failures, egg placement/hatching, mounting, lasso opportunity/throw/success, return start, and quest panel opening.
- **Sessions:** one continuous experience visit across both worlds = one session. Report new/returning starts, completed/active sessions, mean/median total playtime, and quit-time bands; label per-world segments separately as place visits.
- **Transfers:** carry a shared session ID and accumulated online duration across every world transfer, including return trips. Confirm destination arrival; resolve failed/abandoned transfers without double-counting, adding offline time, or leaving sessions open forever. Count the completed experience session once.
- **First-session survival:** % still playing at 1/5/10/15/20 minutes, with eligible entrant counts.
- **Runs:** attempts, successes, crashes, successes per session, and retries within 60 seconds of regaining control; separate tutorial/post-tutorial.
- **Exit phase:** startup, tutorial/base, outbound, return, reward cutscene, or post-tutorial base; record observed state, not an assumed quit reason.
- **Pacing:** median/P75 time to first ride, first reward, next voluntary ride, and each biome, with achiever counts.
- **Replay:** % of tutorial finishers starting a voluntary ride within 90 seconds of regaining control.
- **World progression:** first-visit and lifetime biome reach; cumulative online time in that world to reach each biome; World 2 unlocked versus entered, relative to new World 1 entrants.
- **Gold at 1/5/10 minutes:** wallet balance, gameplay gold earned, gold spent, and passive income/second; report P25/P50/P75 and sample counts. Separate purchased gold/paid boosts; exclude test grants.
- **Gold interpretation:** checkpoints cover first-session survivors; show their share of entrants. Missing later samples are not zero. P50 is the median, replacing ambiguous “top/bottom 50th percentile.”
- **Cohorts:** distinguish new/returning, world, entry build/date, and device; exclude Studio/dev/reset tests. World transfers preserve first-session IDs/timers and are not quits.
- **Denominators:** checkpoint cohorts must be old enough for the full observation window; early quitters count as failures. Apply this to survival/retry/replay. Keep active sessions out of completed averages; expire stale heartbeats.
- **Storage:** bounded mergeable histograms for approximate global percentiles; never average server medians. Show N/A for empty samples; make retries idempotent and telemetry failures non-blocking.
- **Verification:** fresh/returning players, finished quests, misses/crashes/retries, repeat successes, transfers/reconnects, early exits, and multi-server totals. Eight minutes in World 1 + twelve in World 2 must produce one twenty-minute session; test failed transfers too. Verify native delivery using published-game [View Events](https://create.roblox.com/docs/production/analytics/event-types#validate-your-event-tracking).
- **Scope:** retain Creator Hub error/performance and D1 reports as supporting evidence; building the dashboard website is separate.
