terraform {
  backend "s3" {
    bucket         = "mycompany-terraform-state"
    key            = "eks/prod/terraform.tfstate"
    region         = "us-east-1"

    # Enable state locking
    dynamodb_table = "terraform-locks"

    # (Optional but recommended) enforce encryption
    encrypt        = true
  }
}
