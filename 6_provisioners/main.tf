resource "aws_instance" "unixserver-dev" {
  ami           = "ami-045443a70fafb8bbc"
  instance_type = "t3.micro"
  key_name      = aws_key_pair.mykey.key_name   #<-- Private key which is stored in my local machine
  tags = {
    Name = "UnixServer-Dev"
  }

  provisioner "local-exec" {
    command = "echo 'Running on the machine where terraform is executed' > localenvprovisioner_op.txt"
  }
# Create directory first
  provisioner "remote-exec" {
    inline = [
      "mkdir -p /home/ec2-user/copyfromlocalmachine"
    ]
     connection {
        type        = "ssh"
        user        = "ec2-user"
        private_key = file("/home/sravan/.ssh/id_ed25519")
        port        = 22
        host        = self.public_ip
        }
  }
provisioner "file" {
    source      = "/mnt/e/vscodePlayground/terrafomlnd/provisioners/sample.txt"
    destination = "/home/ec2-user/copyfromlocalmachine/sample.txt"
    
    connection {
        type        = "ssh"
        user        = "ec2-user"
        private_key = file("/home/sravan/.ssh/id_ed25519")
        port        = 22
        host        = self.public_ip
        }
        }
provisioner "file" {
    source      = "/mnt/e/vscodePlayground/terrafomlnd/provisioners/sample_data.csv"
    destination = "/home/ec2-user/copyfromlocalmachine/sample_data.csv"
    
    connection {
        type        = "ssh"
        user        = "ec2-user"
        private_key = file("/home/sravan/.ssh/id_ed25519")
        port        = 22
        host        = self.public_ip
        }
        }

provisioner "remote-exec" {
    inline = [ 
        "echo 'hello, this is appended text' >> /home/ec2-user/copyfromlocalmachine/sample.txt",
        "ls -a /home/ec2-user/copyfromlocalmachine",
        "cat /home/ec2-user/copyfromlocalmachine/sample.txt",
        "cat /home/ec2-user/copyfromlocalmachine/sample_data.csv",
        "ls -a /home/ec2-user/copyfromlocalmachine",]
    connection {
        type        = "ssh"
        user        = "ec2-user"
        private_key = file("/home/sravan/.ssh/id_ed25519")
        port        = 22
        host        = self.public_ip
        }
        }
}

resource "aws_key_pair" "mykey" {
  key_name   = "id_ed25519"
  public_key = file("/home/sravan/.ssh/id_ed25519.pub")
}
