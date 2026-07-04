---@type vim.lsp.Config
return {
  ---@type lspconfig.settings.lua_ls
  settings = {
    Lua = {
      runtime = { version = 'LuaJIT' },
      telemetry = { enable = false },
      workspace = {
        checkThirdParty = false,
        library = { '/usr/share/hypr/stubs' },
      },
    },
  },
}
