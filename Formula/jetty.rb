class Jetty < Formula
  desc "Java servlet engine and webserver"
  homepage "https://www.eclipse.org/jetty/"
  url "https://search.maven.org/remotecontent?filepath=org/eclipse/jetty/jetty-distribution/9.4.37.v20210219/jetty-distribution-9.4.37.v20210219.tar.gz"
  version "9.4.37.v20210219"
  sha256 "272834710067c18b5c5499ebdae5b013ff720b7c2af822d34c62adbf706c66cf"
  license any_of: ["Apache-2.0", "EPL-1.0"]

  livecheck do
    url "https://www.eclipse.org/jetty/download.php"
    regex(/href=.*?jetty-distribution[._-]v?(\d+(?:\.\d+)+(?:\.v\d+)?)\.t/i)
  end

  bottle :unneeded

  depends_on "openjdk"

  def install
    libexec.install Dir["*"]
    (libexec/"logs").mkpath

    bin.mkpath
    Dir.glob("#{libexec}/bin/*.sh") do |f|
      scriptname = File.basename(f, ".sh")
      (bin/scriptname).write <<~EOS
        #!/bin/bash
        export JETTY_HOME='#{libexec}'
        export JAVA_HOME="${JAVA_HOME:-#{Formula["openjdk"].opt_prefix}}"
        exec #{f} "$@"
      EOS
      chmod 0755, bin/scriptname
    end
  end

  test do
    ENV["JETTY_ARGS"] = "jetty.http.port=#{free_port} jetty.ssl.port=#{free_port}"
    ENV["JETTY_BASE"] = testpath
    cp_r Dir[libexec/"*"], testpath
    pid = fork { exec bin/"jetty", "start" }
    sleep 5 # grace time for server start
    begin
      assert_match(/Jetty running pid=\d+/, shell_output("#{bin}/jetty check"))
      assert_equal "Stopping Jetty: OK\n", shell_output("#{bin}/jetty stop")
    ensure
      Process.kill 9, pid
      Process.wait pid
    end
  end
end
