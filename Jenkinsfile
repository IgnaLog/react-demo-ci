pipeline {
    agent any
    tools {
        nodejs "node20"
    }
    environment {
        SCANNER_HOME = tool "sonar-scanner"
        APP_NAME = "react-demo-ci"
        RELEASE = "0.1.0"
        DOCKER_USER = "ignalog"
        DOCKER_PASS = "DockerHub-Token"
        IMAGE_NAME = "${DOCKER_USER}" + "/" + "${APP_NAME}"
        IMAGE_TAG = "${RELEASE}-${BUILD_NUMBER}"
        JENKINS_API_TOKEN = credentials("JENKINS_API_TOKEN")
    }
    stages {
        stage("Clean Workspace") {
            steps {
                cleanWs()
            }
        }
        stage("Checkout form GitHub") {
            steps {
                git branch: "main", url: "https://github.com/IgnaLog/react-demo-ci"
            }
        }
        stage("Sonarqube Analysis") {
            steps {
                withSonarQubeEnv('Sonarqube-Server') {
                    sh '''$SCANNER_HOME/bin/sonar-scanner -Dsonar.projectName=React-Demo-CI -Dsonar.projectKey=React-Demo-CI'''
                }
            }
        }
        stage("Quality Gate") {
            steps {
                script {
                    waitForQualityGate abortPipeline: false, credentialsId: "SonarQube-Token"
                }
            }
        }
        stage("Install Dependencies") {
            steps {
                sh "npm install"
            }
        }
        stage("Trivy Fs Scan") {
            steps {
                sh "trivy fs . > trivyfs.txt"
            }
        }
        stage("Testing") {
            steps {
                sh "npm run test"
            }
        }
        stage("Build & Push Docker Image") {
            steps {
                script {
                    docker.withRegistry('',DOCKER_PASS) {
                        image = docker.build("${IMAGE_NAME}", "--build-arg APP_VERSION=${IMAGE_TAG} -f Dockerfile .")
                        image.push("${IMAGE_TAG}")
                        image.push("latest")
                    }
                }
            }
        }
        stage("Trivy Image Scan") {
            steps {
                script {
	                sh "docker run -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy image ignalog/react-demo-ci:latest --no-progress --scanners vuln  --exit-code 0 --severity HIGH,CRITICAL --format table > trivyimage.txt"
                }
            }
        }
        stage ("Cleanup Artifacts") {
            steps {
                script {
                    sh "docker rmi ${IMAGE_NAME}:${IMAGE_TAG}"
                    sh "docker rmi ${IMAGE_NAME}:latest"
                }
            }
        }
        // stage("Trigger CD Pipeline") {
        //     steps {
        //         script {
        //             sh "curl -v -k --user admin:${JENKINS_API_TOKEN} -X POST -H 'cache-control: no-cache' -H 'content-type: application/x-www-form-urlencoded' --data 'IMAGE_TAG=${IMAGE_TAG}' '20.199.113.26:8080/job/React-Demo-CD/buildWithParameters?token=gitops-token'"
        //         }
        //     }
        // }
    }
    post {
        success {
            script {
                updateGitHubCommitStatus('success')
            }
        }
        failure {
            script {
                updateGitHubCommitStatus('failure')
            }
        }
        always {
            emailext attachLog: true,
                subject: "'${currentBuild.result}'",
                body: "Project: ${env.JOB_NAME}<br/>" +
                    "Build Number: ${env.BUILD_NUMBER}<br/>" +
                    "URL: ${env.BUILD_URL}<br/>",
                to: 'ignacio.coding@gmail.com',
                attachmentsPattern: 'trivyfs.txt,trivyimage.txt'
        }
    }
}

def updateGitHubCommitStatus(String status) {
    def gitHubCredentialsId = "GitHub-Token"
    def commitSha = sh(script: "git rev-parse HEAD", returnStdout: true).trim()

    withCredentials([usernamePassword(credentialsId: gitHubCredentialsId, usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
        script {
            sh """
                curl -X POST \
                -u \$USERNAME:\$PASSWORD \
                -H 'Accept: application/vnd.github.v3+json' \
                https://api.github.com/repos/IgnaLog/react-demo-ci/statuses/$commitSha \
                -d '{"state":"$status", "context":"Jenkins"}'
            """
        }
    }
}
