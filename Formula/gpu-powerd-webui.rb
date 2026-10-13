class GpuPowerdWebui < Formula
  desc "Responsive GPU dashboard for gpu-powerd telemetry and SSH hosts"
  homepage "https://github.com/tpurtell/gpu-powerd-webui"
  url "https://github.com/tpurtell/gpu-powerd-webui/releases/download/v0.1.1/gpu-powerd-webui-0.1.1.tar.gz"
  sha256 "f32598db8673e5e7a39a6819c131a047d814bf14a401eb833eb9e27dc005c679"
  license "MIT"

  bottle do
    root_url "https://github.com/tpurtell/local-ai-tap/releases/download/bottles-20261013-webui-2"
    sha256 cellar: :any_skip_relocation, arm64_linux:  "5a3d93b0b61d91a71543cef4d1459813e4188da37ebed7dca71458fc154714a6"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "aed83283bcd1e6ae2f2c4e49b549c299ea51d3c8032a8d258951d0c54579d1c4"
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
