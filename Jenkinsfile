pipeline {
    agent any
    
    environment {
        NEXUS_CREDS = credentials('nexus-credentials')
        NEXUS_HELM_REPO_URL = 'http://51.21.169.25:8081/repository/helm-releases/'
    }
    
    stages {
        stage('Package') {
            steps {
                sh '''
                  chmod +x scripts/package.sh
                  ./scripts/package.sh
                '''
            }
        }
        
        stage('Push to Nexus') {
            steps {
                sh '''
                  chmod +x scripts/push-to-nexus.sh
                  ./scripts/push-to-nexus.sh
                '''
            }
        }
        
        stage('Deploy to Dev') {
            steps {
                sh 'scripts/deploy.sh dev'
            }
        }
        
        stage('Approve Production') {
            steps {
                timeout(time: 1, unit: 'HOURS') {
                    input(
                        message: 'Deploy to Production?',
                        ok: 'Deploy'
                    )
                }
            }
        }
        
        stage('Deploy to Prod') {
            steps {
                sh 'scripts/deploy.sh prod'
            }
        }
    }
}
