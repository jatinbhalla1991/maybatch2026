


resource "aws_s3_bucket" "abc" {
    #count = var.create_s3 ? 1 : 0
    bucket = var.bucket_name
    tags = {
        Name = "test"
    }
}



# resource "aws_s3_bucket" "abc1" {
#     bucket = "jatin1234112121"
# }



# resource "aws_ec2_instance" "my_ec2" {
#   ami           = data.aws_ami.ubuntu.id
#   instance_type = "t2.micro"
# }