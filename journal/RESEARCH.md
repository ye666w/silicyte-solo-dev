# silicyte — research map

Not `MAP.md`. `MAP.md` ships with the product and tells an agent which file answers for what;
it deliberately carries no line numbers. This file is the opposite trade: it is local, it is
mine, and it carries anchors, measurements and suspicions — the things that go stale but pay
for themselves while they are fresh.

**Pinned to:** product `main` at `f4341e7`, 22.09.2026. (Was `157de77` for two days after the
file said otherwise — if this line looks old, it is, and so is anything below that cites a number.)
**Lives at** `workspace/journal/RESEARCH.md` — inside the workspace repo, so it is versioned with
the config and the skills and survives every restart and every clear. It sits under `journal/`
rather than beside `fleet.config.ts` for a blunt reason: that is the only place in the workspace a
session is permitted to write, and a reference nobody may update rots.
If an anchor finds nothing, the section is stale — say so rather than guessing at what replaced it.

**The anchor in `«»` is the address. There are no line numbers beside it any more, and that is
deliberate.** This file carried both for a while; on 20.09.2026 every one of its numbers went
stale twice in the same afternoon — 11 of 11, then 12 of 12, a few hours apart — because
`supervisor.ts` is edited constantly and every edit moves everything below it. The grep string
never moved once. Carrying a number beside it bought nothing and created a chore that had to be
done again by the evening, so the number is gone: `grep -n` the anchor and the line is yours,
current by construction.

A few bare numbers survive below in prose. Treat every one of them as approximate, and if it
disagrees with reality believe the file.

## Read this much before your first edit, and the rest when you have a question

This file is long because it accretes. **That is its failure mode, not its virtue.** On 22.09.2026
a session re-derived a measurement three sections below say "do not re-derive", and found three
sections describing defects that had already been fixed — because it went looking *after* it
started, not before. What follows is the short list that pays for itself every time.

1. **Rails move only on `fleet_restart` with `updateRails: true`.** Landing is not running, and
   the gap is not visible from the branch. Measure it against the source, never against memory —
   grep a marker of the fix in `silicyte-solo-dev/src/` *and* in `git -C silicyte grep <marker>
   origin/main`. → *The three checkouts*, *Where the rails come from*.
2. **Chain gates with `&&`, never `;`.** And `npm test | tail` reports **tail's** exit status, not
   the suite's. Both have shipped a red suite as green. → *A pipe eats the exit status*.
3. **`$TMPDIR`, never `/tmp`.** The write guard reads your command *text*, so a grep whose pattern
   merely contains a protected path is refused too. Rephrase; do not argue.
   → *The write guard, and what it cannot see*.
4. **`supervisor.ts` is large and not tangled. Do not propose splitting it.** The measurement is
   done, twice, and it says there is no seam. → *`supervisor.ts` is large and not tangled*.
5. **Mutation is the discipline, not reading.** Commit, change one thing in `src/`, re-run,
   restore. A suite still green is a hole, and re-reading the code finds almost none of them.
   → *The fifth worker task*, *The three shapes of an untested boundary*.
6. **A difference between two code paths is not a defect until you can name who it hurts.** Carry
   the scenario forward to a person reading or doing the wrong thing. If the sentence will not
   finish, you found the design. → *Смерть сессии бывает двух сортов*.
7. **Compaction: keep the instruction on one line and well under 3 KB**, and check `self_context`
   afterwards — nothing confirms it ran. → *Compaction: the CLI never reports a cancellation*.
8. **The network is open; `~/.ssh` is not.** Landing goes through `fleet_land` and needs no key.
   → *The network, measured 2026-09-21*.

### This file has no test, and `MAP.md` does

`tests/map-is-true.test.ts` fails if a source or test file is missing from `MAP.md`, in both
directions, so that file is true by construction. **Nothing guards this one.** It is true only for
as long as somebody keeps it so, and the evidence above is that for two days nobody did.

So two duties come with writing here, and they are the whole of the discipline:

- **Every claim carries its evidence** — a commit hash, a grep string, or the measurement and the
  date. A claim with neither cannot be checked and will outlive its truth.
- **A fixed thing is never deleted.** It gets a line saying which commit fixed it and stays where
  it is. The list of what was once wrong is the most reusable part of this file — but only while
  it is honest about which entries are past tense.

## The three checkouts

    /Users/photon/projects/silicyte/silicyte              product. `main` is what ships. A git repo.
    /Users/photon/projects/silicyte/silicyte-solo-dev     fork. THIS fleet runs here, on ITS src/.
    /Users/photon/projects/silicyte/silicyte-dev-team     fork. The older nine-role team fleet.

All three are clones of `ye666w/silicyte`. **Only one fleet may run at a time** — both forks cut
worktrees from the same product checkout and push to the same `main`.

A fork's `src/` is **the rails** — the code its supervisor is actually executing. Its
`workspace/` is a **separate git repo with its own remote**, holding `fleet.config.ts`, the
`skills/`, `journal/` and this file. `.gitignore` in the fork ignores `/workspace/`, which is why
the two histories never collide.

This fleet: `root` (Opus 5, max) owning six `worker`s (Haiku, high), `maxSessions: 7`, rails from
`origin/main`. The team fleet's nine roles are the previous design and its
`workspace/skills/` is still worth reading — most of what is written there was paid for.

Consequences worth holding:

- Reading the product tells you what `main` says. Reading the fork's `src/` tells you what the
  fleet **actually ran**. When a log does not match the code, check which one you read.
- A fork's `src/` moves only on `fleet_restart` with `updateRails: true`, which does
  `git pull <railsFrom>`, runs test/typecheck/lint, and rolls back if any goes red.
  `railsFrom` is `origin/main` here, `upstream/main` in the team fork.
  → `src/self-restart.ts` `«class Rails»` `«whatFailsOnThem»`
- The product checkout goes stale silently. Nobody in the fleet may write to it (by design,
  card #24). It has been found 13, 15 and 17 commits behind. **Check `git -C … log --oneline -1`
  against the fork before concluding anything about current behaviour.**
- Directories here have been renamed under a live session. If a path 404s, re-locate it before
  concluding anything was lost.

## The 60-second model

One Node process (`src/start.ts`) holds a `Supervisor`. The Supervisor owns N Claude Code CLI
sessions, each a separate ~270 MB process reached through the Agent SDK's `query()`. Every
session gets its own git worktree, its own branch `silicyte/<sid>`, its own MCP server minted
for exactly its authority, and a briefing assembled from its role profile. Messages from a
session are `SDKMessage`s; `bus.ts` translates them into a `FleetEvent` union; everything else
in the system is a reaction to that union. A web panel on `:4173` reads the same bus over SSE.

**This fleet is two roles, not nine.** `maxSessions: 7`.

    root (Opus 5, max)  →  worker × 6 (Haiku, high)

`root` is the root (`reportsTo: null`), holds every verb over its workers, and is the only
session that may reach the operator or restart the fleet. A worker grants no authority onward,
so the tree is exactly two deep. Memory is not the binding constraint here that it was at nine.

The nine-role shape below is the **previous** design, kept because the product still supports it
and because `silicyte-dev-team`'s `workspace/skills/` is worth reading. It is not what is
running:

    manager  →  docs, reflector, dev          manager was the root
    dev      →  back, front                   only manager and reflector could ask the operator
    back     →  researcher, review, tester    dev could neither close a session nor ask
    front    →  researcher, review, tester

## The spine: how a session is born, lives and dies

All in `src/supervisor.ts` unless noted. It is the whole product's centre of mass and by some
way its largest file; `wc -l` it rather than trusting a number written here.

    spawn()                       «async spawn(req: SpawnRequest»
      refuses while the limit holds the fleet       «this.theLimit.holdsTheFleet()»
      refuses if the machine is already full         «>= this.sessionCap»
      refuses if refusalIfTheRoleIsFull             «refusalIfTheRoleIsFull(role: string)»
      worktrees.create → branch silicyte/<sid>       «this.worktrees.create(sid»
      registry.add, then launchProcess               «rec.handle = this.launchProcess(»
      drainIntoBus (fire and forget)                «void this.drainIntoBus»

    launchProcess()               «private launchProcess»
      assembles: skill + briefing + mcpServers + disallowedTools + sandbox

    drainIntoBus()                «for await (const msg of rec.handle!.query)»
      the ONLY place SDK messages enter. finally: advances the spend baseline.
      Ordering is load-bearing and now tested — `55ac66d`, tests/spending-survives.test.ts.

    react(e)                     «private react(e: FleetEvent)»
      the single switch every event passes through. Read this before theorising
      about what happens after anything.

    routeReportToItsReader()     «private routeReportToItsReader»
      fires on EVERY result, unconditionally. An agent cannot choose not to report.
      Any skill rule saying "do not send interim reports" is unenforceable.
      The header it writes is what the reader above reacts to, and until `f19a2f8`
      it had two words for three things: a turn cut short arrived as `failure`,
      because `ok` is false, and readers restarted work that had been stopped on
      purpose. A turn now carries `cutShortOnPurpose: { by, because }` from the
      point it is marked; `by` is `theOperator`, `aSessionAbove` or `theFleetItself`
      and `howThatReads` switches over the three with no default. The operator and
      a session are deliberately worded apart: a session that stopped one of its
      own will say what happens next, a human may simply have wanted it stopped.

    park / unpark                 «private async park»
      idle → process stopped, memory freed, transcript kept. parkAfterIdleSeconds: 90.

    clear()                      «async clear(sid»
      the one thing that throws a conversation away. Refuses a quarantined session by name.

    kill / closeOne               «private async closeOne»

Death paths that are not closing on purpose, each greppable by its own name:
`recoverFromFailedTurn`, `reportUnexpectedDeath`, `recoverManager`, `halt`, `freezeEntireFleet`,
`quarantineForIncident`.
`freezeEntireFleet` splits into `claimEverythingForFreezing` (synchronous, sets the statuses)
and `interruptWhatWasClaimed` (awaits the IPC interrupts) — `af2b817` split them because `spawn()`
gates on a set that was only filled after the await, leaving a window where a session could still
be started into a freeze it would never be released from.

## Where state lives on disk

Everything persistent is under `<fork>/.silicyte/`. This is the first place to look for
"what did the fleet think was true".

    registry.json              who exists, role, reportsTo, status, tokens, branch, cwd
    spending.json              the token ledger; survives fleet_restart
    operator-questions.json    questions waiting on the human, and their answers
    timings.json               the four tunables (see below)
    connectors.json            which MCP connectors answered
    integrations.json          Slack/Telegram — mode 600, HOLDS A LIVE TELEGRAM BOT TOKEN.
                               Never paste values anywhere. Key names only.
    activity.log               human-readable, written by ActivityLog from the bus
    panel/activity.jsonl       what the panel replays after a reload
    panel/<sid>.transcript.jsonl   per-session transcript the panel restores
    worktrees/                 one git worktree per live session
    restarting.json            the restart intent, read once on the way back up
    fleet.log                  NOT written by the product — the operator's stdout redirect

Written by: `registry.ts:150`, `spending.ts:126`, `operator-questions.ts:208`, `timings.ts:46`,
`connectors.ts:56`, `integrations.ts:44`, `self-restart.ts:68`, `web/panel-memory.ts:33`.
Protected from every agent by `write-guard.ts:16-20` `«ORCHESTRATOR_OWN_FILES»`.

Archived snapshots follow the pattern `<name>.before-the-<n>th-start.json`. Those are mine,
made by hand at each reset — not a product feature. They are the only record of what a previous
run believed, and several diagnoses have come out of diffing them.

Workspace side, `<fork>/workspace/`:

    fleet.config.ts            nine roles, models, authority, caps
    skills/<role>/SKILL.md     what each role is told it is
    skills/<role>/references/  what that role should simply know
    supervisor-messages.json   the three things the supervisor says: rootFirstTask,
                               rootResumed, idleNudge  «SupervisorMessageKey»
    journal/YYYY-MM-DD.md      the manager's daily journal
    journal/lessons/<role>.md  written by roles, read and EMPTIED by reflector
    journal/docs/<role>/       optional artefacts; nothing processes or empties this
    journal/scratch/           cleared at every restart

CLI transcripts live outside both checkouts, in `~/.claude/projects/<mangled-cwd>/<uuid>.jsonl`.
That is where a session's real conversation is. **Before deleting any of them, assert my own
session ids are not in the set.**

## The event vocabulary

`FleetEvent` in `src/types.ts:175` `«export type FleetEvent»` — 30 variants. This union is the
best single index of "what can happen in this system". Reading it beats reading prose.

Produced in exactly one place: `bus.ts:66` `«ingest(sid: string, msg: SDKMessage)»`. That
function is the entire translation surface between the SDK and this product — **every question
of the form "does the fleet notice X?" is answered there in about forty lines.** If a field
is not read in `ingest`, nothing downstream can know it. That was the whole of card #54
(`msg.tools` was discarded; now `toolsOfferedByCli: msg.tools ?? []` at `bus.ts:125`).

SDK message types handled: `assistant`, `result`, `rate_limit_event`, and `system` with
subtypes `init`, `status`, `background_tasks_changed`, `compact_boundary`,
`model_refusal_fallback`, `model_refusal_no_fallback`. Everything else falls through `return`.

## Authority

Structural, not prompt-based. Three things compose:

1. **`SessionAuthority`** (`types.ts:35`) = `{ mayOwnRoles, maxOwnedAtOnce, maxTreeDepth, verbs }`.
   `SessionVerb` = read | interrupt | send | retune | kill | clear.
2. **`WhatTheSessionMayDo`** (`fleet-mcp.ts:11`) = the four booleans/lists that are not verbs:
   `mayReachTheOperator`, `sculptableSkills`, `mayRestartTheFleet`, `maySeeAccountLimits`.
3. **`mintFleetServerBoundTo(sid, authority, registry, api, granted)`** (`fleet-mcp.ts:18`)
   builds an MCP server holding only the tools that authority earns. A session is not told
   not to use a tool — the tool is not there.

Eighteen tools, in five groups:

    subtree   (needs a SessionAuthority)  fleet_list fleet_request fleet_transcript
                                          fleet_interrupt fleet_send fleet_retune
                                          fleet_kill fleet_compact fleet_clear
                                          fleet_reload_skills
    operator  (mayReachTheOperator)       ask_operator close_operator_question
    rails     (mayRestartTheFleet)        fleet_restart
    skills    (sculptableSkills.length)   apply_skill_changes
    always                                self_context self_compact self_clear
                                          + account_limits if maySeeAccountLimits

Separately, `disallowedToolsFor(profile, isHumanEntryPoint)` (`supervisor.ts:122`) removes
`TOOLS_THAT_REACH_AGENTS_OUTSIDE_THE_REGISTRY = ['Agent', 'Task', 'SendMessage']` from every
session including the root, plus `AskUserQuestion` from everything that is not the root.
Held by `tests/blocked-tools.test.ts`, which is written to go red if an SDK update renames
or adds one.

## The write guard, and what it cannot see

`src/write-guard.ts`, 559 lines, the second-hairiest file here. It is a **Bash PreToolUse
hook plus a path check on the file-writing tools**. It reads command *text*.

It handles, genuinely: redirects and `tee` `«REDIRECTED_INTO»`, verbs that write every path
`«VERBS_THAT_WRITE_EVERY_PATH_THEY_NAME»`, verbs that write their last path
`«VERBS_THAT_WRITE_THEIR_LAST_PATH»`, flag-pointed targets, `cd`-tracking across up to 16
chained pieces `«WHERE_ONE_COMMAND_MIGHT_STAND»`, quote state across pieces
`«piecesThatAreOnlyPartOfAQuote»`, alias/function redefinition `«anyNameIsBeingReassigned»`,
and `git` by subcommand and `-C`/`--git-dir` target `«whatAGitCommandWouldRewrite»`.

It is blind to, by construction:

- **The `Read` tool.** It is a write guard. It has nothing to say about reading
  `.silicyte/integrations.json`. That gap is card #53.
- **The network.** `curl`ing a secret out is not a write.
- **Interpreters.** `PROGRAMS_THIS_GUARD_CANNOT_FOLLOW` is a 60-entry deny-list — it refuses
  rather than reasons. A program not on that list and not on
  `PROGRAMS_THIS_GUARD_JUDGES_BY_ITSELF` (`git`, `echo`, `printf`) is a hole.
- **Runtime-assembled paths**, anything behind `$` or backticks `«A_TARGET_THIS_CANNOT_WORK_OUT»`.

README's "Honest limitations" states this as intentional and points at the OS-level
`allowWrite` sandbox as the real fix. Do not file it again as news.

**Do not poke at this one blindly — it is the best-tested thing in the repo.**
`tests/write-guard.test.ts` is 1026 lines, the largest test file by a factor of two, and it
covers the cases that look like holes. The single-argument forms, for instance: `uniq FILE`
reads and prints, and `whatOnePieceWritesInto` (`:92`, the rule itself at `:101`) guards the last-path rule with
`args.length > 1` precisely so that `uniq ${RAILS_FILE}` is allowed and
`uniq /tmp/x ${RAILS_FILE}` is denied — both asserted, at test lines 802 and 829. Alias and
shell-function redefinition, `awk` redirects inside a program string, `sed --in-place`,
`find -delete`, `find -fprintf`, `sort -o`: all covered. **Grep the test file before filing
anything about the write guard.** The real gaps are the four structural ones above, which the
tests do not pretend to close.

## Money

**97–99% of every session's tokens are `cacheRead`.** Price is driven by *how many times a
session is woken and on what context length*, not by output volume. This inverts most
intuitions about what is expensive.

    cacheRead  Opus $1.50/M   Sonnet $0.30/M   Haiku $0.10/M

Measured on this fleet: one card on a session that started clean = 3.1M tokens. Cards taken
one after another on a context nobody compacted = 11.9M average. **Compaction at hand-over is
the single biggest lever**, which is why it moved from `dev` into `back`/`front`'s own skills.

The longest skill is ~3,470 tokens ≈ under $1 across a whole night of the most expensive
session — under 1% of that session's bill. **"Skills are too long, length is money" is wrong by
two orders of magnitude.** It was removed from reflector's skill. The inversion that matters:
a `references/` file that *is* read costs more than the same text in the skill, because it is
read as a tool call on top of a context that already holds the skill.

Two accounting surfaces that do not sum, and confusing them has cost an hour:

    spentSinceThisFleetWasFirstStarted  :200  the ledger, includes ended sessions
    spendingRanking()                         reads registry.all(), live rows only

## Rate limits and the stop

    stopFleetAtFiveHourPercent: 85
    stopFleetAtWeeklyPercent:   90

    stopTheFleetIfALimitSaysSo()    «private async stopTheFleetIfALimitSaysSo»
    the hold itself now lives in `src/limit-hold.ts` (68cc3cd): how long, why, what it said,
    whether the operator is spending the window out, how long nothing is nudged. The five
    fields that used to sit on the supervisor are gone from it.
    letTheFleetBackWhenTheLimitResets()  :1453
    releaseOnlyWhatTheLimitFroze()       :1459
    holdOffUntilTheLimitLifts()          :1468

One `{kind:'rateLimit'}` event with `status:'rejected'` raises **two different delays**, and
they are easy to read as one. `holdOffUntilTheLimitLifts` sets `nothingIsNudgedUntil` — the
fleet stops being poked, nothing is frozen. `stopTheFleetIfALimitSaysSo` sets `holdsUntil` —
the fleet is actually stopped. Different fields on `TheLimitOnTheFleet`, different questions
(`nothingIsNudgedYet()` vs `holdsTheFleet()`), and only the first is set synchronously; the
second happens inside an async call the case does not await. Both take
`max(now + QUIET_WHILE_RATE_LIMITED_MS, resetsAt)`, so the account's own reset wins whenever it
is further out than five minutes. Joined by a test in `ac1f0cf` — until then the refusal branch
had never run in any test, because the only bus-level case carried an allowed snapshot at 88%.

Two readings are merged field by field in `rate-limits.ts:85` `«everythingEitherReadingKnows»`.
Card #52 was exactly this: a percentage measured in one window was carried onto the next. Fixed
in `ad56613` by `«theWindowItMeasuredHasSinceRolledOver»`, which compares how far the boundary
moved against how much time passed. **Verified present at pin.**

**How wide the freeze actually is — measured**, by `tester-f04c8a2e` on the previous fleet,
`performance.now()` either side of `await freezeEntireFleet`, one real Haiku session, stand
adapted from `src/demo/guardian-drill.ts`:

    mid-turn    13.5 ms   9.8 ms   9.7 ms      unreadByCliDropped=1
    idle         1.3 ms  115.9 ms  1.1 ms      unreadByCliDropped=0

Treat **10 ms as the resting width and the tail as unbounded** — the 115.9 ms outlier is an IPC
round-trip to a process whose scheduling this machine's memory pressure owns, and nothing in
silicyte bounds it. One session is a floor, not the answer: `interruptWhatWasClaimed` is
`Promise.all` over every live session, so the real width is the slowest of N. Nobody has measured
N > 1. Full method in `silicyte-dev-team`'s workspace repo,
`journal/docs/back/how-wide-the-freeze-window-is.md` (pushed to `ye666w/silicyte-dev-team`; the
checkout itself is gone).

**The guard principle that came out of it, and it generalises past this file:** a guard that keys
on the *byproduct* an operation fills in is open for exactly as long as the operation takes. That
was `af2b817`. `halt()` is the pattern with no window — it sets `haltRequiringHuman` synchronously
and every reader keys on that. When adding state a guard reads, ask whether it is set by the
**decision** or by the **work the decision causes**. Only the first is safe to guard on.

**Closed by `1f9dbac`, and the operator's ruling behind it is the durable part.** `spawn()` used
to key on `frozenByTheLimit.size`, the set an async freeze fills in, which is empty in two
different situations — when there was nothing left to freeze (everything already `frozen` after a
Stop or an incident) and after a Resume cleared it. Either way spawn was open for the whole hold,
up to five hours, against the 10 ms window `af2b817` closed. Both now key on
`theLimitHoldsTheFleetUntil`, the synchronous decision. So does `applyVerdict`.

**The ruling: a stop for our own ceiling and a stop because the account is out are different
stops, and Resume means different things in each.**

  **Our own ceiling** (`stopFleetAtFiveHourPercent` / `stopFleetAtWeeklyPercent`). Resume is the
  operator deciding to spend the rest of the window. The deadline is cleared and
  `spendingThisWindowOutUntil` holds the ceiling off until that window rolls over. Deliberately
  **not** a re-arm — re-arming trips again within seconds and makes the button a lie. The ceiling
  comes back with the next window.
  **The account itself refused.** Resume cannot help; the API refuses whoever asks. The deadline
  is kept, nothing is unfrozen, and the fleet wakes itself at the reset via
  `letTheFleetBackWhenTheLimitResets`. The operator is told when that is.

Telling them apart needed `theAccountItselfRefused` in `rate-limits.ts`: `limitsTellingTheFleetToStop`
only ever compared percentages, so an account that refused outright stopped the fleet only
incidentally, when a configured threshold happened to trip on the same window. It is scoped to
`WINDOWS_COVERING_THE_WHOLE_ACCOUNT` so an exhausted `model_scoped:` limit does not stop a fleet
that is not on that model.

One bound worth knowing before reasoning about the override: `stopTheFleetIfALimitSaysSo` floors
every hold at `QUIET_WHILE_RATE_LIMITED_MS` (5 min), so `spendingThisWindowOutUntil` inherits that
floor — a Resume near the end of a window keeps the ceiling off for five minutes into the next
one. Bounded and deliberate, not a leak.

The test that guards the first half is `tests/stop-at-the-limit.test.ts:261`, and it uses the
cheap-refusal trick: `spawn({role: 'nobody-declared-this'})` answers "close to its limit" while
the guard is shut and "is not declared in the config" once it opens, with no process ever started.
It goes red on the guard change alone and green again once Resume clears the deadline — which is
how the intermediate state was caught rather than shipped.

## The four tunables

`src/timings.ts`. Bounds are enforced, out-of-range values are clamped, not rejected.

    parkAfterIdleSeconds     90    20 .. 86400   0 allowed (off)
    nudgeAfterQuietSeconds   30    15 .. 86400   0 allowed (off)
    compactAtPercent         75    40 .. 95      0 NOT allowed
    guardianVerdictSeconds  420    60 .. 3600    0 NOT allowed

## How to research this cheaply

**The test suite is the harness.** Tests build a real `Registry` on a `mkdtempSync` path, a
fake `FleetApi` cast `as unknown as FleetApi`, and call `mintFleetServerBoundTo`. No model, no
money, no fleet. `tests/one-per-role.test.ts:20-58` is the cleanest template; `tests/grants.ts`
gives `NOTHING_GRANTED` and `granted({…})`.

Calling a tool directly, from `one-per-role.test.ts:68`:

    const registered = (server.instance as unknown as { _registeredTools: Registered })._registeredTools;
    const answered = await registered[name].handler({ …args }, {});

**Stands, by cost:**

    npm run demo:blocked-tools   ONE real session. Spends. Proof a refusal is the CLI's.
    npm run watch                THREE real sessions, cheap model, tight budgets. Spends.
    npm run demo:guardian        ONE real session + synthetic refusal. Spends.
    src/demo/panel-stand.ts      fake supervisor, NO model. Free.
    src/demo/trouble-stand.ts    every failure state on one page. Free.

**Two refusals in one function test an ordering without paying for the happy path.** `spawn()`
checks the limit *before* it looks the role up, so `spawn({role: 'not-declared'})` answers "close
to its limit" while the guard is shut and "is not declared in the config" once it opens — a
red/green signal with no process ever started. Read a function for a cheap existing refusal before
building a fixture to drive the expensive one.

**A session with no prompt costs nothing and still answers control requests.** That is the
instrument for any "does the SDK actually do X" question — see the researcher role's
`references/probing.md`. Two rules learned expensively: do not wait for `init` in a directory
the CLI has not onboarded (it never arrives — poll with a deadline), and do not read a status
once (servers say `pending` for the first seconds).

**Reading what happened:** `.silicyte/activity.log` for the human narrative,
`.silicyte/fleet.log` for the supervisor's own console, `.silicyte/panel/*.transcript.jsonl`
for what the panel kept, `~/.claude/projects/…/*.jsonl` for the real conversation.
`git log --oneline` in the fork's `workspace/` for what the fleet changed about itself.

    npm test        writes to a file and check $? — NOT `| tail`, that reports tail's code
    npm run lint
    npm run typecheck
    npm run doctor

## Reported in the second pass, not yet checked

Findings from six workers reading the files this map had never anchored, 2026-09-20 at `55ac66d`.
**None of these has been verified by anyone.** Half of the batch they came in with did not
survive checking, and two were wrong in the direction that would have caused a worse defect if
"fixed". Treat every line here as a lead, not a fact. Check first.

- ~~`close_operator_question` and `ask_operator`'s `continues` took a task id on trust~~ — FIXED
  in `608e404`. The asker is a required argument now rather than an optional check, a task that
  is not yours is refused in the same words as one that does not exist so ids cannot be probed,
  and a `continues` naming someone else's thread opens a task of its own. It was unreachable in a
  fleet where one session may reach the operator, which is why it survived; a second role with
  `mayAskTheOperator` is a config line, not a code change.
- ~~`incident.ts:104,111` — the incident latch is never released when the investigation ends in a
  halt~~ — real, FIXED in `ba15b28`, **and the reported fix was the wrong one.** Keeping the latch
  through a halt is deliberate and already covered: a second classifier refusal must not start a
  second guardian on top of a halted fleet, and `tests/guardian-reserve.test.ts` says so. I wrote
  the suggested `finally` and that test caught me. The actual gap is that `closeIncident` had no
  caller anywhere outside the handler's own happy path, and `resumeEverything` — which clears the
  halt, the limit freeze and the root's trouble history — left this one latched. So the operator
  resumes, everything looks recovered, and the classifier-refusal path is dead until the process
  restarts, with no symptom but silence. Resuming now closes it. **A latch that is right to hold
  still needs somebody whose job is to let go.**
- `worktree.ts:82` — `git worktree add -b` against a branch that already exists fails, and
  `removeKeepingBranch` keeps branches on purpose. Structurally true; **I could not construct the
  path that reaches it**, since sids are not reused and the crash path does not remove worktrees.
  Left alone rather than hardened on a hunch. If a session ever refuses to start with a branch
  error, this is the line.
- `worktree.ts:95` — `--force` discards uncommitted work, and it is reached from `closeOne`, which
  is a deliberate close. The README says closing on purpose cascades; the flag is the decision,
  not a bug. The crash path does not call it.
- ~~`operator-questions.ts:179` — a malformed state file drops every question in silence~~ —
  real, FIXED in `fd28608`. The write path had said so since `157de77`; the read path had not, and
  a session that filed a blocking task waits for an answer nobody is coming to give.
- ~~`verdict.ts:21` — candidates tried newest-first~~ — CHECKED, sound. The reverse is the
  deliberate "the last thing it said is its conclusion", and `readVerdict` refuses anything
  without a non-empty `negativeConstraintDescription`, so a truncated or incidental object does
  not get through. Left alone.
- ~~`push-stream.ts` — two concurrent consumers share one waiting-reader queue~~ — CHECKED,
  unreachable. One is made per session at `launchProcess` and handed to `query({ prompt: input })`;
  there is no second `for await` over it anywhere. True of the code and not worth defending.
- `fleet_reload_skills` has no verb check where its neighbours do (`fleet-mcp.ts:246`). It *does*
  check the subtree. Verified as a consistency point with no consequence.

## The network, measured 2026-09-21 — the sandbox does not close it

**`theSandboxASessionRunsIn` sets no network settings at all.** It builds `filesystem.allowWrite`
and `filesystem.denyRead` and stops. The single role with a network setting anywhere in `src/` is
Guardian: `guardian.ts:9` `NO_NETWORK_AT_ALL = { strictAllowlist: true, allowedDomains: [] }`.
Every other role inherits the harness default. What that default actually permits, tried from
inside a sandboxed session rather than reasoned about:

    curl https://example.com               200
    curl https://api.github.com            200
    curl https://registry.npmjs.org/...    200
    git ls-remote https://github.com/...   returns a real sha
    python socket.gethostbyname('pypi.org')  gaierror — no DNS from a raw socket
    git ls-remote git@github.com:...       reaches the proxy, refused: "this proxy requires
                                           authentication, and this client did not offer an
                                           authentication method"

So: **HTTP and HTTPS go out; nothing that is not HTTP does.** Egress is a proxy on `localhost`
(`HTTP_PROXY`, `ALL_PROXY`, `GRPC_PROXY`, `FTP_PROXY` as socks5h, and `GIT_SSH_COMMAND` with an
`nc -X 5` ProxyCommand). A bare `ssh` on the command line does **not** use `GIT_SSH_COMMAND` —
only git does, so testing ssh with `ssh -T` measures nothing. That mistake was made here first.

**`npm` still fails, and not for a network reason.** The registry answers, but the npm cache
(`~/.npm/_cacache`) is outside `allowWrite`, and npm reports the denial as *"your cache folder
contains root-owned files… run `sudo chown`"*. That is a false trail; nothing is wrong with the
cache. Only `~/.npm/_logs` is writable.

**The security shape, stated plainly.** A session that can reach HTTPS can send to anywhere it can
reach. What keeps a credential in is `denyRead` on the file it lives in — `~/.ssh` and
`.silicyte/integrations.json` — not the absence of a way out. `fleet_land` is still necessary, but
because there is no readable key, not because ssh cannot cross.

Corrected in `889a1f5` (README), and in both skills, which had said "there is no network" and told
workers that `npm install` fails for that reason.

**Asked and settled for this installation (`0de93a74`): the network stays open.** Egress is needed,
and the cost of closing it is that no session could ever pull a dependency again — irreversible in
a way the broken npm cache is not. So `theSandboxASessionRunsIn` leaving `network` unset is the
state somebody chose, not one nobody looked at. **Do not "harden" it.** The README states the
choice because it belongs to whoever deploys this; this line states which way it went here.

## The sandbox, as of `59605a2`

    src/sandbox.ts          «export function theSandboxASessionRunsIn»
      enabled, failIfUnavailable  a sandbox that quietly did not apply would be worse
                                  than none, because nobody would know
      allowUnsandboxedCommands: FALSE since `365a312`. A session cannot mark a command
                                as stepping outside; the parameter is inert, and the
                                session's own sandbox description says so.
      filesystem.allowWrite   built from the same WhereASessionWorks the write guard is
                              given, and NOT the same list — this was stated backwards here,
                              in MAP.md and in the root skill until 2026-09-22. It adds each
                              shared checkout's `.git`, the workspace's `.git` and `tmpdir()`.
                              `write-guard.ts` does not import `sandbox.ts` at all. Three of
                              the gaps found that day live in exactly that difference
      network                 undefined. A session is handed nothing of its own. What
                              is left is whatever the CLI itself needs.

    Writes are closed. READS ARE NOT — `denyOnly` of three paths, so a session reads the
    whole machine. That is Trello #57, and it is deliberately not the same job as writes:
    a missing write fails loudly with "Operation not permitted", a missing read returns
    emptiness three levels down and looks like a bug in something else.

    Measured from inside, after the flag came down:
      git ls-remote origin, WITH dangerouslyDisableSandbox: true   refused by the proxy
      curl https://github.com                                      still passes
    So the remaining reach is HTTP through the CLI's own allowance. Narrowing that needs
    `strictAllowlist`, and nobody has established whether web tools and MCP connectors
    run through the same box. Measure before touching it.

## Where the rails come from

`fleet_restart` with `updateRails` pulls from `config.railsFrom?.remote ?? 'upstream'` and
`?.branch ?? 'main'` (`supervisor.ts:728`). **The default is a remote nothing creates.** This
installation works because `workspace/fleet.config.ts:23` sets
`railsFrom: { remote: 'origin', branch: 'main' }` — the fork is the only copy here, so `origin` is
the upstream. `npm run sync` is hardcoded to `upstream` and has no such override, so on this
machine it fails. Documented in the readme as of `9a90c75`.

## Landing

    src/landing.ts          «export class LandsWorkOnTheMainBranch»
      fetch()   the supervisor's, in the SHARED checkout. Every worktree of that
                repository sees it: they share one object store and one set of refs.
      land()    refuses unless the branch already contains the remote main
                                «does not contain ${upstream}»
                so a conflict is never the supervisor's; it goes back to the session
                with the reason, and the refusal doubles as the fetch.
      the injected RanCommand is what makes all of it testable without a remote.

    supervisor.landTheWorkOf(sid, repo?)    «private whereThatWouldLand»
      repo left out  → the session's own branch, silicyte/<sid>, in config.repos[0]
      repo 'journal' → the workspace repository, branch HEAD; no session has a branch
                       there, and without this a closed sandbox would leave sessions
                       able to ship code and unable to write down what they learned.

    the tool takes NO session id — it lands the caller's branch and nothing else.

    All three states exercised against the real remote on 2026-09-20, not only against
    the injected runner:
      a branch on top of main          landed, five times, code and journal
      a branch main has moved past     refused, naming the rebase — and the refusal had
                                       just fetched, so the rebase it asks for is possible
                                       without any network in the session
      a branch level with main         refused as holding nothing
    The recovery loop closes: refuse, rebase, land. That is what makes a session with no
    network able to get current by itself, and it is the whole argument for the design.

## Checked in the third pass and found sound — do not re-derive these

Ten findings, one real (`7acf0e8`). The other nine are written down so nobody spends an hour
rediscovering them, because four of them read as plausible defects and one carried a fix that
would have caused a real one.

    root-trouble.ts   wentWell() clears the failure chain, and it is called ONLY under
                      «e.sid === this.humanEntryPointSid». A worker succeeding does not
                      reset the root's chain. Not a defect.
    session-state.ts  ALSO_ENDS is not inverted. Process ⊂ conversation ⊂ session, so a
                      session ending forgets all three lifetimes. "Forget only its own"
                      would recreate the first defect of 2026-09-20. Not a defect.
    spending.ts       recordTotalFor has one caller, noteWhatItSpent, which applies
                      theHigherReading before calling it. The guard is upstream by
                      construction. Not a defect.
    registry.ts       setStatus('stopped') calls persist(), and persist() writes live()
                      — already filtered. The row is removed from disk, not kept.
    workspace.ts      the three mirror read/write races are real in principle. The cost of
                      a lock is higher than a transient ENOENT on a skill file, and
                      apply_skill_changes restarts the affected sessions anyway.
    config-file.ts    the Date.now() cache-buster could collide inside one millisecond.
                      Reachable only by two config loads in the same tick; consequence is
                      one stale read.

## The outer ring: everything the spine section does not cover

Read 2026-09-20 at `55ac66d`-`fd28608`, all of it verified by hand rather than taken from a
report. Grep strings, not line numbers.

    bus.ts
      ingest(sid, msg)            «ingest(sid: string, msg: SDKMessage)»
        sid is a PARAMETER the supervisor passes, never read off the message.
        Dispatches on msg.type, then on subtype for type === 'system'.
      emit()                      «for (const fn of this.listeners)»
        already guards a listener that throws. History bounded since `c9a5c7d`.
      toPercent / toMilliseconds  «A_READING_THIS_SMALL_COULD_BE_EITHER_UNIT»
        these normalise the EVENT-side fields, which the SDK does not document.
        The usage-API fields in rate-limits.ts are documented 0-100 and read raw.
        The two are different APIs. Do not harmonise them. Tests say why.

    web/server.ts
      listens on the loopback address only        «this.http.listen(this.port, '127.0.0.1'»
      and has NO authentication of any kind. Anything on the machine can call it.
      the only consumer of bus.history()          «MAX_REPLAYED_EVENTS_PER_SESSION»
        takes the last 120 for one session, so a bounded history costs it nothing.

    fleet-mcp.ts
      mintFleetServerBoundTo()    «export function mintFleetServerBoundTo»
        every tool is built per session; what a role may do is decided here, once.
      subtree rule                «refusalIfOutsideOwnSubtree»
        applied to every session-id argument. Checked: no path skips it.
      tool descriptions are built from the granted list at mint time, so a RESUMED
      session can show an old description with new behaviour. Call it, read the reply.

    incident.ts
      open() latches              «if (this.handling) return»
        and KEEPS the latch when the investigation ends in a halt — deliberate, so a
        second refusal cannot start a second guardian. Covered by a test; do not
        "fix" it with a finally. Released by resumeEverything since `ba15b28`.

    verdict.ts
      candidates = fenced block, then every balanced top-level object, reversed.
      readVerdict refuses anything without a non-empty negativeConstraintDescription,
      which is what makes the loose scan safe.

    operator-questions.ts
      ask({ continues })          «const continuing = params.continues»
      close(id, askedBy)          «question?.askedBy !== askedBy»
        a thread belongs to whoever opened it, and a task that is not yours is refused
        in the same words as one that does not exist, so ids cannot be probed.

    integrations.ts
      secrets on disk at 0600, never handed back to the page.
      deliver() checks the answer «refuseUnlessItWasAccepted»
        fetch does not throw on an HTTP error; without this a wrong token read as success.
      errors are filtered against the values actually stored «withoutSayingTheSecret»

    worktree.ts
      create()                    «'worktree', 'add', '-b', branch»  skips if the dir exists
      removeKeepingBranch()       «'worktree', 'remove', '--force'»  the branch survives

    session-state.ts
      mapBySid / setOfSids with three lifetimes. 13 of the supervisor's 17 collection
      fields go through it, which is why the coordination-state sweep found nothing.

    push-stream.ts
      one per session at launchProcess, single consumer via query({ prompt: input }).

## Soft spots — where to dig

Ranked by how much they would explain if true.

1. **Compaction — FIXED in `be1e4f6` and `38579d9`. Keep reading: this entry is the best
   worked example in the file of a symptom mistaken for a cause, twice.**

   What is actually true, measured 2026-09-20 against a worker held near 30% context. Every
   request is attributable because no human typed anywhere near it:

       /compact                                 8 chars    fired
       /compact <57-character single line>     66 chars    fired
       /compact <3.5 KB, single line>        3.5k chars    fired
       /compact <3.7 KB, paragraph breaks>   3.7k chars    cancelled

   **A slash command ends at the first newline.** Instructions containing a line break made
   the CLI cancel the compaction and say nothing. Length was never the cause, so a cap would
   have been the wrong fix. `38579d9` collapses whitespace in `queueCompaction`, so a long
   instruction arrives whole and on one line.

   **The third round, 2026-09-20 evening, and the answer is now structural rather than
   statistical.** Two more cancellations on rails that already carried `38579d9` (3.9 KB and
   1.9 KB single-line; a 1.4 KB one in between fired). Length looked like the variable again.
   It is not:

       A worker read the shipped CLI and SDK bundles: no length cap on command text anywhere.
       The validated limits in there are 65536 for scripts and 1024 for paths. Nothing near 4 KB.

       The activity log for the 1.9 KB cancellation: the compaction turn ran at 20:48:02, ended
       with a 0-char report and NO `compact` line, and the idle nudge arrived at 20:50:02 — two
       minutes after the cancellation, so it cannot be the cause. I claimed it was. `send` marks
       the session working and resets the quiet clock, and the nudge skips a fleet with anything
       busy in it, so the guard I wrote for it was unreachable and its test passed without it.
       Reverted in `14fb2cd`.

       What the log does show beside the cancelled turn: `tools root-5cf1dd86 104 offered` at
       20:48:02 and `59 offered` at 20:50:06. MCP servers dropping and reconnecting re-initialise
       the session. **Best remaining suspect, and still only a suspect.**

   **And none of it needed guessing in the first place.** `SDKStatusMessage` carries
   `compact_result: 'success' | 'failed'` and `compact_error`. `bus.ts` reached that exact
   message to read a busy flag off `status` and dropped both other fields on the floor; no line
   in the codebase had ever mentioned either. Since `f368dcd` a refusal is an event, an alarm in
   the activity log carrying the CLI's own reason, and the refused session is asked again at once
   instead of waiting out a window it never used. **The next cancellation names its own cause.
   Read `.silicyte/activity.log` for `compact refused` before theorising.**

   Working rule until one of those lines appears: keep an instruction well under 3 KB and check
   `self_context` on the next turn rather than trusting "Compaction queued".

   The flag that never cleared was real: `compactionAskedFor` now expires after two minutes
   (`be1e4f6`) instead of disabling threshold compaction for that session forever.

   **Two claims in the original entry were wrong, and both were wrong in the alarming
   direction.** "No `compacted` event for an entire run" was read as the mechanism never
   having worked; in fact the threshold path calls `queueCompaction` with *no* instructions,
   which is exactly the case that always fires. Nothing had ever reached 75%. And "the two
   causes share one symptom, an empty 0-char report, and are indistinguishable from outside"
   is false: a 0-char report follows a **successful** compaction too. The discriminator is the
   `compact` line in `.silicyte/activity.log` — exact, free, and the thing to grep. Never infer
   a compaction from report size.

2. **Swallowed catches — MEASURED AND LARGELY WRONG AS WRITTEN, corrected at `157de77`.** There are 71 `catch` blocks in `src/`, 15 speak, 56 are quiet, and **not one is empty** — every quiet catch returns a fallback, and many are right to. The useful cut is not how many there are but which sit around a **write**: 12 try blocks write state, and 8 of them used to return in silence. Those are fixed. The count below is kept only to show what the claim was. No `as any`, no `@ts-ignore`, no
   `eslint-disable` anywhere — the codebase is otherwise strict. So the catches are the
   accepted escape hatch, and they are concentrated exactly where persistence and probing
   happen: `workspace.ts` 6, `supervisor.ts` 6, `connectors.ts` 4, `self-restart.ts` 3,
   `supervisor-messages.ts` 3. **Every "the state file just didn't have it" mystery ends in
   one of these.** `operator-questions.ts` and `spending.ts` at least carry an
   `alreadySaidItCannotBeWritten` flag; most do not.

3. **Not twenty shots in the air — two habits. AUDITED 2026-09-22, three fixed in `69b0580`.**

   All 21 `void this.…` in `supervisor.ts` were walked, each by forcing the callee to reject.
   **Thirteen cannot reject at all** and need nothing: `bus.emit` catches every subscriber
   (`bus.ts:60`), `memory.sample()` has `catch { return … }` on both commands, **`notifyHuman`
   never rejects** — `integrations.announce` swallows delivery failures and the webhook is wrapped
   — and the rest already carry their own catch. `void` on those is honest.

   What the audit actually found is two orderings, and the `void` only hides what they leave:

   **The intent is marked spent before the thing is done.**
   `if (this.reloadWhenQuiet.delete(e.sid)) void this.parkForReload(e.sid)` consumed the intent in
   the condition, while the work behind it stands behind two ordinary early returns — any session
   frozen anywhere, or one unread message. **No rejection needed.** The session kept its old
   process and old system prompt for good, after the operator had been told it would restart.
   Same shape: `refusalsBySid.delete` before `incidents.open`, which erased the three refusals that
   had earned the escalation and made the threshold unreachable.

   **The latch goes up before the work.** `halt()` set `haltRequiringHuman` and then froze. A
   freeze that fails leaves a fleet that believes it halted and stopped nothing, with no `halted`
   event, and the same latch is the guard at the top — so a retry does nothing for the rest of the
   process, while silencing every nudge and every park.

   Still unfixed and recorded rather than pretended away: `handleDowngrade` writes the session's
   new model and marks the turn refused **before** opening the incident, so an open that fails
   leaves a quietly downgraded model, no incident, and `recoverFromFailedTurn` suppressed by the
   mark. Four more `void` sites (`reportUnexpectedDeath`, `recoverFromFailedTurn`, two in
   `stopTheFleetIfALimitSaysSo`) lead into the same halt/incident machinery and were not driven to
   a conclusion — the limit probe needed ceiling settings the prober's config lacked.

4. **The spend baseline ordering — FIXED in `55ac66d`, and the reason it stayed open is worth
   more than the fix.** The baseline advances in `drainIntoBus`'s `finally`; moving it earlier
   double-counts, because the last usage a process reports is cumulative for that process. The
   README said no behavioural test could catch it, since the suite drives a fake `SessionHandle`
   with no mid-drain moment. **That was a fact about the one fake that existed, read as a fact
   about fakes.** `aProcessWithOneLastReadingOnTheWayOut` is four lines: an async generator that
   yields once and then reports usage while it is still being iterated. Two tests now hold the
   ordering, and reintroducing the advance at the top of `drainIntoBus` fails both and nothing
   else.

   The general lesson, because this was not the only place it applies: **a claim that something
   cannot be tested is usually a claim about the test harness that happens to exist.** Check what
   the fixture actually does before believing it.

5. **The coordination-state sweep — DONE 2026-09-20 against `55ac66d`, and it found nothing.**
   The entry used to say `supervisor.ts` holds "~25 private fields of mutable coordination
   state", that defect #1 was that shape, and that a sweep was the highest-yield audit here.
   The sweep is done. The number is **17**, and the answer is no.

       13 of 17   declared through `stateBySid` with an explicit lifetime, and cleared by that
                  machinery at the right boundary rather than by hand
        1         `roleFingerprints` — keyed by role, bounded by the number of roles
        1         `stoppedOnPurpose` — keyed by task id, deleted on both outcomes (748, 1324)
        2         `reportsHeldUntilUnfreeze`, `humanOutbox` — cleaned in `closeOne`

   **The asymmetry that looks like a defect and is not.** `closeOne` drops both arrays; the
   `finally` in `drainIntoBus` does not. That is the process/session distinction doing its job:
   `closeOne` is the session ending, the `finally` is a process ending while the session may
   continue on its own transcript. A human message queued for a session that then crashes
   *should* survive to be delivered when it comes back (it is, at the `result` case around 1341).
   Cleaning there would lose it.

   The one residue, named so nobody re-derives it: `stoppedOnPurpose` keeps an entry if
   `stopTask` succeeds and the task never appears in a later `gone` list. Bounded by tasks ever
   stopped on purpose, keyed by a unique id, consequence nil unless ids repeat. Not worth code.

   **What this entry is really evidence of.** `stateBySid` was built to make this class of bug
   impossible, and 13 of 17 fields went through it. The audit's yield was already collected by
   the design — which is the outcome you want and the one nobody writes down.

6. **`app.html` — DONE, waves 1-6 on 2026-09-22 (`38d1bf9`..`de2e538`). Read this entry before
   proposing to split that file: the reason to split it was solved more cheaply.**

   What was true: 2073 lines of script, 128 functions, nothing in it reachable from a test, 11
   raw `innerHTML` sinks and 19 `escapeHtml` calls that each render path had to remember.

   What is true now: **1 sink, 3 `escapeHtml` calls, 19 globals, and every function callable from
   a test.** `tests/panel-harness.ts` lifts the script out, drops the single `void boot();` at its
   end and runs the rest in a subprocess with a forty-line page stub and an `EventSource` stub.
   No restructuring was needed, because nothing but that one call runs at load. Escaping is a
   tagged template — interpolations escape, markup carries a symbol saying it is already markup —
   and `tests/panel-script.test.ts` asserts that exactly one line writes `innerHTML` and that it
   is the escaping one. The panel keeps **one** record of the open session and every channel
   updates only the fields it carries; there were four update paths and no rule about which of
   ten renders belonged to each.

   **The file was not split, on purpose.** Modules buy isolation for testing, and the harness
   already bought it for the price of one file. Splitting also touches delivery — the server
   serves one file, `write-guard.ts` names it, four tests read it by path. Size alone is not a
   defect.

   **What it caught, in code that had been read carefully:** `findInTree` recursing into
   `node.reports` unguarded (one node without the field throws out of a function every render path
   calls); `formatTokens(999999)` reading `1000k`; a rate-limit refusal with no percentage drawn
   grey and labelled "no data"; a session freezing while open showing the new status word and no
   reason until reopened. Four, in the first two hours of the harness existing.

   Still open and carded: **#60**, the context bar is not live. The reading itself has to reach
   the fleet snapshot, which is server-side. Wave 4 made that a one-field change rather than a
   second render path.

7. **Test residue pollutes the product repo.** Quarantine tests have left 32 `silicyte/worker-*`
   branches and 8 worktrees under `/tmp` and `/var/folders`. Verified none held unique commits;
   deleted once, will come back. Not filed.

8. **The two sessions the product spawns itself are pinned a model generation back.** The
   naming half is FIXED in `f23b870`; the version is the operator's, filed as `e4c55abc`.

   What was there: `guardian.ts:5` `export const DEFAULT_MODEL = 'claude-opus-4-8'` imported by
   nobody — its only use was the line below its own declaration — and `setup.ts:21`
   `const SETUP_MODEL = 'claude-opus-4-8'`, an independent copy of the same string. Two names,
   one value, agreeing by coincidence, and `DEFAULT_MODEL` claiming to be a fleet-wide default
   when the fleet's models come from the role config. Same class of lying name as `rec.branch`.
   Now one `MODEL_FOR_WRAPPER_OWNED_ROLES` in `types.ts`, beside `MODELS_THE_CODE_KNOWS`, with
   a test that the name is in that list at all.

   Settled, and the reason is worth knowing on its own. **`claude-opus-4-8` is where classifier
   fallback stops.** `bus.ts:166` turns a classifier refusal into `retriedOnFallbackModel` with
   an `originalModel`, a `fallbackModel` and `swapsSessionModel`; `supervisor.ts:841` changes
   the session's model when the last two are set. There is nothing beneath this model to swap
   in, so a session on it stays on it. The guardian scrubs after incidents under
   `bypassPermissions` with no network, and the setup session runs the interview — neither may
   be moved onto another model mid-run without anyone choosing that. It is not age and not cost
   (same price as `claude-opus-5`).

   The constant is `MODEL_NOT_SWAPPED_WHEN_THE_CLASSIFIER_TRIPS` in `types.ts` (`72d01ed`), and
   the name is deliberately the whole record: raising it to a newer model now contradicts the
   name rather than looking like a tidy-up. **Do not "fix" it.**

   Two lessons, both from the operator inside ten minutes. "Nobody would deliberately do that"
   has now been wrong twice on this product. And an assertion written to carry knowledge that
   belongs in a name is a workaround for the comment ban, not a test — this codebase puts it in
   the identifier (`refuseAWriteGrantNoRoleWillBeGiven`, `theWindowItMeasuredHasSinceRolledOver`)
   and so should you.

## The write guard, after 2026-09-22 — what is closed and what is not

Six gaps found by an opus worker, every one verified by asking `buildWriteGuard` directly rather
than by running anything. **Closed** in `0f2ec5f` and `aea6915`:

- `git --git-dir <path>` / `--work-tree <path>` with a **space** skipped the entire git branch:
  only the `=` form was matched, so the target stayed at cwd and the path read as the subcommand.
- `/usr/bin/git` walked past the git rules *and* the unreadable-program scan at once — one looked
  for a token equal to `git`, the other took the basename.
- The stopping-verb test matched after any whitespace, so any `grep` carrying that word and a path
  from this product was refused. **This cost root two turns in one sitting.** Anchored now.
- `pkill -f node` was allowed, because the check asked for the words silicyte or supervisor. The
  supervisor is a node process.
- The unreadable-program scan walked only `ORCHESTRATOR_OWN_FILES`, so `python3 -c` writing into
  a **shared checkout's `.git`** passed while the shell redirect was refused. Now carries those.
- `ln` was read for its last path only, so aiming a link anywhere looked like making an ordinary
  file. It names every path it is given now.

**STILL OPEN, and not closable by reading command text.** `isInside` compares paths lexically;
the OS resolves realpath; and `everywhereASessionMayWrite` **must** include each shared checkout's
`.git`, because committing from a worktree writes there. A symlink inside a worktree pointed at
that directory is therefore a door the guard cannot see — demonstrated on the filesystem, not
argued. `ln` is closed, so what remains is a symlink made by a program the guard cannot follow, or
one that already exists. Fixing it properly means resolving symlinks inside the hook, on every
command; nobody has measured what that costs or what it would falsely refuse.

**The rule this leaves:** the guard is a second line, not the line. The OS decides, the guard only
reads what you typed. Anything that reaches the filesystem another way reaches what the sandbox
permits, and the sandbox permits more than the guard does — see the entry on `filesystem.allowWrite`.

## Checked in the fourth pass and found FALSE — do not re-derive these

Research round 2026-09-22, four workers on `claude-haiku-4-5-20251001` plus root. ~25 claims
returned. **Every one verified was false except one.** Kept here so nobody spends the hour again.

- **"The write guard misses `2>/path` without a space."** False. `REDIRECTED_INTO` uses `\s*`,
  not `\s+`. Asked the guard itself with all four spacings against a protected path — all four
  refused. The way to check this is `buildWriteGuard(...)` and call the hook, never by running
  the command.
- **"`integrations.json` is write-protected but readable, so a session can take the token."**
  False. `supervisor.ts:403` always passes it in `secretsNoSessionNeeds`; the deny is a product
  default, not this installation's config. Only `~/.ssh` and that file are denied by default
  (`sandbox.ts:16`).
- **"A session can curl the panel and retune the root."** False *as stated* — but read the true
  version below, which is worse. The panel does listen on `127.0.0.1:4173`; a session's
  connection to it is refused.
- **"The panel's API has no subtree checks, so a session can interrupt any other."** The premise
  is true and the conclusion does not follow: the panel is the operator's surface and the
  operator may touch any session.
- **"`recordTotalFor` after `retire` double-counts in `fleetTotal`."** False.
  `noteWhatItSpent` returns early on `status === 'stopped'`, and `closeOne` retires and sets that
  status in one synchronous block — there is no awaitable gap between them.
- **"`isFrozen` / `applyVerdict` / `releaseOnlyWhatTheLimitFroze` leave state inconsistent if a
  call in the middle throws."** Reported three times in different words. Structurally true of
  almost any multi-step mutation and undemonstrated in every case: no throw was shown. Do not
  file this shape again without an input that actually throws.

**True and minor, from the same round:** a window that leaves `polled` lives on in `pushed`,
because `snapshots()` unions both key sets and `poll()` replaces `polled` wholesale
(`rate-limits.ts:177`). Consequence is a stale row in the full summary with an honest
`observedAt`; it cannot affect `theWindowThatBinds`, which only considers windows that do not
vanish. Not filed.

**True and material, from the same round:** see the panel entry below.

## The panel's API has no authority checks at all, and nothing in the product supplies them

`src/web/server.ts` performs no authentication and no subtree check on anything. `/api/auth`
reports whether `claude auth login` has happened; it guards nothing. Every state-changing
endpoint — retune, interrupt, stop a background task, answer an operator question, stop and
resume the fleet — is available to whatever can open TCP to `127.0.0.1:4173`.

Sessions cannot reach it **today**, and that is the harness sandbox refusing localhost, not the
product. `mayRunOutsideTheSandbox: true` is a documented per-role option the README calls the
operator's decision; a role given it also receives the whole fleet-control API, bypassing the
subtree authority that `fleet-mcp.ts` enforces on every equivalent operation. The two surfaces
disagree about who may do what, and only one of them knows it.

Measured 2026-09-22: panel listening on 4173 confirmed, connection from a sandboxed session
refused. Not filed as a card yet.

## A drain belongs to a process, not to a session — `060386e`

`drainIntoBus` ends in a `finally` that marks the session stopped unless it is parking. That
finally is per **process**. Nothing tied it to the session's *current* process, so when a
replacement had already taken over, the older drain finishing last closed a session that was
working. `setStatus` emits nothing, so the record said nothing at all: no kill, no death, no halt.

Reported from production. A root whose turn failed was relaunched on the same conversation,
answered normally twenty seconds later, then left the registry and the panel while its process
kept opening pull requests. Six sessions were left reporting to a root that no longer existed and
`humanEntryPointSid` was null, so nothing could reach the operator.

**The tell in the log was two `init` events a second apart** — two processes, one sid.

**The detail that decides the fix:** `Registry.update` is `Object.assign` onto the *same* record
object, so `rec.handle` inside an old drain is already the **new** handle by the time its finally
runs. Comparing `rec.handle` to the registry's proves nothing. The handle has to be captured in a
local when the drain starts.

Same disease as `reportUnexpectedDeath` and the cut-short mark, all three found on 2026-09-22:
**an obligation resting on a value read later than somebody else overwrote it.** When you find one
of these, look for the others before you stop.

## A worker reads the code its worktree was cut from, which is not the code that runs

A worktree's branch is cut from `origin/main` **at the moment the session is created** and does
not follow it afterwards. That is right for a session writing code and wrong for one reading it:
a worker started in the morning analyses the morning's code and reports line numbers nobody can
find. Measured 2026-09-22 — the shared checkout's local `main` sat at `de2e538` while
`origin/main` had moved eight commits on.

A session cannot `git fetch` (ssh is refused at the proxy), **but it does not need to**: worktrees
share one object store and one set of refs with the checkout they were cut from, and the
supervisor fetches on every land. So `git show origin/main:<path>` and `git archive origin/main`
give the current code from inside any worktree. Say so in a reading task; do not assume.

## Traps that have already cost time

- `npm test | tail` reports **tail's** exit code. Write to a file and check `$?`.
- The panel's strings are **not** in `src/web/`. They are `locales/en.json` and `locales/ru.json`
  at the repo root; `app.html` only asks for keys. `tests/locales-agree.test.ts` enforces that
  both files carry the same keys and that every literal `t('...')` key exists — template keys
  like `` t(`effort.${level}`) `` are invisible to it.
- Only `data-i18n` and `data-i18n-title` are applied (`applyStaticText`). There is no
  `data-i18n-placeholder`; a placeholder needs its own line, or a prefilled value instead.
- `${PIPESTATUS[0]}` is empty in zsh — zsh uses `$pipestatus[1]`.
- `maxTurns` / `budgetUsd` are lifetime caps on the whole `query()`, not per-turn brakes, and
  `recoverFromFailedTurn` returns early for non-root sessions. They are not a spending control.
- The absence of a tool call is not proof a block worked. **Check timestamps** — a tools list
  logged before a fix landed proves nothing. This nearly produced a wrong report on card #54.
- A test may assert the behaviour you are about to "fix". `tests/stop-at-the-limit.test.ts:141`
  deliberately holds the fleet on a past `resetsAt`. Read the test before changing the code.
- A stale registry row restored from disk has caused three separate failures to start. When the
  fleet comes up wrong, `registry.json` is the first file to read.
- `/compact` typed with a Cyrillic `с` does not fire and gives no error.
- **A resumed session can see a tool's old description with its new behaviour.** Measured
  2026-09-20: after a restart that granted root the right to edit its own role file, the sandbox
  allow-list already carried the new directory, but `apply_skill_changes` still described itself
  as covering `worker` alone. Calling it answered `Applied to: root.` Both values come from the
  same `profile.maySculptSkills` in the same function (`launchProcess`), so they cannot really
  disagree — the description was a snapshot, most likely the cached prompt prefix a resume reuses.
  Mechanism unproven; the observation is not. **Never conclude a capability is missing from a tool
  description. Call it and read the reply.**

- **A compaction instruction must be one line.** `self_compact`/`fleet_compact` take free text
  and it used to go straight into `/compact ${instructions}`; a line break silently cancelled
  the whole thing. Fixed in `38579d9`, but the same rule applies to anything else ever sent as
  a slash command through `send()`.
- **The write guard reads Bash command *text*, so merely mentioning a forbidden operation is
  refused.** `grep -rn "supervisor.kill("` over `tests/` is rejected exactly like the real
  thing would be, and so is a commit message containing `rm` or `git mv`. Searching for the
  word costs you the call and the turn. Two ways through: a bracket expression that is not the
  literal token (`k[i]ll`), or the Read/Edit/Write tools, which the Bash hook never sees. Long
  commit messages go through a file with `git commit -F`, written with the Write tool.
- **`fleet_restart` only works if the fleet was launched under the watcher.** `npm start`
  (`src/start.ts`) runs it with nothing outside the process to bring it back, and the restart is
  refused with "nothing outside this process would start it again". `npm run fleet`
  (`src/supervised.ts`) is the supervised launch that makes self-restart possible. Check which
  one is running *before* promising the operator a restart — the refusal arrives only after you
  have already told them it is happening.
- **Config changes in `workspace/fleet.config.ts` apply at startup, not on write.** Editing the
  file changes nothing in the running process, so the old ceilings stay in force until somebody
  relaunches. Worth saying out loud when a limit threshold is the thing being changed.
- The orchestrator checkout (`silicyte-solo-dev`) has `origin` = the **same** repo you land to
  (`ye666w/silicyte.git`), on `main`. So the rails are exactly what you pushed — but only after
  that checkout is pulled. It can sit many commits behind while you keep landing, which means
  the fleet runs code you fixed hours ago. `git log HEAD..origin/main` in that checkout is the
  one-line check for how stale the running fleet is.
- **`SessionState` owns a collection by holding a reference to it, so the field pointing at it
  must be `readonly`.** `mapBySid`/`setOfSids` hand back a Map/Set and capture *that object* in
  the `forget` closure. Reassigning the field (`this.x = new Set()`) leaves the mechanism
  emptying the old object while the code fills a new one — silently, with no observable symptom,
  because `whatIsStillHeldAbout` inspects the object SessionState was given and therefore answers
  "not held". It is wrong in the reassuring direction. All thirteen declarations are `readonly`
  as of `375a575`, so the compiler refuses it (TS2540), and `tests/session-state.test.ts` refuses
  a newly added declaration that is not. Empty in place with `.clear()`. This bit once, in
  `frozenByTheLimit`, five sites, shipped and landed before it was noticed.
- **`supervisor.ts` is big because orchestration is big, and cutting it further makes it worse.**
  Measured 2026-09-20 at `68cc3cd`. Of its 44 fields, 17 are collaborator objects that are
  already their own modules (bus, registry, spending, rateLimits, incidents, timings, worktrees,
  rootTroubles, theLimit…), 13 are per-session collections owned by `SessionState`, 4 are timers,
  and only 6 are loose scalars. There are 39 modules in `src/` and this file is what ties them
  together.

  The test for whether a cluster can leave: count the supervisor members it would still need
  from outside. Measured, per candidate:

      limits, the orchestration methods      74 lines   needs 10 outside
      incident / quarantine                  77 lines   needs  9 outside
      money / token polling                  53 lines   needs  6 outside

  All three drag the registry, the bus and per-session state with them, so moving them relocates
  the coupling instead of reducing it — "six files with the same defect", which the plan warned
  about in exactly these words. **What extracts cleanly is pure decision state with no
  per-session data.** That is why `limit-hold.ts` worked: five fields, nine rules, no sid
  anywhere, 23 raw field touches became 13 named calls and the rules got their first direct
  tests. It is also why the limits *methods* stayed behind.

  So the rule for any future split here: extract the decision, never the orchestration, and
  never anything keyed by sid (that belongs to `SessionState` — see the reference trap above).
  If a candidate needs more than two or three supervisor members from outside, leave it.
- **Open question, not yet a defect:** `isOrchestratorsOwnSkill` (`src/workspace.ts:63`) compares
  names with `Array.includes`, which is case-sensitive, against `['guardian', 'setup']`. macOS
  filesystems are case-insensitive by default, so a fork skill directory named `Guardian` is the
  *same directory* as `guardian` while reading as an ordinary fork skill. I have not established
  what the right behaviour is, so `tests/workspace.test.ts` deliberately does not assert the
  current one — asserting it would turn an open question into a promise. Worth settling before
  anyone relies on the reserved list as a boundary.
- **There is no local `main` to fast-forward from a worktree.** `git branch -f main <sha>` dies
  with "cannot force update the branch 'main' used by worktree at …/silicyte" — the orchestrator's
  own checkout has it checked out. Landing is `git push origin HEAD:main`, full stop. Do not
  `git -C` into the orchestrator checkout to work around it: that checkout backs a running fleet.
  This wording was wrong in three skills of the previous fleet and cost a turn every time.
- **A `git push` to this remote can run past two minutes and still exit 0.** Not a hang — both
  refs moved. Give it a long timeout or background it deliberately, rather than reading the wait
  as a stuck prompt and killing it.

## Resuming a session: two facts, both measured

Both established here on 20.09.2026 with throwaway Haiku sessions, `maxBudgetUsd: 0.05`, by
creating a session, then resuming it and asking about something only one side could know.

**`resume` is not scoped to the working directory.** A session created with `cwd: A` resumes
fine with `cwd: B`, keeps its whole conversation, and its transcript **stays in A's project
directory** — B never gets one. `~/.claude/projects/<mangled-realpath>/<uuid>.jsonl`, and the
mangling resolves symlinks, so `/var/folders/…` is stored as `-private-var-folders-…`.

**`systemPrompt.snapshot` decides whether a resume can re-brief a session.**

    snapshot: false   a new system prompt IS applied on resume
    snapshot: true    frozen at creation; the new prompt is ignored
    field omitted     behaves like true

`launchProcess` passes `snapshot: rec.role === GUARDIAN_ROLE`, so **every ordinary role is
re-briefed on every resume and Guardian deliberately is not.** That is what makes
`apply_skill_changes` actually work — park, relaunch on the same conversation, new skill in the
system prompt. If that flag ever flips to the default, skill rewrites would stop reaching running
sessions silently, with the conversation intact and nothing to show it failed. Worth a test that
nobody has written.

The trap to know: asking a resumed session the same question it already answered proves nothing —
the old answer is in the history and it will repeat it. Ask about a fact that exists **only** in
the new system prompt.

## Keeping this file honest

Re-verify before trusting, in this order:

1. `git -C <product> log --oneline -1` and `git -C <fork> log --oneline -1` against the pin above.
2. For any anchor used in an argument, grep the `«»` text. If it does not match, the section
   is stale — fix it in place rather than working around it.
3. When a soft spot is fixed, do not delete it. Move it to a closing line saying which commit
   fixed it. The list of things that were once wrong is the most reusable thing here.

## `supervisor.ts` is large and not tangled — measured 2026-09-22, do not re-derive

2028 lines, 47 fields, 124 methods, and the obvious move is to split it. **Do not.** Measured by
grouping every `this.<field>` by the method that touches it:

- `registry` — touched by **67** methods
- `bus` — **32**
- `roles` 14, `theLimit` 10, `frozenByTheLimit` 8 (now gone), `backgroundTasksBySid` 7,
  `haltRequiringHuman` 7
- **everything else — one or two methods each**

There is no seam. Any class carved out still holds `registry` and `bus`, so a split adds
indirection and removes no coupling; and the fields that look extractable are touched by a single
method, so extracting them moves one method and achieves nothing. The file is a facade over
concerns that are already separate at the field level.

The script is twenty lines: regex the field declarations, walk each method body by brace depth,
intersect `this.<name>` with the field set, invert. Redo it before anyone argues for the split
again — it is cheaper than the argument.

What the same measurement *did* find is below.

## One reason a session is held — `1e224d3`

Before: three parallel registers for one fact. `rec.quarantinedByIncident` (a boolean, persisted),
`heldBackByAVerdict` (a Set, memory only), `frozenByTheLimit` (a Set, memory only). `isFrozen` was
a subtraction over two of the three, so every new reason meant remembering to subtract it.

**The hole that mattered:** only the boolean reached disk, and `applyVerdict` cleared exactly that
boolean while moving the holding into the in-memory Set. So a session a verdict called
contaminated came back from the next fleet restart **`parked`** — an ordinary session any message
wakes. This fleet restarts several times a day.

Now: `SessionRecord.heldBecause: WhyASessionIsHeld | undefined`, persisted, and one table in
`types.ts`:

| `heldBecause` | holdsTheWholeFleet | aPlainUnfreezeLiftsIt | whatSurvivesARestartSays |
|---|---|---|---|
| `undefined` | yes | yes | — |
| `theAccountRanOut` | yes | yes | — |
| `anIncidentHasNoVerdictYet` | no | **no** | a sentence |
| `aVerdictCalledItContaminated` | no | yes | a sentence |

`whatAHoldMeans(why)` is an exhaustive switch, so a fifth reason will not compile until all three
columns are answered for it. Grep `heldBecause`.

Semantics worth knowing before touching this, all three deliberate and tested: the operator
resuming by hand **does** release a verdict hold and **does not** release a quarantine; a restart
does the opposite of both.

**A table is the cheapest thing in this codebase to mutation-check** — one cell at a time, one
loop. Doing that found `theAccountRanOut → holdsTheWholeFleet` covered by nothing, whose
consequence is the dashboard reading "working" while every session is frozen.

## The one-shot mark, and the guard that now holds the shape

`tests/marks-are-spent.test.ts`. A method that deletes what it just read answers once. Put behind
`&&` or `||` it is asked only on some runs, and on the others the mark it was meant to spend stays
for the life of the conversation and answers a question asked hours later about something else.

That is how **root recovery switched itself off**: `thatTurnWasRefused` was the last term of
`!e.ok && !cutShortOnPurpose && !thatTurnWasRefused(sid)`, and a refusal the fallback rides out is
precisely the case where the turn goes on to *succeed* — so the mark was set, never read, and
suppressed the next genuine crash. Fixed in `b9f6d36`; the guard is `c28b744`.

The guard reads `supervisor.ts` as text, finds every non-void private method whose body deletes
per-session state, and refuses call sites behind a short circuit. `if (f(x))` as the sole term
stays allowed, and is correct — it is always evaluated.

**Source-reading structural tests are the house style here** and there are now six:
`map-is-true`, `session-state` (×3), `marks-are-spent` (×2). Reach for one whenever a defect is a
*shape* rather than an instance.

## Still open, with the diagnosis already done

- ~~**`incident.open` raises `this.handling` before the work it guards.**~~ Fixed — `ed8f1be`,
  `c2f55cc`. The hold table grew the fourth reason it needed
  (`itRefusedWhileAnotherIncidentWasOpen`) and the column that goes with it.
- ~~**`Worktrees.create` pushes to its rollback list after the work.**~~ Fixed — `06c47e3`.
- **The polled rate-limit map is replaced, not merged**, so a reply omitting a window erases the
  last reading of it. Left alone deliberately: whether a window the account stopped reporting
  should still hold the fleet is a question about the API's meaning, not about this code.
- **`awaitVerdict` subscribes after `await spawnGuardian`.** Shape present, window a couple of
  microtasks, no plausible way to land a message in it.

## The panel's state frames carried less than the panel showed — FIXED, kept for the shape

`TreeNode` (`web/server.ts`) carries `sid, role, title, status, model, effort, tokens, startedAt,
frozenReason, isHumanEntryPoint, backgroundTasks, reports`. It carries **no context**, and neither
does `fleetState()`, and no event frame does either. `refreshSelectedStatus` merges only
`{ record: live }`.

So `known.context` is forever whatever the single `fetch` in `showSession` put there. That is the
whole of backlog #60 — and the same sentence explains the `session:`, `connectors:` and worktree
tags, which live only in `/api/session/:sid`.

**The consequence nobody had noticed:** because `known.context` stays truthy, `renderContextBar`
always takes its first branch, so a session that parks never gets the `stale` class and never
falls back to `lastKnownContext`. The bar looks fresh and is wrong.

One job, not three: **put what the detail panel shows into the snapshot.** Done — `TreeNode` now
carries `context`, and the context bar goes stale when it should.

The second half of this section is also closed — `f4341e7`. The panel kept **two** copies of
decisions the server owns: `HEADLINE_LIMIT_TYPES` beside the `primaryLimitType` it was already
being sent and ignoring, and `ACCOUNT_WIDE_LIMIT_TYPES` beside the two windows `thresholdFor`
names in `rate-limits.ts`. `thresholdFor` is one table now, `LIMITS_THAT_CAN_STOP_THE_FLEET` is
derived from it, the server sends both, and the panel draws what it is told.

**The shape worth keeping from all of this:** a client that restates a decision the server already
transmits is not a duplication a test will find, because both copies are right on the day they are
written. Grep for the constant's *value*, not its name — `five_hour` appeared in two files under
two different names. Still open in the same family: `/api/session/:sid` sifts the whole bus history
to send events the panel destructures away.

## `tests/panel-harness.ts` can drive async paths now

`askThePanel` used to print its answer synchronously, before the first microtask, so nothing with
an `await` in it could be asked a question. It now answers on a `setTimeout(…, 0)`: every
microtask has drained, so a stubbed `fetch` that resolves immediately has completed. Everything
already in the file is synchronous and was unaffected.

If you need to wait for something a *timer* resolves, the older trick still applies: in
`setUpFirst`, stash `console.log`, stub it, and call the real one at the end of your own chain.

**And a trap that reads as a passing mutation:** a test that awaits an answer nobody will give
*hangs*, and a mutation run that hangs looks exactly like one you have not read yet. Answer
everything the test asked for — with the guard in place the extra answer lands on nobody.

## The hold table grew a fourth reason and a fourth column — `ed8f1be`, `c2f55cc`

`itRefusedWhileAnotherIncidentWasOpen`, and the column `aVerdictMayLiftIt`.

One incident is handled at a time, and that latch stood above the line that quarantines, so a
second session the classifier fired in during an open incident was never held, never in Guardian's
brief, and released as innocent by a verdict that judged somebody else.

Designing it in the table is what showed the trap: **if a verdict may not lift it, neither may
Resume, and the session is stuck for good.** Those are different columns. A verdict may not lift a
hold it never judged; the operator's Resume may, and the question filed for them says so.

The fourth column paid for itself at once — it replaced both the `heldBecause !== 'theAccountRanOut'`
in the verdict's clean filter and the matching special case in the loop below it.

**`unfreeze` clears `heldBecause` when it lifts a freeze.** Whatever lifts a hold clears the reason
for it, or a resumed session runs carrying a hold that is no longer true and freezes itself again
at the next restart. That rule removed a separate verdict-hold sweep from `resumeEverything`.

## Connectors: an empty reading is not evidence — `2fdae74`

`noteWhatASessionSees([])` used to wipe the remembered list and save it, so `keptAwayFrom`
answered with nothing and **a role the config allows one connector received no `mcp__*` denials at
all** — while `briefing.ts`, counting the same emptied list, still told it no connector was its
own. Denial and sentence drifting opposite ways from one cause.

Empty readings are ordinary: `askItOnce` returns `[]` on a throw, `learn` returns `[]` when its
thirty-second window runs out, and a session started with `settingSources: []` (Guardian, setup)
sees none of them. The asymmetry settles it — never forgetting a connector that has gone costs a
denial on a tool that does not exist.

`runDoctor` also stood up its own `Connectors` on a running fleet and let `learn()` save, so disk
and the live supervisor's memory diverged and only a restart believed the disk. **A check should
not write**: `probeWithoutRememberingIt()` exists for that and the doctor uses it.

## Three worker passes over `src/`, 2026-09-22 — what is now read

Twenty-three findings, every one verified by a run, no false positives. Reported clean:
`registry.ts`, `bus.ts`, `workspace.ts`, `spending.ts`, `landing.ts`, `self-restart.ts`,
`push-stream.ts`, `activity-log.ts`, `keeping-a-file.ts`, `skills.ts`, `briefing.ts`, `setup.ts`,
`model-switch.ts`, `memory-watch.ts`, `capacity.ts`.

Not yet read by anyone: `fleet-mcp.ts`, `write-guard.ts` (audited separately 2026-09-21),
`guardian.ts`, `sandbox.ts`, `verdict.ts`, `timings.ts`, `config-file.ts`, `cli-binary.ts`,
`supervised.ts`, `supervisor-messages.ts`, `session-state.ts`, `root-trouble.ts`,
`unobserved-failure.ts`, `start.ts`, `setup-session.ts`, `doctor-cli.ts`.

**The task shape that produced this**, worth copying verbatim: one sentence of what is wanted at
the top; the exact file list; read `origin/main`, not the worktree; a description of the *shape*
rather than a place to look; what is already decided and must not be reopened; at most N findings,
most serious first, each with the two lines, one sentence of consequence, and a mandatory
«проверено» naming what was run; a line saying "clean" is a complete answer; one turn.

## A pipe eats the exit status of what feeds it

`npm run typecheck 2>&1 | tail -4 && npm test` runs the tests even when the typecheck failed,
because `&&` reads **tail's** status. Already known for `npm test`; it is true of every gate.
Give each one its own line and its own `echo "…=$?"`.

## Compaction: the CLI never reports a cancellation — measured 2026-09-22

In a full day of a real fleet, `.silicyte/activity.log` holds **185 lines mentioning compaction and
zero `compact refused`**. The bus only emits `compactionRefused` from `msg.compact_result ===
'failed'` (`bus.ts`), and that message does not arrive. A cancelled compaction is therefore
**invisible to the supervisor**, which is why it retried every two minutes forever.

Do not assume `compacted` (from `compact_boundary`) is the only signal either — it does arrive, so
a successful compaction *is* observable. It is only the failure that is silent.

Consequences now handled (`b3661a4`):
- asks are counted; three that change nothing stop the asking and file an operator task;
- the ask waits for the turn to end and for nothing to be unread, instead of being posted into the
  middle of a turn where the next arriving message cancels it;
- the ask is stamped with the clock of the event that sent it.

**Still unknown and worth asking the operator, not guessing:** *why* the CLI cancels. The leading
hypothesis is input arriving during the compaction. Task `e9fe25fb` asks for the transcript around
one.

## Why the CLI cancels a compaction — answered by the operator, task `e9fe25fb`

**The session was busy.** A `/compact` posted into the middle of a turn is cancelled. That is the
whole of it, and it makes `b3661a4` the right fix rather than a guess.

Two things follow that were not obvious before:

**The old "a 3.9 KB instruction was cancelled while 1.4 KB went through" mystery is probably not
about size at all.** `self_compact` and `fleet_compact` still call `queueCompaction` directly, so
they post into the middle of the asking session's own turn. Whether it survives then depends on
what arrives next — a report from below, a nudge, the operator typing — not on how long the
instruction is. Two runs with different sizes are two runs with different traffic. Worth
re-testing before anyone bisects on length again.

**Deferring the ask opened a hole of its own**, fixed the same day: an intent held for a quiet
moment that never comes is an intent never spent, and nothing counts or reports it. A session
written to on every turn has something unread at every turn's end. The wait is bounded by
`LONG_ENOUGH_FOR_A_COMPACTION_TO_HAVE_LANDED_MS`, after which it asks anyway — the old behaviour,
which at least gets counted.

The general shape, third time this week: **moving work later moves the failure later too, and the
new failure is usually silence.** When deferring something, ask what reports it if the later
moment never arrives.

## `Worktrees.create` — the rollback list was written after the work — `06c47e3`

`git worktree add -b` prints `Preparing worktree (new branch ...)` **and then** checks the
destination, so an add that fails can already have made the branch. The push onto
`cutByThisCall` sat after that call, so such a repository was never on the list and
`leaveNoTraceOf` never reached it. `create` throws, no registry row is written, nothing comes
back for it, and every retry leaves another `silicyte/<sid>`.

Measured, not assumed: `existsSync` on a **dangling symlink returns false**, while git sees the
path as present. That is the reachable route past the `if (!existsSync(dest))` guard, and it is
the shape a previous half-failure leaves behind — so the failure feeds itself.

This is soft spot 7 (stray `silicyte/worker-*` branches) in part: some of that residue is real
tests, some was this.

## The fifth worker task: mutation over the suite, not reading

Six "decorations" in one day — guards written, nothing observing them, and **re-reading found none
of them.** The counter-measure that works is mechanical: change one thing in `src/`, run the
suite, put it back. Green means a hole.

The full suite takes about five seconds, so the loop is cheap enough to do by the dozen. Worth
repeating periodically rather than once.

## The authority layer was decoration until `9218900` — and how that was found

A worker made sixty single mutations across `src/`, ran the suite after each and reported what
stayed green. Ten findings; **nine were one hole**, and its shape is the reusable part:

> the suite tested the **functions** that do the checking and never tested **which callers are
> obliged to ask them**.

`refusalIfOutsideOwnSubtree`, `hasVerb`, `isInside` were all covered — remove a line inside any of
them and the suite goes red. Remove the *call* from a tool and nothing noticed. So every boundary
in `fleet-mcp.ts` held only by habit: no authority meant full authority, four of six verbs gated
nothing, three of five grants gated nothing, two tools reached outside the caller's subtree,
`__setup__` could be started from inside the fleet, and both caps on `fleet_request` were an
off-by-one loose.

`tests/authority.test.ts` is one table — each tool against the verb, grant and subtree it needs —
because it was one hole. Sixteen mutations, sixteen caught. **A table grows with the number of
tools; separate tests do not.**

Covered and confirmed dense by the same pass, so do not re-derive: `write-guard.ts` (13 of 14
mutations caught), `sandbox.ts` (9 of 9), `landing.ts` (5 of 5), `limit-hold.ts` (4 of 4),
`capacity.ts` (5 of 5), and most of `registry.ts`.

**How to run this again.** `git archive origin/main | tar -x -C "$TMPDIR/…"`, symlink
`node_modules` with `node -e 'fs.symlinkSync(…)'` (`ln -s` is refused by the guard), then one
mutation → `npm test` → restore, in a loop. A full run is about five seconds. **The unpacked tree
is not a git repository, so `setup is told that src/ is the code this fleet runs` fails always —
the oracle is `fail > 1`, not `fail > 0`.** And beware `X ? [` → `[] ? [`: an empty array is
truthy, so that mutation changes nothing.

Worth repeating periodically. Six "decorations" of my own were found the same day by the same
method, and re-reading had found none of them.

## The panel's HTTP surface had never been asked anything — `a1afc8d`

39 mutations in `web/server.ts`, 3 caught. **No test calls `route()` and none calls `start()`.**
`tests/panel-routes.test.ts` stubs `IncomingMessage`/`ServerResponse` and calls `route` directly —
a real listen on port 0 is not needed and the class exposes no port or `stop()`. Table of
path × method × body → status; 15 mutations, 15 caught.

Two of those 15 only became catchable after the test was made honest:
- a traversal that leads **nowhere** is refused by the file not existing, and proves nothing about
  the guard. Put a real JSON file one directory up and ask for it.
- a route that returns 404 for a missing *session* must also be asked with a real session and a
  missing *task*, or the inner branch is never reached.

## A fixture that starts past the threshold tests none of the thresholds — `2eba92b`

The nudge had one fixture (`quietFleet`) that set `lastActivityAt` 10 minutes back and every
session idle, so every "when" condition was already true before the call. Removing any of them
changed nothing. `parkWhoeverIsIdle` was called by **no test at all**.

`tests/when-the-fleet-is-quiet.test.ts` is a table of the states that mean *not yet*, each
starting before its own condition is met, plus positive rows so refusing everything does not pass.

**It found a guard that could never fire.** `workingInBackground` required
`registry.get(sid)?.status === 'busy'`, and the line above already returns for any busy live
session — and `live()` is everything not stopped, so a busy session is always live. Meanwhile a
background task is exactly what outlives its turn: the session goes idle and the task runs on.
Fixed to ask whether a live session has a non-ambient task.

**Watch for tests that pass for the wrong reason.** The Guardian-is-never-parked test passed
because `__guardian__` starts with `WRAPPER_OWNED_ROLE_PREFIX` and so already had the 15-minute
patience; the fixture's 10 minutes never reached the Guardian branch. Both a mutation and a
reading were needed to see it.

## The three shapes of an untested boundary, in the order they were found

1. **The check is covered, the callers are not** — `fleet-mcp.ts`, fixed by a table of
   tool × authority (`9218900`).
2. **The caller is covered, but nothing ever calls it for real** — `web/server.ts`, fixed by
   asking the router (`a1afc8d`).
3. **The call is covered, but the fixture starts past every condition** — the two timers, fixed by
   a table of *not yet* states (`2eba92b`).

Look for all three when a file reads as well-tested and mutates green.

## Смерть сессии бывает двух сортов, и подметал только один — `6e80020`

Повторил измерение из секции «`supervisor.ts` is large and not tangled» на `f164809`: 2108 строк,
**47 полей, 128 методов**, `registry` — 70, `bus` — 32, остальное по одному-два. Вывод той секции
держится, не перевыводите его снова. Но у неё не хватало главного: «всё остальное по одному-два» —
это **не двадцать спрятанных классов, а двадцать side-таблиц об одной и той же сессии**, и
пятнадцать из них уже ходят через `SessionState`.

Настоящий дефект нашёлся не в связности, а в **терминальном состоянии, в которое ведут два пути**:

- `closeOne` — kill, каскад, дважды провалившийся корень — сбрасывает очередь оператора, сбрасывает
  придержанные отчёты, гасит все три срока жизни и списывает трату (`spending.retire`);
- `noteThatItsLastProcessEnded` — падение, OOM, выход CLI — ставил `stopped` и эмитил событие.
  Всё.

И `closeOne` начинается с `if (rec.status === 'stopped') return`, поэтому уборка **не
откладывалась, а терялась навсегда**. Сообщение оператора исчезало без `humanMessageWithdrawn`,
которое он бы увидел; придержанный отчёт оставался без `heldReportsLost`, на которое его автор
имел право; трата мёртвой сессии числилась за живой колонкой до ближайшего перезапуска. Второй
сорт смерти — ровно тот, ради которого написаны `RootTroubles`, `MemoryWatch` и `capacity.ts`.

Починка — один метод `nothingMoreWillBeHeardFrom(sid)`, который зовут оба пути. Worktree при
падении **намеренно остаётся**: `closeOne` его сносит, потому что конца сессии попросили; падения
не просил никто, и там может лежать незакоммиченное.

**Обобщение, ради которого это стоит помнить:** если в состояние ведут два пути, состояние значит
две разные вещи. Проверка дешёвая — `grep -n "setStatus(" src/` и сгруппировать по значению. На
`f164809`: `stopped` — два входа (теперь сведены), `frozen` — четыре, `idle` — два. Четыре входа в
`frozen` я проверил в тот же день, и там всё честно: `claimEverythingForFreezing` намеренно
оставляет `heldBecause` пустым, а `whatAHoldMeans(undefined)` — это и есть «обычная заморозка»
(держит флот, снимается чем угодно, не переживает перезапуск).

### И одна поправка, которая важнее находки

Воркер, нашедший эту разницу, приложил к ней восьмой пункт: «десять conversation- и
session-жизней переживают смерть процесса». **Это не дефект, а замысел.** Смерть процесса не есть
смерть разговора: припаркованная сессия поднимается тем же разговором, и `theLastContextSeen`,
`compactionAskedFor`, `refusalsBySid` обязаны её пережить. Три срока жизни заведены ровно ради
этой разницы.

Форма ошибки общая и повторяемая: **сравнить два пути, увидеть разную глубину и принять разницу за
дефект, не спросив, не она ли и есть замысел.** Отличать их можно одним вопросом — «доведи
сценарий до того, кому станет плохо». Для `stoppedOnPurpose` цепочка есть (запись живёт вечно,
`whatIsStillHeldAbout` врёт). Для `theLastContextSeen` цепочки нет, потому что сессия вернётся и
показание ей пригодится.

## Две оси в одном поле — `70d3068`

Самая дорогая ложь дня жила в четырёх строках:

```ts
answerOperatorQuestion(id, answer): boolean {
  ...
  this.send(question.askedBy, ...);   // результат выброшен
  return true;                        // всегда
}
```

`send` отказывает остановленной сессии и честно возвращает `false`. Его выбрасывали. Маршрут
превращал `true` в `200 {ok:true}`, панель закрывала задачу, оператор уходил — а ответ, который он
напечатал, не получал никто, и никому об этом не говорилось. **Проверяйте каждое место, где
результат `send` не присвоен переменной:** это единственная функция во флоте, которая возвращает
«не доставлено», и выброшенный `false` выглядит как доставка.

**Вторая половина — про моделирование, и она переиспользуемее самой починки.** У задачи оператору
было поле `status: 'waiting' | 'answered' | 'closed'`. Возник вопрос: что ставить, когда спросивший
умер? Соблазн — четвёртое значение (`'orphaned'`). Это неверно, потому что **спрашиваются две
независимые вещи**: должен ли человек ещё ответить (его сторона) и остался ли кто-то, кто ответ
получит (наша). Они пересекаются во всех четырёх комбинациях, а значит это две оси, а не четыре
значения одной. Стало `status` + `askerEndedAt?`.

Правило, которое стоит проверять при каждом соблазне дописать значение в enum: **перечислите пары.
Если возможны все комбинации — это два поля.** Решение «не закрывать задачу» из того же ряда:
оператор уже согласился её обдумать, и терять единственный вопрос, который человек взял на себя,
из-за падения исполнителя — та же молчаливая потеря, что и выброшенный `false`.

**Решение оператора, задача `1e9347c9`, 22.09.2026: переадресации нет — только пометка.** Ответ
на задачу от умершей сессии никуда не уходит; оператор видит `askerEndedAt` и решает сам. Вариант
«переслать по `reportsTo`» и вариант «пересылать только `blocking`» рассмотрены и отклонены. Не
переоткрывать без него.

То же одной дверью ниже: инцидент, чья сессия-источник умерла, **не снимается** (остальной флот
всё ещё заморожен и всё ещё ждёт суда — снять значило бы освободить всех на основании чужого
падения), но получает `originEndedAt`, событие на шине и строку в баннере.

**И проверка, которая поймала обе декорации:** после каждой такой правки уберите ровно одну строку
— ту, что доносит новый факт до страницы, — и прогоните набор. Поле, о котором никто не читает,
починкой не является. У баннера инцидента строка сначала была именно такой: суффикс в `app.html`
не наблюдался ни одним тестом, и обнаружилось это только мутацией.

## `rootTroubles` — течь без читателя, и почему проверять надо геттер — `bc553d6`

`RootTroubles.failedTurnsBySid` не в `stateBySid`, чистят её только `wentWell(sid)` и
`forgetEverything()`, и замена корня оставляет строку навсегда. **Это не дефект.** Единственный
читатель — `failedTurn(sid)` из `recoverFromFailedTurn` — первой строкой делает
`if (rec?.sid !== this.humanEntryPointSid) return`, а этот геттер строится из `registry.live()`,
откуда остановленная сессия уже ушла. Прочитать накопленное нельзя.

Но свойство, делающее течь безвредной, принадлежит **геттеру**, а не счётчику. Поэтому сторожить
надо геттер: мутация `live()` → `all()` ловится тремя тестами. Записано в
`tests/outliving-the-session.test.ts` — там, где это прочтёт тот, кто соберётся геттер переписать,
а не в отчёте, который никто больше не найдёт.

**Обобщение:** «эта запись живёт вечно» — ещё не находка. Находка — это «её читает вот кто, и вот
что он сделает не так». Если читателя нет, скажите это прямо и застрахуйте **то, из-за чего его
нет**, а не саму запись.
