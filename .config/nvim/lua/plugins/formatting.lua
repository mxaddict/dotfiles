return {
  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      opts.formatters_by_ft.gdscript = { "gdformat" }
      opts.formatters_by_ft.sql = { "sqlfluff" }

      opts.formatters = opts.formatters or {}
      opts.formatters.gdformat = {}
      opts.formatters.sqlfluff = {
        args = { "fix", "-" },
      }
    end,
  },
}
