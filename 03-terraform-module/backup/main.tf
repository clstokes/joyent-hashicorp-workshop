module "nginx" {
  source = "./nginx-module"
}

output "nginx_ip" {
  value = ["${module.nginx.nginx_ip}"]
}
