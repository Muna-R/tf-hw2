terraform {
  backend "s3" {
    bucket = "tf-backend-muna"
    region = "us-east-1"
    key    = "hw2-sf-muna"

  }
}