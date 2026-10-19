# Private caches from PHP Builder

This repository consumes signed private PHP Builder packages from the existing
`php-darwin-private` R2 bucket and stages tested Ubuntu caches in that bucket.
Bucket provisioning happens outside CI and public access stays disabled.

1. Upload `php-X.Y.Z.tar.xz` or `.tar.gz` under the shared `uploads/` directory.
2. Run **Stage private PHP Builder** in `shivammathur/php-builder` on `main`.
   Wait for its signed approval in `php-builder/uploads/RUN_ID-ATTEMPT/ready.json`.
3. Run **Stage private PHP Ubuntu** (`stage-private.yml`) on `main`, supplying
   `php-version`, `builder-build-id`, and supported Ubuntu `containers`.
4. After the announcement, run **Release PHP Ubuntu from private R2** with
   `php-version`, this repository's `build-id`, the exact `release-version`, and
   official `source-sha256` for the staged source compression format.

Ubuntu verifies Builder's signature and complete test evidence. The selected
Ubuntu platforms must all have been built and tested upstream. It records the
upstream approval hash and installs its exact NTS/ZTS, release/debug-symbol
archive and tested installer through authenticated R2. It never falls back to
public Builder packages. The existing dependency cleanup, filesystem snapshot,
dpkg-status merging and cache packaging paths remain in use.

The Ubuntu build ID is its own `RUN_ID-ATTEMPT`, independent of Builder's ID.
Objects live under `php-ubuntu/builds/BUILD_ID/`: `plan.json`, `inputs/`,
`packages/`, `results/`, `logs/`, signed `ready.json`, and archived `workflow.json`.
Both minor and full-version cache names are retained and must have identical
bytes. Each selected variant is installed on its matching Ubuntu hosted runner;
runtime, ZTS, FPM, optional extensions and broken-package checks must pass before
approval. Tests disable package repair so a broken cache cannot silently pass.

Promotion verifies the signature, source/version inputs, every package hash and
the exact publicly announced php.net source. It calls the normal publisher for
GitHub Releases and the existing public mirrors without compiling PHP. The tested
installer is published with the caches. Production requires staging from `main`
in both repositories; branch staging is available for development only. A changed
candidate requires new Builder and Ubuntu builds. Public publishing is serialized
with normal workflows and rejects downgrades from older queued caches.

There are no Actions artifacts in private staging. Build/test output and step
summaries are captured into private R2 logs. Child environment/path/state/output
files also stay private; only the plan publishes validated job matrices.
GitHub still exposes run existence, names, timing,
status and dispatch inputs until deletion; inputs must not contain credentials.
Use disposable runners. Forced termination or a bootstrap/storage failure may
prevent log preservation or local cleanup. Downloaded inputs and captured logs
are removed after the log transfer succeeds. Packaging and installation also use
`/tmp` and system paths; the disposable container/runner must be destroyed at job
completion.

After merging to the default branch, `cleanup-private.yml` preserves completed
staging run/job metadata in R2 and deletes the GitHub run automatically. Its
manual `build-id` input retries cleanup. R2 data is retained, so neither Builder
nor Ubuntu GitHub runs need to remain present for the handoff or promotion.
Retry with **Re-run all jobs** before deletion, or a new run after deletion.

Required secrets:

- `PRIVATE_R2_ENDPOINT`, `PRIVATE_R2_ACCESS_KEY_ID`, `PRIVATE_R2_SECRET_ACCESS_KEY`:
  credentials scoped to the existing private bucket.
- `PHP_BUILDER_PRIVATE_SIGNING_KEY`: Builder's approval verification key.
- `PRIVATE_RELEASE_SIGNING_KEY`: a distinct Ubuntu approval key, 64 lowercase hex
  characters representing 32 random bytes.
- Existing public publishing and mirror secrets, used only during promotion.

The shared Python protocol files must remain compatible with PHP Builder. Validate
with `python3 -m unittest discover -s tests/private -v` and `actionlint`.

## Branch trial before integration

For a development trial, set the repository Actions variable
`PRIVATE_TEST_PHP_VERSION` to the minor and push a commit containing
`[private-stage]` to `feature/private-r2-releases`. Ordinary pushes do not stage
private sources. Source archives are selected from authenticated R2; never put
private source contents, candidate filenames or hashes in the commit. Ubuntu
also needs `PRIVATE_TEST_BUILDER_BUILD_ID` set to the signed Builder run-attempt.
The full configured matrix is used. All intermediate handoffs use private R2,
including SAPI archives, final packages, and the Builder-to-Ubuntu handoff.
No GitHub Actions artifacts or Actions caches are used by private staging.

Until the cleanup workflow is on the default branch, archive and delete completed
trial runs with the repository's private cleanup script from a trusted local
checkout. Verify R2 evidence before deleting the run. Branch trial approvals are
for validation only and remain ineligible for production promotion.
