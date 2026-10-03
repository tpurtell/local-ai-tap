class Sparknest < Formula
  desc "RDMA distributed filesystem with explicit placement, built for model caches"
  homepage "https://github.com/tpurtell/sparknest"
  url "https://github.com/tpurtell/sparknest/releases/download/v0.2.1/sparknest-0.2.1.tar.gz"
  sha256 "e9abaf157a3a7c8a0ccef96dca97f83a22bde6de425638f9e9b4567cdd636188"
  license any_of: ["MIT", "Apache-2.0"]

  bottle do
    root_url "https://github.com/tpurtell/local-ai-tap/releases/download/bottles-20261003-1"
    sha256 cellar: :any, arm64_linux:  "a301afd517743067798012f27e360d236e2587c427e1e473884239aec20c77c6"
    sha256 cellar: :any, x86_64_linux: "1736b229d6e2bcd80ed288a647798d4d10fa47c7614b3308d5688ae917d83e4a"
  end

  depends_on "rust" => :build
  depends_on :linux
  depends_on "tpurtell/local-ai/rdma-core"

  conflicts_with "nest", because: "both install a `nest` executable"

  def install
    # One target directory so the daemon and the CLI share compiled crates.
    ENV["CARGO_TARGET_DIR"] = buildpath/"target"
    system "cargo", "install", *std_cargo_args(path: "crates/sparknestd")
    system "cargo", "install", *std_cargo_args(path: "crates/nest-cli")
    pkgshare.install "packaging/config", "packaging/systemd"
    # Benchmark helper: the wrapper installs the setuid binary itself (with
    # sudo, once per host; Homebrew cannot install setuid root files).
    bin.install "tools/drop-page-cache/sparknest-drop-page-cache"
    (libexec/"sparknest").install "tools/drop-page-cache/drop-page-cache.c"
    # Installs a sudoers rule for exactly `systemctl restart sparknestd@CLUSTER`.
    bin.install "tools/allow-restart/sparknest-allow-restart"
    # Hugging Face downloads: sparknestd runs it with the `hf` command's Python.
    (libexec/"sparknest").install "tools/hf-fetch/sparknest-hf-fetch"
    inreplace pkgshare.glob("systemd/*.service"), "@BIN_DIR@", opt_bin
    doc.install "README.md", "docs/INSTALL.md"
  end

  def caveats
    <<~EOS
      Mounting needs the system FUSE 3 package (fusermount3), e.g.
        sudo apt install fuse3
      For cold-cache benchmarks (`nest drop-caches`), once on each host:
        sparknest-drop-page-cache --install
      To restart the daemon without a password (e.g. from an agent), once on each host:
        sparknest-allow-restart
      Cluster setup, configuration and service units:
        #{doc}/INSTALL.md
        #{pkgshare}
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/nest --version")
    assert_match version.to_s, shell_output("#{bin}/sparknestd --version")
    assert_match "Usage: sparknest-drop-page-cache", shell_output("#{bin}/sparknest-drop-page-cache --help")
    assert_match "restart sparknestd@", shell_output("#{bin}/sparknest-allow-restart --help")
    assert_path_exists libexec/"sparknest/sparknest-hf-fetch"

    # A one-node cluster over TCP without a mount: import, offload to an
    # archive store, snapshot the metadata, then rebuild the tree offline.
    port = free_port
    (testpath/"state").mkpath
    (testpath/"archive").mkpath
    (testpath/"secret").write("0123456789abcdef0123456789abcdef")
    (testpath/"node.toml").write <<~TOML
      [node]
      id = 1
      name = "solo"
      state_dir = "#{testpath}/state"
      listen = "127.0.0.1:#{port}"

      [cluster]
      name = "test"
      secret_file = "#{testpath}/secret"
      members = [{ id = 1, name = "solo", addr = "127.0.0.1:#{port}" }]

      [fabric]
      mode = "tcp"
    TOML
    system bin/"sparknestd", "--config", testpath/"node.toml", "--check"
    (testpath/"src/models/demo").mkpath
    (testpath/"src/models/demo/config.json").write "hello sparknest\n"

    sock = testpath/"state/api.sock"
    pid = spawn bin/"sparknestd", "--config", testpath/"node.toml", "--bootstrap",
                [:out, :err] => (testpath/"daemon.log").to_s
    begin
      60.times do
        break if sock.exist? && quiet_system(bin/"nest", "--socket", sock, "status")

        sleep 0.5
      end
      nest = [bin/"nest", "--socket", sock]
      system(*nest, "import", "--wait", testpath/"src/models", "/models")
      assert_match "config.json", shell_output("#{nest.join(" ")} ls /models/demo")
      system(*nest, "store", "add", "archive", testpath/"archive", "--gateways", "solo")
      system(*nest, "offload", "/models", "--store", "archive", "--wait")
      system(*nest, "backup", "meta", "--store", "archive")
    ensure
      Process.kill("INT", pid)
      Process.wait(pid)
    end
    snapshot = Dir[testpath/"archive/meta/*.sqlite"].first
    system bin/"sparknestd", "export", "--meta", snapshot, "--objects", testpath/"archive", "--out", testpath/"out"
    assert_equal "hello sparknest\n", (testpath/"out/models/demo/config.json").read
  end
end
