-- psql -d cat_contacts < schema.sql;
-- psql -d
/*
    Create Database if it does not exist (from within)
*/
-- SELECT 'CREATE DATABASE cat_contacts'
-- WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'cat_contacts')\gexec

/*
    Create Table
*/
/*
    num_nonulls() inspiration to ensure contact always entered with at east either first or last name:
    https://stackoverflow.com/a/66370341
*/
-- CREATE TABLE contacts (
--     id uuid DEFAULT gen_random_uuid(),
--     first_name varchar(250),
--     last_name varchar(250),
--     phone varchar(30),
--     email varchar(250),
--     note varchar(250),
--     PRIMARY KEY (id),
--     CONSTRAINT need_a_name CHECK (
--         num_nonnulls(first_name, last_name) >= 1 AND
--         NOT (TRIM(first_name) = '' AND TRIM(last_name) = '')
--         )
-- );


-- DROP TABLE profile_images
-- CREATE TABLE profile_images (
--     profile_image_id uuid DEFAULT gen_random_uuid(),
--     contact_id uuid references contacts(id) ON DELETE CASCADE,
--     file_type varchar(250) NOT NULL,
--     file_extension varchar(250) NOT NULL,
--     file_name varchar(501) GENERATED ALWAYS AS (profile_image_id || '.' || file_extension) STORED,
--     created_at timestamp NOT NULL DEFAULT (timezone('utc', now())),
--     PRIMARY KEY (profile_image_id)
-- )

SELECT * FROM contacts;
SELECT * FROM profile_images;
-- \d profile_images

-- INSERT INTO profile_images (file_type, file_extension)
--     VALUES('image/jpeg', 'jpg');

-- INSERT INTO profile_images (file_type, file_extension)
--     VALUES('image/png', 'png');

-- UPDATE profile_images
--     SET contact_id = '44179234-39c5-4e60-8da8-2750b387f6a8'

-- SELECT * FROM profile_images;


-- SELECT c.id, c.first_name, c.last_name, c.phone, c.email, c.note, pi.file_name FROM contacts AS c
--     LEFT JOIN profile_images AS pi ON c.id = pi.contact_id
--     WHERE c.id = '024b318a-a30c-4363-b1f4-9f6f87b6bb3f'
--     ORDER BY pi.created_at DESC
--     LIMIT 1

-- select now() at time zone 'utc';


/*
    Populate Database
*/

-- INSERT INTO contacts(first_name,    last_name,      phone,             email,              note)
--     VALUES          ('adam',        'smith',        '001-999-9999',    'asmith@aol.com',    'he likes long walks on the beach'),
--                     ('alfred',       null,          '002-999-9999',    'alfred@aol.com',    'friends with batman'),
--                     ('alex',        'frank',        '003-999-9999',    'afrank@aol.com',    'cool as a cucumber'),
--                     ('arthur',      'clark',        '004-999-9999',    'aclark@aol.com',    'kind of out there dude'),
--                     ('beyonce',     null,           '005-999-9999',    'cuff_it@aol.com',   'so hot, she doesn''t even have a last name'),
--                     ('zlatan',      'ibrahimović',  '006-999-9999',    'zlatan@aol.com',    'swedish soccer player'),
--                     (null,          'bond',         '007-999-9999',    'shaken@aol.com',    'wonder what his first name is?!!!'),
--                     ('special one', 'mourinho',     '008-999-9999',    'jose@aol.com',      'serial winner'),
--                     ('fred',        'the machine',  '009-999-9999',    'fred@aol.com',      'russians be where'),
--                     ('zaha',        null,           '010-999-9999',    'zaha@aol.com',      'he would be friends with zinedane serial winner');


-- INSERT INTO contacts(first_name,    last_name,      phone,             email,              note)
--     VALUES          (' ',        '',        '001-999-9999',    'asmith@aol.com',    'he likes long walks on the beach');


-- \d contacts

-- SELECT * FROM contacts;

/*
    Get all the contacts
*/
-- SELECT * FROM contacts
--     ORDER BY first_name, last_name;

/*
    Get the contacts
*/
-- SELECT first_name, last_name FROM contacts
--     ORDER BY first_name, last_name
--     LIMIT 5;

/*
    Sort by full name
*/
-- SELECT *, lower(concat_ws(' ', TRIM(first_name), TRIM(last_name))) AS full_name FROM contacts
--     ORDER BY full_name;

/*
    Limits and ofsetts
*/
-- SELECT *, concat_ws(' ', first_name, last_name) AS full_name FROM contacts
--     ORDER BY full_name
--     LIMIT 4
--     OFFSET 1


/*
    count of rows in the database
*/
-- SELECT count(*) AS contacts_count FROM contacts;

-- SELECT last_name, length(last_name) FROM contacts
--     WHERE id = '61f1a1ea-780d-4263-9554-6e4118a19640';

-- SELECT ''::char(5) = ''::char(5)     AS eq1
--      , ''::char(5) = '  '::char(5)   AS eq2
--      , ''::char(5) = '    '::char(5) AS eq3;

-- ALTER TABLE contacts DROP CONSTRAINT need_a_name;




-- ALTER TABLE contacts
-- ADD CONSTRAINT need_a_name
-- CHECK (
--     num_nonnulls(first_name, last_name) >= 1 AND
--     NOT (TRIM(first_name) = '' AND TRIM(last_name) = '')
-- );
