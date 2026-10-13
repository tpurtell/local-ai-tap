class GpuPowerd < Formula
  desc "Thermal- and budget-aware NVIDIA power-limit daemon"
  homepage "https://github.com/tpurtell/gpu-powerd"
  url "https://github.com/tpurtell/gpu-powerd/archive/refs/tags/v0.1.1.tar.gz"
  sha256 "e4d85bafad3474e77c0c1ee5a8d176a77270adadff40c42e7ce890f180ed08fe"
  license any_of: ["Apache-2.0", "MIT"]

  bottle do
    root_url "https://github.com/tpurtell/local-ai-tap/releases/download/bottles-20261013-2"
    sha256 arm64_linux:  "b22237064d20d15c8fcb67379c5a225ca439f17661a7094624ac23f74872d6d0"
    sha256 x86_64_linux: "17f61b53a1a7e6992a2932f74b871043f2d1c958fcd55c59b165337fe7763722"
  end

  depends_on "patchelf" => :build
  depends_on "rust" => :build
  depends_on :linux

  def install
    # gpu-powerd runs as root, so it must not load anything from this user-writable
    # prefix. Point both service binaries at the system loader with no embedded library
    # paths and pack them: Homebrew rewrites the loader of every ELF it pours, but
    # leaves a tarball alone. `gpu-powerd-setup` verifies the bundle and installs it
    # into root-owned /usr/local. NVML is dlopen()ed at runtime from the driver, so
    # there is no link-time dependency.
    root = buildpath/"root"
    system "cargo", "install", *std_cargo_args(root: root)
    bundle = buildpath/"root-bundle"
    bundle.mkpath
    cp root/"bin/gpu-powerd", bundle
    cp root/"bin/gpu-powerd-ws", bundle
    cp "deploy/install.sh", bundle
    cp "deploy/gpu-powerd.service", bundle
    cp "deploy/gpu-powerd-ws.service", bundle
    cp "config.example.toml", bundle
    loader = Hardware::CPU.arm? ? "/lib/ld-linux-aarch64.so.1" : "/lib64/ld-linux-x86-64.so.2"
    %w[gpu-powerd gpu-powerd-ws].each do |binary|
      system formula_opt_bin("patchelf")/"patchelf", "--set-interpreter", loader, "--remove-rpath",
             bundle/binary
    end
    (libexec/"gpu-powerd").mkpath
    system "tar", "-C", bundle, "--owner=0", "--group=0", "--numeric-owner",
           "-cf", libexec/"gpu-powerd/root-bundle.tar", "."

    # The same binary, unprivileged, for `--check`, `status` and `model` as your user.
    bin.install root/"bin/gpu-powerd"
    bin.install "deploy/gpu-powerd-setup"
    pkgshare.install "config.example.toml", "deploy"
    doc.install "README.md"
  end

  def caveats
    <<~EOS
      gpu-powerd sets GPU power limits as root, so a separate step installs it (and the
      unprivileged WebSocket relay gpu-powerd-ws) into root-owned /usr/local and starts
      both (replacing nvidia-power-limit.service if present):
        sudo "#{opt_bin}/gpu-powerd-setup"
      After `brew upgrade gpu-powerd`, run it again. To remove it (and re-enable what it replaced):
        sudo "#{opt_bin}/gpu-powerd-setup" --uninstall

      Read-only views, no root needed:  gpu-powerd --check | status | model
      Live stream: ws://HOST:9877/ (read-only, NO AUTHENTICATION; websocket_bind/_port
      in the config, websocket = false to turn it off).
      Config: /etc/gpu-powerd/config.toml. Change it with the root-owned copy (never sudo the
      brew one):  sudo /usr/local/sbin/gpu-powerd set KEY=VALUE   (edits and reloads)
    EOS
  end

  test do
    # The root bundle: system loader, no embedded library paths, glibc <= 2.39.
    assert_match "bundle verified", shell_output("#{bin}/gpu-powerd-setup --check")
    assert_match version.to_s, shell_output("#{bin}/gpu-powerd --version")
    (testpath/"config.toml").write "system_budget_w = 900\n"
    # `set` edits the config (validated before writing); a bad value is rejected unchanged.
    system bin/"gpu-powerd", "set", "hard_c=88", "--no-reload", "--config", testpath/"config.toml"
    assert_match "hard_c = 88", (testpath/"config.toml").read
    output = shell_output("#{bin}/gpu-powerd set hard_c=60 --no-reload --config #{testpath}/config.toml 2>&1", 1)
    assert_match "invalid", output
    assert_match "hard_c = 88", (testpath/"config.toml").read
  end
end
