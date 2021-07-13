https://builtin.com/software-engineering-perspectives/automate-azure-app-terraform-ansible



terraform.tfvars


location = "Southeast Asia"
resource_group = "nilavembu-rg-corp"
cloud_shell_source = "20.106.152.225"
domain_name_prefix = "nilavembu"
management_ip = "106.212.145.12"



--------------------------


variables.tf

variable "location" {
    type = string
}

variable "resource_group" {
    type = string
}

variable "cloud_shell_source" {
    type = string
}

variable "management_ip" {
    type = string
}

variable "domain_name_prefix" {
    type = string
}


----------------------

https://raw.githubusercontent.com/NoBSDevOps/BookResources/master/Part-II-Project/Virtual-Machines/Ansible-Configuration/hosts

[azurevms]
# Public IPs of the Azure VM Machines
40.122.168.175
40.122.168.162

[azurevms:vars]
ansible_user=vmadmin
ansible_password=Vmadmin!2345
ansible_connection=winrm
ansible_winrm_transport=basic
ansible_winrm_server_cert_validation=ignore
ansible_port=5986




