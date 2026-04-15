#!/usr/bin/env python3
"""Block edits to sensitive files containing secrets or credentials.

Prevents accidental modification of environment files, private keys,
certificates, and other files that commonly hold sensitive data.
Exit code 2 blocks the tool call and surfaces the error to the user.

Customize:
  - Add filenames to `blocked_names` to protect additional specific files
    (e.g. "vault-token", "kubeconfig", ".netrc").
  - Add extensions to `blocked_suffixes` for additional key/cert formats.
  - Remove entries you don't need in your environment.
"""
import os
import sys
import json

try:
    data = json.load(sys.stdin)
except (json.JSONDecodeError, ValueError):
    sys.exit(0)

file_path = (data.get("tool_input") or {}).get("file_path", "")
basename = os.path.basename(file_path)

if basename.startswith(".env") and not basename.endswith(
    (".example", ".sample", ".template")
):
    print(
        f"BLOCKED: '{file_path}' is an environment file that may contain secrets.",
        file=sys.stderr,
    )
    sys.exit(2)

blocked_suffixes = (".pem", ".key", ".p12", ".pfx")
if basename.endswith(blocked_suffixes):
    print(
        f"BLOCKED: '{file_path}' appears to be a private key/certificate file.",
        file=sys.stderr,
    )
    sys.exit(2)

# Add any additional filenames you want to protect here.
blocked_names = [
    "id_rsa",
    "id_ed25519",
    "id_ecdsa",
    "credentials.json",
    "service-account.json",
]
if basename in blocked_names:
    print(
        f"BLOCKED: '{file_path}' is a protected file that may contain secrets.",
        file=sys.stderr,
    )
    sys.exit(2)

if "/.git/" in file_path or file_path.endswith("/.git"):
    print(
        f"BLOCKED: '{file_path}' is inside .git/. Do not modify git internals.",
        file=sys.stderr,
    )
    sys.exit(2)

sys.exit(0)
