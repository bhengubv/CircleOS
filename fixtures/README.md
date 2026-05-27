# fixtures

Centralized corpus of static binary files for **offline validation**, per
the CircleOS v2.0 component-first standard. Anything a test or local
harness needs to verify behaviour without network goes here.

For `circleos-gsi`, this will hold (as work lands):

- Sample DSU manifest JSON
- Mock device `build.prop` fragments for Treble compliance checks
- Verified-boot test vectors (once ramdisk work begins)
- Reference GSI metadata snapshots (`update_engine_client` outputs, etc.)
- Mock Aether transport frames for `aether-protocol` integration tests

Currently empty. Drop binaries here as components land, and reference
them from CI workflows and local test scripts. Do **not** add anything
that requires a network fetch at test time.
