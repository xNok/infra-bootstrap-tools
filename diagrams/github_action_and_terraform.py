
from diagrams import Diagram, Cluster, Edge
from diagrams.onprem.iac import Terraform
from diagrams.onprem.ci import GithubActions
from diagrams.aws.compute import EC2
from diagrams.aws.network import ELB
from diagrams.digitalocean.compute import Droplet
from diagrams.digitalocean.network import LoadBalancer


with Diagram("Infrastructure Provisioning", show=False):

    tf = Terraform("Terraform")
    ga = GithubActions("Github Actions")

    tf >>  Edge(label="configure") >> ga

    with Cluster("AWS Environnement"):
        aws = [EC2("worker1"), EC2("worker2")]

    with Cluster("Digital Ocean Environnement"):
        do = [Droplet("worker1"), Droplet("worker2")]

    
    tf >> Edge(label="provision", color="brown", style="dashed") >> aws
    tf >> Edge(label="provision", color="brown", style="dashed") >> do

    ga >> Edge(label="deploy to", color="grey", style="dashed") >> aws
    ga >> Edge(label="deploy to", color="grey", style="dashed") >> do

        