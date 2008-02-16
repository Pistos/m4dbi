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
    c5 INTEGER
);