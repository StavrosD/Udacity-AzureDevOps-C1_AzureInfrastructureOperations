# Azure Infrastructure Operations Project: Deploying a scalable IaaS web server in Azure

### Introduction
For this project, you will write a Packer template and a Terraform template to deploy a customizable, scalable web server in Azure.

### Getting Started
1. Clone this repository

2. Create your infrastructure as code

3. Update this README to reflect how someone would use your code.

### Dependencies
1. Create an [Azure Account](https://portal.azure.com) 
2. Install the [Azure command line interface](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
3. Install [Packer](https://www.packer.io/downloads)
4. Install [Terraform](https://www.terraform.io/downloads.html)

### Instructions
In order to support application deployment, a server immage should be created and deployed to a virtual machine.

Packer will be used for the server image creation and terraform will be used for provisioning the infrastructure.

Packer is a tool that creates an image using a settings file that supply the required parameters such as the operating system.

Terraform is a  tool that creates the infrastructure using a JSON configuration file.

#### 1. Login
After installing the Azure CLI, open a terminal window and log in to your azure account.
> az login

#### 2. Server image creation
On the terminal windows, go to the folder where you cloned the repository. The file server.json is the packer file that describes the server image. 

The specific file will create an Ubuntu 18.04-LTS server image.
Before creating the image a service principal is required to allow packer creating resources in your azure account.

Use the following command to create a service principal and configure it for auzre access.
> az ad sp create-for-rbac --query "{ client_id: appId, client_secret: password, tenant_id: tenant }"

After running this command, the following info will be displayed in your terminal window:
> {
>  "client_id": "your client id,
>  "client_secret": "your client secret",
>  "tenant_id": "your tenant id"
>}

Never share this info on internet, github, email, etc.

Then, use the following command to get the subscription id (key: "id")
> az account show 

You may use these values either by calling them each time using packer parameters but it is more useful to export them on the envinroment so it will be easier to use packer.

On Mac, you may use the following commands:

> export ARM_CLIENT_ID="your client id"
> export ARM_CLIENT_SECRET="your client secret"
> export ARM_TENANT_ID="your tenant id"
> export ARM_SUBSCRIPTION_ID="your subesciption id"

Now everything is set up to create the server image using packer.
> packer build server.json

After a while, the server image will be ready on your azure account.

#### 3. Create infrastructure


The following infrastructure will be automatically created using Terraform:

*  a Resource Group.

* a Virtual network and a subnet on that virtual network.

* a Network Security Group with policies that explicitly allow access to other VMs on the subnet and deny direct access from the internet.

* a Network Interface for each virtual machine.

* a Public IP.

* a Load Balancer. 

* a virtual machine availability set.

* virtual machines using the image you deployed using Packer!

* disks for the virtual machines.

Before using Terraform, it is required to either login via a microsoft account or via service principal 
Assuming that you did not close the terminal window, you should be already logged in via a microsoft account (az login).

Use the following commands to create the infrastructure using Terraform:

Initialize terraform:
> terraform init

The next step is to customize the infrastructure. The file variables.tf contains variables that can be changed to match your project requirements.
The following variables are available:
* prefix : a prefix that will be used on each resource 
* location: The location where the resources will be created
* instance_count: The number of the virtual machines that will be created
* managed_disks_size: The size of each VMs' managed disks (GB)
You may either modify the default value or call terraform using the "-var" parameter
> terraform apply -var variable_name="value"

 


Calculate a plan and save it to a file:
> terraform plan -out solution.plan  

Apply the plan:
> terraform apply solution.plan

After a few minutes, the infrastructure should be ready. You may see the new infrastructure using the command:
> terraform show

If you no longer need the infrustructure run the following command to take it down:
> terraform destroy

Then verify that everything is destroyed, use:
> terraform show


### Output
##### 1. Packer
When you run packer, a list of the executed actions will be displayed in green color.
If everything works as expected, you should see a line with different color:
> ==> azure-arm: + echo Hello, World!
If you see this message then the provisioning shell script was executed as expected. 

When the image creation is completed, a verification message will be displayed.
>==> Wait completed after 19 minutes 288 milliseconds
>==> Builds finished. The artifacts of successful builds are:
>--> azure-arm: Azure.ResourceManagement.VMImage:
>...

You may verify the image creation using the Azure portal, under "All resources" an image named "myPackerProjectImage" will be avaiable that belongs to the "UdacityDevOpsResourceGroup" resource group.


##### 2. Terraform
After running "terraform init", you should see the message:
> Terraform has been successfully initialized!

Next, running "terraform plan -out solution.plan" should create the file "solution.plan" in the current directory and a detailed plan should be displayed.
A summary with the number of resources that will be created is also displayed
> Plan: 21 to add, 0 to change, 0 to destroy.
 
Finally, after running "terraform apply solution.plan" a message will be displayed that verifies that the resources are created successfully.

The resources will be vissible in your Azure Portal account under the "azureDevOpsCourse-resources" resource group.
![Created resources](https://github.com/StavrosD/Udacity-AzureDevOps-C1_AzureInfrastructureOperations/raw/main/resources.png)

