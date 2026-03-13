#!/usr/bin/env python3
import re
import sys
import urllib.request
from html.parser import HTMLParser

class LinkParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.links = []
        self._current_href = None
        self._current_text = []
        self._in_anchor = False
        self._skip = False

    def handle_starttag(self, tag, attrs):
        if tag == "a":
            self._in_anchor = True
            self._current_text = []
            self._current_href = dict(attrs).get("href", "")
        elif self._in_anchor and tag == "span":
            # Only skip span if its class ends with 'sr-only' (exactly as whimsy does)
            classes = dict(attrs).get("class", "")
            if classes.endswith("sr-only"):
                self._skip = True

    def handle_endtag(self, tag):
        if tag == "a":
            text = " ".join(self._current_text).strip()
            # squash multiple spaces like whimsy does
            text = re.sub(r'\s+', ' ', text).strip()
            self.links.append((self._current_href, text))
            self._in_anchor = False
            self._current_href = None
            self._current_text = []
            self._skip = False
        elif tag == "span":
            self._skip = False

    def handle_data(self, data):
        if self._in_anchor and not self._skip:
            stripped = data.strip()
            if stripped:
                self._current_text.append(stripped)


# Matches exactly what whimsy's site-scan.rb does:
# - license: checks BOTH url (CHECK_CAPTURE) AND text (CHECK_TEXT)
# - thanks/security/sponsorship/privacy: checks text only (CHECK_CAPTURE on a_text)
# - foundation/events: checks url only
CHECKS = {
    "foundation": {
        "url_pattern": r"apache\.org",
        "text_pattern": None,
        "description": "Link to apache.org"
    },
    "license": {
        # Both url AND text must match (from site-scan.rb)
        "url_pattern": r"^https?://.*apache\.org/licenses/?$",
        "text_pattern": r"^license$",  # whimsy downcases a_text before matching
        "description": 'Link text "License" pointing to apache.org/licenses/'
    },
    "thanks": {
        # text only match (whimsy uses CHECK_CAPTURE on a_text for these)
        "url_pattern": None,
        "text_pattern": r"^(thanks|sponsors|thanks to our sponsors)$",
        "description": 'Link text "Thanks" or "Sponsors" pointing to foundation/thanks.html'
    },
    "security": {
        "url_pattern": None,
        "text_pattern": r"^security$",
        "description": 'Link text "Security" pointing to apache.org/security'
    },
    "sponsorship": {
        "url_pattern": None,
        "text_pattern": r"^(sponsorship|sponsor|donate)$",
        "description": 'Link text "Sponsorship" or "Sponsor" pointing to foundation/sponsorship.html'
    },
    "privacy": {
        "url_pattern": None,
        "text_pattern": r"^privacy$",
        "description": 'Link text "Privacy" pointing to apache.org privacy policy'
    },
    "events": {
        "url_pattern": r"apache\.org/events/current-event",
        "text_pattern": None,
        "description": "Link to apache.org/events/current-event"
    },
}


def check_whimsy(url="http://127.0.0.1:8000"):
    try:
        with urllib.request.urlopen(url) as response:
            html = response.read().decode("utf-8")
    except Exception as e:
        print(f"ERROR: Could not fetch {url}: {e}")
        sys.exit(1)

    parser = LinkParser()
    parser.feed(html)

    failed = False
    for name, check in CHECKS.items():
        match_href = next(
            (href for href, text in parser.links
             if (check["url_pattern"] is None or
                 re.search(check["url_pattern"], href or "", re.IGNORECASE))
             and (check["text_pattern"] is None or
                  re.search(check["text_pattern"], text.lower(), re.IGNORECASE))),
            None
        )
        if match_href:
            print(f"{name}=GREEN\n  value=\"{match_href}\"")
        else:
            print(f"{name}=RED\n  {check['description']}")
            failed = True

    return failed


if __name__ == "__main__":
    sys.exit(1 if check_whimsy() else 0)