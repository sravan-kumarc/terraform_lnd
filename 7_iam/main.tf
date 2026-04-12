resource "aws_iam_role" "ec2assumerole" {
    name = "ec2assumeRole"
    assume_role_policy = file("${path.module}/policy.json")
}
resource "aws_iam_role_policy_attachment" "ec2assumepolicyattachment" {
    role = aws_iam_role.ec2assumerole.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}
resource "aws_iam_instance_profile" "ec2assumeprofilerole" {
    name = "ec2profilerole"
    role = aws_iam_role.ec2assumerole.name
}

resource "aws_instance" "unix-server-dev_e1" {
    ami = "ami-045443a70fafb8bbc"
    instance_type = "t3.micro"
    key_name = aws_key_pair.mysecurekey.key_name
    depends_on = [aws_iam_role_policy_attachment.ec2assumepolicyattachment]
    iam_instance_profile = aws_iam_instance_profile.ec2assumeprofilerole.name
    tags = {
        Name = "UnixServer-Dev-E1"
    }

provisioner "remote-exec" {
    inline = [
      "sudo dnf update -y",
      "sudo dnf install awscli -y",
      "sleep 30",
      "aws s3 ls"
    ]
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("/home/sravan/.ssh/id_ed25519")
      host        = self.public_ip
    }
  }
}

resource "aws_key_pair" "mysecurekey" {
    key_name = "mysecure"
    public_key = file("/home/sravan/.ssh/id_ed25519.pub")
}

output "ec2publicip" {
    value = aws_instance.unix-server-dev_e1.public_ip
}