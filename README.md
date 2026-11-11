# Speedrun.com mini-world – Phase 4

Web app modelled on **speedrun.com** (game leaderboards, run submission and verification, player profiles, forums, news, tickets).

## Stack
- **Paradigm / DBMS:** Relational, MySQL 8.0+ (fill in your exact version: `mysql --version`)
- **Backend:** Python 3 + Flask, PyMySQL driver (raw parameterised SQL only, no ORM)
- **Frontend:** Jinja server-side templates, plain HTML / CSS / JavaScript

## Design Changes
Phase 2 team: `<number>`   Phase 3 team: `<number>`

Fill in every change you made to the Phase 3 schema, one line each with a reason. Example format:
- *(none / e.g.)* Added `X` column to `Y` — needed for feature Z.

Note: the app has no password login. `USER.password_hash` is kept in the schema but the demo uses "Act as a user" (pick any user) to avoid storing real credentials.

## Setup
```bash
# 1. database (from the folder containing schema.sql / populate.sql)
mysql -u root -p < schema.sql
mysql -u root -p < populate.sql

# 2. python deps
python -m venv venv && source venv/bin/activate      # Windows: venv\Scripts\activate
pip install -r requirements.txt

# 3. credentials (or edit config.py)
export DB_USER=root DB_PASSWORD=yourpassword          # Windows: set DB_USER=root
# optional: DB_HOST, DB_PORT, DB_NAME

# 4. run
python app.py        # open http://localhost:5000
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
14. **Edit a reply (W – UPDATE)** – thread page, "Edit" on your own reply.
15. **Post a reply (W – CREATE)** – thread page, reply box. Locked threads and banned users are blocked by triggers.
16. **Delete a reply (W – DELETE)** – thread page, "Delete" on your own reply.
17. **Withdraw a pending run (W – DELETE)** – run page of your own run while status is `new`.
18. **Follow / unfollow a game or a player (W – CREATE / DELETE)** – game page and profile page buttons. Following yourself is blocked by a trigger.
