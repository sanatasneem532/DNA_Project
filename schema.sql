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
  -- supports English, Indian languages, special symbols, and emojis
  -- can store characters requiring up to 4 bytes
  CHARACTER SET utf8mb4
  -- defines how strings are compared and sorted in the database
  -- Uses the utf8mb4 character set
  -- Based on Unicode Collation Algorithm version 9.0
  -- Accent-insensitive  ->  SELECT 'cafe' = 'café'; is TRUE 
  -- Case-insensitive ->  SELECT 'Hello' = 'hello'; is TRUE
  COLLATE utf8mb4_0900_ai_ci;

USE speedrun_db;

-- SET @DEBUG = 1;
-- DELIMITER //
-- CREATE PROCEDURE DEBUG(IN msg VARCHAR(500))
-- BEGIN
--     IF @DEBUG = 1 THEN
--         SELECT CONCAT('[DEBUG] ', msg) AS '';
--     END IF;
-- END //

-- DELIMITER ;
-- CALL DEBUG('speedrun_db created successfully');
-- CALL DEBUG('Starting database schema creation');

-- ------------------------------------------------------------
-- 1. Strong entities
-- ------------------------------------------------------------

CREATE TABLE SERIES (
    series_id       BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    series_name     VARCHAR(150) NOT NULL
-- Supports transactions (COMMIT, ROLLBACK), foreign keys
-- Uses row-level locking
-- Provides crash recovery
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
        ON DELETE SET NULL ON UPDATE CASCADE
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

    -- Stage D: ticket status is inferred from handler_id/closed_at.
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
    link            VARCHAR(500) NOT NULL,
    PRIMARY KEY (game_id, link),
    CONSTRAINT fk_game_link_game
        FOREIGN KEY (game_id) REFERENCES GAME(game_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_game_link_url
        CHECK (link REGEXP '^https?://')
) ENGINE=InnoDB;

CREATE TABLE USER_SOCIAL_LINK (
    user_id         BIGINT UNSIGNED NOT NULL,
    link            VARCHAR(500) NOT NULL,
    PRIMARY KEY (user_id, link),
    CONSTRAINT fk_user_social_link_user
        FOREIGN KEY (user_id) REFERENCES `USER`(user_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_user_social_link_url
        CHECK (link REGEXP '^https?://')
) ENGINE=InnoDB;

CREATE TABLE RUN_VIDEO_LINK (
    run_id          BIGINT UNSIGNED NOT NULL,
    link            VARCHAR(500) NOT NULL,
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
        ON DELETE CASCADE ON UPDATE CASCADE
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
-- 9. MySQL 9.7-compatible business-rule triggers
-- ============================================================
-- MySQL 9.7 rejects CHECK constraints that reference columns which
-- also participate in foreign keys having referential actions.
-- Those rules are implemented below as triggers instead.
--
-- IMPORTANT LIMITATION:
-- MySQL has no deferred constraint triggers. Rules that require
-- multiple child rows (e.g. every GAME must have AVAILABLE_ON rows,
-- every RUN must have RUN_TIME and PLAYED_BY rows) are checked at
-- the point where the operation becomes meaningful (e.g. before a
-- run is verified), and must also be validated by the application
-- before committing a newly-created game/run workflow.
-- ============================================================

DELIMITER $$

-- ------------------------------------------------------------
-- GAME rules
-- ------------------------------------------------------------

CREATE TRIGGER trg_game_bi
BEFORE INSERT ON GAME
FOR EACH ROW
BEGIN
    IF NEW.base_game_id IS NOT NULL
       AND NEW.base_game_id = NEW.game_id THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'A game cannot be its own base game';
    END IF;
END$$

CREATE TRIGGER trg_game_bu
BEFORE UPDATE ON GAME
FOR EACH ROW
BEGIN
    IF NEW.base_game_id IS NOT NULL
       AND NEW.base_game_id = NEW.game_id THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'A game cannot be its own base game';
    END IF;
END$$

-- A game must retain at least one available platform.
CREATE TRIGGER trg_available_on_bd
BEFORE DELETE ON AVAILABLE_ON
FOR EACH ROW
BEGIN
    IF (SELECT COUNT(*) FROM AVAILABLE_ON
        WHERE game_id = OLD.game_id) <= 1 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'A game must have at least one available platform';
    END IF;
END$$

-- ------------------------------------------------------------
-- USER / social rules
-- ------------------------------------------------------------

CREATE TRIGGER trg_follows_bi
BEFORE INSERT ON FOLLOWS
FOR EACH ROW
BEGIN
    IF NEW.follower_id = NEW.followed_id THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'A user cannot follow themselves';
    END IF;
END$$

CREATE TRIGGER trg_follows_bu
BEFORE UPDATE ON FOLLOWS
FOR EACH ROW
BEGIN
    IF NEW.follower_id = NEW.followed_id THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'A user cannot follow themselves';
    END IF;
END$$

-- ------------------------------------------------------------
-- RUN rules
-- ------------------------------------------------------------

CREATE TRIGGER trg_run_bi
BEFORE INSERT ON RUN
FOR EACH ROW
BEGIN
    DECLARE v_release_date DATE;
    DECLARE v_available INT DEFAULT 0;
    DECLARE v_region_count INT DEFAULT 0;
    DECLARE v_region_match INT DEFAULT 0;
    DECLARE v_emulators_allowed BOOLEAN;

    SELECT release_date, emulators_allowed
      INTO v_release_date, v_emulators_allowed
      FROM GAME WHERE game_id = NEW.game_id;

    SELECT COUNT(*) INTO v_available
      FROM AVAILABLE_ON
     WHERE game_id = NEW.game_id
       AND platform_id = NEW.platform_id;

    IF v_available = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Run platform is not available for this game';
    END IF;

    SELECT COUNT(*) INTO v_region_count
      FROM RELEASED_IN WHERE game_id = NEW.game_id;

    IF v_region_count > 0 THEN
        IF NEW.region_id IS NULL THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'A region is required for this game';
        END IF;
        SELECT COUNT(*) INTO v_region_match
          FROM RELEASED_IN
         WHERE game_id = NEW.game_id AND region_id = NEW.region_id;
        IF v_region_match = 0 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Run region is not a release region for this game';
        END IF;
    END IF;

    IF NEW.run_date > CURRENT_DATE() THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Run date cannot be in the future';
    END IF;

    IF v_release_date IS NOT NULL AND NEW.run_date < v_release_date THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Run date cannot precede game release date';
    END IF;

    IF NEW.emulated = TRUE AND v_emulators_allowed = FALSE THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Emulators are not allowed for this game';
    END IF;

    IF EXISTS (SELECT 1 FROM `USER`
               WHERE user_id = NEW.submitter_id AND banned_on IS NOT NULL) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Banned users cannot submit runs';
    END IF;

    IF (NEW.examiner_id IS NULL) <> (NEW.decided_on IS NULL) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Examiner and decision timestamp must be supplied together';
    END IF;

    IF NEW.examiner_id IS NULL AND NEW.reject_reason IS NOT NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'A run cannot have a rejection reason before examination';
    END IF;

    IF NEW.examiner_id IS NOT NULL THEN
        IF NEW.reject_reason IS NOT NULL THEN
            IF NOT EXISTS (
                SELECT 1 FROM `USER`
                 WHERE user_id = NEW.examiner_id
                   AND site_role = 'administrator'
            ) THEN
                SIGNAL SQLSTATE '45000'
                    SET MESSAGE_TEXT = 'Only an administrator may reject by ban exception';
            END IF;
        ELSEIF NOT (
            EXISTS (
                SELECT 1 FROM MODERATES_GAME mg
                 WHERE mg.user_id = NEW.examiner_id
                   AND mg.game_id = NEW.game_id
                   AND mg.since <= DATE(NEW.decided_on)
            )
            OR EXISTS (
                SELECT 1
                  FROM MODERATES_SERIES ms
                  JOIN PART_OF po ON po.series_id = ms.series_id
                 WHERE ms.user_id = NEW.examiner_id
                   AND po.game_id = NEW.game_id
                   AND ms.since <= DATE(NEW.decided_on)
            )
        ) THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Examiner must moderate this game or one of its series';
        END IF;

        IF NOT EXISTS (SELECT 1 FROM PLAYED_BY pb WHERE pb.run_id = NEW.run_id)
           AND NEW.run_id IS NOT NULL THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'A run needs at least one player before examination';
        END IF;
    END IF;
END$$

CREATE TRIGGER trg_run_bu
BEFORE UPDATE ON RUN
FOR EACH ROW
BEGIN
    DECLARE v_release_date DATE;
    DECLARE v_available INT DEFAULT 0;
    DECLARE v_region_count INT DEFAULT 0;
    DECLARE v_region_match INT DEFAULT 0;
    DECLARE v_emulators_allowed BOOLEAN;

    SELECT release_date, emulators_allowed
      INTO v_release_date, v_emulators_allowed
      FROM GAME WHERE game_id = NEW.game_id;

    SELECT COUNT(*) INTO v_available
      FROM AVAILABLE_ON
     WHERE game_id = NEW.game_id AND platform_id = NEW.platform_id;

    IF v_available = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Run platform is not available for this game';
    END IF;

    SELECT COUNT(*) INTO v_region_count
      FROM RELEASED_IN WHERE game_id = NEW.game_id;

    IF v_region_count > 0 THEN
        IF NEW.region_id IS NULL THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'A region is required for this game';
        END IF;
        SELECT COUNT(*) INTO v_region_match
          FROM RELEASED_IN
         WHERE game_id = NEW.game_id AND region_id = NEW.region_id;
        IF v_region_match = 0 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Run region is not a release region for this game';
        END IF;
    END IF;

    IF NEW.run_date > CURRENT_DATE()
       OR (v_release_date IS NOT NULL AND NEW.run_date < v_release_date) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Run date must be between game release date and today';
    END IF;

    IF NEW.emulated = TRUE AND v_emulators_allowed = FALSE THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Emulators are not allowed for this game';
    END IF;

    IF EXISTS (SELECT 1 FROM `USER`
               WHERE user_id = NEW.submitter_id AND banned_on IS NOT NULL) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Banned users cannot submit runs';
    END IF;

    IF (NEW.examiner_id IS NULL) <> (NEW.decided_on IS NULL) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Examiner and decision timestamp must be supplied together';
    END IF;

    IF NEW.examiner_id IS NULL AND NEW.reject_reason IS NOT NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'A run cannot have a rejection reason before examination';
    END IF;

    IF NEW.examiner_id IS NOT NULL THEN
        IF NOT EXISTS (SELECT 1 FROM RUN_TIME rt WHERE rt.run_id = OLD.run_id) THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'A run needs at least one time before examination';
        END IF;
        IF NOT EXISTS (SELECT 1 FROM PLAYED_BY pb WHERE pb.run_id = OLD.run_id) THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'A run needs at least one player before examination';
        END IF;
        IF EXISTS (
            SELECT 1 FROM GAME g
             WHERE g.game_id = NEW.game_id AND g.require_video = TRUE
        ) AND NOT EXISTS (
            SELECT 1 FROM RUN_VIDEO_LINK rv WHERE rv.run_id = OLD.run_id
        ) THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'This game requires a run video';
        END IF;

        IF NEW.reject_reason IS NOT NULL THEN
            IF NOT EXISTS (SELECT 1 FROM `USER`
                           WHERE user_id = NEW.examiner_id
                             AND site_role = 'administrator') THEN
                SIGNAL SQLSTATE '45000'
                    SET MESSAGE_TEXT = 'Only an administrator may reject by ban exception';
            END IF;
        ELSEIF NOT (
            EXISTS (SELECT 1 FROM MODERATES_GAME mg
                    WHERE mg.user_id = NEW.examiner_id
                      AND mg.game_id = NEW.game_id
                      AND mg.since <= DATE(NEW.decided_on))
            OR EXISTS (
                SELECT 1 FROM MODERATES_SERIES ms
                JOIN PART_OF po ON po.series_id = ms.series_id
                WHERE ms.user_id = NEW.examiner_id
                  AND po.game_id = NEW.game_id
                  AND ms.since <= DATE(NEW.decided_on)
            )
        ) THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Examiner must moderate this game or one of its series';
        END IF;
    END IF;
END$$

-- A RUN_TIME must use a time type configured for its game.
CREATE TRIGGER trg_run_time_bi
BEFORE INSERT ON RUN_TIME
FOR EACH ROW
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM RUN r JOIN GAME g ON g.game_id = r.game_id
         WHERE r.run_id = NEW.run_id
           AND NEW.time_type IN (g.run_time_type_1,
                                 g.run_time_type_2,
                                 g.run_time_type_3)
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Time type is not configured for this game';
    END IF;
END$$

CREATE TRIGGER trg_run_time_bu
BEFORE UPDATE ON RUN_TIME
FOR EACH ROW
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM RUN r JOIN GAME g ON g.game_id = r.game_id
         WHERE r.run_id = NEW.run_id
           AND NEW.time_type IN (g.run_time_type_1,
                                 g.run_time_type_2,
                                 g.run_time_type_3)
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Time type is not configured for this game';
    END IF;
END$$

-- ------------------------------------------------------------
-- LEVEL_RUN specialization rule
-- ------------------------------------------------------------

CREATE TRIGGER trg_level_run_bi
BEFORE INSERT ON LEVEL_RUN
FOR EACH ROW
BEGIN
    IF NOT EXISTS (
        SELECT 1
          FROM RUN r
          JOIN CATEGORY c
            ON c.game_id = r.game_id AND c.category_no = r.category_no
         WHERE r.run_id = NEW.run_id AND c.type = 'per level'
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'LEVEL_RUN is allowed only for per-level categories';
    END IF;
END$$

CREATE TRIGGER trg_level_run_bu
BEFORE UPDATE ON LEVEL_RUN
FOR EACH ROW
BEGIN
    IF NOT EXISTS (
        SELECT 1
          FROM RUN r
          JOIN CATEGORY c
            ON c.game_id = r.game_id AND c.category_no = r.category_no
         WHERE r.run_id = NEW.run_id AND c.type = 'per level'
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'LEVEL_RUN is allowed only for per-level categories';
    END IF;
END$$

-- ------------------------------------------------------------
-- Banned-user and forum rules
-- ------------------------------------------------------------

CREATE TRIGGER trg_thread_bi
BEFORE INSERT ON THREAD
FOR EACH ROW
BEGIN
    IF EXISTS (SELECT 1 FROM `USER`
               WHERE user_id = NEW.starter_id AND banned_on IS NOT NULL) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Banned users cannot start threads';
    END IF;
END$$

CREATE TRIGGER trg_reply_bi
BEFORE INSERT ON REPLY
FOR EACH ROW
BEGIN
    IF EXISTS (SELECT 1 FROM `USER`
               WHERE user_id = NEW.author_id AND banned_on IS NOT NULL) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Banned users cannot post replies';
    END IF;
    IF EXISTS (SELECT 1 FROM THREAD
               WHERE forum_id = NEW.forum_id
                 AND thread_code = NEW.thread_code
                 AND is_locked = TRUE) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cannot reply to a locked thread';
    END IF;
END$$

CREATE TRIGGER trg_reply_bu
BEFORE UPDATE ON REPLY
FOR EACH ROW
BEGIN
    IF EXISTS (SELECT 1 FROM THREAD
               WHERE forum_id = NEW.forum_id
                 AND thread_code = NEW.thread_code
                 AND is_locked = TRUE) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cannot edit a reply in a locked thread';
    END IF;
END$$

-- ------------------------------------------------------------
-- NEWS rules
-- ------------------------------------------------------------

CREATE TRIGGER trg_news_post_bi
BEFORE INSERT ON NEWS_POST
FOR EACH ROW
BEGIN
    IF EXISTS (SELECT 1 FROM `USER`
               WHERE user_id = NEW.author_id AND banned_on IS NOT NULL) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Banned users cannot write news';
    END IF;

    IF NEW.status = 'approved' THEN
        IF NEW.approver_id IS NULL OR NEW.approved_at IS NULL THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Approved news requires approver and approval timestamp';
        END IF;
        IF NOT EXISTS (SELECT 1 FROM `USER`
                       WHERE user_id = NEW.approver_id
                         AND site_role = 'administrator') THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'News approver must be an administrator';
        END IF;
        IF NEW.approver_id = NEW.author_id THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'News author cannot approve their own post';
        END IF;
    ELSEIF NEW.approver_id IS NOT NULL OR NEW.approved_at IS NOT NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Pending/rejected news cannot have approval fields';
    END IF;
END$$

CREATE TRIGGER trg_news_post_bu
BEFORE UPDATE ON NEWS_POST
FOR EACH ROW
BEGIN
    IF NEW.status = 'approved' THEN
        IF NEW.approver_id IS NULL OR NEW.approved_at IS NULL THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Approved news requires approver and approval timestamp';
        END IF;
        IF NOT EXISTS (SELECT 1 FROM `USER`
                       WHERE user_id = NEW.approver_id
                         AND site_role = 'administrator') THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'News approver must be an administrator';
        END IF;
        IF NEW.approver_id = NEW.author_id THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'News author cannot approve their own post';
        END IF;
    ELSEIF NEW.approver_id IS NOT NULL OR NEW.approved_at IS NOT NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Pending/rejected news cannot have approval fields';
    END IF;
END$$

-- ------------------------------------------------------------
-- TICKET rules (replaces CHECKs that conflict with FK actions)
-- ------------------------------------------------------------

CREATE TRIGGER trg_ticket_bi
BEFORE INSERT ON TICKET
FOR EACH ROW
BEGIN
    IF NEW.game_id IS NOT NULL AND NEW.run_id IS NOT NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'A ticket cannot reference both a game and a run';
    END IF;
    IF NEW.run_id IS NOT NULL AND NEW.ticket_type <> 'run report' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Only run-report tickets may reference a run';
    END IF;
    IF NEW.closed_at IS NOT NULL AND NEW.handler_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'A closed ticket must have a handler';
    END IF;
    IF (NEW.closed_at IS NULL) <> (NEW.resolution IS NULL) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Ticket resolution and closed_at must be set together';
    END IF;
    IF NEW.closed_at IS NOT NULL AND NEW.closed_at < NEW.created_at THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Ticket cannot be closed before it was created';
    END IF;
    IF NEW.handler_id IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM `USER`
         WHERE user_id = NEW.handler_id AND site_role = 'administrator'
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Ticket handler must be an administrator';
    END IF;
    IF EXISTS (SELECT 1 FROM `USER`
               WHERE user_id = NEW.raised_by AND banned_on IS NOT NULL)
       AND NEW.ticket_type <> 'ban appeal' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Banned users may raise only ban-appeal tickets';
    END IF;
END$$

CREATE TRIGGER trg_ticket_bu
BEFORE UPDATE ON TICKET
FOR EACH ROW
BEGIN
    IF NEW.game_id IS NOT NULL AND NEW.run_id IS NOT NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'A ticket cannot reference both a game and a run';
    END IF;
    IF NEW.run_id IS NOT NULL AND NEW.ticket_type <> 'run report' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Only run-report tickets may reference a run';
    END IF;
    IF NEW.closed_at IS NOT NULL AND NEW.handler_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'A closed ticket must have a handler';
    END IF;
    IF (NEW.closed_at IS NULL) <> (NEW.resolution IS NULL) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Ticket resolution and closed_at must be set together';
    END IF;
    IF NEW.closed_at IS NOT NULL AND NEW.closed_at < NEW.created_at THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Ticket cannot be closed before it was created';
    END IF;
    IF NEW.handler_id IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM `USER`
         WHERE user_id = NEW.handler_id AND site_role = 'administrator'
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Ticket handler must be an administrator';
    END IF;
    IF EXISTS (SELECT 1 FROM `USER`
               WHERE user_id = NEW.raised_by AND banned_on IS NOT NULL)
       AND NEW.ticket_type <> 'ban appeal' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Banned users may raise only ban-appeal tickets';
    END IF;
END$$

-- ------------------------------------------------------------
-- FEATURE rules
-- ------------------------------------------------------------

CREATE TRIGGER trg_features_bi
BEFORE INSERT ON FEATURES
FOR EACH ROW
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM RUN r
         WHERE r.run_id = NEW.run_id
           AND r.examiner_id IS NOT NULL
           AND r.reject_reason IS NULL
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Only verified runs can be featured';
    END IF;
    IF NOT EXISTS (
        SELECT 1 FROM PLAYED_BY pb
         WHERE pb.run_id = NEW.run_id AND pb.user_id = NEW.user_id
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Users may feature only runs they participated in';
    END IF;
END$$

CREATE TRIGGER trg_features_bu
BEFORE UPDATE ON FEATURES
FOR EACH ROW
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM RUN r
         WHERE r.run_id = NEW.run_id
           AND r.examiner_id IS NOT NULL
           AND r.reject_reason IS NULL
    ) OR NOT EXISTS (
        SELECT 1 FROM PLAYED_BY pb
         WHERE pb.run_id = NEW.run_id AND pb.user_id = NEW.user_id
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Only your own verified runs can be featured';
    END IF;
END$$

-- Moderators cannot be banned users.
CREATE TRIGGER trg_moderates_game_bi
BEFORE INSERT ON MODERATES_GAME
FOR EACH ROW
BEGIN
    IF EXISTS (SELECT 1 FROM `USER`
               WHERE user_id = NEW.user_id AND banned_on IS NOT NULL) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Banned users cannot hold moderator roles';
    END IF;
END$$

CREATE TRIGGER trg_moderates_series_bi
BEFORE INSERT ON MODERATES_SERIES
FOR EACH ROW
BEGIN
    IF EXISTS (SELECT 1 FROM `USER`
               WHERE user_id = NEW.user_id AND banned_on IS NOT NULL) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Banned users cannot hold moderator roles';
    END IF;
END$$

-- A game with runs cannot be deleted.
CREATE TRIGGER trg_game_bd
BEFORE DELETE ON GAME
FOR EACH ROW
BEGIN
    IF EXISTS (SELECT 1 FROM RUN WHERE game_id = OLD.game_id) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cannot delete a game while runs exist';
    END IF;
END$$

DELIMITER ;

-- ============================================================
-- 10. Rules requiring transaction/application-level validation
-- ============================================================
-- The following cannot be safely enforced as ordinary immediate
-- row triggers because a valid workflow inserts a parent first and
-- its required child rows afterwards. Validate these before COMMIT:
--
-- A. Every GAME must have at least one AVAILABLE_ON row.
-- B. Every RUN must have at least one RUN_TIME row and one PLAYED_BY
--    row, and must have the game's default time type in RUN_TIME.
-- C. If GAME.require_video = TRUE, a RUN must have a RUN_VIDEO_LINK
--    before it is verified. (The RUN update trigger checks this.)
-- D. When a game has configured release regions, each run must use
--    one of them; the RUN triggers enforce this.
-- E. The RUN_TIME triggers ensure every supplied time type belongs
--    to the game's configured types.
-- F. A LEVEL_RUN is allowed only for a 'per level' category.
-- G. The RUN triggers validate platform, date, emulator policy,
--    examiner authority, and submitter ban status.
-- H. The TICKET triggers enforce the game/run exclusivity, ticket
--    type, closure/resolution, handler authority, and banned-user
--    ban-appeal-only rules.
-- I. The NEWS_POST triggers enforce approval fields, administrator
--    approval, author/approver separation, and author ban status.
-- J. Thread/reply, self-follow, feature, moderator, and game-delete
--    rules are enforced by triggers above.
--
-- MySQL does not support deferred constraint triggers. For rules A
-- and B, the application must perform the parent + child inserts in
-- one transaction and run validation queries before COMMIT.
--
-- Phase 2 evaluation note: moderator-role history is not retained
-- in this Phase 3 mapping; this script does not add role end dates.
-- ============================================================
