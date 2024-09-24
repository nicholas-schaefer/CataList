require 'sinatra'
require 'pg'
require 'pry'

require_relative 'database_persistence'

configure do
  set :erb, :escape_html => true
end

configure(:development) do
  require "sinatra/reloader"
  also_reload "database_persistence.rb"
end

helpers do
  def full_name(first_name:"", last_name:"")
    first_name&.capitalize!
    last_name&.capitalize!
    [first_name, last_name].join(" ")
  end
end

before do
  @storage ||= DatabasePersistence.new(logger: logger)
  @app_name = "cat contacts"
  @pagination_item_limit = 3
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
end

def get_all_file_system_image_names
  dir = File.expand_path("../public/images/profiles", __FILE__)

  # Ensure the directory exists
  return [] unless Dir.exist?(dir)

  # Get all entries in the directory, filter out subdirectories and special entries
  paths =
    (Dir.entries(dir).select do |entry|
      next if entry == '.' || entry == '..' # Skip current and parent directory
      file_path = File.join(dir, entry)
      File.file?(file_path) # Include only files
    end)
end

def delete_all_file_system_images
  file_system_image_names = get_all_file_system_image_names

  file_system_image_names.each do |fname|
    fpath = data_path + "/" + fname
    File.delete(fpath)
  end
end

def data_path
  File.expand_path("../public/images/profiles", __FILE__)
  # if ENV["RACK_ENV"] == "hack_test"
  #   File.expand_path("../test/data", __FILE__)
  # else
  #   File.expand_path("../data", __FILE__)
  # end
end


def query_select_all_results
  @storage.find_all_contacts
end

def query_select_one_result(contact_id)
  @storage.find_contact(id: contact_id)
end

def page_title_tag(title:"", delimiter:"-", app_name:@app_name)
  return app_name if title.empty?
  "#{app_name} #{delimiter} #{title}"
end


## Methods in spired by https://stackoverflow.com/a/47511286
def valid_uuid_format?(uuid)
  uuid_regex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/
  return true if uuid_regex.match?(uuid.to_s.downcase)
  # log_and_raise_error("Given argument is not a valid UUID: '#{format_argument_output(uuid)}'")
end

#######################################
# Form Front End Sanitization
#######################################

def sanitize_field_first_name(input)
  input.strip.downcase
end

def sanitize_field_last_name(input)
  input.strip.downcase
end

def sanitize_field_phone_number(input)
  input.strip
end

def sanitize_field_email(input)
  input.strip
end

def sanitize_field_note(input)
  input.strip
end

#######################################
# Pages
#######################################

def load_contact_page
  halt 404 unless valid_uuid_format?(params['contact_id'])

  result = query_select_one_result(params['contact_id'])
  halt 404 unless result.ntuples == 1

  @contact = result.first

  image_file_path = "/images/profiles/"
  if @contact["file_name"]
    image_file_path += @contact["file_name"]
  else
    image_file_path += "/_no_profile_default/no-image-found-placeholder.png"
  end
  @contact["image_file_path"] = image_file_path

  @path_slug = params['contact_id']
  @path_info = request.path_info
  @edit_action = "#{@path_info}/edit"
  @delete_action = "#{@path_info}/delete"
  # @path_info = params['slug']
  @page_title_tag = page_title_tag(title:"contact")

  erb :contact, :layout => :layout
end

def load_all_contacts_page
  @path_info = "/contacts" # need to hard code this, handle form submit from other pages, can't use @path_info = request.path_info
  total_contacts_count = @storage.contacts_total_count


  total_pages = nil #THIS WORKS BUT SHOULD MAKE IT A SEPARATE PAGINATION FUNCTION
  if total_contacts_count.zero?
    total_pages = 1
  else
    total_pages = ((total_contacts_count-1)/(@pagination_item_limit)) + 1
  end
  @pages = (1..total_pages).to_a

  pagination_requested = params['page'] || '1'
  halt 404 unless @storage.string_also_an_integer?(pagination_requested) #lazy, need error message rewrite, helper class?
  halt 404 unless @pages.any?(pagination_requested.to_i) #need different error, means page not in range

  @validated_pagination_int = pagination_requested.to_i
  pagination_offset = (@validated_pagination_int - 1)* @pagination_item_limit

  @contacts = @storage.find_selected_contacts(limit: @pagination_item_limit, offset:pagination_offset)
  @page_title_tag = page_title_tag(title:"home")

  erb :index, :layout => :layout
end


#######################################
# Routes
#######################################

get '/' do
  redirect to('/contacts')
end

# Get All Contacts
get '/contacts' do
  load_all_contacts_page
end

# Add a new contact
post '/contacts' do
  first_name = sanitize_field_first_name(params['first_name'])
  last_name = sanitize_field_last_name(params['last_name'])
  phone_number = sanitize_field_phone_number(params['phone_number'])
  email = sanitize_field_email(params['email'])
  note = sanitize_field_note(params['note'])
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
    load_all_contacts_page
  else
    @newly_added_contact_id = res.first["id"]
    load_all_contacts_page
  end
end

# Add Preset Entries to a database
post '/contacts/seed_storage' do
  # erb "<p>YAY!!!!!!!!!!!</p>"
  begin
    res = @storage.add_seed_contacts()
    @count_contacts_successfully_seeded = res.cmd_tuples
  rescue StandardError => e
    erb "<p>evil</p> <p>#{e.message}</p>"
  else
    # @contact_successfully_deleted = true
    @contacts_successfully_seeded = true
    load_all_contacts_page
  end
end

# Refreshes after seeing go the main contacts listing page
get '/contacts/seed_storage' do
  redirect to('/contacts')
end

# Delete All Contacts
post '/contacts/delete_all' do
  delete_all_file_system_images
  # erb "<p>YAY!!!!!!!!!!!</p>"
  begin
    res = @storage.delete_all_contacts()
  rescue StandardError => e
    erb "<p>evil</p> <p>#{e.message}</p>"
  else
    # erb "<p>YAY!!!!!!!!!!!</p>"
    @contact_successfully_deleted = true
    load_all_contacts_page
  end
end

# Refreshes after delete all the url to the main contacts listing page
get '/contacts/delete_all' do
  redirect to('/contacts')
end

# Update contact details
# BRILLIANT INSPIRATION: https://gist.github.com/runemadsen/3905593
# also helpful https://stackoverflow.com/questions/2686044/file-upload-with-sinatra
# also good video https://www.youtube.com/watch?v=1PPqDQZDABU
post '/contacts/:contact_id' do
  first_name = sanitize_field_first_name(params['first_name'])
  last_name = sanitize_field_last_name(params['last_name'])
  phone_number = sanitize_field_phone_number(params['phone_number'])
  email = sanitize_field_email(params['email'])
  note = sanitize_field_note(params['note'])
  id = params['contact_id']
  profile_pic = params['profile_pic']

  if profile_pic
    picture_file_type = profile_pic['type']
    picture_file_extension =
    case picture_file_type
    when 'image/jpeg' then 'jpg'
    when 'image/png' then 'png'
    else
      raise("Invalid filetype, png, or jpg required")
    end

    query_add_image = @storage.add_image(
      contact_id: id,
      file_type: picture_file_type,
      file_extension: picture_file_extension)

    profile_image_id = query_add_image.first["profile_image_id"]

    new_file_name = "#{profile_image_id}.#{picture_file_extension}"
    absolute_path = File.join(data_path, new_file_name)

    write_operation = (File.open(absolute_path, mode = 'wb') do |f|
      file = profile_pic['tempfile']
      f.write(file.read)
    end)
    raise("write operation failed") unless write_operation > 0
  end

  begin
    raise("contact id not found") unless valid_uuid_format?(id) && @storage.find_contact(id: id).ntuples == 1
    res = @storage.edit_contact(
            id: id,
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
  load_contact_page
end

# Get contact details
get '/contacts/:contact_id' do
  load_contact_page
end

# Delete an existing contact
# prevents success message if we've already deeleted this contact
post '/contacts/:contact_id/delete' do
  id = params['contact_id']
  begin
    raise("contact id not found") unless valid_uuid_format?(id) && @storage.find_contact(id: id).ntuples == 1 #Must find correct header fort this
    res = @storage.delete_contact(id: id)
  rescue StandardError => e
    erb "<p>evil</p> <p>#{e.message}</p>"
  else
    # erb "<p>YAY!!!!!!!!!!!</p>"
    @contact_successfully_deleted = true
    load_all_contacts_page
  end
end



# Refreshes after delete revert the url to the main contacts listing page
get '/contacts/:contact_id/delete' do
  redirect to('/contacts')
end

# When there's a 404 error this is what happens
not_found do
  erb :page_not_found, :layout => :layout
end



# Update an existing contact
# post '/contacts/:contact_id/edit' do
#   erb :contact, :layout => :layout
# end

# Refreshes after edit the url to the contacts page
# get '/contacts/:contact_id/edit' do
#   @path_slug = params['contact_id']
#   redirect to("/contacts/#{params['contact_id']}")
# end
