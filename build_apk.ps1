# PowerShell wrapper for automatic version bumping and release APK building
param(
    [switch]$BuildOnly,
    [switch]$Minor,
    [switch]$Major,
    [switch]$NoBuild,
    [switch]$SplitPerAbi
)

$argsList = @()
if ($BuildOnly) { $argsList += "--build-only" }
if ($Minor) { $argsList += "--minor" }
if ($Major) { $argsList += "--major" }
if ($NoBuild) { $argsList += "--no-build" }
if ($SplitPerAbi) { $argsList += "--split-per-abi" }

dart run tool/bump_and_build.dart $argsList
