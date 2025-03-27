# flowchart.py
from diagrams import Diagram, Cluster
from diagrams.aws.network import VPC, PublicSubnet, PrivateSubnet, ALB
from diagrams.aws.compute import EC2
from diagrams.onprem.iac import Terraform
from diagrams.onprem.ci import Jenkins
from diagrams.onprem.git import Git
from diagrams.onprem.client import Users
from diagrams.onprem.container import Docker, Kubernetes
from diagrams.onprem.monitoring import Prometheus, Grafana

with Diagram("End-to-End DevOps Flow", show=False):
    dev = Users("Developers")
    repo = Git("GitHub")

    with Cluster("CI/CD"):
        jenkins = Jenkins("Jenkins")
    
    with Cluster("Infrastructure - AWS"):
        tf = Terraform("Terraform")
        vpc = VPC("VPC")
        with Cluster("Public Subnets"):
            alb = ALB("Public ALB")
            web_public = [EC2("PubWeb1"), EC2("PubWeb2")]
        with Cluster("Private Subnets"):
            web_private = [EC2("PrivWeb1"), EC2("PrivWeb2")]

    ans = Docker("Ansible + Docker tasks")
    k8s = Kubernetes("Kubernetes Cluster")
    prom = Prometheus("Prometheus")
    graf = Grafana("Grafana")

    dev >> repo >> jenkins >> tf >> vpc
    vpc >> alb >> web_public
    vpc >> web_private
    jenkins >> ans >> [web_public, web_private]
    jenkins >> k8s >> [prom, graf]
    dev >> alb
