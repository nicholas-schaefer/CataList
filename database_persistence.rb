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
