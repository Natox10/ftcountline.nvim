# ftcountline.nvim

ftcountline.nvim is a little plugin for neovim that displays the size of your functions for .c files.

## Installation

Lazy :
```Lua
return {
  {
    "Natox10/ftcountline.nvim",
    opts = {
      auto_update = true,
    },
    ft = "c",
  },
}
```

Packer :
```Lua
use {
	'Natox10/ftcountline.nvim',
	config = function(
		require('ftcountline').setup()
	end,
	ft = 'c'
	)
}
```
