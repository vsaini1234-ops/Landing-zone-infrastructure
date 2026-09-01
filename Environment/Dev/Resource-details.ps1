param(
    [string]$CsvFile = (Join-Path $PSScriptRoot "dev_auto_resources.csv"),
    [string]$TfvarsFile = (Join-Path $PSScriptRoot "terraform.tfvars")
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host " Resource Details -> terraform.tfvars" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# -------------------------------------------------
# Check CSV file
# -------------------------------------------------

if (-not (Test-Path -LiteralPath $CsvFile)) {
    Write-Host "ERROR: CSV file not found!" -ForegroundColor Red
    Write-Host "Path: $CsvFile" -ForegroundColor Red
    exit 1
}

Write-Host "CSV File    : $CsvFile"
Write-Host "TFVars File : $TfvarsFile"
Write-Host ""

# -------------------------------------------------
# Import CSV
# -------------------------------------------------

$resources = Import-Csv -LiteralPath $CsvFile

if ($resources.Count -eq 0) {
    Write-Host "ERROR: CSV file is empty." -ForegroundColor Red
    exit 1
}

# -------------------------------------------------
# Initialize maps
# -------------------------------------------------

$resourceGroups  = [ordered]@{}
$storageAccounts = [ordered]@{}
$vnets           = [ordered]@{}
$subnets         = [ordered]@{}

# -------------------------------------------------
# Process Resources
# -------------------------------------------------

foreach ($resource in $resources) {

    switch ($resource.ResourceType.Trim()) {

        "ResourceGroup" {

            $resourceGroups[$resource.Key] = [ordered]@{
                name     = $resource.Name
                location = $resource.Location
            }
        }

        "StorageAccount" {

            $storageAccounts[$resource.Key] = [ordered]@{
                name                      = $resource.Name
                resource_group_name       = $resource.ResourceGroupName
                location                  = $resource.Location
                account_tier              = $resource.AccountTier
                account_replication_type  = $resource.AccountReplicationType
            }
        }

        "VNet" {

            $vnets[$resource.Key] = [ordered]@{
                name                = $resource.Name
                resource_group_name = $resource.ResourceGroupName
                location            = $resource.Location
                address_space       = $resource.AddressSpace
            }
        }

        "Subnet" {

            $subnets[$resource.Key] = [ordered]@{
                name                 = $resource.Name
                resource_group_name  = $resource.ResourceGroupName
                virtual_network_name = $resource.VirtualNetworkName
                address_prefixes     = $resource.AddressPrefixes
            }
        }

        default {

            Write-Host "WARNING: Unknown ResourceType: $($resource.ResourceType)" `
                -ForegroundColor Yellow
        }
    }
}

# -------------------------------------------------
# HCL String Escape
# -------------------------------------------------

function Escape-HclString {
    param(
        [string]$Value
    )

    if ($null -eq $Value) {
        return ""
    }

    return $Value.Replace('\', '\\').Replace('"', '\"')
}

# -------------------------------------------------
# Convert Map -> Terraform HCL
# -------------------------------------------------

function Convert-ToTerraformMap {

    param(
        [System.Collections.IDictionary]$Map,
        [int]$Indent = 0
    )

    $lines = @()
    $spaces = " " * $Indent

    foreach ($key in $Map.Keys) {

        $value = $Map[$key]

        $lines += "$spaces$key = {"

        foreach ($property in $value.Keys) {

            $propertyValue = $value[$property]

            if ([string]::IsNullOrWhiteSpace($propertyValue)) {
                continue
            }

            # address_space
            if ($property -eq "address_space") {

                $lines += "$spaces  $property = ["
                $lines += "$spaces    `"$(Escape-HclString $propertyValue)`""
                $lines += "$spaces  ]"

            }

            # address_prefixes
            elseif ($property -eq "address_prefixes") {

                $lines += "$spaces  $property = ["
                $lines += "$spaces    `"$(Escape-HclString $propertyValue)`""
                $lines += "$spaces  ]"

            }

            # Normal string
            else {

                $escapedValue = Escape-HclString $propertyValue

                $lines += "$spaces  $property = `"$escapedValue`""
            }
        }

        $lines += "$spaces}"
    }

    return $lines
}

# -------------------------------------------------
# Build terraform.tfvars
# -------------------------------------------------

$output = @()

$output += "# =================================================="
$output += "# terraform.tfvars"
$output += "# Generated by Resource-details.ps1"
$output += "# Do not edit manually"
$output += "# =================================================="
$output += ""

# -------------------------------------------------
# Resource Groups
# -------------------------------------------------

if ($resourceGroups.Count -gt 0) {

    $output += "dev_module_rg = {"

    $output += Convert-ToTerraformMap `
        -Map $resourceGroups `
        -Indent 2

    $output += "}"
    $output += ""
}

# -------------------------------------------------
# Storage Accounts
# -------------------------------------------------

if ($storageAccounts.Count -gt 0) {

    $output += "dev_module_storacc = {"

    $output += Convert-ToTerraformMap `
        -Map $storageAccounts `
        -Indent 2

    $output += "}"
    $output += ""
}

# -------------------------------------------------
# VNets
# -------------------------------------------------

if ($vnets.Count -gt 0) {

    $output += "dev_module_vnet = {"

    $output += Convert-ToTerraformMap `
        -Map $vnets `
        -Indent 2

    $output += "}"
    $output += ""
}

# -------------------------------------------------
# Subnets
# -------------------------------------------------

if ($subnets.Count -gt 0) {

    $output += "dev_module_subnet = {"

    $output += Convert-ToTerraformMap `
        -Map $subnets `
        -Indent 2

    $output += "}"
    $output += ""
}

# -------------------------------------------------
# Create Output Directory if required
# -------------------------------------------------

$outputDirectory = Split-Path -Parent $TfvarsFile

if (-not [string]::IsNullOrWhiteSpace($outputDirectory)) {

    if (-not (Test-Path -LiteralPath $outputDirectory)) {

        New-Item `
            -ItemType Directory `
            -Path $outputDirectory `
            -Force | Out-Null
    }
}

# -------------------------------------------------
# Write terraform.tfvars
# -------------------------------------------------

$output | Set-Content `
    -LiteralPath $TfvarsFile `
    -Encoding UTF8

# -------------------------------------------------
# Summary
# -------------------------------------------------

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host " terraform.tfvars CREATED SUCCESSFULLY" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""

Write-Host "Resource Summary:" -ForegroundColor Cyan
Write-Host "Resource Groups  : $($resourceGroups.Count)"
Write-Host "Storage Accounts : $($storageAccounts.Count)"
Write-Host "VNets            : $($vnets.Count)"
Write-Host "Subnets          : $($subnets.Count)"

Write-Host ""
Write-Host "Output: $TfvarsFile" -ForegroundColor Green
Write-Host ""