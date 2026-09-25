# ScrumForge — presentation notes

My notes for tomorrow's class demo. The app is `scrumforge/index-demo.html` — one file, runs offline in demo mode, complete with the seeded sprint history, demo identities and the "the tool built itself" story. (The plain `index.html` is now a clean personal work board with no demo data — use that one for real work, not for the class demo.) If I got the Supabase backend set up (see `scrumforge/BACKEND-SETUP.md`) there's a cloud mode too, but the demo works fine without it. Last-resort fallback: `scrumforge/index-v1.1-local.html`.

## The point I want to land

We built a Scrum tool *with* Scrum. The sprint history, burndown and velocity in the app aren't sample data — they're the record of actually building the tool, sprint by sprint. If someone asks what the project is, that's the answer.

## Demo order (about 6 minutes)

1. **Sign in / roles** — Log in as Awa Nkeng (owner). Mention there are six roles and that permissions are checked on every action, not just hidden in the UI.
2. **Workspaces** — Top bar: switch Forge Labs → Acme Logistics. A user can belong to several workspaces; each has its own projects. Show the project templates (Scrum / Kanban / Scrumban) while I'm here.
3. **Vision** — About view → product vision card. Backlog comes from a vision; the rest of the roadmap hangs off it.
4. **Backlog & hierarchy** — Product backlog: MoSCoW priorities, story points. Then the Hierarchy view: epics → stories → tasks and subtasks.
5. **Sprint planning** — Sprints view. Sprint 3 committed 23 points and finished 20, and the spillover is right there on the chart. Good moment to say planning is an estimate, not a promise.
6. **Board** — Drag one card To Do → Done. Mention the WIP limit on In Progress.
7. **Role enforcement** — Switch account to Bello (viewer). Try to drag: the app refuses, buttons disappear. The mutation is blocked in code, not just hidden with CSS.
8. **Reports** — Burndown and velocity. This is where the "we managed the build with the build" story shows up in data.
9. **Roadmap** — Release 2 backlog, estimated and prioritised. Billing is marked Won't have — for now, which usually gets a small laugh and is honest.
10. **Close** — About → sprint timeline. One sentence to end on: the tool delivered itself.

## If the cloud mode is set up

Three things, in this order, then move on:

- Two browsers side by side: drag a card in one, it moves in the other within a second. That's Supabase realtime.
- Invite a teammate by email from Workspace Admin, pick their role.
- One sentence on security: permissions are enforced by Postgres row-level security policies, so hiding a button isn't the security boundary.

If the venue Wi-Fi is shaky, skip this section entirely — the local mode tells the same Scrum story.

## Questions I should be ready for

- **What happens to unfinished sprint work?** Closing a sprint returns unfinished stories to the backlog. I can show it live by closing Sprint 6.
- **Who decides priority?** The product owner orders the backlog; the team estimates in points. Separation of *what* from *how much*.
- **Isn't this just a to-do list?** Timeboxes, sprint goals, ceremonies with tracked actions, and metrics that feed the next planning — that loop is the Scrum part.
- **What's real and what's demo?** Honest answer: locally, the login identities are simulated; with Supabase configured, accounts, roles and sync are real. Both modes ship in the same file.
- **Why story points?** Relative size, recalibrated every sprint against actual velocity — visible in Reports.
- **How did you handle scope?** Release 1 is the core Scrum loop; everything else is sized and prioritised in the Release 2 roadmap instead of half-built.

## Numbers (re-check in Reports before presenting)

| | |
|---|---|
| Sprints | 6 (5 done, 1 active) |
| Items | 40 (27 delivered + 13 roadmap) |
| Average velocity | 17.4 points |
| Roles | 6 |
| Views | 11 |

## Getting it online

- **Netlify Drop:** drag the `scrumforge` folder onto app.netlify.com/drop — live URL in under a minute.
- **GitHub Pages:** push, then Settings → Pages → deploy from main.
- **No internet at the venue:** open the file directly. Local mode is fully offline and is what I'll rehearse anyway.

## ScrumForge has two files now

- **index-demo.html** — the class-demo app (fake team, sprint history, demo identities). Nothing was changed in it; it's exactly what I rehearsed.
- **index.html** — my actual work board (starts empty, real sign-in, light/dark). This is the "and I actually use it" bonus point if someone asks.

- [ ] Sign in as owner, **Reset demo data** once so the numbers match the table above
- [ ] Confirm I'm opening **index-demo.html**, not the clean personal board (index.html) — they look similar at a glance
- [ ] Run through the demo order once out loud, including the viewer switch
- [ ] Cloud configured: test sign-up, one invite and two-browser sync once. Not configured: skip it, don't improvise on stage
- [ ] Export the sprint report as PDF (Reports → print) — that's the hand-in
- [ ] Fullscreen, and check the light theme is legible on the projector
