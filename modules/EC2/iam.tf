###############################################
# IAM Role for EC2 Instances
# Purpose: Allow EC2 to be managed via SSM (Session Manager)
# Notes: Role name is dynamic, avoid hardcoding.
###############################################
resource "aws_iam_role" "ec2_role" {
  name = "${local.name}-ec2-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

###############################################
# Attach minimum policy for SSM access
# Purpose: Enables SSM agent on EC2 to register with Systems Manager
###############################################
resource "aws_iam_role_policy_attachment" "ec2_ssm_core" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.ec2_role.name
}

###############################################
# Attach extra policies if really needed
# Example: S3 read access or CloudWatch logging
# Do NOT attach AdministratorAccess in production.
###############################################
# resource "aws_iam_role_policy_attachment" "ec2_s3_read" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
#   role       = aws_iam_role.ec2_role.name
# }

###############################################
# Instance Profile to associate role with EC2
###############################################
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${local.name}-ec2-ssm-instance-profile"
  role = aws_iam_role.ec2_role.name
}
