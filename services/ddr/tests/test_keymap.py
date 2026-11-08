"""Unit tests for scripts/fix-keymap.py (the DDR keymap contract)."""

from __future__ import annotations

import contextlib
import importlib.util
import io
import tempfile
import unittest
from pathlib import Path

SCRIPTS = Path(__file__).resolve().parent.parent / "scripts"
SPEC = importlib.util.spec_from_file_location("fix_keymap", SCRIPTS / "fix-keymap.py")
fix_keymap = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(fix_keymap)

# What .54's broken keymap looked like: W/D on directions, A/S only on menu,
# and the menu buttons on Home/End/Delete/PgDn instead of the arrows.
BROKEN = """[dance]
1_MenuUp=::::Key_home
1_MenuDown=::::Key_end
1_MenuLeft=::::Key_delete
1_MenuRight=::::Key_pgdn
2_Up=Key_w::::Key_KP 8
2_Down=::::Key_KP 2
2_Left=::::Key_KP 4
2_Right=Key_d::::Key_KP 6
2_MenuDown=Key_s::::Key_KP +
2_MenuLeft=Key_a::::Key_KP /
"""


class KeymapTests(unittest.TestCase):
    def run_main(self, argv):
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf), contextlib.redirect_stderr(buf):
            return fix_keymap.main(argv), buf.getvalue()

    def test_broken_keymap_fails_check(self):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d) / "Keymaps.ini"
            p.write_text(BROKEN)
            rc, _ = self.run_main(["--check", "--file", str(p)])
            self.assertEqual(rc, 1)

    def test_apply_fixes_and_validates(self):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d) / "Keymaps.ini"
            p.write_text(BROKEN)
            rc, _ = self.run_main(["--file", str(p), "--force"])
            self.assertEqual(rc, 0)
            rc2, out = self.run_main(["--check", "--file", str(p)])
            self.assertEqual(rc2, 0, out)

            _, entries, _ = fix_keymap.parse(p.read_text())
            # P1/P2 directions.
            for a, k in (("1_Up", "Key_up"), ("1_Down", "Key_down"),
                         ("1_Left", "Key_left"), ("1_Right", "Key_right"),
                         ("2_Up", "Key_w"), ("2_Down", "Key_s"),
                         ("2_Left", "Key_a"), ("2_Right", "Key_d")):
                self.assertEqual(entries[a], k)
            # Menu buttons must stay unbound so they cannot collide with the
            # direction bindings (OutFox clears one side on exit).
            for a in ("1_MenuUp", "1_MenuDown", "1_MenuLeft", "1_MenuRight",
                      "2_MenuUp", "2_MenuDown", "2_MenuLeft", "2_MenuRight"):
                self.assertEqual(entries[a], "")

    def test_no_direction_menu_overlap(self):
        issues = fix_keymap.problems(fix_keymap.CANONICAL)
        self.assertFalse(
            [x for x in issues if "both a direction and a menu" in x], issues
        )

    def test_overlap_is_rejected(self):
        entries = dict(fix_keymap.CANONICAL)
        entries["1_MenuUp"] = "Key_up"  # collides with 1_Up
        issues = fix_keymap.problems(entries)
        self.assertTrue(any("both a direction and a menu" in x for x in issues), issues)

    def test_forbidden_key_in_direction_fails(self):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d) / "Keymaps.ini"
            p.write_text("[dance]\n2_Left=Key_escape\n")
            issues = fix_keymap.problems(fix_keymap.parse(p.read_text())[1])
            self.assertTrue(any("forbidden" in x for x in issues), issues)

    def test_unknown_keys_are_preserved(self):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d) / "Keymaps.ini"
            p.write_text(BROKEN + "1_Custom=Key_z\n")
            self.run_main(["--file", str(p), "--force"])
            _, entries, _ = fix_keymap.parse(p.read_text())
            self.assertEqual(entries.get("1_Custom"), "Key_z")

    def test_missing_section_is_error(self):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d) / "Keymaps.ini"
            p.write_text("nothing here\n")
            rc, _ = self.run_main(["--check", "--file", str(p)])
            self.assertEqual(rc, 2)


if __name__ == "__main__":
    unittest.main()
