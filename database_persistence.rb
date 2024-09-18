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

  def find_contact(contact_id)
    sql = <<~SQL
    SELECT * FROM contacts
    WHERE id = $1;
    SQL
    query(sql, contact_id)
  end

  def find_all_contacts
    find_selected_contacts(limit: contacts_total_count, offset:0)
  end

  def find_selected_contacts(limit: 4, offset:0)
    sql = <<~SQL
    SELECT *, concat_ws(' ', first_name, last_name) AS full_name FROM contacts
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
