return {
  before_init = require('neodev.lsp').before_init,
  settings = {
    Lua = {
      runtime = { version = 'LuaJIT' },
      telemetry = { enable = false },
      workspace = { checkThirdParty = false },
    },
  },
}
