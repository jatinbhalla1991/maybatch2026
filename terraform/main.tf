


# resource "aws_s3_bucket" "abc" {
#     bucket = var.bucket_name
# }

# resource "aws_s3_bucket" "abc1" {
#     bucket = "jatin1234112121"
# }



resource "aws_ec2_instance" "my_ec2" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
}