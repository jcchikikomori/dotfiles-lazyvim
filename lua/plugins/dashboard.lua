-- Startup dashboard (snacks.nvim), rebuilt as a VS Code -> LazyVim translation table.
--
-- The LazyVim ASCII logo used to be blanked out here, which left the most valuable screen in the
-- session doing nothing. It now carries the one idea a VS Code refugee has to internalise on day
-- one: VS Code presses keys *together* (chords), LazyVim presses them *in sequence* (Space, then a
-- mnemonic). Everything below the header is reference material, not a launcher.
--
-- Colour contract, so "press now" is never confused with "press later":
--   green        a key you can press right now, on this screen
--   blue         a key you press later, while editing (reference only)
--   muted italic the VS Code chord you are migrating away from
-- Colours are read back out of the active theme (colorscheme.lua stays the single source of truth)
-- instead of being re-hardcoded here.

-- Leader is Space. Spelling it "<leader>" teaches nothing to someone who has never seen Vim
-- notation, so it renders as the open-box glyph and the header explains it once. Swap this to
-- "Spc" if a terminal font draws U+2423 badly.
local SPC = "␣"

-- Nerd-font glyphs sit in the Unicode private use area, which plenty of editors, pipes and
-- clipboards strip silently (this file lost its icons exactly that way once). Building them from
-- codepoints makes the file safe to move around, and padding each glyph to a fixed cell width keeps
-- the icon column straight no matter how wide the font draws it.
local ICON_W = 2
local function nf(cp)
  local glyph = vim.fn.nr2char(cp)
  return glyph .. (" "):rep(math.max(1, ICON_W - vim.api.nvim_strwidth(glyph)))
end

-- Pane geometry. snacks has no per-section width; every pane is opts.width wide and the count is
-- floor((win_width + pane_gap) / (width + pane_gap)). At 56/4 that is 2 panes from 116 columns up
-- and 1 pane below, so a narrow terminal collapses to a single readable column instead of
-- truncating. Items are declared alternating between panes so the collapsed order still reads
-- top-to-bottom sensibly.
local WIDTH = 56
local PANE_GAP = 4
local INDENT = 2

-- Row columns, summing to WIDTH - INDENT so nothing wraps.
local CONTENT = WIDTH - INDENT
local COL_OLD = 15 -- VS Code chord, right-aligned so the arrows form a clean seam
local COL_ARROW = 3 -- literal " -> "
local COL_NEW = 14 -- LazyVim keys
local COL_DESC = CONTENT - COL_OLD - COL_ARROW - COL_NEW

-- Read an attribute off the live theme so the dashboard follows any colorscheme change.
local function fg(group)
  local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = group, link = false })
  if ok and type(hl) == "table" then
    return hl.fg
  end
end

local function set_highlights()
  -- Function/Title resolve to the accent blue and String to the green in tokyonight, and to
  -- something sane in any other theme, which beats pinning hex values in two files.
  local accent, mark = fg("Function") or fg("Title"), fg("String")

  -- Pressable dashboard keys go green. snacks defines SnacksDashboardKey with default=true, so it
  -- will not clobber this regardless of which of us runs first.
  vim.api.nvim_set_hl(0, "SnacksDashboardKey", { fg = mark, bold = true })

  vim.api.nvim_set_hl(0, "DashKeyNew", { fg = accent, bold = true })
  vim.api.nvim_set_hl(0, "DashHead", { fg = accent, bold = true })
  vim.api.nvim_set_hl(0, "DashMark", { fg = mark })
  -- Linking to Comment inherits the theme's italic, which reads nicely as "the old way".
  vim.api.nvim_set_hl(0, "DashKeyOld", { link = "Comment" })
  vim.api.nvim_set_hl(0, "DashTip", { link = "Comment" })
  vim.api.nvim_set_hl(0, "DashArrow", { link = "NonText" })
  vim.api.nvim_set_hl(0, "DashRule", { link = "NonText" })
end

vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("dashboard_teach_hl", { clear = true }),
  callback = set_highlights,
})
set_highlights() -- cover the case where the colorscheme is already applied

-- Section heading with a rule filling the rest of the pane. Width is measured rather than assumed
-- because nerd-font glyphs are not reliably one cell wide.
local function heading(cp, label)
  local icon = nf(cp)
  return {
    text = {
      { icon, hl = "DashMark" },
      { label .. " ", hl = "DashHead" },
      { ("─"):rep(math.max(0, CONTENT - vim.api.nvim_strwidth(icon .. label .. " "))), hl = "DashRule" },
    },
  }
end

-- One translation. No `key`, no `action`, so it is inert and cannot be mistaken for a shortcut.
local function row(vscode, lazyvim, desc)
  return {
    text = {
      { vscode, width = COL_OLD, align = "right", hl = "DashKeyOld" },
      { " → ", hl = "DashArrow" },
      { lazyvim, width = COL_NEW, align = "left", hl = "DashKeyNew" },
      { desc, width = COL_DESC, align = "left", hl = "normal" },
    },
  }
end

-- Two key/label pairs per line, used for the leader-group legend and the closing tips.
local function pair(key1, label1, key2, label2)
  return {
    text = {
      { key1, width = 7, align = "left", hl = "DashKeyNew" },
      { label1, width = 19, align = "left", hl = "normal" },
      { key2, width = 7, align = "left", hl = "DashKeyNew" },
      { label2, width = CONTENT - 33, align = "left", hl = "normal" },
    },
  }
end

return {
  "folke/snacks.nvim",
  opts = {
    dashboard = {
      width = WIDTH,
      pane_gap = PANE_GAP,
      -- Deliberately NOT setting preset.keys. lazy.nvim replaces list-like tables wholesale, and
      -- extras/editor/snacks_picker.lua does `table.insert(opts.dashboard.preset.keys, 3, ...)`
      -- from an opts *function*, which runs after the merge. Overriding the list would splice an
      -- uninvited Projects entry into position 3 of ours, and a list shorter than two entries would
      -- make that insert throw "position out of bounds". Leaving LazyVim's list untouched keeps the
      -- splice harmless, because the sections below never render `section = "keys"`.
      -- preset.header is skipped for the same reason: no `section = "header"` here.
      sections = {
        -- The thesis, stated once, before any list.
        {
          align = "center",
          padding = 1,
          text = { { "VS Code sends chords. LazyVim sends sequences.", hl = "DashTip" } },
        },
        {
          align = "center",
          padding = 1,
          text = {
            { "Ctrl+Shift+P", hl = "DashKeyOld" },
            { "   →   ", hl = "DashArrow" },
            { SPC .. " s C", hl = "DashKeyNew" },
          },
        },
        {
          align = "center",
          padding = 2,
          text = { { SPC .. " is Space, the leader key. Tap it and wait.", hl = "DashTip" } },
        },

        -- Pane 2 leads with the only keys that do anything here, so the eye lands on them first.
        -- Icons are the ones LazyVim's own preset uses, so they are known to exist in the font.
        {
          pane = 2,
          indent = INDENT,
          padding = 1,
          heading(0xF0E7, "Press a key now"),
          { icon = nf(0xF002), key = "f", desc = "Find file", action = ":lua Snacks.dashboard.pick('files')" },
          {
            icon = nf(0xF022),
            key = "g",
            desc = "Search in files",
            action = ":lua Snacks.dashboard.pick('live_grep')",
          },
          { icon = nf(0xF0C5), key = "r", desc = "Recent files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
          { icon = nf(0xF15B), key = "n", desc = "New file", action = ":ene | startinsert" },
          -- Resolves through the session section, which yields nothing if persistence is missing.
          { icon = nf(0xE348), key = "s", desc = "Restore session", section = "session" },
          {
            icon = nf(0xF423),
            key = "c",
            desc = "Config",
            action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})",
          },
          { icon = nf(0xF04B2), key = "l", desc = "Plugins (Lazy)", action = ":Lazy" },
          { icon = nf(0xF426), key = "q", desc = "Quit", action = ":qa" },
        },

        {
          pane = 1,
          indent = INDENT,
          padding = 1,
          heading(0xF002, "Navigate"),
          row("Ctrl+P", SPC .. " " .. SPC, "Find file"),
          row("Ctrl+Shift+F", SPC .. " /", "Search in files"),
          row("Ctrl+Shift+P", SPC .. " s C", "Command palette"),
          row("Ctrl+B", SPC .. " e", "File explorer"),
          row("Ctrl+Tab", SPC .. " ,", "Switch buffer"),
          row("Ctrl+W", SPC .. " b d", "Close buffer"),
        },

        -- The second thing to learn after "Space first": the letter after Space is a category.
        {
          pane = 2,
          indent = INDENT,
          padding = 1,
          heading(0xF11C, "After Space, pick a group"),
          pair(SPC .. " c", "code / LSP", SPC .. " g", "git"),
          pair(SPC .. " f", "find files", SPC .. " b", "buffers"),
          pair(SPC .. " s", "search", SPC .. " u", "toggles / UI"),
          pair(SPC .. " x", "diagnostics", SPC .. " d", "debug"),
        },

        {
          pane = 1,
          indent = INDENT,
          padding = 1,
          heading(0xF044, "Edit"),
          row("Ctrl+/", "g c c", "Comment line"),
          row("Ctrl+S", "Ctrl+S", "Save (same key)"),
          row("Alt+Up/Down", "Alt+K / Alt+J", "Move line"),
          row("Ctrl+Shift+H", SPC .. " s r", "Replace in files"),
        },

        {
          pane = 2,
          indent = INDENT,
          padding = 1,
          heading(0xF121, "Code intelligence"),
          row("F12", "g d", "Definition"),
          row("Shift+F12", "g r", "References"),
          row("Ctrl+K Ctrl+I", "K", "Hover docs"),
          row("F2", SPC .. " c r", "Rename symbol"),
          row("Ctrl+.", SPC .. " c a", "Code action"),
          row("Ctrl+Shift+M", SPC .. " x x", "Problems list"),
        },

        {
          pane = 1,
          indent = INDENT,
          padding = 1,
          heading(0xF126, "Git and terminal"),
          row("Ctrl+Shift+G", SPC .. " g g", "Lazygit"),
          row("Ctrl+`", "Ctrl+/", "Terminal"),
        },

        {
          pane = 1,
          indent = INDENT,
          padding = 1,
          heading(0xF0DB, "Windows"),
          row("Ctrl+\\", SPC .. " |   " .. SPC .. " -", "Split right/down"),
          row("Ctrl+K arrows", "Ctrl+H J K L", "Focus window"),
        },

        -- Point at the real reference so this screen stops being needed.
        {
          pane = 2,
          indent = INDENT,
          padding = 1,
          heading(0xF05A, "Good to know"),
          { text = { { "F-keys, Ctrl+P and Ctrl+B do nothing in LazyVim.", hl = "DashTip" } } },
          { text = { { "After " .. SPC .. ", which-key lists what can follow.", hl = "DashTip" } } },
          pair(SPC .. " ?", "buffer keymaps", SPC .. " s k", "all keymaps"),
        },

        { pane = 2, section = "startup", padding = { 0, 1 } },
      },
    },
  },
}
