"""Tests for .local/bin/md2adf: the converter itself, and the command as each
OS runs it (the script by its shebang on Linux and macOS, md2adf.ps1 on
Windows). Standard library only; run with `python3 -I test_md2adf.py`.
"""

import importlib.machinery
import importlib.util
import json
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

BIN = Path(__file__).resolve().parents[2] / ".local" / "bin"
SCRIPT = BIN / "md2adf"


def load_md2adf():
    # No bytecode: a __pycache__ would land in .local/bin, beside the scripts.
    sys.dont_write_bytecode = True
    loader = importlib.machinery.SourceFileLoader("md2adf", str(SCRIPT))
    spec = importlib.util.spec_from_loader("md2adf", loader)
    assert spec is not None
    module = importlib.util.module_from_spec(spec)
    loader.exec_module(module)
    return module


md2adf = load_md2adf()


def text(value, *marks):
    node = {"type": "text", "text": value}
    if marks:
        node["marks"] = list(marks)
    return node


def para(*content):
    return {"type": "paragraph", "content": list(content)}


def item(*content):
    return {"type": "listItem", "content": list(content)}


def body(md):
    doc = md2adf.convert(md)
    assert doc["type"] == "doc" and doc["version"] == 1, doc
    return doc["content"]


class Convert(unittest.TestCase):
    def test_empty_input_is_an_empty_doc(self):
        self.assertEqual(
            md2adf.convert(""), {"type": "doc", "version": 1, "content": []}
        )

    def test_headings_one_to_six(self):
        self.assertEqual(
            body("# One\n###### Six"),
            [
                {"type": "heading", "attrs": {"level": 1}, "content": [text("One")]},
                {"type": "heading", "attrs": {"level": 6}, "content": [text("Six")]},
            ],
        )

    def test_seven_hashes_or_no_space_is_text(self):
        self.assertEqual(
            body("####### Seven\n\n#tag"),
            [para(text("####### Seven")), para(text("#tag"))],
        )

    def test_lines_join_and_blank_lines_split_paragraphs(self):
        self.assertEqual(
            body("one\n  two\n\nthree"),
            [para(text("one two")), para(text("three"))],
        )

    def test_inline_marks(self):
        self.assertEqual(
            body("a `c` **b** *i* [t](https://example.com/x) z"),
            [
                para(
                    text("a "),
                    text("c", {"type": "code"}),
                    text(" "),
                    text("b", {"type": "strong"}),
                    text(" "),
                    text("i", {"type": "em"}),
                    text(" "),
                    text(
                        "t",
                        {"type": "link", "attrs": {"href": "https://example.com/x"}},
                    ),
                    text(" z"),
                )
            ],
        )

    def test_marks_in_headings_and_list_items(self):
        self.assertEqual(
            body("## `x` title\n\n- **y**"),
            [
                {
                    "type": "heading",
                    "attrs": {"level": 2},
                    "content": [text("x", {"type": "code"}), text(" title")],
                },
                {
                    "type": "bulletList",
                    "content": [item(para(text("y", {"type": "strong"})))],
                },
            ],
        )

    def test_bullet_list_takes_dash_and_star(self):
        self.assertEqual(
            body("- a\n* b"),
            [
                {
                    "type": "bulletList",
                    "content": [item(para(text("a"))), item(para(text("b")))],
                }
            ],
        )

    def test_ordered_list(self):
        self.assertEqual(
            body("1. a\n2. b"),
            [
                {
                    "type": "orderedList",
                    "content": [item(para(text("a"))), item(para(text("b")))],
                }
            ],
        )

    def test_nested_list_joins_the_item_above(self):
        self.assertEqual(
            body("- a\n  1. inner\n- b"),
            [
                {
                    "type": "bulletList",
                    "content": [
                        item(
                            para(text("a")),
                            {
                                "type": "orderedList",
                                "content": [item(para(text("inner")))],
                            },
                        ),
                        item(para(text("b"))),
                    ],
                }
            ],
        )

    def test_indented_line_continues_the_item(self):
        self.assertEqual(
            body("- first\n  more **here**"),
            [
                {
                    "type": "bulletList",
                    "content": [
                        item(
                            para(
                                text("first"),
                                text(" more "),
                                text("here", {"type": "strong"}),
                            )
                        )
                    ],
                }
            ],
        )

    def test_list_marker_inside_a_paragraph_stays_text(self):
        self.assertEqual(
            body("intro\n- not a list"), [para(text("intro - not a list"))]
        )

    def test_list_ends_at_a_blank_line(self):
        self.assertEqual(
            body("- a\n\nafter"),
            [
                {"type": "bulletList", "content": [item(para(text("a")))]},
                para(text("after")),
            ],
        )

    def test_code_block_keeps_language_and_indentation(self):
        self.assertEqual(
            body("```bash\necho **hi**\n  indented\n```\nafter"),
            [
                {
                    "type": "codeBlock",
                    "attrs": {"language": "bash"},
                    "content": [text("echo **hi**\n  indented")],
                },
                para(text("after")),
            ],
        )

    def test_code_block_without_language_has_no_attrs(self):
        self.assertEqual(
            body("```\nx\n```"),
            [{"type": "codeBlock", "content": [text("x")]}],
        )

    def test_unterminated_code_block_runs_to_the_end(self):
        self.assertEqual(
            body("text\n```\nx\ny"),
            [para(text("text")), {"type": "codeBlock", "content": [text("x\ny")]}],
        )

    def test_crlf_input_matches_lf(self):
        md = "# H\n\n- a\n  b\n\n```py\nx = 1\n```\n"
        self.assertEqual(md2adf.convert(md.replace("\n", "\r\n")), md2adf.convert(md))


class Command(unittest.TestCase):
    """md2adf as a shell runs it on this OS."""

    @staticmethod
    def run_md2adf(*args):
        if sys.platform == "win32":
            cmd = ["pwsh", "-NoProfile", "-File", str(BIN / "md2adf.ps1"), *args]
        else:
            cmd = [str(SCRIPT), *args]
        return subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8")

    def write(self, content):
        fd, path = tempfile.mkstemp(suffix=".md")
        with os.fdopen(fd, "w", encoding="utf-8", newline="") as f:
            f.write(content)
        self.addCleanup(os.remove, path)
        return path

    def test_prints_the_adf_json_of_a_file(self):
        md = "## Ticket\n\nSee `x` and **y**.\n\n- one\n1. two\n"
        result = self.run_md2adf(self.write(md))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout), md2adf.convert(md))

    def test_reads_the_file_as_utf8(self):
        result = self.run_md2adf(self.write("# Café ✓\n"))
        self.assertEqual(result.returncode, 0, result.stderr)
        heading = json.loads(result.stdout)["content"][0]
        self.assertEqual(heading["content"], [text("Café ✓")])

    def test_usage_without_a_file(self):
        result = self.run_md2adf()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("usage: md2adf", result.stderr)
        self.assertEqual(result.stdout, "")

    def test_missing_file_fails(self):
        missing = os.path.join(tempfile.gettempdir(), "md2adf-no-such-file.md")
        result = self.run_md2adf(missing)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(result.stdout, "")


if __name__ == "__main__":
    unittest.main(verbosity=2)
