# Set the tenant ID for your environment
$tenantId = "<your-tenantid-here>"

# Connect to Microsoft Graph with the required permissions
Connect-MgGraph -Scopes "Application.ReadWrite.All" -TenantId $tenantId

# Specify the application object ID where extensions will be created
$applicationObjectId = "<your-objectID-from-previous-step-here>"

# Define the extension property names to create
$extensions = @("persona", "personaSubType")

# Loop through each extension name
foreach ($extension in $extensions) {
    # Create parameters hashtable for the extension property
    $params = @{
        name = $extension
        dataType = "String"
        targetObjects = @(
            "User"
        )
    }
    
    # Create the directory extension property on the application
    New-MgApplicationExtensionProperty -ApplicationId $applicationObjectId -BodyParameter $params
}

# Retrieve and display the created extension properties
Get-MgApplicationExtensionProperty -ApplicationId $applicationObjectId | fl