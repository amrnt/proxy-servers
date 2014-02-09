class InjectHtml < Struct.new(:app)
  def call(env)
    status, headers, body = app.call(env)

    Rack::Response.new(body, status, headers) do |response|
      if media_type(response) == 'text/html'
        content = add_tags(response.body.join)
        response.body = [content]
        response.headers['Content-Length'] = content.length.to_s
      end
    end
  end

  def media_type(response)
    response.content_type.to_s.split(';').first
  end

  def add_tags(content)
    content.sub(%r{(?=</head>)}, header_tag)
  end

  def header_tag
    "<h1 style='background: red; text-align: center; color: white;'>This is Amr Tamimi</h1>"
  end
end
