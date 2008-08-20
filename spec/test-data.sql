DELETE FROM posts;
DELETE FROM authors_fans;
DELETE FROM fans;
DELETE FROM authors;
DELETE FROM many_col_table;
DELETE FROM mcpk;

INSERT INTO authors (id, name) VALUES ( 1, 'author1' );
INSERT INTO authors (id, name) VALUES ( 2, 'author2' );
INSERT INTO authors (id, name) VALUES ( 3, 'author3' );

INSERT INTO posts (
    id, author_id, text
) SELECT
    1,
    a.id,
    'First post.'
FROM
    authors a
WHERE
    a.name = 'author1'
;

INSERT INTO posts (
    id, author_id, text
) SELECT
    2,
    a.id,
    'Second post.'
FROM
    authors a
WHERE
    a.name = 'author2'
;

INSERT INTO posts (
    id, author_id, text
) SELECT
    3,
    a.id,
    'Third post.'
FROM
    authors a
WHERE
    a.name = 'author1'
;

INSERT INTO fans ( id, name ) VALUES ( 1, 'fan1' );
INSERT INTO fans ( id, name ) VALUES ( 2, 'fan2' );
INSERT INTO fans ( id, name ) VALUES ( 3, 'fan3' );
INSERT INTO fans ( id, name ) VALUES ( 4, 'fan4' );
INSERT INTO fans ( id, name ) VALUES ( 5, 'fan5' );


INSERT INTO authors_fans ( author_id, fan_id ) VALUES ( 1, 2 );
INSERT INTO authors_fans ( author_id, fan_id ) VALUES ( 1, 3 );
INSERT INTO authors_fans ( author_id, fan_id ) VALUES ( 2, 3 );
INSERT INTO authors_fans ( author_id, fan_id ) VALUES ( 2, 4 );


INSERT INTO many_col_table ( c1,c2,c3 ) VALUES ( 100, 50, 20 );
INSERT INTO many_col_table ( c1,c3 ) VALUES ( 100, 40 );
INSERT INTO many_col_table ( ts ) VALUES ( NOW() );

INSERT INTO mcpk ( kc1, kc2, val ) VALUES ( 1, 1, 'one one' );
INSERT INTO mcpk ( kc1, kc2, val ) VALUES ( 2, 2, 'two two' );
INSERT INTO mcpk ( kc1, kc2, val ) VALUES ( 3, 4, 'three four' );
INSERT INTO mcpk ( kc1, kc2, val ) VALUES ( 5, 6, 'five six' );
