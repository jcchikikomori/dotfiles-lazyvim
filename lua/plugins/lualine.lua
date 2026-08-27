-- Custom lualine theme matching the SteamOS-dark palette used by tmux and Starship.
-- Mode-indicator (`a` section) mirrors tmux's session segment / Starship's directory pill
-- (accent blue). `b`/`c` sections reuse tmux's inactive-tab bg (#1a2332) as a subtler
-- secondary background, tying the statusline back to the terminal chrome around it.
return {
  "nvim-lualine/lualine.nvim",
  opts = function(_, opts)
    local colors = {
      bg = "#0E1419",
      bg_alt = "#1a2332",
      blue = "#00BFFF",
      green = "#5FAF87",
      fg = "#cccccc",
    }

    local bc = {
      b = { bg = colors.bg_alt, fg = colors.fg },
      c = { bg = colors.bg, fg = colors.fg },
    }

    opts.options = opts.options or {}
    opts.options.theme = {
      normal = {
        a = { bg = colors.blue, fg = colors.bg, gui = "bold" },
        b = bc.b,
        c = bc.c,
      },
      insert = {
        a = { bg = colors.green, fg = colors.bg, gui = "bold" },
        b = bc.b,
        c = bc.c,
      },
      visual = {
        a = { bg = colors.fg, fg = colors.bg, gui = "bold" },
        b = bc.b,
        c = bc.c,
      },
      replace = {
        a = { bg = colors.bg_alt, fg = colors.blue, gui = "bold" },
        b = bc.b,
        c = bc.c,
      },
      command = {
        a = { bg = colors.bg, fg = colors.blue, gui = "bold" },
        b = bc.b,
        c = bc.c,
      },
      inactive = {
        a = { bg = colors.bg_alt, fg = colors.fg },
        b = { bg = colors.bg_alt, fg = colors.fg },
        c = { bg = colors.bg, fg = colors.fg },
      },
    }
  end,
}
