"""Unit tests for scripts/fix-keymap.py (the DDR keymap contract).

The critical invariant: a key is never bound to both a gameplay direction and
the matching menu button. OutFox drops the direction side of such a duplicate,
so the pad works in menus but not in gameplay.
"""

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

# The old broken shape: A/S on menu only, arrows duplicated with menu, P2
# Down/Left on keypad only.
BROKEN = """[dance]
1_MenuUp=Key_up
1_MenuLeft=Key_left
1_MenuRight=Key_right
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
            rc = fix_keymap.main(argv)
        return rc, buf.getvalue()

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
            rc, _ = self.run_main(["--file", str(p)])
            self.assertEqual(rc, 0)
            rc2, out = self.run_main(["--check", "--file", str(p)])
            self.assertEqual(rc2, 0, out)

            _, entries, _ = fix_keymap.parse(p.read_text())
            for a, k in (
                ("1_Up", "Key_up"), ("1_Down", "Key_down"),
                ("1_Left", "Key_left"), ("1_Right", "Key_right"),
                ("2_Up", "Key_w"), ("2_Down", "Key_s"),
                ("2_Left", "Key_a"), ("2_Right", "Key_d"),
                ("1_Start", "Key_enter"), ("2_Start", "Key_space"),
            ):
                self.assertEqual(entries[a], k, a)
            # Menus must never share the direction keys.
            for a in ("1_MenuUp", "1_MenuDown", "1_MenuLeft", "1_MenuRight",
                      "2_MenuUp", "2_MenuDown", "2_MenuLeft", "2_MenuRight"):
                self.assertEqual(entries[a], "", a)

    def test_canonical_has_no_problems(self):
        self.assertEqual(fix_keymap.problems(fix_keymap.CANONICAL), [])

    def test_canonical_has_no_overlap(self):
        self.assertEqual(fix_keymap.overlaps(fix_keymap.CANONICAL), [])

    def test_duplicate_binding_is_rejected(self):
        entries = dict(fix_keymap.CANONICAL)
        entries["1_MenuUp"] = "Key_up"  # collides with 1_Up
        issues = fix_keymap.problems(entries)
        self.assertTrue(any("both a direction and a menu" in x for x in issues), issues)

    def test_forbidden_key_in_direction_fails(self):
        entries = dict(fix_keymap.CANONICAL)
        entries["2_Left"] = "Key_escape"
        issues = fix_keymap.problems(entries)
        self.assertTrue(any("forbidden" in x for x in issues), issues)

    def test_unknown_keys_are_preserved(self):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d) / "Keymaps.ini"
            p.write_text(BROKEN + "1_Custom=Key_z\n")
            self.run_main(["--file", str(p)])
            _, entries, _ = fix_keymap.parse(p.read_text())
            self.assertEqual(entries.get("1_Custom"), "Key_z")

    def test_missing_section_is_error(self):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d) / "Keymaps.ini"
            p.write_text("nothing here\n")
            rc, _ = self.run_main(["--check", "--file", str(p)])
            self.assertEqual(rc, 2)

    def test_unlocks_immutable_file_before_writing(self):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d) / "Keymaps.ini"
            p.write_text("[dance]\n")
            subprocess = __import__("subprocess")
            subprocess.run(["chflags", "uchg", str(p)], check=True)
            try:
                rc, _ = self.run_main(["--file", str(p)])
                self.assertEqual(rc, 0)
                self.assertFalse(
                    bool(getattr(p.stat(), "st_flags", 0) & 0x2),
                    "file should be writable after apply",
                )
            finally:
                subprocess.run(["chflags", "nouchg", str(p)], check=False)


if __name__ == "__main__":
    unittest.main()
