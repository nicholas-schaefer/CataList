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

  def find_contact(id:)
    sql = <<~SQL
    SELECT * FROM contacts
    WHERE id = $1;
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
