-- Make highlight groups transparent while preserving their other attributes

-- Capture the active colorscheme's editor background BEFORE make_transparent
-- clears it below. Used as the dim shade so the editor surface fully tracks
-- the current theme (Solarized Osaka, TokyoNight, Catppuccin, ...). Captured
-- in order: Normal.bg, NormalNC.bg, WinSeparator.bg, WinSeparator.fg.
local function capture_theme_shade()
  for _, name in ipairs({ "Normal", "NormalNC", "WinSeparator" }) do
    local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
    if ok then
      if hl.bg and hl.bg ~= 0 then
        return hl.bg
      end
      if name == "WinSeparator" and hl.fg and hl.fg ~= 0 then
        return hl.fg
      end
    end
  end
  return nil
end

local theme_shade = capture_theme_shade()

local function make_transparent(name)
  local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
  if ok then
    hl.bg = nil
    vim.api.nvim_set_hl(0, name, hl)
  end
end

-- Reduce wallpaper intensity: instead of fully transparent Normal, lay a dim
-- dark shade over the background so the wallpaper becomes a subtle texture.
-- The blend value controls how much of the wallpaper shows through: lower =
-- more wallpaper visible. Tunable via `vim.g.editor_blend` (default 15).
-- The shade tracks the active colorscheme (captured at file load above) so it
-- follows every Omarchy theme hot-reload without any plugin-side work.
-- Sync editor blend with the host Kitty window so the editor surface and the rest of the terminal blend identically. Kitty's opacity is the inverse of
-- editor_blend (opacity = 1 - blend/100). Skipped automatically when Kitty is
-- unreachable (no socket, SSH session, etc.); set
-- `vim.g.editor_blend_sync_kitty = false` to opt out.
local function push_blend_to_kitty(blend)
  if vim.g.editor_blend_sync_kitty == false then
    return
  end
  local opacity = math.max(0, math.min(100, blend)) / 100
  pcall(function()
    vim
      .system({ "kitty", "@", "set-background-opacity", tostring(opacity) }, { text = true })
      :wait(500)
  end)
end

local function dim_background()
  -- Prefer the theme's own editor background. WinSeparator.fg is an accent
  -- after ui-polish, so only use it if capture failed.
  local shade = theme_shade
  if not shade or shade == 0 then
    local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = "WinSeparator", link = false })
    shade = ok and hl.fg or nil
  end
  if not shade or shade == 0 then
    shade = 1973790 -- rough #1e2429 dark teal-grey
  end
  local blend = tonumber(vim.g.editor_blend) or 15
  vim.g.editor_blend = blend
  local painted = {
    "Normal",
    "NormalNC",
    "EndOfBuffer",
    "MsgArea",
    "NeoTreeNormal",
    "NeoTreeNormalNC",
    "NeoTreeEndOfBuffer",
    "NeoTreeTitleBar",
    "NeoTreeStatusLineNC",
    "NeoTreeTabActive",
    "NeoTreeTabInactive",
    "NvimTreeNormal",
    "NvimTreeEndOfBuffer",
  }
  for _, name in ipairs(painted) do
    local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
    hl = ok and hl or {}
    hl.bg = shade
    hl.blend = blend
    vim.api.nvim_set_hl(0, name, hl)
  end
  push_blend_to_kitty(blend)
end

local groups = {
  -- transparent background
  "Normal",
  "NormalFloat",
  "FloatBorder",
  "Pmenu",
  "Terminal",
  "EndOfBuffer",
  "FoldColumn",
  "Folded",
  "SignColumn",
  "LineNr",
  "CursorLineNr",
  "NormalNC",
  "StatusLine",
  "StatusLineNC",
  "TabLine",
  "TabLineFill",
  "TabLineSel",
  "BufferLineFill",
  "BufferLineBackground",
  "WhichKeyFloat",
  "TelescopeBorder",
  "TelescopeNormal",
  "TelescopePromptBorder",
  "TelescopePromptTitle",
  -- neotree
  "NeoTreeNormal",
  "NeoTreeNormalNC",
  "NeoTreeVertSplit",
  "NeoTreeWinSeparator",
  "NeoTreeEndOfBuffer",
  "NeoTreeTitleBar",
  "NeoTreeStatusLineNC",
  "NeoTreeTabActive",
  "NeoTreeTabInactive",
  "NeoTreeTabSeparatorActive",
  "NeoTreeTabSeparatorInactive",
  -- nvim-tree
  "NvimTreeNormal",
  "NvimTreeVertSplit",
  "NvimTreeEndOfBuffer",
  -- notify
  "NotifyINFOBody",
  "NotifyERRORBody",
  "NotifyWARNBody",
  "NotifyTRACEBody",
  "NotifyDEBUGBody",
  "NotifyINFOTitle",
  "NotifyERRORTitle",
  "NotifyWARNTitle",
  "NotifyTRACETitle",
  "NotifyDEBUGTitle",
  "NotifyINFOBorder",
  "NotifyERRORBorder",
  "NotifyWARNBorder",
  "NotifyTRACEBorder",
  "NotifyDEBUGBorder",
  -- rainbow-delimiters
  "RainbowDelimiter1",
  "RainbowDelimiter2",
  "RainbowDelimiter3",
  "RainbowDelimiter4",
  "RainbowDelimiter5",
  "RainbowDelimiter6",
}

for _, name in ipairs(groups) do
  make_transparent(name)
end

-- Reapply transparency on demand and cycle blend for fast tuning.
local cycle = { 0, 5, 15, 30, 50 }
vim.keymap.set("n", "<leader>tt", function()
  local cur = tonumber(vim.g.editor_blend) or cycle[1]
  local idx = 1
  for i, v in ipairs(cycle) do
    if v == cur then
      idx = (i % #cycle) + 1
      break
    end
  end
  vim.g.editor_blend = cycle[idx]
  dim_background()
end, { desc = "Cycle editor blend and Kitty opacity" })

vim.api.nvim_create_user_command("EditorTransparency", function(opts)
  local v = tonumber(opts.args)
  if v then
    vim.g.editor_blend = math.max(0, math.min(100, v))
    dim_background()
  else
    local cur = tonumber(vim.g.editor_blend) or 15
    print(string.format("editor_blend=%d  Kitty opacity=%.2f", cur, 1 - cur / 100))
  end
end, { nargs = "?", desc = "Set/show editor blend (0-100; 0 = fully transparent)" })

-- Dim the wallpaper so it reads as a subtle background texture. Must run after
-- the transparent groups above (and after the colorscheme is applied) so the
-- derived shade is correct.
dim_background()

vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("editor-transparency", { clear = true }),
  callback = function()
    theme_shade = capture_theme_shade()
    for _, name in ipairs(groups) do
      make_transparent(name)
    end
    dim_background()
  end,
})
