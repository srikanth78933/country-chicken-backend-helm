pipeline {
    agent any

    environment {
        NEXUS_CREDS = credentials('nexus-credentials')
        NEXUS_CREDS_USR = "${NEXUS_CREDS_USR}"
        NEXUS_CREDS_PSW = "${NEXUS_CREDS_PSW}"

        NEXUS_HELM_REPO_URL = 'http://54.87.4.226:8081/repository/helm-releases/'

        BUILD_TAG = "${BUILD_NUMBER}"
    }

    options {
        timestamps()
        ansiColor('xterm')
    }

    stages {

        stage('Validate Helm Chart') {
            steps {
                sh '''
                  chmod +x scripts/*.sh
                  ./scripts/validate.sh
                '''
            }
        }

        stage('Package Helm Chart') {
            steps {
                sh './scripts/package.sh'
            }
        }

        stage('Push Helm Package to Nexus') {
            steps {
                sh './scripts/push-to-nexus.sh'
            }
        }

        stage('Deploy to Dev') {
            steps {
                sh '''
                  echo "Deploying to DEV..."
                  ./scripts/deploy.sh dev
                '''
            }
        }

        stage('Verify Dev Deployment') {
            steps {
                sh '''
                  kubectl get pods -n country-chicken
                  kubectl get svc -n country-chicken
                  kubectl get ingress -n country-chicken
                '''
            }
        }

        stage('Approve Production') {
            steps {
                timeout(time: 1, unit: 'HOURS') {
                    input message: 'Deploy to Production?', ok: 'Deploy'
                }
            }
        }

        stage('Deploy to Prod') {
            steps {
                sh '''
                  echo "Deploying to PROD..."
                  ./scripts/deploy.sh prod
                '''
            }
        }

        stage('Verify Prod Deployment') {
            steps {
                sh '''
                  kubectl rollout status deployment/country-chicken-backend -n country-chicken
                  kubectl get ingress -n country-chicken
                '''
            }
        }
    }

    post {
        success {
            echo "✅ Deployment completed successfully"
        }
        failure {
            echo "❌ Deployment failed - check logs"

            // Optional auto rollback
            sh '''
              echo "Attempting rollback..."
              ./scripts/rollback.sh 1 || true
            '''
        }
    }
}
