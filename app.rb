require 'bundler/setup'
require "ostruct"

require 'sinatra'
require 'pg'
require "yaml"
require "bcrypt"

require_relative 'database_persistence'
require_relative 'f_system'
require_relative 'user'
require_relative 'form_input'

configure do
  set :erb, :escape_html => true

  enable :sessions
  set :session_secret, SecureRandom.hex(32)
end

configure(:development) do
  require 'pry'
  require "sinatra/reloader"
  also_reload "database_persistence.rb"
  also_reload "f_system.rb"
  also_reload "user.rb"
  also_reload "form_input.rb"
end

helpers do
  def full_name(first_name:"", last_name:"")
    first_name&.capitalize!
    last_name&.capitalize!
    [first_name, last_name].join(" ")
  end
end

before do
  # Persistent Storage
  @storage ||= DatabasePersistence.new(logger: logger)
  @f_system ||= Fsystem.new()
  @form_input ||= FormInput.new()
  session[:user] ||= User.new()
  @user = session[:user]
  session[:previous_path] ||= []

  # Transient Storage
  @request_errors = []
  @add_contact_form = {
    first_name: "John",
    last_name: "Wick",
    phone_number: "867-5309",
    email: "jwick@gmail.com",
    note: "no one messes with john wick!"
  }
  @newly_added_contact_id = ""
  @contact_successfully_edited = false
  @contact_successfully_deleted = false
  @contacts_successfully_seeded = false
  @count_contacts_successfully_seeded = nil

  # Constants
  @app_name = "CataList".freeze
  @pagination_item_limit = 10

  # Methods
  handle_authentication
end

#######################################
# Authentication
#   additional methods in `User` class
#######################################

def handle_authentication
  if (@user.logged_in? == false) && !(request.path_info == "/account")
    session[:previous_path][0] = request.fullpath
    redirect '/account'
  end
end


#######################################
# Sanitization
#   additional methods in `FormInput` class
#######################################

## Method inspired by https://stackoverflow.com/a/47511286
def valid_uuid_format?(uuid)
  uuid_regex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/
  return true if uuid_regex.match?(uuid.to_s.downcase)
end


#######################################
# Pages
#   every page in the app
#######################################

def load_account_management_page
  @login_status =
    @user.logged_in? ? "#{@user.name} is now logged in" : "logged out"

  @page_title_tag = page_title_tag(title:"account management")
  halt erb :admin, :layout => :layout
end

def load_contact_page
  param_contact_id = params['contact_id']

  if !contact_exists?(param_contact_id)
    @request_errors << "No contact exists at that path"
    halt 404
  end

  @contact = @storage.find_contact(id: param_contact_id).first
  @contact_profile_images = @storage.find_contact_profile_pics(id: param_contact_id)

  file_to_load = @contact["file_name"] ? @contact["file_name"] : "_no_profile_default/no-image-found-placeholder.jpg"
  @contact["image_file_path"] = File.join("/images/profiles", file_to_load)

  @path_slug = param_contact_id
  @path_info = request.path_info
  @edit_action = "#{@path_info}/edit"
  @delete_action = "#{@path_info}/delete"
  @page_title_tag = page_title_tag(title:"contact")

  @edit_param_present = !!request.params["edit"]

  erb :contact, :layout => :layout
end

def load_all_contacts_page
  @path_info = "/contacts" # needed to hard code this, handle form submit from other pages, can't use @path_info = request.path_info

  total_contacts_count = @storage.contacts_total_count
  total_pages = nil
  if total_contacts_count.zero?
    total_pages = 1
  else
    total_pages = ((total_contacts_count-1)/(@pagination_item_limit)) + 1
  end
  @pages = (1..total_pages).to_a

  pagination_requested = params['page'] || '1'

  unless string_also_an_integer?(pagination_requested) && @pages.any?(pagination_requested.to_i)
    @request_errors << "Given page number is not in range"
    halt 404
  end

  @validated_pagination_int = pagination_requested.to_i
  pagination_offset = (@validated_pagination_int - 1) * @pagination_item_limit

  @contacts = @storage.find_selected_contacts(limit: @pagination_item_limit, offset:pagination_offset)
  @page_title_tag = page_title_tag(title:"home")

  @edit_param_present = !!request.params["edit"]

  erb :index, :layout => :layout
end

def load_page_not_found
  @page_title_tag = page_title_tag(title:"page not found")
  erb :page_not_found, :layout => :layout
end


#######################################
# Routes
#######################################

post '/account' do
  username = params['user_name']
  password = params['user_password']

  if @user.credentials_correct?(username_input: username, password_input: password)
    @user.name = username
    @user.log_in
    redirect session[:previous_path].shift
  end
  load_account_management_page
end

get '/account' do
  load_account_management_page
end

post '/account/log_out' do
  @user.log_out
  redirect '/account'
end

get '/images/profiles/_no_profile_default/no-image-found-placeholder.jpg' do
  not_found_image = File.join(@f_system.data_images_profiles_path, '_no_profile_default', 'no-image-found-placeholder.jpg' )
  send_file(not_found_image)
end

get '/images/profiles/:profile_pic_id' do
  profile_pic_path = File.join(@f_system.data_images_profiles_path, params['profile_pic_id'])

  if !File.exist?(profile_pic_path)
    @request_errors << "profile image not found at that path"
    halt 404
  end

  send_file(profile_pic_path)
end

get '/' do
  redirect to('/contacts')
end

get '/contacts' do
  load_all_contacts_page
end

# Add a new contact
post '/contacts' do
  handle_contact_text_creation(
    first_name: params['first_name'],
    last_name: params['last_name'],
    phone_number: params['phone_number'],
    email: params['email'],
    note: params['note'])

  if @request_errors.empty?
    profile_pic = params['profile_pic']
    newly_created_profile_image_id = nil
    if profile_pic
      newly_created_profile_image_id =
        handle_image_upload(profile_pic: profile_pic, picture_file_type: profile_pic['type'], contact_id: @newly_added_contact_id,)
    end

    image_upload_failed_abort_required = (newly_created_profile_image_id == false)
    if image_upload_failed_abort_required
      @storage.delete_contact(id: @newly_added_contact_id)
      @newly_added_contact_id = ""
    end
  end

  load_all_contacts_page
end

# Add Preset Entries to a database
post '/contacts/seed_storage' do
  begin
    res = @storage.add_seed_contacts()
    @count_contacts_successfully_seeded = res.cmd_tuples
  rescue StandardError => e
    @request_errors << "seeding failed"
  else
    @contacts_successfully_seeded = true
  end
  load_all_contacts_page
end

# Refreshes after seeing go the main contacts listing page
get '/contacts/seed_storage' do
  redirect to('/contacts')
end

# Delete All Contacts
post '/contacts/delete_all' do
  @f_system.delete_all_file_system_images
  begin
    res = @storage.delete_all_contacts()
  rescue StandardError => e
    @request_errors << "deletion failed"
  else
    @contact_successfully_deleted = true
  end
  load_all_contacts_page
end

# Refreshes after delete all the url to the main contacts listing page
get '/contacts/delete_all' do
  redirect to('/contacts')
end

# Delete an existing contact
post '/contacts/:contact_id/delete' do
  id = params['contact_id']
  begin
    raise("contact not found") unless contact_exists?(id)
    contact_profile_images = @storage.find_contact_profile_pics(id: id)
    res = @storage.delete_contact(id: id)

    contact_profile_images.each do |tuple|
      deletion_response = @f_system.delete_file_system_image(image_basename: tuple["file_name"])
    end

  rescue StandardError => e
    @request_errors << "contact deletion failed. contact may have already been deleted."
  else
    @contact_successfully_deleted = true
  end
  load_all_contacts_page
end

get '/contacts/:contact_id/delete' do
  redirect to('/contacts')
end

# Delete a profile image
post '/contacts/:contact_id/delete_profile_pic/:profile_image_id' do
  # erb "<p>this worked</p>"
  id = params['contact_id']
  profile_image_id = params['profile_image_id']
  # binding.pry
  begin
    raise("contact not found") unless contact_exists?(id)
    raise("image not found") unless profile_pic_exists?(profile_image_id)

    profile_pic_details = @storage.find_profile_pic(pic_id: profile_image_id)
    profile_image_file_name = profile_pic_details.first['file_name']

    res = @storage.delete_image(profile_image_id: profile_image_id)
  rescue StandardError => e
    @request_errors << "image deletion failed."
  else
  end

  @f_system.delete_file_system_image(image_basename: profile_image_file_name)

  redirect "/contacts/#{id}?edit=true"
  # load_contact_page
end


# Update profile image's last modified time
post '/contacts/:contact_id/make_featured_image/:profile_image_id' do
  # erb "<p>this worked</p>"
  id = params['contact_id']
  profile_image_id = params['profile_image_id']
  # binding.pry
  begin
    raise("contact not found") unless contact_exists?(id)
    raise("image not found") unless profile_pic_exists?(profile_image_id)
    # binding.pry

    res = @storage.edit_image_last_modified_time(profile_image_id: profile_image_id)
  rescue StandardError => e
    @request_errors << "image order change failed"
    # erb "<p>fail</p>"
    load_contact_page
  else
  end
  redirect "/contacts/#{id}?edit=true"

  # load_contact_page
end

# Update contact details
# inspiration: https://gist.github.com/runemadsen/3905593 and https://stackoverflow.com/questions/2686044/file-upload-with-sinatra
post '/contacts/:contact_id' do
  id = params['contact_id']
  begin
    raise("contact not found") unless contact_exists?(id)
  rescue  StandardError => e
    @request_errors << "contact edit failed. contact may have already been deleted."
    load_all_contacts_page
  else
    profile_pic = params['profile_pic']
    newly_created_profile_image_id = nil
    if profile_pic
      newly_created_profile_image_id =
        handle_image_upload(profile_pic: profile_pic, picture_file_type: profile_pic['type'], contact_id: id,)
    end

    image_upload_failed_abort_required = (newly_created_profile_image_id == false)
    unless image_upload_failed_abort_required
      handle_contact_text_update(
        contact_id: id,
        first_name: params['first_name'],
        last_name: params['last_name'],
        phone_number: params['phone_number'],
        email: params['email'],
        note: params['note'])

      if @contact_successfully_edited == false
        @storage.delete_image(profile_image_id: newly_created_profile_image_id)
      end
    end
    load_contact_page
  end
end

# Get contact details
get '/contacts/:contact_id' do
  load_contact_page
end

# When there's a 404 error this is what happens
not_found do
  load_page_not_found
end


#######################################
# Uncategorized
#######################################

def handle_image_upload(profile_pic:, picture_file_type:, contact_id:)
  picture_file_extension = @form_input.acceptable_image_type?(picture_file_type)
  if picture_file_extension == false
    @request_errors << "Invalid filetype, png, or jpg required"
    false
  else
    query_add_image = @storage.add_image(
      contact_id: contact_id,
      file_type: picture_file_type,
      file_extension: picture_file_extension)

    profile_image_id = query_add_image.first["profile_image_id"]

    new_file_name = "#{profile_image_id}.#{picture_file_extension}"
    absolute_path = File.join(@f_system.data_images_profiles_path, new_file_name)

    write_operation = (File.open(absolute_path, mode = 'wb') do |f|
      file = profile_pic['tempfile']
      f.write(file.read)
    end)
    raise("write operation failed") unless write_operation > 0
    profile_image_id
  end
end

def handle_contact_text_creation(first_name:, last_name:, phone_number:, email:, note:)
  first_name = @form_input.sanitize_field_first_name(first_name)
  last_name = @form_input.sanitize_field_last_name(last_name)
  phone_number = @form_input.sanitize_field_phone_number(phone_number)
  email = @form_input.sanitize_field_email(email)
  note = @form_input.sanitize_field_note(note)
  begin
    res = @storage.add_contact(
            first_name: first_name,
            last_name: last_name,
            phone_number: phone_number,
            email: email,
            note: note)
  rescue StandardError => e
    regex = /violates check constraint "need_a_name"/
    if !!(regex =~ e.message)
      @request_errors << "Both first name and last name cannot be empty"
    else
      @request_errors << "Unspecified problem - Are you sending post requests outside the form - don't!!!!!"
    end
    @add_contact_form = {
      first_name: first_name,
      last_name: last_name,
      phone_number: phone_number,
      email: email,
      note: note
    }
  else
    @newly_added_contact_id = res.first["id"]
  end
end

def handle_contact_text_update(contact_id:, first_name:, last_name:, phone_number:, email:, note:)
  first_name = @form_input.sanitize_field_first_name(first_name)
  last_name = @form_input.sanitize_field_last_name(last_name)
  phone_number = @form_input.sanitize_field_phone_number(phone_number)
  email = @form_input.sanitize_field_email(email)
  note = @form_input.sanitize_field_note(note)
  begin
    res = @storage.edit_contact(
            id: contact_id,
            first_name: first_name,
            last_name: last_name,
            phone_number: phone_number,
            email: email,
            note: note)
  rescue StandardError => e
    regex = /violates check constraint "need_a_name"/
    if !!(regex =~ e.message)
      @request_errors << "Both first name and last name cannot be empty"
    else
      @request_errors << "Unspecified problem - Are you sending post requests outside the form - don't!!!!!"
    end
    @edit_contact_form = {
      first_name: first_name,
      last_name: last_name,
      phone_number: phone_number,
      email: email,
      note: note
    }
  else
    @contact_successfully_edited = true
  end
end

def string_also_an_integer?(input)
  regex = /^\d+$/
  !!(regex =~ input)
end

def contact_exists?(contact_id)
  valid_uuid_format?(contact_id) && @storage.find_contact(id: contact_id).ntuples == 1
end

def profile_pic_exists?(profile_pic_id)
  valid_uuid_format?(profile_pic_id) && @storage.find_profile_pic(pic_id: profile_pic_id).ntuples == 1
end

def page_title_tag(title:"", delimiter:"-", app_name:@app_name)
  return app_name if title.empty?
  "#{app_name} #{delimiter} #{title}"
end
