#!/usr/bin/env ruby
# Extracted from https://github.com/apache/whimsy/blob/master/tools/site-scan.rb
# Only includes site parsing logic - no ASF/LDAP/committee dependencies

require 'net/http'
require 'nokogiri'
require 'uri'
require 'json'

# Copied directly from site-scan.rb
def squash(text)
  text.scrub.gsub(/[[:space:]]+/, ' ').strip
end

# Copied directly from site-scan.rb
def get_link_text(anode)
  bits = []
  anode.traverse do |node|
    if node.name == 'text'
      bits << node.text unless node.parent.name == 'span' and
        node.parent.attribute('class')&.value&.end_with?('sr-only')
    end
  end
  squash(bits.join(' '))
end

# Copied from sitestandards.rb COMMON_CHECKS patterns
CHECKS = {
  'foundation'  => { url: /apache\.org/,                              text: nil },
  'license'     => { url: /^https?:\/\/.*apache\.org\/licenses\/?$/,  text: /^license$/i },
  'thanks'      => { url: nil, text: /^(thanks|sponsors|thanks to our sponsors)$/i },
  'security'    => { url: nil, text: /^security$/i },
  'sponsorship' => { url: nil, text: /^(sponsorship|sponsor|donate)$/i },
  'privacy'     => { url: nil, text: /^privacy$/i },
  'events'      => { url: /apache\.org\/events\/current-event/, text: nil },
}

site = ARGV[0] || 'http://127.0.0.1:8000'
uri  = URI.parse(site)

response = Net::HTTP.get_response(uri)
doc      = Nokogiri::HTML(response.body)

results  = {}

# Copied from parse() in site-scan.rb - only the link scanning part
doc.traverse do |a|
  next unless a.name == 'a'

  a_href     = a['href'].to_s.strip
  a_text     = get_link_text(a)
  a_text_down = a_text.downcase.strip

  CHECKS.each do |name, check|
    next if results[name]
    url_match  = check[:url].nil?  || a_href      =~ check[:url]
    text_match = check[:text].nil? || a_text_down =~ check[:text]
    results[name] = a_href if url_match && text_match
  end
end

# Print results
failed = false
CHECKS.each_key do |name|
  if results[name]
    puts "#{name}=GREEN\n  value=\"#{results[name]}\""
  else
    puts "#{name}=RED\n  No matching link found for '#{name}'"
    failed = true
  end
end

exit(failed ? 1 : 0)
