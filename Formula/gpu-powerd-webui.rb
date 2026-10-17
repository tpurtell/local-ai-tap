class GpuPowerdWebui < Formula
  desc "GPU and system dashboard for gpu-powerd telemetry and SSH hosts"
  homepage "https://github.com/tpurtell/gpu-powerd-webui"
  url "https://github.com/tpurtell/gpu-powerd-webui/releases/download/v0.2.0/gpu-powerd-webui-0.2.0.tar.gz"
  sha256 "268491726c3dca4ac7ca8fa449030aa64ef71acdda192b1f0a60051a115e3b23"
  license "MIT"

  bottle do
    root_url "https://github.com/tpurtell/local-ai-tap/releases/download/bottles-20261017-webui-1"
    sha256 cellar: :any_skip_relocation, arm64_linux:  "6dc9f6c71d647a753c26cafbb628af2784aa890e83c38cd48b51253119350d8b"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "cd086960f03d4964890298ac77b7255d448207fb67387814d746c8c0ddfc14c1"
  end

  depends_on :linux

  def install
    # No ELF payload or third-party runtime: the system service uses /usr/bin/python3.
    pkgshare.install "server.py", "app.js", "index.html", "config.example.json"
    bin.install "deploy/gpu-powerd-webui-setup"
    (bin/"gpu-powerd-webui").write <<~SH
      #!/bin/sh
      exec /usr/bin/python3 "#{opt_pkgshare}/server.py" "$@"
    SH
    doc.install "README.md"
  end

  def caveats
    <<~EOS
      Requires system Python 3.10+ and gpu-powerd with stream = true.
      Install an unprivileged systemd service with root-owned application files:
        sudo "#{opt_bin}/gpu-powerd-webui-setup"
      To monitor SSH hosts as an existing user:
        sudo "#{opt_bin}/gpu-powerd-webui-setup" --user YOUR_USER --config /path/to/config.json
      Run setup again after brew upgrade. Config: /etc/gpu-powerd-webui/config.json.
      Default URL: http://127.0.0.1:13456/. History: /var/lib/gpu-powerd-webui.
    EOS
  end

  test do
    assert_match "gpu-powerd-webui #{version}", shell_output("#{bin}/gpu-powerd-webui --version")
    assert_match "bundle verified", shell_output("#{bin}/gpu-powerd-webui-setup --check")
    cp pkgshare/"config.example.json", testpath/"config.json"
    assert_match "config valid", shell_output("#{bin}/gpu-powerd-webui --config #{testpath}/config.json --check")
  end
end
