"""Unit test for the padbridge button map (scripts/padbridge.c).

The safety requirement is simple: the pad may only emit up/down/left/right and
Enter. The Back button and every unlabelled button must be inert, because a
stray Escape/F-key can drop focus to the macOS desktop.
"""

from __future__ import annotations

import re
import unittest
from pathlib import Path

C_SOURCE = Path(__file__).resolve().parent.parent / "scripts" / "padbridge.c"

ARROW_KEYS = {126, 125, 123, 124}  # up, down, left, right (HID key codes)
ENTER = 36
ALLOWED_NONZERO = {1, 2, 3, 4, 8, 10}


def kmap() -> list[int]:
    text = C_SOURCE.read_text()
    m = re.search(
        r"kmap\[\d+\]\s*=\s*\{(.*?)\};", text, re.S
    )
    if not m:
        raise AssertionError("could not find kmap[] initializer")
    body = re.sub(r"/\*.*?\*/", "", m.group(1), flags=re.S)
    body = re.sub(r"//.*", "", body)
    return [int(n) for n in re.findall(r"-?\d+", body)]


class PadbridgeMapTests(unittest.TestCase):
    def test_table_has_15_slots(self):
        self.assertEqual(len(kmap()), 15)

    def test_arrows_and_enter_only(self):
        table = kmap()
        for usage, key in enumerate(table):
            if key != 0:
                self.assertIn(
                    usage, ALLOWED_NONZERO, f"usage {usage} maps to key {key}"
                )
        self.assertEqual([table[1], table[2], table[3], table[4]], [126, 125, 123, 124])
        self.assertEqual(table[8], ENTER)
        self.assertEqual(table[10], ENTER)

    def test_back_is_inert(self):
        self.assertEqual(kmap()[9], 0, "usage 9 (Back) must be inert")

    def test_no_escape_or_system_keys(self):
        table = kmap()
        self.assertNotIn(53, table, "Escape must never be emitted")
        self.assertNotIn(48, table, "Tab must never be emitted")
        for key in table:
            if key:
                self.assertIn(
                    key, ARROW_KEYS | {ENTER}, f"unexpected key code {key}"
                )


if __name__ == "__main__":
    unittest.main()
