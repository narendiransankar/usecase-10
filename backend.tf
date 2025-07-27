terraform {
  backend "s3" {
    bucket         = "new-state-temp"
    key            = "usecase-10-new/terraform.tfstate"
    region         = "ap-south-1"                
    use_lockfile = true

  }
}
