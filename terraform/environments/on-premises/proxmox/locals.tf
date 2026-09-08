locals {
  k8s_nodes = {
    "master"  = { ip = "172.16.0.12", gw = "172.16.0.1", cpu = 2, ram = 2048 }
    "worker1" = { ip = "172.16.0.13", gw = "172.16.0.1", cpu = 2, ram = 2048 }
    "worker2" = { ip = "172.16.0.14", gw = "172.16.0.1", cpu = 2, ram = 2048 }
  }
}