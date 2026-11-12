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

# populate.sql, part 2 (synthetic supplement)

Appended to `populate.sql` after the scraped part. Regenerate with `python gen_extra.py extra.sql` (fixed seed, deterministic; optional args: number of new users, run scale) and append the output.
**All of this is generated, not scraped.** Tested on MySQL 8.4.3 with every trigger active (loads in about 8 s).

| Added | Notes |
|---|---|
| 4,880 fictional users (ids 121-5000) | 6 administrators, 1 programmer, some `trusted`, 12 banned; random countries, pronouns, signup / last-online dates, social links |
| 40 more games (46 total) | real titles, release dates, platforms, genres, developers and categories (e.g. Super Mario Bros., Super Metroid, Hollow Knight, Elden Ring, Final Fantasy VII, Mario Kart 64/8 Deluxe with per-track levels); 13 new platforms, PAL region, ~20 series, one forum per game |
| ~6,950 runs by fictional players | plausible (not real) times with realistic spread; players with older slower personal bests; ~80 awaiting a decision, ~40 rejected by an admin; second time types (RTA + in-game); video links (fake ids); emulator runs on retro platforms |
| 404 game staff + series moderators, role permissions | fictional staff |
| 152 tickets | open / in progress / closed bug reports, run reports (generated runs only) and ban appeals |
| 450 memberships held (3 plans), 78 streams, 29k follows, 20k game follows, 488 featured runs | plan names/prices approximate; channels fictional |
| ~420 threads, ~2,250 replies, 46 news posts | approved by administrators, plus pending / rejected examples |
| Last-online dates for the 120 real users | only `last_online`; nothing else about real users was changed |

No generated runs, tickets or posts are attributed to real speedrun.com users.
