# Lab 2 - Privileged Users - Identity Stores - SCIM

In this lab you will learn about identity personas, set up SCIM 2.0 API provisioning for privileged users, and configure governance controls around privileged account lifecycle management.

> 📌 **About SCIM Provisioning in Entra ID**  
> Entra ID offers multiple provisioning approaches:
> - **Lab 1 (API-driven provisioning app)**: Built-in provisioning feature via Enterprise Apps, uses application-specific endpoints and tokens
> - **Lab 2 (SCIM 2.0 API)**: Direct programmatic access using OAuth 2.0 authentication, Microsoft Graph endpoints, requires P1 license and Azure billing
> 
> This lab focuses on the **SCIM 2.0 API** approach for direct, programmatic control. See [Microsoft Learn: SCIM Support in Entra ID](https://learn.microsoft.com/en-us/entra/identity/app-provisioning/scim-support-in-entra-id) for comparison. 
> Sjekke pris og evt. bare gjenbruke provisioning app med tillegg av persona!!!

&nbsp;

## Lab 2.1 - Understanding Identity Personas & Attribute Design

Identity personas help you define different user types and their attributes within your organization. In this section, you will design personas for standard and privileged users.

### Tasks:

1. **Define Identity Personas** - Create 2 personas for your organization:
   - Standard User (regular employees). Suggestion: EndUser
   - Administrator accounts (dedicated administrator accounts). Suggestion: Admin 

2. **Optional! Map Attributes for Each Persona** - For each persona, identify key attributes:
   - Core attributes: userName, displayName, email, userType
   - Enterprise attributes: department, company, costCenter, division
   - Custom attributes for privileged users: hireDateDate, leaveDate, title (e.g., "Privileged Admin")
   - Naming conventions: consider using suffixes (e.g., `.admin`) or prefixes for privileged accounts

3. **Review Sample Payloads** - Examine the sample SCIM payloads in the resources folder, and add Persona under custom schema extension (in the same way as in Lab 1.3):
   - [minimum-user.json](../../../resources/resource-2-scim-sample-payloads/minimum-user.json) - Basic user with required fields
   - [privileged-user.json](../../../resources/resource-2-scim-sample-payloads/privileged-user.json) - Privileged user with enterprise and custom extensions
   - [full-user.json](../../../resources/resource-2-scim-sample-payloads/full-user.json) - Complete user profile with all attributes

> 💡 **Tip**  
> Pay attention to the `schemas` array in the payloads. Custom extension schemas follow the format `urn:ietf:params:scim:schemas:extension:yourorgname:1.0:User`. These allow you to add organization-specific attributes beyond the SCIM standard. E.g. Persona

&nbsp;

## Lab 2.1.1 - Create Directory Extensions for Persona Classification

Directory extensions in Entra ID allow you to extend the user object with custom attributes that can be used for classification, governance, and provisioning logic. In this section, you will create a custom extension to classify users by persona type.

### Prerequisites:
- **Application Administrator** or **Global Administrator** role
- Microsoft Graph PowerShell SDK installed

### What You'll Create:
A custom extension attribute named `persona` that will store the user's persona type with allowed values you defined in the first task in lab 2.1:
- `Admin` - Administrative or privileged user
- `Service` - Service account for applications
- `Test` - Test user for development/testing
- `EndUser` - Standard end user

> 📌 **Important**  
> Creating **directory extension definitions** is done through Microsoft Graph (API/PowerShell). The Entra admin center UI can show and use extension attributes in some places (for example dynamic membership rules), but the extension definition itself should be created via Graph.

### Step 1 - Create App Registration in Entra Admin Center

1. Go to **Microsoft Entra admin center** → **App registrations** → **+ New registration**
2. Name: `ELUK26-Directory-Extensions` (or similar)
3. Supported account types: **Single tenant only - {TenantName}**
4. Click **Register**
5. Save (from the app overview):
   - **Application (client) ID**
   - **Object ID** 

### Step 2 - Define Directory Extension via PowerShell

Use the script in the repository:

- [Create-DirectoryExtensions.ps1](../../../resources/resource-4-powershell-scripts/Create-DirectoryExtensions.ps1)

Run the script and define the directory extension (`persona`) for the app registration you created in Step 1.


> 💡 **Tip**  
> Directory extensions can also be used with dynamic group membership rules for automatic role assignment or access control. For example, you could create a dynamic group that automatically includes all users where `persona == "admin"`.

&nbsp;

## Lab 2.2 - Enable and Configure SCIM 2.0 API

In this section, you will enable the SCIM 2.0 API in Entra ID and set up authentication credentials for programmatic provisioning of privileged users.

> 📌 **Important**  
> This lab uses the **SCIM 2.0 API** for direct programmatic access. This is different from Lab 1's "API-driven provisioning app," which uses a built-in Entra ID provisioning feature. The SCIM API is a paid add-on that requires licensing and billing setup.
> Microsoft Entra SCIM Provisioning API: $0.002 Per 1 transaction (USD)


### Prerequisites:
- **Entra ID P1** license (or equivalent like P2, Microsoft 365 E3/E5)
- **Application Administrator** or **Cloud Application Administrator** role
- **Billing Administrator** role to enable SCIM API billing
- **Active Azure subscription** linked to your Entra tenant (for billing)

### Tasks:

1. **Enable SCIM Provisioning API in Entra Admin Center**
   - Sign in to [Microsoft Entra admin center](https://entra.microsoft.com/)
   - In the left navigation, expand **ID Governance** and select **Dashboard**
   - Locate the **SCIM Provisioning API** tile and click **Get Started**
   - In the SCIM Provisioning API pane:
     - Under **Link subscription**, select your Azure subscription
     - Choose an existing **Resource group** or create a new one
     - Review the **Billing Unit** details (every SCIM API call is billed per the pricing model)
     - Click **Turn on**
   - Wait for the feature to be enabled (may take a few minutes)

2. **Register an Application for SCIM API Authentication**
   - Go to **Microsoft Entra** → **App registrations** → **+ New registration**
   - Name: `ELUK26-SCIM-API-Client` (or similar)
   - Supported account types: **Accounts in this organizational directory only**
   - Click **Register**
   - Save the following values:
     - **Application (client) ID**
     - **Directory (tenant) ID**

3. **Grant API Permissions**
   - In the app registration, go to **API permissions** → **+ Add a permission**
   - Select **Microsoft Graph** → **Application permissions**
   - Search for and grant the following permissions (select based on your use case):
     - `User.ReadWrite.All` (read and write access to users)
     - `User.EnableDisableAccount.All` (ability to disable/enable accounts)
     - `User-LifeCycleInfo.ReadWrite.All` (update lifecycle attributes like leave dates)
   - Click **Grant admin consent for [Tenant]**
   - Verify that admin consent is shown as **Granted**

4. **Create a Client Secret**
   - In the app registration, go to **Certificates & secrets** → **+ New client secret**
   - Description: `SCIM API authentication`
   - Expires: Choose appropriate expiration (recommended: 12-24 months)
   - Click **Add**
   - **Important**: Copy and store the secret value securely - you cannot retrieve it again

5. **Test Connectivity to SCIM API**
   - Open Postman or a terminal, and first obtain an access token using OAuth 2.0 client credentials flow:
     ```
     POST https://login.microsoftonline.com/{tenant_id}/oauth2/v2.0/token
     Content-Type: application/x-www-form-urlencoded
     
     client_id={your_client_id}&client_secret={your_client_secret}&scope=https%3A%2F%2Fgraph.microsoft.com%2F.default&grant_type=client_credentials
     ```
   - Save the `access_token` from the response
   - Test the SCIM endpoint:
     ```
     GET https://graph.microsoft.com/rp/scim/serviceproviderconfig
     Authorization: Bearer {access_token}
     Accept: application/json
     ```
   - Expected response (200 OK): Service provider configuration confirming the endpoint is accessible

&nbsp;

## Lab 2.3 - Build & Test Privileged User Payloads

Now you will create and test SCIM 2.0 bulk request payloads to provision privileged users using the SCIM API endpoint.

### Prerequisites:
- Completed Lab 2.2 with valid access token and SCIM API enabled

### Tasks:

1. **Prepare Your Access Token**
   - From Lab 2.2, obtain a fresh access token via OAuth 2.0 client credentials:
     ```
     POST https://login.microsoftonline.com/{tenant_id}/oauth2/v2.0/token
     Content-Type: application/x-www-form-urlencoded
     
     client_id={your_client_id}&client_secret={your_client_secret}&scope=https%3A%2F%2Fgraph.microsoft.com%2F.default&grant_type=client_credentials
     ```
   - Store the `access_token` - valid for ~1 hour

2. **Create Minimum Privileged User Payload**
   - Start with the [privileged-user.json](../../../resources/resource-2-scim-sample-payloads/privileged-user.json) sample
   - Modify the following fields for your tenant:
     - `externalId`: Use a unique identifier (e.g., `priv-001`)
     - `userName`: Apply your naming convention (e.g., `firstname.lastname.admin`)
     - `displayName`: e.g., `FirstName LastName (Admin)`
     - Email domain: Replace with your tenant domain (e.g., `user@contoso.com`)
     - Custom schema namespace: Update to reflect your organization

3. **Create Multiple Test Payloads**
   - Create at least 2-3 SCIM bulk request variations:
     - **Minimal privileged user**: externalId, userName, displayName, active
     - **Enhanced with org attributes**: Add department, costCenter, division, organization
     - **Full with custom extensions**: Include hiring dates, leave dates, and custom fields

4. **POST Users via SCIM API**
   - Use Postman or curl to send bulk requests to the SCIM API:
     ```
     POST https://graph.microsoft.com/rp/scim/Users
     Authorization: Bearer {your_access_token}
     Content-Type: application/scim+json
     
     {
       "schemas": ["urn:ietf:params:scim:schemas:core:2.0:User"],
       "externalId": "priv-001",
       "userName": "joe.bloggs.admin",
       "displayName": "Joe Bloggs (Admin)",
       "active": true,
       "userType": "Privileged",
       "name": {
         "givenName": "Joe",
         "familyName": "Bloggs"
       },
       "emails": [{
         "primary": true,
         "type": "work",
         "value": "joe.bloggs.admin@yourtenant.onmicrosoft.com"
       }]
     }
     ```
   - Record the response and check for successful creation (HTTP 201 Created)
   - Note the `id` returned in the response (you'll need this for updates/deletes)

5. **Verify in Entra ID**
   - Go to Microsoft Entra portal → Users
   - Search for the newly created users by userName
   - Verify all attributes were provisioned correctly
   - Check custom attributes if visible in the user profile

> 💡 **Note on Bulk Operations**  
> The SCIM API also supports bulk operations for creating multiple users in one request. See the [Microsoft Learn SCIM API reference](https://learn.microsoft.com/en-us/entra/identity/app-provisioning/entra-id-scim-api-reference) for bulk request format details.

&nbsp;

## Lab 2.4 - Update & Deprovisioning Scenarios

Test real-world provisioning scenarios including attribute updates and user deprovisioning via the SCIM API.

### Prerequisites:
- Completed Lab 2.3 with at least one created user and current access token

### Tasks:

1. **Perform PATCH Operations (Update Users)**
   - Update an existing user's attributes using the SCIM API:
     ```
     PATCH https://graph.microsoft.com/rp/scim/Users/{user-id}
     Authorization: Bearer {your_access_token}
     Content-Type: application/scim+json
     
     {
       "schemas": ["urn:ietf:params:scim:api:messages:2.0:PatchOp"],
       "Operations": [{
         "op": "replace",
         "path": "title",
         "value": "Senior Privileged Admin"
       }]
     }
     ```
   - Example updates: Change department, modify title, update costCenter
   - Verify changes appear in Entra ID within a few seconds

2. **Test State Transitions (Disable Users)**
   - Change a user's `active` status from `true` to `false`:
     ```
     PATCH https://graph.microsoft.com/rp/scim/Users/{user-id}
     Authorization: Bearer {your_access_token}
     Content-Type: application/scim+json
     
     {
       "schemas": ["urn:ietf:params:scim:api:messages:2.0:PatchOp"],
       "Operations": [{
         "op": "replace",
         "path": "active",
         "value": false
       }]
     }
     ```
   - Verify the user is disabled in Entra ID (marked as inactive)
   - Try re-enabling by setting `active` to `true`

3. **Deprovisioning (DELETE Operations)**
   - Remove a test user via SCIM API:
     ```
     DELETE https://graph.microsoft.com/rp/scim/Users/{user-id}
     Authorization: Bearer {your_access_token}
     ```
   - Verify the user is deleted from Entra ID (or moved to recycle bin based on retention settings)

4. **Error Handling & Troubleshooting**
   - Test with invalid data and document common errors:
     - Missing required fields (HTTP 400 Bad Request)
     - Invalid schema references (HTTP 400)
     - Non-existent user ID (HTTP 404 Not Found)
     - Duplicate externalId values (HTTP 409 Conflict)
   - Review error responses from the SCIM API
   - Document retry logic (transient errors should be retried)

&nbsp;

## Lab 2.5 - Apply Privileged RBACs & RMAU Assignment

Connect your provisioned privileged users to governance controls by assigning them to a Restricted Management Administrative Unit.

### Tasks:

1. **Review Provisioned Privileged Users**
   - List all users in Entra ID that match your privileged calling convention (e.g., `*.admin` suffix)
   - Verify their `userType` attribute is set to "Privileged"

2. **Create Restricted Management Administrative Unit (RMAU)**
   - Follow the steps in Lab 2.6 below to create an RMAU
   - Configure dynamic membership rules to automatically include all privileged users

3. **Assign Roles at AU Scope**
   - Assign an administrative role with scope limited to the RMAU
   - Optionally: Delegate management to a dedicated Control Plane group

&nbsp;

## Lab 2.6 - Assign Privileged Accounts to Restricted Management Administrative Unit (RMAU)

1. Create an [Administrative Unit with dynamic membership](https://learn.microsoft.com/en-us/entra/identity/role-based-access-control/admin-units-members-dynamic?tabs=admin-center#add-rules-for-dynamic-membership-groups) named “Privileged Users” and enable “[Restricted management administrative unit](https://learn.microsoft.com/en-us/entra/identity/role-based-access-control/admin-units-restricted-management)” during the creation process.

2. Configure a rule depending on your naming convention for privileged users or other unique attributes (e.g., domain suffix for cloud-only accounts).

    > 💡 **Optional**  
    > Evaluate the option to configure [dynamic membership with the memberOf attribute](https://learn.microsoft.com/en-us/entra/identity/users/groups-dynamic-rule-member-of). This allows you to assign members of role-assignable groups or other privileged groups to RMAU automatically. Consider that this feature is in preview and take note of the warning about limitations from the [Microsoft Learn](https://learn.microsoft.com/en-us/entra/identity/users/groups-dynamic-rule-member-of) documentation.

3. Assign a role [on the scope of the Administrative Unit](https://learn.microsoft.com/en-us/entra/identity/role-based-access-control/manage-roles-portal?tabs=admin-center#assign-roles-with-administrative-unit-scope-1) to regain access for managing privileged users. Choose a dedicated role-assignable group which will be used for Control Plane Management.
