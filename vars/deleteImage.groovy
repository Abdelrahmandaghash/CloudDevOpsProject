// Removes the image from the Jenkins server to save disk space
def call(String image) {
    sh "docker rmi ${image}"
}
