"""Speedrun.com mini-world: Flask + PyMySQL (raw parameterised SQL only)."""
import pymysql
from flask import (Flask, render_template, request, redirect, url_for,
                   flash, session, g, abort)

import db
from config import SECRET_KEY

app = Flask(__name__)
app.secret_key = SECRET_KEY


# ---------------------------------------------------------------- helpers
@app.template_filter("ms")
def fmt_ms(total):
    """Milliseconds -> '1h 02m 03s 450ms' (speedrun.com style)."""
    if total is None:
        return "—"
    total = int(total)
    ms, s = total % 1000, (total // 1000) % 60
    m, h = (total // 60000) % 60, total // 3600000
    parts = []
    if h:
        parts.append(f"{h}h")
    if h or m:
        parts.append(f"{m:02d}m" if h else f"{m}m")
    parts.append(f"{s:02d}s" if (h or m) else f"{s}s")
    if ms:
        parts.append(f"{ms:03d}ms")
    return " ".join(parts)


@app.template_filter("dt")
def fmt_dt(value):
    return value.strftime("%d %b %Y, %H:%M") if value else "—"


@app.template_filter("d")
def fmt_d(value):
    return value.strftime("%d %b %Y") if value else "—"


def to_int(value, default=0):
    try:
        return int(value)
    except (TypeError, ValueError):
        return default


def need_login():
    flash("Pick a user first (this demo uses 'act as' instead of passwords).", "error")
    return redirect(url_for("login", next=request.path))


def write_and_redirect(action, ok_msg, target):
    """Run a write callback; show a flash message either way."""
    try:
        result = action()
        flash(ok_msg if result is None or result else "Nothing changed: record not found, already handled, or not yours.",
              "ok" if result is None or result else "error")
    except pymysql.MySQLError as e:
        flash(db.friendly_error(e), "error")
    return redirect(target)


@app.before_request
def load_user():
    g.user = None
    if request.endpoint == "static":
        return
    uid = session.get("uid")
    if uid:
        g.user = db.fetch_one(
            "SELECT user_id, username, site_role, banned_on FROM `USER` WHERE user_id = %s",
            (uid,))
        if g.user is None:
            session.pop("uid", None)


@app.errorhandler(404)
def not_found(_):
    return render_template("404.html"), 404


@app.errorhandler(pymysql.MySQLError)
def db_down(e):
    return render_template("404.html", message=db.friendly_error(e)), 500


# ---------------------------------------------------------------- login (demo "act as")
@app.route("/login", methods=["GET", "POST"])
def login():
    if request.method == "POST":
        uid = to_int(request.form.get("user_id"))
        row = db.fetch_one("SELECT user_id, username FROM `USER` WHERE user_id = %s", (uid,))
        if not row:
            flash("That user does not exist.", "error")
            return redirect(url_for("login"))
        session["uid"] = row["user_id"]
        flash(f"You are now acting as {row['username']}.", "ok")
        nxt = request.form.get("next") or url_for("index")
        return redirect(nxt if nxt.startswith("/") else url_for("index"))
    users = db.fetch_all(
        "SELECT user_id, username, site_role, banned_on FROM `USER` ORDER BY username")
    return render_template("login.html", users=users, next=request.args.get("next", ""))


@app.route("/logout", methods=["POST"])
def logout():
    session.pop("uid", None)
    flash("Logged out.", "ok")
    return redirect(url_for("index"))


# ---------------------------------------------------------------- QUERY 1: game search / filter / sort
GAME_SORTS = {   # fixed ORDER BY fragments: user input only picks a key, never enters SQL
    "name": "g.name_international ASC",
    "runs": "verified_runs DESC, g.name_international ASC",
    "followers": "followers DESC, g.name_international ASC",
    "newest": "g.release_date DESC, g.name_international ASC",
}


@app.route("/")
def index():
    q = request.args.get("q", "").strip()
    genre = request.args.get("genre", "").strip()
    platform_id = to_int(request.args.get("platform"))
    sort = request.args.get("sort", "name")
    order_by = GAME_SORTS.get(sort, GAME_SORTS["name"])

    games = db.fetch_all(
        """
        SELECT g.game_id, g.abbreviation, g.name_international, g.name_japanese,
               g.release_date,
               (SELECT COUNT(*) FROM RUN r
                 WHERE r.game_id = g.game_id
                   AND r.examiner_id IS NOT NULL AND r.reject_reason IS NULL) AS verified_runs,
               (SELECT COUNT(*) FROM FOLLOWS_GAME fg WHERE fg.game_id = g.game_id) AS followers,
               (SELECT GROUP_CONCAT(gg.genre ORDER BY gg.genre SEPARATOR ', ')
                  FROM GAME_GENRE gg WHERE gg.game_id = g.game_id) AS genres
        FROM GAME g
        WHERE (%s = '' OR g.name_international LIKE CONCAT('%%', %s, '%%')
                       OR g.name_japanese      LIKE CONCAT('%%', %s, '%%')
                       OR g.abbreviation       LIKE CONCAT('%%', %s, '%%'))
          AND (%s = '' OR EXISTS (SELECT 1 FROM GAME_GENRE g2
                                   WHERE g2.game_id = g.game_id AND g2.genre = %s))
          AND (%s = 0  OR EXISTS (SELECT 1 FROM AVAILABLE_ON ao
                                   WHERE ao.game_id = g.game_id AND ao.platform_id = %s))
        ORDER BY """ + order_by,
        (q, q, q, q, genre, genre, platform_id, platform_id))

    genres = db.fetch_all("SELECT DISTINCT genre FROM GAME_GENRE ORDER BY genre")
    platforms = db.fetch_all("SELECT platform_id, platform_name FROM PLATFORM ORDER BY platform_name")

    # QUERY 2: latest verified runs (default time type of each game)
    latest = db.fetch_all(
        """
        SELECT r.run_id, r.decided_on, g.abbreviation, g.name_international,
               c.name AS category_name,
               ((rt.hours*60 + rt.minutes)*60 + rt.seconds)*1000 + rt.milliseconds AS total_ms,
               (SELECT GROUP_CONCAT(u.username ORDER BY pb.player_order SEPARATOR ', ')
                  FROM PLAYED_BY pb JOIN `USER` u ON u.user_id = pb.user_id
                 WHERE pb.run_id = r.run_id) AS players
        FROM RUN_WITH_STATUS r
        JOIN GAME g      ON g.game_id = r.game_id
        JOIN CATEGORY c  ON c.game_id = r.game_id AND c.category_no = r.category_no
        JOIN RUN_TIME rt ON rt.run_id = r.run_id AND rt.time_type = g.default_time_type
        WHERE r.status = 'verified'
        ORDER BY r.decided_on DESC
        LIMIT 8
        """)
    return render_template("index.html", games=games, genres=genres, platforms=platforms,
                           latest=latest, q=q, genre=genre, platform_id=platform_id, sort=sort)


# ---------------------------------------------------------------- QUERY 3: game page + leaderboard
LB_HEAD = """
SELECT RANK() OVER (ORDER BY t.total_ms) AS place, t.*
FROM (
  SELECT r.run_id, r.run_date, r.emulated, lead_u.username AS lead_name,
         ((rt.hours*60 + rt.minutes)*60 + rt.seconds)*1000 + rt.milliseconds AS total_ms,
         pl.platform_name,
         (SELECT GROUP_CONCAT(u2.username ORDER BY pb2.player_order SEPARATOR ', ')
            FROM PLAYED_BY pb2 JOIN `USER` u2 ON u2.user_id = pb2.user_id
           WHERE pb2.run_id = r.run_id) AS players,
         ROW_NUMBER() OVER (
             PARTITION BY lead_u.user_id
             ORDER BY ((rt.hours*60 + rt.minutes)*60 + rt.seconds)*1000 + rt.milliseconds,
                      r.run_date, r.run_id) AS rn
  FROM RUN_WITH_STATUS r
  JOIN PLAYED_BY lp   ON lp.run_id = r.run_id AND lp.player_order = 1
  JOIN `USER` lead_u  ON lead_u.user_id = lp.user_id
  JOIN RUN_TIME rt    ON rt.run_id = r.run_id AND rt.time_type = %s
  JOIN PLATFORM pl    ON pl.platform_id = r.platform_id
"""
LB_LEVEL_JOIN = "  JOIN LEVEL_RUN lr ON lr.run_id = r.run_id AND lr.level_no = %s\n"
LB_TAIL = """
  WHERE r.status = 'verified' AND r.game_id = %s AND r.category_no = %s
) t
WHERE t.rn = 1
ORDER BY place, t.run_date
LIMIT 100
"""


@app.route("/game/<abbr>")
def game(abbr):
    gm = db.fetch_one(
        """
        SELECT g.*, f.forum_name, b.name_international AS base_name, b.abbreviation AS base_abbr
        FROM GAME g
        JOIN FORUM f ON f.forum_id = g.forum_id
        LEFT JOIN GAME b ON b.game_id = g.base_game_id
        WHERE g.abbreviation = %s
        """, (abbr,))
    if not gm:
        abort(404)
    gid = gm["game_id"]

    categories = db.fetch_all(
        """SELECT category_no, name, type, rules, is_misc FROM CATEGORY
           WHERE game_id = %s ORDER BY is_misc, type, category_no""", (gid,))
    cat_no = to_int(request.args.get("cat"), categories[0]["category_no"] if categories else 0)
    cur_cat = next((c for c in categories if c["category_no"] == cat_no),
                   categories[0] if categories else None)

    levels, cur_level, board = [], None, []
    if cur_cat:
        if cur_cat["type"] == "per level":
            levels = db.fetch_all(
                "SELECT level_no, name, rules FROM LEVEL WHERE game_id = %s ORDER BY level_no", (gid,))
            lvl_no = to_int(request.args.get("level"), levels[0]["level_no"] if levels else 0)
            cur_level = next((l for l in levels if l["level_no"] == lvl_no),
                             levels[0] if levels else None)
            if cur_level:
                board = db.fetch_all(LB_HEAD + LB_LEVEL_JOIN + LB_TAIL,
                                     (gm["default_time_type"], cur_level["level_no"],
                                      gid, cur_cat["category_no"]))
        else:
            board = db.fetch_all(LB_HEAD + LB_TAIL,
                                 (gm["default_time_type"], gid, cur_cat["category_no"]))

    uid = g.user["user_id"] if g.user else None
    info = {
        "platforms": db.fetch_all(
            """SELECT p.platform_name FROM AVAILABLE_ON a JOIN PLATFORM p ON p.platform_id = a.platform_id
               WHERE a.game_id = %s ORDER BY p.platform_name""", (gid,)),
        "regions": db.fetch_all(
            """SELECT rg.region_name FROM RELEASED_IN ri JOIN REGION rg ON rg.region_id = ri.region_id
               WHERE ri.game_id = %s ORDER BY rg.region_name""", (gid,)),
        "genres": db.fetch_all("SELECT genre FROM GAME_GENRE WHERE game_id = %s ORDER BY genre", (gid,)),
        "developers": db.fetch_all("SELECT developer FROM GAME_DEVELOPER WHERE game_id = %s ORDER BY developer", (gid,)),
        "links": db.fetch_all("SELECT link FROM GAME_LINK WHERE game_id = %s", (gid,)),
        "series": db.fetch_all(
            """SELECT s.series_name FROM PART_OF po JOIN SERIES s ON s.series_id = po.series_id
               WHERE po.game_id = %s""", (gid,)),
        "mods": db.fetch_all(
            """SELECT u.username, mr.role_name, mg.since
               FROM MODERATES_GAME mg
               JOIN `USER` u ON u.user_id = mg.user_id
               JOIN MODERATOR_ROLE mr ON mr.role_id = mg.role_id
               WHERE mg.game_id = %s ORDER BY mr.role_id DESC, u.username""", (gid,)),
        "streams": db.fetch_all(
            "SELECT channel_name, service, title FROM STREAM WHERE game_id = %s", (gid,)),
        "follow": db.fetch_one(
            """SELECT COUNT(*) AS followers, COALESCE(SUM(user_id = %s), 0) AS mine
               FROM FOLLOWS_GAME WHERE game_id = %s""", (uid, gid)),
    }
    return render_template("game.html", gm=gm, categories=categories, cur_cat=cur_cat,
                           levels=levels, cur_level=cur_level, board=board, info=info)


# UPDATE-type: follow / unfollow a game
@app.route("/game/<abbr>/follow", methods=["POST"])
def follow_game(abbr):
    if not g.user:
        return need_login()
    return write_and_redirect(
        lambda: db.execute(
            """INSERT INTO FOLLOWS_GAME (user_id, game_id, last_visit)
               SELECT %s, game_id, NOW() FROM GAME WHERE abbreviation = %s""",
            (g.user["user_id"], abbr)),
        "You now follow this game.", url_for("game", abbr=abbr))


@app.route("/game/<abbr>/unfollow", methods=["POST"])
def unfollow_game(abbr):
    if not g.user:
        return need_login()
    return write_and_redirect(
        lambda: db.execute(
            """DELETE fg FROM FOLLOWS_GAME fg JOIN GAME gm ON gm.game_id = fg.game_id
               WHERE fg.user_id = %s AND gm.abbreviation = %s""",
            (g.user["user_id"], abbr)),
        "You unfollowed this game.", url_for("game", abbr=abbr))


# ---------------------------------------------------------------- QUERY 4: run detail
@app.route("/run/<int:run_id>")
def run_detail(run_id):
    run = db.fetch_one(
        """
        SELECT r.*, g.abbreviation, g.name_international, g.default_time_type,
               c.name AS category_name, c.type AS category_type,
               pl.platform_name, rg.region_name,
               ex.username AS examiner, su.username AS submitter,
               lv.name AS level_name
        FROM RUN_WITH_STATUS r
        JOIN GAME g       ON g.game_id = r.game_id
        JOIN CATEGORY c   ON c.game_id = r.game_id AND c.category_no = r.category_no
        JOIN PLATFORM pl  ON pl.platform_id = r.platform_id
        JOIN `USER` su    ON su.user_id = r.submitter_id
        LEFT JOIN REGION rg      ON rg.region_id = r.region_id
        LEFT JOIN `USER` ex      ON ex.user_id = r.examiner_id
        LEFT JOIN LEVEL_RUN lr   ON lr.run_id = r.run_id
        LEFT JOIN LEVEL lv       ON lv.game_id = lr.game_id AND lv.level_no = lr.level_no
        WHERE r.run_id = %s
        """, (run_id,))
    if not run:
        abort(404)
    players = db.fetch_all(
        """SELECT u.username, pb.player_order FROM PLAYED_BY pb
           JOIN `USER` u ON u.user_id = pb.user_id
           WHERE pb.run_id = %s ORDER BY pb.player_order""", (run_id,))
    times = db.fetch_all(
        """SELECT time_type,
                  ((hours*60 + minutes)*60 + seconds)*1000 + milliseconds AS total_ms
           FROM RUN_TIME WHERE run_id = %s ORDER BY time_type""", (run_id,))
    videos = db.fetch_all("SELECT link FROM RUN_VIDEO_LINK WHERE run_id = %s", (run_id,))
    return render_template("run.html", run=run, players=players, times=times, videos=videos)


# ---------------------------------------------------------------- QUERY 5: player profile
@app.route("/user/<username>")
def user_profile(username):
    u = db.fetch_one(
        """SELECT user_id, username, signup_date, last_online, site_role, pronouns,
                  country, subregion, banned_on
           FROM `USER` WHERE username = %s""", (username,))
    if not u:
        abort(404)
    uid = u["user_id"]
    pbs = db.fetch_all(
        """
        SELECT x.* FROM (
          SELECT r.run_id, g.abbreviation, g.name_international, c.name AS category_name,
                 lv.name AS level_name, r.run_date,
                 ((rt.hours*60 + rt.minutes)*60 + rt.seconds)*1000 + rt.milliseconds AS total_ms,
                 ROW_NUMBER() OVER (
                     PARTITION BY r.game_id, r.category_no, lr.level_no
                     ORDER BY ((rt.hours*60 + rt.minutes)*60 + rt.seconds)*1000 + rt.milliseconds,
                              r.run_date, r.run_id) AS rn
          FROM PLAYED_BY pb
          JOIN RUN_WITH_STATUS r ON r.run_id = pb.run_id AND r.status = 'verified'
          JOIN GAME g       ON g.game_id = r.game_id
          JOIN CATEGORY c   ON c.game_id = r.game_id AND c.category_no = r.category_no
          JOIN RUN_TIME rt  ON rt.run_id = r.run_id AND rt.time_type = g.default_time_type
          LEFT JOIN LEVEL_RUN lr ON lr.run_id = r.run_id
          LEFT JOIN LEVEL lv     ON lv.game_id = lr.game_id AND lv.level_no = lr.level_no
          WHERE pb.user_id = %s
        ) x
        WHERE x.rn = 1
        ORDER BY x.name_international, x.category_name
        """, (uid,))
    featured = db.fetch_all(
        """SELECT f.featured_order, r.run_id, g.abbreviation, g.name_international, c.name AS category_name,
                  ((rt.hours*60 + rt.minutes)*60 + rt.seconds)*1000 + rt.milliseconds AS total_ms
           FROM FEATURES f
           JOIN RUN r        ON r.run_id = f.run_id
           JOIN GAME g       ON g.game_id = r.game_id
           JOIN CATEGORY c   ON c.game_id = r.game_id AND c.category_no = r.category_no
           JOIN RUN_TIME rt  ON rt.run_id = r.run_id AND rt.time_type = g.default_time_type
           WHERE f.user_id = %s ORDER BY f.featured_order""", (uid,))
    submitted = db.fetch_all(
        """SELECT r.run_id, r.submitted_at, r.status, g.abbreviation, g.name_international,
                  c.name AS category_name
           FROM RUN_WITH_STATUS r
           JOIN GAME g     ON g.game_id = r.game_id
           JOIN CATEGORY c ON c.game_id = r.game_id AND c.category_no = r.category_no
           WHERE r.submitter_id = %s ORDER BY r.submitted_at DESC LIMIT 15""", (uid,))
    social = db.fetch_all("SELECT link FROM USER_SOCIAL_LINK WHERE user_id = %s", (uid,))
    mods = db.fetch_all(
        """SELECT g.abbreviation AS slug, g.name_international AS name, mr.role_name
           FROM MODERATES_GAME mg JOIN GAME g ON g.game_id = mg.game_id
           JOIN MODERATOR_ROLE mr ON mr.role_id = mg.role_id
           WHERE mg.user_id = %s ORDER BY g.name_international""", (uid,))
    plans = db.fetch_all(
        """SELECT m.plan_name, h.start_date, h.end_date
           FROM HOLDS_MEMBERSHIP h JOIN MEMBERSHIP m ON m.plan_id = h.plan_id
           WHERE h.user_id = %s AND h.end_date >= CURDATE()""", (uid,))
    me = g.user["user_id"] if g.user else None
    social_counts = db.fetch_one(
        """SELECT (SELECT COUNT(*) FROM FOLLOWS WHERE followed_id = %s) AS followers,
                  (SELECT COUNT(*) FROM FOLLOWS WHERE follower_id = %s) AS following,
                  (SELECT COUNT(*) FROM FOLLOWS WHERE follower_id = %s AND followed_id = %s) AS i_follow""",
        (uid, uid, me, uid))
    return render_template("user.html", u=u, pbs=pbs, featured=featured, submitted=submitted,
                           social=social, mods=mods, plans=plans, sc=social_counts)


@app.route("/user/<username>/follow", methods=["POST"])
def follow_user(username):
    if not g.user:
        return need_login()
    return write_and_redirect(
        lambda: db.execute(
            "INSERT INTO FOLLOWS (follower_id, followed_id) SELECT %s, user_id FROM `USER` WHERE username = %s",
            (g.user["user_id"], username)),
        f"You now follow {username}.", url_for("user_profile", username=username))


@app.route("/user/<username>/unfollow", methods=["POST"])
def unfollow_user(username):
    if not g.user:
        return need_login()
    return write_and_redirect(
        lambda: db.execute(
            """DELETE f FROM FOLLOWS f JOIN `USER` u ON u.user_id = f.followed_id
               WHERE f.follower_id = %s AND u.username = %s""",
            (g.user["user_id"], username)),
        f"You unfollowed {username}.", url_for("user_profile", username=username))


@app.route("/players")
def players():
    q = request.args.get("q", "").strip()
    rows = db.fetch_all(
        """
        SELECT u.username, u.country, u.site_role, u.signup_date, u.banned_on,
               (SELECT COUNT(*) FROM PLAYED_BY pb JOIN RUN r ON r.run_id = pb.run_id
                 WHERE pb.user_id = u.user_id
                   AND r.examiner_id IS NOT NULL AND r.reject_reason IS NULL) AS verified_runs
        FROM `USER` u
        WHERE %s = '' OR u.username LIKE CONCAT('%%', %s, '%%')
        ORDER BY verified_runs DESC, u.username
        LIMIT 100
        """, (q, q))
    return render_template("players.html", rows=rows, q=q)


# ---------------------------------------------------------------- CREATE: submit a run (multi-table transaction)
@app.route("/submit", methods=["GET", "POST"])
def submit_run():
    if not g.user:
        return need_login()
    abbr = request.values.get("game", "").strip()
    games = db.fetch_all("SELECT abbreviation, name_international FROM GAME ORDER BY name_international")
    gm = categories = levels = platforms = regions = None
    if abbr:
        gm = db.fetch_one(
            """SELECT game_id, abbreviation, name_international, require_video,
                      emulators_allowed, default_time_type, release_date
               FROM GAME WHERE abbreviation = %s""", (abbr,))
    if gm:
        gid = gm["game_id"]
        categories = db.fetch_all(
            "SELECT category_no, name, type FROM CATEGORY WHERE game_id = %s ORDER BY is_misc, type, category_no", (gid,))
        levels = db.fetch_all("SELECT level_no, name FROM LEVEL WHERE game_id = %s ORDER BY level_no", (gid,))
        platforms = db.fetch_all(
            """SELECT p.platform_id, p.platform_name FROM AVAILABLE_ON a
               JOIN PLATFORM p ON p.platform_id = a.platform_id
               WHERE a.game_id = %s ORDER BY p.platform_name""", (gid,))
        regions = db.fetch_all(
            """SELECT rg.region_id, rg.region_name FROM RELEASED_IN ri
               JOIN REGION rg ON rg.region_id = ri.region_id
               WHERE ri.game_id = %s ORDER BY rg.region_name""", (gid,))

    if request.method == "POST" and gm:
        f = request.form
        cat_no = to_int(f.get("category_no"))
        cat = next((c for c in categories if c["category_no"] == cat_no), None)
        platform_id = to_int(f.get("platform_id"))
        region_id = to_int(f.get("region_id")) or None
        level_no = to_int(f.get("level_no")) or None
        h, m, s, ms = (to_int(f.get(k)) for k in ("hours", "minutes", "seconds", "milliseconds"))
        video = f.get("video", "").strip()
        run_date = f.get("run_date", "").strip()
        comment = f.get("comment", "").strip() or None
        emulated = 1 if f.get("emulated") else 0

        errors = []
        if not cat:
            errors.append("Choose a category.")
        if not run_date:
            errors.append("Enter the date the run was played.")
        if not platform_id:
            errors.append("Choose a platform.")
        if regions and not region_id:
            errors.append("Choose a region (this game has release regions).")
        if cat and cat["type"] == "per level" and not level_no:
            errors.append("Choose a level for a per-level category.")
        if cat and cat["type"] == "full game":
            level_no = None
        if not (0 <= h <= 99 and 0 <= m <= 59 and 0 <= s <= 59 and 0 <= ms <= 999):
            errors.append("Time out of range (minutes/seconds 0-59, milliseconds 0-999).")
        elif h + m + s + ms == 0:
            errors.append("Time must be greater than zero.")
        if video and not video.lower().startswith(("http://", "https://")):
            errors.append("Video link must start with http:// or https://.")
        if gm["require_video"] and not video:
            errors.append("This game requires a video link.")
        if errors:
            for e in errors:
                flash(e, "error")
        else:
            try:
                with db.transaction() as cur:
                    cur.execute(
                        """INSERT INTO RUN (run_date, emulated, comment, game_id, category_no,
                                            submitter_id, platform_id, region_id)
                           VALUES (%s, %s, %s, %s, %s, %s, %s, %s)""",
                        (run_date, emulated, comment, gm["game_id"], cat_no,
                         g.user["user_id"], platform_id, region_id))
                    run_id = cur.lastrowid
                    cur.execute("INSERT INTO PLAYED_BY (run_id, user_id, player_order) VALUES (%s, %s, 1)",
                                (run_id, g.user["user_id"]))
                    cur.execute(
                        """INSERT INTO RUN_TIME (run_id, time_type, hours, minutes, seconds, milliseconds)
                           VALUES (%s, %s, %s, %s, %s, %s)""",
                        (run_id, gm["default_time_type"], h, m, s, ms))
                    if video:
                        cur.execute("INSERT INTO RUN_VIDEO_LINK (run_id, link) VALUES (%s, %s)", (run_id, video))
                    if level_no:
                        cur.execute("INSERT INTO LEVEL_RUN (run_id, game_id, level_no) VALUES (%s, %s, %s)",
                                    (run_id, gm["game_id"], level_no))
                flash("Run submitted. It is now waiting for a moderator.", "ok")
                return redirect(url_for("run_detail", run_id=run_id))
            except pymysql.MySQLError as e:
                flash(db.friendly_error(e), "error")

    return render_template("submit.html", games=games, gm=gm, categories=categories,
                           levels=levels, platforms=platforms, regions=regions, abbr=abbr)


# ---------------------------------------------------------------- QUERY 6: moderation queue + UPDATE verify/reject
@app.route("/moderation")
def moderation():
    if not g.user:
        return need_login()
    show_all = 1 if request.args.get("all") == "1" else 0
    uid = g.user["user_id"]
    queue = db.fetch_all(
        """
        SELECT r.run_id, r.submitted_at, r.run_date, r.emulated, r.comment,
               g.abbreviation, g.name_international, c.name AS category_name,
               ((rt.hours*60 + rt.minutes)*60 + rt.seconds)*1000 + rt.milliseconds AS total_ms,
               (SELECT GROUP_CONCAT(u.username ORDER BY pb.player_order SEPARATOR ', ')
                  FROM PLAYED_BY pb JOIN `USER` u ON u.user_id = pb.user_id
                 WHERE pb.run_id = r.run_id) AS players,
               (SELECT COUNT(*) FROM RUN_VIDEO_LINK v WHERE v.run_id = r.run_id) AS videos
        FROM RUN_WITH_STATUS r
        JOIN GAME g      ON g.game_id = r.game_id
        JOIN CATEGORY c  ON c.game_id = r.game_id AND c.category_no = r.category_no
        LEFT JOIN RUN_TIME rt ON rt.run_id = r.run_id AND rt.time_type = g.default_time_type
        WHERE r.status = 'new'
          AND (%s = 1
               OR EXISTS (SELECT 1 FROM MODERATES_GAME mg
                           WHERE mg.user_id = %s AND mg.game_id = r.game_id)
               OR EXISTS (SELECT 1 FROM MODERATES_SERIES ms
                            JOIN PART_OF po ON po.series_id = ms.series_id
                           WHERE ms.user_id = %s AND po.game_id = r.game_id))
        ORDER BY r.submitted_at
        """, (show_all, uid, uid))
    return render_template("moderation.html", queue=queue, show_all=show_all)


@app.route("/run/<int:run_id>/verify", methods=["POST"])
def verify_run(run_id):
    if not g.user:
        return need_login()
    return write_and_redirect(
        lambda: db.execute(
            """UPDATE RUN SET examiner_id = %s, decided_on = NOW(), reject_reason = NULL
               WHERE run_id = %s AND examiner_id IS NULL""",
            (g.user["user_id"], run_id)),
        f"Run #{run_id} verified.", request.referrer or url_for("moderation"))


@app.route("/run/<int:run_id>/reject", methods=["POST"])
def reject_run(run_id):
    if not g.user:
        return need_login()
    reason = request.form.get("reason", "").strip()
    if not reason:
        flash("A rejection needs a reason.", "error")
        return redirect(request.referrer or url_for("moderation"))
    return write_and_redirect(
        lambda: db.execute(
            """UPDATE RUN SET examiner_id = %s, decided_on = NOW(), reject_reason = %s
               WHERE run_id = %s AND examiner_id IS NULL""",
            (g.user["user_id"], reason, run_id)),
        f"Run #{run_id} rejected.", request.referrer or url_for("moderation"))


# DELETE: withdraw your own run while it is still waiting
@app.route("/run/<int:run_id>/delete", methods=["POST"])
def delete_run(run_id):
    if not g.user:
        return need_login()
    return write_and_redirect(
        lambda: db.execute(
            "DELETE FROM RUN WHERE run_id = %s AND submitter_id = %s AND examiner_id IS NULL",
            (run_id, g.user["user_id"])),
        f"Run #{run_id} withdrawn.", url_for("user_profile", username=g.user["username"]))


# ---------------------------------------------------------------- QUERY 7: forums
@app.route("/forums")
def forums():
    rows = db.fetch_all(
        """
        SELECT f.forum_id, f.forum_name, gm.abbreviation, COUNT(t.thread_code) AS threads
        FROM FORUM f
        LEFT JOIN GAME gm ON gm.forum_id = f.forum_id
        LEFT JOIN THREAD t ON t.forum_id = f.forum_id
        GROUP BY f.forum_id, f.forum_name, gm.abbreviation
        ORDER BY f.forum_name
        """)
    return render_template("forums.html", rows=rows)


@app.route("/forum/<int:forum_id>")
def forum(forum_id):
    fm = db.fetch_one("SELECT forum_id, forum_name FROM FORUM WHERE forum_id = %s", (forum_id,))
    if not fm:
        abort(404)
    q = request.args.get("q", "").strip()
    threads = db.fetch_all(
        """
        SELECT t.thread_code, t.title, t.created_at, t.is_locked, u.username AS starter,
               COUNT(rp.reply_no) AS replies, MAX(rp.posted_at) AS last_reply
        FROM THREAD t
        JOIN `USER` u ON u.user_id = t.starter_id
        LEFT JOIN REPLY rp ON rp.forum_id = t.forum_id AND rp.thread_code = t.thread_code
        WHERE t.forum_id = %s AND (%s = '' OR t.title LIKE CONCAT('%%', %s, '%%'))
        GROUP BY t.forum_id, t.thread_code, t.title, t.created_at, t.is_locked, u.username
        ORDER BY COALESCE(MAX(rp.posted_at), t.created_at) DESC
        """, (forum_id, q, q))
    return render_template("forum.html", fm=fm, threads=threads, q=q)


@app.route("/forum/<int:forum_id>/<thread_code>")
def thread(forum_id, thread_code):
    th = db.fetch_one(
        """SELECT t.forum_id, t.thread_code, t.title, t.created_at, t.is_locked,
                  u.username AS starter, f.forum_name
           FROM THREAD t JOIN `USER` u ON u.user_id = t.starter_id
           JOIN FORUM f ON f.forum_id = t.forum_id
           WHERE t.forum_id = %s AND t.thread_code = %s""", (forum_id, thread_code))
    if not th:
        abort(404)
    replies = db.fetch_all(
        """SELECT rp.reply_no, rp.body, rp.posted_at, rp.edited_at, rp.author_id, u.username
           FROM REPLY rp JOIN `USER` u ON u.user_id = rp.author_id
           WHERE rp.forum_id = %s AND rp.thread_code = %s ORDER BY rp.reply_no""",
        (forum_id, thread_code))
    return render_template("thread.html", th=th, replies=replies)


# CREATE: post a reply (next reply_no computed inside a transaction)
@app.route("/forum/<int:forum_id>/<thread_code>/reply", methods=["POST"])
def post_reply(forum_id, thread_code):
    if not g.user:
        return need_login()
    body = request.form.get("body", "").strip()
    target = url_for("thread", forum_id=forum_id, thread_code=thread_code)
    if not body:
        flash("A reply cannot be empty.", "error")
        return redirect(target)
    try:
        with db.transaction() as cur:
            cur.execute(
                """SELECT COALESCE(MAX(reply_no), 0) + 1 AS nxt FROM REPLY
                   WHERE forum_id = %s AND thread_code = %s FOR UPDATE""", (forum_id, thread_code))
            nxt = cur.fetchone()["nxt"]
            cur.execute(
                """INSERT INTO REPLY (forum_id, thread_code, reply_no, body, author_id)
                   VALUES (%s, %s, %s, %s, %s)""",
                (forum_id, thread_code, nxt, body, g.user["user_id"]))
        flash("Reply posted.", "ok")
    except pymysql.MySQLError as e:
        flash(db.friendly_error(e), "error")
    return redirect(target)


# UPDATE: edit your own reply
@app.route("/forum/<int:forum_id>/<thread_code>/reply/<int:reply_no>/edit", methods=["POST"])
def edit_reply(forum_id, thread_code, reply_no):
    if not g.user:
        return need_login()
    body = request.form.get("body", "").strip()
    target = url_for("thread", forum_id=forum_id, thread_code=thread_code)
    if not body:
        flash("A reply cannot be empty.", "error")
        return redirect(target)
    return write_and_redirect(
        lambda: db.execute(
            """UPDATE REPLY SET body = %s, edited_at = NOW()
               WHERE forum_id = %s AND thread_code = %s AND reply_no = %s AND author_id = %s""",
            (body, forum_id, thread_code, reply_no, g.user["user_id"])),
        "Reply updated.", target)


# DELETE: delete your own reply
@app.route("/forum/<int:forum_id>/<thread_code>/reply/<int:reply_no>/delete", methods=["POST"])
def delete_reply(forum_id, thread_code, reply_no):
    if not g.user:
        return need_login()
    return write_and_redirect(
        lambda: db.execute(
            """DELETE FROM REPLY
               WHERE forum_id = %s AND thread_code = %s AND reply_no = %s AND author_id = %s""",
            (forum_id, thread_code, reply_no, g.user["user_id"])),
        "Reply deleted.", url_for("thread", forum_id=forum_id, thread_code=thread_code))


# ---------------------------------------------------------------- QUERY 8: news
@app.route("/news")
def news():
    topic = request.args.get("topic", "").strip()
    posts = db.fetch_all(
        """
        SELECT n.news_id, n.title, n.body, n.approved_at, au.username AS author,
               gm.name_international AS game_name, gm.abbreviation,
               (SELECT GROUP_CONCAT(nt.topic ORDER BY nt.topic SEPARATOR ',')
                  FROM NEWS_POST_TOPIC nt WHERE nt.news_id = n.news_id) AS topics
        FROM NEWS_POST n
        JOIN `USER` au ON au.user_id = n.author_id
        LEFT JOIN GAME gm ON gm.game_id = n.game_id
        WHERE n.status = 'approved'
          AND (%s = '' OR EXISTS (SELECT 1 FROM NEWS_POST_TOPIC t2
                                   WHERE t2.news_id = n.news_id AND t2.topic = %s))
        ORDER BY n.approved_at DESC
        """, (topic, topic))
    topics = db.fetch_all(
        """SELECT DISTINCT nt.topic FROM NEWS_POST_TOPIC nt
           JOIN NEWS_POST n ON n.news_id = nt.news_id AND n.status = 'approved'
           ORDER BY nt.topic""")
    return render_template("news.html", posts=posts, topics=topics, topic=topic)


# ---------------------------------------------------------------- QUERY 9: tickets
@app.route("/tickets")
def tickets():
    status = request.args.get("status", "").strip()
    ttype = request.args.get("type", "").strip()
    rows = db.fetch_all(
        """
        SELECT t.ticket_id, t.subject, t.ticket_type, t.status, t.resolution,
               t.created_at, t.closed_at, ru.username AS raised_by, h.username AS handler
        FROM TICKET_WITH_STATUS t
        JOIN `USER` ru ON ru.user_id = t.raised_by
        LEFT JOIN `USER` h ON h.user_id = t.handler_id
        WHERE (%s = '' OR t.status = %s) AND (%s = '' OR t.ticket_type = %s)
        ORDER BY t.created_at DESC
        """, (status, status, ttype, ttype))
    return render_template("tickets.html", rows=rows, status=status, ttype=ttype)


# ---------------------------------------------------------------- QUERY 10: statistics (aggregates)
@app.route("/stats")
def stats():
    top_runners = db.fetch_all(
        """
        SELECT u.username, u.country, COUNT(*) AS verified_runs,
               COUNT(DISTINCT r.game_id) AS games_played
        FROM PLAYED_BY pb
        JOIN RUN_WITH_STATUS r ON r.run_id = pb.run_id AND r.status = 'verified'
        JOIN `USER` u ON u.user_id = pb.user_id
        GROUP BY u.user_id, u.username, u.country
        ORDER BY verified_runs DESC, games_played DESC, u.username
        LIMIT 10
        """)
    platform_usage = db.fetch_all(
        """
        SELECT p.platform_name, COUNT(*) AS runs,
               SUM(r.emulated) AS emulated_runs
        FROM RUN_WITH_STATUS r JOIN PLATFORM p ON p.platform_id = r.platform_id
        WHERE r.status = 'verified'
        GROUP BY p.platform_id, p.platform_name
        ORDER BY runs DESC
        """)
    game_activity = db.fetch_all(
        """
        SELECT gm.abbreviation, gm.name_international,
               SUM(r.status = 'verified') AS verified,
               SUM(r.status = 'new')      AS waiting,
               SUM(r.status = 'rejected') AS rejected,
               COUNT(*) AS total
        FROM RUN_WITH_STATUS r JOIN GAME gm ON gm.game_id = r.game_id
        GROUP BY gm.game_id, gm.abbreviation, gm.name_international
        HAVING COUNT(*) >= 1
        ORDER BY total DESC, gm.name_international
        """)
    return render_template("stats.html", top_runners=top_runners,
                           platform_usage=platform_usage, game_activity=game_activity)


if __name__ == "__main__":
    app.run(debug=True, port=5000)
