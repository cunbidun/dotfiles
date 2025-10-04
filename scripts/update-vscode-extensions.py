#!/usr/bin/env python3
"""Generate marketplace VS Code extensions as Nix derivations.

This script reads extension identifiers (`publisher.name`) from
`scripts/vscode-extensions.txt`, determines the expected Visual Studio
Code build (either via Microsoft's update API or a user-supplied
override), selects the newest extension release whose engine requirement
is satisfied by that VS Code version, downloads its VSIX once to compute
integrity hashes, and finally writes
`nix/home-manager/configs/vscode/extensions.nix`. Existing content is
overwritten.
"""
from __future__ import annotations

import argparse
import base64
import hashlib
import json
import re
import sys
import textwrap
import urllib.error
import urllib.request
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, List, Optional

MARKETPLACE_API = (
    "https://marketplace.visualstudio.com/_apis/public/gallery/extensionquery"
    "?api-version=7.2-preview.1"
)
UPDATE_API = "https://update.code.visualstudio.com/api/update/{platform}/{quality}/latest"


@dataclass
class ExtensionSpec:
    publisher: str
    name: str
    version: str
    download_url: str
    hash: str
    engine: Optional[str]

    @property
    def identifier(self) -> str:
        return f"{self.publisher}.{self.name}"


def read_extension_ids(path: Path) -> List[str]:
    ids: List[str] = []
    for raw_line in path.read_text().splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        if "." not in line:
            raise ValueError(f"Invalid extension identifier '{line}' – expected 'publisher.name'.")
        ids.append(line)
    if not ids:
        raise ValueError(f"No extensions found in {path}.")
    return ids


def query_extension(publisher: str, name: str) -> dict:
    body = {
        "filters": [
            {
                "criteria": [
                    {
                        "filterType": 7,
                        "value": f"{publisher}.{name}",
                    }
                ],
                "pageNumber": 1,
                "pageSize": 1,
                "sortBy": 0,
                "sortOrder": 0,
            }
        ],
        # flags 914 -> include versions, files, statistics (same as VS Code)
        "flags": 914,
    }
    data = json.dumps(body).encode("utf-8")
    request = urllib.request.Request(
        MARKETPLACE_API,
        data=data,
        headers={
            "Content-Type": "application/json",
            "Accept": "application/json;api-version=7.2-preview.1",
            "User-Agent": "nix-vscode-extension-generator/1.0",
        },
        method="POST",
    )
    with urllib.request.urlopen(request) as response:
        payload = json.load(response)
    try:
        return payload["results"][0]["extensions"][0]
    except (KeyError, IndexError) as err:
        raise RuntimeError(f"Extension {publisher}.{name} not found on marketplace") from err


def compute_caret_upper_bound(base: tuple[int, int, int]) -> tuple[int, int, int]:
    major, minor, patch = base
    if major > 0:
        return (major + 1, 0, 0)
    if minor > 0:
        return (major, minor + 1, 0)
    return (major, minor, patch + 1)


def compute_tilde_upper_bound(base: tuple[int, int, int]) -> tuple[int, int, int]:
    major, minor, _patch = base
    return (major, minor + 1, 0)


def parse_version(version: str) -> tuple[int, int, int]:
    core = re.split(r"[-+]", version, maxsplit=1)[0]
    parts = core.split(".")
    nums = [int(p) for p in parts[:3]]
    while len(nums) < 3:
        nums.append(0)
    return nums[0], nums[1], nums[2]


def compare_versions(a: tuple[int, int, int], b: tuple[int, int, int]) -> int:
    if a == b:
        return 0
    return 1 if a > b else -1


Constraint = tuple[str, tuple[int, int, int]]


def expand_constraint(token: str) -> list[Constraint]:
    token = token.strip()
    if not token or token == "*":
        return []
    if token.startswith("^"):
        lower = parse_version(token[1:])
        upper = compute_caret_upper_bound(lower)
        return [(">=", lower), ("<", upper)]
    if token.startswith("~"):
        lower = parse_version(token[1:])
        upper = compute_tilde_upper_bound(lower)
        return [(">=", lower), ("<", upper)]
    for op in (">=", "<=", ">", "<", "="):
        if token.startswith(op):
            return [(op, parse_version(token[len(op) :]))]
    return [("=", parse_version(token))]


def satisfies_engine(version: str, range_expr: Optional[str]) -> bool:
    if not range_expr:
        return True
    expr = range_expr.strip()
    if not expr or expr == "*":
        return True

    version_tuple = parse_version(version)
    for alternative in expr.split("||"):
        tokens = [tok for tok in alternative.strip().split() if tok]
        constraints: list[Constraint] = []
        for token in tokens:
            constraints.extend(expand_constraint(token))
        if not constraints:
            return True
        if all(
            (
                compare_versions(version_tuple, target) >= 0
                if op == ">="
                else compare_versions(version_tuple, target) <= 0
                if op == "<="
                else compare_versions(version_tuple, target) > 0
                if op == ">"
                else compare_versions(version_tuple, target) < 0
                if op == "<"
                else compare_versions(version_tuple, target) == 0
            )
            for op, target in constraints
        ):
            return True
    return False


def locate_vsix(
    metadata: dict,
    vscode_version: str,
    allow_incompatible: bool,
) -> tuple[str, str, Optional[str]]:
    versions = metadata.get("versions", [])
    if not versions:
        raise RuntimeError("Marketplace response is missing versions array")

    fallback: Optional[tuple[str, str, Optional[str]]] = None

    for entry in versions:
        version = entry.get("version")
        if not version:
            continue
        properties = {prop["key"]: prop["value"] for prop in entry.get("properties", [])}
        engine_req = properties.get("Microsoft.VisualStudio.Code.Engine")
        base_uri = entry.get("fallbackAssetUri") or entry.get("assetUri")
        if base_uri:
            url = f"{base_uri}/Microsoft.VisualStudio.Services.VSIXPackage"
            if satisfies_engine(vscode_version, engine_req):
                return version, url, engine_req
            if allow_incompatible and fallback is None:
                fallback = (version, url, engine_req)

    if allow_incompatible and fallback is not None:
        version, url, engine_req = fallback
        print(
            f"Warning: using {metadata.get('extensionId', 'extension')}@{version} despite engine constraint {engine_req!r} for VS Code {vscode_version}",
            file=sys.stderr,
        )
        return version, url, engine_req

    raise RuntimeError(
        f"No compatible VSIX found for VS Code {vscode_version}"
    )


def download_hash(url: str) -> str:
    request = urllib.request.Request(url, headers={"Accept-Encoding": "identity"})
    with urllib.request.urlopen(request) as response:
        payload = response.read()
    digest = hashlib.sha256(payload).digest()
    return f"sha256-{base64.b64encode(digest).decode('ascii')}"


def fetch_extension(
    publisher: str,
    name: str,
    vscode_version: str,
    allow_incompatible: bool,
) -> ExtensionSpec:
    metadata = query_extension(publisher, name)
    version, url, engine = locate_vsix(metadata, vscode_version, allow_incompatible)
    hash_value = download_hash(url)
    return ExtensionSpec(publisher, name, version, url, hash_value, engine)


def fetch_vscode_version(platform: str, quality: str) -> str:
    request = urllib.request.Request(
        UPDATE_API.format(platform=platform, quality=quality),
        headers={"Accept": "application/json", "User-Agent": "nix-vscode-extension-generator/1.0"},
    )
    with urllib.request.urlopen(request) as response:
        payload = json.load(response)
    try:
        return payload["name"]
    except KeyError as err:
        raise RuntimeError("Unable to determine VS Code version from update API") from err


def generate_nix(exts: Iterable[ExtensionSpec]) -> str:
    header = textwrap.dedent(
        """
        # This file is auto-generated by scripts/update-vscode-extensions.py
        # Do not edit manually; run the script after changing vscode-extensions.txt.
        { pkgs }:
        let
          inherit (pkgs.vscode-utils) buildVscodeMarketplaceExtension;
        in [
        """
    ).lstrip("\n")

    body_lines = []
    for ext in exts:
        body_lines.append(
            textwrap.dedent(
                f"""
                  (buildVscodeMarketplaceExtension {{
                    mktplcRef = {{
                      publisher = "{ext.publisher}";
                      name = "{ext.name}";
                      version = "{ext.version}";
                      hash = "{ext.hash}"; # engine {ext.engine or '*'}
                    }};
                  }})
                """
            ).rstrip()
        )

    body = "\n".join(body_lines)
    footer = "\n]\n"
    return header + body + footer


def main(argv: List[str]) -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--input",
        type=Path,
        default=Path(__file__).resolve().parent / "vscode-extensions.txt",
        help="Path to the extension list (default: scripts/vscode-extensions.txt)",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=Path(__file__).resolve().parents[1]
        / "nix/home-manager/configs/vscode/extensions.nix",
        help="Path to the generated Nix file",
    )
    parser.add_argument(
        "--platform",
        default="linux-x64",
        help="VS Code platform identifier for the update API (default: linux-x64)",
    )
    parser.add_argument(
        "--quality",
        default="stable",
        help="VS Code quality channel (default: stable)",
    )
    parser.add_argument(
        "--vscode-version",
        help="Explicit VS Code version (skip querying the update API)",
    )
    parser.add_argument(
        "--allow-incompatible",
        action="store_true",
        help="Allow falling back to the newest release even if its engine constraint is unsatisfied",
    )
    args = parser.parse_args(argv)

    try:
        identifiers = read_extension_ids(args.input)
    except Exception as exc:  # pylint: disable=broad-except
        parser.error(str(exc))

    if args.vscode_version:
        vscode_version = args.vscode_version
    else:
        vscode_version = fetch_vscode_version(args.platform, args.quality)
    print(f"Using VS Code {vscode_version} for compatibility checks")

    allow_incompatible = args.allow_incompatible or not args.vscode_version

    specs: List[ExtensionSpec] = []
    skipped: List[str] = []
    for ident in identifiers:
        publisher, name = ident.split(".", 1)
        try:
            spec = fetch_extension(publisher, name, vscode_version, allow_incompatible)
        except RuntimeError as exc:
            print(f"Skipping {ident}: {exc}", file=sys.stderr)
            skipped.append(ident)
            continue
        except urllib.error.URLError as exc:
            raise SystemExit(f"Failed to fetch {ident}: {exc}") from exc
        specs.append(spec)
        print(f"Fetched {ident}@{spec.version} (engine {spec.engine or '*'})")

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(generate_nix(exts=specs))
    print(f"Wrote {args.output}")
    if skipped:
        print(
            "Skipped incompatible extensions: " + ", ".join(skipped),
            file=sys.stderr,
        )


if __name__ == "__main__":
    main(sys.argv[1:])
