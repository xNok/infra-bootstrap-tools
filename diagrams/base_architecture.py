from diagrams import Diagram, Cluster, Edge
from diagrams.custom import Custom

from diagrams.onprem.compute import Server

from diagrams.onprem.monitoring import Grafana, Prometheus
from diagrams.onprem.container import Docker

from diagrams.onprem.database import Mongodb

from diagrams.onprem.iac import Ansible
from diagrams.onprem.ci import GithubActions

with Diagram(name="Startup infra for small self hosted project", show=False):
    

    ansible = Ansible("Ansible")
    actions = GithubActions("Github Actions")

    with Cluster("Master worker"):

        ingress = Custom("ingress", "/out/caddy2.png")

        with Cluster("Observability"):
            portainer = Custom("portainer", "/out/portainer.png")
            registery = Docker("Private Registery")
            
            metrics = Prometheus("Prometheus")
            graphana = Grafana("Grafana")

            ingress >> portainer >> registery 
            ingress >> graphana >> metrics

            # CI/CD
            ob = [metrics, graphana, portainer, registery]
            ob << Edge(color="firebrick", style="dashed") << ansible    

        with Cluster("Application worker", direction="TB"):
            app = Server("Application")
            db  = Mongodb("Database")

            ingress >> app >> db

        
        registery \
            << Edge(color="firebrick", style="dashed") << actions \
            >> Edge(color="firebrick", style="dashed") >> [db, app]