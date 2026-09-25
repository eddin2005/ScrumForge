# ScrumForge — optional Supabase backend

There are two apps in this folder:

- **`index.html` — the real work board.** Starts empty; sign in with your name for local mode, or with email once Supabase is connected. This guide is for this file.
- **`index-demo.html` — the class-demo build**, with seeded data and demo identities. It also supports the cloud backend below, but the class demo works fine without it.

With Supabase connected, `index.html` becomes a proper cloud app: real accounts, your data synced across devices in realtime, projects listed per workspace. It takes about 15 minutes.

## 1. Create the project (2 min)

1. https://supabase.com → *Start your project* → sign up (free tier is enough)
2. **New project** → name it `scrumforge` → pick the nearest region → set a database password (you won't need it again after this) → Create

## 2. Run the schema (1 min)

1. Dashboard → **SQL Editor** → **New query**
2. Copy all of `scrumforge/supabase-schema.sql`, paste, **Run**
3. `Success. No rows returned` means the tables, RLS policies, role helper function and realtime publication are in place
4. Then paste all of `scrumforge/supabase-bootstrap.sql` and **Run** it too — this adds the `create_my_workspace` function the app calls on first sign-in (without it, workspace auto-creation can be blocked by RLS ordering)

## 3. Get the keys (1 min)

**Settings → API** — copy two values:

- **Project URL** — looks like `https://abcdefgh.supabase.co`
- **anon public** key — a long `eyJ...` string

## 4. Point the app at it (2 min)

In `scrumforge/index.html`:

1. Paste both keys at the top of the `<script>` section:

```js
const SUPABASE_URL='https://abcdefgh.supabase.co';
const SUPABASE_ANON='eyJhbGciOi...your-anon-key...';
```

2. Just before the closing `</head>` tag, add the Supabase CDN:

```html
<script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>
```

The app also loads this CDN at runtime on its own; the explicit tag is the more reliable of the two on weak Wi-Fi.

3. Save and reload — the auth screen should now say **"Cloud connected ✓"**.

## 5. Create the accounts (3 min)

1. In the app: **Sign up** with a real email → confirm from the inbox → **Sign in**
2. The first sign-up becomes the workspace owner; create the workspace when prompted
3. In another browser or an incognito window, sign up a second account (e.g. `viewer@demo.com`)

## 6. Invite members and assign roles (2 min)

On first sign-in the app creates your workspace automatically and adds you as its owner — nothing to do by hand. Any board you already built in local mode is uploaded as your first project.

To add another person later, run this once in the Supabase **SQL Editor** (they must have signed up first):

```sql
select public.add_member_by_email('<workspace-uuid>', 'friend@email.com', 'developer');
```

You'll find the workspace UUID in the dashboard under Table Editor → `workspaces`. Roles available: `developer`, `scrum_master`, `product_owner`, `admin`, `viewer`.

## 7. Realtime (1 min)

Open the same project on two browsers side by side. Change anything in one; it appears in the other within about a second, with an *"Updated on another device"* toast. That's Supabase Realtime on top of Postgres.

## 8. Deploy (2 min)

Netlify Drop or GitHub Pages as before. The cloud features keep working from the deployed URL: the keys in the file are the client-side anon key, which is designed to be public — the RLS policies are what actually protect the data.

## Troubleshooting

| Symptom | Fix |
|---|---|
| Auth screen says *local demo mode* | Keys pasted correctly? CDN tag added? Hard-refresh (Ctrl+F5) |
| `Failed to fetch` on sign-in | Check the Project URL; free-tier projects pause after inactivity — restore from the dashboard |
| Invite says *no signed-up user with email* | The teammate must sign up first, then get invited |
| Realtime not firing | Re-run the two `alter publication supabase_realtime ...` lines from the schema |
| Viewer still sees edit buttons | They were logged in before the invite — log out and back in |

## If it breaks on demo day

`scrumforge/index.html` falls back to local demo mode on its own whenever the backend is unreachable, so the demo still runs. `scrumforge/index-v1.1-local.html` is the previous single-user build as a last resort.
