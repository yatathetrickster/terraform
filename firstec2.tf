provider "aws" {
	region	= "us-west-2"
	access_key = "AKIA6LILQSQ2RKK7XKNA"
	secret_key = "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"
}

resource "aws_instance" "myec2" {
	ami = "ami-082b5a644766e0e6f"
	instance_type = "t2.micro"
}
