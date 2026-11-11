-- =====================================================================
-- populate.sql  -  Speedrun.com mini-world (Phase 4)
-- Data collected from public speedrun.com pages (leaderboards, run pages, game pages,
-- staff lists, forum/news listings), plus a few well-known public facts for Super Mario 64
-- and Celeste (release date, genre, developer). See DATA_SOURCES.md for the full list and caveats.
-- Run AFTER schema.sql:   mysql -u root -p < populate.sql
--
-- Fields the website does not expose publicly are filled with clearly marked placeholders:
--   USER.email          -> <username>@example.invalid   USER.password_hash -> disabled placeholder
--   USER.signup_date    -> 2014-01-01     MODERATES_GAME.since -> 2014-01-01
--   run_date            -> exact where a source gave it; else 'N years ago' converted from 2026-11-11 (marked ~);
--                          2026-11-11 (observation date) where no date was shown at all (marked ?)
-- =====================================================================
USE speedrun_db;
SET NAMES utf8mb4;

-- ---------- lookup tables
INSERT INTO MODERATOR_ROLE (role_id, role_name) VALUES (1,'verifier'), (2,'moderator'), (3,'super moderator');
INSERT INTO PLATFORM (platform_id, platform_name, release_year) VALUES
  (1,'N64',1996),
  (2,'PC',NULL),
  (3,'SNES',1990),
  (4,'GBA',2001),
  (5,'Web',NULL),
  (6,'PS4',2013),
  (7,'XboxOne',2013),
  (8,'Switch',2017),
  (9,'WiiVC',NULL),
  (10,'WiiUVC',NULL);
INSERT INTO REGION (region_id, region_name) VALUES (1,'JPN / NTSC'), (2,'USA / NTSC');
INSERT INTO SERIES (series_id, series_name) VALUES (1,'Super Mario Series'), (2,'Celeste Series'), (3,'Super Mario World ROM Hacks Series'), (4,'Celeste Fangames Series');
INSERT INTO FORUM (forum_id, forum_name) VALUES
  (1,'Super Mario 64 Forums'),
  (2,'Celeste Forums'),
  (3,'Modded Celeste Forums'),
  (4,'CELESTE Classic 2 Mods Forums'),
  (5,'Celeste.smc Forums'),
  (6,'Celeste for GBA Forums');

-- ---------- users (email / password_hash / signup_date are placeholders; see header)
INSERT INTO `USER` (user_id, username, email, password_hash, signup_date, site_role, pronouns, country, subregion) VALUES
  (1,'8lubat','8lubat@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,'Japan',NULL),
  (2,'AbUnderscored','abunderscored@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,NULL,NULL),
  (3,'adelyn','adelyn@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,NULL,NULL),
  (4,'Akira','akira@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,'Japan',NULL),
  (5,'alaris','alaris@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,NULL,NULL),
  (6,'Amahumahaba','amahumahaba@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,NULL,NULL),
  (7,'Andri_dn','andri_dn@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,'Ireland',NULL),
  (8,'BadelineBot','badelinebot@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,NULL,NULL),
  (9,'badroenis','badroenis@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,'United States','Ohio'),
  (10,'Banova','banova@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,'France','Aquitaine'),
  (11,'Ben_eXceL','ben_excel@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,'United States','Utah'),
  (12,'Benj','benj@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,NULL,NULL),
  (13,'Benji64','benji64@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,'Austria','Burgenland'),
  (14,'Bluely','bluely@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,NULL,NULL),
  (15,'blupee','blupee@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,NULL,NULL),
  (16,'bonjoursauce','bonjoursauce@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,'Québec',NULL),
  (17,'BrandonBlank','brandonblank@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,'United States','Massachusetts'),
  (18,'Bree12am','bree12am@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,NULL,NULL),
  (19,'CactusSB','cactussb@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,NULL,NULL),
  (20,'capos00','capos00@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,NULL,NULL),
  (21,'Chambo_','chambo_@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,'Canada',NULL),
  (22,'CMcD','cmcd@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,NULL,NULL),
  (23,'cominixo','cominixo@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,NULL,NULL),
  (24,'creepcrafting56','creepcrafting56@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,NULL,NULL),
  (25,'Deadalus','deadalus@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,NULL,NULL),
  (26,'DillaGames','dillagames@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,NULL,NULL),
  (27,'DoenerAli','doenerali@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,NULL,NULL),
  (28,'Drac','drac@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,'Brazil','Bahia'),
  (29,'DT_Ryan','dt_ryan@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,NULL,NULL),
  (30,'Dwhatever','dwhatever@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,'Germany',NULL),
  (31,'EEE_uwu','eee_uwu@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,'China',NULL),
  (32,'ElSyviliano','elsyviliano@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,'Venezuela',NULL),
  (33,'Envyy_','envyy_@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,'France',NULL),
  (34,'Ergoold','ergoold@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,NULL,NULL),
  (35,'Fladervy','fladervy@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,NULL,NULL),
  (36,'FlamvellYT','flamvellyt@example.invalid','!disabled-placeholder','2014-01-01','user','She/Her','Germany','North Rhine-Westphalia'),
  (37,'FlyingPenguin223','flyingpenguin223@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,NULL,NULL),
  (38,'fmx000','fmx000@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,NULL,NULL),
  (39,'GiliWhonka','giliwhonka@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,'Spain',NULL),
  (40,'Goldrush','goldrush@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,'Japan',NULL),
  (41,'gonengazit','gonengazit@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,NULL,NULL),
  (42,'goofgoose','goofgoose@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,NULL,NULL),
  (43,'Goombs','goombs@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,'United Kingdom',NULL),
  (44,'grandpoobear','grandpoobear@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,'United States','California'),
  (45,'Hank_Sinatra','hank_sinatra@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,'United States','Wisconsin'),
  (46,'HazelSR','hazelsr@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,'Sweden',NULL),
  (47,'IAmTheLine','iamtheline@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,'United States',NULL),
  (48,'Jackthewack','jackthewack@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,'Canada',NULL),
  (49,'JiggityJed','jiggityjed@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,'United States',NULL),
  (50,'Jumpyluff','jumpyluff@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,'United States','Colorado'),
  (51,'Kally','kally@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,'United States','Colorado Springs, CO'),
  (52,'Karinpune','karinpune@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,'Japan',NULL),
  (53,'Kaya25efe','kaya25efe@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,'Turkey',NULL),
  (54,'Kezaron','kezaron@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,'Uganda',NULL),
  (55,'KilleDragon','killedragon@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,NULL,NULL),
  (56,'koralreef','koralreef@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,'United States','California'),
  (57,'larksford','larksford@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,'United States',NULL),
  (58,'LCDAngel99','lcdangel99@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,NULL,NULL),
  (59,'Liam','liam@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,'United States',NULL),
  (60,'Lightlie','lightlie@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,NULL,NULL),
  (61,'Lmjacks','lmjacks@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,NULL,NULL),
  (62,'LordSNEK','lordsnek@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,NULL,NULL),
  (63,'Lyreins','lyreins@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,'Russia',NULL),
  (64,'Malakbel','malakbel@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,NULL,NULL),
  (65,'maridon','maridon@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,NULL,NULL),
  (66,'MarkAlarm','markalarm@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,'United States',NULL),
  (67,'maxmarshmallows','maxmarshmallows@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,NULL,NULL),
  (68,'MCGamerGuy06','mcgamerguy06@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,'Canada',NULL),
  (69,'me_is_sam','me_is_sam@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,NULL,NULL),
  (70,'Meep_Moop','meep_moop@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,NULL,NULL),
  (71,'MeikainaKibou','meikainakibou@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,'France',NULL),
  (72,'minikori','minikori@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,NULL,NULL),
  (73,'mrmightymouse','mrmightymouse@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,'United States',NULL),
  (74,'NextGenGaming','nextgengaming@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,'United States','Missouri'),
  (75,'nikono','nikono@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,'United States','St. Louis, MO'),
  (76,'oneframejames','oneframejames@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,'United States','Washington'),
  (77,'orbittwz','orbittwz@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,NULL,NULL),
  (78,'Pac','pac@example.invalid','!disabled-placeholder','2014-01-01','administrator',NULL,NULL,NULL),
  (79,'Parsee02','parsee02@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,'Japan',NULL),
  (80,'Peniiie','peniiie@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,'United States','Tennessee'),
  (81,'Peter56166','peter56166@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,'United States',NULL),
  (82,'petrainukai','petrainukai@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,NULL,NULL),
  (83,'preimi','preimi@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,'Germany',NULL),
  (84,'PugRoy','pugroy@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,'United States','Minnesota'),
  (85,'rellort','rellort@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,'Canada','Manitoba'),
  (86,'rexwow','rexwow@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,'Brazil',NULL),
  (87,'Rhalekey','rhalekey@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,'Brazil','Espírito Santo'),
  (88,'Rileyoshi','rileyoshi@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,'United States','New Mexico'),
  (89,'RONC3NA','ronc3na@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,NULL,NULL),
  (90,'RubyRed','rubyred@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,NULL,NULL),
  (91,'saksdal','saksdal@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,'United States','New York'),
  (92,'Sat_Bot_RBVA','sat_bot_rbva@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,'France',NULL),
  (93,'SaySurprise','saysurprise@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,NULL,NULL),
  (94,'seckswrecks','seckswrecks@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,NULL,NULL),
  (95,'secureaccount','secureaccount@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,'United States',NULL),
  (96,'Senen','senen@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,'France',NULL),
  (97,'Serenilink','serenilink@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,NULL,NULL),
  (98,'simply','simply@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,'United States','Minnesota'),
  (99,'skun','skun@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,'France','Île-de-France'),
  (100,'SM64ModerationBot','sm64moderationbot@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,NULL,NULL),
  (101,'Smau','smau@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,'Finland','Etelä-Savo'),
  (102,'Spirialis','spirialis@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,'United States',NULL),
  (103,'StableMap','stablemap@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,'Brazil',NULL),
  (104,'Storster','storster@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,NULL,NULL),
  (105,'Suigi','suigi@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,'Canada',NULL),
  (106,'Taggo','taggo@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,'Sweden','Norrbotten'),
  (107,'Terji','terji@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,'Faroe Islands',NULL),
  (108,'thedigitalandrew','thedigitalandrew@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,'United States',NULL),
  (109,'thom148','thom148@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,'Canada',NULL),
  (110,'Tiyo','tiyo@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,NULL,NULL),
  (111,'TrevABC','trevabc@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,NULL,NULL),
  (112,'truegen','truegen@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,'England',NULL),
  (113,'Vadien','vadien@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,NULL,NULL),
  (114,'VininiciusCunha','vininiciuscunha@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,'Brazil',NULL),
  (115,'WafflesAreNice','wafflesarenice@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,NULL,NULL),
  (116,'WilacK','wilack@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,'France',NULL),
  (117,'Windrunner315','windrunner315@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,NULL,NULL),
  (118,'Xoofey','xoofey@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,'United States','Maryland'),
  (119,'yujene','yujene@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,'Canada',NULL),
  (120,'zVypurr','zvypurr@example.invalid','!disabled-placeholder','2014-01-01','user',NULL,NULL,NULL);
INSERT INTO USER_SOCIAL_LINK (user_id, link) VALUES (105,'https://www.speedrun.com/users/Suigi');

-- ---------- games
INSERT INTO GAME (game_id, abbreviation, name_international, release_date, show_milliseconds, require_video, emulators_allowed, default_time_type, run_time_type_1, run_time_type_2, forum_id) VALUES (1,'sm64','Super Mario 64','1996-06-23',1,0,1,'real time','real time',NULL,1);
INSERT INTO GAME (game_id, abbreviation, name_international, release_date, show_milliseconds, require_video, emulators_allowed, default_time_type, run_time_type_1, run_time_type_2, forum_id) VALUES (2,'celeste','Celeste','2018-01-25',1,0,1,'in-game time','in-game time',NULL,2);
INSERT INTO GAME (game_id, abbreviation, name_international, release_date, show_milliseconds, require_video, emulators_allowed, default_time_type, run_time_type_1, run_time_type_2, forum_id) VALUES (3,'modded_celeste','Modded Celeste',NULL,1,0,1,'in-game time','in-game time',NULL,3);
INSERT INTO GAME (game_id, abbreviation, name_international, release_date, show_milliseconds, require_video, emulators_allowed, default_time_type, run_time_type_1, run_time_type_2, forum_id) VALUES (4,'celeste_classic_2_mods','CELESTE Classic 2 Mods',NULL,1,0,1,'in-game time','in-game time',NULL,4);
INSERT INTO GAME (game_id, abbreviation, name_international, release_date, show_milliseconds, require_video, emulators_allowed, default_time_type, run_time_type_1, run_time_type_2, forum_id) VALUES (5,'celestesmc','Celeste.smc',NULL,1,0,1,'real time','real time',NULL,5);
INSERT INTO GAME (game_id, abbreviation, name_international, release_date, show_milliseconds, require_video, emulators_allowed, default_time_type, run_time_type_1, run_time_type_2, forum_id) VALUES (6,'celestegba','Celeste for GBA',NULL,1,0,1,'in-game time','in-game time','real time',6);
INSERT INTO PART_OF (game_id, series_id) VALUES (1,1), (2,2), (3,2), (4,2), (5,3), (5,4), (6,4);
INSERT INTO AVAILABLE_ON (game_id, platform_id) VALUES (1,1), (1,9), (1,10), (1,8), (2,2), (2,6), (2,7), (2,8), (3,2), (4,5), (5,3), (6,4);
INSERT INTO GAME_GENRE (game_id, genre) VALUES (1,'Platformer'), (2,'Platformer');
INSERT INTO GAME_DEVELOPER (game_id, developer) VALUES (1,'Nintendo EAD'), (2,'Maddy Makes Games');
INSERT INTO GAME_LINK (game_id, link) VALUES (1,'https://www.speedrun.com/sm64'), (2,'https://www.speedrun.com/celeste'), (3,'https://www.speedrun.com/modded_celeste'), (4,'https://www.speedrun.com/celeste_classic_2_mods'), (5,'https://www.speedrun.com/celestesmc'), (6,'https://www.speedrun.com/celestegba');
INSERT INTO CATEGORY (game_id, category_no, name, type, rules) VALUES
  (1,1,'120 Star','full game','Beat the game while collecting all 120 stars.'),
  (1,2,'70 Star','full game',NULL),
  (1,3,'16 Star','full game','Beat the game as quickly as possible.'),
  (1,4,'1 Star','full game','Beat the game as quickly as possible. The DDD skip is banned.'),
  (1,5,'0 Star','full game','Beat the game as quickly as possible without collecting any stars.'),
  (1,6,'Stage RTA','per level',NULL),
  (2,1,'Any%','full game',NULL),
  (2,2,'100%','full game',NULL),
  (2,3,'Clear','per level',NULL),
  (3,1,'Any%','full game',NULL),
  (4,1,'Any%','full game',NULL),
  (4,2,'100%','full game',NULL),
  (5,1,'Any%','full game',NULL),
  (5,2,'All Red Berries','full game',NULL),
  (5,3,'True Ending','full game',NULL),
  (5,4,'100%','full game',NULL),
  (6,1,'Any%','full game',NULL);
INSERT INTO LEVEL (game_id, level_no, name) VALUES
  (1,1,'Bob-omb Battlefield'),
  (1,2,'Whomp''s Fortress'),
  (1,3,'Jolly Roger Bay'),
  (1,4,'Cool, Cool Mountain'),
  (1,5,'Big Boo''s Haunt'),
  (1,6,'Hazy Maze Cave'),
  (1,7,'Lethal Lava Land'),
  (1,8,'Shifting Sand Land'),
  (1,9,'Dire, Dire Docks'),
  (1,10,'Snowman''s Land'),
  (1,11,'Wet-Dry World'),
  (2,1,'Forsaken City'),
  (2,2,'Old Site'),
  (2,3,'Celestial Resort'),
  (2,4,'Golden Ridge'),
  (2,5,'Mirror Temple'),
  (2,6,'Reflection'),
  (2,7,'The Summit'),
  (2,8,'Core'),
  (2,9,'Farewell');

-- ---------- moderators (as listed on each game page; 'since' is a placeholder)
INSERT INTO MODERATES_GAME (user_id, game_id, role_id, since) VALUES
  (5,1,3,'2014-01-01'),
  (72,1,3,'2014-01-01'),
  (38,1,2,'2014-01-01'),
  (93,1,2,'2014-01-01'),
  (100,1,2,'2014-01-01'),
  (113,1,2,'2014-01-01'),
  (20,1,2,'2014-01-01'),
  (89,1,2,'2014-01-01'),
  (2,1,1,'2014-01-01'),
  (3,1,1,'2014-01-01'),
  (6,1,1,'2014-01-01'),
  (15,1,1,'2014-01-01'),
  (58,1,1,'2014-01-01'),
  (94,2,3,'2014-01-01'),
  (110,2,3,'2014-01-01'),
  (111,2,3,'2014-01-01'),
  (112,2,3,'2014-01-01'),
  (61,2,3,'2014-01-01'),
  (24,2,2,'2014-01-01'),
  (60,2,2,'2014-01-01'),
  (84,2,2,'2014-01-01'),
  (97,2,2,'2014-01-01'),
  (117,2,2,'2014-01-01'),
  (18,2,2,'2014-01-01'),
  (8,2,1,'2014-01-01'),
  (12,2,1,'2014-01-01'),
  (19,2,1,'2014-01-01'),
  (26,2,1,'2014-01-01'),
  (35,2,1,'2014-01-01'),
  (42,2,1,'2014-01-01'),
  (65,2,1,'2014-01-01'),
  (67,2,1,'2014-01-01'),
  (71,2,1,'2014-01-01'),
  (61,3,3,'2014-01-01'),
  (94,3,3,'2014-01-01'),
  (110,3,3,'2014-01-01'),
  (111,3,3,'2014-01-01'),
  (112,3,3,'2014-01-01'),
  (18,3,2,'2014-01-01'),
  (24,3,2,'2014-01-01'),
  (84,3,2,'2014-01-01'),
  (117,3,2,'2014-01-01'),
  (8,3,1,'2014-01-01'),
  (70,4,3,'2014-01-01'),
  (94,4,3,'2014-01-01'),
  (23,4,2,'2014-01-01'),
  (41,4,2,'2014-01-01'),
  (62,4,2,'2014-01-01'),
  (82,4,2,'2014-01-01'),
  (90,4,2,'2014-01-01'),
  (37,4,1,'2014-01-01'),
  (104,5,3,'2014-01-01'),
  (66,5,2,'2014-01-01'),
  (73,5,2,'2014-01-01'),
  (11,6,3,'2014-01-01');

-- ---------- runs. Inserted unexamined, then verified (examiner must moderate the game; see header notes)
-- Super Mario 64: 41 runs
INSERT INTO RUN (run_id, run_date, submitted_at, emulated, comment, game_id, category_no, submitter_id, platform_id, region_id) VALUES
  (1,'2025-12-30','2025-12-30 00:00:00',0,NULL,1,5,105,1,1),
  (2,'2026-01-14','2026-01-14 00:00:00',0,NULL,1,4,105,1,1),
  (3,'2026-07-02','2026-07-02 00:00:00',0,'Route: LBLJ',1,3,105,1,1),
  (4,'2026-02-17','2026-02-17 00:00:00',0,NULL,1,2,105,1,2),
  (5,'2026-04-25','2026-04-25 00:00:00',0,NULL,1,1,105,1,1),
  (6,'2026-06-15','2026-06-15 00:00:00',0,NULL,1,1,52,1,NULL),
  (7,'2025-11-11','2025-11-11 00:00:00',0,NULL,1,1,105,1,1),
  (8,'2024-11-11','2024-11-11 00:00:00',0,'Route: LBLJ',1,3,105,1,1),
  (9,'2020-11-11','2020-11-11 00:00:00',1,NULL,1,3,105,1,1),
  (10,'2020-11-11','2020-11-11 00:00:00',0,NULL,1,1,59,1,1),
  (11,'2026-11-11','2026-11-11 00:00:00',0,NULL,1,6,51,1,NULL),
  (12,'2026-11-11','2026-11-11 00:00:00',0,NULL,1,6,9,1,NULL),
  (13,'2026-11-11','2026-11-11 00:00:00',0,NULL,1,6,79,1,NULL),
  (14,'2026-11-11','2026-11-11 00:00:00',0,NULL,1,6,30,1,NULL),
  (15,'2026-11-11','2026-11-11 00:00:00',0,NULL,1,6,10,1,NULL),
  (16,'2026-11-11','2026-11-11 00:00:00',0,NULL,1,6,13,1,NULL),
  (17,'2026-11-11','2026-11-11 00:00:00',0,NULL,1,6,51,1,NULL),
  (18,'2026-11-11','2026-11-11 00:00:00',0,NULL,1,6,101,1,NULL),
  (19,'2026-11-11','2026-11-11 00:00:00',0,NULL,1,6,79,1,NULL),
  (20,'2026-11-11','2026-11-11 00:00:00',0,NULL,1,6,40,1,NULL),
  (21,'2026-11-11','2026-11-11 00:00:00',0,NULL,1,6,79,1,NULL),
  (22,'2026-11-11','2026-11-11 00:00:00',0,NULL,1,6,106,1,NULL),
  (23,'2026-11-11','2026-11-11 00:00:00',0,NULL,1,6,79,1,NULL),
  (24,'2026-11-11','2026-11-11 00:00:00',0,NULL,1,6,51,1,NULL),
  (25,'2026-11-11','2026-11-11 00:00:00',0,NULL,1,6,105,1,NULL),
  (26,'2026-11-11','2026-11-11 00:00:00',0,NULL,1,6,79,1,NULL),
  (27,'2026-11-11','2026-11-11 00:00:00',0,NULL,1,6,51,1,NULL),
  (28,'2026-11-11','2026-11-11 00:00:00',0,NULL,1,6,4,1,NULL),
  (29,'2026-11-11','2026-11-11 00:00:00',0,NULL,1,6,118,1,NULL),
  (30,'2026-11-11','2026-11-11 00:00:00',0,NULL,1,6,105,1,NULL),
  (31,'2026-11-11','2026-11-11 00:00:00',0,NULL,1,6,51,1,NULL),
  (32,'2026-11-11','2026-11-11 00:00:00',0,NULL,1,6,79,1,NULL),
  (33,'2026-11-11','2026-11-11 00:00:00',0,NULL,1,6,98,1,NULL),
  (34,'2026-11-11','2026-11-11 00:00:00',0,NULL,1,6,105,1,NULL),
  (35,'2026-11-11','2026-11-11 00:00:00',0,NULL,1,6,28,1,NULL),
  (36,'2026-11-11','2026-11-11 00:00:00',0,NULL,1,6,79,1,NULL),
  (37,'2026-11-11','2026-11-11 00:00:00',0,NULL,1,6,91,1,NULL),
  (38,'2026-11-11','2026-11-11 00:00:00',0,NULL,1,6,51,1,NULL),
  (39,'2026-11-11','2026-11-11 00:00:00',0,NULL,1,6,79,1,NULL),
  (40,'2026-11-11','2026-11-11 00:00:00',0,NULL,1,6,105,1,NULL),
  (41,'2026-11-11','2026-11-11 00:00:00',0,NULL,1,6,51,1,NULL);
INSERT INTO PLAYED_BY (run_id, user_id, player_order) VALUES (1,105,1), (2,105,1), (3,105,1), (4,105,1), (5,105,1), (6,52,1), (7,105,1), (8,105,1), (9,105,1), (10,59,1), (11,51,1), (12,9,1), (13,79,1), (14,30,1), (15,10,1), (16,13,1), (17,51,1), (18,101,1), (19,79,1), (20,40,1), (21,79,1), (22,106,1), (23,79,1), (24,51,1), (25,105,1), (26,79,1), (27,51,1), (28,4,1), (29,118,1), (30,105,1), (31,51,1), (32,79,1), (33,98,1), (34,105,1), (35,28,1), (36,79,1), (37,91,1), (38,51,1), (39,79,1), (40,105,1), (41,51,1);
INSERT INTO RUN_TIME (run_id, time_type, hours, minutes, seconds, milliseconds) VALUES (1,'real time',0,6,14,190), (2,'real time',0,6,53,680), (3,'real time',0,14,32,870), (4,'real time',0,46,11,0), (5,'real time',1,35,14,0), (6,'real time',1,35,28,0), (7,'real time',1,35,33,0), (8,'real time',0,14,35,500), (9,'real time',0,30,0,0), (10,'real time',1,38,43,0), (11,'real time',0,6,2,380), (12,'real time',0,6,2,960), (13,'real time',0,6,5,230), (14,'real time',0,3,24,970), (15,'real time',0,3,26,230), (16,'real time',0,3,26,430), (17,'real time',0,5,27,930), (18,'real time',0,5,32,190), (19,'real time',0,5,33,160), (20,'real time',0,4,36,370), (21,'real time',0,4,38,510), (22,'real time',0,4,40,380), (23,'real time',0,5,53,820), (24,'real time',0,5,54,50), (25,'real time',0,5,54,830), (26,'real time',0,4,42,740), (27,'real time',0,4,51,320), (28,'real time',0,4,54,190), (29,'real time',0,3,50,160), (30,'real time',0,3,50,630), (31,'real time',0,3,51,260), (32,'real time',0,5,4,70), (33,'real time',0,5,6,950), (34,'real time',0,5,10,70), (35,'real time',0,5,47,730), (36,'real time',0,3,32,270), (37,'real time',0,3,47,500), (38,'real time',0,3,49,610), (39,'real time',0,4,39,170), (40,'real time',0,4,45,840), (41,'real time',0,4,46,950);
INSERT INTO LEVEL_RUN (run_id, game_id, level_no) VALUES (11,1,1), (12,1,1), (13,1,1), (14,1,2), (15,1,2), (16,1,2), (17,1,3), (18,1,3), (19,1,3), (20,1,4), (21,1,4), (22,1,4), (23,1,5), (24,1,5), (25,1,5), (26,1,6), (27,1,6), (28,1,6), (29,1,7), (30,1,7), (31,1,7), (32,1,8), (33,1,8), (34,1,8), (35,1,9), (36,1,10), (37,1,10), (38,1,10), (39,1,11), (40,1,11), (41,1,11);
-- Celeste: 31 runs
INSERT INTO RUN (run_id, run_date, submitted_at, emulated, comment, game_id, category_no, submitter_id, platform_id, region_id) VALUES
  (42,'2022-11-11','2022-11-11 00:00:00',0,'Version 1.4.0.0',2,2,56,2,NULL),
  (43,'2023-11-11','2023-11-11 00:00:00',0,'Version 1.4.0.0',2,2,49,2,NULL),
  (44,'2024-11-11','2024-11-11 00:00:00',0,'Version 1.3.3.0',2,1,68,2,NULL),
  (45,'2025-11-11','2025-11-11 00:00:00',0,'Version 1.4.0.0',2,3,80,2,NULL),
  (46,'2026-11-11','2026-11-11 00:00:00',0,NULL,2,3,95,2,NULL),
  (47,'2026-11-11','2026-11-11 00:00:00',0,NULL,2,3,85,2,NULL),
  (48,'2026-11-11','2026-11-11 00:00:00',0,NULL,2,3,25,2,NULL),
  (49,'2026-11-11','2026-11-11 00:00:00',0,NULL,2,3,95,2,NULL),
  (50,'2026-11-11','2026-11-11 00:00:00',0,NULL,2,3,31,2,NULL),
  (51,'2026-11-11','2026-11-11 00:00:00',0,NULL,2,3,63,2,NULL),
  (52,'2026-11-11','2026-11-11 00:00:00',0,NULL,2,3,95,2,NULL),
  (53,'2026-11-11','2026-11-11 00:00:00',0,NULL,2,3,63,2,NULL),
  (54,'2026-11-11','2026-11-11 00:00:00',0,NULL,2,3,54,2,NULL),
  (55,'2026-11-11','2026-11-11 00:00:00',0,NULL,2,3,95,2,NULL),
  (56,'2026-11-11','2026-11-11 00:00:00',0,NULL,2,3,39,2,NULL),
  (57,'2026-11-11','2026-11-11 00:00:00',0,NULL,2,3,63,2,NULL),
  (58,'2026-11-11','2026-11-11 00:00:00',0,NULL,2,3,85,2,NULL),
  (59,'2026-11-11','2026-11-11 00:00:00',0,NULL,2,3,83,2,NULL),
  (60,'2026-11-11','2026-11-11 00:00:00',0,NULL,2,3,92,2,NULL),
  (61,'2026-11-11','2026-11-11 00:00:00',0,NULL,2,3,109,2,NULL),
  (62,'2026-11-11','2026-11-11 00:00:00',0,NULL,2,3,48,2,NULL),
  (63,'2026-11-11','2026-11-11 00:00:00',0,NULL,2,3,95,2,NULL),
  (64,'2026-11-11','2026-11-11 00:00:00',0,NULL,2,3,95,2,NULL),
  (65,'2026-11-11','2026-11-11 00:00:00',0,NULL,2,3,63,2,NULL),
  (66,'2026-11-11','2026-11-11 00:00:00',0,NULL,2,3,120,2,NULL),
  (67,'2026-11-11','2026-11-11 00:00:00',0,NULL,2,3,95,2,NULL),
  (68,'2026-11-11','2026-11-11 00:00:00',0,NULL,2,3,46,2,NULL),
  (69,'2026-11-11','2026-11-11 00:00:00',0,NULL,2,3,43,2,NULL),
  (70,'2026-11-11','2026-11-11 00:00:00',0,NULL,2,3,119,2,NULL),
  (71,'2026-11-11','2026-11-11 00:00:00',0,NULL,2,3,47,2,NULL),
  (72,'2026-11-11','2026-11-11 00:00:00',0,NULL,2,3,95,2,NULL);
INSERT INTO PLAYED_BY (run_id, user_id, player_order) VALUES (42,56,1), (43,49,1), (44,68,1), (45,80,1), (46,95,1), (47,85,1), (48,25,1), (49,95,1), (50,31,1), (51,63,1), (52,95,1), (53,63,1), (54,54,1), (55,95,1), (56,39,1), (57,63,1), (58,85,1), (59,83,1), (60,92,1), (61,109,1), (62,48,1), (63,95,1), (64,95,1), (65,63,1), (66,120,1), (67,95,1), (68,46,1), (69,43,1), (70,119,1), (71,47,1), (72,95,1);
INSERT INTO RUN_TIME (run_id, time_type, hours, minutes, seconds, milliseconds) VALUES (42,'in-game time',1,41,59,864), (43,'in-game time',3,22,24,579), (44,'in-game time',1,59,14,688), (45,'in-game time',0,14,27,986), (46,'in-game time',0,0,52,445), (47,'in-game time',0,0,52,513), (48,'in-game time',0,0,52,547), (49,'in-game time',0,1,30,576), (50,'in-game time',0,1,30,763), (51,'in-game time',0,1,30,865), (52,'in-game time',0,3,41,153), (53,'in-game time',0,3,43,6), (54,'in-game time',0,3,47,613), (55,'in-game time',0,2,5,970), (56,'in-game time',0,2,6,123), (57,'in-game time',0,2,6,701), (58,'in-game time',0,3,37,345), (59,'in-game time',0,3,40,796), (60,'in-game time',0,3,41,459), (61,'in-game time',0,5,15,316), (62,'in-game time',0,5,15,928), (63,'in-game time',0,5,17,526), (64,'in-game time',0,7,26,624), (65,'in-game time',0,7,27,321), (66,'in-game time',0,7,33,951), (67,'in-game time',0,2,59,10), (68,'in-game time',0,3,13,630), (69,'in-game time',0,3,13,800), (70,'in-game time',0,4,49,765), (71,'in-game time',0,5,56,150), (72,'in-game time',0,12,58,770);
INSERT INTO LEVEL_RUN (run_id, game_id, level_no) VALUES (45,2,7), (46,2,1), (47,2,1), (48,2,1), (49,2,2), (50,2,2), (51,2,2), (52,2,3), (53,2,3), (54,2,3), (55,2,4), (56,2,4), (57,2,4), (58,2,5), (59,2,5), (60,2,5), (61,2,6), (62,2,6), (63,2,6), (64,2,7), (65,2,7), (66,2,7), (67,2,8), (68,2,8), (69,2,8), (70,2,9), (71,2,9), (72,2,9);
-- Modded Celeste: 11 runs
INSERT INTO RUN (run_id, run_date, submitted_at, emulated, comment, game_id, category_no, submitter_id, platform_id, region_id) VALUES
  (73,'2025-11-11','2025-11-11 00:00:00',0,NULL,3,1,53,2,NULL),
  (74,'2025-11-11','2025-11-11 00:00:00',0,NULL,3,1,71,2,NULL),
  (75,'2022-11-11','2022-11-11 00:00:00',0,NULL,3,1,86,2,NULL),
  (76,'2021-11-11','2021-11-11 00:00:00',0,NULL,3,1,84,2,NULL),
  (77,'2021-11-11','2021-11-11 00:00:00',0,NULL,3,1,57,2,NULL),
  (78,'2020-11-11','2020-11-11 00:00:00',0,NULL,3,1,102,2,NULL),
  (79,'2022-11-11','2022-11-11 00:00:00',0,NULL,3,1,7,2,NULL),
  (80,'2021-11-11','2021-11-11 00:00:00',0,NULL,3,1,112,2,NULL),
  (81,'2021-11-11','2021-11-11 00:00:00',0,NULL,3,1,116,2,NULL),
  (82,'2021-11-11','2021-11-11 00:00:00',0,NULL,3,1,34,2,NULL),
  (83,'2021-11-11','2021-11-11 00:00:00',0,NULL,3,1,99,2,NULL);
INSERT INTO PLAYED_BY (run_id, user_id, player_order) VALUES (73,53,1), (74,71,1), (75,86,1), (76,84,1), (77,57,1), (78,102,1), (79,7,1), (80,112,1), (81,116,1), (82,34,1), (83,99,1);
INSERT INTO RUN_TIME (run_id, time_type, hours, minutes, seconds, milliseconds) VALUES (73,'in-game time',0,1,41,405), (74,'in-game time',0,1,45,995), (75,'in-game time',0,1,50,279), (76,'in-game time',0,1,55,413), (77,'in-game time',0,1,56,484), (78,'in-game time',0,1,57,725), (79,'in-game time',0,2,2,145), (80,'in-game time',0,2,2,604), (81,'in-game time',0,2,5,426), (82,'in-game time',0,2,39,290), (83,'in-game time',0,2,39,341);
-- CELESTE Classic 2 Mods: 2 runs
INSERT INTO RUN (run_id, run_date, submitted_at, emulated, comment, game_id, category_no, submitter_id, platform_id, region_id) VALUES
  (84,'2023-11-11','2023-11-11 00:00:00',0,NULL,4,1,1,5,NULL),
  (85,'2022-11-11','2022-11-11 00:00:00',0,NULL,4,1,81,5,NULL);
INSERT INTO PLAYED_BY (run_id, user_id, player_order) VALUES (84,1,1), (85,81,1);
INSERT INTO RUN_TIME (run_id, time_type, hours, minutes, seconds, milliseconds) VALUES (84,'in-game time',0,1,44,0), (85,'in-game time',0,2,6,0);
-- Celeste.smc: 12 runs
INSERT INTO RUN (run_id, run_date, submitted_at, emulated, comment, game_id, category_no, submitter_id, platform_id, region_id) VALUES
  (86,'2022-11-11','2022-11-11 00:00:00',0,NULL,5,1,17,3,2),
  (87,'2022-11-11','2022-11-11 00:00:00',0,NULL,5,1,21,3,NULL),
  (88,'2022-11-11','2022-11-11 00:00:00',0,NULL,5,1,73,3,2),
  (89,'2022-11-11','2022-11-11 00:00:00',0,NULL,5,1,44,3,NULL),
  (90,'2022-11-11','2022-11-11 00:00:00',0,NULL,5,1,108,3,NULL),
  (91,'2022-11-11','2022-11-11 00:00:00',0,NULL,5,1,45,3,NULL),
  (92,'2022-11-11','2022-11-11 00:00:00',0,NULL,5,1,96,3,NULL),
  (93,'2022-11-11','2022-11-11 00:00:00',1,NULL,5,1,66,3,2),
  (94,'2022-11-11','2022-11-11 00:00:00',0,NULL,5,1,76,3,NULL),
  (95,'2022-11-11','2022-11-11 00:00:00',0,NULL,5,1,75,3,NULL),
  (96,'2023-11-11','2023-11-11 00:00:00',0,NULL,5,1,16,3,NULL),
  (97,'2022-11-11','2022-11-11 00:00:00',1,NULL,5,1,74,3,2);
INSERT INTO PLAYED_BY (run_id, user_id, player_order) VALUES (86,17,1), (87,21,1), (88,73,1), (89,44,1), (90,108,1), (91,45,1), (92,96,1), (93,66,1), (94,76,1), (95,75,1), (96,16,1), (97,74,1);
INSERT INTO RUN_TIME (run_id, time_type, hours, minutes, seconds, milliseconds) VALUES (86,'real time',0,17,35,0), (87,'real time',0,18,5,0), (88,'real time',0,18,24,0), (89,'real time',0,19,40,0), (90,'real time',0,22,46,0), (91,'real time',0,23,18,0), (92,'real time',0,23,32,0), (93,'real time',0,26,31,0), (94,'real time',0,27,6,0), (95,'real time',0,28,40,0), (96,'real time',0,30,24,0), (97,'real time',0,34,23,0);
-- Celeste for GBA: 7 runs
INSERT INTO RUN (run_id, run_date, submitted_at, emulated, comment, game_id, category_no, submitter_id, platform_id, region_id) VALUES
  (98,'2026-01-11','2026-01-11 00:00:00',1,NULL,6,1,32,4,NULL),
  (99,'2025-11-11','2025-11-11 00:00:00',1,NULL,6,1,88,4,NULL),
  (100,'2025-11-11','2025-11-11 00:00:00',1,NULL,6,1,103,4,NULL),
  (101,'2025-11-11','2025-11-11 00:00:00',1,NULL,6,1,33,4,NULL),
  (102,'2025-11-11','2025-11-11 00:00:00',1,NULL,6,1,87,4,NULL),
  (103,'2025-11-11','2025-11-11 00:00:00',1,NULL,6,1,11,4,NULL),
  (104,'2025-11-11','2025-11-11 00:00:00',1,NULL,6,1,114,4,NULL);
INSERT INTO PLAYED_BY (run_id, user_id, player_order) VALUES (98,32,1), (99,88,1), (100,103,1), (101,33,1), (102,87,1), (103,11,1), (104,114,1);
INSERT INTO RUN_TIME (run_id, time_type, hours, minutes, seconds, milliseconds) VALUES (98,'in-game time',0,3,54,0), (98,'real time',0,4,35,0), (99,'in-game time',0,3,56,0), (99,'real time',0,4,23,0), (100,'in-game time',0,4,19,0), (100,'real time',0,4,49,0), (101,'in-game time',0,4,27,0), (101,'real time',0,4,55,0), (102,'in-game time',0,4,39,0), (102,'real time',0,5,13,0), (103,'in-game time',0,6,36,0), (103,'real time',0,7,15,0), (104,'in-game time',0,20,11,0), (104,'real time',0,21,36,0);

-- verification: decision time = submission time (the site does not show the decision time on tables)
UPDATE RUN SET examiner_id = 5, decided_on = submitted_at WHERE run_id IN (1, 2, 4, 5, 6, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41);
UPDATE RUN SET examiner_id = 58, decided_on = submitted_at WHERE run_id IN (3);
UPDATE RUN SET examiner_id = 113, decided_on = submitted_at WHERE run_id IN (7);
UPDATE RUN SET examiner_id = 61, decided_on = submitted_at WHERE run_id IN (42);
UPDATE RUN SET examiner_id = 112, decided_on = submitted_at WHERE run_id IN (43, 44, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72);
UPDATE RUN SET examiner_id = 24, decided_on = submitted_at WHERE run_id IN (45);
UPDATE RUN SET examiner_id = 112, decided_on = submitted_at WHERE run_id IN (73, 74, 75, 76, 77, 78, 79, 81, 82, 83);
UPDATE RUN SET examiner_id = 94, decided_on = submitted_at WHERE run_id IN (80);
UPDATE RUN SET examiner_id = 94, decided_on = submitted_at WHERE run_id IN (84, 85);
UPDATE RUN SET examiner_id = 104, decided_on = submitted_at WHERE run_id IN (86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97);
UPDATE RUN SET examiner_id = 11, decided_on = submitted_at WHERE run_id IN (98, 99, 100, 101, 102, 103, 104);
INSERT INTO FEATURES (user_id, run_id, featured_order) VALUES (105,8,1);

-- ---------- forum threads and replies (thread_code is x<number> because the schema requires that format)
INSERT INTO THREAD (forum_id, thread_code, title, created_at, starter_id) VALUES (1,'x1','Leaderboard Histories','2020-11-11 12:00:00',14);
INSERT INTO THREAD (forum_id, thread_code, title, created_at, starter_id) VALUES (1,'x2','Announcement: automated submission rejection','2024-11-11 12:00:00',29);
INSERT INTO THREAD (forum_id, thread_code, title, created_at, starter_id) VALUES (1,'x3','Nintendo Switch Online and 3D All-Stars','2022-11-11 12:00:00',55);
INSERT INTO THREAD (forum_id, thread_code, title, created_at, starter_id) VALUES (1,'x4','Mobile emulators?','2020-11-11 12:00:00',36);
INSERT INTO REPLY (forum_id, thread_code, reply_no, body, posted_at, author_id) VALUES (1,'x4',1,'Asks whether any mobile emulator is allowed for runs and, if not, whether one could be approved since a controller can be connected to the phone.','2020-11-11 12:00:00',36);
INSERT INTO REPLY (forum_id, thread_code, reply_no, body, posted_at, author_id) VALUES (1,'x4',2,'^','2020-11-11 12:00:00',107);
INSERT INTO THREAD (forum_id, thread_code, title, created_at, starter_id) VALUES (1,'x5','Mods','2017-11-11 12:00:00',50);
INSERT INTO THREAD (forum_id, thread_code, title, created_at, starter_id) VALUES (1,'x6','Controller input displays','2026-11-08 12:00:00',22);
INSERT INTO THREAD (forum_id, thread_code, title, created_at, starter_id) VALUES (2,'x1','obs refusing to capture celeste','2026-07-11 12:00:00',115);
INSERT INTO THREAD (forum_id, thread_code, title, created_at, starter_id) VALUES (2,'x2','question about speedrunning','2026-06-11 12:00:00',64);
INSERT INTO THREAD (forum_id, thread_code, title, created_at, starter_id) VALUES (2,'x3','game crashing in reflection','2026-05-11 12:00:00',115);
INSERT INTO THREAD (forum_id, thread_code, title, created_at, starter_id) VALUES (3,'x1','Info, Map Submission Form and Related Leaderboards','2024-11-11 12:00:00',110);
INSERT INTO THREAD (forum_id, thread_code, title, created_at, starter_id) VALUES (3,'x2','into the jungle?','2026-02-11 12:00:00',27);
INSERT INTO THREAD (forum_id, thread_code, title, created_at, starter_id) VALUES (3,'x3','celeste.net?','2023-11-11 12:00:00',77);

-- ---------- news posts (approved by site administrator Pac; bodies are short summaries)
INSERT INTO NEWS_POST (news_id, title, body, created_at, status, approved_at, author_id, approver_id, game_id) VALUES (1,'Rules Update: Input Displays','Rules update: adapters and input displays must not show more than an unmodified controller (no exact input values, carpetless skins or off-notch indicators). Emulator runners on Project64 are asked to use Counter Factor 1.','2026-01-11 12:00:00','approved','2026-01-11 12:00:00',113,78,1);
INSERT INTO NEWS_POST_TOPIC (news_id, topic) VALUES (1,'Rules');
INSERT INTO NEWS_POST (news_id, title, body, created_at, status, approved_at, author_id, approver_id, game_id) VALUES (2,'Replacing Expiring Twitch VODs','Notice about replacing run videos hosted on expiring Twitch VODs. Full text: speedrun.com/sm64/news.','2025-11-11 12:00:00','approved','2025-11-11 12:00:00',5,78,1);
INSERT INTO NEWS_POST_TOPIC (news_id, topic) VALUES (2,'Videos');
INSERT INTO NEWS_POST (news_id, title, body, created_at, status, approved_at, author_id, approver_id, game_id) VALUES (3,'EMU/VC subcategories for Stage RTA','Announcement of emulator/Virtual Console subcategories for Stage RTA. Full text: speedrun.com/sm64/news.','2024-11-11 12:00:00','approved','2024-11-11 12:00:00',5,78,1);
INSERT INTO NEWS_POST_TOPIC (news_id, topic) VALUES (3,'Leaderboard');
INSERT INTO NEWS_POST (news_id, title, body, created_at, status, approved_at, author_id, approver_id, game_id) VALUES (4,'Handling of Farewell, Rules Update, and New Modded Board','Moderator announcement about how the Farewell chapter is handled, a rules update and a new modded board. Full text: speedrun.com/celeste/news.','2026-08-11 12:00:00','approved','2026-08-11 12:00:00',69,78,2);
INSERT INTO NEWS_POST_TOPIC (news_id, topic) VALUES (4,'Rules');
INSERT INTO NEWS_POST_TOPIC (news_id, topic) VALUES (4,'Leaderboard');

-- Not populated (not publicly visible on speedrun.com): TICKET, MEMBERSHIP, HOLDS_MEMBERSHIP, STREAM, FOLLOWS, FOLLOWS_GAME, MODERATES_SERIES, ROLE_PERMISSION.
