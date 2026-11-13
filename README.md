# Speedrun.com mini-world – Phase 4

Web app modelled on **speedrun.com** (game leaderboards, run submission and verification, player profiles, forums, news, tickets).

## Stack
- **Paradigm / DBMS:** Relational, MySQL 8.4.3 (schema needs 8.0+; tested end to end on 8.4.3)
- **Backend:** Python 3.13 + Flask 3.x, PyMySQL 1.1 driver (raw parameterised SQL only, no ORM)
- **Frontend:** Jinja server-side templates, hand-written CSS design system (dark/light theme), plain JavaScript

## Design Changes
Phase 2 team: `63`   Phase 3 team: `54`  

- None to the table/column structure of the Phase 3 schema; `schema.sql` is used as received.
- `populate.sql` holds data collected from speedrun.com plus additional rows (46 games, 5,000 users, about 7,000 runs, forums, news, tickets and more) so every feature has data to demonstrate. See the Data section below.

Note: the app has no password login. `USER.password_hash` is kept in the schema but the demo uses "Act as a user" (pick any user) to avoid storing real credentials.

## Setup
```bash
# 1. database (from the src/ folder)
cd src
mysql -u root -p < schema.sql
mysql -u root -p < populate.sql

# 2. python deps
python -m venv venv && source venv/bin/activate      # Windows: venv\Scripts\activate
pip install -r requirements.txt

# 3. credentials (or edit config.py)
export DB_USER=root DB_PASSWORD=yourpassword          # Windows: set DB_USER=root
# optional: DB_HOST, DB_PORT, DB_NAME

# 4. run
python app.py        # (inside src/) open http://localhost:5000
```

## Features (in video order)
Reads = R, writes = W. Click **Act as a user** (top right) before any write.

1. **Search / filter / sort games (R)** – Home `/`. Search box, genre, platform and sort dropdowns. Lists games with verified-run and follower counts.
2. **Latest verified runs (R)** – Home `/`, right column. Newest verified runs with time and players.
3. **Game page + leaderboard (R)** – `/game/<abbr>`. Click a game. Category tabs and (for per-level categories) a level picker. Ranks each player's best verified run using the game's default time type.
4. **Run details (R)** – click any time on a leaderboard, `/run/<id>`. Times, players, video, status, examiner.
5. **Player profile (R)** – `/user/<username>`. Personal bests, featured runs, submissions with status, moderated games, memberships, follower counts.
6. **Player search (R)** – `/players?q=`. Search by name, shows verified-run counts.
7. **Forums, thread search and thread view (R)** – `/forums`, `/forum/<id>?q=`, `/forum/<id>/<code>`.
8. **News by topic (R)** – `/news?topic=`. Approved posts only.
9. **Tickets filter (R)** – `/tickets?status=&type=`. Uses the `TICKET_WITH_STATUS` view.
10. **Statistics (R)** – `/stats`. Top runners, runs per platform, run activity per game (aggregates).
11. **Moderation queue (R)** – `/moderation` (and `?all=1`). Runs awaiting a decision in games the user moderates.
12. **Submit a run (W – CREATE)** – "Submit a run" button or `/submit?game=<abbr>`. One transaction inserts into RUN, PLAYED_BY, RUN_TIME, and optionally RUN_VIDEO_LINK and LEVEL_RUN. Trigger rules (future date, platform, region, emulator, banned user) show as error messages.
13. **Verify / reject a run (W – UPDATE)** – `/moderation` or run page. Sets `examiner_id`, `decided_on`, `reject_reason`. A non-moderator is rejected by the database trigger.
14. **Post a reply (W – CREATE)** – thread page, reply box. Locked threads and banned users are blocked by triggers.
15. **Edit a reply (W – UPDATE)** – thread page, "Edit" on your own reply.
16. **Delete a reply (W – DELETE)** – thread page, "Delete" on your own reply.
17. **Withdraw a pending run (W – DELETE)** – run page of your own run while status is `new`.
18. **Follow / unfollow a game or a player (W – CREATE / DELETE)** – game page and profile page buttons. Following yourself is blocked by a trigger.
19. **Start a forum thread (W – CREATE)** – forum page, "New thread" button (`/forum/<id>/new`). One transaction inserts the THREAD (code `x<next number>`) and its first REPLY. Banned users are blocked by a trigger.
20. **Lock / unlock a thread (W – UPDATE)** – thread page, "Lock thread" / "Unlock thread" button (shown to moderators and super moderators of that game, and to administrators). Sets `THREAD.is_locked`; while locked, the `trg_reply_bi` / `trg_reply_bu` triggers reject new and edited replies.

## Data sources and caveats (src/populate.sql)

All data comes from public speedrun.com pages, collected 11 Nov 2026. Fandom wiki and indiespeedrun.com were used only for exact world-record dates.

### What is real
| Data | Source page(s) |
|---|---|
| 6 games, categories, platforms, series membership | speedrun.com game pages: /sm64, /celeste, /modded_celeste, /celeste_classic_2_mods, /celestesmc, /celestegba |
| 104 runs: players, times, platform, emulator flag, region (where shown) | leaderboard tables, /sm64/levels, /celeste/levels, individual run pages |
| Exact dates for Super Mario 64 world records | indiespeedrun.com (SM64 records), super-mario-64-speedrun.fandom.com (120 Star N64) |
| Verifier for 3 SM64/Celeste runs | individual run pages (LCDAngel99, Vadien, creepcrafting56, Lmjacks) |
| 120 users (username, country, subregion; FlamvellYT pronouns) | leaderboard tables and profiles |
| Staff lists (super moderator / moderator / verifier) per game | "Moderators" section of each game page |
| Forum thread titles and starters (12 threads); 2 replies | each game's "Latest threads" and forum pages |
| 4 news posts (title, author) | /sm64/news, /celeste news listing |
| Featured run (Suigi) | speedrun.com/users/Suigi |
| Release date / genre / developer of Super Mario 64 and Celeste | well-known public facts, not from the leaderboard pages |

### Placeholders (not public on the site, but NOT NULL in the schema)
- `USER.email` = `<username>@example.invalid`, `USER.password_hash` = disabled placeholder
- `USER.signup_date` and `MODERATES_GAME.since` = `2014-01-01`
- `run_date`: exact where a source gave it. Otherwise "N years ago" converted from 2026-11-11 (approximate). Stage RTA / Celeste level runs show no date, so they use the observation date 2026-11-11.
- `decided_on` = `submitted_at` (decision time is not shown on tables).
- **Examiner**: the schema requires the verifier to moderate the game. Where the real verifier is shown and is current staff, that person is used. Otherwise a current moderator of that game is used as a stand-in.
- Stage RTA / Celeste level runs: platform not shown on those pages, so N64 / PC are used.
- News bodies are short summaries (not copies). News approver = `Pac` (site founder/staff, set as administrator).
- Thread codes are `x1, x2, ...` because the schema requires the `x<number>` format.

### Not publicly visible on speedrun.com
Tickets, memberships, streams, follows, game follows, series moderators and role permissions are not shown publicly. They are still populated so that every table in `schema.sql` has rows.

### Skipped
Users whose names contain "." (e.g. `bobo.`, `Phoenix.`) because the schema's username CHECK forbids it.
