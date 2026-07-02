# Ocasio-Perez/sourcevault Homebrew tap

Install **SourceVault** — private, local code memory for AI: cited semantic
code search over your repositories, powered entirely by local models — on
macOS with one command:

```bash
brew trust ocasio-perez/sourcevault     # Homebrew 6+ requires trusting third-party taps once
brew install ocasio-perez/sourcevault/sourcevault
```

That pulls everything SourceVault needs: Node 24, [Ollama](https://ollama.com)
(from homebrew-core), and ChromaDB (the companion formula in this tap), and
generates the config + secrets at `$(brew --prefix)/etc/sourcevault/`.

Then pull the models once and start the services:

```bash
ollama pull nomic-embed-text
ollama pull qwen2.5-coder:14b

brew services start ollama
brew services start ocasio-perez/sourcevault/chromadb
brew services start ocasio-perez/sourcevault/sourcevault
```

Open <http://127.0.0.1:9000/dashboard/> and log in with the token from:

```bash
grep DASHBOARD_TOKEN "$(brew --prefix)/etc/sourcevault/sourcevault.env"
```

## Formulae

| Formula | What it is |
| --- | --- |
| `sourcevault` | The SourceVault server (Node 24, launchd service via `brew services`) |
| `chromadb` | ChromaDB vector store in a private Python virtualenv, with a service block |

## Upgrades

```bash
brew update && brew upgrade sourcevault
brew services restart ocasio-perez/sourcevault/sourcevault
```

Config in `etc/sourcevault/` and data in `var/sourcevault/` + `var/chromadb/`
survive upgrades. After an embedding-model change, reindex your repos.

## Releases

This tap also hosts the versioned release tarballs the `sourcevault` formula
installs from (the source repository is private); see this repo's Releases tab.
