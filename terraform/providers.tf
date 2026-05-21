provider "aws" {
  region = "us-east-1"
}
terraform {
backend "s3" {
  region = "us-east-1"
  bucket = "my-terraform-state-1991"
  key    = "devterraform.tfstate"
}
}