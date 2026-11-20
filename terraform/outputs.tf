output "jenkins_public_ip" {
  value = module.server.public_ip
}

output "ecr_urls" {
  value = module.ecr.repo_urls
}

output "eks_cluster_name" {
  value = module.eks.cluster_name
}
