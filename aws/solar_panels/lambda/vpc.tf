resource "aws_vpc" "luminex" {
    cidr_block = "10.0.0.0/28"
}

resource "aws_subnet" "subnet" {
    vpc_id     = aws_vpc.luminex.id
    cidr_block = "10.0.0.0/28"
}

resource "aws_eip" "nat" {
    domain = "vpc"
}

resource "aws_nat_gateway" "gateway" {
    connectivity_type = "public"
    allocation_id = aws_eip.nat.id
    subnet_id     = aws_subnet.subnet.id
}

resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.luminex.id
}

resource "aws_route_table" "example" {
  vpc_id = aws_vpc.luminex.id
}

resource "aws_route" "internet_gw" {
    route_table_id         = aws_route_table.example.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
}

resource "aws_route" "nat_gw" {
    route_table_id         = aws_route_table.example.id
    destination_cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.gateway.id
}


resource "aws_security_group" "lambda_sg" {
  name        = "lambda_sg"
  description = "Allow inbound traffic"
  vpc_id      = aws_vpc.luminex.id

  depends_on = [ aws_vpc.luminex ]

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    # cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
  }
}

resource "aws_route_table_association" "example" {
  subnet_id      = aws_subnet.subnet.id
  route_table_id = aws_route_table.example.id
}