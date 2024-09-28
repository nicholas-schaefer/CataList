# Managing user authentication
class User
  attr_accessor :name
  def initialize(user_is_authenticated: false, user_name: nil)
    @is_authenticated = user_is_authenticated
    @name = user_name
  end

  def logged_in?
    is_authenticated
  end

  def log_in
    self.is_authenticated = true
  end

  def log_out
    self.is_authenticated = false
    self.name = nil
  end

  def credentials_correct?(username_input:, password_input:)
    credentials = load_user_credentials

    return false unless credentials.key?(username_input)
    valid_username = username_input

    bcrypt_password = BCrypt::Password.new(credentials[valid_username])
    bcrypt_password == password_input
  end

  private
  attr_accessor :is_authenticated

  def load_user_credentials
    credentials_path = File.expand_path("../users.yaml", __FILE__)
    YAML.load_file(credentials_path)
  end

end
