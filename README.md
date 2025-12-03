ultra basic diagnostic tools for nvim

example config

```----------
return {
  {
    'Gabriel2409/diagnostic-tools',
    name = 'diagnostic-tools',
    opts = {
      sources = {
        Ruff = {
          format = '# noqa: %s',
          url_path = 'user_data.lsp.codeDescription.href',
        },
        ty = {
          format = '# ty: ignore[%s]',
          url_path = 'user_data.lsp.codeDescription.href',
        },
      },
    },
    keys = {
      {
        '<leader>cDI',
        "<cmd>lua require('diagnostic-tools').suppress_diagnostic()<CR>",
        desc = 'Ignore diagnostic',
      },
      {
        '<leader>cDD',
        "<cmd>lua require('diagnostic-tools').debug_diagnostic()<CR>",
        desc = 'Debug diagnostic',
      },
      {
        '<leader>cDO',
        "<cmd>lua require('diagnostic-tools').open_diagnostic_docs()<CR>",
        desc = 'Open diagnostic docs',
      },
    },
  },
  {
    'folke/which-key.nvim',
    opts = {
      defaults = {
        ['<leader>cD'] = { name = '+Diagnostics' },
      },
    },
  },
}

```
