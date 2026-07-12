#!/usr/bin/env python3
"""State-machine tests for source-bound draft release publication."""

from __future__ import annotations

import importlib.util
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MODULE_PATH = ROOT / "scripts" / "publish_github_release.py"
SPEC = importlib.util.spec_from_file_location("publish_github_release", MODULE_PATH)
assert SPEC and SPEC.loader
publisher_module = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = publisher_module
SPEC.loader.exec_module(publisher_module)


Response = publisher_module.Response
ReleaseError = publisher_module.ReleaseError
ReleasePublisher = publisher_module.ReleasePublisher
TransportError = publisher_module.TransportError
inspect_assets = publisher_module.inspect_assets


class FakeAPI:
    def __init__(self) -> None:
        self.release = None
        self.assets = []
        self.next_asset_id = 100
        self.calls = []
        self.ambiguous_create = False
        self.ambiguous_publish = False
        self.ambiguous_upload_names = set()

    def get_release_by_tag(self, repository, tag):
        self.calls.append(("get_by_tag", repository, tag))
        if self.release is None or self.release["tag_name"] != tag:
            return Response(404, {"message": "Not Found"}, {})
        return Response(200, dict(self.release), {})

    def get_release(self, repository, release_id):
        self.calls.append(("get", repository, release_id))
        if self.release is None or self.release["id"] != release_id:
            return Response(404, {"message": "Not Found"}, {})
        return Response(200, dict(self.release), {})

    def create_release(self, repository, payload):
        self.calls.append(("create", repository, dict(payload)))
        if self.release is not None:
            return Response(422, {"message": "already_exists"}, {})
        self.release = {
            "id": 42,
            "tag_name": payload["tag_name"],
            "target_commitish": payload["target_commitish"],
            "name": payload["name"],
            "body": payload["body"],
            "draft": payload["draft"],
            "prerelease": payload["prerelease"],
        }
        if self.ambiguous_create:
            raise TransportError("simulated ambiguous create")
        return Response(201, dict(self.release), {})

    def update_release(self, repository, release_id, payload):
        self.calls.append(("update", repository, release_id, dict(payload)))
        assert self.release and self.release["id"] == release_id
        self.release.update(payload)
        if self.ambiguous_publish:
            raise TransportError("simulated ambiguous publish")
        return Response(200, dict(self.release), {})

    def list_assets(self, repository, release_id):
        self.calls.append(("list_assets", repository, release_id))
        assert self.release and self.release["id"] == release_id
        return [dict(asset) for asset in self.assets]

    def delete_asset(self, repository, asset_id):
        self.calls.append(("delete_asset", repository, asset_id))
        self.assets = [asset for asset in self.assets if asset["id"] != asset_id]
        return Response(204, None, {})

    def upload_asset(self, repository, release_id, name, content):
        self.calls.append(("upload_asset", repository, release_id, name, bytes(content)))
        asset = {
            "id": self.next_asset_id,
            "name": name,
            "state": "uploaded",
            "size": len(content),
            "digest": f"sha256:{publisher_module.hashlib.sha256(content).hexdigest()}",
        }
        self.next_asset_id += 1
        self.assets.append(asset)
        if name in self.ambiguous_upload_names:
            raise TransportError("simulated ambiguous upload")
        return Response(201, dict(asset), {})


class ReleasePublisherTests(unittest.TestCase):
    repository = "virtualboard/example"
    tag = "v1.2.3"
    sha = "a" * 40
    title = "VirtualBoard example v1.2.3"

    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        root = Path(self.temporary.name)
        self.first = root / "first.bin"
        self.second = root / "checksums.txt"
        self.first.write_bytes(b"first-release-bytes")
        self.second.write_bytes(b"checksum manifest\n")
        self.assets = inspect_assets([str(self.first), str(self.second)])

    def make_publisher(self, api):
        return ReleasePublisher(
            api,
            self.repository,
            self.tag,
            self.sha,
            self.title,
            self.assets,
        )

    def bind_draft(self, api, publisher, *, draft=True, marker=None, sha=None):
        api.release = {
            "id": 42,
            "tag_name": self.tag,
            "target_commitish": sha or self.sha,
            "name": self.title,
            "body": marker if marker is not None else publisher.marker,
            "draft": draft,
            "prerelease": False,
        }

    def remote_asset(self, asset_id, expected, *, size=None, state="uploaded"):
        return {
            "id": asset_id,
            "name": expected.name,
            "state": state,
            "size": expected.size if size is None else size,
            "digest": f"sha256:{expected.sha256}",
        }

    def test_published_same_tag_is_refused_without_asset_mutation(self):
        api = FakeAPI()
        publisher = self.make_publisher(api)
        self.bind_draft(api, publisher, draft=False)

        with self.assertRaisesRegex(ReleaseError, "published release.*already exists"):
            publisher.publish()

        self.assertFalse(any(call[0] in {"delete_asset", "upload_asset", "update"} for call in api.calls))

    def test_mismatched_same_tag_draft_is_never_reconciled(self):
        api = FakeAPI()
        publisher = self.make_publisher(api)
        self.bind_draft(api, publisher, marker="not-the-binding-marker")

        with self.assertRaisesRegex(ReleaseError, "source-binding marker"):
            publisher.publish()

        self.assertFalse(any(call[0] in {"delete_asset", "upload_asset", "update"} for call in api.calls))

    def test_valid_partial_draft_is_reconciled_then_published(self):
        api = FakeAPI()
        publisher = self.make_publisher(api)
        self.bind_draft(api, publisher)
        first, second = self.assets
        api.assets = [
            self.remote_asset(1, first),
            self.remote_asset(2, second, size=second.size + 1),
            {
                "id": 3,
                "name": "unexpected.bin",
                "state": "uploaded",
                "size": 4,
                "digest": None,
            },
        ]

        release_id = publisher.publish()

        self.assertEqual(release_id, 42)
        self.assertFalse(api.release["draft"])
        self.assertEqual({asset["name"] for asset in api.assets}, {first.name, second.name})
        self.assertEqual(
            {call[2] for call in api.calls if call[0] == "delete_asset"}, {2, 3}
        )
        self.assertEqual(
            [call[3] for call in api.calls if call[0] == "upload_asset"],
            [second.name],
        )

    def test_ambiguous_create_resumes_only_the_created_bound_draft(self):
        api = FakeAPI()
        api.ambiguous_create = True
        publisher = self.make_publisher(api)

        self.assertEqual(publisher.publish(), 42)
        self.assertFalse(api.release["draft"])
        self.assertEqual(len([call for call in api.calls if call[0] == "create"]), 1)

    def test_ambiguous_publish_is_refetched_and_never_cleaned_up(self):
        api = FakeAPI()
        api.ambiguous_publish = True
        publisher = self.make_publisher(api)
        self.bind_draft(api, publisher)

        self.assertEqual(publisher.publish(), 42)
        self.assertFalse(api.release["draft"])
        self.assertFalse(any(call[0] == "delete_release" for call in api.calls))

    def test_ambiguous_upload_is_reconciled_by_exact_name_size_and_digest(self):
        api = FakeAPI()
        publisher = self.make_publisher(api)
        self.bind_draft(api, publisher)
        api.ambiguous_upload_names.add(self.assets[0].name)

        self.assertEqual(publisher.publish(), 42)
        self.assertEqual(
            {asset["name"] for asset in api.assets},
            {expected.name for expected in self.assets},
        )

    def test_draft_with_different_source_sha_is_refused(self):
        api = FakeAPI()
        publisher = self.make_publisher(api)
        self.bind_draft(api, publisher, sha="b" * 40)

        with self.assertRaisesRegex(ReleaseError, "different source SHA"):
            publisher.publish()

        self.assertFalse(any(call[0] in {"delete_asset", "upload_asset", "update"} for call in api.calls))

    def test_zero_length_and_linked_assets_are_rejected(self):
        root = Path(self.temporary.name)
        empty = root / "empty.bin"
        empty.write_bytes(b"")
        with self.assertRaisesRegex(ReleaseError, "between 1 and"):
            inspect_assets([str(empty)])

        link = root / "link.bin"
        try:
            link.symlink_to(self.first)
        except (NotImplementedError, OSError):
            self.skipTest("symlinks are unavailable")
        with self.assertRaisesRegex(ReleaseError, "regular unlinked file"):
            inspect_assets([str(link)])


if __name__ == "__main__":
    unittest.main()
