class Madplay < Formula
  desc "MPEG Audio Decoder"
  homepage "http://www.underbit.com/products/mad/"
  url "https://downloads.sourceforge.net/project/mad/madplay/0.15.2b/madplay-0.15.2b.tar.gz"
  sha256 "5a79c7516ff7560dffc6a14399a389432bc619c905b13d3b73da22fa65acede0"

  bottle do
    sha256 "81dbc8781c5da50f7188a4031ed5d500b07c51a7589da6799c6bf3477bb90bf6" => :el_capitan
    sha256 "4ab0b6303cafe408494e85c38b80a3c44964953995c024d2b65a019bc5608c05" => :yosemite
    sha256 "2b1967955d83ca172724b119e837457aec0eeaa7ded354c810f3635dafbec057" => :mavericks
  end

  depends_on "mad"
  depends_on "libid3tag"

  patch :p0 do
    url "https://raw.githubusercontent.com/Homebrew/patches/f6c5992c/madplay/patch-audio_carbon.c"
    sha256 "380e1a5ee3357fef46baa9ba442705433e044ae9e37eece52c5146f56da75647"
  end

  def install
    args = %W[
      --disable-debug
      --disable-dependency-tracking
      --prefix=#{prefix}
      --mandir=#{man}
    ]

    # Avoid "error: CPU you selected does not support x86-64 instruction set"
    args << "--build=#{Hardware::CPU.arch_64_bit}" if MacOS.prefer_64_bit?
    system "./configure", *args
    system "make", "install"
  end
end
