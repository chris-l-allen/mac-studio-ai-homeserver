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
# menu buttons on Home/End/Delete/PgDn, and directions vs menu not shared.
BROKEN = """[dance]
1_Down=Key_down
1_Left=Key_left
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
            rc = fix_keymap.main(argv)
        return rc, buf.getvalue()

    def test_broken_keymap_fails_check(self):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d) / "Keymaps.ini"
            p.write_text(BROKEN)
            rc, _ = self.run_main(["--check", "--file", str(p), "--no-lock"])
            self.assertEqual(rc, 1)

    def test_apply_fixes_and_validates(self):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d) / "Keymaps.ini"
            p.write_text(BROKEN)
            rc, _ = self.run_main(["--file", str(p), "--no-lock"])
            self.assertEqual(rc, 0)
            rc2, out = self.run_main(["--check", "--file", str(p), "--no-lock"])
            self.assertEqual(rc2, 0, out)

            _, entries, _ = fix_keymap.parse(p.read_text())
            # Directions and their matching menu buttons share the pad keys.
            for a, k in (
                ("1_Up", "Key_up"), ("1_MenuUp", "Key_up"),
                ("1_Down", "Key_down"), ("1_MenuDown", "Key_down"),
                ("1_Left", "Key_left"), ("1_MenuLeft", "Key_left"),
                ("1_Right", "Key_right"), ("1_MenuRight", "Key_right"),
                ("2_Up", "Key_w"), ("2_MenuUp", "Key_w"),
                ("2_Down", "Key_s"), ("2_MenuDown", "Key_s"),
                ("2_Left", "Key_a"), ("2_MenuLeft", "Key_a"),
                ("2_Right", "Key_d"), ("2_MenuRight", "Key_d"),
            ):
                self.assertEqual(entries[a], k, a)

    def test_canonical_has_no_content_problems(self):
        self.assertEqual(fix_keymap.problems(fix_keymap.CANONICAL), [])

    def test_duplicate_bindings_detected(self):
        keys = fix_keymap.overlaps(fix_keymap.CANONICAL)
        self.assertIn("Key_left", keys)
        self.assertIn("Key_w", keys)

    def test_check_requires_lock_when_duplicates(self):
        # Not locked -> check must fail even though content is canonical.
        with tempfile.TemporaryDirectory() as d:
            p = Path(d) / "Keymaps.ini"
            p.write_text("[dance]\n")
            self.run_main(["--file", str(p), "--no-lock"])
            try:
                rc, out = self.run_main(["--check", "--file", str(p)])
                self.assertEqual(rc, 1, out)
                self.assertIn("not locked", out)
                fix_keymap.set_locked(p, True)
                rc2, out2 = self.run_main(["--check", "--file", str(p)])
                self.assertEqual(rc2, 0, out2)
            finally:
                fix_keymap.set_locked(p, False)

    def test_apply_locks_and_survives(self):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d) / "Keymaps.ini"
            p.write_text("[dance]\n")
            try:
                rc, _ = self.run_main(["--file", str(p)])
                self.assertEqual(rc, 0)
                self.assertTrue(fix_keymap.is_locked(p))
                # Simulate OutFox trying to rewrite: the write should fail.
                with self.assertRaises(PermissionError):
                    p.write_text("garbage")
            finally:
                fix_keymap.set_locked(p, False)

    def test_forbidden_key_in_direction_fails(self):
        entries = {
            "2_Left": "Key_escape",
            "2_MenuLeft": "Key_escape",
        }
        issues = fix_keymap.problems(entries)
        self.assertTrue(any("forbidden" in x for x in issues), issues)

    def test_unknown_keys_are_preserved(self):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d) / "Keymaps.ini"
            p.write_text(BROKEN + "1_Custom=Key_z\n")
            self.run_main(["--file", str(p), "--no-lock"])
            _, entries, _ = fix_keymap.parse(p.read_text())
            self.assertEqual(entries.get("1_Custom"), "Key_z")

    def test_missing_section_is_error(self):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d) / "Keymaps.ini"
            p.write_text("nothing here\n")
            rc, _ = self.run_main(["--check", "--file", str(p), "--no-lock"])
            self.assertEqual(rc, 2)


if __name__ == "__main__":
    unittest.main()
