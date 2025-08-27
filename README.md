# jjsigns.nvim

A Neovim plugin that shows [Jujutsu (jj)](https://github.com/martinvonz/jj) diff information in the gutter, similar to how [gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim) works for Git.

## Features

- **Gutter Signs**: Shows `┃`, `▁`, `▔`, `~` signs in the sign column for added, changed, and deleted lines (same as gitsigns)
- **Line Highlighting**: Optional highlighting of modified lines
- **Number Column**: Optional highlighting of line numbers for modified lines
- **Real-time Updates**: Updates signs as you type (with debouncing for performance)
- **Auto-attach**: Automatically attaches to files in JJ repositories
- **Customizable**: Configurable signs, colors, and behavior

## Requirements

- Neovim 0.9+
- [Jujutsu (jj)](https://github.com/martinvonz/jj) executable in your PATH

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'your-username/jjsigns.nvim',
  config = function()
    require('jjsigns').setup()
  end
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'your-username/jjsigns.nvim',
  config = function()
    require('jjsigns').setup()
  end
}
```

## Configuration

### Default Configuration

```lua
require('jjsigns').setup({
  enabled = true,
  
  attach = {
    auto = true,  -- Auto-attach to JJ repository files
  },
  
  signs = {
    add = { text = '┃', numhl = 'JjSignsAddNr', linehl = 'JjSignsAddLn' },
    change = { text = '┃', numhl = 'JjSignsChangeNr', linehl = 'JjSignsChangeLn' },
    delete = { text = '▁', numhl = 'JjSignsDeleteNr', linehl = 'JjSignsDeleteLn' },
    topdelete = { text = '▔', numhl = 'JjSignsDeleteNr', linehl = 'JjSignsDeleteLn' },
    changedelete = { text = '~', numhl = 'JjSignsChangeNr', linehl = 'JjSignsChangeLn' },
  },
  
  sign_priority = 6,
  signcolumn = true,  -- Toggle with `:JjSigns toggle_signs`
  numhl = false,      -- Toggle with `:JjSigns toggle_numhl`
  linehl = false,     -- Toggle with `:JjSigns toggle_linehl`
  
  -- JJ specific options
  base = '@-',  -- Base revision to compare against (default: parent revision)
  
  -- Performance options
  update_debounce = 100,  -- Debounce time for updates in milliseconds
})
```

## Commands

- `:JjSigns setup` - Setup/reinitialize the plugin
- `:JjSigns toggle` - Toggle the plugin on/off
- `:JjSigns enable` - Enable the plugin
- `:JjSigns disable` - Disable the plugin

## Highlight Groups

The plugin defines the following highlight groups:

### Sign Column
- `JjSignsAdd` - Added lines sign
- `JjSignsChange` - Changed lines sign  
- `JjSignsDelete` - Deleted lines sign
- `JjSignsTopdelete` - Top deleted lines sign
- `JjSignsChangedelete` - Changed+deleted lines sign

### Number Column
- `JjSignsAddNr` - Added lines number
- `JjSignsChangeNr` - Changed lines number
- `JjSignsDeleteNr` - Deleted lines number
- `JjSignsTopdeletNr` - Top deleted lines number
- `JjSignsChangedeletefNr` - Changed+deleted lines number

### Line Highlights
- `JjSignsAddLn` - Added lines background
- `JjSignsChangeLn` - Changed lines background
- `JjSignsDeleteLn` - Deleted lines background
- `JjSignsTopdeleteLn` - Top deleted lines background
- `JjSignsChangedeleteLn` - Changed+deleted lines background

By default, these link to the corresponding `GitSigns*` highlight groups if available, providing consistent styling with gitsigns.nvim.

## How it Works

1. The plugin automatically detects JJ repositories when you open files
2. For tracked files, it runs `jj diff` to compare the working copy with the parent revision (`@-`)
3. It parses the diff output to identify added, changed, and deleted lines
4. Signs are placed in the gutter using Neovim's extmarks API
5. Signs are updated in real-time as you edit files, with debouncing for performance

## Comparison with JJ

The plugin compares your working copy files against the base revision (default `@-`, the parent revision). This is equivalent to running:

```bash
jj diff --git --context=0 -r @-..@ -- path/to/file
```

You can change the base revision in the configuration if you want to compare against a different revision.

## Performance

- Uses debouncing (100ms by default) to avoid excessive updates while typing
- Only processes files that are tracked in the JJ repository
- Automatically detaches from buffers when they're unloaded
- Minimal memory footprint by storing only essential state

## Troubleshooting

### Signs not appearing
1. Ensure `jj` is in your PATH: `:!jj version`
2. Check if you're in a JJ repository: `:!jj status`  
3. Verify the file is tracked: `:!jj file list path/to/file`
4. Check if the plugin is enabled: `:JjSigns toggle`

### Performance issues
- Increase `update_debounce` in the configuration
- Disable `linehl` or `numhl` if not needed

## Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.

### Development

The codebase uses [StyLua](https://github.com/JohnnyMorganz/StyLua) for formatting. To format the code:

```bash
# Install stylua (if not already installed)
cargo install stylua

# Format all Lua files
stylua --config-path stylua.toml lua/ plugin/ *.lua
```

## License

MIT License - see LICENSE file for details.

## Acknowledgments

- Inspired by [gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim)
- Built for [Jujutsu VCS](https://github.com/martinvonz/jj)