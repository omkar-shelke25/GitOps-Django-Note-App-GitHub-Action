@Library("Shared") _
pipeline {
    agent any

    stages {
        stage("Checkout The Code") {
            steps {
                script {
                    
                    checkout_code("https://github.com/omkar-shelke25/Django-App-Pipeline-Jenkins", "main")
                }
            }
        }

        stage("Testing") {
            steps {
                script {
                   
                    hello()
                }
            }
        }

        stage("Build The Code") {
            steps {
                script {
                    if (!fileExists('Dockerfile')) {
                        error "Dockerfile not found!"
                    }
                }
                script {
                    // Replace with your shared library function
                    docker_build("note-app")
                }
            }
        }

        stage("Store Image In Artifactory") {
            steps {
                script {
                   
                    docker_push("note-app", "latest")
                }
            }
        }

        stage("Deploy The Docker Image") {
            steps {
                script {
                    if (!fileExists('docker-compose.yml')) {
                        error "docker-compose.yml file not found!"
                    }
                }
                script {
                    sh "docker compose down && docker compose up -d"
                }
            }
        }
    }

    post {
        always {
            echo 'Cleaning up workspace...'
            cleanWs() // Cleans up the workspace after the pipeline finishes
        }
        success {
            echo 'Pipeline completed successfully.'
        }
        failure {
            echo 'Pipeline failed.'
        }
    }
}
