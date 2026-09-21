-- Startup dashboard (snacks.nvim), rebuilt as a VS Code -> LazyVim translation table.
--
-- The LazyVim ASCII logo used to be blanked out here, which left the most valuable screen in the
-- session doing nothing. It now opens with a boxed header naming the project, then carries the one
-- idea a VS Code refugee has to internalise on day one: VS Code presses keys *together* (chords),
-- LazyVim presses them *in sequence* (Space, then a mnemonic). Everything below is reference
-- material, not a launcher.
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

-- Boxed header. Box-drawing characters are BMP rather than private use area, so unlike the icons
-- above they are safe to write literally and need no nr2char round trip. The width adapts to the
-- longest content line but is clamped under 30 columns, so the box still fits a narrow tmux split
-- or a vertical editor split without the borders wrapping.
local BOX_MAX = 29
local BOX_MIN = 22
local BOX_PAD = 1
local SUBTITLE = "Welcome to LazyVim, Nerd!"

-- Honest project name: whatever directory nvim was opened in, shortened against $HOME. Falls back
-- to a literal if the cwd cannot be read, so the header never renders half-built.
local function project_name()
  local ok, name = pcall(function()
    return vim.fn.fnamemodify(vim.fn.getcwd(), ":~")
  end)
  if not ok or type(name) ~= "string" or name == "" then
    return "nvim"
  end
  return name
end

-- Trim from the left: the directory you are sitting in matters more than the path leading to it.
-- Measured in cells, not bytes, because the title comes from the filesystem and can hold anything.
local function truncate_left(str, max)
  if vim.api.nvim_strwidth(str) <= max then
    return str
  end
  local chars, kept = vim.fn.split(str, "\\zs"), ""
  for i = #chars, 1, -1 do
    if vim.api.nvim_strwidth(chars[i] .. kept) + 1 > max then
      break
    end
    kept = chars[i] .. kept
  end
  return "…" .. kept
end

local function header_box()
  local title = project_name()
  local lines = { SUBTITLE }
  -- Only wrap when the clamp genuinely forces it. At 29 columns the subtitle fits on one line, so
  -- this stays dormant unless the text or the clamp changes; the break then follows the comma.
  if vim.api.nvim_strwidth(SUBTITLE) + BOX_PAD * 2 + 2 > BOX_MAX then
    local head, tail = SUBTITLE:match("^(.-,)%s*(.+)$")
    if head then
      lines = { head, tail }
    end
  end

  local width = BOX_MIN
  for _, line in ipairs(lines) do
    width = math.max(width, vim.api.nvim_strwidth(line) + BOX_PAD * 2 + 2)
  end
  -- "╭─ " + title + " " + at least one "─" + "╮" is the title width plus 6.
  width = math.max(BOX_MIN, math.min(BOX_MAX, math.max(width, vim.api.nvim_strwidth(title) + 6)))
  local inner = width - 2
  title = truncate_left(title, width - 6)

  -- Every row is exactly `width` cells, so centring each item independently still lines the
  -- borders up underneath each other.
  local function framed(text)
    local pad = inner - vim.api.nvim_strwidth(text)
    local before = math.floor(pad / 2)
    return {
      text = {
        { "│", hl = "DashRule" },
        { (" "):rep(before) .. text .. (" "):rep(pad - before), hl = "normal" },
        { "│", hl = "DashRule" },
      },
    }
  end

  local box = { align = "center", padding = 1 }
  table.insert(box, {
    text = {
      { "╭─ ", hl = "DashRule" },
      { title, hl = "DashHead" },
      { " " .. ("─"):rep(width - 5 - vim.api.nvim_strwidth(title)) .. "╮", hl = "DashRule" },
    },
  })
  table.insert(box, framed(""))
  for _, line in ipairs(lines) do
    table.insert(box, framed(line))
  end
  table.insert(box, framed(""))
  table.insert(box, { text = { { "╰" .. ("─"):rep(inner) .. "╯", hl = "DashRule" } } })
  return box
end

-- Vertical budget.
--
-- snacks centres the dashboard by prepending blank lines:
--   row = max(floor((window_height - #lines) / 2), 0)   (snacks/dashboard.lua, D:render)
-- The clamp is the whole problem. As soon as the content is as tall as the window, row hits 0, the
-- first line pins to the top of the terminal and everything past the last visible row is dropped.
-- Nothing scrolls, it is simply not drawn. Adding blank lines above therefore makes it worse: they
-- count towards #lines and push row further into the clamp.
--
-- So the fix is the other direction. Render fewer lines than the window has, and snacks' own
-- centring hands back the top margin for free. TOP_MARGIN is reserved at both ends, which leaves
-- floor(2 * TOP_MARGIN / 2) = TOP_MARGIN blank rows above in the worst case.
local TOP_MARGIN = 2

-- Rendered height of one section, padding included. Every item built in this file is exactly one
-- line tall, so counting children is exact rather than an estimate. snacks stores padding as
-- { below, above }, and a bare number means { n, 0 }.
local function section_cost(section)
  local pad = type(section.padding) == "table" and section.padding or { section.padding or 0, 0 }
  return math.max(#section, 1) + pad[1] + pad[2]
end

-- Everything the dashboard can show, in declaration order. Panes alternate so that a terminal too
-- narrow for two columns still reads top-to-bottom in a sensible order. Rebuilt on every render
-- because snacks' resolve() mutates the tables it walks, and because the project name in the
-- header comes from the cwd.
local function all_blocks()
  return {
    -- Boxed header, centred in pane 1. The project name lives in the top border so it costs no
    -- extra line.
    { id = "header", section = header_box() },

    -- The thesis. Two centred lines: one asserts the idea, one demonstrates it.
    {
      id = "thesis",
      section = {
        align = "center",
        padding = 1,
        text = { { "VS Code sends chords. LazyVim sends sequences.", hl = "DashTip" } },
      },
    },
    -- The demo outlives the assertion above: it shows the translation instead of only claiming it.
    {
      id = "demo",
      section = {
        align = "center",
        padding = 1,
        text = {
          { "Ctrl+Shift+P", hl = "DashKeyOld" },
          { "  →  ", hl = "DashArrow" },
          { SPC .. " s C", hl = "DashKeyNew" },
          { "    " .. SPC .. " = Space, the leader key", hl = "DashTip" },
        },
      },
    },

    -- Pane 2 leads with the only keys that do anything here, so the eye lands on them first.
    -- Icons are the ones LazyVim's own preset uses, so they are known to exist in the font.
    {
      id = "launcher",
      section = {
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
    },

    {
      id = "navigate",
      section = {
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
    },

    -- The second thing to learn after "Space first": the letter after Space is a category.
    {
      id = "groups",
      section = {
        pane = 2,
        indent = INDENT,
        padding = 1,
        -- The glyph is named in the heading so this block still reads on its own once the demo
        -- line above has been dropped by the fitting pass.
        heading(0xF11C, "After ␣ (Space), pick a group"),
        pair(SPC .. " c", "code / LSP", SPC .. " g", "git"),
        pair(SPC .. " f", "find files", SPC .. " b", "buffers"),
        pair(SPC .. " s", "search", SPC .. " u", "toggles / UI"),
        pair(SPC .. " x", "diagnostics", SPC .. " d", "debug"),
      },
    },

    {
      id = "edit",
      section = {
        pane = 1,
        indent = INDENT,
        padding = 1,
        heading(0xF044, "Edit"),
        row("Ctrl+/", "g c c", "Comment line"),
        row("Ctrl+S", "Ctrl+S", "Save (same key)"),
        row("Alt+Up/Down", "Alt+K / Alt+J", "Move line"),
        row("Ctrl+Shift+H", SPC .. " s r", "Replace in files"),
      },
    },

    {
      id = "code",
      section = {
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
    },

    -- Git, terminal and window handling used to carry a heading each. Four bindings did not earn
    -- two headings and two padding rows, so they share one block now.
    {
      id = "shell",
      section = {
        pane = 1,
        indent = INDENT,
        padding = 1,
        heading(0xF126, "Git, terminal and windows"),
        row("Ctrl+Shift+G", SPC .. " g g", "Lazygit"),
        row("Ctrl+`", "Ctrl+/", "Terminal"),
        row("Ctrl+\\", SPC .. " |   " .. SPC .. " -", "Split right/down"),
        row("Ctrl+K arrows", "Ctrl+H J K L", "Focus window"),
      },
    },

    -- Point at the real reference so this screen stops being needed.
    {
      id = "tips",
      section = {
        pane = 2,
        indent = INDENT,
        padding = 1,
        heading(0xF05A, "Good to know"),
        { text = { { "F-keys, Ctrl+P and Ctrl+B do nothing in LazyVim.", hl = "DashTip" } } },
        { text = { { "After " .. SPC .. ", which-key lists what can follow.", hl = "DashTip" } } },
        pair(SPC .. " ?", "buffer keymaps", SPC .. " s k", "all keymaps"),
      },
    },

    { id = "startup", section = { pane = 2, section = "startup", padding = { 0, 1 } } },
  }
end

-- Progressive disclosure, least essential first. "launcher" is absent on purpose: the eight
-- pressable keys are the only interactive thing on the screen, so they are never dropped.
--
-- The order is an argument about teaching value, not about line count:
--   tips, thesis  prose. Says things the rest of the screen already demonstrates.
--   shell         four bindings a beginner reaches for last.
--   edit          useful, but Ctrl+S already works and comments are discoverable.
--   startup       vanity line.
--   code, navigate  the cheatsheet proper. Bulk of the height, so it goes before the legends.
--   demo          the only line that explains what ␣ means.
--   groups        the generalisable mental model: after Space, the next letter is a category.
--   header        identity, and cheap at six lines.
local DROP_ORDER = { "tips", "thesis", "shell", "edit", "startup", "code", "navigate", "demo", "groups", "header" }

-- Height-adaptive section list.
--
-- Width and height are not independent here. Below 116 columns snacks collapses to one pane, which
-- stacks pane 2 underneath pane 1 and roughly doubles the rendered height, so the same window
-- needs a stricter tier when it is narrow. Rather than tier the two axes separately, this measures
-- the layout snacks is actually going to produce: per-pane sums at two panes, one big sum at one
-- pane, then drops blocks until the tallest pane fits the budget.
--
-- Dropping always targets the tallest pane. Removing a pane 1 block while pane 2 is the tall one
-- would cost content and buy no height at all.
local function sections_for(self)
  local size = self and self._size or { width = vim.o.columns, height = vim.o.lines }
  local panes = math.max(1, math.floor((size.width + PANE_GAP) / (WIDTH + PANE_GAP)))
  local budget = size.height - TOP_MARGIN * 2

  local blocks, by_id = all_blocks(), {}
  for _, block in ipairs(blocks) do
    block.pane = (((block.section.pane or 1) - 1) % panes) + 1
    block.cost = section_cost(block.section)
    by_id[block.id] = block
  end

  local dropped = {}
  for _ = 1, #DROP_ORDER do
    local heights, tallest = {}, 1
    for _, block in ipairs(blocks) do
      if not dropped[block.id] then
        heights[block.pane] = (heights[block.pane] or 0) + block.cost
        if heights[block.pane] > (heights[tallest] or 0) then
          tallest = block.pane
        end
      end
    end
    if (heights[tallest] or 0) <= budget then
      break
    end
    -- Prefer the most expendable block in the tallest pane; fall back to the most expendable
    -- block anywhere when that pane holds nothing droppable.
    local victim, fallback
    for _, id in ipairs(DROP_ORDER) do
      if not dropped[id] then
        fallback = fallback or id
        if by_id[id].pane == tallest then
          victim = id
          break
        end
      end
    end
    victim = victim or fallback
    if not victim then
      break
    end
    dropped[victim] = true
  end

  local sections = {}
  for _, block in ipairs(blocks) do
    if not dropped[block.id] then
      table.insert(sections, block.section)
    end
  end
  return sections
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
      --
      -- One function section rather than a static list. snacks calls function sections as
      -- `item(self)` from D:resolve, and D:update refreshes self._size before resolving, so this
      -- sees the real window size. Resize re-renders (D:init deep-compares _size on WinResized),
      -- which means dragging a tmux split re-picks the tier instead of leaving stale content.
      sections = { sections_for },
    },
  },
}
