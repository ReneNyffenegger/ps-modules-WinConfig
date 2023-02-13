set-strictMode -version 3

function set-environmentVariable {

   param(
      [string] $name,
      [string] $value,
      [switch] $machine
   )

   [EnvironmentVariableTarget] $tgt = 'user'
   if ($machine) {             $tgt = 'machine' }

   [environment]::setEnvironmentVariable($name, $value, $tgt)
 #  Add new value also to process so that it is immediately available
   [environment]::setEnvironmentVariable($name, $value, 'process')

   publish-environmentVariables
}

function remove-environmentVariable {

   param(
      [string] $name,
      [switch] $machine
   )

   [EnvironmentVariableTarget] $tgt = 'user'
   if ($machine) {             $tgt = 'machine' }

   [environment]::setEnvironmentVariable($name, '', $tgt)

   invoke-expression "`$env:$name = ''"
   publish-environmentVariables
}

function add-dirToPath {

   param(
      [string]                    $dir,
      [switch]                    $machine,
    # [EnvironmentVariableTarget] $tgt = 'user', # or 'machine' (but probably not 'process')
      [switch]                    $psModulePath
   )

   if (-not (test-path -pathType container $dir) ) {
      write-textInConsoleWarningColor "Directory $dir does not exist"
      return
   }

  [EnvironmentVariableTarget] $tgt = 'user'
   if ($machine) {
      $tgt = 'machine'
   }

   $envVar = 'PATH'
   if ($psModulePath) {
      $envVar = 'PSModulePath'
   }

   $path = [environment]::getEnvironmentVariable($envVar, $tgt)
  [environment]::setEnvironmentVariable($envVar, "$dir;$path", $tgt)

   $pathBoth = [environment]::getEnvironmentVariable($envVar, 'machine') + ';' + [environment]::getEnvironmentVariable($envVar, 'user')
  [environment]::setEnvironmentVariable($envVar, $pathBoth, 'process')

   publish-environmentVariables
}

function add-toPathExt {

 #
 # TODO: apparently, the user's PATHEXT value shadows the system's value (if the user's is set)
 #

   param(
      [string] $ext
   )

   if ($ext -notMatch '^\.') {
      $ext = ".$ext"
   }

   $ext = $ext.ToUpper()

#  if ([System.Environment]::GetEnvironmentVariable('PATHEXT', 'user')) {
#     write-textInConsoleWarningColor "PATHEXT is shadowed by user variable"
#  }

   $cur_exts_reg = [System.Environment]::GetEnvironmentVariable('PATHEXT', 'user')


   $cur_exts_ary = $cur_exts_reg -split ';'
   if ($cur_exts_ary.Contains($ext)) {
      write-host "$ext is already in PATHEXT"
      return
   }

   $pathext = "$cur_exts_reg;$ext"
  [Environment]::SetEnvironmentVariable('PATHEXT', $pathext, 'user')

   invoke-expression "`$env:PATHEXT = '$pathext'"
   publish-environmentVariables

}

function remove-dirFromPath {

   param(
      [string]                    $dir,
      [EnvironmentVariableTarget] $tgt = 'user'
   )

 #
 # The parameter firstOnly is used to remove only one
 # occurence of the directory.
 # It is indended to be used if a directory has
 # duplicate entries in the PATH environment variable.
 #

   $pathsOld = [environment]::getEnvironmentVariable('PATH', $tgt) -split ';'
   $pathsNew = @()

   foreach ($dir_ in $pathsOld) {
      if (-not ($dir_ -eq $dir)) {
         $pathsNew += $dir_
      }
   }

   $pathsNew -join ';'

  [environment]::setEnvironmentVariable('PATH', ($pathsNew -join ';'), $tgt)

#  invoke-expression "`$env:PATH = '$([environment]::getEnvironmentVariable('PATH', 'machine'));$([environment]::getEnvironmentVariable('PATH', 'machine'))'"
   publish-environmentVariables
}

function hide-NewsAndInterest {

   set-itemProperty hkcu:\SOFTWARE\Microsoft\Windows\CurrentVersion\Feeds ShellFeedsTaskbarViewMode 2

}

function publish-environmentVariables {
 #
 #  https://renenyffenegger.ch/notes/Windows/registry/environment-variables
 #  https://github.com/ReneNyffenegger/about-Windows-Registry/blob/master/HKEY_CURRENT_USER/Environment/apply-changes.ps1
 #

    $funcDef = @'

    [DllImport("user32.dll", SetLastError = true, CharSet=CharSet.Auto)]

     public static extern IntPtr SendMessageTimeout (
        IntPtr     hWnd,
        uint       msg,
        UIntPtr    wParam,
        string     lParam,
        uint       fuFlags,
        uint       uTimeout,
    out UIntPtr    lpdwResult
     );

'@

   $funcRef = add-type -namespace WinAPI -name functions -memberDefinition $funcDef

   $HWND_BROADCAST   = [intPtr] 0xFFFF
   $WM_SETTINGCHANGE =          0x001A  # Same as WM_WININICHANGE
   $fuFlags          =               2  # SMTO_ABORTIFHUNG: return if receiving thread does not respond (hangs)
   $timeOutMs        =            1000  # Timeout in milli seconds
   $res              = [uIntPtr]::zero

 #
 # If the function succeeds, this value is non-zero.
 #
   $funcVal = [WinAPI.functions]::SendMessageTimeout($HWND_BROADCAST, $WM_SETTINGCHANGE, [UIntPtr]::zero, "Environment", $fuFlags, $timeOutMs, [ref] $res);

   if ($funcVal -eq 0) {
      write-host "SendMessageTimeout did not succeed, res= $res"
   }

}
