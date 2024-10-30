# ftcountline.nvim

Ftcountline.nvim is a little plugin for neovim that display the number of line in your functions in c.

##Installation

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
