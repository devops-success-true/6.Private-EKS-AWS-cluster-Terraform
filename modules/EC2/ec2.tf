resource "aws_instance" "bootstrap" {
  ami                         = data.aws_ami.ubuntu.id # or SSM parameter for pinned AMI
  subnet_id                   = element(var.public_subnets, 0) # or private if using SSM
  associate_public_ip_address = false # recommended; use SSM instead of public IP
  instance_type               = var.instance_type       # make configurable
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  vpc_security_group_ids      = [var.bastion_sg_id]     # passed from VPC/SG module
  user_data                   = file("${path.module}/bootstrap.sh")

  root_block_device {
    volume_size = 30
    volume_type = "gp3" # gp3 is the new standard (cheaper, faster than gp2)
    encrypted   = true  # always encrypt in prod
  }

  tags = merge(
    var.common_tags,
    {
      Name        = "${local.name}-bootstrap"
      Environment = var.environment
      Owner       = var.owner
      CostCenter  = var.cost_center
    }
  )
}
