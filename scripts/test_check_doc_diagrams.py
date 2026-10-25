#!/usr/bin/env python3
#
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements. See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership. The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License. You may obtain a copy of the License at
#
#   https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied. See the License for the
# specific language governing permissions and limitations
# under the License.
#
"""Tests for check_doc_diagrams.py."""

import base64
import struct
import tempfile
import unittest
import zlib
from pathlib import Path

import check_doc_diagrams

TESTDATA = Path(__file__).resolve().parent / "testdata"
# The batch-jobs diagram as first published in docs/1.16.0, and as rebuilt.
ERROR_PNG = (TESTDATA / "plantuml-graphviz-error.png").read_bytes()
GOOD_PNG = (TESTDATA / "plantuml-batch-jobs.png").read_bytes()

# The text of one of the broken diagrams first published in docs/1.16.0.
GRAPHVIZ_ERROR_SVG = (
    "<svg xmlns='http://www.w3.org/2000/svg'>"
    "<text>Command Processing Architecture (Level 1) - Core Components</text>"
    "<text>Dot Executable: /opt/local/bin/dot</text>"
    "<text>File does not exist</text>"
    "<text>Cannot find Graphviz. You should try</text>"
    "<text>@startuml</text><text>testdot</text><text>@enduml</text>"
    "</svg>"
)
GOOD_SVG = (
    "<svg xmlns='http://www.w3.org/2000/svg'>"
    "<rect width='10' height='10'/><text>CommandHandler</text></svg>"
)


def img(svg):
    encoded = base64.b64encode(svg.encode("utf-8")).decode("ascii")
    return f'<img src="data:image/svg+xml;base64,{encoded}" alt="diagram">'


def png_img(png):
    return f'<img src="data:image/png;base64,{base64.b64encode(png).decode("ascii")}">'


def chunk(kind, data):
    return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data))


def make_png(pixels, filter_type=0, plantuml=True, alpha=False):
    """Encode rows of RGB tuples as an 8-bit PNG using one row filter throughout."""
    bpp = 4 if alpha else 3
    raw, previous = b"", bytes(len(pixels[0]) * bpp)
    for row_pixels in pixels:
        row = b"".join(bytes(p) + (b"\xff" if alpha else b"") for p in row_pixels)
        encoded = bytearray(row)
        for x in range(len(row)):
            left = row[x - bpp] if x >= bpp else 0
            up = previous[x]
            up_left = previous[x - bpp] if x >= bpp else 0
            predictor = (0, left, up, (left + up) // 2, check_doc_diagrams.paeth(left, up, up_left))[filter_type]
            encoded[x] = (row[x] - predictor) & 0xFF
        raw += bytes([filter_type]) + bytes(encoded)
        previous = row
    header = struct.pack(">IIBBBBB", len(pixels[0]), len(pixels), 8, 6 if alpha else 2, 0, 0, 0)
    tag = chunk(b"tEXt", b"copyleft\0" + check_doc_diagrams.PLANTUML_PNG_TAG) if plantuml else b""
    return (
        check_doc_diagrams.PNG_SIGNATURE
        + chunk(b"IHDR", header)
        + tag
        + chunk(b"IDAT", zlib.compress(raw))
        + chunk(b"IEND", b"")
    )


WHITE, BLACK, GREEN = (255, 255, 255), (0, 0, 0), (0x33, 0xFF, 0x02)
WITH_GREEN = [[WHITE, BLACK, WHITE], [BLACK, GREEN, WHITE], [WHITE, WHITE, BLACK]]
WITHOUT_GREEN = [[WHITE, BLACK, WHITE], [BLACK, (0x33, 0xFF, 0x03), WHITE], [WHITE, WHITE, BLACK]]


class PlantumlPngTest(unittest.TestCase):
    def test_published_graphviz_error_png_is_detected(self):
        self.assertTrue(check_doc_diagrams.is_plantuml_error_png(ERROR_PNG))

    def test_rebuilt_png_passes(self):
        self.assertFalse(check_doc_diagrams.is_plantuml_error_png(GOOD_PNG))

    def test_every_row_filter_is_decoded(self):
        for filter_type in range(5):
            for alpha in (False, True):
                with self.subTest(filter_type=filter_type, alpha=alpha):
                    self.assertTrue(
                        check_doc_diagrams.is_plantuml_error_png(make_png(WITH_GREEN, filter_type, alpha=alpha))
                    )
                    self.assertFalse(
                        check_doc_diagrams.is_plantuml_error_png(make_png(WITHOUT_GREEN, filter_type, alpha=alpha))
                    )

    def test_png_not_made_by_plantuml_is_not_decoded(self):
        self.assertFalse(check_doc_diagrams.is_plantuml_error_png(make_png(WITH_GREEN, plantuml=False)))


class BrokenDiagramsTest(unittest.TestCase):
    def test_graphviz_error_image_is_reported(self):
        html = f"<p>{img(GOOD_SVG)}</p><p>{img(GRAPHVIZ_ERROR_SVG)}</p>"
        self.assertEqual(check_doc_diagrams.broken_diagrams(html), ["Cannot find Graphviz"])

    def test_good_diagrams_pass(self):
        self.assertEqual(check_doc_diagrams.broken_diagrams(img(GOOD_SVG) * 3), [])

    def test_error_text_outside_an_image_is_ignored(self):
        # The docs may quote PlantUML's messages in prose; only images count.
        html = "<p>If you see Cannot find Graphviz, install it.</p><img src='images/a.png'>"
        self.assertEqual(check_doc_diagrams.broken_diagrams(html), [])

    def test_broken_png_is_reported_in_page_order(self):
        html = png_img(GOOD_PNG) + png_img(ERROR_PNG) + img(GRAPHVIZ_ERROR_SVG)
        self.assertEqual(
            check_doc_diagrams.broken_diagrams(html),
            [check_doc_diagrams.PNG_ERROR_MARKER, "Cannot find Graphviz"],
        )

    def test_truncated_png_and_invalid_base64_are_skipped(self):
        html = '<img src="data:image/png;base64,iVBORw0KGgo="><img src="data:image/svg+xml;base64,@@@">'
        self.assertEqual(check_doc_diagrams.broken_diagrams(html), [])


class CheckDocsTest(unittest.TestCase):
    def test_reports_each_broken_diagram_per_version(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            for version, body in (
                ("1.16.0", img(GRAPHVIZ_ERROR_SVG) * 2),
                ("1.15.0", img(GOOD_SVG)),
            ):
                (root / version).mkdir()
                (root / version / "index.html").write_text(body, encoding="utf-8")

            errors = check_doc_diagrams.check_docs(root, known_broken={})

        self.assertEqual(len(errors), 2)
        self.assertTrue(all("1.16.0" in error for error in errors))

    def write_page(self, root, version, body):
        (root / version).mkdir()
        (root / version / "index.html").write_text(body, encoding="utf-8")

    def test_known_broken_count_is_allowed(self):
        with tempfile.TemporaryDirectory() as tmp:
            self.write_page(Path(tmp), "1.13.0", png_img(ERROR_PNG))
            self.assertEqual(check_doc_diagrams.check_docs(Path(tmp), {"1.13.0": 1}), [])

    def test_new_breakage_in_a_known_version_fails(self):
        with tempfile.TemporaryDirectory() as tmp:
            self.write_page(Path(tmp), "1.13.0", png_img(ERROR_PNG) + img(GRAPHVIZ_ERROR_SVG))
            self.assertEqual(len(check_doc_diagrams.check_docs(Path(tmp), {"1.13.0": 1})), 2)

    def test_fixed_known_version_asks_for_the_entry_to_go(self):
        with tempfile.TemporaryDirectory() as tmp:
            self.write_page(Path(tmp), "1.13.0", png_img(GOOD_PNG))
            errors = check_doc_diagrams.check_docs(Path(tmp), {"1.13.0": 1})
        self.assertEqual(len(errors), 1)
        self.assertIn("remove it from KNOWN_BROKEN", errors[0])


if __name__ == "__main__":
    unittest.main()
