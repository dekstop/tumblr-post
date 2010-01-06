#!/usr/local/bin/ruby

# =tumblr-post.rb
#
# http://www.tumblr.com/api
#
# martind 2007-11-07

require 'rexml/document'
require 'net/http'

@prefs = {
  :host => 'www.tumblr.com',
  :post_path => '/api/write',
  :account_url => 'http://my_account.tumblr.com/',

  :shorturl_maxlen => 45,
  
  :params => {
    :email => 'my_email',
    :password => 'my_password',
    :generator => 'tumblr-post.rb 1',
  }
}


# =======
# = subs =
# =======

def unsymbolise(hash)
  result = {}
  hash.keys.each do |key|
    result[key.to_s] = hash[key]
  end
  result
end

def post(params)
  #require 'pp'
  #pp unsymbolise(params)

  http = Net::HTTP.new(@prefs[:host], 80)
  http.start do |http|
      req = Net::HTTP::Post.new(@prefs[:post_path], {'User-Agent' => @prefs[:params][:generator]})
      req.set_form_data(unsymbolise(params))
      response = http.request(req)
      if (response.code =~ /2\d{2}/) then
        puts "#{@prefs[:account_url]}post/#{response.body}"
        return true
      else
        puts "HTTP #{response.code}: #{response.message}"
        return false
      end
  end
end

def error_exit(msg)
  puts msg
  exit -1
end

def entities( str )
  converted = []
  str.split(//).collect { |c| converted << ( c[0] > 127 ? "&##{c[0]};" : c ) }
  converted.join('')
end

def extract_url_and_message(txt)
  if (txt !~ /^https?:\/\/.+/)
    error_exit "URL missing"
  end
  txt.split(' ', 2)
end

def extract_video_and_message(txt)
  return txt.split(' ', 2) if (txt =~ /^https?:\/\/.+/)
  txt.split('|', 2)
end

def shorturl(url, maxlen=30)
  url = url.match(/^https?:\/\/(?:www\.)?(.*)$/).captures.first
  url = (url[0,maxlen-3] + '...') if (url.length>maxlen)
  url
end

def print_help
  #name = File.basename(__FILE__)
  name = '?tumble'
  puts "#{name} <text>"
  puts "#{name} photo <url> [text]"
  puts "#{name} link <url> [text]"
  puts "#{name} quote <text> | <source>"
  puts "#{name} video <youtube url> [text]"
  puts "#{name} video <embed html> | <text>"
end

# ========
# = main =
# ========

if (ARGV.size == 0 || ARGV.first.length==0) then
  print_help
  exit 1
end

params = @prefs[:params]

# stupid irccat security-related fix (we quote all input)
args = ARGV.join(' ').split(' ')

case args.first.upcase
when 'HELP'
  print_help
  exit
when 'PHOTO', 'IMAGE', 'PIC', 'IMG'
  params[:type] = 'photo'
  url, msg = extract_url_and_message(args[1..-1].join(' '))
  params[:source] = url
  params[:caption] = msg if msg
when 'LINK', 'URL'
  params[:type] = 'link'
  url, msg = extract_url_and_message(args[1..-1].join(' '))
  params[:url] = url
  params[:name] = shorturl(url, @prefs[:shorturl_maxlen])
  params[:description] = msg if msg
when 'QUOTE'
  params[:type] = 'quote'
  quote, source = (args[1..-1].join(' ')).split('|', 2)
  params[:quote] = quote
  params[:source] = source if source
when 'VIDEO'
  params[:type] = 'video'
  embed, caption = extract_video_and_message(args[1..-1].join(' '))
  params[:embed] = embed
  params[:caption] = caption if caption
else
  params[:type] = 'regular'
  params[:body] = args.join(' ')
end

post(params) or exit 1


