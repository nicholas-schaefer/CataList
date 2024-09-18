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
    sql = <<~SQL
    SELECT *, concat_ws(' ', first_name, last_name) AS full_name FROM contacts
    ORDER BY full_name;
    SQL
    query(sql)
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
