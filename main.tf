provider "aws" {
  alias   = "seoul"
  region  = "ap-northeast-2"
  profile = "s2s"
}

provider "aws" {
  alias   = "japan"
  region  = "ap-northeast-1"
  profile = "s2s"
}

variable "project_name" {
  description = "The name of the project"
  default     = "s2s"
}