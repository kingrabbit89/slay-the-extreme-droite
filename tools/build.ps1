param([switch]$Test, [switch]$Export)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
Push-Location $projectRoot
try {
    if ($Test) {
        cargo test -p tribune_rules --locked
        if ($LASTEXITCODE -ne 0) { throw 'Les tests Rust ont échoué.' }
    }
    cargo build -p tribune_godot --release --locked
    if ($LASTEXITCODE -ne 0) { throw 'La compilation Rust a échoué.' }
    New-Item -ItemType Directory -Force -Path 'demo/bin' | Out-Null
    Copy-Item -LiteralPath 'target/release/tribune_godot.dll' -Destination 'demo/bin/tribune_godot.dll'
    $godotExecutable = Join-Path $PSScriptRoot 'godot/Godot_v4.5-stable_win64_console.exe'
    if (-not (Test-Path -LiteralPath $godotExecutable)) { throw 'Godot 4.5 est attendu dans tools/godot.' }
    & $godotExecutable --headless --path demo --editor --import --quit
    if ($LASTEXITCODE -ne 0) { throw "L'import Godot a échoué." }
    if ($Export) {
        New-Item -ItemType Directory -Force -Path 'build/SlayTheExtremeDroite' | Out-Null
        & $godotExecutable --headless --path demo --export-release 'Windows Desktop' '../build/SlayTheExtremeDroite/SlayTheExtremeDroite.exe'
        if ($LASTEXITCODE -ne 0) { throw "L'export Windows a échoué." }
        Copy-Item -LiteralPath 'README.md' -Destination 'build/SlayTheExtremeDroite/LIRE-MOI.md'
        Copy-Item -LiteralPath 'docs' -Destination 'build/SlayTheExtremeDroite' -Recurse -Force
    }
} finally { Pop-Location }
