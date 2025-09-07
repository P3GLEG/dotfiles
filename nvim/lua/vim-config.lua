vim.cmd("set cmdheight=2")
vim.cmd("set cursorline")
vim.cmd("set encoding=utf-8")
vim.cmd("set expandtab")
vim.cmd("set hidden")
vim.cmd("set shiftwidth=4")
vim.cmd("set shortmess+=c")
vim.cmd("set signcolumn=yes")
vim.cmd("set softtabstop=4")
vim.cmd("set tabstop=4")
vim.cmd("set clipboard=")
vim.cmd("set mouse=")

-- Leader key is spacebar
vim.g.mapleader = " "

-- Remap window navigation keys
vim.keymap.set("n", "<leader>h", "<C-w>h", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>j", "<C-w>j", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>k", "<C-w>k", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>l", "<C-w>l", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>m", "<C-6>", { noremap = true, silent = true })

-- Keep Persistent history in XDG state (outside repo)
vim.cmd("set undofile")
local undodir = vim.fn.stdpath("state") .. "/undo"
vim.fn.mkdir(undodir, "p")
vim.opt.undodir = undodir

local function augroup(name)
	return vim.api.nvim_create_augroup(name, { clear = true })
end

-- Highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
	group = augroup("highlight_yank"),
	callback = function()
		vim.highlight.on_yank()
	end,
})

-- go to last loc when opening a buffer
vim.api.nvim_create_autocmd("BufReadPost", {
	group = augroup("last_loc"),
	callback = function(event)
		local exclude = { "gitcommit" }
		local buf = event.buf
		if vim.tbl_contains(exclude, vim.bo[buf].filetype) or vim.b[buf].lazyvim_last_loc then
			return
		end
		vim.b[buf].lazyvim_last_loc = true
		local mark = vim.api.nvim_buf_get_mark(buf, '"')
		local lcount = vim.api.nvim_buf_line_count(buf)
		if mark[1] > 0 and mark[1] <= lcount then
			pcall(vim.api.nvim_win_set_cursor, 0, mark)
		end
	end,
})
-- close some filetypes with <q>
vim.api.nvim_create_autocmd("FileType", {
	group = augroup("close_with_q"),
	pattern = {
		"PlenaryTestPopup",
		"help",
		"lspinfo",
		"man",
		"notify",
		"qf",
		"query",
		"spectre_panel",
		"startuptime",
		"tsplayground",
		"neotest-output",
		"checkhealth",
		"neotest-summary",
		"neotest-output-panel",
	},
	callback = function(event)
		vim.bo[event.buf].buflisted = false
		vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, silent = true })
	end,
})

--Copy current file to clipboard
function CopyWholeFileToClipboard()
	local content = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
	vim.fn.setreg("+", content)
end

vim.api.nvim_set_keymap("n", "bp", ":lua CopyWholeFileToClipboard()<CR>", { noremap = true, silent = true })
