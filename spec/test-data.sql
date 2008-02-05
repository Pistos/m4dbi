DELETE FROM posts;
DELETE FROM authors;

INSERT INTO authors (name) VALUES ('author1');
INSERT INTO authors (name) VALUES ('author2');

INSERT INTO posts (
    author_id, text
) SELECT
    a.id,
    'First post.'
FROM
    authors a
WHERE
    a.name = 'author1'
;

INSERT INTO posts (
    author_id, text
) SELECT
    a.id,
    'Second post.'
FROM
    authors a
WHERE
    a.name = 'author2'
;

