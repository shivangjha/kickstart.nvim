-- Render markdown in the buffer: headings, tables, code blocks.
-- https://github.com/MeanderingProgrammer/render-markdown.nvim

vim.pack.add {
  'https://github.com/MeanderingProgrammer/render-markdown.nvim',
}

require('render-markdown').setup {}
