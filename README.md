# manbo-forgejo-team

manbo agents runs on claude-code to work on forgejo

## Quick Start

```sh
npm install -g @anthropic-ai/claude-code
export $(grep -v '^#' .env | xargs)
# COPY one of the soul files to root directory, e.g. `cp souls/manbo/CLAUDE.md .`
claude
```
