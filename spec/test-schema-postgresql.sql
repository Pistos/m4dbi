CREATE TABLE authors (
    id SERIAL NOT NULL PRIMARY KEY,
    name VARCHAR( 128 ) NOT NULL
);

CREATE TABLE posts (
    id SERIAL NOT NULL PRIMARY KEY,
    author_id INTEGER NOT NULL REFERENCES authors( id ),
    text VARCHAR( 4096 ) NOT NULL
);

CREATE TABLE fans (
    id SERIAL NOT NULL PRIMARY KEY,
    name VARCHAR( 128 ) NOT NULL
);

CREATE TABLE authors_fans (
    author_id INTEGER NOT NULL REFERENCES authors( id ),
    fan_id INTEGER NOT NULL REFERENCES fans( id )
);

CREATE TABLE empty_table (
    id SERIAL NOT NULL PRIMARY KEY,
    i INTEGER
);

CREATE TABLE many_col_table (
    id SERIAL NOT NULL PRIMARY KEY,
    c1 INTEGER,
    c2 INTEGER,
    c3 INTEGER,
    c4 INTEGER,
    c5 INTEGER,
    ts TIMESTAMP
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
      id SERIAL PRIMARY KEY
    , c1 INTEGER
    , class VARCHAR( 32 )
    , dup BOOLEAN
);

CREATE TABLE has_all_defaults (
      id SERIAL PRIMARY KEY
    , time_created TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE has_many_rows (
    id INTEGER
);
