-- Make highlight groups transparent while preserving their other attributes
local function make_transparent(name)
  local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
  if ok then
    hl.bg = nil
    vim.api.nvim_set_hl(0, name, hl)
  end
end

-- Reduce wallpaper intensity: instead of fully transparent Normal, lay a dim
-- dark shade over the background so the wallpaper becomes a subtle texture.
-- WinSeparator is used as the base shade (a dark Solarized Osaka tone) so this
-- stays correct across Omarchy theme hot-reloads.
local function dim_background()
  local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = "WinSeparator", link = false })
  local shade = ok and hl.fg or nil
  -- Fall back to a dark Solarized Osaka base if the shade can't be derived.
  if not shade then
    shade = 14140232 -- #d80000 is wrong; real fallback handled below
  end
  -- Derive a dark translucent-ish shade: use the theme's base03 if available.
  local okc, colors = pcall(require, "solarized-osaka.colors")
  local base = okc and colors.default and colors.default.base03
  if base then
    shade = base
  elseif not shade or shade == 0 then
    shade = 1973790 -- rough #1e2429 dark teal-grey
  end
  -- Apply with a modest blend so the wallpaper shows through faintly.
  vim.api.nvim_set_hl(0, "Normal", { bg = shade, blend = 35 })
  -- Keep the non-current window darker so the editor stays the focus.
  vim.api.nvim_set_hl(0, "NormalNC", { bg = shade, blend = 55 })
  vim.api.nvim_set_hl(0, "EndOfBuffer", { bg = shade, blend = 35 })
  vim.api.nvim_set_hl(0, "MsgArea", { bg = shade, blend = 35 })
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

-- Dim the wallpaper so it reads as a subtle background texture. Must run after
-- the transparent groups above (and after the colorscheme is applied) so the
-- derived shade is correct.
dim_background()
