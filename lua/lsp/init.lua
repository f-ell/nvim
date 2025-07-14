-- inspired by glepnir's lspsaga: https://github.com/nvimdev/lspsaga.nvim

return {
  cda = require('lsp.code_action'),
  def = require('lsp.definition'),
  dgn = require('lsp.diagnostic'),
  ren = require('lsp.rename'),
  sig = require('lsp.signature_help'),
}
