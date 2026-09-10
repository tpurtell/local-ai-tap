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

Homebrew installs `rdma-core` and the other dependencies automatically. These
formulae build from source on the machine's native architecture. No cross
compiler is used. Both tools must be installed on each transfer endpoint.

This repository intentionally uses the name `local-ai-tap`. Add it with its
explicit URL, since Homebrew normally looks for a `homebrew-` repository prefix:

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

For new releases, publish a new upstream tag and source archive, update its
formula URL and SHA-256, and run `brew style`, `brew audit --strict --online`,
`brew install --build-from-source`, `brew test`, and `brew linkage --test`.
Run ARM64 builds natively on a Spark and `scripts/test-fabric` from raptor.
GitHub Actions supplies an additional AMD64 build/test check without RDMA
hardware. Never replace a published release archive; publish a new version.

The tap's packaging is MIT licensed. Packaged projects retain their own
licenses: MIT for rdmapipe, GPL-3.0-or-later for rdmasync, and rdma-core's
upstream dual licenses and component-specific notices.
