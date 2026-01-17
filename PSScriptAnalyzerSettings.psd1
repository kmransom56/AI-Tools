
@{
    Rules = @(
        'PSAvoidUsingWriteHost',              # Prefer Write-Output or logging
        'PSAvoidUsingCmdletAliases',          # Avoid aliases for clarity
        'PSAvoidUsingPlainTextForPassword',   # Security best practice
        'PSAvoidUsingConvertToSecureStringWithPlainText', # Security
        'PSUseConsistentIndentation',         # Code readability
        'PSUseConsistentWhitespace',          # Formatting
        'PSUseCorrectCasing',                 # Cmdlet casing
        'PSUseDeclaredVarsMoreThanAssignments', # Avoid unused variables
        'PSAvoidUsingEmptyCatchBlock',        # Ensure error handling
        'PSAvoidUsingInvokeExpression',       # Prevent injection risks
        'PSAvoidUsingPositionalParameters',   # Explicit parameter names
        'PSAvoidUsingHardcodedCredentials',   # Security
        'PSUseApprovedVerbs',                 # Consistent naming
        'PSAvoidGlobalVars',                  # Avoid global state
        'PSAvoidUsingDeprecatedManifestFields' # Module hygiene
    )

    ExcludeRules = @(
        # Add rules you want to relax for your team
    )

    Severity = @{
        PSAvoidUsingPlainTextForPassword = 'Error'
        PSAvoidUsingInvokeExpression = 'Error'
        PSAvoidUsingHardcodedCredentials = 'Error'
        PSUseConsistentIndentation = 'Warning'
        PSUseConsistentWhitespace = 'Warning'
    }

    IncludeRules = @()
}
