class GpuPowerdWebui < Formula
  desc "Responsive GPU dashboard for gpu-powerd telemetry and SSH hosts"
  homepage "https://github.com/tpurtell/gpu-powerd-webui"
  url "https://github.com/tpurtell/gpu-powerd-webui/releases/download/v0.1.0/gpu-powerd-webui-0.1.0.tar.gz"
  sha256 "7a20efbeb9e14f120c03f479c5770b9ebba7047b46467ef7f4148709cd30283c"
  license "MIT"

  bottle do
    root_url "https://github.com/tpurtell/local-ai-tap/releases/download/bottles-20261013-webui-1"
    sha256 cellar: :any_skip_relocation, arm64_linux:  "61150ce2b1109f08515386a6a36b506cc3d9b4e0db28b11c6f7b0955cdcfa97f"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "b49e8fdc7fd57ea2c2e72494bef155e876aa1179bef8aba0402fe52491bd6605"
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
