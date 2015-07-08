
require 'sinatra'
require "sinatra/reloader" if development?
require 'net/http'

set :protection, :except => :path_traversal
set :public_folder, File.dirname(__FILE__) + '/pdf.js'
set :server, 'thin'

set :my_temp, {
    viewer: "pdf.js/web/viewer.html"
}

helpers do
    def find_template(views, name, engine, &block)
        temp = settings.my_temp
        yield temp[name] if temp.key? name
        super(views, name, engine, &block)
    end
end

get '/' do
    "Ehlo from sinatra!"
end

get '/proxy/*' do |url|
    "proxy: #{url}"
    unless url.match "^https?://"
        url = "http://"+url
    end
    content_type "application/pdf"
    stream do |out|
        Net::HTTP.get_response URI(url) do |resp|
            if response['content-type'].match /pdf/
                resp.read_body do |chunk|
                    out << chunk
                end
            end
        end
    end
end

get '/*' do |url|
    unless url.match "^https?://"
        url = "http://"+url
    end
    @url = url
    erb :viewer
end

error do
    "<!DOCTYPE html>
        <html>
        <head>
            <title>genius-pdf error</title>
        </head>
        <body>
        <h1>oops!</h1>
        <pre><code>#{env['sinatra.error'].message}</code></pre>
    </body>
    </html>"
end 