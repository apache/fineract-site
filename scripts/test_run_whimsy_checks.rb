#!/usr/bin/env ruby
# Unit tests for run_whimsy_checks.rb
# Tests that get_link_text() and parse() work exactly like whimsy's site-scan.rb

require 'minitest/autorun'
require 'nokogiri'
require_relative 'run_whimsy_checks'

class WhimsyChecksTest < Minitest::Test

  #########################################################################
  # Helper: parse raw HTML string instead of fetching from server
  #########################################################################
  def parse_html(html)
    data = {}
    SiteStandards::COMMON_CHECKS.each_key { |k| data[k.to_sym] = nil }
    doc = Nokogiri::HTML(html)

    doc.traverse do |a|
      if a.name == 'script'
        a_src = a['src'].to_s.strip
        if a_src =~ SiteStandards::COMMON_CHECKS['events'][SiteStandards::CHECK_CAPTURE]
          data[:events] = a_src
        end
      end

      next unless a.name == 'a'

      a_href     = a['href'].to_s.strip
      a_text     = get_link_text(a)
      a_text_down = a_text.downcase.strip

      if a_href =~ SiteStandards::COMMON_CHECKS['foundation'][SiteStandards::CHECK_CAPTURE]
        img = a.at('img')
        if img
          data[:foundation] = img['title'] ? squash(img['title']) : img['src'].strip
        else
          data[:foundation] = a_text
        end
      end

      if a_href =~ SiteStandards::COMMON_CHECKS['events'][SiteStandards::CHECK_CAPTURE]
        data[:events] = a_href
      end

      if (a_text_down =~ SiteStandards::COMMON_CHECKS['license'][SiteStandards::CHECK_TEXT]) and
          (a_href =~ SiteStandards::COMMON_CHECKS['license'][SiteStandards::CHECK_CAPTURE])
        data[:license] = a_href
      end

      %w(thanks security sponsorship privacy).each do |check|
        if a_text_down =~ SiteStandards::COMMON_CHECKS[check][SiteStandards::CHECK_CAPTURE]
          data[check.to_sym] = a_href
        end
      end
    end

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
  # get_link_text() tests
  #########################################################################

  def test_get_link_text_with_i_tag_includes_icon_text
    html = '<a href="https://www.apache.org/licenses/"><i class="material-icons">gavel</i><span>License</span></a>'
    node = Nokogiri::HTML(html).at('a')
    assert_equal 'gavel License', get_link_text(node)
  end

  def test_get_link_text_with_sr_only_span_skips_icon_text
    html = '<a href="https://www.apache.org/licenses/"><span class="material-icons icon-sr-only">gavel</span><span>License</span></a>'
    node = Nokogiri::HTML(html).at('a')
    assert_equal 'License', get_link_text(node)
  end

  def test_get_link_text_plain_span_is_not_skipped
    html = '<a href="#"><span>Hello</span></a>'
    node = Nokogiri::HTML(html).at('a')
    assert_equal 'Hello', get_link_text(node)
  end

  def test_get_link_text_squashes_whitespace
    html = "<a href='#'><span class='icon-sr-only'>icon</span>  License  </a>"
    node = Nokogiri::HTML(html).at('a')
    assert_equal 'License', get_link_text(node)
  end

  #########################################################################
  # license tests
  #########################################################################

  def test_license_fails_with_i_tag
    html = <<~HTML
      <html><body>
        <a href="https://www.apache.org/licenses/">
          <i class="material-icons">gavel</i>
          <span>License</span>
        </a>
      </body></html>
    HTML
    data = parse_html(html)
    assert_nil data[:license], 'license should be nil with <i> tag as icon text prefix causes mismatch'
  end

  def test_license_passes_with_sr_only_span
    html = <<~HTML
      <html><body>
        <a href="https://www.apache.org/licenses/">
          <span class="material-icons icon-sr-only">gavel</span>
          <span>License</span>
        </a>
      </body></html>
    HTML
    data = parse_html(html)
    assert_equal 'https://www.apache.org/licenses/', data[:license]
  end

  def test_license_fails_with_wrong_url
    html = <<~HTML
      <html><body>
        <a href="https://www.apache.org/licenses/LICENSE-2.0">
          <span class="material-icons icon-sr-only">gavel</span>
          <span>License</span>
        </a>
      </body></html>
    HTML
    data = parse_html(html)
    # URL matches CHECK_CAPTURE (%r{apache\.org}) but fails CHECK_VALIDATE
    assert data[:license], 'license href should be captured'
    refute_match SiteStandards::COMMON_CHECKS['license'][SiteStandards::CHECK_VALIDATE], data[:license]
  end

  def test_license_fails_with_licenses_text
    html = <<~HTML
      <html><body>
        <a href="https://www.apache.org/licenses/">
          <span class="material-icons icon-sr-only">gavel</span>
          <span>Licenses</span>
        </a>
      </body></html>
    HTML
    data = parse_html(html)
    assert_nil data[:license], 'license should be nil when text is "Licenses" not "License"'
  end

  #########################################################################
  # thanks tests
  #########################################################################

  def test_thanks_fails_with_i_tag
    html = <<~HTML
      <html><body>
        <a href="https://www.apache.org/foundation/thanks.html">
          <i class="material-icons">favorite</i>
          <span>Thanks</span>
        </a>
      </body></html>
    HTML
    data = parse_html(html)
    assert_nil data[:thanks], 'thanks should be nil with <i> tag'
  end

  def test_thanks_passes_with_sr_only_span
    html = <<~HTML
      <html><body>
        <a href="https://www.apache.org/foundation/thanks.html">
          <span class="material-icons icon-sr-only">favorite</span>
          <span>Thanks</span>
        </a>
      </body></html>
    HTML
    data = parse_html(html)
    assert_equal 'https://www.apache.org/foundation/thanks.html', data[:thanks]
  end

  def test_thanks_passes_with_sponsors_text
    html = <<~HTML
      <html><body>
        <a href="https://www.apache.org/foundation/sponsors.html">
          <span class="material-icons icon-sr-only">favorite</span>
          <span>Sponsors</span>
        </a>
      </body></html>
    HTML
    data = parse_html(html)
    assert_equal 'https://www.apache.org/foundation/sponsors.html', data[:thanks]
  end

  #########################################################################
  # security tests
  #########################################################################

  def test_security_passes
    html = <<~HTML
      <html><body>
        <a href="https://www.apache.org/security/">
          <span class="material-icons icon-sr-only">security</span>
          <span>Security</span>
        </a>
      </body></html>
    HTML
    data = parse_html(html)
    assert_equal 'https://www.apache.org/security/', data[:security]
  end

  def test_security_fails_without_security_text
    html = <<~HTML
      <html><body>
        <a href="https://www.apache.org/security/">
          <span class="material-icons icon-sr-only">lock</span>
          <span>Protection</span>
        </a>
      </body></html>
    HTML
    data = parse_html(html)
    assert_nil data[:security]
  end

  #########################################################################
  # sponsorship tests
  #########################################################################

  def test_sponsorship_passes
    html = <<~HTML
      <html><body>
        <a href="https://www.apache.org/foundation/sponsorship.html">
          <span class="material-icons icon-sr-only">volunteer_activism</span>
          <span>Sponsorship</span>
        </a>
      </body></html>
    HTML
    data = parse_html(html)
    assert_equal 'https://www.apache.org/foundation/sponsorship.html', data[:sponsorship]
  end

  def test_sponsorship_passes_with_donate_text
    html = <<~HTML
      <html><body>
        <a href="https://www.apache.org/foundation/sponsorship.html">
          <span class="material-icons icon-sr-only">volunteer_activism</span>
          <span>Donate</span>
        </a>
      </body></html>
    HTML
    data = parse_html(html)
    assert_equal 'https://www.apache.org/foundation/sponsorship.html', data[:sponsorship]
  end

  #########################################################################
  # privacy tests
  #########################################################################

  def test_privacy_passes
    html = <<~HTML
      <html><body>
        <a href="https://privacy.apache.org/policies/privacy-policy-public.html">
          <span class="material-icons icon-sr-only">privacy_tip</span>
          <span>Privacy Policy</span>
        </a>
      </body></html>
    HTML
    data = parse_html(html)
    assert_equal 'https://privacy.apache.org/policies/privacy-policy-public.html', data[:privacy]
  end

  def test_privacy_fails_without_privacy_text
    html = <<~HTML
      <html><body>
        <a href="https://privacy.apache.org/policies/privacy-policy-public.html">
          <span class="material-icons icon-sr-only">privacy_tip</span>
          <span>Data Policy</span>
        </a>
      </body></html>
    HTML
    data = parse_html(html)
    assert_nil data[:privacy]
  end

  #########################################################################
  # trademarks tests
  #########################################################################

  def test_trademarks_passes
    html = <<~HTML
      <html><body>
        <p>Apache Fineract, Apache, the Apache logo are trademarks of The Apache Software Foundation.</p>
      </body></html>
    HTML
    data = parse_html(html)
    assert_match SiteStandards::COMMON_CHECKS['trademarks'][SiteStandards::CHECK_VALIDATE], data[:trademarks]
  end

  def test_trademarks_fails_without_asf_mention
    html = <<~HTML
      <html><body>
        <p>All trademarks belong to their respective owners.</p>
      </body></html>
    HTML
    data = parse_html(html)
    refute_match SiteStandards::COMMON_CHECKS['trademarks'][SiteStandards::CHECK_VALIDATE], data[:trademarks].to_s
  end

  #########################################################################
  # copyright tests
  #########################################################################

  def test_copyright_passes
    html = <<~HTML
      <html><body>
        <p>Copyright © 2009-2026 The Apache Software Foundation</p>
      </body></html>
    HTML
    data = parse_html(html)
    assert_match SiteStandards::COMMON_CHECKS['copyright'][SiteStandards::CHECK_VALIDATE], data[:copyright]
  end

  def test_copyright_fails_without_apache_mention
    html = <<~HTML
      <html><body>
        <p>Copyright © 2026 Some Other Foundation</p>
      </body></html>
    HTML
    data = parse_html(html)
    assert data[:copyright], 'copyright text is captured'
    refute_match SiteStandards::COMMON_CHECKS['copyright'][SiteStandards::CHECK_VALIDATE], data[:copyright]
  end

  #########################################################################
  # foundation tests
  #########################################################################

  def test_foundation_passes
    html = <<~HTML
      <html><body>
        <a href="https://www.apache.org/">The Apache Software Foundation</a>
      </body></html>
    HTML
    data = parse_html(html)
    assert_equal 'The Apache Software Foundation', data[:foundation]
  end

  #########################################################################
  # events tests
  #########################################################################

  def test_events_passes
    html = <<~HTML
      <html><body>
        <a href="https://www.apache.org/events/current-event.html">
          <img src="https://www.apache.org/events/current-event-234x60.png" alt="Apache Current Event">
        </a>
      </body></html>
    HTML
    data = parse_html(html)
    assert data[:events], 'events should be captured'
  end

end
