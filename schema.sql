-- psql -d cat_contacts < schema.sql;

/*
    Create Database if it does not exist
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
--     CONSTRAINT need_a_name CHECK (num_nonnulls(first_name, last_name) >= 1)
-- );

/*
    Populate Database
*/

-- INSERT INTO contacts(first_name, last_name, phone, email, note)
--     VALUES ('beyonce', null, '999-999-9999', 'biteme@gmail.com', 'here I am'),
--            ('nick', 'schaefer', '999-999-9999', 'biteme@gmail.com', 'here I am');


-- \d contacts
-- SELECT * FROM contacts;


