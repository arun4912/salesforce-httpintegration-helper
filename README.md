# Salesforce Integration Helper

A Salesforce package for configurable HTTP integrations using Custom Metadata Types. Provides reusable Apex classes for HTTP callouts with endpoint URLs, headers, and static values configured via Custom Metadata.

## Components

### Apex Classes

- **IntegrationHelper** – Handles HTTP endpoint configuration, headers, and static values from Custom Metadata
- **IntegrationUtility** – Performs HTTP callouts with configurable timeouts and error logging

### Custom Metadata Types

- **Integration Setting** (`Integration_Setting__mdt`) – Parent metadata for API configuration (URL, method, timeout, target system)
- **Integration Setting Detail** (`Integration_Setting_Detail__mdt`) – Child metadata for headers and static parameters (key-value pairs)

## Integration Setting Fields

| Field | Type | Description |
|-------|------|--------------|
| Name | Text | Display name or path suffix |
| Active | Boolean | Whether this setting is active |
| Method | Picklist | HTTP method (GET, POST, PUT, PATCH, DELETE) |
| Session Timeout | Number(3,0) | Request timeout in seconds |
| Target System | Picklist | External or Internal |
| Webservice URL | Text(255) | Endpoint URL |

## Integration Setting Detail Fields

| Field | Type | Description |
|-------|------|--------------|
| Name | Text | Display name |
| Integration Setting | Lookup | Parent Integration Setting |
| Active | Boolean | Whether this detail is active |
| Key | Text(100) | Header name or parameter key |
| Type | Picklist | Header, Static, String, Number, Boolean, URL |
| Value | Long Text Area | Header value or parameter value |

## Usage

```apex
// Deploy Integration Setting first, then create Integration Setting Detail records.
// Use DeveloperName as the service name when calling:

HttpRequest req = new HttpRequest();
req = IntegrationHelper.getHttpEndPointUrl(req, 'MyServiceName');
req.setBody('{"key":"value"}');

HttpResponse res = IntegrationUtility.performHttpCallout(req.getBody(), 'MyServiceName');
```

## Deployment

```bash
# Deploy to your org
sf project deploy start --source-dir force-app

# Or deploy specific components
sf project deploy start --metadata "ApexClass:IntegrationHelper,ApexClass:IntegrationUtility,CustomObject:Integration_Setting__mdt,CustomObject:Integration_Setting_Detail__mdt"
```

**Note:** Deploy `Integration_Setting__mdt` before `Integration_Setting_Detail__mdt` (the child references the parent).

## Requirements

- Salesforce API version 62.0 or later
- Salesforce CLI (sf)

## GitHub Setup

To push this project to GitHub:

```bash
cd salesforce-integration-helper

# Initialize git (if not already done)
git init

# Add all files
git add .

# Initial commit
git commit -m "Initial commit: IntegrationHelper, IntegrationUtility, and Custom Metadata Types"

# Create a new repository on GitHub (github.com/new), then:
git remote add origin https://github.com/YOUR_USERNAME/salesforce-integration-helper.git
git branch -M main
git push -u origin main
```

Or use GitHub CLI:

```bash
cd salesforce-integration-helper
git init
git add .
git commit -m "Initial commit: IntegrationHelper, IntegrationUtility, and Custom Metadata Types"
gh repo create salesforce-integration-helper --public --source=. --push
```

## License

MIT
