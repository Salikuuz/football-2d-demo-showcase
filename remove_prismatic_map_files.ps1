$ErrorActionPreference = "SilentlyContinue"
Remove-Item -Force ".\Assets\generated_fields\map_24_preview.png"
Remove-Item -Force ".\Assets\generated_fields\map_24_preview.png.import"
Remove-Item -Force ".\Assets\generated_fields\map_24_surface.png"
Remove-Item -Force ".\Assets\generated_fields\map_24_surface.png.import"
Write-Host "Prismatic Mosaic map files removed. Previous map state restored." -ForegroundColor Green
