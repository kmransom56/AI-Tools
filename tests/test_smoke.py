import unittest
import os
import sys
import subprocess


class TestSmokeAndBranches(unittest.TestCase):
    def test_required_files_present(self):
        # Basic repo health checks that don't require heavy dependencies
        repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
        self.assertTrue(
            os.path.exists(os.path.join(repo_root, "ai_web_app.py"))
            or os.path.exists(os.path.join(repo_root, "AI-Tools-ci", "ai_web_app.py")),
            "ai_web_app.py not found in repo root",
        )
        self.assertTrue(
            os.path.exists(os.path.join(repo_root, "requirements.txt"))
            or os.path.exists(
                os.path.join(repo_root, "AI-Tools-ci", "requirements.txt")
            ),
            "requirements.txt not found in repo root",
        )

    def test_gpu_branches_exist(self):
        repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
        branches = ["gpu-k80-test", "gpu-rtx3060ti-test"]
        for br in branches:
            with self.subTest(branch=br):
                res = subprocess.run(
                    ["git", "rev-parse", "--verify", br],
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                    text=True,
                    cwd=repo_root,
                )
                self.assertEqual(
                    res.returncode, 0, f"Branch {br} not found: {res.stderr.strip()}"
                )


if __name__ == "__main__":
    unittest.main()
