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
# Routes
#######################################

get '/' do
  redirect to('/contacts')
end

get '/contacts' do
  @page_title_tag = page_title_tag(title:"home")
  erb :index, :layout => :layout
end

get '/contacts/:slug' do
  @path_info = request.path_info
  @path_info = params['slug']
  @page_title_tag = page_title_tag(title:"contact")
  @page_title_tag = page_title_tag(title:"</title><script>alert('evil')</script>")
  erb :contact, :layout => :layout
end

# https://www.reddit.com/r/webdev/comments/194uuru/best_structure_for_api_urls/
post '/contacts/new' do
  erb :index, :layout => :layout
end

post '/contacts/contact_id/{contact_id}/edit' do
  # erb "hit!"
end
