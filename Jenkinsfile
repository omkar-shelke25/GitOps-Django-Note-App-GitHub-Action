@Library("Shared") _
pipeline {
    agent any

    stages {
        stage("Checkout The Code") {
            steps {
                
                script{
                    checkout_code("https://github.com/omkar-shelke25/Django-App-Pipeline-Jenkins","main")
                }
            }
        }
        
        stage("Testing") {
            steps {
                script{                                                    
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
                    docker_build("note-app")

                }
               
            }
        }
        
        stage("Store Image In Artifactory") {
            steps {
                script{
                    docker_push("note-app","latest")
                }
                }
            }
        
        
        stage("Deploy The Docker Image") {
            steps {
                scrigit pt {
                    if (!fileExists('docker-compose.yml')) {
                        error "docker-compose.yml file not found!"
                    }
                }
                sh "docker compose down && docker-compose up -d"
            }
        }
    }
}
