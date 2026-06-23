# Cluster EKS (control plane) + Node Group (workers), siguiendo el
# patron de la solucion de ejemplo del curso.
#
# En AWS Academy Learner Lab no se pueden crear roles IAM nuevos, por
# lo que se reutilizan los roles ya provistos por el laboratorio.
# IMPORTANTE: estos roles NO se llaman literalmente "LabEKSClusterRole"
# ni "LabEKSNodeRole": cada instancia de laboratorio les agrega un
# prefijo/sufijo unico (ej. "c206632a...-LabEksClusterRole-FgIzNkgVmCOD").
# Por eso se buscan por patron (regex) en lugar de por nombre exacto.

data "aws_iam_roles" "eks_cluster_role_search" {
  name_regex = ".*LabEksClusterRole.*"
}

data "aws_iam_roles" "eks_node_role_search" {
  name_regex = ".*LabEksNodeRole.*"
}

locals {
  eks_cluster_role_arn = tolist(data.aws_iam_roles.eks_cluster_role_search.arns)[0]
  eks_node_role_arn     = tolist(data.aws_iam_roles.eks_node_role_search.arns)[0]
}

resource "aws_security_group" "eks_cluster" {
  name        = "${var.project_name}-sg-eks-cluster"
  description = "Security Group del control plane de EKS"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-sg-eks-cluster"
    Project = var.project_name
  }
}

resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = local.eks_cluster_role_arn
  version  = "1.30"

  vpc_config {
    subnet_ids              = [aws_subnet.public.id, aws_subnet.public_b.id]
    security_group_ids      = [aws_security_group.eks_cluster.id]
    endpoint_public_access  = true
    endpoint_private_access = false
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator"]

  tags = {
    Project = var.project_name
  }
}

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.project_name}-nodes"
  node_role_arn   = local.eks_node_role_arn
  subnet_ids      = [aws_subnet.public.id, aws_subnet.public_b.id]

  capacity_type  = "SPOT"
  instance_types = ["t3.large"]

  scaling_config {
    desired_size = 1
    min_size     = 1
    max_size     = 3
  }

  depends_on = [aws_eks_cluster.main]

  tags = {
    Project = var.project_name
  }
}

# Addons del cluster: VPC CNI (redes de pods) y CoreDNS (DNS interno,
# fundamental para que los backends encuentren mysql-service por DNS).
resource "aws_eks_addon" "vpc_cni" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "vpc-cni"
  depends_on   = [aws_eks_node_group.main]
}

resource "aws_eks_addon" "coredns" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "coredns"
  depends_on   = [aws_eks_node_group.main]
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "kube-proxy"
  depends_on   = [aws_eks_node_group.main]
}

# Metrics Server: requerido para que el HorizontalPodAutoscaler (IE3)
# pueda leer el uso real de CPU de los pods.
resource "aws_eks_addon" "metrics_server" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "metrics-server"
  depends_on   = [aws_eks_node_group.main]
}
