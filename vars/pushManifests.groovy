// Commits the changed YAML file and pushes it to GitHub (ArgoCD then deploys it)
// githubRepo example: github.com/Abdelrahmandaghash/CloudDevOpsProject.git
def call(String githubRepo) {
    withCredentials([usernamePassword(credentialsId: 'github-creds',
                                      usernameVariable: 'GIT_USER',
                                      passwordVariable: 'GIT_TOKEN')]) {
        sh """
            git config user.email "jenkins@ivolve.com"
            git config user.name "jenkins"
            git add k8s
            git commit -m "Update image from Jenkins build ${env.BUILD_NUMBER}"
            git push https://\${GIT_USER}:\${GIT_TOKEN}@${githubRepo} HEAD:main
        """
    }
}
