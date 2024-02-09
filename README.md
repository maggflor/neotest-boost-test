# neotest-boost-test

<img src="img/test-summary.png" alt="Demo test summary" style="max-height:500px"/>

This is a [neotest](https://github.com/nvim-neotest/neotest) adapter for [Boost.Test](https://github.com/boostorg/test), a popular C++ testing
library. It allows easy interactions with tests from your neovim.

## Installation

Use your favorite package manager. Don't forget to install [neotest] itself, which
also has a couple dependencies. The plugin also depends on `nvim-treesitter`, chances
are that so do your other plugins.

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
-- best to add to dependencies of `neotest`:
{
    "nvim-neotest/neotest",
    dependencies = {
        "nvim-treesitter/nvim-treesitter",
        "maggflor/neotest-boost-test"
        -- your other adapters here
    }
}
```

## Usage

Simply add `neotest-boost-test` to the `adapters` field of neotest's config:

```lua
require("neotest").setup({
  adapters = {
    require("neotest-boost-test")
  }
})
```

Once that's done, use `neotest` the way you usually do: see
[their documentation](https://github.com/nvim-neotest/neotest#usage).

