variable "prefix" {
    description = "myProjectPrefix"
    default = "azureDevOpsCourse"
}

variable "location" {
    description = "I chose to create the VM in Europe because I am in Europe and by chosing a European location I will have lower latency and better UX for my clients."
  default = "westeurope"
}

variable "instance_count" {
    description = "The number of your virtual machines"
  default = 2
}

variable "managed_disks_size"{
  description = "The size of managed disks (GB)"
  default = 1
}