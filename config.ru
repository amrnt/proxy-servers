require 'rack'
require 'rack/proxy'
require 'rack/cache'
require 'uri'
require './inject_html'

AMZN_URL = URI.parse('http://www.amazon.com')

class AmazonProxy < Rack::Proxy
  def rewrite_env env
    @perimeter_host = env['HTTP_HOST']
    @host           = AMZN_URL.host
    @port           = AMZN_URL.port

    env.merge(
      'rack.url_scheme' => AMZN_URL.scheme,
      'HTTP_HOST'       => @host,
      'SERVER_PORT'     => @port
    ).reject { |key, _| key == 'HTTP_ACCEPT_ENCODING' }
  end

  def rewrite_response triplet
    status, headers, @response = triplet

    headers['set-cookie'] = headers['set-cookie'].map { |e| e.gsub('.amazon.com', @perimeter_host) }

    [
      status,
      headers.reject { |key, _| %w(status transfer-encoding).include?(key) },
      self
    ]
  end

  def each
    @response.each do |chunk|
      yield chunk.gsub(/#{@host}(:#{@port})?/, @perimeter_host)
    end
  end
end

use InjectHtml
run AmazonProxy.new
