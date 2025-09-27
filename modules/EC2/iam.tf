resource "aws_iam_role" "ec2_role" {
  name = "ec2-ssm-role1"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
 })
}

resource "aws_iam_role_policy_attachment" "ec2_AmazonSSMManagedInstanceCore" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.ec2_role.name
}

resource "aws_iam_role_policy_attachment" "ec2_AdministratorAccess" {
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
  role       = aws_iam_role.ec2_role.name
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-ssm-instance-profile"
  role = aws_iam_role.ec2_role.name
}