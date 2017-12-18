service {
  name = "dnsmasq"
  tags = ["primary"]
  port = 53
  check {
    args     = ["/usr/bin/pgrep","dnsmasq"]
    interval = "10s"
  }
}
