# piki

> [!note]
> AI was heavily used in the development of this plugin.

piki is an opinionated Neovim wiki plugin — a picky selection of features from [womwiki](https://github.com/wom/womwiki) and Obsidian, built around my own day-to-day workflow.

This plugin makes no assumptions about directory structure or desired features. Everything is explicitly opt-in. See [Configuration](#configuration) for details.

## Features
- Support for wikilinks and/or markdown links (with 'gf' navigation)
- Support for tags (parsing, inline, and frontmatter)
- Support for daily note templates
- Calendar view for navigating daily notes
- Support for completion

## Requirements
- Neovim >= 0.10
- A picker (telescope, fzf-lua, mini.pick, or snacks) if you intend to use search or navigation
- A completion plugin (blink-cmp, nvim-cmp) or native neovim completion if you want to use link/tag/heading completion

## Installation
vim.pack:
```lua
-- vim.pack (built-in, Neovim 0.11+)
vim.pack.add({ "https://github.com/n-samaniego/piki" })
```
Then in your config:
```lua
vim.cmd("packadd piki")
require("piki").setup({})
```

lazy.nvim:

## Configuration

## Usage

## License
MIT — see [LICENSE](LICENSE) for details.
Original work copyright (c) 2025 wom.
