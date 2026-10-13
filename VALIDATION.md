# Release validation — 2026-09-10

## Published binary bottles

[Bottle release](https://github.com/tpurtell/local-ai-tap/releases/tag/bottles-20260910-1)
contains six archives: ARM64 and AMD64 builds of rdma-core 65.0, rdmapipe
0.1.0, and rdmasync 0.1.0. The release also includes each Homebrew bottle JSON
and a [manifest](https://github.com/tpurtell/local-ai-tap/releases/download/bottles-20260910-1/BOTTLE-MANIFEST.json)
with exact SHA-256 values, source commit, and build environment.

- Built natively with `brew install --build-bottle` on ostrich and raptor,
  using Homebrew's ARMv8 and Core 2 CPU baselines. No cross compilation.
- All 73 packaged ELF files on each architecture require glibc symbols no
  newer than 2.38, below Homebrew's 2.39 baseline. The native build hosts use
  glibc 2.39 (ostrich) and 2.43 (raptor); the manifest preserves this distinction.
- Every anonymous public bottle download matched its declared SHA-256.
- All three installed receipts on **raptor, ostrich, dodo, emu, and kiwi**
  report `poured_from_bottle=true` after reinstalling from the public release.
- All three Homebrew tests and linkage checks passed on all five hosts after
  pouring. Homebrew's `ibv_devices` discovered the expected hardware.
- `scripts/test-fabric ostrich dodo emu kiwi` passed using the poured packages:
  both tools, both transfer directions, every raptor/Spark pair, with random
  16 MiB payloads and SHA-256/exact byte comparisons. rdmasync used
  `--rdma=required` to exclude TCP fallback.
- The [Ubuntu 24.04 bottle CI job](https://github.com/tpurtell/local-ai-tap/actions/runs/34447015267)
  passed an ordinary fresh `brew install`, receipt verification, package
  tests, linkage checks, and the ABI check. This additionally verifies the
  AMD64 artifacts against an older libc than their build host.
  The separate source-install CI job also passed, verifying the fallback path.

`rdma-core` bottles use the standard `/home/linuxbrew/.linuxbrew/Cellar`.
Homebrew marks the two tool bottles relocatable, but their rdma-core dependency
means the complete installation should use the standard Linux prefix.
The bottle archives contain each project's applicable license files.

## Initial source release verification

All three formulae were built from their published source archives. ARM64
builds ran natively on DGX Sparks; AMD64 builds ran natively on raptor.
`file -L` confirmed aarch64 and x86-64 executables. No cross compilation.

| Host | Architecture | Source builds | Homebrew tests | Linkage checks |
| --- | --- | --- | --- | --- |
| raptor | AMD64 | All three passed | All three passed | All three passed |
| ostrich | ARM64 | All three passed | All three passed | All three passed |
| dodo | ARM64 | All three passed | All three passed | All three passed |
| emu | ARM64 | All three passed | All three passed | All three passed |
| kiwi | ARM64 | All three passed | All three passed | All three passed |

Versions: rdmapipe 0.1.0, rdmasync 0.1.0, rdma-core 65.0.

`brew style` and `brew audit --strict --online` passed for all three formulae.
The [GitHub AMD64 build/test run](https://github.com/tpurtell/local-ai-tap/actions/runs/34444465480)
also passed for these formula revisions.
`rdmasync --version` advertises RDMA-bulk, ACLs, xattrs, OpenSSL, xxHash, zstd,
LZ4, and zlib. Linkage resolves libibverbs and compression/checksum libraries
to Homebrew dependencies. Homebrew's rdma-core `ibv_devices` discovers the
Mellanox adapters on all five hosts.

## Upstream suites

- rdmapipe protocol and command tests passed on raptor and ostrich, and
  `make check` also runs during each formula installation.
- rdmasync's complete default suite: raptor 110 passed / 5 skipped;
  ostrich 107 passed / 8 skipped; zero failures.
- Both suites skip creation-time support and three tests requiring the
  separate TCP-daemon harness, plus a privilege-dependent protected-file test.
  Ostrich additionally skips chown, device-node creation, and the x86 SIMD test.

## Actual fabric transfers

`scripts/test-fabric` passed for each of raptor ↔ ostrich, raptor ↔ dodo,
raptor ↔ emu, and raptor ↔ kiwi:

- rdmapipe transferred a random 16 MiB stream in both directions using two
  active RDMA channels, with SHA-256 or exact byte comparison.
- rdmasync pushed and pulled the same payload with `--rdma=required`, with
  SHA-256 or exact byte comparison. Required mode prevents TCP fallback.

These are functional integrity checks, not throughput benchmarks. The script
uses unique temporary directories and removes its fixtures after each run.

Reproduce with the packages installed and passwordless SSH configured:

```sh
brew test tpurtell/local-ai/rdma-core tpurtell/local-ai/rdmapipe tpurtell/local-ai/rdmasync
brew linkage --test tpurtell/local-ai/rdma-core tpurtell/local-ai/rdmapipe tpurtell/local-ai/rdmasync
./scripts/test-fabric ostrich dodo emu kiwi
```

## Published archive integrity

Anonymous HTTPS downloads were hashed and matched the formula checksums:

```text
rdmapipe-0.1.0.tar.gz
29fe87ded0d9dfb1d86441a6770d975c276ef5ab42c0e54cbce06a317e972171
rdmasync-0.1.0.tar.gz
66a81c505a844e8dbcab9162f97c365a969ebc0986d098bdd37316c6eb8b0d0d
rdma-core v65.0.tar.gz
714881af1c875f335aee55e94e770894963af3b9bbb6c1248e4a279058dcba58
```

The two tool repositories have annotated `v0.1.0` tags and public GitHub
releases. rdmasync's release includes generated configure files and manual
pages; package installation does not fetch moving generated upstream files.

## sparknest 0.1.0 (bottles-20260928-2)

Source: <https://github.com/tpurtell/sparknest/releases/tag/v0.1.0>, archive
`sparknest-0.1.0.tar.gz` SHA-256
`ce7d16e98c8b1663859782933826c76735158429b4fab007ce187acee37a7e5e`
(downloaded anonymously and matched).

Bottles, built with `scripts/build-bottles-native bottles-20260928-2 DIR
sparknest` from tap commit 26bcc19 (only sparknest; other formulae keep their
bottles):

```text
sparknest-0.1.0.arm64_linux.bottle.1.tar.gz   rhea (DGX Spark, aarch64)
e1d012f3b702c405c9781d052e2beb9e90400ca8eb501e096b72127faa6f3bf3
sparknest-0.1.0.x86_64_linux.bottle.1.tar.gz  raptor (x86_64)
36f39bf0c9ab48f1dcac8799bab293743dd169d3abb6f0fbf3b3b75e130c649a
```

Both builds passed `brew test` (a one-node cluster over TCP: import, offload
to an archive store, metadata backup, offline export), `brew linkage --test`
and the glibc 2.39 ceiling check. The pinned Homebrew containers could not be
used: their image downloads from ghcr.io kept resetting. ARM64 was built on
rhea because ostrich, dodo, emu and kiwi were running benchmarks. Uploaded
assets matched the manifest digests; `scripts/check-bottles --download`
passed for every formula after the bottle block was merged.

Installed from the published bottles on raptor, ostrich, dodo, emu, kiwi, rhea
and moa (`brew install --force-bottle`): `poured_from_bottle=true` and
`brew linkage --test` passed on all seven. moa's first download failed
(GitHub CDN) and succeeded on retry. The running daemons were not restarted.

## sparknest 0.2.0 (bottles-20261001-1)

Source: <https://github.com/tpurtell/sparknest/releases/tag/v0.2.0>, archive
SHA-256 `9998daf31c1ae18c228d7cb4f47bb63c9cbaf132281248b3db10010050776338`
(downloaded anonymously and matched).

```text
sparknest-0.2.0.arm64_linux.bottle.tar.gz   rhea (DGX Spark, aarch64; nice 19, 4 cores, beside GPU jobs)
b3b2054dbc040ab52223254887fec1612d2e71d9bb49e18d6c49155e496d9c1a
sparknest-0.2.0.x86_64_linux.bottle.tar.gz  raptor (x86_64)
1f57ce65789447730a2848936dd811335cdf5b0938bb45ac4e9a5daca5741a2d
```

Built with `scripts/build-bottles-native bottles-20261001-1 DIR sparknest`
from tap commit 299d40f; both passed `brew test`, `brew linkage --test` and
the glibc 2.39 check. Uploaded assets matched the manifest digests. CI on the
bottle commit d32fc63 passed (Ubuntu 24.04: source build, bottle install);
the 0.2.0 formula commit failed the bottle check until its bottles existed,
as expected. Installed from the published bottles on all seven hosts:
`poured_from_bottle=true`, linkage passed, `libexec/sparknest/sparknest-hf-fetch`
present. Daemons keep running 0.1.0 until their next restart.

## sparknest 0.2.1 (bottles-20261003-1)

Source: <https://github.com/tpurtell/sparknest/releases/tag/v0.2.1>, archive
SHA-256 `e9abaf157a3a7c8a0ccef96dca97f83a22bde6de425638f9e9b4567cdd636188` (downloaded anonymously and matched).

```text
sparknest-0.2.1.arm64_linux.bottle.tar.gz   rhea (DGX Spark, aarch64; nice 19, 4 cores, beside GPU jobs)
a301afd517743067798012f27e360d236e2587c427e1e473884239aec20c77c6
sparknest-0.2.1.x86_64_linux.bottle.tar.gz  raptor (x86_64)
1736b229d6e2bcd80ed288a647798d4d10fa47c7614b3308d5688ae917d83e4a
```

Built from tap commit 9631680 with `scripts/build-bottles-native`
(sparknest only); both passed `brew test`, `brew linkage --test` and the
glibc 2.39 check. Uploaded assets matched the manifest digests. CI on the
bottle commit d1466ff passed (Ubuntu 24.04: source build, bottle install).
Installed from the published bottles on all seven hosts:
`poured_from_bottle=true`, linkage passed, driver present. Daemons keep
running 0.2.0 until their next restart.

## sparknest 0.2.2 (bottles-20261011-1)

Source: <https://github.com/tpurtell/sparknest/releases/tag/v0.2.2>, archive
SHA-256 `29042783830128463409101c1ac0dd300e677bfd00481d3910b7cc5c99413d27`
(downloaded anonymously and matched).

```text
sparknest-0.2.2.arm64_linux.bottle.tar.gz   rhea (DGX Spark, aarch64; nice 19, 4 cores)
3096a6e4f3e53c2253bd50cf84afa599e6a8e3d34a38f8be10e8fe815b9aac36
sparknest-0.2.2.x86_64_linux.bottle.tar.gz  raptor (x86_64)
4718f7e06449ae9f659f0ef7ec52621a65e851e24d4adedbfb4e01c8a190d98a
```

Built with `scripts/build-bottles-native bottles-20261011-1 DIR sparknest`
from tap commit 631c491; both passed `brew test`, `brew linkage --test` and
the glibc 2.39 check. The first rhea build failed with "Text file busy": the
daemon was restarted mid-build and ran from the build keg; the rerun passed.
The first raptor build gave up on a brew download lock after fetching rust
and llvm; the rerun passed. Uploaded assets matched the manifest digests and
`scripts/check-bottles --download` passed. CI on the bottle commit c22901b
passed (Ubuntu 24.04: source build, bottle install); the formula-only commit
631c491 failed the bottle check until its bottles existed, as expected.

Installed from the published bottles on all seven hosts:
`poured_from_bottle=true`, linkage passed. ostrich, kiwi and moa stalled
downloading from GitHub; the bottle was copied from rheas cache into theirs

## sparknest 0.2.2 (bottles-20261011-1)

Source: <https://github.com/tpurtell/sparknest/releases/tag/v0.2.2>, archive
SHA-256 `29042783830128463409101c1ac0dd300e677bfd00481d3910b7cc5c99413d27`
(downloaded anonymously and matched).

```text
sparknest-0.2.2.arm64_linux.bottle.tar.gz   rhea (DGX Spark, aarch64; nice 19, 4 cores)
3096a6e4f3e53c2253bd50cf84afa599e6a8e3d34a38f8be10e8fe815b9aac36
sparknest-0.2.2.x86_64_linux.bottle.tar.gz  raptor (x86_64)
4718f7e06449ae9f659f0ef7ec52621a65e851e24d4adedbfb4e01c8a190d98a
```

Built with `scripts/build-bottles-native bottles-20261011-1 DIR sparknest`
from tap commit 631c491; both passed `brew test`, `brew linkage --test` and
the glibc 2.39 check. The first rhea build failed with "Text file busy": the
daemon was restarted mid-build and ran from the build keg; the rerun passed.
The first raptor build gave up on a brew download lock after fetching rust
and llvm; the rerun passed. Uploaded assets matched the manifest digests and
`scripts/check-bottles --download` passed. CI on the bottle commit c22901b
passed (Ubuntu 24.04: source build, bottle install); the formula-only commit
631c491 failed the bottle check until its bottles existed, as expected.

Installed from the published bottles on all seven hosts:
`poured_from_bottle=true`, linkage passed. ostrich, kiwi and moa stalled
downloading from GitHub; the bottle was copied from rhea's cache into theirs
(SHA-256 matched) and poured from there. All seven daemons restarted onto
0.2.2 (7/7 serving after each). RDMA QPs per host fell from 46k-136k on the
Sparks (0.2.1, a week up) to 5-15.

## sparknest 0.3.0 (bottles-20261012-1)

Source: <https://github.com/tpurtell/sparknest/releases/tag/v0.3.0>, archive
SHA-256 `95cd0f8c9a4ea891fc7e06341fca105971036e4a50762eca29b981c70ec1b208`
(downloaded anonymously and matched).

```text
sparknest-0.3.0.arm64_linux.bottle.tar.gz   rhea (DGX Spark, aarch64; nice 19, 4 cores)
fb093e961ed25ac7a1fcae8baf430782d2384ad9a48443ae71ff52844a219fab
sparknest-0.3.0.x86_64_linux.bottle.tar.gz  raptor (x86_64; nice 10)
9d6898ef00959e57e3fa20b5859af930a2299f74966668573bd86c85f9b46685
```

Built with `scripts/build-bottles-native bottles-20261012-1 DIR sparknest`
from tap commit c3b86b9; both passed `brew test`, `brew linkage --test` and
the glibc 2.39 check. The first attempt on both hosts failed downloading
the new rust 1.99.0_1 and llvm 23.1.3_1 bottles from ghcr; after `brew
fetch llvm` on rhea the reruns passed. Uploaded assets matched the
manifest digests. CI on the bottle commit 0e16fb5 passed (Ubuntu 24.04:
source build, bottle install).

Installed from the published bottles on all nine hosts (the seven fabric
hosts, and the new off-grid hosts kakapo and oliver): `poured_from_bottle=true`,
linkage passed. The bottles were fetched once on raptor and copied into
each host's Homebrew cache (GitHub downloads stalled on some Sparks before).
kakapo and oliver run Homebrew 7.0.9, which refused the untrusted
dependency `rdma-core` until `brew trust --formula
tpurtell/local-ai/rdma-core`. Running daemons stay on 0.2.2 until restarted.

## gpu-powerd 0.1.0 (bottles-20261013-1)

Source: <https://github.com/tpurtell/gpu-powerd/releases/tag/v0.1.0>, archive
`v0.1.0.tar.gz` SHA-256
`279542c6d7d862ce90709ec676affce18e195efa926b4133d68f9f05c2fa262e`
(downloaded anonymously and matched). First tap release.

```text
gpu-powerd-0.1.0.arm64_linux.bottle.tar.gz   kakapo (DGX Spark build host, aarch64)
8ac81ce58a48652f64f9475f2736edabae96c1a214ab5abed6bba0675d0fe0fc
gpu-powerd-0.1.0.x86_64_linux.bottle.tar.gz  raptor (x86_64; nice 10)
e054d74ed5efa76f89a227c7d51040dfd4f71b4c82200116f2461c1dade5c2d2
```

Built with `scripts/build-bottles-native bottles-20261013-1 DIR gpu-powerd`
from tap commit e8aa3c5; both passed `brew test`, `brew linkage --test` and
the glibc 2.39 check (maximum GLIBC_2.34). The root bundle's `gpu-powerd`
and `gpu-powerd-ws` use the system loader with no RPATH/RUNPATH, and
`gpu-powerd-setup --check` reported the bundle verified on both
architectures. The first ARM64 attempt (ostrich) was moved to kakapo, the
build host that never serves; on both, GHCR stalled on the rust and llvm
bottles, and `brew install` exited nonzero after pouring from a cache seeded
with copies from rhea and ostrich that matched the manifest digests, so the
script stopped before `brew test`. The rerun on kakapo with a complete cache
passed. Uploaded assets matched the manifest digests and
`scripts/check-bottles --download` passed for every formula. CI on the
bottle commit 19e7e86 passed ([run](https://github.com/tpurtell/local-ai-tap/actions/runs/38352402494),
Ubuntu 24.04: source build, bottle install). The formula-only commit e8aa3c5 failed CI's bottle check until its bottles
existed, as expected.

Installed from the published bottles with `brew install
tpurtell/local-ai/gpu-powerd` on raptor and kakapo: `poured_from_bottle=true`,
`brew linkage --test` and `brew test` passed. `gpu-powerd --check` on raptor
read both RTX PRO 6000 cards read-only (default config, PI controller, 600 W
plan). The kakapo install was removed afterwards; Sparks don't run the daemon.
`gpu-powerd-setup` (the root daemon install) was not run: that is the
operator's step on raptor.

## gpu-powerd-webui 0.1.0 (bottles-20261013-webui-1)

Source: https://github.com/tpurtell/gpu-powerd-webui/releases/tag/v0.1.0.
The archive contains one clean initial commit, MIT license, examples,
server/browser regression tests, static assets, and a systemd installer. Personal
host configuration, history, logs, sockets, and browser artifacts are excluded.
Source SHA-256: `7a20efbeb9e14f120c03f479c5770b9ebba7047b46467ef7f4148709cd30283c`.

Native builds from tap commit `eebab47`:

```text
raptor x86_64_linux b49e8fdc7fd57ea2c2e72494bef155e876aa1179bef8aba0402fe52491bd6605
rhea   arm64_linux  61150ce2b1109f08515386a6a36b506cc3d9b4e0db28b11c6f7b0955cdcfa97f
```

Both passed `brew test`, `brew linkage --test`, and the package ABI check. The
payload is Python/shell/static files and contains no ELF files or compiled CPU
requirements. ARM64 packaging used the shared fair queue's rhea lock. AMD64
packaging used a raptor CPU lock in that queue, with nice 10; it only copies scripts
and tests configuration and never accesses GPU hardware. Full build logs and
manifest are in `bottle-output/gpu-powerd-webui-20261013`.

Both architectures were reinstalled from the actual published bottles:
`poured_from_bottle=true`, Homebrew tests and linkage passed. Uploaded GitHub
asset digests matched the manifest, and both published bottle downloads matched
SHA-256. `brew style` and `brew audit --strict --online` passed. `scripts/test-fabric`
passed against ostrich, dodo, emu, and kiwi, both tools and both directions.

The web UI repository's GitHub CI passed on Python 3.10, 3.12, and 3.14 and ran
its browser regression suite. Browser checks covered 320/390/768/1280 px widths,
independent filters after hiding the two-GPU host, all-hidden recovery, legend
highlighting/statistics, request races, repeated suspension/resume, and history
pruning. An integration check consumed the real daemon stream, stored samples in
SQLite, and checked HTTP history and SSE. Legacy daemon versions without VRAM
fields show unavailable memory; new `mem_used_mib`/`mem_total_mib` fields are accepted.

Installed the poured package on raptor with `gpu-powerd-webui-setup --user tj`
through agent-sudo. The unprivileged system service is enabled at boot and serves
port 13456 using root-owned application files, config in `/etc/gpu-powerd-webui`,
and history in `/var/lib/gpu-powerd-webui`. Existing history was migrated; all
eight hosts and nine GPUs collected successfully. A browser check against the
installed service passed mobile layout, filters, and legend highlighting. Old
runtime state was archived outside the source checkout. gpu-powerd was not changed.

The initial tap CI at `8cc885e` verified both web UI bottle downloads, then stopped
because the concurrently released gpu-powerd 0.1.3 lacked an ARM64 bottle entry.
That separate formula was subsequently completed at `2f07605`. Both Ubuntu 24.04
source and bottle jobs then passed in [run 38358706730](https://github.com/tpurtell/local-ai-tap/actions/runs/38358706730).
The web UI also passed twelve real SSE disconnect/resume cycles against its
installed service, with exactly one stream per visible tab; the server returned
to three threads and its memory settled around 60 MiB after those checks.

## gpu-powerd 0.1.3 (bottles-20261013-3)

Source: <https://github.com/tpurtell/gpu-powerd/releases/tag/v0.1.3>, archive
SHA-256 `5f71adff9a34baf4eb9c55890f3b5707077bc9efd1f1754a1467dee1d11682ad`
(downloaded anonymously and matched). 0.1.1 shipped as `bottles-20261013-2`
(lock moved to root-owned `/run/gpu-powerd/daemon.lock`); 0.1.3 adds VRAM
fields to the samples, with the per-process read off by default. 0.1.2 was
skipped.

```text
gpu-powerd-0.1.3.arm64_linux.bottle.tar.gz   kakapo (DGX Spark build host, aarch64)
4d86e936b0baa193f10c7b4f74e53ac3d69e6837d486ec41de3dc4a05c0a6792
gpu-powerd-0.1.3.x86_64_linux.bottle.tar.gz  raptor (x86_64; nice 10)
70ea494ebf3a2b3653cf92e78c67547afdb62897280f319754c357eeaf61f769
```

Built with `scripts/build-bottles-native bottles-20261013-3 DIR gpu-powerd`
from tap commit 2d9755e; both passed `brew test`, `brew linkage --test` and
the glibc 2.39 check (maximum GLIBC_2.34). A first raptor build took bottle
rebuild 1 because the tap's `origin/HEAD` already pointed at the 0.1.1
formula; it was discarded and rebuilt with `origin/HEAD` at the previous
release commit, giving rebuild 0 on both. Uploaded assets matched the
manifest digests. Installed from the published bottles on raptor and kakapo:
`poured_from_bottle=true`, `brew test` and linkage passed; the kakapo copy
was removed afterwards.

## gpu-powerd-webui 0.1.1 (bottles-20261013-webui-2)

Source: https://github.com/tpurtell/gpu-powerd-webui/releases/tag/v0.1.1,
commit `377af85`, SHA-256
`f32598db8673e5e7a39a6819c131a047d814bf14a401eb833eb9e27dc005c679`.
Focused framebuffer GPUs in the Power chart show their recorded power limit
as a dashed step line. Limits come from the daemon's measured `reading.limit_w`
or `power.limit` in the existing SSH/local query. No extra collection command
or GPU setting changes. Unified-memory hosts and unsupported values have no
limit overlay. Limit history begins at upgrade; existing samples retain null
limits. Buckets keep the latest recorded setting rather than averaging limits.

Native bottles from tap commit `2598c4f`:

```text
raptor x86_64_linux aed83283bcd1e6ae2f2c4e49b549c299ea51d3c8032a8d258951d0c54579d1c4
kakapo arm64_linux  5a3d93b0b61d91a71543cef4d1459813e4188da37ebed7dca71458fc154714a6
```

Used the shared fair queue's kakapo lock for ARM64 and its raptor CPU lock
with nice 10 for Python/static AMD64 packaging. Both native builds passed
Homebrew tests, linkage, and the Python/static ABI check. Both were reinstalled
from their actual published bottles; receipts report `poured_from_bottle=true`.
All uploaded asset digests matched the staged manifest before publication.
`brew style` and `brew audit --strict --online` passed. Fleet transfer checks
passed for ostrich, dodo, emu, and kiwi, both directions and both tools.

Ten server regressions passed, covering measured/unsupported limits, exclusion
of unified hosts, schema upgrades preserving history, raw limit series and
latest-setting buckets. Browser regressions verify dashed step geometry, axis
bounds, focus/metric/Spark conditions, tooltips, live limit updates, independent
draw statistics, and history pruning, plus the existing mobile/lifecycle suite.
Web UI GitHub CI passed on Python 3.10, 3.12, and 3.14 and in Chrome:
https://github.com/tpurtell/gpu-powerd-webui/actions/runs/38395388464.
Integration checks used real daemon and SSH readings and upgraded a consistent
copy of the running database without altering its existing samples.

Applied the poured package to raptor's system service through agent-sudo, keeping
port 13456, its nine-host config (including kakapo), and SQLite history. A private
history/config backup was saved before upgrade. All nine hosts and ten GPUs
collected successfully: raptor reported 450 W per GPU, the WSL GPU 300 W, and
Sparks null. A live mobile browser verified both framebuffer overlays and their
absence for kakapo. The service runs v0.1.1 and remains enabled at boot.

Both tap Ubuntu 24.04 source and bottle CI jobs passed at `7f7e6df`, including
full tap bottle downloads/checksums, source/bottle installs, tests and ABI checks:
https://github.com/tpurtell/local-ai-tap/actions/runs/38395834710.
