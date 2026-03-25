#!/usr/bin/env ruby
# Replicates exactly how whimsy's site-scan.rb uses sitestandards.rb
# Source: https://github.com/apache/whimsy/blob/master/tools/site-scan.rb
# Source: https://github.com/apache/whimsy/blob/master/lib/whimsy/sitestandards.rb

require 'net/http'
require 'nokogiri'
require 'uri'

#########################################################################
# Exact copy of SiteStandards module from sitestandards.rb
#########################################################################
module SiteStandards
  CHECK_TEXT     = 'text'
  CHECK_CAPTURE  = 'capture'
  CHECK_VALIDATE = 'validate'
  CHECK_TYPE     = 'type'
  CHECK_POLICY   = 'policy'
  CHECK_DOC      = 'doc'

  COMMON_CHECKS = {
    'foundation' => {
      CHECK_TEXT     => %r{apache|asf|foundation}i,
      CHECK_CAPTURE  => %r{^(https?:)?//(www\.)?apache\.org/?$},
      CHECK_VALIDATE => %r{apache|asf|foundation}i,
      CHECK_TYPE     => 'text',
      CHECK_POLICY   => 'https://www.apache.org/foundation/marks/pmcs#navigation',
      CHECK_DOC      => 'All projects must feature some prominent link back to the main ASF homepage at http://www.apache.org/',
    },
    'events' => {
      CHECK_TEXT     => nil,
      CHECK_CAPTURE  => %r{apachecon\.com/event-images|events\.apache\.org|apache\.org/events/current-event},
      CHECK_VALIDATE => %r{^https?://((www\.)?apache\.org/events/current-event|events\.apache\.org|www\.apachecon\.com/event-images/snippet\.js)},
      CHECK_TYPE     => 'href',
      CHECK_POLICY   => 'https://www.apachecon.com/event-images/',
      CHECK_DOC      => 'Projects SHOULD include a link to any current CommunityOverCode event.',
    },
    'license' => {
      CHECK_TEXT     => /^license$/,
      CHECK_CAPTURE  => %r{apache\.org},
      CHECK_VALIDATE => %r{^https?://.*apache.org/licenses/?$},
      CHECK_TYPE     => 'href',
      CHECK_POLICY   => 'https://www.apache.org/foundation/marks/pmcs#navigation',
      CHECK_DOC      => 'There should be a "License" (*not* "Licenses") navigation link which points to: http[s]://www.apache.org/licenses[/]. (Do not link to sub-pages)',
    },
    'thanks' => {
      CHECK_TEXT     => /\A(sponsors|thanks!?|thanks to our sponsors)\z/,
      CHECK_CAPTURE  => /\A(sponsors|thanks!?|thanks to our sponsors)\z/,
      CHECK_VALIDATE => %r{^https?://.*apache.org/foundation/(thanks|sponsors)},
      CHECK_TYPE     => 'href',
      CHECK_POLICY   => 'https://www.apache.org/foundation/marks/pmcs#navigation',
      CHECK_DOC      => '"Sponsors", "Thanks" or "Thanks to our Sponsors" should link to: http://www.apache.org/foundation/thanks.html or sponsors.html',
    },
    'security' => {
      CHECK_TEXT     => /security/,
      CHECK_CAPTURE  => /security/,
      CHECK_VALIDATE => %r{^(https?://.*apache.org|[^:]*)/.*[Ss]ecurity},
      CHECK_TYPE     => 'href',
      CHECK_POLICY   => 'https://www.apache.org/foundation/marks/pmcs#navigation',
      CHECK_DOC      => '"Security" should link to a project-specific page or http://www.apache.org/security/',
    },
    'sponsorship' => {
      CHECK_TEXT     => %r{sponsorship|\bdonate\b|sponsor\sapache|sponsoring\sapache|\bsponsor\b},
      CHECK_CAPTURE  => %r{sponsorship|\bdonate\b|sponsor\sapache|sponsoring\sapache|\bsponsor\b},
      CHECK_VALIDATE => %r{^https?://.*apache.org/foundation/sponsorship},
      CHECK_TYPE     => 'href',
      CHECK_POLICY   => 'https://www.apache.org/foundation/marks/pmcs#navigation',
      CHECK_DOC      => '"Sponsorship", "Sponsor Apache", or "Donate" should link to: http://www.apache.org/foundation/sponsorship.html',
    },
    'trademarks' => {
      CHECK_TEXT     => %r{\btrademarks\b},
      CHECK_CAPTURE  => %r{\btrademarks\b},
      CHECK_VALIDATE => %r{trademarks of [Tt]he Apache Software Foundation},
      CHECK_TYPE     => 'text',
      CHECK_POLICY   => 'https://www.apache.org/foundation/marks/pmcs#attributions',
      CHECK_DOC      => 'All project homepages must feature a prominent trademark attribution.',
    },
    'copyright' => {
      CHECK_TEXT     => %r{((Copyright|©).*apache|apache.*(Copyright|©))}i,
      CHECK_CAPTURE  => %r{(Copyright|©)}i,
      CHECK_VALIDATE => %r{((Copyright|©).*apache|apache.*(Copyright|©))}i,
      CHECK_TYPE     => 'text',
      CHECK_POLICY   => 'https://www.apache.org/legal/src-headers.html#headers',
      CHECK_DOC      => 'All website content SHOULD include a copyright notice for the ASF.',
    },
    'privacy' => {
      CHECK_TEXT     => %r{Privacy Policy}i,
      CHECK_CAPTURE  => %r{(Privacy)}i,
      CHECK_VALIDATE => %r{\Ahttps://privacy\.apache\.org/policies/privacy-policy-public\.html\z
                          |
                          \Ahttps?://(?:www\.)?apache\.org/foundation/policies/privacy\.html\z
                          }ix,
      CHECK_TYPE     => 'href',
      CHECK_POLICY   => 'https://www.apache.org/foundation/marks/pmcs.html#navigation',
      CHECK_DOC      => 'All websites must link to the Privacy Policy.',
    },
  }
end

#########################################################################
# Exact copy of helper functions from site-scan.rb
#########################################################################
def squash(text)
  text.scrub.gsub(/[[:space:]]+/, ' ').strip
end

def get_link_text(anode)
  bits = []
  anode.traverse do |node|
    if node.name == 'text'
      bits << node.text unless node.parent.name == 'span' and
        node.parent.attribute('class')&.value&.end_with? 'sr-only'
    end
  end
  squash(bits.join(' '))
end

def save_events(data, value)
  prev = data[:events]
  if prev and prev != value
    puts "Events: already have '#{prev}', not storing '#{value}'"
  else
    data[:events] = value
  end
end

<<<<<<< HEAD
exit(failed ? 1 : 0)
=======
#########################################################################
# Exact copy of parse() from site-scan.rb
# (minus ASF/LDAP/committee/podling parts)
#########################################################################
def parse(site)
  data = {}
  SiteStandards::COMMON_CHECKS.each_key { |k| data[k.to_sym] = nil }

  uri      = URI.parse(site)
  response = Net::HTTP.get_response(uri)
  doc      = Nokogiri::HTML(response.body)

  # FIRST: scan each link's a_href - exact logic from site-scan.rb
  doc.traverse do |a|

    # events: check script src
    if a.name == 'script'
      a_src = a['src'].to_s.strip
      if a_src =~ SiteStandards::COMMON_CHECKS['events'][SiteStandards::CHECK_CAPTURE]
        save_events data, (uri + a_src).to_s
      end
    end

    next unless a.name == 'a'

    a_href = a['href'].to_s.strip
    a_text = get_link_text(a) # Not down-cased yet

    # foundation
    if a_href =~ SiteStandards::COMMON_CHECKS['foundation'][SiteStandards::CHECK_CAPTURE]
      img = a.at('img')
      if img
        data[:foundation] = img['title'] ? squash(img['title']) : (uri + img['src'].strip).to_s
      else
        data[:foundation] = a_text
      end
    end

    # events
    if a_href =~ SiteStandards::COMMON_CHECKS['events'][SiteStandards::CHECK_CAPTURE]
      save_events data, (uri + a_href).to_s
    end

    # license: downcase a_text before matching
    a_text_down = a_text.downcase.strip
    if (a_text_down =~ SiteStandards::COMMON_CHECKS['license'][SiteStandards::CHECK_TEXT]) and
        (a_href =~ SiteStandards::COMMON_CHECKS['license'][SiteStandards::CHECK_CAPTURE])
      data[:license] = a_href
    end

    # thanks, security, sponsorship, privacy: CHECK_CAPTURE on downcased a_text
    %w(thanks security sponsorship privacy).each do |check|
      if a_text_down =~ SiteStandards::COMMON_CHECKS[check][SiteStandards::CHECK_CAPTURE]
        data[check.to_sym] = a_href
      end
    end

  end

  # SECOND: scan text nodes for trademarks and copyright
  doc.traverse do |node|
    next unless node.is_a?(Nokogiri::XML::Text)
    txt = squash(node.text)

    if (txt =~ SiteStandards::COMMON_CHECKS['trademarks'][SiteStandards::CHECK_CAPTURE] and not data[:trademarks]) or
        txt =~ /are trademarks of [Tt]he Apache Software/
      data[:trademarks] = txt.sub(/^.*?Copyright .+? Foundation[.]?/, '').strip
    end

    if txt =~ SiteStandards::COMMON_CHECKS['copyright'][SiteStandards::CHECK_CAPTURE]
      data[:copyright] = txt.sub(/^.*?((Copyright|©) .+? Foundation[.]?).*/, '\1').strip
    end
  end

  data
end

#########################################################################
# Validate and print results using CHECK_VALIDATE
#########################################################################
def validate(data)
  failed = false
  SiteStandards::COMMON_CHECKS.each do |name, check|
    value = data[name.to_sym]
    if value && value.to_s =~ check[SiteStandards::CHECK_VALIDATE]
      puts "#{name}=GREEN\n  value=\"#{value}\""
    elsif value
      puts "#{name}=WARN\n  value=\"#{value}\""
      puts "  expected: #{check[SiteStandards::CHECK_VALIDATE].source}"
      puts "  doc: #{check[SiteStandards::CHECK_DOC]}"
      failed = true
    else
      puts "#{name}=RED\n  #{check[SiteStandards::CHECK_DOC]}"
      puts "  policy: #{check[SiteStandards::CHECK_POLICY]}"
      failed = true
    end
  end
  failed
end

#########################################################################
# Main
#########################################################################
if __FILE__ == $0
  site   = ARGV[0] || 'http://127.0.0.1:8000'
  data   = parse(site)
  failed = validate(data)
  exit(failed ? 1 : 0)
end
>>>>>>> bd8df1f (FINERACT-2528: Add unit tests for whimsy checks and daily whimsy monitoring workflow)
