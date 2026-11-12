"""Generates populate_extra.sql (synthetic, deterministic). Usage: python gen_extra.py <out.sql>"""
import random, sys, datetime as dt

random.seed(20261112)
OUT = sys.argv[1]
L = []
def w(s=""): L.append(s)
def q(v):
    if v is None: return "NULL"
    if isinstance(v, bool): return "1" if v else "0"
    if isinstance(v, (int, float)): return str(v)
    return "'" + str(v).replace("\\", "\\\\").replace("'", "''") + "'"
def ins(table, cols, rows):
    if not rows: return
    w(f"INSERT INTO {table} ({', '.join(cols)}) VALUES")
    w(",\n".join("  (" + ", ".join(q(x) for x in r) + ")" for r in rows) + ";")

# ---------------------------------------------------------------- generated users
ADJ = "Swift Pixel Cosmic Frozen Turbo Silent Rapid Golden Crimson Lunar Neon Atomic Misty Rusty Bold Quick Sleepy Lucky Hyper Mellow Cobalt Amber Velvet Stormy Dizzy".split()
NOUN = "Fox Panda Falcon Otter Wizard Ninja Comet Badger Raven Tiger Lynx Gecko Moose Pilot Knight Pirate Robot Yeti Cricket Walrus Heron Goblin Dragon Beetle Koala".split()
COUNTRIES = ["United States","United States","United States","Germany","Japan","Canada","United Kingdom","Brazil","France","Australia","Netherlands","Sweden","Poland","Spain","Mexico","South Korea","Finland","Norway","Italy","India"]
SUBREG = {"United States":["California","Texas","New York","Washington","Ohio"],"Canada":["Ontario","Quebec"],"Germany":["Bavaria","Berlin"],"United Kingdom":["England","Scotland"]}
PRON = [None]*6 + ["he/him","she/her","they/them","he/they","she/they"]

FIRST_NEW_UID = 121
N_NEW = int(sys.argv[2]) if len(sys.argv) > 2 else 70
SCALE = max(1, N_NEW // 70)
names = set()
users = []  # (uid, name, role, country, sub, pron, signup, last_online, banned)
uid = FIRST_NEW_UID
special = {  # uid -> (name, role)
    121: ("SpeedSiteAdmin", "administrator"),
    122: ("RunDeskAdmin", "administrator"),
    123: ("TicketWardenAdmin", "administrator"),
    124: ("BoardCoder", "programmer"),
}
BANNED = {169, 170}
while len(users) < N_NEW:
    if uid in special:
        name, role = special[uid]
    else:
        while True:
            name = random.choice(ADJ) + random.choice(NOUN) + str(random.choice([random.randint(1, 99), ""]) )
            if name.lower() not in names: break
        role = "trusted" if uid % 11 == 0 else "user"
    names.add(name.lower())
    c = random.choice(COUNTRIES)
    sub = random.choice(SUBREG[c]) if c in SUBREG and random.random() < .5 else None
    signup = dt.date(2016, 1, 1) + dt.timedelta(days=random.randint(0, 3400))
    last = dt.datetime(2026, 9, 1) + dt.timedelta(minutes=random.randint(0, 70 * 1440))
    if uid in BANNED: last = dt.datetime(2026, 3, 1) + dt.timedelta(minutes=random.randint(0, 40000))
    banned = dt.datetime(2026, 4, 2, 9, 30) + dt.timedelta(days=uid - 169) if uid in BANNED else None
    users.append((uid, name, role, c, sub, random.choice(PRON), signup, last, banned))
    uid += 1
LAST_UID = uid - 1
ADMINS = [121, 122, 123]
POOL = [u[0] for u in users if u[0] not in BANNED and u[0] not in (121, 122, 123, 124)]  # regular players/mods

w("""-- =====================================================================
-- populate_extra.sql  -  SYNTHETIC supplement to populate.sql (Phase 4)
-- Run AFTER schema.sql and populate.sql:   mysql -u root -p < populate_extra.sql
--
-- Everything here is GENERATED (deterministic seed), not scraped. It models how the live
-- speedrun.com looks: more games + leaderboards, tickets, supporter memberships, live streams,
-- user/game follows, series moderators, role permissions, extra forum/news activity, ban appeals.
-- New usernames are fictional (user_id 121+). No real person is given generated runs/tickets.
-- Times, dates and counts are plausible approximations, NOT real world records.
-- =====================================================================
USE speedrun_db;
SET NAMES utf8mb4;
""")

# ---------------------------------------------------------------- users
w("-- ---------- generated users (fictional)")
ins("`USER`", ["user_id","username","email","password_hash","signup_date","last_online","site_role","pronouns","country","subregion","banned_on"],
    [(u[0], u[1], u[1].lower() + "@example.invalid", "!disabled-placeholder", str(u[6]), str(u[7]), u[2], u[5], u[3], u[4], str(u[8]) if u[8] else None) for u in users])
ins("USER_SOCIAL_LINK", ["user_id","link"],
    [(u[0], f"https://www.twitch.tv/{u[1].lower()}") for u in users if u[0] % 3 == 0 and u[0] not in BANNED] +
    [(u[0], f"https://www.youtube.com/@{u[1].lower()}") for u in users if u[0] % 5 == 0 and u[0] not in BANNED] +
    [(u[0], f"https://twitter.com/{u[1].lower()}") for u in users if u[0] % 7 == 0 and u[0] not in BANNED])
# lightly vary last_online for the real users too (the site shows "last seen"); signup stays placeholder
w("UPDATE `USER` SET last_online = TIMESTAMP('2026-10-01 00:00:00') + INTERVAL ((user_id * 7919) % 40) DAY + INTERVAL ((user_id * 104729) % 1440) MINUTE WHERE user_id <= 120;")

# ---------------------------------------------------------------- lookups
w("\n-- ---------- new platforms / regions / series / forums")
ins("PLATFORM", ["platform_id","platform_name","release_year"], [(11,"GameCube",2001),(12,"3DS",2011),(13,"Wii",2006)])
ins("REGION", ["region_id","region_name"], [(3,"PAL")])
ins("SERIES", ["series_id","series_name"], [(5,"The Legend of Zelda Series"),(6,"Portal Series"),(7,"Minecraft Series")])
ins("FORUM", ["forum_id","forum_name"], [(7,"Super Mario World Forums"),(8,"The Legend of Zelda: Ocarina of Time Forums"),(9,"Portal Forums"),(10,"Minecraft: Java Edition Forums")])

# ---------------------------------------------------------------- games
# (id, abbr, name, jp, release, ms, req_video, emu, default, t1, t2, forum, genres, devs, platforms, regions, series, categories[(no,name,base_s,spread,rules)])
RT, RTNL, IGT = "real time", "real time without loads", "in-game time"
GAMES = [
 dict(id=7, abbr="smw", name="Super Mario World", jp="スーパーマリオワールド", rel="1990-11-21", ms=1, vid=0, emu=1, default=RT, t1=RT, t2=None, forum=7,
      genres=["Platformer"], devs=["Nintendo EAD"], plats=[3, 9, 8], regions=[], series=[1],
      cats=[(1,"Any%",560,.30,"Beat the game via any route. Timing starts on file select and ends on the final input."),
            (2,"96 Exit",2650,.12,"Finish the game having cleared all 96 exits."),
            (3,"11 Exit",1620,.15,"Finish the game using only 11 exits.")],
      plat_for_run=[3, 3, 3, 9, 8], mods=(2, 2, 2), n_runs=(9, 7, 6), ids=None),
 dict(id=8, abbr="oot", name="The Legend of Zelda: Ocarina of Time", jp="ゼルダの伝説 時のオカリナ", rel="1998-11-21", ms=0, vid=1, emu=1, default=RT, t1=RT, t2=None, forum=8,
      genres=["Action-adventure"], devs=["Nintendo EAD"], plats=[1, 11, 13, 9], regions=[1, 2, 3], series=[5],
      cats=[(1,"Any%",1620,.18,"Reach the credits as fast as possible."),
            (2,"100%",12400,.12,"Collect every item, heart piece, and Skulltula token."),
            (3,"Glitchless Any%",11300,.10,"Beat the game without glitches.")],
      plat_for_run=[1, 1, 1, 11, 13, 9], mods=(2, 2, 1), n_runs=(8, 6, 6), ids=None),
 dict(id=9, abbr="portal", name="Portal", jp=None, rel="2007-10-10", ms=1, vid=0, emu=0, default=RTNL, t1=RTNL, t2=RT, forum=9,
      genres=["Puzzle", "First-person"], devs=["Valve"], plats=[2, 8], regions=[], series=[6],
      cats=[(1,"Inbounds",415,.10,"No out-of-bounds glitches. Timing excludes loads."),
            (2,"Out of Bounds",530,.12,"Out-of-bounds glitches allowed. Timing excludes loads."),
            (3,"Glitchless",760,.14,"No glitches of any kind.")],
      plat_for_run=[2, 2, 2, 2, 8], mods=(2, 1, 1), n_runs=(8, 6, 6), ids=None),
 dict(id=10, abbr="mcj", name="Minecraft: Java Edition", jp=None, rel="2011-11-18", ms=1, vid=1, emu=0, default=RT, t1=RT, t2=None, forum=10,
      genres=["Sandbox", "Survival"], devs=["Mojang Studios"], plats=[2], regions=[], series=[7],
      cats=[(1,"Any% Random Seed Glitchless",720,.40,"Defeat the Ender Dragon on a random seed without glitches. Video required."),
            (2,"Any% Set Seed Glitchless",560,.25,"Defeat the Ender Dragon on a fixed seed without glitches. Video required."),
            (3,"All Advancements",19800,.20,"Earn every advancement.")],
      plat_for_run=[2], mods=(2, 2, 1), n_runs=(9, 6, 5), ids=None),
]
w("\n-- ---------- new games")
for g in GAMES:
    ins("GAME", ["game_id","abbreviation","name_international","name_japanese","release_date","show_milliseconds","require_video","emulators_allowed","default_time_type","run_time_type_1","run_time_type_2","forum_id"],
        [(g["id"], g["abbr"], g["name"], g["jp"], g["rel"], g["ms"], g["vid"], g["emu"], g["default"], g["t1"], g["t2"], g["forum"])])
ins("PART_OF", ["game_id","series_id"], [(g["id"], s) for g in GAMES for s in g["series"]])
ins("AVAILABLE_ON", ["game_id","platform_id"], [(g["id"], p) for g in GAMES for p in g["plats"]])
ins("RELEASED_IN", ["game_id","region_id"], [(g["id"], r) for g in GAMES for r in g["regions"]])
ins("GAME_GENRE", ["game_id","genre"], [(g["id"], x) for g in GAMES for x in g["genres"]])
ins("GAME_DEVELOPER", ["game_id","developer"], [(g["id"], x) for g in GAMES for x in g["devs"]])
ins("GAME_LINK", ["game_id","link"], [(g["id"], f"https://www.speedrun.com/{g['abbr']}") for g in GAMES])
ins("CATEGORY", ["game_id","category_no","name","type","rules"], [(g["id"], c[0], c[1], "full game", c[4]) for g in GAMES for c in g["cats"]])

# ---------------------------------------------------------------- staff
w("\n-- ---------- game staff (generated; since = 2019-01-01)")
pool = POOL[:]
random.shuffle(pool)
staff = {}   # game id -> {'all': [...], 'verifiers': ...}
mg_rows = []
for g in GAMES:
    nsm, nm, nv = 1, g["mods"][1], g["mods"][2]
    sm = [pool.pop() for _ in range(nsm)]
    mo = [pool.pop() for _ in range(nm)]
    ve = [pool.pop() for _ in range(nv)]
    staff[g["id"]] = sm + mo + ve
    mg_rows += [(u, g["id"], 3, "2019-01-01") for u in sm] + [(u, g["id"], 2, "2019-01-01") for u in mo] + [(u, g["id"], 1, "2019-01-01") for u in ve]
ins("MODERATES_GAME", ["user_id","game_id","role_id","since"], mg_rows)
# series moderators (real speedrun.com lets series staff moderate every game in the series)
sm_series = {5: pool.pop(), 6: pool.pop(), 7: pool.pop()}
ins("MODERATES_SERIES", ["user_id","series_id","role_id","since"], [(u, s, 3, "2019-01-01") for s, u in sm_series.items()] + [(staff[7][0], 1, 2, "2019-01-01")])
for s, u in sm_series.items():  # series staff also verify games of that series
    pass

# ---------------------------------------------------------------- runs
w("\n-- ---------- runs: inserted unexamined, then verified / rejected (examiner must moderate the game)")
rid = 105
run_rows, pb_rows, rt_rows, vid_rows, upd_verify, upd_reject = [], [], [], [], [], []
video_n = 2000000000
REJECT = ["Run does not meet the category rules.", "Video does not show the full run.", "Timing is wrong: the time on the splits does not match the submission.", "Missing required game audio / input display."]
runs_by_game = {}
for g in GAMES:
    players_pool = [u for u in POOL if u not in staff[g["id"]]]
    gstaff = staff[g["id"]]
    for ci, c in enumerate(g["cats"]):
        base, spread = c[2], c[3]
        n = g["n_runs"][ci] * SCALE
        chosen = random.sample(players_pool, n)
        for k, p in enumerate(chosen):
            secs = base * (1 + spread * (k ** 1.15) / max(n - 1, 1) + random.random() * .01)
            total_ms = int(secs * 1000)
            if not g["ms"]: total_ms = (total_ms // 1000) * 1000
            rdate = dt.date(2021, 1, 1) + dt.timedelta(days=random.randint(0, 1750))
            sub = dt.datetime.combine(rdate, dt.time(random.randint(8, 22), random.randint(0, 59), random.randint(0, 59))) + dt.timedelta(days=random.randint(0, 3))
            status = "verified"
            if k == n - 1 and ci == 0: status = "new"          # newest unexamined run in each game's first category
            if k == n - 2 and ci == 1: status = "rejected"
            if status == "new":
                rdate = dt.date(2026, 11, random.randint(5, 10)); sub = dt.datetime.combine(rdate, dt.time(random.randint(8, 22), random.randint(0, 59), 0))
            plat = random.choice(g["plat_for_run"])
            region = random.choice(g["regions"]) if g["regions"] else None
            emu = 1 if (g["emu"] and plat in (9, 13) and False) else 0
            comment = random.choice([None, None, None, "Not a perfect run but happy with the pace.", "PB! Route finally clicked.", "Good RNG on the middle section.", "New personal best."])
            run_rows.append((rid, str(rdate), str(sub), emu, comment, g["id"], c[0], p, plat, region))
            pb_rows.append((rid, p, 1))
            if random.random() < .08:  # occasional co-op style second player (only for smw)
                if g["abbr"] == "smw":
                    co = random.choice([u for u in players_pool if u != p]); pb_rows.append((rid, co, 2))
            h, rem = divmod(total_ms, 3600000); m, rem = divmod(rem, 60000); s, ms = divmod(rem, 1000)
            rt_rows.append((rid, g["default"], h, m, s, ms))
            if g["t2"] and random.random() < .6:
                tt = int(total_ms * 1.07); h2, rem = divmod(tt, 3600000); m2, rem = divmod(rem, 60000); s2, ms2 = divmod(rem, 1000)
                rt_rows.append((rid, g["t2"], h2, m2, s2, ms2 if g["ms"] else 0))
            video_n += random.randint(1000, 999999)
            vid_rows.append((rid, f"https://www.twitch.tv/videos/{video_n}"))
            if status == "verified":
                ex = random.choice(gstaff); dec = sub + dt.timedelta(hours=random.randint(1, 96))
                upd_verify.append((rid, ex, str(dec)))
            elif status == "rejected":
                dec = sub + dt.timedelta(hours=random.randint(2, 48))
                upd_reject.append((rid, random.choice(ADMINS), str(dec), random.choice(REJECT)))
            runs_by_game.setdefault(g["id"], []).append((rid, p, status))
            rid += 1
ins("RUN", ["run_id","run_date","submitted_at","emulated","comment","game_id","category_no","submitter_id","platform_id","region_id"], run_rows)
ins("PLAYED_BY", ["run_id","user_id","player_order"], pb_rows)
ins("RUN_TIME", ["run_id","time_type","hours","minutes","seconds","milliseconds"], rt_rows)
ins("RUN_VIDEO_LINK", ["run_id","link"], vid_rows)
for r, ex, dec in upd_verify:
    w(f"UPDATE RUN SET examiner_id = {ex}, decided_on = {q(dec)} WHERE run_id = {r};")
for r, ex, dec, why in upd_reject:
    w(f"UPDATE RUN SET examiner_id = {ex}, decided_on = {q(dec)}, reject_reason = {q(why)} WHERE run_id = {r};")

# features: each of a few players features their best verified run
feat = []
seen = set()
for gid, rs in runs_by_game.items():
    for (r, p, st) in rs[:3]:
        if st == "verified" and p not in seen:
            seen.add(p); feat.append((p, r, 1))
ins("FEATURES", ["user_id","run_id","featured_order"], feat)

# ---------------------------------------------------------------- memberships
w("\n-- ---------- supporter memberships (plan names / prices are approximations of speedrun.com's Supporter plans)")
ins("MEMBERSHIP", ["plan_id","plan_name","monthly_price"], [(1,"Supporter",3.00),(2,"Supporter Plus",5.00),(3,"Patron",10.00)])
holders = random.sample(POOL, 14)
ins("HOLDS_MEMBERSHIP", ["user_id","plan_id","start_date","end_date"],
    [(u, random.choice([1, 1, 1, 2, 3]), str(d := dt.date(2025, 6, 1) + dt.timedelta(days=random.randint(0, 400))), str(d + dt.timedelta(days=random.choice([30, 90, 180, 365])))) for u in holders])

# ---------------------------------------------------------------- streams
w("\n-- ---------- live streams (fictional channels)")
streams = []
titles = {1:"{} - 120 Star practice", 2:"Celeste any% grind", 7:"SMW 96 exit attempts", 8:"OoT 100% route work", 9:"Portal OoB practice", 10:"MC random seed glitchless attempts"}
for gid, tmpl in titles.items():
    for k in range(2 if gid in (1, 2, 8, 10) else 1):
        u = random.choice(POOL); nm = next(x[1] for x in users if x[0] == u)
        streams.append((nm.lower(), random.choice(["Twitch", "Twitch", "YouTube"]), tmpl.replace("{}", nm), gid))
ins("STREAM", ["channel_name","service","title","game_id"], streams)

# ---------------------------------------------------------------- follows
w("\n-- ---------- follows (user->user, user->game)")
fol = set()
for u in POOL + ADMINS:
    for _ in range(random.randint(2, 6)):
        t = random.choice(list(range(1, LAST_UID + 1)))
        if t != u and t not in BANNED: fol.add((u, t))
ins("FOLLOWS", ["follower_id","followed_id"], sorted(fol))
fg = set()
for u in range(1, LAST_UID + 1):
    if u in BANNED: continue
    for gid in random.sample(range(1, 11), random.randint(1, 4)): fg.add((u, gid))
ins("FOLLOWS_GAME", ["user_id","game_id","last_visit"],
    [(u, gid, str(dt.datetime(2026, 10, 1) + dt.timedelta(minutes=random.randint(0, 42 * 1440)))) for u, gid in sorted(fg)])

# ---------------------------------------------------------------- role permissions
w("\n-- ---------- moderator role permissions (descriptive)")
ins("ROLE_PERMISSION", ["role_id","permission"],
    [(1,"verify runs"),(1,"view submission queue"),
     (2,"verify runs"),(2,"view submission queue"),(2,"edit categories and levels"),(2,"edit game rules"),(2,"post game news"),(2,"lock forum threads"),
     (3,"verify runs"),(3,"view submission queue"),(3,"edit categories and levels"),(3,"edit game rules"),(3,"post game news"),(3,"lock forum threads"),(3,"manage game moderators"),(3,"edit game settings")])

# ---------------------------------------------------------------- forum activity
w("\n-- ---------- extra threads / replies")
THREADS = {
 1: ["Best route for 70 star?", "Is the 1 Star DDD skip consistent for anyone?", "Splits for 16 star?"],
 2: ["Farewell route help", "Which controller do you use?", "B-side tips thread"],
 7: ["Rules clarification: Small Only", "Beginner tips for 96 Exit", "Best setup for SNES capture?"],
 8: ["Any% Wrong Warp setup question", "Glitchless route changes", "Looking for race partners", "Region differences discussion"],
 9: ["OoB strat help (portal 2 map)", "Why was my run rejected?", "Frame-perfect doors"],
 10: ["Seed pool discussion", "Allowed mods for random seed", "Bastion vs fortress split"],
}
REPL = ["Thanks, that helped a lot!", "I had the same issue last week.", "Check the pinned rules, it's in there.", "+1", "Can confirm, works for me.", "You can ask in the Discord too.", "Good question, I'd like to know as well.", "That route is outdated, try the new one."]
th_rows, rp_rows, locked = [], [], []
counters = {1: 6, 2: 3, 3: 3, 4: 0, 5: 0, 6: 0, 7: 0, 8: 0, 9: 0, 10: 0}
for fid, tts in THREADS.items():
    for t in tts:
        counters[fid] += 1; code = f"x{counters[fid]}"
        st = random.choice(POOL); created = dt.datetime(2025, 1, 1) + dt.timedelta(minutes=random.randint(0, 600 * 1440))
        th_rows.append((fid, code, t, str(created), st))
        for rno in range(1, random.randint(1, 5) + 1):
            posted = created + dt.timedelta(hours=rno * random.randint(1, 30))
            edited = str(posted + dt.timedelta(minutes=random.randint(1, 90))) if random.random() < .15 else None
            rp_rows.append((fid, code, rno, random.choice(REPL), str(posted), edited, random.choice(POOL)))
        if random.random() < .15: locked.append((fid, code))
ins("THREAD", ["forum_id","thread_code","title","created_at","starter_id"], th_rows)
ins("REPLY", ["forum_id","thread_code","reply_no","body","posted_at","edited_at","author_id"], rp_rows)
for fid, code in locked: w(f"UPDATE THREAD SET is_locked = 1 WHERE forum_id = {fid} AND thread_code = {q(code)};")

# ---------------------------------------------------------------- news (approved by generated admins; plus pending/rejected)
w("\n-- ---------- extra news posts")
news = [
 (5,"New category added: 11 Exit","The 11 Exit category is now open for submissions on Super Mario World.","approved",7,"Rules"),
 (6,"Glitchless rules update","Clarified rules about skipping the long cutscenes in Ocarina of Time Glitchless Any%.","approved",8,"Rules"),
 (7,"Portal leaderboard cleanup","Old timing method runs were re-timed to exclude loads.","approved",9,"Leaderboard"),
 (8,"Video now required for Minecraft runs","All Minecraft: Java Edition submissions now require a continuous video.","approved",10,"Videos"),
 (9,"Community tournament announced","A friendly community tournament for Super Mario 64 is being planned.","pending",1,"Community"),
 (10,"Spam post","Buy cheap followers now.","rejected",None,"Other"),
]
for nid, title, body, status, gid, topic in news:
    author = (staff[gid][0] if gid in staff else random.choice(POOL)) if status != "rejected" else random.choice(POOL)
    created = dt.datetime(2026, 5, 1) + dt.timedelta(days=nid * 6)
    appr = ADMINS[nid % 3] if status == "approved" else None
    apt = str(created + dt.timedelta(hours=7)) if status == "approved" else None
    ins("NEWS_POST", ["news_id","title","body","created_at","status","approved_at","author_id","approver_id","game_id"], [(nid, title, body, str(created), status, apt, author, appr, gid)])
    ins("NEWS_POST_TOPIC", ["news_id","topic"], [(nid, topic)])

# ---------------------------------------------------------------- tickets
w("\n-- ---------- tickets (handlers are administrators; run reports only reference generated runs)")
def tk(subject, body, typ, created, handler=None, closed=None, res=None, raised=None, game=None, run=None):
    return (subject, body, typ, res, str(created), str(closed) if closed else None, raised, handler, game, run)
vrun = [r for rs in runs_by_game.values() for (r, p, st) in rs if st == "verified"]
T = []
d0 = dt.datetime(2026, 8, 1, 10)
T.append(tk("Leaderboard page not loading", "The leaderboard for a game times out on mobile.", "bug", d0, 121, d0 + dt.timedelta(days=2), "accepted", random.choice(POOL), None, None))
T.append(tk("Wrong platform shown on run", "The run page lists PC but it was run on console.", "bug", d0 + dt.timedelta(days=3), 122, d0 + dt.timedelta(days=4), "accepted", random.choice(POOL), 7, None))
T.append(tk("Search ignores accented names", "Searching 'Jose' does not return 'José'.", "bug", d0 + dt.timedelta(days=9), 123, None, None, random.choice(POOL), None, None))
T.append(tk("Please add Wii Virtual Console to Ocarina of Time", "Platform list is missing the Wii VC release.", "other", d0 + dt.timedelta(days=12), None, None, None, random.choice(POOL), 8, None))
T.append(tk("Theme request: dark mode toggle", "Could a toggle be added to the profile page?", "other", d0 + dt.timedelta(days=15), 121, d0 + dt.timedelta(days=20), "declined", random.choice(POOL), None, None))
for i, rr in enumerate(random.sample(vrun, 5)):
    c = d0 + dt.timedelta(days=20 + i * 4)
    if i == 0:   T.append(tk("Suspected spliced video", "The video appears to contain a cut near the 5 minute mark.", "run report", c, 122, c + dt.timedelta(days=3), "declined", random.choice(POOL), None, rr))
    elif i == 1: T.append(tk("Incorrect time on run", "Submitted time does not match the video timer.", "run report", c, 123, c + dt.timedelta(days=2), "accepted", random.choice(POOL), None, rr))
    elif i == 2: T.append(tk("Run missing required input display", "The video does not show inputs.", "run report", c, 121, None, None, random.choice(POOL), None, rr))
    else:        T.append(tk("Possible wrong category", "This looks like a different category than listed.", "run report", c, None, None, None, random.choice(POOL), None, rr))
T.append(tk("Ban appeal: sorry for the spam", "I was banned for posting links in the forums. I have read the rules and will not repeat this.", "ban appeal", dt.datetime(2026, 5, 10, 9), 123, dt.datetime(2026, 5, 14, 9), "declined", 169, None, None))
T.append(tk("Ban appeal: wrongly flagged", "I believe my account was flagged by mistake. I only submitted real runs.", "ban appeal", dt.datetime(2026, 9, 20, 9), None, None, None, 170, None, None))
ins("TICKET", ["subject","body","ticket_type","resolution","created_at","closed_at","raised_by","handler_id","game_id","run_id"], T)

with open(OUT, "w", encoding="utf-8", newline="\n") as f:
    f.write("\n".join(L) + "\n")
print("runs:", len(run_rows), "users:", len(users), "tickets:", len(T))
