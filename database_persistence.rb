class DatabasePersistence
  def initialize(dbname: "cat_contacts", logger:)
    # @conn ||= PG.connect(dbname: dbname)
    @db = PG.connect(dbname: dbname)
    @logger = logger
  end

  def query(statement, *params)
    @logger.info "#{statement}: #{params}"
    @db.exec_params(statement, params)
  end

  def add_seed_contacts
    sql = <<~SQL
    INSERT INTO contacts(first_name,    last_name,      phone,             email,              note)
        VALUES          ('adam',        'smith',        '001-999-9999',    'asmith@aol.com',    'he likes long walks on the beach'),
                        ('alfred',       null,          '002-999-9999',    'alfred@aol.com',    'friends with batman'),
                        ('alex',        'frank',        '003-999-9999',    'afrank@aol.com',    'cool as a cucumber'),
                        ('arthur',      'clark',        '004-999-9999',    'aclark@aol.com',    'kind of out there dude'),
                        ('beyonce',     null,           '005-999-9999',    'cuff_it@aol.com',   'so hot, she doesn''t even have a last name'),
                        ('zlatan',      'ibrahimović',  '006-999-9999',    'zlatan@aol.com',    'swedish soccer player'),
                        (null,          'bond',         '007-999-9999',    'shaken@aol.com',    'wonder what his first name is?!!!'),
                        ('special one', 'mourinho',     '008-999-9999',    'jose@aol.com',      'serial winner'),
                        ('fred',        'the machine',  '009-999-9999',    'fred@aol.com',      'russians be where'),
                        ('zaha',        null,           '010-999-9999',    'zaha@aol.com',      'he would be friends with zinedane serial winner');
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

  # We are upgrading this method below
  def find_contact(id:)
    sql = <<~SQL
    SELECT * FROM contacts
    WHERE id = $1;
    SQL
    query(sql, id)
  end

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

  def find_all_contacts
    find_selected_contacts(limit: contacts_total_count, offset:0)
  end

  def find_selected_contacts(limit: 4, offset:0)
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

  def string_also_an_integer?(input)
    regex = /^\d+$/
    !!(regex =~ input)
  end

end



  # def initialize(logger)
  #   @db = if Sinatra::Base.production?
  #     PG.connect(ENV['DATABASE_URL'])
  #   else
  #     PG.connect(dbname: "todos")
  #   end
  #   @logger = logger
  # end

  # def query(statement, *params)
  #   @logger.info "#{statement}: #{params}"
  #   @db.exec_params(statement, params)
  # end
