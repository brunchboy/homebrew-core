class UcspiTools < Formula
  desc "Various tools to handle UCSPI connections"
  homepage "https://github.com/younix/ucspi/blob/master/README.md"
  revision 10

  stable do
    url "https://github.com/younix/ucspi/archive/v1.2.tar.gz"
    sha256 "38cd0ae9113324602a600a6234d60ec9c3a8c13c8591e9b730f91ffb77e5412a"

    # LibreSSL is still in rapid development & the release branch we follow
    # moves much quicker than the ucspi project. Since ucspi-tools breaks
    # every LibreSSL update vendor until new release is available.
    resource "libressl" do
      url "http://ftp.openbsd.org/pub/OpenBSD/LibreSSL/libressl-2.2.7.tar.gz"
      sha256 "7e2c68b383bba8efb7dce5ea1eccfda77048547d1d2a7355c072efd7ccd893cd"
    end

    # LibreSSL renamed a function between the 2.1.3 and 2.1.4 release which ucspi uses.
    # https://github.com/younix/ucspi/issues/2
    # http://www.freshbsd.org/commit/openbsd/2b22762d1139c74c743195f46b41fea0b9459ecd
    patch do
      url "https://github.com/younix/ucspi/pull/3.diff"
      sha256 "932aa6fcde21dc4eb3ad4474a6cd5f413f4da076b1de1491360a60584e0e514e"
    end
  end

  bottle do
    sha256 "dcb8b5831d2efd0387780ee4b6bb205071e6246b80e33a8ede14d0f453a6e55e" => :el_capitan
    sha256 "9094348d82cf0baf6d9b3d740bb6de28a5bfa769c54aeb67cdc03446bb5704f6" => :yosemite
    sha256 "b88e7cffbd5dbd26d6b0dec0ce785b208401c57d4c990a7eb3dd5861187ecb38" => :mavericks
  end

  head do
    url "https://github.com/younix/ucspi.git"

    depends_on "libressl"
  end

  depends_on "pkg-config" => :build
  depends_on "ucspi-tcp"

  def install
    if build.stable?
      vendordir = libexec/"vendor/libressl"
      resource("libressl").stage do
        args = %W[
          --disable-dependency-tracking
          --disable-silent-rules
          --prefix=#{vendordir}
          --with-openssldir=#{vendordir}/etc
          --sysconfdir=#{vendordir}/etc
        ]

        # https://github.com/libressl-portable/portable/issues/121
        args << "--disable-asm" if MacOS.version <= :snow_leopard

        system "./configure", *args
        system "make"
        system "make", "check"
        system "make", "install"

        # It looks for the headers prior to checking pkg-config so we
        # can't just pass PKG_CONFIG_PATH sadly.
        ENV.prepend_path "PATH", vendordir/"bin"
        ENV.prepend_path "PKG_CONFIG_PATH", "#{vendordir}/lib/pkgconfig"
        ENV.prepend "CFLAGS", "-I#{vendordir}/include"
      end
    end

    system "make", "PREFIX=#{prefix}", "install", "CFLAGS=#{ENV.cflags}"
  end

  def post_install
    return unless File.exist?(libexec/"vendor")

    keychains = %w[
      /Library/Keychains/System.keychain
      /System/Library/Keychains/SystemRootCertificates.keychain
    ]

    certs_list = `security find-certificate -a -p #{keychains.join(" ")}`
    certs = certs_list.scan(
      /-----BEGIN CERTIFICATE-----.*?-----END CERTIFICATE-----/m
    )

    valid_certs = certs.select do |cert|
      IO.popen("openssl x509 -inform pem -checkend 0 -noout", "w") do |openssl_io|
        openssl_io.write(cert)
        openssl_io.close_write
      end

      $?.success?
    end

    # LibreSSL install a default pem - We prefer to use OS X for consistency.
    rm_f libexec/"vendor/libressl/etc/cert.pem"
    (libexec/"vendor/libressl/etc/cert.pem").atomic_write(valid_certs.join("\n"))
  end

  test do
    out = shell_output("#{bin}/tlsc 2>&1", 1)
    assert_equal "tlsc [-hCH] [-c cert_file] [-f ca_file] [-p ca_path] program [args...]\n", out
  end
end
