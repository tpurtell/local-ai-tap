# Local AI Homebrew tap

Local AI tools on Linux including DGX Spark.

Homebrew packages for Linux ARM64 (aarch64) and AMD64 (x86_64):

- `rdmapipe`: stream Unix pipes over RDMA.
- `rdmasync`: rsync-derived file synchronization with RDMA bulk transfers.
- `rdma-core`: shared RDMA libraries, hardware providers, and diagnostic tools.

Install on a Linux machine with [Homebrew](https://brew.sh/) installed:

```sh
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
brew tap tpurtell/local-ai https://github.com/tpurtell/local-ai-tap.git
# New Homebrew versions require explicit trust for third-party taps.
if brew commands | grep -qx trust; then
  brew trust --tap tpurtell/local-ai
fi
brew install tpurtell/local-ai/rdmapipe tpurtell/local-ai/rdmasync
rdmapipe --version
rdmasync --version
```

Homebrew downloads precompiled **bottles** for Linux ARM64 and AMD64 and installs
`rdma-core` and the other dependencies automatically. Use the standard Linux
Homebrew prefix, `/home/linuxbrew/.linuxbrew`. Both tools must be installed on
each transfer endpoint. Source builds remain available with `--build-from-source`.

The [published bottles](https://github.com/tpurtell/local-ai-tap/releases/tag/bottles-20260910-1)
were built natively on ostrich (ARM64 DGX Spark) and raptor (AMD64), with
Homebrew's default CPU baselines. No cross compiler is used.

To replace an existing source installation with these bottles:

```sh
brew update
brew reinstall --force-bottle tpurtell/local-ai/rdma-core tpurtell/local-ai/rdmapipe tpurtell/local-ai/rdmasync
```

This repository intentionally uses the name `local-ai-tap`. Add it with its
explicit URL, since Homebrew normally looks for a `homebrew-` repository prefix.

RDMA requires Linux kernel drivers, a configured RDMA fabric, and access to
`/dev/infiniband`. macOS is not supported by these RDMA tools.

DGX Spark systems use the NVIDIA/Ubuntu kernel RDMA drivers already installed
on the machine. The tap supplies userspace libraries and providers; it does
not install kernel modules or activate system services. Check device visibility
with `/home/linuxbrew/.linuxbrew/bin/ibv_devices`.

SSH's non-interactive PATH must also include Homebrew. Explicit paths work
without changing shell startup files:

```sh
printf 'hello\n' | rdmapipe \
  --remote-path=/home/linuxbrew/.linuxbrew/bin/rdmapipe ostrich -- cat
rdmasync -a --rdma=required \
  --rsync-path=/home/linuxbrew/.linuxbrew/bin/rdmasync ./models/ ostrich:/data/models/
```

To update later:

```sh
brew update
brew upgrade tpurtell/local-ai/rdmapipe tpurtell/local-ai/rdmasync
```

The packaged releases are [rdmapipe 0.1.0](https://github.com/tpurtell/rdmapipe/releases/tag/v0.1.0)
and [rdmasync 0.1.0](https://github.com/tpurtell/rdmasync/releases/tag/v0.1.0),
with [rdma-core 65.0](https://github.com/linux-rdma/rdma-core/releases/tag/v65.0).
The formulae use versioned archives verified with SHA-256, declare their
dependencies and licenses, and install within Homebrew's managed directories.
`rdmasync` coexists with `rsync`; its SSL helper lives under
`$(brew --prefix rdmasync)/libexec/bin/rsync-ssl` and its daemon manual is named
`rdmasyncd.conf(5)` to avoid collisions.

This is a third-party tap, not a submission to `homebrew/core`. The packaging
follows the applicable source, release, dependency, and installation practices
in [Acceptable Formulae](https://docs.brew.sh/Acceptable-Formulae) and
[Creating a Tap](https://docs.brew.sh/How-to-Create-and-Maintain-a-Tap).

Native builds, Homebrew tests, and real bidirectional RDMA transfers were
validated on raptor (AMD64) and ostrich, dodo, emu, and kiwi (ARM64 DGX Sparks).
See [VALIDATION.md](VALIDATION.md) for scope and reproduction commands.

Every release must include **both ARM64 and AMD64 bottles for every formula**.
See [RELEASING.md](RELEASING.md) for the build, publication, and verification
process. CI checks both bottle and source installs on Ubuntu 24.04, requires
both architecture entries, and downloads all six bottle assets to verify
their checksums. Native Spark checks and `scripts/test-fabric` cover ARM64 and
real RDMA hardware. Never replace published source or bottle archives.

The tap's packaging is MIT licensed. Packaged projects retain their own
licenses: MIT for rdmapipe, GPL-3.0-or-later for rdmasync, and rdma-core's
upstream dual licenses and component-specific notices.
