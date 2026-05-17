-- Space をリーダーキーに設定
-- キーマップより前に宣言する必要がある
vim.g.mapleader = " "

require("config.editor")
require("config.colorscheme")
require("config.neo-tree")
require("config.telescope")
require("config.claudecode")
require("config.lualine")
require("config.winresizer")
require("config.toggleterm")
require("config.gitsigns")
require("config.accelerated-jk")
require("config.scrollbar")