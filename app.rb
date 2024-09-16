require 'sinatra'
require "sinatra/reloader" if development?

configure do
  set :erb, :escape_html => true
end

helpers do

end

before do
  @app_name ||= "cat contacts"
end

def page_title_tag(title:"", delimiter:"-", app_name:@app_name)
  return app_name if title.empty?
  "#{app_name} #{delimiter} #{title}"
end

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
