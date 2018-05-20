
-- YYYYmmddHHMM
-- 201804092200 up
-- http://www.sqlite.org/pragma.html#pragma_encoding
PRAGMA encoding = "UTF-8";
PRAGMA temp_store = MEMORY;
-- 'Groups for users in a Слово system.'
CREATE TABLE groups (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name VARCHAR(100) UNIQUE NOT NULL,
  description VARCHAR(255) NOT NULL,
  disabled INT(1) NOT NULL DEFAULT 1
);

-- 'This table stores the users'
CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  login_name varchar(100) UNIQUE,
  -- sha1_sum($login_name.$login_password)
  login_password varchar(40) NOT NULL,
  first_name varchar(100) NOT NULL DEFAULT '',
  last_name varchar(100) NOT NULL DEFAULT '',
  email varchar(255) NOT NULL UNIQUE,
  description varchar(255) DEFAULT NULL,
  -- 'last modification time'
  -- 'All dates are stored as seconds since the epoch(1970) in GMT.
  -- In Perl we use gmtime as object from Time::Piece'
  tstamp INTEGER DEFAULT 0,
  -- 'registration time',,
  reg_time INTEGER DEFAULT 0, 
  disabled INT(1) DEFAULT 1,
  start_date INTEGER DEFAULT 0,
  stop_date INTEGER DEFAULT 0
);
CREATE INDEX user_start_date ON users(start_date);
CREATE INDEX user_stop_date ON users(stop_date);


-- 'Which user to which group belongs'
CREATE TABLE user_group (
--  'ID of the user belonging to the group with group_id.'
  user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
--  'ID of the group to which the user with user_id belongs.'
  group_id INTEGER REFERENCES groups(id) ON DELETE CASCADE,
  PRIMARY KEY(user_id, group_id)
);

INSERT INTO `groups`(id,name,description) VALUES(0,'null','null group');
INSERT INTO `users` (id,login_name,login_password,first_name,last_name,email,description) 
    VALUES(0,'null','9f1bd12057905cf4f61a14e3eeac06bf68a28e64',
    'Null','Null','null@localhost','Disabled system user. Do not use!');
INSERT INTO `user_group` VALUES(0,0);


-- Why we add columns(constraints) later? See https://stackoverflow.com/questions/1884818/#23574053
ALTER TABLE groups ADD COLUMN created_by INTEGER DEFAULT NULL REFERENCES users(id) ON DELETE SET DEFAULT;
ALTER TABLE groups ADD COLUMN changed_by INTEGER DEFAULT NULL REFERENCES users(id) ON DELETE SET DEFAULT;

ALTER TABLE users ADD COLUMN group_id INTEGER DEFAULT NULL REFERENCES groups(id) ON DELETE SET DEFAULT;
ALTER TABLE users ADD COLUMN created_by INTEGER DEFAULT NULL REFERENCES users(id) ON DELETE SET DEFAULT;
ALTER TABLE users ADD COLUMN changed_by INTEGER DEFAULT NULL REFERENCES users(id) ON DELETE SET DEFAULT;

INSERT INTO groups VALUES(1,'admin','group for administrators',0,0,0);
INSERT INTO users VALUES(1,'foo','9f1bd12057905cf4f61a14e3eeac06bf68a28e64','Foo','Bar','foo@localhost',
  'System user. Do not use!',1,1,0,0,0, 1,0,0);
 INSERT INTO `user_group` VALUES(1,1);
 
INSERT INTO groups VALUES(2,'guest','guest',0,1,1);
INSERT INTO users
VALUES(2,'guest','8097beb8d5950479e49d803e683932150f469827','гостенин','','guest@localhost',
  'Guest user. Anybody not authenticated is a guest user.',
  1,1,0,0,0, 2,1,1);
INSERT INTO `user_group` VALUES(2,2);
 
INSERT INTO `groups` VALUES(3,'test1','test1',1,1,1);
INSERT INTO `users` VALUES(3,'test1','b5e9c9ab4f777c191bc847e1aca222d6836714b7','Test','1','test1@localhost',
  'test1 user. Delete. used for tests only.',1,1,1,0,0, 3,1,1);
INSERT INTO `user_group` VALUES(3,3);
 
INSERT INTO `groups` VALUES(4,'test2','test2',0,1,1);
INSERT INTO `users` VALUES(4,'test2','272a11a0206b949355be4b0bda9a8918609f1ac6','Test','2','test2@localhost',
  'test2 user. Delete. Used for tests only.',
  1,1,0,0,0, 4,1,1); 
INSERT INTO `user_group` VALUES(4,4);

INSERT INTO `groups` VALUES(5,'краси','краси',0,4,4);
-- sha1_sum(encode("utf8","красиберов")
INSERT INTO `users` VALUES(5,'краси','f65676423e87854b434b8015da176c01b086ef0b','Краси','Беров','краси@localhost',
    'краси user. Delete this user. ' || 'Used for tests only.',1,1,0,0,0, 5,4,4);
INSERT INTO `user_group` VALUES(5,5);

-- 201804092200 down
DROP TABLE IF EXISTS user_group;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS groups;

-- YYYYmmddHHMM
-- 201804302200 up
-- 'Sites managed by this system'
CREATE TABLE domove (
-- domove is the plural form of 'dom' in Bulgarian, meaning 'home'.
-- The similarity with domains is not a coincidence
--  'Id referenced by stranici that belong to this domain.'
  id INTEGER PRIMARY KEY AUTOINCREMENT,
--  'Domain name as in $ENV{HTTP_HOST}.'
  domain VARCHAR(63) UNIQUE NOT NULL, 
--  'The name of this site.'
  site_name VARCHAR(63) NOT NULL,
--  'Site description'
  description VARCHAR(2000) NOT NULL DEFAULT '',
--   'User for which the permissions apply (owner).'
  owner_id INTEGER REFERENCES users(id),
--  'Group for which the permissions apply.'
  group_id INTEGER  REFERENCES groups(id),
--  'Domain permissions',
  permissions VARCHAR(10) DEFAULT '-rwxr-xr-x' ,
--  '0:not published, 1:for review, >=2:published'
  published INT(1) DEFAULT 0
);

CREATE INDEX IF NOT EXISTS domove_published ON domove(published);

INSERT INTO domove (id, domain, description, site_name, owner_id, permissions, published)
    VALUES ( 0, 'localhost', 'default domain', 'Слово', 0, '-rwxr-xr-x', 2);

CREATE TABLE stranici (
  -- 'stranica(страница)' in Bulgarian means 'page'.
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  -- Parent page id
  pid INTEGER DEFAULT 0,
  -- Refrerence to domove.id to which this page belongs.
  dom_id INTEGER DEFAULT 0,
  -- Alias for the page which may be used instead of the id.
  alias VARCHAR(32) NOT NULL,
  -- 'обичайна','коренъ' etc.
  page_type VARCHAR(32) NOT NULL,
  -- Page editing permissions. Prefixes: d - folder, l - link
  permissions varchar(10) DEFAULT '-rwxr-xr-x',
  sorting INTEGER DEFAULT 1,
  -- MT code to display this page. Default template is used if not specified.
  template VARCHAR(255),
  -- User for which the permissions apply (owner/creator).
  user_id INTEGER,
  -- Group for which the permissions apply (usually primary group of the owner).
  group_id INTEGER,
  tstamp INTEGER DEFAULT 0,
  start INTEGER DEFAULT 0,
  stop INTEGER DEFAULT 0,
  -- 0: not published, 1: for review/preview, >=2: published
  published int(1) DEFAULT 1,
  -- Is this page hidden? 0=No, 1=Yes
  hidden int(1) DEFAULT 0,
  -- Is this page deleted? 0=No, 1=Yes
  deleted int(1) DEFAULT 0,
  -- Who modified this page the last time?
  changed_by INTEFER REFERENCES users(id),
  FOREIGN KEY (pid)       REFERENCES stranici(id) ON UPDATE CASCADE ON DELETE CASCADE,
  FOREIGN KEY (dom_id)    REFERENCES domove(id)   ON UPDATE CASCADE ON DELETE CASCADE,
  FOREIGN KEY (user_id)   REFERENCES users(id)    ON UPDATE CASCADE,
  FOREIGN KEY (group_id)  REFERENCES groups(id)   ON UPDATE CASCADE
);
CREATE UNIQUE INDEX IF NOT EXISTS stranici_alias_in_domove ON stranici(alias, dom_id);
CREATE INDEX IF NOT EXISTS stranici_user_id_group_id ON stranici(user_id, group_id);
CREATE INDEX IF NOT EXISTS stranici_hidden ON stranici(hidden);

-- only root pages have pid same as id!
INSERT INTO stranici (
    id, alias, changed_by, deleted, dom_id, group_id, hidden, page_type,
    permissions, pid, published, sorting, start, stop, tstamp, user_id)
VALUES ( 
    0, 'коренъ', 0, 0, 0, 0, 0, 'root',
    '-rwxr-xr-x', 0, 1, 0, 0, 0, 1523795424, 0);


 -- Initially created by SQL::Translator::Producer::SQLite
 -- Created on Sat Apr 14 13:32:46 2018
 -- 
 
 CREATE TABLE celini (
 -- content elements are one or more paragraphs, or whole article. Different
 -- data_types denote the semantic of a content element.
 -- This table is a modified version of MYDLjE table "content".
 -- 'celina(целина)' is the original Bulgarian word for 'paragraph'.
 
  -- Primary unique identifier
  id INTEGER PRIMARY KEY,
  -- Lowercased and trimmed of \W characters unique identifier for the row data_type
  alias VARCHAR(255) DEFAULT 'seo-friendly-id',
  -- Parent content: Question, Article, Note, Book ID etc.
  pid INTEGER DEFAULT 0,
  -- Id from which this content is copied (translated), if not original content.
  from_id INTEGER DEFAULT 0,
  -- page.id to which this content belongs. Default: 0 
  page_id INTEGER DEFAULT 0,
  -- User for which the permissions apply (owner).
  user_id INTEGER NOT NULL,
  -- Group for which the permissions apply.(primary group of the user by default)
  group_id INTEGER NOT NULL,
  -- For sorting chapters in a book, stranici in a menu etc.
  sorting int(10) DEFAULT 0,
  -- Semantic content types. 'въпрос', 'отговор', 'писанѥ', 'бележка', 'книга', 'заглавѥ', 'целина'…
  data_type VARCHAR(32) DEFAULT 'бележка',
  -- text, html, markdown, asc…
  data_format VARCHAR(32) DEFAULT 'text',
  -- When this content was inserted
  created_at INTEGER NOT NULL DEFAULT 0,
  -- Last time the record was touched
  tstamp INTEGER DEFAULT 0,
  -- Used in title html tag for stranici or or as h1 for other data types.
  title VARCHAR(255) DEFAULT '',
  -- Used in description meta tag when appropriate.
  description VARCHAR(255) DEFAULT '',
  -- Used in keywords meta tag.
  keywords VARCHAR(255) DEFAULT '',
  -- Used in tag cloud boxes. merged with keywords and added to keywords meta tag.
  tags VARCHAR(100) DEFAULT '',
  -- Main celini when applicable.
  body TEXT DEFAULT '',
  -- celini box in which this element should be displayed (e.g. main|главна, left|лѣва, right|дѣсна, header|глава, footer|дъно, foo, bar).
  box VARCHAR(35) DEFAULT 'main',
  -- Language of this content. All languages when empty string
  language VARCHAR(5) DEFAULT '',
  -- tuuugggooo - Experimental permissions for the content. Who can see/edit/delete it.
  -- TODO: document and design the behavior for pages which are "d" (directories) and "l" (links)
  permissions char(10) DEFAULT '-rwxr-xr-x',
  -- Show on top independently of other sorting.
  featured int(1) DEFAULT 0,
  -- Answer accepted?
  accepted int(1) DEFAULT 0,
  -- Reported as inapropriate offensive etc. higher values -very bad.
  bad int(2) DEFAULT 0,
  -- When set to 1 the record is not visible anywhere.
  deleted int(1) DEFAULT 0,
  -- Date/Time from which the record will be accessible in the site.
  start INTEGER DEFAULT 0,
  -- Date/Time till which the record will be accessible in the site.
  stop INTEGER DEFAULT 0,
  -- Who modified this целина the last time?
  changed_by INTEFER REFERENCES users(id),
  FOREIGN KEY (pid)      REFERENCES celini(id)   ON UPDATE CASCADE ON DELETE CASCADE,
  FOREIGN KEY (page_id)  REFERENCES stranici(id) ON UPDATE CASCADE ON DELETE CASCADE,
  FOREIGN KEY (user_id)  REFERENCES users(id)    ON UPDATE CASCADE,
  FOREIGN KEY (group_id) REFERENCES groups(id)   ON UPDATE CASCADE
 );
 
 CREATE INDEX celini_pid ON celini (pid);
 CREATE INDEX celini_tags ON celini (tags);
 CREATE INDEX celini_user_id_group_id ON celini (user_id, group_id);
 CREATE INDEX celini_data_type ON celini (data_type);
 CREATE INDEX celini_language ON celini (language);
 CREATE INDEX celini_page_id ON celini (page_id);
 CREATE INDEX celini_deleted ON celini (deleted);
 CREATE UNIQUE INDEX celini_alias_with_data_type_in_page_id ON celini (alias, data_type, page_id);
 
 CREATE INDEX user_group_id ON users(group_id);
 
  INSERT INTO celini (
      id, alias, body, created_at, data_format, data_type, group_id, 
      keywords, language, page_id, pid, tags, title, user_id)
  VALUES (
      0, 'начало', '', 1523807733, 'text', 'заглавѥ', 0,
      'Slovo, Слово', 'bg', 0, 0, 'начало, home', 'Слово', 0);
 

-- 201804302200 down
DROP TABLE domove;
DROP INDEX domove_published;
DROP TABLE stranici;

-- 201805012200 up
UPDATE stranici SET alias = 'коренъ',"page_type" = 'коренъ',
permissions = 'drwxr-xr-x' WHERE ( id = 0 );
INSERT INTO stranici VALUES(1,0,0,'писания','обичайна','drwxr-xr-x',1,NULL,5,5,1525187608,1525187608,0,1,0,0,NULL);
INSERT INTO stranici VALUES(2,1,0,'вести','обичайна','-rwxr-xr-x',1,NULL,5,5,1525191489,1525191489,0,1,0,0,NULL);
INSERT INTO stranici VALUES(3,0,0,'ѿносно','обичайна','-rwxr-xr-x',1,NULL,5,5,1525193683,1525193683,0,1,0,0,NULL);

UPDATE "celini" SET "body" = 'Добре дошли на страниците на слово.бг!',
"language" = 'bg-bg', "title" = 'Слово' WHERE ( "id" = 0 );
INSERT INTO "celini"
VALUES(1,'писания',0,0,1,5,5,0,'заглавѥ','text',1525178911,0,'Писания',
    '','','','Добре дошли на нашата страница за „Писания“! Опитайте и вие да
    напишете нещо, може да ви се удаде. Ура, записва!','main','bg-bg',
    '-rwxr-xr-x',0,0,0,0,0,0,5);
INSERT INTO "celini"
VALUES(3,'вести',0,0,2,5,5,0,'заглавѥ','text',1525191489,0,'Вести','',
    '','','Новините са в този раздел.','main','bg-bg','-rwxr-xr-x',0,0,0,0,0,0,5);
INSERT INTO "celini"
VALUES(4,'ѿносно',0,0,3,5,5,0,'заглавѥ','text',1525193683,0,'Ѿносно',
    '','','','Обяснения за сайта. Какъв е и за какво се говори в него. Каква е
    неговата цел.','main','bg-bg','-rwxr-xr-x',0,0,0,0,0,0,5);

-- 201805012200 down
delete from stranici where id IN(1,2,3);


-- 201805242200 up
INSERT INTO "celini" VALUES(5,'втора-целина',0,0,0,5,5,1,'целина','html',1526844885,0,'Втора целина','','','','нещо още в главната кутия на страницата','главна','bg-bg','-rwxr-xr-x',0,0,0,0,0,0,5);
INSERT INTO "celini" VALUES(6,'северна-и-южна-корея-в-спор-за-12-сервитьорки',0,0,0,5,5,2,'целина','html',1526851706,0,'Северна и Южна Корея в спор за 12 сервитьорки','','','','<p>Северна Корея настоя Южна Корея да върне обратно 12 сервитьорки, за които твърди, че са отвлечени, предава AFP.</p>
<p>Те са работели в държавен севернокорейски ресторант в Китай. Управителят на ресторанта казва, че ги излъгал и принудил да го  последват по нареждане на южнокорейските тайни служби.</p>
<p>„Южнокорейските власти трябва незабавно да върнат нашите гражданки обратно при семействата им и това ще покаже воля за подобряване на двустранните отношения“, заявяват от Пхенян.</p>
<p>Сеул настоява, че те са избягали в страната преди около две години и са останали в нея по собствено желание.</p>','главна','bg-bg','-rwxr-xr-x',0,0,0,0,0,0,5);

-- 201805242200 down
delete from celini where id in (5,6);

