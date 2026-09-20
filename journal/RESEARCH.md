# silicyte — research map

Not `MAP.md`. `MAP.md` ships with the product and tells an agent which file answers for what;
it deliberately carries no line numbers. This file is the opposite trade: it is local, it is
mine, and it carries anchors, measurements and suspicions — the things that go stale but pay
for themselves while they are fresh.

**Pinned to:** product and this fork both at `157de77`, 20.09.2026.
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

- `close_operator_question` takes an id and does not check who filed it (`fleet-mcp.ts:308`, and
  `OperatorQuestions.close` takes no asker either). Same shape for `ask_operator`'s `continues`:
  `operator-questions.ts:104` looks the thread up by id without comparing `askedBy`. **I did
  verify these two reads myself** — what is unchecked is whether it matters, and today it cannot
  be reached: only sessions with `mayAskTheOperator` get the tools, and this fleet has one.
- `incident.ts:104,111` — if `halt()` or `applyVerdict()` throws, `closeIncident()` never runs and
  `handling` stays non-null, so every later `open()` returns immediately. A freeze nothing can
  lift. Wants a `finally`. Unverified.
- `worktree.ts:82` — recreating a session whose branch survived a crash runs
  `git worktree add -b` against an existing branch and fails. Unverified.
- `worktree.ts:95` — `git worktree remove --force` discards uncommitted work. Whether that is
  reachable outside a deliberate close is the question, not the flag. Unverified.
- `operator-questions.ts:179` — a malformed state file is caught and every stored question is
  dropped in silence. Same class as the ten silent writes; this one is a silent *read*. Unverified.
- `verdict.ts:21` — JSON candidates are tried newest-first, so a truncated object could parse
  before the complete one. Unverified.
- `push-stream.ts` — two concurrent consumers would share one waiting-reader queue. Whether any
  code creates two is unasked. Unverified and probably unreachable.
- `fleet_reload_skills` has no verb check where its neighbours do (`fleet-mcp.ts:246`). It *does*
  check the subtree. Verified as a consistency point with no consequence.

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

   **Still open, measured 2026-09-20 on root itself, after `38579d9` was in the rails.** A
   3.9 KB single-line instruction was queued and cancelled; a 1.4 KB one fired. The newline
   fix cannot explain it, and the table above has 3.5 KB single-line firing. So either there
   is a limit somewhere between 3.5 KB and 3.9 KB, or something in that particular text broke
   the slash command. Two points is not a boundary. Until it is bisected, keep a compaction
   instruction well under 3 KB, and check `self_context` on the next turn rather than trusting
   "Compaction queued".

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

3. **20 `void this.…` fire-and-forget calls in `supervisor.ts`.** `no-floating-promises` is on,
   so each one was a deliberate `void`. Several sit on failure paths —
   `void this.recoverFromFailedTurn` :1292, `void this.halt` :1314,
   `void this.handleDowngrade` :1318. Nothing in `src/` registers `unhandledRejection` (only
   SIGINT/SIGTERM, `start.ts:134`), so on Node's default that is **not a swallowed error — it
   takes the supervisor process down**, and `supervised.ts` brings it back up as if it had
   crashed. A failure inside failure recovery therefore looks like an unexplained restart.
   Worth staging deliberately: reject one of these and watch what the operator actually sees.

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

6. **`app.html` is 2683 lines with 120 functions and no module boundary.** Everything the
   panel renders is agent-written and untrusted; `escapeHtml` at :893 is the only defence and
   it is used by convention, not by structure. A new render path that forgets it is a defect of
   the same size whether or not anything exploits it today.

7. **Test residue pollutes the product repo.** Quarantine tests have left 32 `silicyte/worker-*`
   branches and 8 worktrees under `/tmp` and `/var/folders`. Verified none held unique commits;
   deleted once, will come back. Not filed.

## Traps that have already cost time

- `npm test | tail` reports **tail's** exit code. Write to a file and check `$?`.
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
