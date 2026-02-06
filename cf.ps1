# ===============================
# Usage: ./create_feature.ps1 auth
# Run from Flutter project root
# ===============================

param (
    [Parameter(Mandatory = $true)]
    [string]$feature
)

$base = "lib/features/$feature"

$folders = @(
    "data/datasources",
    "data/models",
    "data/repositories",
    "domain/entities",
    "domain/repositories",
    "domain/usecases",
    "presentation/controllers",
    "presentation/pages",
    "presentation/widgets",
    "presentation/bindings"
)

$files = @(
    "data/datasources/${feature}_remote_data_source.dart",
    "data/models/${feature}_model.dart",
    "data/repositories/${feature}_repository_impl.dart",
    "domain/entities/${feature}_entity.dart",
    "domain/repositories/${feature}_repository.dart",
    "domain/usecases/${feature}_usecase.dart",
    "presentation/controllers/${feature}_controller.dart",
    "presentation/pages/${feature}_page.dart",
    "presentation/widgets/${feature}_widget.dart",
    "presentation/bindings/${feature}_binding.dart"
)

foreach ($folder in $folders) {
    New-Item -ItemType Directory -Path "$base/$folder" -Force | Out-Null
}

foreach ($file in $files) {
    New-Item -ItemType File -Path "$base/$file" -Force | Out-Null
}

Write-Host "Clean architecture feature '$feature' with binding created successfully!"
