# sourcevault-ai/tap — the SourceVault Homebrew tap

Install **SourceVault** — private, local code memory for AI: cited semantic
code search over your repositories, powered entirely by local models — on
macOS with one command:

```bash
brew trust sourcevault-ai/tap     # Homebrew 6+ requires trusting third-party taps once
brew install sourcevault-ai/tap/sourcevault
```

That pulls everything SourceVault needs: Node 24 and [Ollama](https://ollama.com)
(from homebrew-core), and generates the config + secrets at
`$(brew --prefix)/etc/sourcevault/`. There is no vector database to run: code
vectors and git history live in a SQLite file under `var/sourcevault/`.

Then pull the models once and start the services. The server picks the
reasoning model by RAM: `qwen3.5:9b` on 16 GB+, `qwen3.5:4b` on 8-12 GB.

```bash
ollama pull nomic-embed-text
ollama pull qwen3.5:9b

brew services start ollama
brew services start sourcevault-ai/tap/sourcevault
```

Open <http://127.0.0.1:9000/dashboard/> and log in with the token from:

```bash
grep DASHBOARD_TOKEN "$(brew --prefix)/etc/sourcevault/sourcevault.env"
```

Installs include a **7-day trial with one indexed repository** — enough to
evaluate SourceVault on a real codebase. Every install, trial included, carries the
SourceVault Gateway (access policy, secret redaction, audit chain,
provenance, agent identity). A license key (dashboard → Settings → Plan &
licence) continues past the trial, raises or removes the source cap, and from
Pro up unlocks multi-repo ask: <https://sourcevault.ai>

## Formulae

| Formula | What it is |
| --- | --- |
| `sourcevault` | The SourceVault server (Node 24, launchd service via `brew services`) |
| `chromadb` | ChromaDB in a private Python virtualenv, with a service block. Only for installs that indexed on ChromaDB before v1.49; fresh installs do not need it |

## Upgrades

```bash
brew update && brew upgrade sourcevault
brew services restart sourcevault-ai/tap/sourcevault
```

Config in `etc/sourcevault/` and data in `var/sourcevault/` (plus
`var/chromadb/` on pre-1.49 installs) survive upgrades. Upgrading from 1.48 or
earlier? Keep the `chromadb` service running until you run
`npm run migrate-vectors -- --to sqlite` in the formula's `libexec` and switch
the stores under Settings → Advanced. After an embedding-model change, reindex your repos.

## Releases

This tap also hosts the versioned release tarballs the `sourcevault` formula
installs from (the source repository is private); see this repo's Releases tab.

Maintainer note: if a formula carries a `revision` line (used to rebuild kegs
for a formula-only change), it must be removed when the version next changes —
CI strips it automatically (`.github/workflows/drop-stale-revision.yml` fires
on any push that changes a formula's `url`); drop it by hand only if that
workflow is disabled.
