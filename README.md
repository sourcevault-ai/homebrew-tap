# sourcevault-ai/tap — the SourceVault Homebrew tap

Install **SourceVault** — private, local code memory for AI: cited semantic
code search over your repositories, powered entirely by local models — on
macOS with one command:

```bash
brew trust sourcevault-ai/tap     # Homebrew 6+ requires trusting third-party taps once
brew install sourcevault-ai/tap/sourcevault
```

That pulls everything SourceVault needs: Node 24, [Ollama](https://ollama.com)
(from homebrew-core), and ChromaDB (the companion formula in this tap), and
generates the config + secrets at `$(brew --prefix)/etc/sourcevault/`.

Then pull the models once and start the services:

```bash
ollama pull nomic-embed-text
ollama pull qwen2.5-coder:14b

brew services start ollama
brew services start sourcevault-ai/tap/chromadb
brew services start sourcevault-ai/tap/sourcevault
```

Open <http://127.0.0.1:9000/dashboard/> and log in with the token from:

```bash
grep DASHBOARD_TOKEN "$(brew --prefix)/etc/sourcevault/sourcevault.env"
```

Installs include a **7-day trial with one indexed repository** — enough to
evaluate SourceVault on a real codebase. A license key (dashboard →
Settings → License) continues past the trial, raises or removes the repo
cap, and unlocks multi-repo ask and compliance features:
<https://trysourcevault.com>

## Formulae

| Formula | What it is |
| --- | --- |
| `sourcevault` | The SourceVault server (Node 24, launchd service via `brew services`) |
| `chromadb` | ChromaDB vector store in a private Python virtualenv, with a service block |

## Upgrades

```bash
brew update && brew upgrade sourcevault
brew services restart sourcevault-ai/tap/sourcevault
```

Config in `etc/sourcevault/` and data in `var/sourcevault/` + `var/chromadb/`
survive upgrades. After an embedding-model change, reindex your repos.

## Releases

This tap also hosts the versioned release tarballs the `sourcevault` formula
installs from (the source repository is private); see this repo's Releases tab.
