require 'sinatra'
require "sinatra/reloader" if development?

helpers do
  def page_title_tag(title="", delimiter="-")
    return APP_TITLE if title.empty?
    "#{APP_NAME} #{delimiter} #{title}"
  end
end

before do
  @app_name = "cat contacts"
  @title ||= ""
end


get '/' do
  @page_title_tag = page_title_tag
  # '<strong>Hello World</strong>'
  erb :index, :layout => :layout
end

get '/contact/:slug' do
  erb :contact, :layout => :layout
end

# https://www.reddit.com/r/webdev/comments/194uuru/best_structure_for_api_urls/
post '/contacts/new' do
  erb :index, :layout => :layout
end

post '/contacts/contact_id/{contact_id}/edit' do
  # erb "hit!"
end
