// Scans the image with Trivy and prints HIGH/CRITICAL problems
def call(String image) {
    sh "trivy image --severity HIGH,CRITICAL ${image}"
}
