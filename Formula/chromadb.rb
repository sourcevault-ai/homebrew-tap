class Chromadb < Formula
  desc "AI-native open-source embedding database"
  homepage "https://www.trychroma.com/"
  url "https://files.pythonhosted.org/packages/92/d1/5e33b26985f0c7046a0be1cee2158ada1748ee700d2545057fde1468d74d/chromadb-1.5.9.tar.gz"
  sha256 "5c20e62a455c28bacac927f26116a73fd8e1799e0d908be8e8a4f02197a54731"
  license "Apache-2.0"

  depends_on "python@3.13"

  def install
    # ChromaDB has dozens of Python dependencies; rather than vendoring a
    # resource stanza per package (the homebrew-core pattern), this personal
    # tap installs the pinned release into a private virtualenv with pip
    # resolving dependencies (network is permitted during tap builds).
    # Plain `python -m venv` (not Homebrew's virtualenv_create, which builds
    # the venv --without-pip) so libexec/bin/pip exists.
    system formula_opt_bin("python@3.13")/"python3.13", "-m", "venv", libexec
    system libexec/"bin/pip", "install", "--no-input", "chromadb==#{version}"
    bin.install_symlink libexec/"bin/chroma"
  end

  service do
    run [opt_bin/"chroma", "run", "--path", var/"chromadb", "--host", "127.0.0.1", "--port", "8000"]
    keep_alive true
    working_dir var/"chromadb"
    log_path var/"log/chromadb.log"
    error_log_path var/"log/chromadb.err.log"
  end

  def caveats
    <<~EOS
      Data is stored in #{var}/chromadb.
      Start the server (127.0.0.1:8000) with:
        brew services start ocasio-perez/sourcevault/chromadb
    EOS
  end

  test do
    # The chroma CLI reports its own component version, not the package's,
    # so pin the assertion to pip's view of the installed package.
    assert_match "chroma", shell_output("#{bin}/chroma --version 2>&1").downcase
    assert_match version.to_s, shell_output("#{libexec}/bin/pip show chromadb")
  end
end
