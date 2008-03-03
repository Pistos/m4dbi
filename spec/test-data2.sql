DELETE FROM posts;
DELETE FROM authors;

INSERT INTO authors (id, name) VALUES ( 11, 'author11' );
INSERT INTO authors (id, name) VALUES ( 12, 'author12' );
INSERT INTO authors (id, name) VALUES ( 13, 'author13' );

INSERT INTO posts (
    id, author_id, text
) SELECT
    11,
    a.id,
    'First post.'
FROM
    authors a
WHERE
    a.name = 'author11'
;

INSERT INTO posts (
    id, author_id, text
) SELECT
    12,
    a.id,
    'Second post.'
FROM
    authors a
WHERE
    a.name = 'author12'
;

INSERT INTO posts (
    id, author_id, text
) SELECT
    13,
    a.id,
    'Third post.'
FROM
    authors a
WHERE
    a.name = 'author11'
;
