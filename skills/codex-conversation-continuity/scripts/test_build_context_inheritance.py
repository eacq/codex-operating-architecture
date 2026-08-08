import argparse
import unittest

from build_context_inheritance import render


class ContextInheritanceBudgetTests(unittest.TestCase):
    def _records(self, count: int):
        records = [{"type": "session_meta", "payload": {"id": "fixture"}}]
        for index in range(count):
            records.append({
                "type": "compacted",
                "payload": {"window_number": index + 1, "previous_window_id": f"p{index}",
                            "window_id": f"w{index}",
                            "message": "# Decision\n- retained constraint " + ("x" * 400)},
            })
        return records

    def test_tight_budget_reports_omissions(self):
        args = argparse.Namespace(current_before=None, current_after=None, max_chars=1000, per_block_chars=200)
        output = render(args, self._records(12))
        self.assertLessEqual(len(output), args.max_chars)
        self.assertNotIn("Omitted blocks due to budget: 0", output)

    def test_large_budget_retains_all_windows(self):
        args = argparse.Namespace(current_before=None, current_after=None, max_chars=12000, per_block_chars=1400)
        output = render(args, self._records(8))
        self.assertIn("Omitted blocks due to budget: 0", output)
        for index in range(1, 9):
            self.assertIn(f"Historical compaction window {index}", output)


if __name__ == "__main__":
    unittest.main()
