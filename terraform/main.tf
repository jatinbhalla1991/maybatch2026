module "s3bucket" {
  source      = "./s3bucket"
  depends_on = [ module.securitygroup ]
  bucket_name = var.bucket_name
  
}
module "ec2" {
  source = "./ec2"
  depends_on = [module.s3bucket]
  
}

# module "securitygroup" {
#   source = "./securitygroup"
#   sg_name = var.sg_name
# }