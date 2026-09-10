class RdmaCore < Formula
  desc "RDMA userspace libraries, hardware providers, and diagnostic tools"
  homepage "https://github.com/linux-rdma/rdma-core"
  url "https://github.com/linux-rdma/rdma-core/archive/refs/tags/v65.0.tar.gz"
  sha256 "714881af1c875f335aee55e94e770894963af3b9bbb6c1248e4a279058dcba58"
  license any_of: ["GPL-2.0-only", "BSD-2-Clause"]

  depends_on "cmake" => :build
  depends_on "ninja" => :build
  depends_on "pandoc" => :build
  depends_on "pkgconf" => :build
  depends_on "python@3.14" => :build
  depends_on "libnl"
  depends_on :linux

  def install
    system "cmake", "-S", ".", "-B", "build", "-G", "Ninja", *std_cmake_args,
           "-DCMAKE_INSTALL_LIBDIR=lib",
           "-DCMAKE_INSTALL_SYSCONFDIR=#{etc}",
           "-DCMAKE_INSTALL_SYSTEMD_BINDIR=#{lib}/systemd",
           "-DSYSUSERS_DIR=#{lib}/sysusers.d",
           "-DCMAKE_INSTALL_RUNDIR=#{var}/run",
           "-DCMAKE_DISABLE_FIND_PACKAGE_UDev=TRUE",
           "-DCMAKE_DISABLE_FIND_PACKAGE_Systemd=TRUE",
           "-DNO_PYVERBS=1",
           "-DENABLE_STATIC=OFF",
           "-DENABLE_VALGRIND=OFF"
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    assert_match "device", shell_output("#{bin}/ibv_devices")
    (testpath/"verbs.c").write <<~C
      #include <infiniband/verbs.h>
      int main(void) {
        int count = 0;
        struct ibv_device **devices = ibv_get_device_list(&count);
        if (!devices) return 1;
        ibv_free_device_list(devices);
        return 0;
      }
    C
    system ENV.cc, "verbs.c", "-I#{include}", "-L#{lib}", "-libverbs", "-o", "verbs"
    system "./verbs"
  end
end
