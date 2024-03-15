$here = $PSScriptRoot
$project_root = (Get-Item $here).Parent.FullName
$target = "debug"
$module_dir = "$project_root\target\$target"

if ($args[0] -eq "watch") {
    Push-Location $project_root
    try {
        cargo watch -s "powershell bin\build.ps1" -s "powershell bin\test.ps1"
    } finally {
        Pop-Location
    }
} else {
    # XXX: It seems that Emacs writes to stderr, so PowerShell thinks it's an error. Redirecting to
    # stdout alone doesn't help, because it's the processed stderr, which contain error records, not
    # the original stderr. Piping at the end to convert these error records into strings doesn't
    # work either.
    #
    # It's worth noting that the issue happens only on Azure Pipelines, with Windows 2019, probably
    # because of the execution mode being remote or something.
    #
    # https://mnaoumov.wordpress.com/2015/01/11/execution-of-external-commands-in-powershell-done-right/
    # https://github.com/PowerShell/JEA/issues/24
    # https://github.com/PowerShell/PowerShell/issues/4002
    # https://stackoverflow.com/questions/2095088/error-when-calling-3rd-party-executable-from-powershell-when-using-an-ide
    $ErrorActionPreference = 'Continue'
    $env:PROJECT_ROOT = $project_root
    $env:MODULE_DIR = $module_dir
    $env:EMACS_MODULE_RS_DEBUG = 1
    emacs --version
    emacs --batch --directory "$module_dir" `
      -l ert `
      -l "$project_root\test-module\tests\main.el" `
      -f ert-run-tests-batch-and-exit
}
