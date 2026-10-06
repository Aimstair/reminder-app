# Product Decisions

Decisions that shape scope, design, and specs. Change them deliberately — each lists what it affects.

| # | Decision | Value | Decided |
|---|---|---|---|
| D1 | Monetization | **Free for now** | 2026-10-05 |
| D2 | App name | **"Reminder App"** (working name) | 2026-10-05 |
| D3 | Launch market & language | **English, global** | 2026-10-05 |
| D4 | v1.0 success focus | **Reliability & retention** | 2026-10-05 |
| D5 | Market strategy | **Consumer launch first, enterprise later** | 2026-10-06 |

---

## D1 — Monetization: free for now

**Implications**
- No paywall, purchase, or subscription flows in v1.0 – v1.2 specs or designs.
- **Keep the option open:** every cloud feature (sync, backup, email, LLM parsing) sits behind one `isFeatureEnabled(feature)` check so it can be gated later without refactoring.
- **Avoid future backlash:** if paid tiers are likely, label cloud features "Free during early access" from v1.1 onward. Never take away a feature that already runs on-device for free.
- **Control server costs** (from v1.1) without revenue: hard caps per user — LLM parses/day, emails/day — and an overall monthly budget alert.

**Revisit when:** before v1.1 ships (cloud costs start), or at 1,000 active users.

## D2 — App name: "Reminder App" (working name)

**Implications**
- Used in specs, code, and internal builds.
- **A final name is needed before the Play Store listing (end of v1.0).** "Reminder App" is generic: hard to find in search, impossible to trademark, and likely to collide with existing listings.
- Code identifiers use a neutral package ID that won't need renaming (e.g. `app.aimstair.reminders`).

**Revisit when:** before the closed beta (v1.0).

## D3 — English, global

**Implications**
- Parser supports English only, with both date orders:
  - Day/month order follows the device locale (`5/10` = 5 Oct in en-GB, May 10 in en-US)
  - Unambiguous forms always work regardless of locale: "Oct 5", "5 Oct", "October 5th", "2026-10-05"
- 12h vs 24h display follows the device setting; parser accepts both ("6pm", "18:00").
- Week start (Mon/Sun) follows the device locale.
- Business-day rules use Mon–Fri; **public holidays are not considered** in v1.
- All UI strings go through a translation layer from day one (no hard-coded strings), so adding languages later is cheap.

## D4 — Success focus: reliability & retention

**v1.0 metrics and targets**

| Metric | Target | How measured |
|---|---|---|
| Alert delivery (fired within 1 min of scheduled time) | ≥ 99.5% | On-device log of scheduled vs. fired time, reported in aggregate |
| Crash-free sessions | ≥ 99.5% | Crash reporting |
| Day-30 retention | Baseline in beta, then set target | Analytics |
| Reminders created per active user per week | Baseline in beta | Analytics |
| Median capture time (open capture → saved) | < 3 s | Analytics |
| Notification action rate (Done/Snooze from notification vs. ignored) | Baseline in beta | Analytics |

**Implications**
- Privacy-respecting analytics from v1.0: event counts and timings only, **never reminder content**.
- Reliability work (alarm spike, device matrix) takes priority over feature breadth when they conflict.

## D5 — Consumer launch first, enterprise later

The long-term goal is an enterprise-grade product, but v1–v3 launch to consumers (personal + professional individuals). Enterprise features come after the consumer product is proven (ROADMAP "v4 — Enterprise").

**Implications now (cheap to do early, expensive to retrofit):**
- **Design stays professional:** calm Things 3 style; the gamified direction (XP, streaks, levels) was explored and rejected because it doesn't fit enterprise buyers (`design-direction.md` DS10).
- **Data model is workspace-ready:** every synced record can later carry a `workspace_id` (personal workspace by default) — v1.1 sync design must not assume one user = one data set forever.
- **Backend choice (v1.1)** must support later: SSO (SAML/OIDC), organizations/teams, role-based access, audit logs, and regional data hosting. Pick a provider that offers these or can add them.
- **No content leaves the device in v1.0** — keeps the privacy story clean for future security reviews.
- **Web matters more for enterprise** (admin console, desktop use) — keep the v3 Flutter Web decision under review with that in mind.
- **Pricing (D1):** free for consumers for now; enterprise will be per-seat — keep `isFeatureEnabled()` gating so plans can be added without refactoring.

**Revisit when:** v2 ships, or earlier if a company asks to use it for a team.
