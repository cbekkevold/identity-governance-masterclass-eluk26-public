# Lab 2 - Privileged Users - Identity Stores - SCIM

In this lab you will learn about identity personas, create directory extensions and add them as user attributes. You will learn how to use persona as a filter/scope. And for last we will set up SCIM 2.0 API provisioning for users/groups, and test some of the functionallity in the API.

> 📌 **About SCIM Provisioning in Entra ID**  
> Entra ID offers multiple provisioning approaches:
> - **Lab 1 showed us how to use the API-driven provisioning app**: Built-in provisioning feature via Enterprise Apps, uses application-specific endpoints and tokens. We will reuse this for the first tasks in lab 2.
> - **Lab 2 also includes enabling and testing of the SCIM 2.0 API**: Direct programmatic access using OAuth 2.0 authentication and different Microsoft Graph/SCIM endpoints.

&nbsp;

## Lab 2.1 - Define Personas and Attribute Mapping

In this section, you define identity personas and the attribute model that will be used in SCIM payloads and governance rules.

### Tasks:

1. **Define identity personas for your organization**
   - Create the personas you need, for example:
     - `EndUser` (standard employees)
     - `AdminUser` (dedicated privileged accounts)
     - `ServiceUser` (service accounts) - Optional!

2. **Map attributes for each persona**
   - Include `Persona` as a custom extension attribute in your design, similar to how custom attributes (like hireDate/leaveDate examples from lab 1) are modeled.
   - Document expected values for each persona (for example `EndUser`, `AdminUser`, `ServiceUser`) so you can reuse them consistently in Lab 2.2 and Lab 2.4. Only if you want to make more changes than adding persona.

&nbsp;

## Lab 2.2 - Update SCIM JSON Payloads for Personas

In this section, you update the sample payloads so they reflect the personas and attribute mappings you defined in Lab 2.1. 

### Tasks:

1. **Review sample payload files**
   - [privileged-user.json](../../resources/resource-2-scim-sample-payloads/privileged-user.json)  (e.g. persona AdminUser)
   - [full-user.json](../../resources/resource-2-scim-sample-payloads/full-user.json) (e.g. persona EndUser)
   - [service-user.json](../../resources/resource-2-scim-sample-payloads/service-user.json) (e.g. persona ServiceUser)

2. **Add or update persona-related attributes**
   - Add `persona` in your custom extension block (same pattern as other extension fields such as `HireDate` and `LeaveDate` in lab 1).
   - Ensure the `schemas` array includes your custom extension namespace. (Should be there already, `urn:ietf:params:scim:schemas:extension:yourorgname:1.0:User`)
   - Align each payload to one of your defined personas. Add `Persona` under `countryCode`
   - Keep this as payload preparation only; provisioning app schema/mapping configuration is done in Lab 2.4.

3. **Create persona-specific payload variants**
   - Prepare at least one payload per persona you defined.
   - Update values like `userName`, `displayName`, and email domain to match your tenant and naming convention.

&nbsp;

## Lab 2.3 - Create Directory Extensions App and Run Script

In this section, you create an app registration used for directory extension definitions and run the extension creation script.

### Prerequisites:
- **Application Administrator** or **Global Administrator** role
- Microsoft Graph PowerShell SDK installed

### Tasks:

1. **Create app registration for directory extensions**
   - Go to **Microsoft Entra** → **App registrations** → **+ New registration**.
   - Name: `ELUK26-Directory-Extensions` (or similar).
   - Supported account types: **Single tenant only - {TenantName}**.
   - Save:
     - **Tenant ID**
     - **Object ID**
     - **Client ID**

2. **Edit the directory extension script to match your attributes**
   - Open [Create-DirectoryExtensions.ps1](../../resources/resource-4-powershell-scripts/Create-DirectoryExtensions.ps1).
   - Update the script with tenantID and objectID for application in previous step. Run the script to create the extension attributes from Lab 2.1 (including `persona` and any additional custom attributes you defined).

3. **Run the script for your app registration**
   - Execute the script with target to app created in Task 1.
   - Verify the extensions are created successfully in Entra ID. Save the name of the extension for later: e.g. extension_{clientIdforApp}_persona. ClientID in extension name shall match the client ID saved in task 1.

&nbsp;

## Lab 2.4 - Update Provisioning App Attribute Mapping and Test

In this section, you update the inbound provisioning app schema and mappings so the `persona` extension attribute is handled correctly, and then validate provisioning for both a regular and a privileged user.

### Tasks:

1. **Open the provisioning app and schema configuration**
   - Go to **Microsoft Entra admin center** → **Enterprise applications**.
   - Open the provisioning app you are using (reuse from Lab 1).
   - Go to **Provisioning**.
   - Open **Mappings** and the user mapping configuration.

2. **Edit the API attribute list (Lab 1.3 style) and add Persona schema attribute**
   - In the mappings view, click **Show advanced options**.
   - Select **Edit attribute list for API**.
   - Add this API attribute (replace `yourorgnamehere` with your own namespace if needed):
     - `urn:ietf:params:scim:schemas:extension:yourorgnamehere:1.0:User:Persona`
   - Save and refresh the provisioning app configuration.

3. **Add or update attribute mapping for Persona**
   - In user mappings, click **Add New Mapping** (or edit existing mapping).
   - Use the following mapping:

   | Entra ID Attribute | API Attribute |
   | --- | --- |
   | `extension_{AppClientID}_persona` | `urn:ietf:params:scim:schemas:extension:yourorgnamehere:1.0:User:Persona` |

   - Save mappings.
   - Ensure the mapping is enabled for update operations.

4. **Update a regular user via full SCIM payload (Lab 1.6 style)**
   - Use Graph Explorer (or Postman) and send a **POST** request to your inbound provisioning `bulkUpload` endpoint from Lab 1.
   - Set header: `Content-Type: application/scim+json`.
   - Start from `full-user.json`, set `persona` to your regular user value (for example `EndUser`), and keep `externalId` for an existing regular user so the operation becomes an update.
   - Run query and verify HTTP `202 Accepted`.

5. **Update a privileged user via full SCIM payload (Lab 1.6 style)**
   - Send another **POST** request to the same `bulkUpload` endpoint.
   - Use a second full payload for an existing privileged user and set `persona` to `AdminUser`, and keep `externalId` for an existing privileged user so the operation becomes an update.
   - Run query and verify HTTP `202 Accepted`.
   - Confirm this user has values suitable for persona-based AU membership rules in the next lab section.

6. **Optional: Create a service user via full SCIM payload (Lab 1.6 style)**
   - Send another **POST** request to the same `bulkUpload` endpoint.
   - Use a full payload for the service  user and set `persona` to `ServiceUser`. Check for unique `externalID` to ensure it will create a new user.
   - Run query and verify HTTP `202 Accepted`.
   - Confirm this user has values suitable for persona-based AU membership rules in the next lab section.

6. **Review provisioning logs and verify update operations**
   - Check **Provisioning logs** for all provisioned users.
   - Verify all entries show successful **Update** or **Create** operations.
   - Resolve any mapping errors before moving on.

&nbsp;

## Lab 2.5 - Create Administrative Units for Personas

In this section, you set up Administrative Units (AUs) in Entra ID for persona-based governance.

### Tasks:

1. **Create Administrative Units for your personas**
   - Create one or more AUs based on the personas from Lab 2.1 (for example `Admin Users`, `Service Accounts`).
   - Go to **Microsoft Entra ID** and **Administrative Units** in the left menu, under **Manage**
   - Click **+Add**. Give the AU a name and description. Let the "restricted" switch be disabled. Click **Review + create**

2. **Define membership logic**
   - Go into the newly created administrative unit. Click *Properties* in the left menu.
   - Change *Membership type* to *Dynamic user*. Click *Add dynamic query*.
   - Click *Get custom extension properties*. Paste the client ID saved from lab 2.3. Click *Refresh properties*
   - Verify that you find your extension at the bottom of the *Property* drop down menu.
   - Choose your directory extension. Set *Operator* to **Equals**. And write your persona-definition in *Value*.
      -- Rule syntax should look something like this: `(user.extension_c1f4f0b8614b418fb6d6c0e40128b7e4_persona -eq "AdminUser")`
   - Click **Save**. You will be taken back to the properties page. Click **Save** again, and confirm you will use dynamic query for membership with **Yes**.

3. **Create administrative units for every persona**
   - Repeat above steps for all personas you have defined.
   - Validate that provisioned users are assigned to the correct AU.

&nbsp;

## Lab 2.6 - Use Administrative Units as Scope for Lifecycle Workflows (Leaver/Inactive Users Example)

In this section, you create or reuse a workflow (joiner, mover or leaver) and set administration scope to one of the Administrative Units you've created. Give to different users (one inside and one outside your administrative unit) so only privileged users are targeted for the inactive users flow.

### Tasks:

1. **Open Lifecycle Workflows in Entra ID**
   - In the left menu, go to **Identity Governance** → **Lifecycle workflows**.

2. **Create or reuse a Leaver workflow from template**
   - Select **Workflows**.
   - Click **+ Create workflow**.
   - E.g. Choose the **Leaver** template named *Offboard inactive users*.
   - Click **Select**.

3. **Configure basic workflow details**
   - Enter a workflow name (for example `Leaver - Inactive Users`).
   - Add description (for example describing deprovisioning of privileged admin accounts).
   - Click **Next**.

4. **Set administration scope to an administrative unit**
   - In the workflow setup, open the **Administrations scopes** by clicking **No selected scopes**.
   - Select one of the AUs you created in Lab 2.5. Click **Select**.
   - Confirm and continue.

5. **Configure trigger and workflow tasks**
   - Complete the setup of the workflow based on your own wishes. 

6. **Verify restricted management of workflow**
   - Sign in with a user who has the Lifecycle Workflows Administrator role, but is outside the AU set in scope. 
   - Do the same for a user who has the Lifecycle Workflows Adminsitrator role and is a member of the AU set in scope. 
   - Verify that only the member of the scoped AU can administer the workflow. 

&nbsp;

## Lab 2.7 - Enable SCIM API and Test with Postman

In this final section, you enable the SCIM API, configure app-based authentication, and validate API connectivity in Postman.

> 📌 **Important**  
> Microsoft Entra SCIM Provisioning API is billed per transaction.

### Prerequisites:
- **Entra ID P1** license (or equivalent like P2, Microsoft 365 E3/E5)
- **Application Administrator** or **Cloud Application Administrator** role
- **Billing Administrator** role to enable SCIM API billing
- **Active Azure subscription** linked to your Entra tenant (for billing)

### Tasks:

1. **Enable SCIM Provisioning API in Entra Admin Center**
   - Go to **Identity Governance** → **Dashboard**.
   - Open the **SCIM Provisioning API** tile and complete subscription/resource group linking. This requires an Azure subscription and permissions to link payment to that subscription and resource group.
   - Turn on the feature.

2. **Create app registration for SCIM API access**
   - Create a new app registration (single-tenant).
   - Save:
     - **Application (client) ID**
     - **Directory (tenant) ID**
   - Add Microsoft Graph *application* permissions needed for your scenario. Start with User.ReadWrite.All and Group.Read.All
   - Grant admin consent.
   - Create a client secret and copy it securely.

3. **Create a Postman environment**
   There are resource files available to get a head start, but you can also do this manually if you want.
   Environment setup: [Environment](../../resources/resource-5-SCIM-postman-collection/ELUK2026.postman_environment)
   Download the files and import them into Postman. You will need, tenantID, clientID and client secret as inputs in the environment.

   - Create an environment and add variables for:
     - `tenant_id`
     - `client_id`
     - `client_secret`
     - `token`
   - Use environment variables in your token and SCIM API requests.

4. **Test token retrieval and SCIM API connectivity**
   There are resource files available to get a head start on request to the SCIM 2.0 API.
   Request Collection: [Collection](../../resources/resource-5-SCIM-postman-collection/ELUK2026.postman_collection.json)
   Download the files and import them into Postman. You will need, tenantID, clientID and client secret as inputs in the environment.
   Remember to set the environment in the collection.
   - First you will have to request a token
   - Save token to `token` in the environment (Script added for this in the GetToken POST-request if using resource files. )
   - Create/or use our collection for all your SCIM-requests and reuse token (OAuth 2.0) under Authorization config for the entire collection. All other requests can inherit from parent.
   - Test SCIM API endpoints:
   API documentation: https://learn.microsoft.com/en-us/entra/identity/app-provisioning/entra-id-scim-api-reference

   1. **ServiceProviderConfig**
   Endpoint: https://graph.microsoft.com/rp/scim/serviceproviderconfig
   Method: GET
   Minimum permissions: User.Read.All and Group.Read.All

   2. **ResourceTypes**
   Endpoint: https://graph.microsoft.com/rp/scim/resourcetypes
   Method: GET
   Minimum permissions: User.Read.All and Group.Read.All

   3. **Schemas**
   Endpoint: https://graph.microsoft.com/rp/scim/schemas
   Method: GET
   Minimum permissions: User.Read.All and Group.Read.All - Optional: CustomSecAttributeDefinition.Read.All to read schema for Custom Security Attributes
   
   4. **List Users or Get User**
   Endpoint: https://graph.microsoft.com/rp/scim/users or byId: https://graph.microsoft.com/rp/scim/users/{id}
   Method: GET
   Minimum permissions: User.Read.All

   5. **Create User**
   Endpoint: https://graph.microsoft.com/rp/scim/users
   Method: POST
   Minimum permissions: User.ReadWrite.All
   Required attributes: userName, password, name.familyName, name.givenName, active, displayName, urn:ietf:params:scim:schemas:extension:Microsoft:Entra:2.0:User:mailNickname

   6. **Update User - single or multiple values at the same time**
   Endpoint: https://graph.microsoft.com/rp/scim/users/{id}
   Method: PATCH 
   Minimum permissions: User.ReadWrite.All

   7. **Delete User**
   Endpoint: https://graph.microsoft.com/rp/scim/users/{id}
   Method: DELETE 
   Minimum permissions: User.ReadWrite.All

   8. **List Groups or Get Group**
   Endpoint: https://graph.microsoft.com/rp/scim/groups or byId: https://graph.microsoft.com/rp/scim/groups/{id}
   Method: GET
   Minimum permissions: Group.Read.All

   9. **Create Group**
   Endpoint: https://graph.microsoft.com/rp/scim/groups
   Method: POST
   Minimum permissions: Group.ReadWrite.All
   Required attribute: displayName

   10. **Update Group**
   Endpoint: https://graph.microsoft.com/rp/scim/groups/{id}
   Method: PATCH
   Minimum permissions: Group.ReadWrite.All

   11. **Delete Group**
   Endpoint: https://graph.microsoft.com/rp/scim/groups/{id}
   Method: DELETE
   Minimum permissions: Group.ReadWrite.All

   Play around with the endpoints for the API to get to know it better!


> 💡 **Note**  
> You can add additional Postman request examples later (create user, update user, disable user, delete user).
