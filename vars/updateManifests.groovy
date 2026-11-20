// Puts the new image name inside the Kubernetes deployment file
def call(String file, String image) {
    sh "sed -i 's|image: .*|image: ${image}|' ${file}"
}
