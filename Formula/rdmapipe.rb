class Rdmapipe < Formula
  desc "Stream Unix pipes over RDMA with SSH orchestration"
  homepage "https://github.com/tpurtell/rdmapipe"
  url "https://github.com/tpurtell/rdmapipe/releases/download/v0.1.0/rdmapipe-0.1.0.tar.gz"
  sha256 "29fe87ded0d9dfb1d86441a6770d975c276ef5ab42c0e54cbce06a317e972171"
  license "MIT"

  bottle do
    root_url "https://github.com/tpurtell/local-ai-tap/releases/download/bottles-20260910-1"
    rebuild 1
    sha256 cellar: :any, arm64_linux:  "1dd033303b92da0d0e49ed0f5a77229cdc0cfa5d82d4c2cfb639a33597d36241"
    sha256 cellar: :any, x86_64_linux: "2244c1efd187c0450813f67b56f3da57017bdc871337610af766068ac2064874"
  end

  depends_on :linux
  depends_on "tpurtell/local-ai/rdma-core"

  def install
    system "make"
    system "make", "check"
    system "make", "install", "PREFIX=#{prefix}"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/rdmapipe --version")
    assert_match "--send", shell_output("#{bin}/rdmapipe --help")
    assert_match "rdmapipe", pipe_output("#{bin}/rdmapipe --recv 2>&1", "{}\n", 2)
  end
end
