## Permissions

One of the following permissions iare required to call this API. To learn more, including how to choose permissions, see [Use Microsoft Defender for Endpoint APIs](https://learn.microsoft.com/en-us/defender-endpoint/api/apis-intro) for details.

Expand table

| Permission type | Permission             | Permission display name                                              |
| --------------- | ---------------------- | -------------------------------------------------------------------- |
| Application     | Vulnerability.Read.All | 'Read Threat and Vulnerability Management vulnerability information' |
| Application     | Machine.Read.All       | 'Read all machine profiles'                                          |





### Step 1: Create User Assigned Managed Identity

1. Within the Azure Portal select **Managed Identities**.

2. Select **Create**.

3. Provide a meaningful name like 'Defender Vulnerability Reader'
   
   1. Select a Resource Group for the deployment
   
   2. Select a Region for the deployment
   
   3. Provide the meaningful name selected for the Identity.

4. Select **Review + Create**.

### Step 2: Assign to Managed Identity Defender Roles

1. **Install Azure AD Module (if not already installed) or use Azure cloud shell:**

```powershell
Install-Module -Name AzureAD
```

2. **Connect to Azure AD:**

```powershell
Connect-AzureAD
```

All Microsoft applications exist in Entra as 'Enterprise Applications'

[Microsoft-Owned-Enterprise-Applications/Microsoft Owned Enterprise Applications Overview.md at main · emilyvanputten/Microsoft-Owned-Enterprise-Applications · GitHub](https://github.com/emilyvanputten/Microsoft-Owned-Enterprise-Applications/blob/main/Microsoft%20Owned%20Enterprise%20Applications%20Overview.md)

This Function App will utilise roles from the WindowsDefenderATP application.

| DisplayName        | AppId                                | AppOwnerTenantId                     |
| ------------------ | ------------------------------------ | ------------------------------------ |
| WindowsDefenderATP | fc780465-2017-40d4-a0c5-307022471b92 | f8cdef31-a31e-4b4a-93e4-5f571e91255a |

3. **Get the Service Principal for the created Managed Identity:**

```powershell
# 'Enter your managed identity Object (principal) ID'
$MIGuid = '9f478d79-18a2-4f06-bf66-ae0a55048028'

$MI = Get-AzureADServicePrincipal -ObjectId $MIGuid
#The Defender AppId is a constant.
$MDEAppId = 'fc780465-2017-40d4-a0c5-307022471b92'
```

5. **Assign Vulnerability.Read.All Role to the Managed Identity:**

Find the `AppRole` ID for `Vulnerability.Read.All` and then assign it to the managed identity.

```powershell
$PermissionName = 'Vulnerability.Read.All'
$MDEServicePrincipal = Get-AzureADServicePrincipal -Filter "appId eq '$MDEAppId'"
$AppRole = $MDEServicePrincipal.AppRoles | Where-Object {$_.Value -eq $PermissionName -and $_.AllowedMemberTypes -contains 'Application'
New-AzureAdServiceAppRoleAssignment -ObjectId $MI.ObjectId -PrincipalId $MI.ObjectId ` -ResourceId $MDEServicePrincipal.ObjectId -Id $AppRole.Id 
```

5. **Assign Machine.Read.All Role to the Managed Identity:**

Find the `AppRole` ID for `Vulnerability.Read.All` and then assign it to the managed identity.

```powershell
$PermissionName = 'Machine.Read.All'
$MDEServicePrincipal = Get-AzureADServicePrincipal -Filter "appId eq '$MDEAppId'"
$AppRole = $MDEServicePrincipal.AppRoles | Where-Object {$_.Value -eq $PermissionName -and $_.AllowedMemberTypes -contains 'Application'
New-AzureAdServiceAppRoleAssignment -ObjectId $MI.ObjectId -PrincipalId $MI.ObjectId ` -ResourceId $MDEServicePrincipal.ObjectId -Id $AppRole.Id  
```

### Example Script

Here’s a complete example script that performs all the necessary steps:

```powershell
# Install AzureAD module if not already installed 
Install-Module -Name AzureAD -Force -AllowClobber  

# Connect to Azure AD 
Connect-AzureAD

# 'Enter your managed identity Object ID'
$MIGuid = '9f478d79-18a2-4f06-bf66-ae0a55048028'

$MI = Get-AzureADServicePrincipal -ObjectId $MIGuid

$MDEAppId = 'fc780465-2017-40d4-a0c5-307022471b92'

$PermissionName = 'Vulnerability.Read.All'
$MDEServicePrincipal = Get-AzureADServicePrincipal -Filter "appId eq '$MDEAppId'"
$AppRole = $MDEServicePrincipal.AppRoles | Where-Object {$_.Value -eq $PermissionName -and $_.AllowedMemberTypes -contains 'Application'}
New-AzureAdServiceAppRoleAssignment -ObjectId $MI.ObjectId -PrincipalId $MI.ObjectId ` -ResourceId $MDEServicePrincipal.ObjectId -Id $AppRole.Id #$PermissionName = 'Vulnerability.Read.All'


$PermissionName = 'Machine.Read.All'
$MDEServicePrincipal = Get-AzureADServicePrincipal -Filter "appId eq '$MDEAppId'"
$AppRole = $MDEServicePrincipal.AppRoles | Where-Object {$_.Value -eq $PermissionName -and $_.AllowedMemberTypes -contains 'Application'}
New-AzureAdServiceAppRoleAssignment -ObjectId $MI.ObjectId -PrincipalId $MI.ObjectId ` -ResourceId $MDEServicePrincipal.ObjectId -Id $AppRole.Id #$PermissionName = 'Vulnerability.Read.All'
```

### 
