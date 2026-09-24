# The panel's new theme — design spec (24.09.2026)

Asked by the operator: "prettier and more solid", then "the new theme first, chat functions after".
Shipped as a theme chosen in Settings, Appearance (per browser, localStorage), next to "Classic",
so he compares both live: sessions cannot render the panel (bind() is denied), he can.

## Principles

1. Colour carries meaning only. The chrome is neutral; the four status hues are reserved for state.
   One brand accent, violet, used sparingly: focus ring, the operator's own bubble, the selected-tab
   indicator, links. Never the only difference between two things a reader compares.
2. Hierarchy by type, space and surface lightness, not by borders.
3. One scale each for spacing, radius, type, elevation and motion. No value outside a scale.
4. Status is never colour alone: a dot plus a word, and an icon for frozen and danger.
5. prefers-reduced-motion switches every animation and transition off.

## Tokens, theme "new" (dark)

Surfaces: --surface-0 #0b0d10 (page, graph canvas) · --surface-1 #111418 (panels, header) ·
--surface-2 #171b21 (cards, bubbles, inputs) · --surface-3 #1e232b (hover, selected, inline code) ·
--surface-4 #262c36 (scrollbar thumb, meter track on surface-3) · --hairline rgba(255,255,255,.07) ·
--hairline-strong rgba(255,255,255,.12).

Text: --text-1 #e8eaef · --text-2 #a4acba · --text-3 #838b9b (meta; must stay ≥ 4.5:1 on
surface-2) · --text-4 #555c6a (placeholder and disabled only).

Accent: --accent #9b8afb, --accent-fg #0b0d10. Links: --text-1 with an accent underline on hover.

Status (validated with the dataviz skill's validator on #111418: adjacent CVD ΔE ≥ 9.5, normal ΔE
≥ 19.7, every hue ≥ 3:1): --status-busy #3ecf8e · --status-starting #4c9dff · --status-frozen
#f0b429 · --status-danger #f2555a · --status-idle #7d8594 · --status-stopped #646c7a.
Tints are derived, never hand-picked: background color-mix(in oklab, <status> 14%, var(--surface-1)),
border 35%. Text on a tint stays --text-1; the dot carries the hue.

Retired: --supervisor gold (3.7 ΔE from frozen) — the supervisor becomes a neutral card with a gear
icon and the word "supervisor". The old accent #7c8cff (1.4 ΔE from starting for deutan).

Type (system sans, SF Pro on a Mac; mono ui-monospace, SF Mono, Menlo): --text-xs 11/16 (meta,
times, units) · --text-sm 12/18 (labels, tags, table cells) · --text-md 13/20 (UI default) ·
--text-lg 14/22 (reading: conversation, question text) · --text-xl 16/24 (panel titles) ·
--text-2xl 20/28 (rare). Weights 400, 500 (labels, buttons), 600 (titles); no 700.
tabular-nums on costs, tokens, percentages, times and counters.

Spacing: 2, 4, 6, 8, 10, 12, 16, 20, 24, 32, 40. Controls 6×10 (small 4×8); cards 12×16;
bubbles 10×16; panel padding 16; section gap 24; list rows 8×12.

Radius: --radius-sm 4 (tags, inline code) · --radius-md 6 (buttons, inputs, icon buttons) ·
--radius-lg 10 (cards, bubbles, thumbnails, popovers) · --radius-xl 14 (lightbox, modals) ·
--radius-full 999 (pills, dots).

Elevation: none at rest. --shadow-1 0 1px 2px rgba(0,0,0,.30) (hovered cards) ·
--shadow-2 0 6px 16px rgba(0,0,0,.35) plus a hairline ring (popovers, toasts) ·
--shadow-3 0 16px 40px rgba(0,0,0,.50) plus a hairline ring (detail panel, lightbox).

Motion: --dur-1 120ms (hover, press) · --dur-2 180ms (small open/close) · --dur-3 280ms (panels) ·
--ease cubic-bezier(.2,.8,.2,1). Busy breathes slowly (2.4s, opacity only); starting keeps a subtle
scan; frozen, danger and idle are still. Edge flow only while messages move.

Focus: :focus-visible outline 2px var(--accent), offset 2px, on everything interactive.

## Components

Buttons, one system: height 32 (small 28), radius-md, text-md 500, 6px gap for icon plus label.
primary = --text-1 fill, --surface-0 text (hover #fff) · secondary = surface-2 plus hairline-strong
(hover surface-3) · ghost = transparent, text-2 (hover surface-3, text-1) · danger = danger tint,
light red text. Icon-only buttons are square. Mapping: .icon-button ghost; .q-send, .auth-action,
#submit primary; .told-actions and .channel-actions buttons secondary; .detail-stop danger small.

Inputs: surface-2, hairline-strong border, radius-md, 6×10, placeholder text-4; focus: accent border
plus a 3px ring of accent at 25%.

Tags: radius-sm, 2×6, text-xs 500, surface-3, text-2. A status chip is a 6px dot plus a word.

Cards (settings rows, questions, integrations): surface-2, hairline, radius-lg, 12×16, no shadow.

Header: 48px, surface-1, hairline below. Left: "silicyte" text-md 600 and the rails commit text-xs
mono text-3. Right: budget meters, fleet controls, questions (with badge), settings.

Meters (context, budget): track 4px radius-full; fill text-2 until a warning threshold, frozen from
there, danger at the stop threshold; a tick at the threshold that matters (50% compaction on context,
the fleet stop on budget); the value text-xs tabular-nums.

Graph: canvas surface-0 with a faint dot grid (1px dots every 24px at rgba(255,255,255,.035)) instead
of the radial blob. Node: surface-2 fill, hairline-strong stroke; a 2px status ring outside it for
busy, starting, frozen and danger; idle has no ring; stopped at 40% opacity. Label: name text-sm 500
text-1; below it model · status as text-xs text-3, so state is never colour alone. Selected: a 2px
text-1 ring and a soft halo — lightness and shape, not hue. Edges 1.5px hairline-strong; flow dashes
text-3. Ghosts: dashed text-4 outline, no fill, label text-3.

Conversation: the session's own text unboxed, text-lg, at most 72ch, with a text-xs text-3 line for
author and time. The operator's messages right-aligned in a bubble: accent 14% tint, accent 30%
border, radius-lg, 10×16, at most 80% wide. Agent-to-agent messages: compact neutral cards with an
arrow icon and the counterpart's name, collapsed as today. Supervisor: neutral card, gear icon, the
word "supervisor", body text-sm text-2. Inline code surface-3, radius-sm, 1×4; code blocks
surface-0, hairline, radius-md, 10×12, mono text-sm, horizontal scroll.

Composer: docked, surface-2, hairline-strong, radius-lg, 8px padding; transparent textarea; a
toolbar row with the paperclip (ghost icon) on the left and send (primary, arrow-up icon) on the right.

Alerts (#alert, #connectors-notice): a surface-2 card with a 3px status bar on the left, an icon and
text-1 text; no saturated full backgrounds.

Scrollbars 8px, surface-4 thumb, transparent track. Empty states: a 24px text-4 icon, a text-md
text-2 title, a text-sm text-3 hint.

Icons: our own inline SVG set, Lucide-style (24 viewBox, 1.75 stroke, round caps, currentColor),
built with createElementNS, replacing every text glyph (▶ ◼ ✉ ☰ ⚙ × ‹ › ▾ ◆ ✕ →) in both themes.

## Classic

A second token set that reproduces today's look as closely as the token model allows (today's hexes,
the #7c8cff accent as the primary fill, 7px cards). Structural fixes — icons, focus rings, reduced
motion, status words, the single button system — apply to both themes.

## Guards (tests)

No colour literal in app.html outside the theme token blocks; every var() used is defined in both
theme blocks; text-3 ≥ 4.5:1 and text-1, text-2 comfortably above it on surface-2; the theme is
applied before first paint (no flash); status never rendered as a colour alone.
