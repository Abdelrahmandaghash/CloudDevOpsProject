# --- Role for the EKS cluster ---
resource "aws_iam_role" "cluster" {
  name = "${var.cluster_name}-cluster-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "eks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "cluster" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# --- The cluster ---
resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = aws_iam_role.cluster.arn

  vpc_config {
    subnet_ids = var.private_subnet_ids
  }

  depends_on = [aws_iam_role_policy_attachment.cluster]
}

# --- Role for the worker nodes ---
resource "aws_iam_role" "nodes" {
  name = "${var.cluster_name}-node-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "nodes" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",    # pull images from ECR
    "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy", # create disks for the database
  ])
  role       = aws_iam_role.nodes.name
  policy_arn = each.value
}

# --- 2 worker nodes, in the 2 private subnets (2 different AZs) ---
resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "ivolve-nodes"
  node_role_arn   = aws_iam_role.nodes.arn
  subnet_ids      = var.private_subnet_ids
  instance_types  = ["t3.small"]

  scaling_config {
    desired_size = 2
    min_size     = 2
    max_size     = 2
  }

  depends_on = [aws_iam_role_policy_attachment.nodes]
}

# Add-on that lets Kubernetes create EBS disks (used by the StorageClass)
resource "aws_eks_addon" "ebs_csi" {
  cluster_name = aws_eks_cluster.this.name
  addon_name   = "aws-ebs-csi-driver"
  depends_on   = [aws_eks_node_group.this]
}
