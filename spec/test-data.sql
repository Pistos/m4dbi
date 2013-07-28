DELETE FROM posts;
DELETE FROM authors_fans;
DELETE FROM fans;
DELETE FROM authors;
DELETE FROM many_col_table;
DELETE FROM non_id_pk;
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
INSERT INTO many_col_table ( ts ) VALUES ( CURRENT_TIMESTAMP );

INSERT INTO non_id_pk ( str, c1, c2 ) VALUES ( 'one', 1, 2 );
INSERT INTO non_id_pk ( str, c1, c2 ) VALUES ( 'two', 2, 4 );
INSERT INTO non_id_pk ( str, c1, c2 ) VALUES ( 'three', 3, 6 );

INSERT INTO mcpk ( kc1, kc2, val ) VALUES ( 1, 1, 'one one' );
INSERT INTO mcpk ( kc1, kc2, val ) VALUES ( 2, 2, 'two two' );
INSERT INTO mcpk ( kc1, kc2, val ) VALUES ( 3, 4, 'three four' );
INSERT INTO mcpk ( kc1, kc2, val ) VALUES ( 5, 6, 'five six' );

INSERT INTO has_many_rows (id) VALUES (1);
INSERT INTO has_many_rows (id) VALUES (2);
INSERT INTO has_many_rows (id) VALUES (3);
INSERT INTO has_many_rows (id) VALUES (4);
INSERT INTO has_many_rows (id) VALUES (5);
INSERT INTO has_many_rows (id) VALUES (6);
INSERT INTO has_many_rows (id) VALUES (7);
INSERT INTO has_many_rows (id) VALUES (8);
INSERT INTO has_many_rows (id) VALUES (9);
INSERT INTO has_many_rows (id) VALUES (10);
INSERT INTO has_many_rows (id) VALUES (11);
INSERT INTO has_many_rows (id) VALUES (12);
INSERT INTO has_many_rows (id) VALUES (13);
INSERT INTO has_many_rows (id) VALUES (14);
INSERT INTO has_many_rows (id) VALUES (15);
INSERT INTO has_many_rows (id) VALUES (16);
INSERT INTO has_many_rows (id) VALUES (17);
INSERT INTO has_many_rows (id) VALUES (18);
INSERT INTO has_many_rows (id) VALUES (19);
INSERT INTO has_many_rows (id) VALUES (20);
INSERT INTO has_many_rows (id) VALUES (21);
INSERT INTO has_many_rows (id) VALUES (22);
INSERT INTO has_many_rows (id) VALUES (23);
INSERT INTO has_many_rows (id) VALUES (24);
INSERT INTO has_many_rows (id) VALUES (25);
INSERT INTO has_many_rows (id) VALUES (26);
INSERT INTO has_many_rows (id) VALUES (27);
INSERT INTO has_many_rows (id) VALUES (28);
INSERT INTO has_many_rows (id) VALUES (29);
INSERT INTO has_many_rows (id) VALUES (30);
INSERT INTO has_many_rows (id) VALUES (31);
INSERT INTO has_many_rows (id) VALUES (32);
