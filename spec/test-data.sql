DELETE FROM posts;
DELETE FROM authors;

INSERT INTO authors (id, name) VALUES ( 1, 'author1' );
INSERT INTO authors (id, name) VALUES ( 2, 'author2' );

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

