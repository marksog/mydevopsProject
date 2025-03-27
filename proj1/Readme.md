# Project 1

Me thinking that encoporates GitHub, jenkins, Testing, monitoring (using prometheus and grafana).
Build the infrastructure using Terraform.
Infrastructure
1 VPC
2 private subnet
Private subnet connects to the internet vai NAT
2 public subnet
Setup IAM Roles
4 Load balancers. One for each subnet.
Each subnet has 4 servers behind the load balancer.
they provide two information
    - each server is apache webserver displaying its hostname and subnet (private or public they are found in)

Later 
Unsing ansible:
add the disk sizes of the servers if they are small
install docker or podman
write docker file to install nginx, and also display information about container (ip, port, etc)
run docker on all images
install kubernetics
deploy kubernetes
Also implements auto-scalling with kubernetes

Deploy using Jenkins

later add installation for grafana and prometheus 

Set up testing using testing tools

also write a flowchart.py for the procedure.


# Step 1
Create repo for this project.


# Step 2
In the public subnet (could be outside or in default vpc), create an EC2 instance that will be used for jenkins
ssh to the instance and install jenkins. (its in a default vpc, or create a simple vpc for it.)

