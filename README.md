![katacoda-scenarios Header](https://github.com/user-attachments/assets/6e171419-ed40-4865-a4d3-0de0adf7a200)

# katacoda-scenarios

## KSM Scenarios Feature Matrix

This table provides a quick overview of the key features covered in each Keeper Secrets Manager (KSM) SDK and integration tutorial available in this repository.

| Feature                        | Python SDK | Java SDK | .NET SDK | Go SDK   | JavaScript SDK | Ansible | KSM CLI | Terraform | HashiCorp Vault | GitHub Actions |
|--------------------------------|------------|----------|----------|----------|----------------|---------|---------|-----------|-----------------|----------------|
| **Setup & Installation**       | ✅         | ✅       | ✅       | ✅       | ✅             | ✅      | ✅      | ✅        | ✅              | ✅             |
| **Initial Connection/Auth**    | ✅         | ✅       | ✅       | ✅       | ✅             | ✅      | ✅      | ✅        | ✅              | ✅             |
|  - One-Time Token              | ✅         | ✅       | ✅       | ✅       | ✅             | ✅      | ✅      | ➖        | ➖              | ➖             |
|  - Config File (ksm-config.json)| ✅         | ✅       | ✅       | ✅       | ✅             | ✅      | ✅      | ✅        | ➖              | ➖             |
|  - Base64/In-Memory Config     | ✅         | ✅       | ✅       | ✅       | ✅             | ✅      | ✅      | ✅        | ✅              | ✅             |
| **List All Shared Records**    | ✅         | ✅       | ✅       | ✅       | ✅             | ➖      | ✅      | ➖        | ✅              | ➖             |
| **Get Specific Record by UID** | ✅         | ✅       | ✅       | ✅       | ✅             | ✅      | ✅      | ✅        | ✅              | ✅             |
| **Get Specific Record by Title**| ✅         | ✅       | ✅       | ✅       | ✅             | ➖      | ✅      | ➖        | ➖              | ✅             |
| **Access Record Fields**       | ✅         | ✅       | ✅       | ✅       | ✅             | ✅      | ✅      | ✅        | ✅              | ✅             |
|  - Standard Fields             | ✅         | ✅       | ✅       | ✅       | ✅             | ✅      | ✅      | ✅        | ✅              | ✅             |
|  - Custom Fields               | ✅         | ✅       | ✅       | ✅       | ✅             | ➖      | ✅      | ✅        | ✅              | ✅             |
|  - Notes                       | ✅         | ✅       | ✅       | ✅       | ✅             | ➖      | ➖      | ✅        | ✅              | ➖             |
| **Record Creation**            | ✅         | ✅       | ✅       | ✅       | ✅             | ➖      | ➖      | ✅        | ✅              | ➖             |
|  - With Various Field Types    | ✅         | ✅       | ✅       | ✅       | ✅             | ➖      | ➖      | ✅        | ✅              | ➖             |
|  - With Password Generation    | ✅         | ✅       | ✅       | ✅       | ✅             | N/A     | N/A     | 🛠️        | ➖              | ➖             |
| **Record Update**              | ✅         | ✅       | ✅       | ✅       | ✅             | ➖      | ✅      | ✅        | ✅              | ➖             |
| **Record Deletion**            | ✅         | ✅       | ✅       | ✅       | ✅             | ➖      | ➖      | ✅        | ✅              | ➖             |
| **Folder Creation/Mgmt.**      | ✅         | ✅       | ✅       | ✅       | ✅             | ➖      | ➖      | ✅        | ➖              | ➖             |
|  - Create Folder               | ✅         | ✅       | ✅       | ✅       | ✅             | ➖      | ➖      | ✅        | ➖              | ➖             |
|  - List Folders                | ✅         | ✅       | ✅       | ✅       | ✅             | ➖      | ➖      | ✅        | ➖              | ➖             |
|  - Rename Folder               | ✅         | ✅       | ✅       | ✅       | ✅             | ➖      | ➖      | ✅        | ➖              | ➖             |
|  - Delete Folder               | ✅         | ✅       | ✅       | ✅       | ✅             | ➖      | ➖      | ✅        | ➖              | ➖             |
| **File Upload to Record**      | ✅         | ✅       | ✅       | ✅       | ✅             | ➖      | ✅      | ✅        | ➖              | ➖             |
| **File Download from Record**  | ✅         | ✅       | ✅       | ✅       | ✅             | ✅      | ✅      | ✅        | ➖              | ✅             |
| **File Delete from Record**    | ✅         | ✅       | ✅       | ✅       | ✅             | ➖      | ➖      | ✅        | ➖              | ➖             |
| **Client-Side Caching**        | ✅         | ✅       | ✅       | ✅       | ✅             | ✅      | ✅      | ➖        | ➖              | ➖             |
| **CLI/Tool Specific Features** | N/A        | N/A      | N/A      | N/A      | N/A            | ✅      | ✅      | N/A       | ✅              | ✅             |

**Legend:**
- ✅: Feature is explicitly covered or conceptually explained in the tutorial.
- ➖: Feature is not explicitly covered or is not applicable to the tool's primary focus in the tutorial.
- 🛠️: Feature is partially covered, covered via tool-specific means, or conceptually discussed.
- N/A: Not Applicable.

**Notes:**
- All SDKs inherently support the full range of KSM capabilities (listing, getting, creating, updating, deleting records/folders/files). The table reflects what is *emphasized and demonstrated within the tutorial steps* of this repository.
- For CLI tools (KSM CLI), many features are available through their rich command sets, even if not every single one is part of a specific tutorial step.

This matrix should help users navigate to the scenario that best fits their learning goals or integration needs.
