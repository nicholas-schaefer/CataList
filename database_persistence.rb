# interactions with the database
class DatabasePersistence
  def initialize(dbname: "cat_contacts", logger:)
    @db = PG.connect(dbname: dbname)
    @logger = logger
  end

  def query(statement, *params)
    @logger.info "#{statement}: #{params}"
    @db.exec_params(statement, params)
  end

  def add_seed_contacts
    sql = <<~SQL
      INSERT INTO contacts(first_name,    last_name,      phone,             email,               note)
          VALUES          ('adam',        'smith',        '001-999-9999',    'asmith@aol.com',    'he likes long walks on the beach'),
                          ('alfred',       null,          '002-999-9999',    'alfred@aol.com',    'friends with batman'),
                          ('alex',        'frank',        '003-999-9999',    'afrank@aol.com',    'cool as a cucumber'),
                          ('arthur',      'clark',        '004-999-9999',    'aclark@aol.com',    'kind of out there dude'),
                          ('beyonce',     null,           '005-999-9999',    'cuff_it@aol.com',   'so hot, she doesn''t even have a last name'),
                          ('zlatan',      'ibrahimović',  '006-999-9999',    'zlatan@aol.com',    'swedish soccer player'),
                          (null,          'bond',         '007-999-9999',    'shaken@aol.com',    'wonder what his first name is?!!!'),
                          ('special one', 'mourinho',     '008-999-9999',    'jose@aol.com',      'serial winner'),
                          ('fred',        'the machine',  '009-999-9999',    'fred@aol.com',      'russians be where'),
                          ('jason',       'bourne',       '011-999-9999',    'shell@aol.com',     'what a man'),
                          ('michael',     'jackson',      '012-999-9999',    'glove@aol.com',     'he''s a thriller'),
                          ('doughboy',    null,           '013-999-9999',    'hehe@aol.com',      'Why is he always so hungry. His stomach is huge!'),
                          ('franken',     'stein',        '014-999-9999',    'scary@aol.com',     'he is not the monster - he is the one who created the monster!'),
                          ('cat',         'girl',         '015-999-9999',    'meow@aol.com',      'looking feline fine'),
                          ('doctor',      'who',          '016-999-9999',    'tardis@aol.com',    'still no idea who they are'),
                          ('peter',       'pan',          '017-999-9999',    'hookhater@aol.com', 'that lad has an amazing skincare regimen'),
                          ('scooby',      'doo',          '018-999-9999',    'snacktime@aol.com', 'a talking dog'),
                          ('jensen',      'ackles',       '019-999-9999',    'dean@aol.com',      'would give his life for his brother'),
                          ('frodo',        null,          '020-999-9999',    'hobbits42@aol.com', 'found that one a long way from the shire'),
                          ('wishbone',     null,          '021-999-9999',    'roof@aol.com',      'what great stories'),
                          ('the',         'ood',          '022-999-9999',    'oooooood@aol.com',  ''),
                          ('donkey',      'kong',         '023-999-9999',    'kingkong@aol.com',  'big dude');
    SQL
    query(sql)
  end

  def add_image(contact_id:, file_type:, file_extension: )
    sql = <<~SQL
    INSERT INTO profile_images(contact_id, file_type, file_extension)
    VALUES                    ($1,         $2,        $3)
    RETURNING profile_image_id
    SQL
    query(sql, contact_id, file_type, file_extension)
  end

  def delete_image(profile_image_id:)
    sql = <<~SQL
    DELETE FROM profile_images
    WHERE profile_image_id = $1
    SQL
    query(sql, profile_image_id)
  end

  def add_contact(first_name:, last_name:, phone_number:, email:, note: )
    sql = <<~SQL
    INSERT INTO contacts(first_name, last_name, phone, email, note)
    VALUES              ($1,         $2,        $3,    $4,    $5)
    RETURNING id
    SQL
    query(sql, first_name, last_name, phone_number, email, note)
  end

  def edit_contact(first_name:, last_name:, phone_number:, email:, note:, id: )
    sql = <<~SQL
    UPDATE contacts
    SET (first_name, last_name, phone, email, note) =
        ($2,         $3,        $4,    $5,    $6)
    WHERE id = $1
    SQL
    query(sql, id, first_name, last_name, phone_number, email, note)
  end

  def delete_contact(id:)
    sql = <<~SQL
    DELETE FROM contacts
    WHERE id = $1
    SQL
    query(sql, id)
  end

  def delete_all_contacts
    sql = <<~SQL
    DELETE FROM contacts
    SQL
    query(sql)
  end

  # method not currently in use
  # We have upgraded this method below
  # def find_contact(id:)
  #   sql = <<~SQL
  #   SELECT * FROM contacts
  #   WHERE id = $1;
  #   SQL
  #   query(sql, id)
  # end

  def find_contact(id:)
    sql = <<~SQL
    SELECT c.id, c.first_name, c.last_name, c.phone, c.email, c.note, pi.file_name
    FROM contacts AS c
    LEFT JOIN profile_images AS pi ON c.id = pi.contact_id
    WHERE c.id = $1
    ORDER BY pi.created_at DESC
    LIMIT 1;
    SQL
    query(sql, id)
  end

  # method not currently in use
  # we are using below method currently
  # def find_all_contacts
  #   find_selected_contacts(limit: contacts_total_count, offset:0)
  # end

  def find_selected_contacts(limit:, offset:0)
    sql = <<~SQL
    SELECT *, lower(concat_ws(' ', TRIM(first_name), TRIM(last_name))) AS full_name FROM contacts
    ORDER BY full_name
    LIMIT $1
    OFFSET $2
    SQL
    query(sql, limit, offset)
  end

  def contacts_total_count
    sql = <<~SQL
    SELECT count(*) AS tuple_count FROM contacts;
    SQL
    result = query(sql)
    result = result.first["tuple_count"]
    result = result.to_i
  end

end
