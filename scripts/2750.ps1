function New-TiedVariable {
#.Synopsis
#   Creates a ReadOnly variable that recalculates it's value each time it's read
#.Description
#   Create a variable tied to a scriptblock by using a breakpoint ;-)
#.Notes
#   New-TiedVariable uses breakpoints to trigger the automatic recalculation of the variables, so the use of a command like Get-PSBreakPoint | Remove-PSBreakPoint will break any variables created using New-TiedVariable
param(
    # The name of the variable to create
    [String]$Name,
    # The scriptblock to use to calculate the value each time
    [ScriptBlock]$Value
)
    Set-Variable $Name -Value (.$Value) -Option ReadOnly, AllScope -Scope Global -Force

    $null = Set-PSBreakpoint -Variable $Name -Mode Read -Action {
        Set-Variable $Name (. $Value) -Option ReadOnly, AllScope -Scope Global -Force
    }.GetNewClosure()
}

