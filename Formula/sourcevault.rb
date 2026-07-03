class Sourcevault < Formula
  desc "Private, local code memory for AI - cited semantic code search"
  # The source repo is private; this tap hosts the release tarballs.
  homepage "https://github.com/sourcevault-ai/homebrew-tap"
  url "https://github.com/sourcevault-ai/homebrew-tap/releases/download/v1.1.2/sourcevault-v1.1.2.tar.gz"
  # From the release asset's .tar.gz.sha256 sidecar (published by the
  # private source repo's release workflow).
  sha256 "5b707b5da5ef2415863fe3c95c29b4774b49372e928a847ed912c5a20c9328d8"
  license :cannot_represent

  depends_on "node@24"
  depends_on "ollama"
  depends_on "sourcevault-ai/tap/chromadb"

  def install
    # Release tarballs ship dashboard/dist prebuilt; production deps only.
    # (The build sandbox allows network, so transitive postinstall downloads
    # like onnxruntime's native binary work here.)
    system "npm", "ci", "--omit=dev", "--no-fund", "--no-audit"
    libexec.install Dir["*"]

    # node@24 is keg-only (not on PATH) — reference its binary explicitly.
    # The env file is sourced login-shell-style, mirroring the launchd
    # template this replaces; state/repo dirs default under Homebrew's var.
    (bin/"sourcevault").write <<~EOS
      #!/bin/bash
      # SOURCEVAULT_ENV_FILE overrides the config location (e.g. /dev/null
      # to run purely from the process environment).
      ENV_FILE="${SOURCEVAULT_ENV_FILE:-#{etc}/sourcevault/sourcevault.env}"
      if [ -f "$ENV_FILE" ]; then
        set -a
        . "$ENV_FILE"
        set +a
      fi
      export SOURCEVAULT_STATE_DIR="${SOURCEVAULT_STATE_DIR:-#{var}/sourcevault/state}"
      export REPO_ROOT="${REPO_ROOT:-#{var}/sourcevault/repos}"
      exec "#{formula_opt_bin("node@24")}/node" "#{libexec}/bin/sourcevault.js" "$@"
    EOS
  end

  def post_install
    (var/"sourcevault/state").mkpath
    (var/"sourcevault/repos").mkpath

    # Generate config + secrets once; never overwritten on upgrade/reinstall.
    env_file = etc/"sourcevault/sourcevault.env"
    return if env_file.exist?

    require "securerandom"
    (etc/"sourcevault").mkpath
    env_file.write <<~EOS
      # SourceVault configuration — sourced by the `sourcevault` launcher.
      # Secrets were generated at install time; rotate the dashboard token
      # from Settings -> Security in the dashboard.
      HOST=127.0.0.1
      PORT=9000
      AGENT_NAME=sourcevault

      REPO_ROOT=#{var}/sourcevault/repos
      SOURCEVAULT_STATE_DIR=#{var}/sourcevault/state

      CHROMA_URL=http://127.0.0.1:8000
      CHROMA_COLLECTION=codebase

      OLLAMA_HOST=http://127.0.0.1:11434
      OLLAMA_EMBED_MODEL=nomic-embed-text

      # Unlicensed installs run a 7-day trial capped at one indexed
      # repository. A license key (Settings -> License in the dashboard)
      # continues past the trial and raises or removes the cap.
      SOURCEVAULT_DEFAULT_MAX_REPOS=1

      CODE_SEARCH_HMAC_SECRET=#{SecureRandom.hex(32)}
      DASHBOARD_TOKEN=#{SecureRandom.hex(32)}
    EOS
    env_file.chmod 0600
  end

  service do
    run [opt_bin/"sourcevault"]
    keep_alive true
    working_dir var/"sourcevault"
    log_path var/"log/sourcevault.log"
    error_log_path var/"log/sourcevault.err.log"
  end

  def caveats
    <<~EOS
      Configuration (secrets generated at install):
        #{etc}/sourcevault/sourcevault.env
      Your dashboard login token:
        grep DASHBOARD_TOKEN #{etc}/sourcevault/sourcevault.env

      Pull the required Ollama models once:
        ollama pull nomic-embed-text
        ollama pull qwen2.5-coder:14b

      Start everything:
        brew services start ollama
        brew services start sourcevault-ai/tap/chromadb
        brew services start sourcevault-ai/tap/sourcevault

      Then open http://127.0.0.1:9000/dashboard/ and index a repo:
        cd #{opt_libexec} && npm run code-repos -- add <git-url>
        cd #{opt_libexec} && npm run index-codebase -- <repo-name>

      Includes a 7-day trial with one indexed repository. Enter a license
      key (Settings -> License) to continue past the trial and add more
      repositories: https://trysourcevault.com
    EOS
  end

  test do
    # The server needs Chroma/Ollama to be useful, but it must at least boot
    # and answer the liveness probe with nothing else running.
    port = free_port
    env = { "PORT" => port.to_s, "HOST" => "127.0.0.1", "SOURCEVAULT_SKIP_STARTUP_PROBE" => "1",
            "SOURCEVAULT_ENV_FILE" => "/dev/null",
            "SOURCEVAULT_STATE_DIR" => (testpath/"state").to_s, "REPO_ROOT" => (testpath/"repos").to_s }
    pid = spawn(env, bin/"sourcevault")
    sleep 5
    output = shell_output("curl -s http://127.0.0.1:#{port}/health")
    assert_match "ok", output
  ensure
    Process.kill("TERM", pid)
  end
end
