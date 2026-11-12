# Egg Rodeo: moving average playtime from about 10 to 20 minutes

Plan prepared October 13, 2026 from the supplied context and local `stamina-loop` source. The current sample size, metric definition, dashboard date range, and published build have not been verified. These are diagnostic steps and hypotheses, not a finding that onboarding is the cause; no gameplay or analytics code was changed.

An average of 10 minutes can describe two very different problems: many players leaving before the fun while a minority stay a long time, or most players understanding the game and exhausting their reason to continue. First establish which pattern you have. The immediate goal is to find one preventable exit, fix its cause, and measure whether more players continue.

1. **Today: locate when players leave using what already exists.**

   In Creator Hub, inspect **Engagement → New User First Session Retention** at 1, 3, 5, 10, 15, and 20 minutes, alongside the current build's Error Report and client performance. Record the number of new players and the exact metric behind “10 minutes”: average session time and daily playtime per user have different denominators. Use complete reporting days from the same gameplay version, and separate mobile/desktop and sponsored/organic traffic where the available reports and sample sizes support it. Roblox describes the first-session chart as the share of new users still playing each minute. [Roblox engagement documentation](https://create.roblox.com/docs/production/analytics/engagement)

   Your existing [/stats implementation](/Users/william/Documents/local_projects/LassoForEggs/LassoForEggs/src/server/Stats.server.luau:83) already has quit-time bands and version-level averages, so use that for an initial signal. It mixes new and returning players, only includes finished server visits, and records a player's lifetime furthest biome at departure; those biome percentages are not first-session conversion rates. A teleport to World 2 also ends the World 1 server visit. Immediately after publishing, long visits still in progress are missing from the average.

   | Where losses concentrate | What to investigate first |
   |---|---|
   | Before meaningful control / first ride | Loading, intro length, mobile performance, egg placement and mounting clarity |
   | During the first ride | Lasso targeting, apparent freezing during slow motion, return crashes and retry friction |
   | After the first reward | Whether players recognize their new pet and understand their next action |
   | After several successful runs | Repetition, choosing an effective mount, visible progress toward Desert/Snow, and reward pacing |

2. **Before collecting a new baseline: make the measurements trustworthy.**

   The [current Player Journey funnel](/Users/william/Documents/local_projects/LassoForEggs/LassoForEggs/src/server/Funnel.luau:32) combines the tutorial with two independently progressing quest lines and uses the same player-based funnel ID across visits. Roblox automatically fills earlier funnel steps when a later one is logged, so reaching a later quest can imply completion of unrelated earlier quests. Keep independent quest claims as custom events or separate quest-line funnels; don't interpret the current combined journey as a literal ordered history. [Roblox funnel semantics](https://create.roblox.com/docs/production/analytics/funnel-events)

   Two event labels also overstate what happened: [Landed Lasso](/Users/william/Documents/local_projects/LassoForEggs/LassoForEggs/src/client/Tutorial.client.luau:560) fires after either a landing or a three-second timeout, and “Boss Appeared” fires when the five-second countdown is released. Record confirmed outcomes at their actual occurrence. The current “Joined” event happens after profile loading, so it does not expose failures that occur before that point.

   Add one small **First Session v1** funnel, restricted to genuinely new World 1 players during their first visit, with its own session ID and an explicit experiment/build label:

   **New player loaded → tutorial controllable → first ride crossed start → first run reward granted → tutorial finished/control restored → first self-started ride after tutorial → reward from a post-tutorial ride.**

   This answers whether players get through the guided loop and then choose to repeat it. Tutorial retries must not count as the first independent ride. Keep actual egg placement, hatching, confirmed lasso success, and Desert/Snow reach as diagnostic events; don't force optional or independently ordered actions into the main sequence. Track total joins and startup readiness separately so profile-load failures aren't silently excluded.

   For each first-session milestone, record elapsed time from joining. Extend the existing session summary with new/returning status, last gameplay phase, successful run count, failed run count, and furthest biome reached **this visit**. Those few values distinguish “quit confused at base,” “quit after repeated crashes,” and “quit after five similar successful runs.” Treat exit phase as an observation, not the player's stated reason.

   Verify a successful tutorial, a missed lasso, a failed return/retry, and the first independent ride against the events actually received in a published test. Roblox's View Events shows recent events while aggregated charts typically take about 24 hours; Studio alone cannot verify analytics delivery. [Roblox event validation](https://create.roblox.com/docs/production/analytics/event-types)

3. **While data accumulates: watch five people who have never played.**

   Include real phone users. Ask them to play normally, with permission to stop whenever they would naturally stop; don't explain the loop or rescue them unless they are truly blocked. Note when they first control the game, mount, land a lasso, return successfully, choose their next pet, start another run, and stop making progress. Record confusion, errors, crashes, and whether a reward changes their next decision.

   After they stop, ask: “What were you trying to do next?”, “Why did you choose that pet?”, and “What made you stop?” Five observations can expose a reproducible usability problem; they cannot establish a population retention rate. Don't make them stay 20 minutes and then count that as success.

4. **Choose one experiment from the evidence.**

   My first hypothesis to investigate is the transition from the first reward to purposeful repeat runs: the tutorial ends after a gate camera move, [quests start folded](/Users/william/Documents/local_projects/LassoForEggs/LassoForEggs/src/client/BaseUi.client.luau:288), and a new player must connect pet choice to further travel. That is a plausible gap, not a verified cause.

   | Observed problem | Small experiment |
   |---|---|
   | Players abandon before riding | Shorten the demonstrated source of delay; if placement/hatching is the problem, test a ready starter pet |
   | Players miss lassos or repeatedly crash | Change the specific aiming/return difficulty that testers struggle with, then measure first success and retries |
   | Players finish the tutorial but wander or stop | Show one compact next goal and point to the best available pet to attempt it; let them choose to ride |
   | Players do several runs without advancing | Show a reachable distance goal and how their mount choice changes their chances; adjust one demonstrated pacing bottleneck |
   | Players advance easily but say runs feel the same | Test one meaningful choice or reward in the existing run loop, then check whether they voluntarily repeat it |

   A correction to the supplied context matters here: [the local configuration](/Users/william/Documents/local_projects/LassoForEggs/LassoForEggs/src/shared/Config.luau:225) has `Gates = false` and `BreakGates = true`, so local biome barriers do not require pen levels or a purchase. Diagnose travel/progression, not an assumed Desert affordability problem; confirm the published version matches before acting.

5. **Evaluate the specific change, then work toward 20 minutes.**

   Keep the build and acquisition mix stable long enough to collect comparable cohorts. With little traffic, make one change at a time and compare before/after cohorts cautiously; that comparison does not prove causality. Report counts such as “12 of 30 tutorial finishers started another ride,” not percentages alone, and let every player have the full measurement window. A reproducible bug does not need a large sample to justify fixing it; a small percentage improvement does.

   If testing the post-tutorial handoff, use **the share of tutorial finishers who start an independent ride within 90 seconds of regaining control** as the immediate measure; 90 seconds is a consistent experiment window, not a Roblox benchmark. Also track successful post-tutorial returns and the share of all new players still playing at 10 and 20 minutes. If the leak is later, use successful runs and first-session Desert/Snow reach to locate the stalled progression stage instead.

   Finally check the original average on the same definition, plus next-day return when enough data has matured. A rise in average caused by a few long sessions, longer cutscenes, or waiting for gold would not demonstrate that the loop improved. Work toward 20 minutes by showing that more ordinary new players choose more rewarding runs.
