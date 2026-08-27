-- SteamOS-inspired dark theme, applied via tokyonight (already bundled by LazyVim).
-- Palette shared with tmux (linux/tmux/.tmux.conf) and Starship (linux/starship/.config/starship.toml)
-- for a consistent look across terminal, prompt, and editor.
return {
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000, -- load before other plugins so the colorscheme is available on startup
    opts = {
      style = "night",
      transparent = false,
      terminal_colors = true,
      styles = {
        comments = { italic = true },
        keywords = { italic = true },
        sidebars = "dark",
        floats = "dark",
      },
      -- Remap the base palette toward the SteamOS-dark target colors.
      on_colors = function(colors)
        colors.bg = "#0E1419"
        colors.bg_dark = "#0A0D11"
        colors.bg_float = "#0E1419"
        colors.bg_sidebar = "#0E1419"
        colors.bg_statusline = "#0E1419"
        colors.bg_popup = "#0E1419"
        colors.bg_highlight = "#1a2332"
        colors.bg_visual = "#1a2332"
        colors.bg_search = "#1a2332"

        colors.fg = "#cccccc"
        colors.fg_dark = "#cccccc"
        colors.fg_float = "#cccccc"
        colors.fg_sidebar = "#cccccc"

        colors.blue = "#00BFFF"
        colors.blue1 = "#00BFFF"
        colors.blue2 = "#00BFFF"
        colors.cyan = "#00BFFF"

        colors.green = "#5FAF87"
        colors.green1 = "#5FAF87"
        colors.git.add = "#5FAF87"

        colors.border = "#1a2332"
        colors.border_highlight = "#00BFFF"
      end,
      -- Patch specific highlight groups tokyonight's defaults don't fully cover.
      on_highlights = function(hl, colors)
        hl.CursorLine = { bg = "#1a2332" }
        hl.CursorLineNr = { fg = colors.blue, bold = true }
        hl.LineNr = { fg = "#5c6773" }
        hl.WinSeparator = { fg = colors.border }
        hl.VertSplit = { fg = colors.border }

        hl.NormalFloat = { bg = colors.bg }
        hl.FloatBorder = { fg = colors.blue, bg = colors.bg }
        hl.Pmenu = { bg = "#1a2332", fg = colors.fg }
        hl.PmenuSel = { bg = colors.blue, fg = colors.bg }

        hl.TelescopeNormal = { bg = colors.bg }
        hl.TelescopeBorder = { fg = colors.blue, bg = colors.bg }
        hl.TelescopePromptBorder = { fg = colors.blue, bg = colors.bg }
        hl.TelescopePromptNormal = { bg = colors.bg }
        hl.TelescopeResultsBorder = { fg = colors.border, bg = colors.bg }

        hl.WhichKeyFloat = { bg = colors.bg }
        hl.WhichKeyBorder = { fg = colors.blue }

        hl.DiagnosticOk = { fg = colors.green }
        hl.GitSignsAdd = { fg = colors.green }
        hl.GitSignsChange = { fg = colors.blue }
      end,
    },
  },

  -- Make tokyonight the active default colorscheme, LazyVim-idiomatic way
  -- (mirrors the gruvbox override already demonstrated, inertly, in example.lua).
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "tokyonight",
    },
  },
}
