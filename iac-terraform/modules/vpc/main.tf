locals {
  name = "${var.project}-vpc"
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = { Name = local.name }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "${local.name}-igw" }
}

# Public subnets (2)
resource "aws_subnet" "public" {
  for_each = { for idx, cidr in var.public_subnet_cidrs : idx => cidr }
  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value
  availability_zone       = data.aws_availability_zones.available.names[tonumber(each.key)]
  map_public_ip_on_launch = true
  tags = {
    Name = "${local.name}-public-${each.key}"
    Tier = "public"
  }
}

# Private subnets (2)
resource "aws_subnet" "private" {
  for_each = { for idx, cidr in var.private_subnet_cidrs : idx => cidr }
  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value
  availability_zone = data.aws_availability_zones.available.names[tonumber(each.key)]
  tags = {
    Name = "${local.name}-private-${each.key}"
    Tier = "private"
  }
}

# NAT Gateway per AZ (costs $) — 1 NAT for simplicity (public[0])
resource "aws_eip" "nat" {
  vpc = true
  tags = { Name = "${local.name}-nat-eip" }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = element(values(aws_subnet.public), 0).id
  tags = { Name = "${local.name}-nat" }
  depends_on = [aws_internet_gateway.igw]
}

# Route tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "${local.name}-public-rt" }
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_assoc" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "${local.name}-private-rt" }
}

resource "aws_route" "private_nat" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

resource "aws_route_table_association" "private_assoc" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}

# Optional: VPC Flow Logs to CloudWatch
resource "aws_cloudwatch_log_group" "vpc_flow" {
  count             = var.enable_vpc_flow_logs ? 1 : 0
  name              = "/aws/vpc/${local.name}/flow-logs"
  retention_in_days = 14
}

data "aws_iam_policy_document" "flow_logs_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals { type = "Service" identifiers = ["vpc-flow-logs.amazonaws.com"] }
  }
}

resource "aws_iam_role" "flow_logs" {
  count              = var.enable_vpc_flow_logs ? 1 : 0
  name               = "${local.name}-flow-logs-role"
  assume_role_policy = data.aws_iam_policy_document.flow_logs_assume.json
}

resource "aws_iam_role_policy" "flow_logs" {
  count  = var.enable_vpc_flow_logs ? 1 : 0
  name   = "${local.name}-flow-logs-policy"
  role   = aws_iam_role.flow_logs[0].id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = ["logs:CreateLogStream","logs:PutLogEvents","logs:CreateLogGroup","logs:DescribeLogGroups","logs:DescribeLogStreams"],
      Resource = "*"
    }]
  })
}

resource "aws_flow_log" "this" {
  count                = var.enable_vpc_flow_logs ? 1 : 0
  log_destination      = aws_cloudwatch_log_group.vpc_flow[0].arn
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.this.id
  iam_role_arn         = aws_iam_role.flow_logs[0].arn
  log_destination_type = "cloud-watch-logs"
}
