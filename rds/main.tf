resource "aws_subnet_group" "sngroup" {
  name       = "lnd-subnet-group"
  subnet_ids  = []

  tags = {
    Name = "LND-Subnet-Group"
  
}
}

resource "aws_db_instance" "lnd_db" {
  identifier              = "lnd-db-instance"
  allocated_storage       = 20
  engine                  = "mysql"
  engine_version          = "13.4"
  instance_class          = "db.t3.micro"
  username                = "admin"
  password                = "Admin1234"
  db_subnet_group_name   = aws_subnet_group.sngroup.name
  vpc_security_group_ids = [aws_security_group.mainvpcsg.id]
  skip_final_snapshot    = true

  tags = {
    Name = "LND-DB-Instance"
    }
}

resource "aws_instance" "lnd_ec2" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_subnet.id
  key_name = aws_key_pair.lnd_key.name
  associate_public_ip_address = true
  security_groups = [aws_security_group.mainvpcsg.id]

    tags = {
        Name = "LND-EC2-Instance"
    }
}
