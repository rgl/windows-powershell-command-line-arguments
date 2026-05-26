param(
    [string]$message,
    [string]$commandLine
)

@{
    message = $message
    commandLine = $commandLine
    args = $args
} | ConvertTo-Json -Depth 100
