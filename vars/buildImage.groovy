// Builds a Docker image.  folder = where the Dockerfile is
def call(String image, String folder) {
    sh "docker build -t ${image} ${folder}"
}
