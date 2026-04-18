return {
  root_dir = function(bufnr, on_dir)
    local root = vim.fs.root(bufnr, { 'deno.json', 'deno.jsonc' })

    if root then
      on_dir(root)
    end
  end,
  settings = {
    javascript = {
      suggest = { completeFunctionCalls = true },
    },
    typescript = {
      suggest = { completeFunctionCalls = true },
    },
    deno = {
      suggest = {
        autoImports = true,
        imports = {
          autoDiscover = true,
        },
        names = true,
        paths = true,
      },
    },
  },
}
