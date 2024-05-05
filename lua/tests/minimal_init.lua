local lazy_path = vim.fn.stdpath("data") .. "/lazy"

-- Make tested plugin available
vim.opt.rtp:append("..")
-- Make dependencies available
vim.opt.rtp:append(lazy_path .. "/neotest")
vim.opt.rtp:append(lazy_path .. "/nvim-nio")

-- Make :PlenaryBustedFile and :PlenaryBustedDirectory available
vim.cmd("runtime! plugin/plenary.vim")
