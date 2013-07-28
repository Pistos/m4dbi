CREATE TABLE authors (
    id INTEGER NOT NULL PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR( 128 ) NOT NULL
);

CREATE TABLE posts (
    id INTEGER NOT NULL PRIMARY KEY AUTO_INCREMENT,
    author_id INTEGER NOT NULL REFERENCES authors( id ),
    text VARCHAR( 4096 ) NOT NULL
);

CREATE TABLE fans (
    id INTEGER NOT NULL PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR( 128 ) NOT NULL
);

CREATE TABLE authors_fans (
    author_id INTEGER NOT NULL REFERENCES authors( id ),
    fan_id INTEGER NOT NULL REFERENCES fans( id )
);

CREATE TABLE empty_table (
    id INTEGER NOT NULL PRIMARY KEY AUTO_INCREMENT,
    i INTEGER
);

CREATE TABLE many_col_table (
    id INTEGER NOT NULL PRIMARY KEY AUTO_INCREMENT,
    c1 INTEGER,
    c2 INTEGER,
    c3 INTEGER,
    c4 INTEGER,
    c5 INTEGER,
    ts DATETIME
);

CREATE TABLE non_id_pk (
    str VARCHAR( 128 ) NOT NULL PRIMARY KEY,
    c1 INTEGER,
    c2 INTEGER
);

CREATE TABLE mcpk (
    kc1 INTEGER NOT NULL,
    kc2 INTEGER NOT NULL,
    val VARCHAR( 20 ) NOT NULL,
    PRIMARY KEY( kc1, kc2 )
);

CREATE TABLE conflicting_cols (
    id INTEGER NOT NULL PRIMARY KEY AUTO_INCREMENT,
    c1 INTEGER,
    class VARCHAR( 32 ),
    dup INTEGER
);

CREATE TABLE has_all_defaults (
      id INTEGER NOT NULL PRIMARY KEY AUTO_INCREMENT
    , time_created DATETIME NOT NULL DEFAULT '2013-01-01 00:00:00'
);

CREATE TABLE has_many_rows (
    id INTEGER
);
