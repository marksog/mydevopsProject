terraform {
  backend "s3" {
    bucket = "small-fufu-plenti-kati-kati"
    key    = "terraform-vpc/terraform.tfstate"
    region = "us-east-1"
    encrypt = true
    dynamodb_table = "terraform_state_lock_with_jenkins"
    
  }
}