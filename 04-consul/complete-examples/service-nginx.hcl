service {
  name = "nginx"
  tags = ["primary"]
  port = 80
  check {
    http     = "http://localhost/"
    interval = "5s"
  }
}
