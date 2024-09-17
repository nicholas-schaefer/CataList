require 'sinatra'
require "sinatra/reloader" if development?
require 'pg'

configure do
  set :erb, :escape_html => true
end

helpers do
  def full_name(first_name:"", last_name:"")
    [first_name, last_name].join(" ")
  end
end

before do
  @app_name ||= "cat contacts"
  @result ||= query1
end

def query1
  conn = PG.connect(dbname: "cat_contacts")
  sql = <<~SQL
      SELECT id, first_name, last_name FROM contacts
      ORDER BY first_name, last_name
      LIMIT 5;
  SQL
  result = conn.exec(sql)
end

def page_title_tag(title:"", delimiter:"-", app_name:@app_name)
  return app_name if title.empty?
  "#{app_name} #{delimiter} #{title}"
end

#######################################
# Database TESTING
#######################################
# conn = PG.connect(dbname: "cat_contacts")
# sql = <<~SQL
#     SELECT first_name, last_name FROM contacts
#     ORDER BY first_name, last_name
#     LIMIT 5;
# SQL
# result = conn.exec(sql)
# result.each do |row|
#   puts row
# end

# {
#   "id"=>"a6351a03-5345-4946-8e36-5f4adecb073f",
#   "first_name"=>"beyonce",
#   "last_name"=>nil,
#   "phone"=>"999-999-9999",
#   "email"=>"biteme@gmail.com",
#   "note"=>"here I am"
# }










#######################################
# Pages
#######################################

def load_contact_page
  @path_info = request.path_info
  @edit_action = "#{@path_info}/edit"
  @delete_action = "#{@path_info}/delete"
  # @path_info = params['slug']
  # @path_slug = params['contact_id']
  @page_title_tag = page_title_tag(title:"contact")
  erb :contact, :layout => :layout
end

def load_all_contacts_page
  @path_info = request.path_info
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
  load_all_contacts_page
end

# Get contact details
get '/contacts/:contact_id' do
  load_contact_page
end

# Update contact details
post '/contacts/:contact_id' do
  load_contact_page
end

# Delete an existing contact
post '/contacts/:contact_id/delete' do
  load_all_contacts_page
end

# Refreshes after delete revert the url to the main contacts listing page
get '/contacts/:contact_id/delete' do
  redirect to('/contacts')
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
