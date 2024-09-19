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

SELECT * FROM contacts;

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
-- SELECT *, concat_ws(' ', first_name, last_name) AS full_name FROM contacts
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
