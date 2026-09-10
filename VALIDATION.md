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
