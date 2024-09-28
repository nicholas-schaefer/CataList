/*
    Create Tables
*/

-- CONSTRAINT need_a_name, ensures contact always entered with at east either first or last name
-- need_a_name inspiration: https://stackoverflow.com/a/66370341
CREATE TABLE contacts (
    id uuid DEFAULT gen_random_uuid(),
    first_name varchar(250),
    last_name varchar(250),
    phone varchar(30),
    email varchar(250),
    note varchar(250),
    PRIMARY KEY (id),
    CONSTRAINT need_a_name CHECK (
        num_nonnulls(first_name, last_name) >= 1 AND
        NOT (TRIM(first_name) = '' AND TRIM(last_name) = '')
        )
);

CREATE TABLE profile_images (
    profile_image_id uuid DEFAULT gen_random_uuid(),
    contact_id uuid references contacts(id) ON DELETE CASCADE,
    file_type varchar(250) NOT NULL,
    file_extension varchar(250) NOT NULL,
    file_name varchar(501) GENERATED ALWAYS AS (profile_image_id || '.' || file_extension) STORED,
    created_at timestamp NOT NULL DEFAULT (timezone('utc', now())),
    PRIMARY KEY (profile_image_id)
)