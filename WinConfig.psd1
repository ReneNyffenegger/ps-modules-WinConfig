@{
   RootModule         = 'WinConfig.psm1'
   ModuleVersion      = '0.1'

   RequiredModules    = @(
   )

   RequiredAssemblies = @(
   )

   FunctionsToExport  = @(
      'set-environmentVariable', 'clear-environmentVariable',  # Set/remove an environment variable
      'add-dirToPath'               ,                          # Add a directory to the PATH environment variable
      'remove-dirFromPath'          ,                          # Remove a directory from the PATH environment variable
      'add-toPathExt'               ,                          # Add an extension environment variable PATHEXT
      'publish-environmentVariables',                          # Apply changes to environment variables (send WM_WININICHANGE with SendMessageTimeout)
      'hide-NewsAndInterest'                                   # Hide 'News and Interest' from the Taskbar
   )

   ScriptsToProcess   = @(
   )

   AliasesToExport    = @(
   )
}
