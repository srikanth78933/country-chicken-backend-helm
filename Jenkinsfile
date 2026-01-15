pipeline {
    agent any
    
    environment {
        NEXUS_USER = credentials('nexus-user')
        NEXUS_PASS = credentials('nexus-pass')
        NEXUS_HELM_REPO_URL = 'https://nexus.company.com/repository/helm-hosted/'
    }
    
    stages {
        stage('Package') {
            steps {
                sh 'scripts/package.sh'
            }
        }
        
        stage('Push to Nexus') {
            steps {
                sh 'scripts/push-to-nexus.sh'
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