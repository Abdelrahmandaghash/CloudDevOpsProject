// Logs in to ECR and pushes the image
def call(String image, String registry, String region) {
    sh """
        aws ecr get-login-password --region ${region} | docker login --username AWS --password-stdin ${registry}
        docker push ${image}
    """
}
