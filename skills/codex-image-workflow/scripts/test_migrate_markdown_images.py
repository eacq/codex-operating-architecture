#!/usr/bin/env python3
"""Focused regression tests for Bilibili CDN URL validation."""

from __future__ import annotations

import unittest
from unittest.mock import patch

from migrate_markdown_images import verify_remote


class FakeResponse:
    status = 206

    def __enter__(self):
        return self

    def __exit__(self, *_args):
        return False


class VerifyRemoteTests(unittest.TestCase):
    @patch("migrate_markdown_images.urllib.request.urlopen", return_value=FakeResponse())
    def test_accepts_current_bilibili_image_cdn(self, _urlopen):
        verify_remote("https://article.biliimg.com/bfs/new_dyn/test.png")

    @patch("migrate_markdown_images.urllib.request.urlopen", return_value=FakeResponse())
    def test_accepts_legacy_bilibili_cdns(self, _urlopen):
        verify_remote("https://i0.hdslb.com/bfs/test.png")
        verify_remote("https://static.bilibili.com/test.png")

    def test_rejects_non_https_and_unrelated_hosts(self):
        for url in ("http://article.biliimg.com/test.png", "https://example.com/test.png"):
            with self.subTest(url=url), self.assertRaises(RuntimeError):
                verify_remote(url)


if __name__ == "__main__":
    unittest.main()
