return {
  cmd = { 'perlnavigator' },
  settings = {
    perlnavigator = {
      perlPath = 'perl',
      enableWarnings = true,
      perltidyProfile = '$workspaceFolder/.perltidyrc',
      perlcriticProfile = '$workspaceFolder/.perlcriticrc',
      perlcriticEnabled = true,
    },
  },
}
