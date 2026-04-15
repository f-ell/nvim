return {
  root_dir = function(bufnr, on_dir)
    local root = vim.fs.root(bufnr, { 'deno.json', 'deno.jsonc' })

    if root then
      on_dir(root)
    end
  end,
  settings = {
    deno = {
      suggest = {
        autoImports = true,
        completeFunctionCalls = true,
        imports = {
          autoDiscover = true,
          hosts = true,
        },
        names = true,
        paths = true,
      },
      lint = true,
    },
  },
}
