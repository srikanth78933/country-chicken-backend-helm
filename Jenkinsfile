pipeline {
    agent any

    environment {
        NEXUS_HELM_REPO_URL = 'http://54.87.4.226:8081/repository/helm-releases/'
        BUILD_TAG = "${BUILD_NUMBER}"
    }

    options {
        timestamps()
    }

    stages {

        stage('Validate Helm Chart') {
            steps {
                sh '''
                  set -e
                  chmod +x scripts/*.sh
                  ./scripts/validate.sh
                '''
            }
        }

        stage('Package Helm Chart') {
            steps {
                sh '''
                  set -e
                  ./scripts/package.sh
                '''
            }
        }

        stage('Push Helm Package to Nexus') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'nexus-credentials',
                    usernameVariable: 'NEXUS_USERNAME',
                    passwordVariable: 'NEXUS_PASSWORD'
                )]) {
                    sh '''
                      set -e
                      ./scripts/push-to-nexus.sh
                    '''
                }
            }
        }

        // 🔥 NEW STAGE (K8s Authentication)
        stage('Configure K8s Access') {
            steps {
                sh '''
                  set -e
                  aws eks --region ap-south-1 update-kubeconfig --name my-cluster
                  kubectl get nodes
                '''
            }
        }

        stage('Deploy to Dev') {
            steps {
                sh '''
                  set -e
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
                  set -e
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
            echo "Deployment completed successfully"
        }
        failure {
            echo "Deployment failed - check logs"
            sh '''
              echo "Attempting rollback..."
              ./scripts/rollback.sh 1 || true
            '''
        }
        always {
            cleanWs()
        }
    }
}
