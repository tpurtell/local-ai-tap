class Rdmasync < Formula
  desc "Rsync-compatible file synchronization with RDMA bulk transfers"
  homepage "https://github.com/tpurtell/rdmasync"
  url "https://github.com/tpurtell/rdmasync/releases/download/v0.1.0/rdmasync-0.1.0.tar.gz"
  sha256 "66a81c505a844e8dbcab9162f97c365a969ebc0986d098bdd37316c6eb8b0d0d"
  license "GPL-3.0-or-later"

  bottle do
    root_url "https://github.com/tpurtell/local-ai-tap/releases/download/bottles-20260910-1"
    rebuild 1
    sha256 cellar: :any, arm64_linux:  "923f6c4f6abc139e46a0fa336dac732d99d255e31030bbe0a5889178bd571873"
    sha256 cellar: :any, x86_64_linux: "8a8cd376a1548c47d7b57ae8b2e6d8254dc7e02445d75700e2f0294866dd69c8"
  end

  depends_on "acl"
  depends_on :linux
  depends_on "lz4"
  depends_on "openssl@3"
  depends_on "popt"
  depends_on "tpurtell/local-ai/rdma-core"
  depends_on "xxhash"
  depends_on "zlib"
  depends_on "zstd"

  def install
    system "./configure", *std_configure_args,
           "--enable-rdma",
           "--enable-acl-support",
           "--enable-xattr-support",
           "--with-included-popt=no",
           "--with-included-zlib=no",
           "--disable-md2man"
    system "make"
    # Keep the fork's helpers and daemon manual from colliding with rsync.
    bin.install "rdmasync"
    man1.install "rsync.1" => "rdmasync.1"
    man5.install "rsyncd.conf.5" => "rdmasyncd.conf.5"
    (libexec/"bin").install "rsync-ssl"
    (libexec/"share/man/man1").install "rsync-ssl.1"
    doc.install "README.md", "INSTALL.md", "ADDING-RDMA.md", "RELEASE.md"
  end

  test do
    assert_match "rdmasync  version #{version}", shell_output("#{bin}/rdmasync --version")
    assert_match "RDMA-bulk", shell_output("#{bin}/rdmasync --version")
    assert_match "--rdma", shell_output("#{bin}/rdmasync --help")
    (testpath/"source/file").write("RDMA sync test\n" * 1024)
    system bin/"rdmasync", "-a", "source/", "destination/"
    assert_equal (testpath/"source/file").read, (testpath/"destination/file").read
    (testpath/"source/file").unlink
    (testpath/"source/file").write("updated\n")
    system bin/"rdmasync", "-ac", "--delete", "source/", "destination/"
    assert_equal "updated\n", (testpath/"destination/file").read
  end
end
