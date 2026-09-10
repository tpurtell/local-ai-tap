# Releasing packages and bottles

Every formula release includes Linux ARM64 and AMD64 bottles. ARM64 builds
run natively on a DGX Spark; AMD64 builds run natively on raptor. Source-only
releases are not the default. Keep the upstream source archives available.

## Prepare and build

Publish a new upstream source release when the source changes, then update
the formula's versioned URL and SHA-256. Commit and push the formula changes.
Choose a new tap release tag, for example `bottles-YYYYMMDD-N`. Never reuse a
published asset URL. Use the same committed formula revision for both builds.

From the tap checkout on each native build host:

```sh
git pull --ff-only
scripts/build-bottles-native bottles-YYYYMMDD-N bottle-output/native-ARCH
```

Replace `ARCH` with `amd64` on raptor or `arm64` on the Spark. The script
temporarily replaces the installed packages from this tap, saves the old kegs,
uses `brew install --build-bottle`, runs tests and linkage checks, checks every
packaged ELF file against the glibc 2.39 ceiling, and writes bottle archives
and JSON metadata. Do not edit a running build script; let it finish first.

It leaves the installed tap at the build commit. Restore its tracking branch
with `git -C "$(brew --repository tpurtell/local-ai)" switch main` before the
final update/pour checks. Inspect and preserve any local changes first.

`scripts/build-bottles` is an alternative using pinned clean Homebrew Ubuntu
24.04 containers on the native host. It needs Docker and registry access;
the image downloads are large. It does not modify host Homebrew packages.

Do not pass `--bottle-arch=native` or other host-specific CPU tuning. Homebrew
selects its ARMv8/Core 2 bottle baseline. Bottles must be compatible with the
standard Linux prefix and Homebrew's glibc 2.39 baseline. Host version alone
is not an ABI test: inspect symbol requirements and test on Ubuntu 24.04.

## Stage and publish

Copy the Spark's `.bottle*` files, `tap-commit.txt`, `build-image.txt`, and
`build.log` into `bottle-output/native-arm64` on raptor. Keep the AMD64 files
in `bottle-output/native-amd64`.

```sh
scripts/prepare-bottles bottles-YYYYMMDD-N bottle-output/release \
  bottle-output/native-amd64 bottle-output/native-arm64
```

This requires a complete matching pair for every formula, verifies that the
current source formula matches the build commit, checks archive SHA-256,
renames the files to Homebrew's download names, and writes a manifest. Use
a new empty staging directory for each release. Preserve the build logs.

Create an annotated tap tag at the build commit and push it. Use a draft
GitHub release so a partial upload is not published:

```sh
gh release create bottles-YYYYMMDD-N bottle-output/release/* \
  --repo tpurtell/local-ai-tap --verify-tag --draft \
  --title 'Linux ARM64 and AMD64 bottles' --notes-file RELEASE_NOTES_FILE
```

Compare the uploaded assets and their digests with `BOTTLE-MANIFEST.json`,
then publish the complete draft with `gh release edit ... --draft=false`.
Do not use `--clobber` on published assets.

Merge both architecture records using Homebrew itself:

```sh
brew bottle --merge --write --no-commit bottle-output/release/*.bottle.json
```

This edits the **installed tap** under `$(brew --repository tpurtell/local-ai)`.
Copy its updated `Formula/*.rb` files into this development checkout, review
the diff, and run `brew style`, `brew audit --strict --online`, and
`scripts/check-bottles --download`. Commit and push the formula bottle blocks.
Preserve the `rebuild` value produced by Homebrew; subsequent rebuilds must
use a new release tag and increment the bottle rebuild number.

## Verify the actual published bottles

Update the tap and reinstall all three packages on raptor and all four Sparks:

```sh
brew update
brew reinstall --force-bottle tpurtell/local-ai/rdma-core tpurtell/local-ai/rdmapipe tpurtell/local-ai/rdmasync
scripts/check-installed-bottles
brew test tpurtell/local-ai/rdma-core tpurtell/local-ai/rdmapipe tpurtell/local-ai/rdmasync
brew linkage --test tpurtell/local-ai/rdma-core tpurtell/local-ai/rdmapipe tpurtell/local-ai/rdmasync
```

`scripts/check-installed-bottles` requires `poured_from_bottle=true` in each
installed receipt, so silent source fallback is a failure. From raptor run:

```sh
scripts/test-fabric ostrich dodo emu kiwi
```

Require passing Ubuntu 24.04 source and bottle CI jobs as well. The bottle
job uses ordinary `brew install`, verifies receipts, and tests compatibility
with an older system libc than raptor's. Record the release URLs, checksums,
build environments, and actual test results in `VALIDATION.md`.
