nodes = [
  "01",
]

domain = {
  name = "id.tjo.cloud"
  zone = "tjo.cloud"
}

additional_domains = [
  {
    name = "id.tjo.space"
    zone = "tjo.space"
  }
]

ssh_keys = {
  "tine+pc"     = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICXAlzwziqfUUb2qmFwNF/nrBYc5MNT1MMOx81ohBmB+ tine+pc@tjo.space"
  "tine+mobile" = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAdPg/nG/Qzk110SBukHHEDqH6/3IJHsIKKHWTrqjaOh tine+mobile@tjo.space"
  "tine+ipad"   = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHrX2u82zWpVhjWng1cR4Kj76SajLJQ/Nmwd2GPaJpt1 tine+ipad@tjo.cloud"
  "tine+mac"    = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAdKdeca1pqJfT5SbvbOVxjvGXdIny29gqRrQbrNht3m tine+mac@tjo.space"
}
