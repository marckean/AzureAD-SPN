# you must belong to the Owner or User Access Administrator roles, or have a customized role that grants write access for Microsoft.Authorization
# https://social.msdn.microsoft.com/Forums/azure/en-US/77928b22-eb59-480d-93e4-4dcf912b7928/unable-to-assign-application-to-role-when-creating-service-principal-for-subscription-payasyougo?forum=WindowsAzureAD

$DisplayName = 'My-SPN'
$Domain = 'company.com'
$Password = 'Password'

$SourceTargetTenant = $null

$SourceTargetSubscription = [System.Windows.Forms.MessageBox]::`
Show("Are the source & target subscription the same?","Source & Target subscription","YesNo","Information")

if($SourceTargetSubscription -eq 'No'){
$SourceTargetTenant = [System.Windows.Forms.MessageBox]::`
Show("Do you use the same logon account to access both subscriptions?","Source & Target tenant","YesNo","Information")
}

Function SPN-Removal ($DisplayName){

    if(Get-AzureRmADApplication | ? {$_.DisplayName -eq $DisplayName}){
    $app = Get-AzureRmADApplication | ? {$_.DisplayName -eq $DisplayName}
    Remove-AzureRmADApplication -ObjectId $app.ObjectId.Guid -Force
    }
    if(Get-AzureRmADServicePrincipal -SearchString $DisplayName){
    $appsp = Get-AzureRmADServicePrincipal -SearchString $DisplayName
    Remove-AzureRmADServicePrincipal -ObjectId $appsp.Id
    }
}

Function SPN-Creation ($Environment, $Subscription, $DisplayName, $Domain, $Password){

    $app = New-AzureRmADApplication `
                                -DisplayName $DisplayName `
                                -HomePage "https://$Domain/$DisplayName" `
                                -IdentifierUris "https://$Domain/$DisplayName" `
                                -Password $Password 

    New-AzureRmADServicePrincipal -ApplicationId $app.ApplicationId.Guid
    Start-Sleep -Seconds 10 # Until it really creates it
    New-AzureRmRoleAssignment -RoleDefinitionName 'Contributor' -ServicePrincipalName $app.ApplicationId.Guid

    write-host -nonewline "`n`tThe $Environment SPN username is: " -ForegroundColor Yellow; `
    write-host -nonewline $app.ApplicationId.Guid`n -ForegroundColor Green; `
    write-host -nonewline "`n`tThe $Environment Password is: " -ForegroundColor Yellow; `
    write-host -nonewline $Password"`n" -ForegroundColor Green; `
    write-host -nonewline "`n`tThe $Environment Subscription Name is: " -ForegroundColor Yellow; `
    write-host -nonewline $Subscription.SubscriptionName"`n" -ForegroundColor Green; `
    write-host -nonewline "`n`tThe $Environment Subscription Tenant ID is: " -ForegroundColor Yellow; `
    write-host -nonewline $Subscription.TenantId`n"`n" -ForegroundColor Green; 

}

##########################################################################################
########################    Logon to Source & Target Tenants     #########################
##########################   ...and Setup Service Principal    ###########################
##########################################################################################

#region Logon to Source & Target environment | @marckean

if($SourceTargetTenant -eq 'No'){
# Logon to Source environment | @marckean

    Write-Host "`nEnter credentials for the SOURCE Azure Tenant.`n" -ForegroundColor Cyan
    $SourceAzure = Get-AzureRmEnvironment 'AzureCloud'
    $SourceEnv = Login-AzureRmAccount -Environment $SourceAzure -Verbose
    Select-AzureRmProfile -Profile $SourceEnv

    $SourceSubscription = (Get-AzureRmSubscription | Out-GridView -Title "Choose a SOURCE Subscription ..." -PassThru)
    Get-AzureRmSubscription -SubscriptionId $SourceSubscription.SubscriptionId | Select-AzureRmSubscription
    $Environment = 'SOURCE'
    SPN-Removal $DisplayName
    SPN-Creation $Environment $SourceSubscription $DisplayName $Domain $Password

# Logon to Target environment | @marckean

    Write-Host "`nEnter credentials for the TARGET Azure Tenant.`n" -ForegroundColor Cyan
    $TargetAzure = Get-AzureRmEnvironment 'AzureCloud'
    $TargetEnv = Login-AzureRmAccount -Environment $TargetAzure -Verbose
    Select-AzureRmProfile -Profile $TargetEnv

    $TargetSubscription = (Get-AzureRmSubscription | Out-GridView -Title "Choose a TARGET Subscription ..." -PassThru)
    Get-AzureRmSubscription -SubscriptionId $TargetSubscription.SubscriptionId | Select-AzureRmSubscription
    $Environment = 'TARGET'
    SPN-Removal $DisplayName
    SPN-Creation $Environment $TargetSubscription $DisplayName $Domain $Password

}

if($SourceTargetSubscription -eq 'Yes'){

# Logon to Azure environment | @marckean

    Write-Host "`nEnter credentials for the Azure Tenant.`n" -ForegroundColor Cyan
    $MigrationAzure = Get-AzureRmEnvironment 'AzureCloud'
    $MigrationEnv = Login-AzureRmAccount -Environment $MigrationAzure -Verbose
    Select-AzureRmProfile -Profile $MigrationEnv
    
    $MigrationSubscription = (Get-AzureRmSubscription | Out-GridView -Title "Choose a Source & Target Subscription ..." -PassThru)
    Get-AzureRmSubscription -SubscriptionId $MigrationSubscription.SubscriptionId | Select-AzureRmSubscription
    $Environment = $null
    SPN-Removal $DisplayName
    SPN-Creation $Environment $MigrationSubscription $DisplayName $Domain $Password
}

if($SourceTargetTenant -eq 'Yes'){

# Logon to Azure environment | @marckean

    Write-Host "`nEnter credentials for the Azure Tenant.`n" -ForegroundColor Cyan
    $MigrationAzure = Get-AzureRmEnvironment 'AzureCloud'
    $MigrationEnv = Login-AzureRmAccount -Environment $MigrationAzure -Verbose
    Select-AzureRmProfile -Profile $MigrationEnv

    $SourceSubscription = (Get-AzureRmSubscription | Out-GridView -Title "Choose a SOURCE Subscription ..." -PassThru)
    Get-AzureRmSubscription -SubscriptionId $SourceSubscription.SubscriptionId | Select-AzureRmSubscription
    $Environment = 'SOURCE'
    SPN-Removal $DisplayName
    SPN-Creation $Environment $SourceSubscription $DisplayName $Domain $Password

# Target environment | @marckean

    $TargetSubscription = (Get-AzureRmSubscription | Out-GridView -Title "Choose a TARGET Subscription ..." -PassThru)
    Get-AzureRmSubscription -SubscriptionId $TargetSubscription.SubscriptionId | Select-AzureRmSubscription
    $Environment = 'TARGET'
    SPN-Removal $DisplayName
    SPN-Creation $Environment $TargetSubscription $DisplayName $Domain $Password

}
