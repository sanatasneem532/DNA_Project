# Data sources and caveats (populate.sql)

All data comes from public speedrun.com pages, collected 11 Nov 2026. Fandom wiki and indiespeedrun.com were used only for exact world-record dates.

## What is real
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

## Placeholders (not public on the site, but NOT NULL in the schema)
- `USER.email` = `<username>@example.invalid`, `USER.password_hash` = disabled placeholder
- `USER.signup_date` and `MODERATES_GAME.since` = `2014-01-01`
- `run_date`: exact where a source gave it. Otherwise "N years ago" converted from 2026-11-11 (approximate). Stage RTA / Celeste level runs show no date, so they use the observation date 2026-11-11.
- `decided_on` = `submitted_at` (decision time is not shown on tables).
- **Examiner**: the schema requires the verifier to moderate the game. Where the real verifier is shown and is current staff, that person is used. Otherwise a current moderator of that game is used as a stand-in.
- Stage RTA / Celeste level runs: platform not shown on those pages, so N64 / PC are used.
- News bodies are short summaries (not copies). News approver = `Pac` (site founder/staff, set as administrator).
- Thread codes are `x1, x2, ...` because the schema requires the `x<number>` format.

## Not populated (not publicly visible)
Tickets, memberships, streams, follows, game follows, series moderators, role permissions.

## Skipped
Users whose names contain "." (e.g. `bobo.`, `Phoenix.`) because the schema's username CHECK forbids it.

---

# populate_extra.sql (synthetic supplement)

Run after `populate.sql`: `mysql -u root -p < populate_extra.sql`. Regenerate with `python gen_extra.py populate_extra.sql` (fixed seed, deterministic).
**All of this is generated, not scraped**, and tested on MySQL 8.4.3 with the triggers active.

| Added | Notes |
|---|---|
| 880 fictional users (ids 121-1000; `python gen_extra.py out.sql 880`, default 70) | 3 administrators, 1 programmer, some `trusted`, 2 banned; random countries, pronouns, signup/last-online dates, social links |
| 4 games: Super Mario World, Ocarina of Time, Portal, Minecraft: Java | real titles/release dates/platforms/categories; 3 categories each, new platforms (GameCube, 3DS, Wii), PAL region, series, forums |
| ~984 runs by fictional players (82 at the default 70 users) | plausible (not real) times; mix of verified, 4 rejected (by an admin), 4 awaiting verification; multiple time types (Portal), video links (fake ids) |
| Game staff, series moderators, role permissions | fictional staff, `since` 2019-01-01 |
| Tickets (12) | open / in progress / closed, bug, run report, ban appeal; run reports reference only generated runs |
| Memberships, holders, streams, follows, game follows | plan names and prices are approximations; channels are fictional |
| Extra forum threads/replies, news (approved, pending, rejected) | |
| Last-online dates for the 120 real users | only `last_online`; no other real-user data was changed |

No generated runs, tickets or posts are attributed to real speedrun.com users.
