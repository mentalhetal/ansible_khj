# ALB 생성
resource "aws_lb" "my_alb" {
  name               = "my-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups   = [aws_security_group.public_sg.id]
  subnets           = [
    aws_subnet.public1.id,
    aws_subnet.public2.id
  ]
  enable_deletion_protection = false
  enable_cross_zone_load_balancing = true

  tags = {
    Name = "my-ALB"
  }
}

# ALB Target Group 생성
resource "aws_lb_target_group" "my_target_group" {
  name     = "my-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  health_check {
    interval            = 30
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  tags = {
    Name = "my-target-group"
  }
}

# ALB Listener 생성
resource "aws_lb_listener" "my_listener" {
  load_balancer_arn = aws_lb.my_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.my_target_group.arn
  }
}

# EC2 인스턴스를 ALB Target Group에 등록
resource "aws_lb_target_group_attachment" "my_attachment_server1" {
  target_group_arn = aws_lb_target_group.my_target_group.arn
  target_id        = aws_instance.public.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "my_attachment_server2" {
  target_group_arn = aws_lb_target_group.my_target_group.arn
  target_id        = aws_instance.public1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "my_attachment_server3" {
  target_group_arn = aws_lb_target_group.my_target_group.arn
  target_id        = aws_instance.public2.id
  port             = 80
}
