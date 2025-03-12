# Variables. DO NOT SAVE TO GITHUB
$BUCKET = ""
$ENDPOINT = ""
$ACCESS_KEY = ""
$SECRET_KEY = ""
$PASSWORD = ""
$ENV = ""

# Function to check the OpenShift cluster
function Test-OnGoldCluster {
    $ocProjectOutput = oc project 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Error executing oc project: $ocProjectOutput"
        exit 1
    }

    if ($ocProjectOutput -notmatch 'https://api.gold.devops.gov.bc.ca') {
        Write-Error "Error: Not on Gold cluster"
        exit 1
    }
}

function Test-OnGoldDRCluster {
    $ocProjectOutput = oc project 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Error executing oc project: $ocProjectOutput"
        exit 1
    }

    if ($ocProjectOutput -notmatch 'https://api.golddr.devops.gov.bc.ca') {
        Write-Error "Error: Not on GoldDR cluster"
        exit 1
    }
}

# Step 1: Shutdown the DB in Gold (if cluster is available).
function Disable-GoldDB {
    Test-OnGoldCluster

    helm upgrade "$ENV-ride-db" -f "./values-$ENV-gold.yaml" "./" `
        --set crunchy.pgBackRest.s3.bucket="$BUCKET" `
        --set crunchy.pgBackRest.s3.endpoint="$ENDPOINT" `
        --set crunchy.shutdown=true
}

# Step 2: Set Gold DR as the Primary DB
function Set-GoldDRPrimary {
    Test-OnGoldDRCluster
    helm upgrade "$ENV-ride-db" -f "./values-$ENV-gold.yaml" -f "./values-$ENV-golddr.yaml" "./" `
        --set crunchy.pgBackRest.s3.bucket="$BUCKET" `
        --set crunchy.pgBackRest.s3.endpoint="$ENDPOINT" `
        --set crunchy.standby.enabled=false
}

# Step 3: Delete Gold DB so that we can rebuild it.
function Remove-GoldDB {
    Test-OnGoldCluster
    helm uninstall "$ENV-ride-db"
}

# Step 4: Rebuild Gold DB as a Standby
function Restore-GoldStandby {
    Test-OnGoldCluster
    helm install "$ENV-ride-db" -f "./values-$ENV-gold.yaml" "./" `
        --set crunchy.pgBackRest.s3.bucket="$BUCKET" `
        --set crunchy.pgBackRest.s3.endpoint="$ENDPOINT" `
        --set crunchy.pgBackRest.s3.accessKey="$ACCESS_KEY" `
        --set crunchy.pgBackRest.s3.secretKey="$SECRET_KEY" `
        --set crunchy.user.password="$PASSWORD" `
        --set crunchy.standby.enabled=true
}

# Step 5: Shutdown the DB in Gold DR to prepare for making Gold Primary again
function Disable-GoldDRDB {
    Test-OnGoldDRCluster
    helm upgrade "$ENV-ride-db" -f "./values-$ENV-gold.yaml" -f "./values-$ENV-golddr.yaml" "./" `
        --set crunchy.pgBackRest.s3.bucket="$BUCKET" `
        --set crunchy.pgBackRest.s3.endpoint="$ENDPOINT" `
        --set crunchy.standby.enabled=false `
        --set crunchy.shutdown=true
}

# Step 6: Set Gold as the Primary DB
function Set-GoldPrimary {
    Test-OnGoldCluster
    helm upgrade "$ENV-ride-db" -f "./values-$ENV-gold.yaml" "./" `
        --set crunchy.pgBackRest.s3.bucket="$BUCKET" `
        --set crunchy.pgBackRest.s3.endpoint="$ENDPOINT" `
        --set crunchy.standby.enabled=false
}

# Step 7: Delete Gold DR DB to prepare for making it a Standby again
function Remove-GoldDRDB {
    Test-OnGoldDRCluster
    helm uninstall "$ENV-ride-db"
}

# Step 8: Rebuild Gold DR as a Standby
function Restore-GoldDRStandby {
    Test-OnGoldDRCluster
    helm install "$ENV-ride-db" -f "./values-$ENV-gold.yaml" -f "./values-$ENV-golddr.yaml" "./" `
        --set crunchy.pgBackRest.s3.bucket="$BUCKET" `
        --set crunchy.pgBackRest.s3.endpoint="$ENDPOINT" `
        --set crunchy.pgBackRest.s3.accessKey="$ACCESS_KEY" `
        --set crunchy.pgBackRest.s3.secretKey="$SECRET_KEY" `
        --set crunchy.user.password="$PASSWORD"
}

# Prompt user for step
Write-Host "This script will perform a failover of the CrunchyDB database if you follow these steps in order." -ForegroundColor Cyan
Write-Host "You must be on the correct cluster to perform each step. Please ensure you are logged into the correct cluster prior to proceding. Enter 0 to exit." -ForegroundColor Red
Write-Host "Current Project: " -NoNewline -ForegroundColor Red
oc project
Write-Host "Choose a step to run:"
Write-Host "1. Shutdown Gold DB (Must be on Gold Cluster)"
Write-Host "2. Set Gold DR Primary (Must be on Gold DR Cluster)"
Write-Host "3. Delete Gold DB (Must be on Gold Cluster)"
Write-Host "4. Rebuild Gold Standby (Must be on Gold Cluster)"
Write-Host "5. Shutdown Gold DR DB (Must be on Gold DR Cluster)"
Write-Host "6. Set Gold Primary (Must be on Gold Cluster)"
Write-Host "7. Delete Gold DR DB (Must be on Gold DR Cluster)"
Write-Host "8. Rebuild Gold DR Standby (Must be on Gold DR Cluster)"
Write-Host "9. Manually Update Monitoring Password (see Readme)"
Write-Host "Enter the step number: " -NoNewline
$step = Read-Host

# Run selected step(s)
switch ($step) {
    "00" { Test-OnGoldCluster }
    "01" { Test-OnGoldDRCluster }
    "1" { Disable-GoldDB }
    "2" { Set-GoldDRPrimary }
    "3" { Remove-GoldDB }
    "4" { Restore-GoldStandby }
    "5" { Disable-GoldDRDB }
    "6" { Set-GoldPrimary }
    "7" { Remove-GoldDRDB }
    "8" { Restore-GoldDRStandby }
    default { Write-Host "Invalid step number." }
}