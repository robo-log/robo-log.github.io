# -*- coding: utf-8 -*-
# $ ruby wp-xml-hugo-import.rb ***.wordpress.yyyy-mm-dd.xml

require 'fileutils'
require 'time'
require 'rexml/document'
include REXML

class Time 
  def timezone(timezone = 'UTC')
    old = ENV['TZ']
    utc = self.dup.utc
    ENV['TZ'] = timezone
    output = utc.localtime
    ENV['TZ'] = old
    output
  end
end

doc = Document.new File.new(ARGV[0])
FileUtils.mkdir_p 'post'
FileUtils.mkdir_p 'page'

doc.elements.each("rss/channel/item[wp:status = 'publish' and (wp:post_type = 'post' or wp:post_type = 'page')]") do |e|
  post = e.elements

  post_id   = post['wp:post_id'].text
  post_name = post['wp:post_name'].text
  post_type = post['wp:post_type'].text
  post_date = Time.parse(post['wp:post_date'].text)
  post_date.timezone('Asia/Tokyo')

  title     = post['title'].text;
  content   = post['content:encoded'].text
  category  = ''

  # Replace absolute path to relative path
  # src="http://rakuishi.com/wp-content/uploads/2011/10/miso.jpg" → src="/images/2011/10/miso.jpg"
  content = content.gsub(/src="http:\/\/blog.syundo.org\/wp-content\/uploads\/(.+?)"/, 'src="/images/\1"')
  content = content.gsub(/href="http:\/\/blog.syundo.org\/wp-content\/uploads\/(.+?)"/, 'href="/images/\1"')
  content = content.gsub(/(<img[^>]*)width="\d+"([^>]*>)/, '\1\2')
  content = content.gsub(/(<img[^>]*)height="\d+"([^>]*>)/, '\1\2')
  content = content.gsub(/(<a href=".+?")([^>]*)(>)/, '\1\3')
  content = content.gsub(/(\n)/, '\1\1')
  
  
  # Page not have category tag
  if defined?(post['category'].text)
    # My blog post have single category
    category = post['category'].text
  end

  filename = "%02d-%02d-%02d-%04d.md" % [post_date.year, post_date.month, post_date.day, post_id]
  puts "Converting: #{filename}"

  File.open("#{post_type}/#{filename}", 'w') do |f|
    f.puts '+++'
    f.puts "date = \"#{post_date.strftime("%Y-%m-%dT%H:%M:%S%:z")}\""
    f.puts 'draft = false'
    f.puts "title = \"#{title}\""
    if !category.empty?
      f.puts "categories = [\"#{category}\"]"
    end
    f.puts "slug = \"#{post_id}\""
    f.puts '+++'
    f.puts "\n"
    f.puts content
  end

end
