terraform {
  backend "s3" {
    bucket = "expensee-dev"
    key    = "expense-dev"
    region = "us-east-1"
    # use_lockfile      = true # enables native locking
    dynamodb_endpoint = "expensee-locking" #The parameter "dynamodb_endpoint" is deprecated. Use parameter "endpoints.dynamodb" instead.
  }
}
    