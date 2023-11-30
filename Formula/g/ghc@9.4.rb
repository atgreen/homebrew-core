class GhcAT94 < Formula
  desc "Glorious Glasgow Haskell Compilation System"
  homepage "https://haskell.org/ghc/"
  url "https://downloads.haskell.org/~ghc/9.4.8/ghc-9.4.8-src.tar.xz"
  sha256 "0bf407eb67fe3e3c24b0f4c8dea8cb63e07f63ca0f76cf2058565143507ab85e"
  # We build bundled copies of libffi and GMP so GHC inherits the licenses
  license all_of: [
    "BSD-3-Clause",
    "MIT", # libffi
    any_of: ["LGPL-3.0-or-later", "GPL-2.0-or-later"], # GMP
  ]

  livecheck do
    url "https://www.haskell.org/ghc/download.html"
    regex(/href=.*?download[._-]ghc[._-][^"' >]+?\.html[^>]*?>\s*?v?(9\.4(?:\.\d+)+)\s*?</i)
  end

  bottle do
    sha256 cellar: :any,                 arm64_sonoma:   "e95b7bdb33044a5933232270fbb9d8cbdf8ee32a3f654f12d57fc84444aaeccc"
    sha256 cellar: :any,                 arm64_ventura:  "94977aaf7e3c603f4954bfc9b92bae3f043d733fce0abb8a3b15d51e91f32472"
    sha256 cellar: :any,                 arm64_monterey: "d4697ca409d8cd3c0257105fbe5562aca8912c220338ddbb1efce6d173dfc859"
    sha256 cellar: :any,                 sonoma:         "4f39fd7e199d543d5b3d9a743a727d079a7af2df2ec2abda76bc4ae7ca36bacd"
    sha256 cellar: :any,                 ventura:        "dc400241b4d3cb59dc42fc5e8f78e34c2b3e613b05be516a64c39fa3b52a8123"
    sha256 cellar: :any,                 monterey:       "c11d02945c240ea3e172334e13e7622fe48ac55d2a856543edccacdae6df84a7"
    sha256 cellar: :any_skip_relocation, x86_64_linux:   "3ec4c2900baf81afba4e80b74a86600155c43b6147ee084a70316e4589baacc9"
  end

  keg_only :versioned_formula

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "python@3.12" => :build
  depends_on "sphinx-doc" => :build

  uses_from_macos "m4" => :build
  uses_from_macos "xz" => :build
  uses_from_macos "ncurses"

  # Build uses sed -r option, which is not available in Catalina shipped sed.
  on_catalina do
    depends_on "gnu-sed" => :build
  end

  on_linux do
    depends_on "gmp" => :build
  end

  # A binary of ghc is needed to bootstrap ghc
  resource "binary" do
    on_macos do
      on_arm do
        url "https://downloads.haskell.org/~ghc/9.2.5/ghc-9.2.5-aarch64-apple-darwin.tar.xz"
        sha256 "b060ad093e0d86573e01b3d1fd622d4892f8d8925cbb7d75a67a01d2a4f27f18"
      end
      on_intel do
        url "https://downloads.haskell.org/~ghc/9.2.5/ghc-9.2.5-x86_64-apple-darwin.tar.xz"
        sha256 "6c46f5003f29d09802d572a7c5fabf6c1f91714a474967a5415b15df77fdcd90"
      end
    end
    on_linux do
      on_arm do
        url "https://downloads.haskell.org/~ghc/9.2.5/ghc-9.2.5-aarch64-deb10-linux.tar.xz"
        sha256 "29c0735ada90cdbf7e4a227dee08f18d74e33ec05d7c681e4ef95b8aa13104b3"
      end
      on_intel do
        url "https://downloads.haskell.org/~ghc/9.2.5/ghc-9.2.5-x86_64-ubuntu20.04-linux.tar.xz"
        sha256 "be1ca5b2864880d7c3623c51f2c2ca773e380624929bf0be8cfadbdb7f4b7154"
      end
    end
  end

  resource "cabal-install" do
    on_macos do
      on_arm do
        url "https://downloads.haskell.org/~cabal/cabal-install-3.10.1.0/cabal-install-3.10.1.0-aarch64-darwin.tar.xz"
        sha256 "fdabdc4dca42688a97f2b837165af42fcfd4c111d42ddb0d4df7bbebd5c8750e"
      end
      on_intel do
        url "https://downloads.haskell.org/~cabal/cabal-install-3.10.1.0/cabal-install-3.10.1.0-x86_64-darwin.tar.xz"
        sha256 "893a316bd634cbcd08861306efdee86f66ec634f9562a8c59dc616f7e2e14ffa"
      end
    end
    on_linux do
      on_arm do
        url "https://downloads.haskell.org/~cabal/cabal-install-3.10.2.0/cabal-install-3.10.2.0-aarch64-linux-deb10.tar.xz"
        sha256 "004ed4a7ca890fadee23f58f9cb606c066236a43e16b34be2532b177b231b06d"
      end
      on_intel do
        url "https://downloads.haskell.org/~cabal/cabal-install-3.10.1.0/cabal-install-3.10.1.0-x86_64-linux-deb10.tar.xz"
        sha256 "9c89f7150a6d09e653ca7d08d22922be2d9f750d0314d9a0a7e2103fac021fac"
      end
    end
  end

  # Backport fix for building docs with sphinx-doc 7.
  # TODO: Remove patch if fix is backported to 9.4.
  # Ref: https://gitlab.haskell.org/ghc/ghc/-/merge_requests/10520
  patch do
    url "https://gitlab.haskell.org/ghc/ghc/-/commit/70526f5bd8886126f49833ef20604a2c6477780a.diff"
    sha256 "54cdde1ca5d1b6fe3bbad8d0eac2b8c112ca1f346c4086d1e7361fa9510f1f44"
  end

  def install
    ENV["CC"] = ENV.cc
    ENV["LD"] = "ld"
    ENV["PYTHON"] = which("python3.12")
    # Work around `ENV["CC"]` no longer being used unless set to absolute path.
    # Caused by https://gitlab.haskell.org/ghc/ghc/-/commit/6be2c5a7e9187fc14d51e1ec32ca235143bb0d8b
    # Issue ref: https://gitlab.haskell.org/ghc/ghc/-/issues/22175
    # TODO: remove once upstream issue is fixed
    ENV["ac_cv_path_CC"] = ENV.cc

    binary = buildpath/"binary"
    resource("binary").stage do
      binary_args = []
      if OS.linux?
        binary_args << "--with-gmp-includes=#{Formula["gmp"].opt_include}"
        binary_args << "--with-gmp-libraries=#{Formula["gmp"].opt_lib}"
      end

      system "./configure", "--prefix=#{binary}", *binary_args
      ENV.deparallelize { system "make", "install" }

      ENV.prepend_path "PATH", binary/"bin"
      # Build uses sed -r option, which is not available in Catalina shipped sed.
      ENV.prepend_path "PATH", Formula["gnu-sed"].libexec/"gnubin" if MacOS.version == :catalina
    end

    resource("cabal-install").stage { (binary/"bin").install "cabal" }
    system "cabal", "v2-update"

    system "./configure", "--prefix=#{prefix}", "--disable-numa", "--with-intree-gmp"
    hadrian_args = %W[
      -j#{ENV.make_jobs}
      --prefix=#{prefix}
      --flavour=release
      --docs=no-sphinx-pdfs
    ]
    # Work around linkage error due to RPATH in ghc-iserv-dyn-ghc
    # Issue ref: https://gitlab.haskell.org/ghc/ghc/-/issues/22557
    os = OS.mac? ? "osx" : OS.kernel_name.downcase
    cpu = Hardware::CPU.arm? ? "aarch64" : Hardware::CPU.arch.to_s
    extra_rpath = rpath(source: lib/"ghc-#{version}/bin",
                        target: lib/"ghc-#{version}/lib/#{cpu}-#{os}-ghc-#{version}")
    hadrian_args << "*.iserv.ghc.link.opts += -optl-Wl,-rpath,#{extra_rpath}"
    # Let hadrian handle its own parallelization
    ENV.deparallelize { system "hadrian/build", "install", *hadrian_args }

    bash_completion.install "utils/completion/ghc.bash" => "ghc"
    (lib/"ghc-#{version}/lib/package.conf.d/package.cache").unlink
    (lib/"ghc-#{version}/lib/package.conf.d/package.cache.lock").unlink
  end

  def post_install
    system "#{bin}/ghc-pkg", "recache"
  end

  test do
    (testpath/"hello.hs").write('main = putStrLn "Hello Homebrew"')
    assert_match "Hello Homebrew", shell_output("#{bin}/runghc hello.hs")
  end
end
