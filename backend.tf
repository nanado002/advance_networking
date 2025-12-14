terraform {
  backend "s3" {
    bucket         = "nanado003-state-files-us-east-1"
    key            = "aws-adv-net-project/terraform.tfstate"
    region         = "us-east-1"
   
    encrypt        = true
  }
}
