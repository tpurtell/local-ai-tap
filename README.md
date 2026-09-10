# Local AI Homebrew tap

Homebrew packages for Linux ARM64 (aarch64) and AMD64 (x86_64):

- `rdmapipe`: stream Unix pipes over RDMA.
- `rdmasync`: rsync-derived file synchronization with RDMA bulk transfers.
- `rdma-core`: shared RDMA libraries, hardware providers, and diagnostic tools.

Packaging and native-machine validation are in progress. Release installation
instructions and validation results will be published here when ready.

This repository intentionally uses the name `local-ai-tap`. Add it with its
explicit URL, since Homebrew normally looks for a `homebrew-` repository prefix:

```sh
brew tap tpurtell/local-ai https://github.com/tpurtell/local-ai-tap.git
```

RDMA requires Linux kernel drivers, a configured RDMA fabric, and access to
`/dev/infiniband`. macOS is not supported by these RDMA tools.
