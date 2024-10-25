---

marp: true

theme: softwire
headingDivider: 3
paginate: true
---

<style>
section::after {
  content: attr(data-marpit-pagination) '/' attr(data-marpit-pagination-total);
}
</style>

# A Beginner's Guide to Terraform

## Overview

Introduction
- What is Terraform?
- Infrastructure as code
- The Terraform language

Core Terraform Concepts
- Resources
- Data sources
- Providers and the `terraform` block
- Modules
- Variables and outputs
- The Terraform state file and the `backend` block

## Overview

Terraform Commands
- `init`
- `fmt` and `validate`
- `plan`
- `apply`
- `destroy`

More on the Terraform Language
- Meta-arguments
- Expressions
- Functions

Terraform In Practice
- Structuring a Terraform project
- Integrating into CI/CD pipelines

# Introduction

## What is Terraform?

- An infrastructure as code tool
    - i.e. Lets you create and modify infrastructure with configuration files
    - These files can be stored in a repository to take advantage of versioning

- The Terraform workflow consists of 3 stages:
    - **Write**: define resources in configuration files
    - **Plan**: Terraform creates an execution plan describing what it will create, update and destroy
    - **Apply**: Terraform performs the changes 

- Works with virtually all cloud platforms (AWS, Azure, GCP etc)


## What is Infrastructure as Code?

IaC is just a fancy way of saying managing infrastructure with configuration files instead of through a GUI.

This is better for many reasons:
- You gain all the benefits of version control
    - e.g. collaboration, history, traceability, reviewing

- Infrastructure changes can fit into automated CI/CD workflows
    - Faster
    - Less error-prone

- Can easily and reliably duplicate changes across environments

- Benefits of code
    - Reuse bits of configuration
    - Linting

## The Terraform Language

Terraform's configuration language is **declarative**
- You describe the desired final state rather than steps to reach it

- Terraform figures out relationships between resources to determine the order of operations
- The ordering of blocks and the files they are organised into is **not** generally important

## The Terraform Language

The syntax of the language consists of:
- **Blocks**: containers with a type, zero or more labels and a body

- **Arguments**: assign a name to a value (which can be a block as well)
- **Expressions**: represent a value literally, or by referencing or combining values

```
resource "aws_vpc" "main" {
  cidr_block = var.base_cidr_block
}

<BLOCK TYPE> "<BLOCK LABEL>" "<BLOCK LABEL>" {
  # Block body
  <IDENTIFIER> = <EXPRESSION> # Argument
}
```

# Core Terraform Concepts

*A very brief tour of the key concepts*

## Resources
Resource blocks describe one or more infrastructure objects

```
resource "resource_type" "resource_name" {
  argument = expression
}
```
- The `resource_type` determines 
    - The kind of infrastructure object it manages
    - The arguments and attributes it supports
    - Look up the documentation for the resource type you want to use!

- There are also some meta-arguments that we will look at later

- Also called *managed resources* to distinguish from data sources

[More on resources](https://developer.hashicorp.com/terraform/language/resources)

## Data sources

Data sources allow Terraform to use information defined outside of your configuration files

```
data "data_source" "name" {
  argument = expression
}
```
- The `data_source`...
    - Tells Terraform where to read the data from
    - Determines the arguments it supports

- The `data_source` and `name` serve as an identifier and must be unique within a module

- Managed resources cause Terraform to create / update / delete infrastructure objects; data sources only cause Terraform to read objects

[More on data sources](https://developer.hashicorp.com/terraform/language/data-sources)

## Providers

Providers are plugins that allow Terraform to interact with cloud providers and other APIs
- Providers add *resource types* and *data sources*

- Most of the time you will use a provider from the [Terraform registry](https://registry.terraform.io/browse/providers?ajs_aid=9b04f4f7-8ad4-421b-95ff-ce56bb8de852&product_intent=terraform)
    - Terraform will install the latest version by default; you should constrain the version
    - If you need to *fix* the version, you can use a [dependency lock file](https://developer.hashicorp.com/terraform/language/files/dependency-lock)

- Providers must be declared within the `terraform` block, which configures Terraform behaviour

- Some providers require configuration themselves in a `provider` block

[More on providers](https://developer.hashicorp.com/terraform/language/providers)

[More on specifying versions](https://developer.hashicorp.com/terraform/language/expressions/version-constraints)

## Providers and the `terraform` block

```
terraform {
  required_version = ">= 1.2.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.63"
    }
  }
}

provider "aws" {
  region = "eu-west-2"
}
```

- Each provider has a local name (here, "aws") which must be used to refer to providers outside the `required_providers` block (e.g. in the `provider` block above)

- The `source` argument tells Terraform where to get the provider from

[More on the `terraform` block](https://developer.hashicorp.com/terraform/language/terraform)


## Variables

Variables take the following arguments:
- `type` - Specifies type of variable
- `description` - Documents usage (always write a description!)
- `default` - A default value; makes the variable optional; type must match `type`
- `validation` - Defines validation rules, usually in addition to type constraints
- `sensitive` - Limits Terraform UI output when the variable is used in configuration
- `nullable` - Specify if the variable can be null (default `true`)

[More on variables](https://developer.hashicorp.com/terraform/language/values)

[More on validation](https://developer.hashicorp.com/terraform/language/expressions/custom-conditions#input-variable-validation)

## Variable types

Basic types
- `string`
- `number`
- `bool`

Collection types
- `list<TYPE>` e.g. `["item_1", "item_2"]`
- `set<TYPE>` e.g. `toSet(["item_1", "item_2"])` N.B. no literal syntax, must use function
- `map<TYPE>` 
- `object({<ATTR_NAME> = <TYPE>, ... })`
- `tuple([<TYPE>, ... ])`

There is also `null` which has no type and indicates absence or omission

[More on types in Terraform](https://developer.hashicorp.com/terraform/language/expressions/types)

## Variable example

```
variable "docker_ports" {
  type = list(object({
    internal = number
    external = number
    protocol = string
  }))
  default = [
    {
      internal = 8300
      external = 8300
      protocol = "tcp"
    }
  ]
  description = "Configures Docker containers for application"
}
```

## Modules

Modules are the main way to package and reuse resource configurations
- A module is a collection of `.tf` and `.tf.json` files in a directory

- Every project has a *root* module consisting of resources defined in the `.tf` files in the main working directory

- Modules can call other modules to include their resources in their configuration
    - These modules are *child* modules
    - Usually this is the root module calling them
    - Modules often take input variables and can output values as well

- Modules can also be used from public / private registries, such as the Terraform registry

[More on modules](https://developer.hashicorp.com/terraform/language/modules)

## Modules and variables

Variables can be defined in the root module or in child modules
- Variables in the root module can be set with 
    - CLI options
    - Environment variables
    - `.tfvars` files

- Variables in child modules are set when calling the module

## Creating a module

- At a minimum, create a new directory containing
    - **main.tf**: this contains your module code (probably a bunch of resource definitions)
    - **variables.tf**: this contains variable definitions for your inputs
    - **outputs.tf**: this contains variable definitions for your outputs

- Provide descriptions for all your input and output variables

- Provide a README if the module is for external use

- Modules can call other modules, but Hashicorp recommend keeping the module tree flat and using [module composition](https://developer.hashicorp.com/terraform/language/modules/develop/composition) instead

## Module inputs and outputs

Inputs are defined in `variables.tf`, e.g.
```
variable "name" {
  type        = string
  description = "Name of user pool"
  nullable    = false
}
```

Outputs are defined in `outputs.tf`, e.g.
```
output "read_policy_arn" {
  value       = aws_iam_policy.read_access_policy.arn
  description = "Policy to read from S3 bucket"
}
```

Resources in the module are encapsulated so the caller cannot access them directly. You must declare output values to expose values to the caller

[More on output variables](https://developer.hashicorp.com/terraform/language/values/outputs)

## Local variables

Assigns a name to an expression for use within a module
```
# Usually placed at the top of the file

locals {
  service_name = "forum"
  common_tags = {
    Service = local.service_name
    Owner   = local.owner
  }
}
```

Using a local variable:
```
resource "aws_instance" "example" {
  # ...
  tags = local.common_tags
}
```

## Calling a module

To call a module, use the `module` block
```
module "servers" {
  source = "./app-cluster"
  servers = 5
}
```

- The `source` argument is required for all modules
    - A path to the module's directory
    - A remote module source that Terraform will download and use
    - Must be a literal string

- The `version` argument is recommended for modules installed from a module registry

- You must specify values for its input variables

## Accessing module outputs

E.g. referencing output `instance_ids` from module defined in `./app-cluster`

```
module "servers" {
  source = "./app-cluster"
  servers = 5
}

resource "aws_elb" "example" {
  # ...
  instances = module.servers.instance_ids
}
```

## Terraform state file

- Terraform stores the IDs and properties of the resources it manages in a file

- This allows it to update or destroy the resources in future

- The file contains sensitive information so it must be stored securely
    - By default, this is a local file on disk
    - In production, this is usually remotely (e.g. in an S3 bucket)

## Terraform state file and the `backend` block

The `backend` block placed within the top-level `terraform` block allows you to configure a remote location
```
terraform {
  backend "<TYPE>" {
    <ATTR_NAME> = <VALUE>
  }
}
```
- The `<TYPE>` specifies the set of attributes that need configuring
- You can have a partial configuration that is fleshed out by CLI arguments (e.g. when you want a different state file for each environment)

[More on the `backend` block](https://developer.hashicorp.com/terraform/language/backend)

[Storing in S3](https://developer.hashicorp.com/terraform/language/backend/s3)

# Terraform Commands

## `terraform init`

- Initialises a directory

- When run in an existing configuration, will download and install all defined providers

```
$ terraform init

Initializing the backend...

Initializing provider plugins...
- Finding hashicorp/aws versions matching "~> 4.16"...
- Installing hashicorp/aws v4.17.0...
- Installed hashicorp/aws v4.17.0 (signed by HashiCorp)

Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above. Include this file in your version control repository
so that Terraform can guarantee to make the same selections by default when
you run "terraform init" in the future.

Terraform has been successfully initialized!
```

## `terraform fmt` and `terraform validate`

Run these before pushing a PR / merging changes!

`terraform fmt`
- Formats terraform files in the current directory

- Use `-recursive` to format your whole configuration (when run from the root directory)

- Any modified files will print to console (if none print, your files are correctly formatted)

    ```
    $ terraform fmt -recursive
    ```

`terraform validate`
- Checks configuration is syntactically valid and consistent

    ```
    $ terraform validate
    Success! The configuration is valid.
    ```

## `terraform plan`

- Lets you preview the changes Terraform plans to make to your infrastructure

- Does not actually carry out the changes

- Use the `-out=<FILENAME>` argument to output the plan to a file that can be applied at a later stage (primarily for use in CI/CD pipelines)

- Values dynamically decided by the remote system are not known at this stage and are shown as `(known after apply)`

- You should run this command when making infra changes to check your changes are as you intended!

[More on the `terraform plan` command](https://developer.hashicorp.com/terraform/cli/commands/plan)

## `terraform apply`

- Generates a plan for you to approve before applying the changes to your infrastructure

    ```
    $ terraform apply

    Terraform will perform the following actions:

    # aws_instance.app_server will be created
    + resource "aws_instance" "app_server" {
        + ami                          = "ami-830c94e3"
        + arn                          = (known after apply)

    Plan: 1 to add, 0 to change, 0 to destroy.

    Do you want to perform these actions?
    Enter a value:
    ```

- Pass in the filename of a plan generated by `terraform plan` to immediately execute the changes without needing approval

[More on the `terraform apply` command](https://developer.hashicorp.com/terraform/cli/commands/apply)

## `terraform destroy`

- Destroys all remote objects managed by a Terraform configuration

- Shorthand for `terraform apply -destroy`

- Can create a speculative destroy plan with `terraform plan -destroy`

- Useful for cleaning up infrastructure from experiments to avoid unnecessary costs!

## Other CLI commands

- There are many other commands not covered here that you can [find in the docs](https://developer.hashicorp.com/terraform/cli/commands)

- Most are quite niche hence why they're not covered

# More on the Terraform language

## Meta-Arguments

- Like arguments, but with extra functionality

- Applicable to language constructs (e.g. `resource`) rather than types (e.g. `aws_s3_bucket`)

- We will look at `count` and `for_each` which are widely used, but there are others:
  - [`depends_on`](https://developer.hashicorp.com/terraform/language/meta-arguments/depends_on): specify dependencies Terraform cannot automatically infer
  - [`lifecycle`](https://developer.hashicorp.com/terraform/language/meta-arguments/lifecycle): specify lifecycle rules for a resource (e.g. `prevent_destroy`)
  - [`provider`](https://developer.hashicorp.com/terraform/language/meta-arguments/resource-provider): specify which config to use when you have multiple for a single provider

## Meta-Arguments: `count` and `for_each`

- By default a `resource` block configures a single infrastructure object
  - Similarly a `module` block includes the child module's contents once

- `count` and `for_each` are two ways of managing several similar objects or modules without writing a separate block for each one

- Conveniently, they can also be used to conditionally create objects or modules

## Meta-Arguments: `count`

- `count` accepts a whole number and creates that many instances of a resource or module

- It makes a value `count.index` available with the index number
  ```
  resource "aws_instance" "server" {
    count = 4                          # create four similar EC2 instances
    tags = {
      Name = "Server ${count.index}"
    }
  }
  ```

- You can conditionally create resources with a ternary expression
  ```
  resource "<TYPE>" "<NAME>" {
    count = <BOOLEAN_EXPRESSION> ? 1 : 0
  }
  ```

- To refer to an instance, use `<TYPE>.<NAME>[<INDEX>]` e.g. `aws_instance.server[1]`

[More on the `count` meta-argument](https://developer.hashicorp.com/terraform/language/meta-arguments/count)

## Meta-Arguments: `for_each`

- `for_each` takes as map or set and creates an instance for each member

- For sets, it makes a value `each.key` available with the current set member

- For maps, it makes `each.key` and `each.value` available with the current key and value

- To refer to an instance, use `<TYPE>.<NAME>[<KEY>]` e.g. `azurerm_resource_group.rg["a_group"]`

```
resource "azurerm_resource_group" "rg" {
  for_each = tomap({
    a_group       = "eastus"
    another_group = "westus2"
  })
  name     = each.key
  location = each.value
}
```

[More on the `for_each` meta-argument](https://developer.hashicorp.com/terraform/language/meta-arguments/for_each)

## Expressions

- We've had a quick look at types (and therefore literals) in the 'variables' section

- We'll look at all expressions I've used in practice (there's more in the links provided):
    - Accessing elements in maps, tuples, lists and sets
    - Strings
    - Referencing values
    - For and splat expressions
    - `dynamic` blocks

- There's some [interesting stuff on validations and custom constraints](https://developer.hashicorp.com/terraform/language/expressions/custom-conditions) I've not ever used so we won't cover it

## Expressions: maps, tuples, lists and sets

- Elements of lists and tuples are accessed using square brackets e.g. `list[3]`

- Elements of maps and objects can be accessed using
    - Square brackets e.g. `map["keyname"]`
    - Dot-separated attribute notation e.g. `object.attrname`

- Sets do not support accessing as they are unordered collections
    - Convert them to lists first using the `tolist` function 
    - e.g. `tolist(var.myset)[0]`

## Expressions: strings

- Multi-line strings:
    ```
    description = <<-EOT
      This is a multi-line string, indicated by "<<". The "-" indicates it's indented; Terraform finds 
      the line with the fewest leading spaces and trims that many spaces from the start of each line.
    EOT
    ```

- String interpolation
    ```
    "Hello, ${var.name}!"
    ```

- Terraform will guarantee valid JSON with the `jsonencode` function (`yamlencode` for YAML)
    ```
    example = jsonencode({
      b = "hello"
    })
    ```

[More on strings](https://developer.hashicorp.com/terraform/language/expressions/strings)

## Expressions: references to values

- **Resources**: `<RESOURCE_TYPE>.<NAME>` will return
    - An object if the resource doesn't use the `count` or `for_each` meta-arguments
    - A list of objects if it uses `count`
    - A map of objects if it uses `for_each`

- **Input variables**: `var.<NAME>`

- **Local variables**: `local.<NAME>`

- **Module outputs**: `module.<MODULE_NAME>` has the same rules as for resources

- Other helpful references:
    - `path.root`: the filesystem path of the root module of the configuration

## Expressions: for and splat

- List and object comprehension:
    - e.g. `[for idx, value in var.list : "${idx} is ${value}"]`
    - e.g. `{for key, device in aws_instance.example.device : key => device.size}`
    - If one argument provided, will ignore index for lists, key for maps

- Splat expressions e.g. `var.list[*].id` is shorthand for `[for o in var.list : o.id]`

- Filtering uses an `if` clause 
    - e.g. `[for s in var.list : upper(s) if s != ""]`
    - e.g. `admin_users = {for name, user in var.users : name => user if user.is_admin}`

[More on for expressions](https://developer.hashicorp.com/terraform/language/expressions/for)

## Expressions: `dynamic` blocks

- In top-level blocks (like resources), expressions can only be used when assigning a value to an argument with the `name = expression` form

- Some resource types include repeatable *nested* blocks in their arguments

- These represent separate objects related or embedded within the containing object
  
  ```
  resource "aws_elastic_beanstalk_environment" "tfenvtest" {
    name = "tf-test-name" # can use expressions here

    setting {
      # but the "setting" block is always a literal block
    }
  }
  ```

- `dynamic` blocks allow us to *dynamically* create these nested blocks rather than copy pasting them (in much the same way that the `count` and `for_each` meta-arguments allow us to do the same with top-level blocks)

[More on `dynamic` blocks](https://developer.hashicorp.com/terraform/language/expressions/dynamic-blocks)

## Expressions: `dynamic` blocks

```
resource "aws_elastic_beanstalk_environment" "tfenvtest" {
  name                = "tf-test-name"

  dynamic "setting" {
    for_each = var.settings
    content {
      name = setting.value["name"]
      value = setting.value["value"]
    }
  }
}
```
- Label of the `dynamic` block, here `"setting"`, specifies the kind of nested block to generate

- Required `for_each` argument provides the values to iterate over; the iterator symbol (name for the current element of the `for_each` value) is the `dynamic` block's label (`setting`)
- Required nested `content` block defines the body of each generated block

## Expressions: `dynamic` blocks

- Useful for generating conditional nested blocks:
  ```
  dynamic "<BLOCK_TYPE>" {
    for_each = <BOOLEAN> ? <VALUE_TO_ITERATE> : [] # or {} for maps
    content {
      # ...
    }
  }
  ```

- Overuse can make configuration harder to read and maintain! Prefer writing blocks out literally where possible

## Functions

Terraform includes many built-in functions that can be called in expressions to transform or combine values.
- Function syntax is `<FUNCTION NAME>(<ARGUMENT 1>, <ARGUMENT 2>)`

- You can expand lists or tuples into separate arguments by using three periods after the list or tuple reference

- You can experiment with functions by using `terraform console`
```
$ terraform console
> max(5, 12, 9)
12
> min([10, 9, 8]...)
8
> exit
$ _
```

You can find [a full list of functions here](https://developer.hashicorp.com/terraform/language/functions); it might be useful to see what's available!

# Terraform in Practice

## Structuring a Terraform project: Small projects

There's no set way to structure a project, but I'll show some suggestions for different-sized projects based off what I've seen in practice.

At a minimum, a Terraform project probably contains the following files. We only have the root module and the amount of configuration is small, so it all goes into `main.tf`

```
terraform
| main.tf
| outputs.tf
| variables.tf
```

## Structuring a Terraform project: Projects with modules

Modules have their own directories under `./terraform`. For clarity, it might be best to place them under `./terraform/modules`

If your `main.tf` file is getting too long, you may consider *only* putting your `terraform` and `provider` configurations in it, as well as any `local` variables for your root module. You can create other `.tf` files in the root module to place the rest of your configuration in.

```
terraform
├── <MODULE NAME>
|   ├── main.tf
|   ├── outputs.tf
|   ├── variables.tf
├── ... other modules
├── main.tf
├── outputs.tf
├── variables.tf
├── ... other .tf configuration files
```

## Structuring a Terraform project: Multiple environments

There are multiple approaches to this. Usage of variable files (`.tfvars` files) is shown below

```
terraform
├── environments
|   ├── live
|   |   ├── state.tfvars
|   |   ├── variables.tfvars
|   ├── ... other environments
├── modules
|   ├── <MODULE NAME>
|   |   ├── main.tf
|   |   ├── outputs.tf
|   |   ├── variables.tf
|   ├── ... other modules
├── resources
|   ├── ... e.g. files to go in S3 buckets 
├── main.tf
├── outputs.tf
├── variables.tf
├── ... other .tf configuration files
```

## Structuring a Terraform project: Large projects
To support multiple environments you might consider:
- Terraform workspaces
- Separate configurations (i.e. a different root module) for each environment 
- Wrappers e.g. Terragrunt

Each has their trade-offs and I won't attempt to cover them.

I'm not an expert in structuring Terraform projects nor will you expected to be — this is tech-lead territory at a minimum!

## CI/CD Integration

Through Terraform we have made it possible to:
- Collaborate on provisioning and maintaining infrastructure
- Version control our infra
- Rollback changes easily
- Configure multiple environments easily

The process of releasing changes to environments (by running `terraform` CLI commands) is still quite manual and prone to human error.
- We need to run multiple commands
- We need to retrieve secrets to deploy changes

What might we want to automate?

## CI/CD Integration: Tasks to automate

- Pre-commit hooks to format and validate our Terraform code
*Helps catch issues early and enforces styling rules*

- Run `terraform plan` when creating a PR 
*Shows planned changes to the reviewer without them having to check out the branch and run the command themselves*

- Automate fetching secrets
*Reduces risk of bad security practices*

- Automated deployment to staging environment on merge to main
*Greater development velocity — can build, deploy and test changes quicker*

- CI/CD workflows to deploy versions to an environment
*Automates the process of deploying changes to an environment; easy for anyone to run*

## Exercise

We're going to try provisioning infrastructure to deploy a static website in a locally-hosted version of AWS. This will let us play around with Terraform without worrying about costs! 

We'll be using LocalStack, which emulates many AWS services; some of them are only available with a pro license. Softwire doesn't seem to have an appropriate pro licence for us to play around with, so we'll only use the free services.

Unfortunately ECS is one of them so we can't try deploying a containerised version of our Node apps!

## Exercise: Installing

- [Sign up for a LocalStack account](https://app.localstack.cloud/)

- Install [LocalStack desktop for Windows](https://apps.microsoft.com/detail/9ntrnft9zws2?hl=en-gb&gl=US) from the Microsoft Store. This will let us browse our created resources in a GUI, which is just a bit easier

- Install Docker desktop

- On WSL2 (to make installing `tflocal` easier):
  - Install `tflocal`: `pip install terraform-local`; it's a wrapper around the `terraform` command for running commands against LocalStack
  - [Install `terraform`](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli#install-terraform)
  - Verify installations with `terraform -help` and `tflocal -help` (you should get the same output)

- (Recommended) Install the Terraform language extension for your IDE

## Exercise: Starting up what we need

- Start Docker desktop

- Start LocalStack desktop and create a new container
  - Give the container a name (e.g. `IntroToTerraformLocalStackContainer`)
  - For image use `localstack/localstack:latest`
  - Find your auth token by signing into your account in a browser

- Once created, click on your container and select the resource browser at the top (the 2x3 grid of squares icon)
  - You'll be prompted to log in to see this screen
  - The screen shows which services require a pro license
  - Clicking into a service shows all resources you've created within it

## Exercise: Creating resources with Terraform

- Create a new directory to place all your Terraform in (for ease later on, you should place this in or close to the directory containing your website's files)

- Add the following files:
  - `provider.tf` which will contain our provider configuration
  - `main.tf` which will contain the main code for our root module
  - `variables.tf` which will contain any root module variables

## Exercise: Provider

There's a fair bit of config to get the AWS provider working with LocalStack. The details aren't particularly important so we can just copy paste this in:

```
provider "aws" {
  region     = "us-east-1"
  access_key = "fake"
  secret_key = "fake"

  s3_use_path_style           = false
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    s3 = "http://s3.localhost.localstack.cloud:4566"
    # For any other services we want to use, the endpoint should be "http://localhost:4566"
  }
}
```

After adding this, run `terraform init` to initialise Terraform in the directory and download the AWS provider

## Exercise: Creating the S3 bucket resources

For the rest of the exercise, we need to create a few resources. I will link the docs for each resource type required and let you figure out the configuration we need for each! 

You may want to try running the steps in the `terraform apply` slide after adding each resource to check you've done it correctly.

- Create an [`aws_s3_bucket` resource](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket); this creates your bucket

- Create an [`aws_s3_bucket_website_configuration` resource](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_website_configuration); this configures an S3 bucket as a static website

- Create [`aws_s3_object` resources](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_object) for each website file you want to put in your bucket
  - You'll need to set the `acl` argument
  - If you set the `content_type` argument, you won't need to specify `.html` in the URL

## Exercise: Creating the S3 bucket resources

Create an [`aws_s3_bucket_policy` resource](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy)
- This specifies:
  - `resource`: the bucket the policy applies to
  - `actions`: the [set of actions](https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-with-s3-policy-actions.html#using-with-s3-policy-actions-related-to-objects) that you will allow
  - `principal`: who is allowed access to actions and resources on the bucket

- Have a think about what each of these should be so you can access your website files in the bucket in the browser

- The policy itself is just JSON; you can pass it a reference to a [`aws_iam_policy_document` block](https://registry.terraform.io/providers/aaronfeng/aws/latest/docs/data-sources/iam_policy_document) or use the `jsonencode()` function

## Exercise: `terraform apply` and viewing the website

- Format and validate your Terraform code

- Run `tflocal plan` to show the Terraform plan

- Run `tflocal apply` to apply the changes
  - You should be able to see your created resources in LocalStack Desktop

- You can see your deployed website at 
  ```
  http://<BUCKET_NAME>.s3-website.us-east-1.localhost.localstack.cloud:4566
  ```

- When you're finished, clean up with `tflocal destroy`

## Exercise: Extensions

- Can you add the website address as an output, so we don't have to figure it out by looking through the configuration?
  - Add an `outputs.tf` file to define it

- Can you use a `for_each` to iterate over your website files, instead of writing an `aws_s3_object` resource for each one?
  - The `fileset()` and `basename()` functions may be of use

- Can you create an S3 module?
  - What might be useful to configure via variables?
  - What outputs might be useful?

- Can you store your tfstate file in an S3 bucket?
  - You'll need to create this bucket in LocalStack outside of your Terraform configuration and then configure Terraform to use it