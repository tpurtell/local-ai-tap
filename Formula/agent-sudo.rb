class AgentSudo < Formula
  desc "Brokered sudo for machines where coding agents do the typing"
  homepage "https://github.com/tpurtell/agent-sudo"
  url "https://github.com/tpurtell/agent-sudo/releases/download/v0.2.0/agent-sudo-0.2.0.tar.gz"
  sha256 "d709851d4404faf026ed3853b94ffeaa2fe86601d26221a240b7e8a7e1969c6b"
  license any_of: ["Apache-2.0", "MIT"]

  depends_on "linux-pam" => :build
  depends_on "patchelf" => :build
  depends_on "pkgconf" => :build
  depends_on "rust" => :build
  depends_on :linux
  depends_on "openssl@3"

  def install
    # The approval service binary: `agent-sudo-service init`, and running without Docker.
    system "cargo", "install", *std_cargo_args(path: "service")

    # The host binaries run as root (setuid agent-sudo and the hostd relay), so they
    # must not load anything from this user-writable prefix. Point them at the system
    # loader with no embedded library paths and pack them: Homebrew rewrites the loader
    # of every ELF it pours, but leaves a tarball alone. `agent-sudo-setup` verifies
    # the bundle and installs it into root-owned /usr/local.
    host = buildpath/"host-root"
    system "cargo", "install", *std_cargo_args(path: "hostd", root: host)
    system "cargo", "install", *std_cargo_args(path: "sudo", root: host),
           "--features", "agent-approval,pam-login", "--bin", "sudo"
    bundle = buildpath/"host-bundle"
    bundle.mkpath
    cp host/"bin/agent-sudo-hostd", bundle
    cp host/"bin/sudo", bundle/"agent-sudo"
    cp "deploy/host/install.sh", bundle
    cp "deploy/host/agent-sudo-hostd.service", bundle
    loader = Hardware::CPU.arm? ? "/lib/ld-linux-aarch64.so.1" : "/lib64/ld-linux-x86-64.so.2"
    %w[agent-sudo agent-sudo-hostd].each do |binary|
      system formula_opt_bin("patchelf")/"patchelf", "--set-interpreter", loader, "--remove-rpath", bundle/binary
    end
    (libexec/"agent-sudo").mkpath
    system "tar", "-C", bundle, "--owner=0", "--group=0", "--numeric-owner",
           "-cf", libexec/"agent-sudo/host-bundle.tar", "."

    bin.install "deploy/host/agent-sudo-setup"
    pkgshare.install "skills", "deploy"
    doc.install "README.md", "docs"
  end

  def caveats
    <<~EOS
      agent-sudo runs as root, so a separate step installs it into root-owned /usr/local:
        sudo "#{opt_bin}/agent-sudo-setup" --enroll https://YOUR-SERVICE TOKEN
      After `brew upgrade agent-sudo`, run it again without arguments.

      Then, as your own user, teach your coding agents to use it:
        agent-sudo-hostd skill install

      To create a deployment of the approval service:
        agent-sudo-service init
    EOS
  end

  test do
    # The host bundle: system loader, no embedded library paths, glibc <= 2.39.
    assert_match "bundle verified", shell_output("#{bin}/agent-sudo-setup --check")
    assert_match version.to_s, shell_output("#{bin}/agent-sudo-service --version")
    system bin/"agent-sudo-service", "init", testpath/"deploy", "--yes", "--no-test",
           "--front-door", "nginx", "--public-url", "https://sudo.example.net",
           "--advisor", "none"
    assert_match "COMPOSE_PROFILES=nginx", (testpath/"deploy/.env").read
    assert_match "public_url", (testpath/"deploy/service.toml").read
  end
end
