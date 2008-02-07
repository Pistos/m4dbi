CREATE TABLE authors (
    id SERIAL NOT NULL PRIMARY KEY,
    name VARCHAR( 128 ) NOT NULL
);

CREATE TABLE posts (
    id SERIAL NOT NULL PRIMARY KEY,
    author_id INTEGER NOT NULL REFERENCES authors( id ),
    text VARCHAR( 4096 ) NOT NULL
);

CREATE TABLE empty_table (
    id SERIAL NOT NULL PRIMARY KEY,
    i INTEGER
);