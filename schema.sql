-- ============================================================
-- Speedrun.com Mini-World
-- MySQL 8.0+
-- Based on Phase 1 requirements, Phase 2 EER (including F1),
-- and Phase 3 Stage A + Stage D relational mapping.
--
-- IMPORTANT:
--   * RUN.status and TICKET.status are intentionally NOT stored.
--     Use RUN_WITH_STATUS and TICKET_WITH_STATUS views.
--   * Derived leaderboard/profile/thread attributes are not stored.
--   * Cross-table business rules listed at the end require
--     transactions/triggers/application validation.
-- ============================================================

DROP DATABASE IF EXISTS speedrun_db;
CREATE DATABASE speedrun_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_0900_ai_ci;
USE speedrun_db;

-- ------------------------------------------------------------
-- 1. Strong entities
-- ------------------------------------------------------------

CREATE TABLE SERIES (
    series_id       BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    series_name     VARCHAR(150) NOT NULL
) ENGINE=InnoDB;

CREATE TABLE PLATFORM (
    platform_id     BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    platform_name   VARCHAR(100) NOT NULL,
    release_year    SMALLINT UNSIGNED NULL,
    CONSTRAINT chk_platform_release_year
        CHECK (release_year IS NULL OR release_year BETWEEN 1970 AND 2100)
) ENGINE=InnoDB;

CREATE TABLE REGION (
    region_id       BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    region_name     VARCHAR(100) NOT NULL
) ENGINE=InnoDB;

CREATE TABLE `USER` (
    user_id         BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    username        VARCHAR(30) NOT NULL,
    email           VARCHAR(254) NOT NULL,
    password_hash   VARCHAR(255) NOT NULL,
    signup_date     DATE NOT NULL,
    last_online     DATETIME NULL,
    site_role       ENUM('user', 'trusted', 'programmer', 'administrator')
                    NOT NULL DEFAULT 'user',
    pronouns        VARCHAR(60) NULL,
    country         VARCHAR(100) NULL,
    subregion       VARCHAR(100) NULL,
    banned_on       DATETIME NULL,

    CONSTRAINT uq_user_username UNIQUE (username),
    CONSTRAINT uq_user_email UNIQUE (email),
    CONSTRAINT chk_username_format
        CHECK (username REGEXP '^[A-Za-z0-9_-]{2,30}$')
) ENGINE=InnoDB;

CREATE TABLE MODERATOR_ROLE (
    role_id         BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    role_name       ENUM('verifier', 'moderator', 'super moderator')
                    NOT NULL,
    CONSTRAINT uq_moderator_role_name UNIQUE (role_name)
) ENGINE=InnoDB;

CREATE TABLE FORUM (
    forum_id        BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    forum_name      VARCHAR(100) NOT NULL,
    CONSTRAINT uq_forum_name UNIQUE (forum_name)
) ENGINE=InnoDB;

CREATE TABLE MEMBERSHIP (
    plan_id         BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    plan_name       VARCHAR(100) NOT NULL,
    monthly_price   DECIMAL(10,2) NOT NULL,
    CONSTRAINT chk_membership_price CHECK (monthly_price >= 0)
) ENGINE=InnoDB;

CREATE TABLE GAME (
    game_id             BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    abbreviation       VARCHAR(30) NOT NULL,
    name_international VARCHAR(200) NOT NULL,
    name_japanese      VARCHAR(200) NULL,
    release_date       DATE NULL,

    show_milliseconds  BOOLEAN NOT NULL DEFAULT FALSE,
    require_video      BOOLEAN NOT NULL DEFAULT FALSE,
    emulators_allowed  BOOLEAN NOT NULL DEFAULT TRUE,
    default_time_type  ENUM('real time', 'real time without loads',
                            'in-game time') NOT NULL,

    -- Phase 3 option (a): at most three time types.
    -- Slot order has no semantic meaning; slot 1 is required
    -- to ensure that the game has at least one time type.
    run_time_type_1    ENUM('real time', 'real time without loads',
                            'in-game time') NOT NULL,
    run_time_type_2    ENUM('real time', 'real time without loads',
                            'in-game time') NULL,
    run_time_type_3    ENUM('real time', 'real time without loads',
                            'in-game time') NULL,

    base_game_id       BIGINT UNSIGNED NULL,
    forum_id           BIGINT UNSIGNED NOT NULL,

    CONSTRAINT uq_game_abbreviation UNIQUE (abbreviation),
    CONSTRAINT uq_game_forum UNIQUE (forum_id),
    CONSTRAINT uq_game_id_game UNIQUE (game_id),
    CONSTRAINT chk_game_abbreviation
        CHECK (abbreviation REGEXP '^[A-Za-z0-9_-]{2,30}$'),
    CONSTRAINT chk_game_not_own_base
        CHECK (base_game_id IS NULL OR base_game_id <> game_id),
    CONSTRAINT chk_game_time_type_2_distinct
        CHECK (run_time_type_2 IS NULL OR run_time_type_2 <> run_time_type_1),
    CONSTRAINT chk_game_time_type_3_distinct
        CHECK (run_time_type_3 IS NULL OR
               (run_time_type_3 <> run_time_type_1 AND
                (run_time_type_2 IS NULL OR run_time_type_3 <> run_time_type_2))),
    CONSTRAINT chk_game_default_time_type
        CHECK (
            default_time_type = run_time_type_1
            OR default_time_type = COALESCE(run_time_type_2, run_time_type_1)
            OR default_time_type = COALESCE(run_time_type_3, run_time_type_1)
        ),
    CONSTRAINT fk_game_base_game
        FOREIGN KEY (base_game_id) REFERENCES GAME(game_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_game_forum
        FOREIGN KEY (forum_id) REFERENCES FORUM(forum_id)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 2. Weak entities
-- ------------------------------------------------------------

CREATE TABLE CATEGORY (
    game_id         BIGINT UNSIGNED NOT NULL,
    category_no     INT UNSIGNED NOT NULL,
    name            VARCHAR(150) NOT NULL,
    type            ENUM('full game', 'per level') NOT NULL,
    rules           TEXT NULL,
    is_misc         BOOLEAN NOT NULL DEFAULT FALSE,

    PRIMARY KEY (game_id, category_no),
    CONSTRAINT fk_category_game
        FOREIGN KEY (game_id) REFERENCES GAME(game_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_category_no CHECK (category_no > 0)
) ENGINE=InnoDB;

CREATE TABLE LEVEL (
    game_id         BIGINT UNSIGNED NOT NULL,
    level_no        INT UNSIGNED NOT NULL,
    name            VARCHAR(150) NOT NULL,
    rules           TEXT NULL,

    PRIMARY KEY (game_id, level_no),
    CONSTRAINT fk_level_game
        FOREIGN KEY (game_id) REFERENCES GAME(game_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_level_no CHECK (level_no > 0)
) ENGINE=InnoDB;

CREATE TABLE THREAD (
    forum_id        BIGINT UNSIGNED NOT NULL,
    thread_code     VARCHAR(30) NOT NULL,
    title           VARCHAR(250) NOT NULL,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_locked       BOOLEAN NOT NULL DEFAULT FALSE,
    starter_id      BIGINT UNSIGNED NOT NULL,

    PRIMARY KEY (forum_id, thread_code),
    CONSTRAINT fk_thread_forum
        FOREIGN KEY (forum_id) REFERENCES FORUM(forum_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_thread_starter
        FOREIGN KEY (starter_id) REFERENCES `USER`(user_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_thread_code CHECK (thread_code REGEXP '^x[0-9]+$')
) ENGINE=InnoDB;

CREATE TABLE REPLY (
    forum_id        BIGINT UNSIGNED NOT NULL,
    thread_code     VARCHAR(30) NOT NULL,
    reply_no        INT UNSIGNED NOT NULL,
    body            TEXT NOT NULL,
    posted_at       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    edited_at       DATETIME NULL,
    author_id       BIGINT UNSIGNED NOT NULL,

    PRIMARY KEY (forum_id, thread_code, reply_no),
    CONSTRAINT fk_reply_thread
        FOREIGN KEY (forum_id, thread_code)
        REFERENCES THREAD(forum_id, thread_code)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_reply_author
        FOREIGN KEY (author_id) REFERENCES `USER`(user_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_reply_no CHECK (reply_no > 0),
    CONSTRAINT chk_reply_edited_at
        CHECK (edited_at IS NULL OR edited_at >= posted_at)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 3. RUN and its LEVEL_RUN specialization
-- ------------------------------------------------------------

CREATE TABLE RUN (
    run_id          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    run_date        DATE NOT NULL,
    submitted_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    decided_on      DATETIME NULL,
    reject_reason   TEXT NULL,
    emulated        BOOLEAN NOT NULL DEFAULT FALSE,
    comment         TEXT NULL,

    game_id         BIGINT UNSIGNED NOT NULL,
    category_no     INT UNSIGNED NOT NULL,
    submitter_id    BIGINT UNSIGNED NOT NULL,
    examiner_id     BIGINT UNSIGNED NULL,
    platform_id     BIGINT UNSIGNED NOT NULL,
    region_id       BIGINT UNSIGNED NULL,

    -- Needed only for the optional same-game LEVEL_RUN composite FK.
    CONSTRAINT uq_run_id_game UNIQUE (run_id, game_id),

    CONSTRAINT fk_run_category
        FOREIGN KEY (game_id, category_no)
        REFERENCES CATEGORY(game_id, category_no)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_run_submitter
        FOREIGN KEY (submitter_id) REFERENCES `USER`(user_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_run_examiner
        FOREIGN KEY (examiner_id) REFERENCES `USER`(user_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_run_platform
        FOREIGN KEY (platform_id) REFERENCES PLATFORM(platform_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_run_region
        FOREIGN KEY (region_id) REFERENCES REGION(region_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    -- Stage D: status is determined by examiner_id/reject_reason
    -- and is exposed through RUN_WITH_STATUS below.
    CONSTRAINT chk_run_decision_date
        CHECK ((examiner_id IS NULL) = (decided_on IS NULL)),
    CONSTRAINT chk_run_reject_reason
        CHECK (reject_reason IS NULL OR examiner_id IS NOT NULL),
    CONSTRAINT chk_run_decision_time
        CHECK (decided_on IS NULL OR decided_on >= submitted_at)
) ENGINE=InnoDB;

CREATE TABLE LEVEL_RUN (
    run_id          BIGINT UNSIGNED PRIMARY KEY,
    game_id         BIGINT UNSIGNED NOT NULL,
    level_no        INT UNSIGNED NOT NULL,

    CONSTRAINT fk_level_run_run
        FOREIGN KEY (run_id, game_id)
        REFERENCES RUN(run_id, game_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_level_run_level
        FOREIGN KEY (game_id, level_no)
        REFERENCES LEVEL(game_id, level_no)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 4. Remaining strong entities
-- ------------------------------------------------------------

CREATE TABLE NEWS_POST (
    news_id         BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    title           VARCHAR(250) NOT NULL,
    body            TEXT NOT NULL,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status          ENUM('pending', 'approved', 'rejected')
                    NOT NULL DEFAULT 'pending',
    approved_at     DATETIME NULL,
    author_id       BIGINT UNSIGNED NOT NULL,
    approver_id     BIGINT UNSIGNED NULL,
    game_id         BIGINT UNSIGNED NULL,

    CONSTRAINT fk_news_author
        FOREIGN KEY (author_id) REFERENCES `USER`(user_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_news_approver
        FOREIGN KEY (approver_id) REFERENCES `USER`(user_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_news_game
        FOREIGN KEY (game_id) REFERENCES GAME(game_id)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT chk_news_approval_fields
        CHECK (
            (status = 'approved' AND approver_id IS NOT NULL AND approved_at IS NOT NULL)
            OR
            (status IN ('pending', 'rejected') AND approver_id IS NULL AND approved_at IS NULL)
        )
) ENGINE=InnoDB;

CREATE TABLE STREAM (
    stream_id       BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    channel_name    VARCHAR(150) NOT NULL,
    service         ENUM('Twitch', 'YouTube') NOT NULL,
    title           VARCHAR(250) NOT NULL,
    game_id         BIGINT UNSIGNED NOT NULL,

    CONSTRAINT fk_stream_game
        FOREIGN KEY (game_id) REFERENCES GAME(game_id)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE TICKET (
    ticket_id       BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    subject         VARCHAR(250) NOT NULL,
    body            TEXT NOT NULL,
    ticket_type     ENUM('bug', 'run report', 'ban appeal', 'other') NOT NULL,
    resolution      ENUM('accepted', 'declined') NULL,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    closed_at       DATETIME NULL,
    raised_by       BIGINT UNSIGNED NOT NULL,
    handler_id      BIGINT UNSIGNED NULL,
    game_id         BIGINT UNSIGNED NULL,
    run_id          BIGINT UNSIGNED NULL,

    CONSTRAINT fk_ticket_raised_by
        FOREIGN KEY (raised_by) REFERENCES `USER`(user_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_ticket_handler
        FOREIGN KEY (handler_id) REFERENCES `USER`(user_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_ticket_game
        FOREIGN KEY (game_id) REFERENCES GAME(game_id)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_ticket_run
        FOREIGN KEY (run_id) REFERENCES RUN(run_id)
        ON DELETE SET NULL ON UPDATE CASCADE,

    -- Phase 3: a run-report ticket obtains its game through RUN.
    CONSTRAINT chk_ticket_game_or_run
        CHECK (game_id IS NULL OR run_id IS NULL),
    CONSTRAINT chk_ticket_run_type
        CHECK (run_id IS NULL OR ticket_type = 'run report'),

    -- Stage D: ticket status is inferred from handler_id/closed_at.
    CONSTRAINT chk_ticket_handler_closed
        CHECK (closed_at IS NULL OR handler_id IS NOT NULL),
    CONSTRAINT chk_ticket_resolution_closed
        CHECK ((closed_at IS NULL) = (resolution IS NULL)),
    CONSTRAINT chk_ticket_closed_time
        CHECK (closed_at IS NULL OR closed_at >= created_at)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 5. Multi-valued attributes (separate relations)
-- ------------------------------------------------------------

CREATE TABLE GAME_GENRE (
    game_id         BIGINT UNSIGNED NOT NULL,
    genre           VARCHAR(100) NOT NULL,
    PRIMARY KEY (game_id, genre),
    CONSTRAINT fk_game_genre_game
        FOREIGN KEY (game_id) REFERENCES GAME(game_id)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE GAME_DEVELOPER (
    game_id         BIGINT UNSIGNED NOT NULL,
    developer       VARCHAR(150) NOT NULL,
    PRIMARY KEY (game_id, developer),
    CONSTRAINT fk_game_developer_game
        FOREIGN KEY (game_id) REFERENCES GAME(game_id)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE GAME_LINK (
    game_id         BIGINT UNSIGNED NOT NULL,
    link            VARCHAR(2048) NOT NULL,
    PRIMARY KEY (game_id, link),
    CONSTRAINT fk_game_link_game
        FOREIGN KEY (game_id) REFERENCES GAME(game_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_game_link_url
        CHECK (link REGEXP '^https?://')
) ENGINE=InnoDB;

CREATE TABLE USER_SOCIAL_LINK (
    user_id         BIGINT UNSIGNED NOT NULL,
    link            VARCHAR(2048) NOT NULL,
    PRIMARY KEY (user_id, link),
    CONSTRAINT fk_user_social_link_user
        FOREIGN KEY (user_id) REFERENCES `USER`(user_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_user_social_link_url
        CHECK (link REGEXP '^https?://')
) ENGINE=InnoDB;

CREATE TABLE RUN_VIDEO_LINK (
    run_id          BIGINT UNSIGNED NOT NULL,
    link            VARCHAR(2048) NOT NULL,
    PRIMARY KEY (run_id, link),
    CONSTRAINT fk_run_video_link_run
        FOREIGN KEY (run_id) REFERENCES RUN(run_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_run_video_link_url
        CHECK (link REGEXP '^https?://')
) ENGINE=InnoDB;

CREATE TABLE RUN_TIME (
    run_id          BIGINT UNSIGNED NOT NULL,
    time_type       ENUM('real time', 'real time without loads',
                         'in-game time') NOT NULL,
    hours           TINYINT UNSIGNED NOT NULL,
    minutes         TINYINT UNSIGNED NOT NULL,
    seconds         TINYINT UNSIGNED NOT NULL,
    milliseconds   SMALLINT UNSIGNED NOT NULL DEFAULT 0,

    PRIMARY KEY (run_id, time_type),
    CONSTRAINT fk_run_time_run
        FOREIGN KEY (run_id) REFERENCES RUN(run_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_run_time_components
        CHECK (hours <= 99 AND minutes <= 59 AND seconds <= 59
               AND milliseconds <= 999),
    CONSTRAINT chk_run_time_positive
        CHECK (hours > 0 OR minutes > 0 OR seconds > 0 OR milliseconds > 0)
) ENGINE=InnoDB;

CREATE TABLE ROLE_PERMISSION (
    role_id         BIGINT UNSIGNED NOT NULL,
    permission      VARCHAR(100) NOT NULL,
    PRIMARY KEY (role_id, permission),
    CONSTRAINT fk_role_permission_role
        FOREIGN KEY (role_id) REFERENCES MODERATOR_ROLE(role_id)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE NEWS_POST_TOPIC (
    news_id         BIGINT UNSIGNED NOT NULL,
    topic           VARCHAR(100) NOT NULL,
    PRIMARY KEY (news_id, topic),
    CONSTRAINT fk_news_topic_post
        FOREIGN KEY (news_id) REFERENCES NEWS_POST(news_id)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 6. Relationship relations
-- ------------------------------------------------------------

CREATE TABLE PART_OF (
    game_id         BIGINT UNSIGNED NOT NULL,
    series_id       BIGINT UNSIGNED NOT NULL,
    PRIMARY KEY (game_id, series_id),
    CONSTRAINT fk_part_of_game
        FOREIGN KEY (game_id) REFERENCES GAME(game_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_part_of_series
        FOREIGN KEY (series_id) REFERENCES SERIES(series_id)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE AVAILABLE_ON (
    game_id         BIGINT UNSIGNED NOT NULL,
    platform_id     BIGINT UNSIGNED NOT NULL,
    PRIMARY KEY (game_id, platform_id),
    CONSTRAINT fk_available_on_game
        FOREIGN KEY (game_id) REFERENCES GAME(game_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_available_on_platform
        FOREIGN KEY (platform_id) REFERENCES PLATFORM(platform_id)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE RELEASED_IN (
    game_id         BIGINT UNSIGNED NOT NULL,
    region_id       BIGINT UNSIGNED NOT NULL,
    PRIMARY KEY (game_id, region_id),
    CONSTRAINT fk_released_in_game
        FOREIGN KEY (game_id) REFERENCES GAME(game_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_released_in_region
        FOREIGN KEY (region_id) REFERENCES REGION(region_id)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE FOLLOWS (
    follower_id     BIGINT UNSIGNED NOT NULL,
    followed_id     BIGINT UNSIGNED NOT NULL,
    PRIMARY KEY (follower_id, followed_id),
    CONSTRAINT fk_follows_follower
        FOREIGN KEY (follower_id) REFERENCES `USER`(user_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_follows_followed
        FOREIGN KEY (followed_id) REFERENCES `USER`(user_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_no_self_follow CHECK (follower_id <> followed_id)
) ENGINE=InnoDB;

CREATE TABLE FOLLOWS_GAME (
    user_id         BIGINT UNSIGNED NOT NULL,
    game_id         BIGINT UNSIGNED NOT NULL,
    last_visit      DATETIME NULL,
    PRIMARY KEY (user_id, game_id),
    CONSTRAINT fk_follows_game_user
        FOREIGN KEY (user_id) REFERENCES `USER`(user_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_follows_game_game
        FOREIGN KEY (game_id) REFERENCES GAME(game_id)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE FEATURES (
    user_id         BIGINT UNSIGNED NOT NULL,
    run_id          BIGINT UNSIGNED NOT NULL,
    featured_order  INT UNSIGNED NOT NULL,
    PRIMARY KEY (user_id, run_id),
    CONSTRAINT uq_featured_order_per_user UNIQUE (user_id, featured_order),
    CONSTRAINT fk_features_user
        FOREIGN KEY (user_id) REFERENCES `USER`(user_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_features_run
        FOREIGN KEY (run_id) REFERENCES RUN(run_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_featured_order CHECK (featured_order > 0)
) ENGINE=InnoDB;

CREATE TABLE MODERATES_GAME (
    user_id         BIGINT UNSIGNED NOT NULL,
    game_id         BIGINT UNSIGNED NOT NULL,
    role_id         BIGINT UNSIGNED NOT NULL,
    since           DATE NOT NULL,
    PRIMARY KEY (user_id, game_id),
    CONSTRAINT fk_moderates_game_user
        FOREIGN KEY (user_id) REFERENCES `USER`(user_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_moderates_game_game
        FOREIGN KEY (game_id) REFERENCES GAME(game_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_moderates_game_role
        FOREIGN KEY (role_id) REFERENCES MODERATOR_ROLE(role_id)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE MODERATES_SERIES (
    user_id         BIGINT UNSIGNED NOT NULL,
    series_id       BIGINT UNSIGNED NOT NULL,
    role_id         BIGINT UNSIGNED NOT NULL,
    since           DATE NOT NULL,
    PRIMARY KEY (user_id, series_id),
    CONSTRAINT fk_moderates_series_user
        FOREIGN KEY (user_id) REFERENCES `USER`(user_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_moderates_series_series
        FOREIGN KEY (series_id) REFERENCES SERIES(series_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_moderates_series_role
        FOREIGN KEY (role_id) REFERENCES MODERATOR_ROLE(role_id)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE PLAYED_BY (
    run_id          BIGINT UNSIGNED NOT NULL,
    user_id         BIGINT UNSIGNED NOT NULL,
    player_order    INT UNSIGNED NOT NULL,
    PRIMARY KEY (run_id, user_id),
    CONSTRAINT uq_player_order_per_run UNIQUE (run_id, player_order),
    CONSTRAINT fk_played_by_run
        FOREIGN KEY (run_id) REFERENCES RUN(run_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_played_by_user
        FOREIGN KEY (user_id) REFERENCES `USER`(user_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_player_order CHECK (player_order > 0)
) ENGINE=InnoDB;

CREATE INDEX idx_played_by_user ON PLAYED_BY(user_id);

CREATE TABLE HOLDS_MEMBERSHIP (
    user_id         BIGINT UNSIGNED NOT NULL,
    plan_id         BIGINT UNSIGNED NOT NULL,
    start_date      DATE NOT NULL,
    end_date        DATE NOT NULL,
    PRIMARY KEY (user_id, plan_id),
    CONSTRAINT fk_holds_membership_user
        FOREIGN KEY (user_id) REFERENCES `USER`(user_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_holds_membership_plan
        FOREIGN KEY (plan_id) REFERENCES MEMBERSHIP(plan_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_membership_dates CHECK (end_date > start_date)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 7. Indexes useful for common lookups and reports
-- ------------------------------------------------------------

CREATE INDEX idx_run_game_category ON RUN(game_id, category_no);
CREATE INDEX idx_run_submitted_at ON RUN(submitted_at);
CREATE INDEX idx_run_examiner ON RUN(examiner_id);
CREATE INDEX idx_run_platform ON RUN(platform_id);
CREATE INDEX idx_run_region ON RUN(region_id);
CREATE INDEX idx_run_date ON RUN(run_date);
CREATE INDEX idx_news_status_created ON NEWS_POST(status, created_at);
CREATE INDEX idx_ticket_handler ON TICKET(handler_id);
CREATE INDEX idx_thread_title ON THREAD(title);
CREATE INDEX idx_reply_author ON REPLY(author_id);

-- ------------------------------------------------------------
-- 8. Stage D views: reconstruct normalized status attributes
-- ------------------------------------------------------------

CREATE OR REPLACE VIEW RUN_WITH_STATUS AS
SELECT
    r.*,
    CASE
        WHEN r.examiner_id IS NULL THEN 'new'
        WHEN r.reject_reason IS NULL THEN 'verified'
        ELSE 'rejected'
    END AS status
FROM RUN AS r;

CREATE OR REPLACE VIEW TICKET_WITH_STATUS AS
SELECT
    t.*,
    CASE
        WHEN t.closed_at IS NOT NULL THEN 'closed'
        WHEN t.handler_id IS NOT NULL THEN 'in progress'
        ELSE 'open'
    END AS status
FROM TICKET AS t;

-- ============================================================
-- BUSINESS RULES THAT NEED TRANSACTIONAL / TRIGGER / APP LOGIC
-- ============================================================
--
-- The following are specified in Phase 1 but cannot all be
-- guaranteed by ordinary foreign keys and row-level CHECKs:
--
-- 1. Every GAME must have at least one AVAILABLE_ON row.
-- 2. RUN.platform_id must be in AVAILABLE_ON for RUN.game_id.
-- 3. RUN.region_id, when supplied, must be in RELEASED_IN for
--    the same game. If a game has regions, the run must provide one.
-- 4. RUN_TIME.time_type must be one of the owning game's time
--    types, and every run must have its game's default time type.
-- 5. RUN must have at least one RUN_TIME row and one PLAYED_BY row.
-- 6. If GAME.require_video = TRUE, a run must have a video link.
--    If GAME.emulators_allowed = FALSE, RUN.emulated must be FALSE.
-- 7. RUN.run_date must not be in the future or before GAME.release_date.
-- 8. A LEVEL_RUN must belong to a CATEGORY whose type is
--    'per level'; a full-game category must not have LEVEL_RUN.
--    The composite FK above ensures its level belongs to the
--    same game as the run's category.
-- 9. The examiner must be a moderator of the run's game at the
--    decision date, directly or through a series containing it.
--    Ban-generated rejection is the administrator exception.
-- 10. A user may feature only their own verified run(s) in which
--     they are a PLAYED_BY participant.
-- 11. A moderator may hold at most one direct role per game and
--     one direct role per series (enforced by the primary keys).
-- 12. A reply cannot be inserted into a locked thread.
-- 13. News approver must be an administrator and must differ
--     from the author. The status CHECK enforces the approval
--     fields, not the administrator/author rule.
-- 14. Banned users cannot submit runs, write news, start threads,
--     post replies, or hold moderator roles; they may raise only
--     ban-appeal tickets.
-- 15. Ticket handlers must be administrators. Ticket status can
--     only move open -> in progress -> closed.
-- 16. A game deletion must be refused if runs exist. Its dependent
--     categories, levels, forum threads/replies, etc. may then be
--     removed according to the project deletion policy.
-- 17. USER deletion is restricted by authored/submitted/history
--     records; banning should be used instead.
-- 18. Run verification/rejection, obsolete-run recalculation,
--     leaderboard places and world records must be handled
--     atomically in a transaction.
--
-- NOTE ON PHASE 2 EVALUATION:
-- Phase 2 flags that moderator-role history is not retained by the
-- original EER design. This schema follows the Phase 3 mapping;
-- it does not add role end dates or a moderation-history table.
-- ============================================================
