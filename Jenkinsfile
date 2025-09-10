// Utilizing the Declarative Jenkinsfile approach, I ensure a clean code checkout from the version control system.
def COLOR_MAP = [
    'SUCCESS': 'good',
    'FAILURE': 'danger',
    'ABORTED': 'warning',
    'UNSTABLE': 'warning',
]

pipeline {
    agent any
    tools {
        maven 'maven3'
        jdk 'OracleJDK8'
    }

    environment {
        SNAP_REPO = 'teksystems-snapshot'
        NEXUS_USER = 'admin'
        NEXUS_PASS = 'admin123'
        RELEASE_REPO = 'teksystems-release'
        CENTRAL_REPO = 'teksystems-maven-central'
        NEXUSIP = '192.168.0.113'
        NEXUSPORT = '8081'
        NEXUS_GRP_REPO = 'teksystems-maven-group'
        NEXUS_LOGIN = 'nexus-creds'
        SONARSERVER = 'sonarserver'
        SONARSCANNER = 'sonarscanner'
        AZURE_CREDENTIALS = credentials('AzureServicePrincipal')
        RESOURCE_GROUP = 'kube-rg'
        LOCATION = 'Central US'
        ISTIO_VERSION = '1.20.0'
        ISTIO_INSTALL_DIR = "/var/lib/jenkins/workspace/profile-project/istio-${ISTIO_VERSION}"
        ISTIO_PATH = "/var/lib/jenkins/workspace/profile-project/istio-1.20.0/bin"
    }

    stages {
        stage('Git Checkout'){
            steps {
                git branch: 'main', credentialsId: 'gitlab-creds', url: 'https://gitlab.com/ernest.awangya/profile_app.git'
            }
        }
        //The pipeline kicks off with a build and comprehensive testing phase, validating the integrity of the codebase.  
        stage('Build') {
            steps {
                executeCommand('mvn -DskipTests clean install', 'Build failed')
            }
            post {
                success {
                    echo "Now Archiving..."
                    archiveArtifacts artifacts: '**/*.war'
                }
            }
        }

        stage('Test') {
            steps {
                executeCommand('mvn test', 'Test failed')
            }
        }

        stage('OWASP Scan') {
            steps {
                dependencyCheck additionalArguments: '', odcInstallation: 'DP-check'
                dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
            }
        }
        // Incorporating Checkstyle analysis ensures that our code adheres to predefined coding standards, promoting consistency.  
        stage('Checkstyle Analysis') {
            steps {
                executeCommand('mvn checkstyle:checkstyle', 'Checkstyle analysis failed')
            }
        }
        // Integrating SonarQube analysis provides in-depth code quality metrics, contributing to continuous improvement.
        stage('SonarQube Analysis') {
            environment {
                def scannerHome = tool "${SONARSCANNER}"
            }
            steps {
                withSonarQubeEnv("${SONARSERVER}") {
                sh '''${scannerHome}/bin/sonar-scanner -Dsonar.projectKey=eawangya \
                    -Dsonar.projectName=eawangya \
                    -Dsonar.projectVersion=1.0 \
                    -Dsonar.sources=src/ \
                    -Dsonar.java.binaries=target/test-classes/com/visualpathit/account/controllerTest/ \
                    -Dsonar.junit.reportsPath=target/surefire-reports/ \
                    -Dsonar.jacoco.reportsPath=target/jacoco.exec \
                    -Dsonar.java.checkstyle.reportPaths=target/checkstyle-result.xml'''
                }
            }
        }
        //Quality Gate is enforced through SonarQube, ensuring that only high-quality code progresses further in the pipeline.
        stage("Quality Gate"){
            steps {
                timeout(time: 60, unit: 'MINUTES') {
                waitForQualityGate abortPipeline: true

                }
            }
        }
        // Upon successful build and analysis, artifacts are securely uploaded to Nexus, serving as a centralized repository for dependencies.
        stage("Upload Artifact to Nexus") {
            steps {
                nexusArtifactUploader(
                    nexusVersion: 'nexus3',
                    protocol: 'http',
                    nexusUrl: "${NEXUSIP}:${NEXUSPORT}",
                    groupId: 'QA',
                    version: "${env.BUILD_ID}-${env.BUILD_TIMESTAMP}",
                    repository: "${RELEASE_REPO}",
                    credentialsId: "${NEXUS_LOGIN}",
                    artifacts: [
                        [artifactId: 'vprofileapp',
                            classifier: '',
                            file: 'target/vprofile-v2.war',
                            type: 'war']
                    ]
                )
            }
        }
        // Docker images are built as part of the pipeline, encapsulating our applications for consistency across different environments.
        stage('Build Docker') {
            steps {
                script {
                    executeCommand('docker build -t eawangya/techharbor:version2 .', 'Docker build failed')
                }
            }
        }

        stage('Trivy Image Scan') {
            steps {
                executeCommand('trivy image eawangya/techharbor:version2', 'Trivy image scan failed')
            }
        }
        // These Docker images are then pushed to a Docker registry, facilitating efficient deployment.
        stage('Docker Push') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', passwordVariable: 'PASS', usernameVariable: 'USER')]) {
                        executeCommand("echo \${PASS} | docker login -u \${USER} --password-stdin", 'Docker login failed')
                        executeCommand("docker push eawangya/techharbor:version2", 'Docker push failed')

                        // Clean Jenkins Server
                        executeCommand("docker rmi -f \$(docker images -qa)", 'Docker image cleanup failed')
                    }
                }
            }
        }
        // The pipeline establishes a connection to Azure, a key step in our multi-cloud strategy
        stage('Azure Login') {
            steps {
                script {
                    withCredentials([azureServicePrincipal(credentialsId: 'AzureServicePrincipal', variable: 'AZURE_CREDENTIALS')]) {
                        executeCommand("az login --service-principal --username $AZURE_CREDENTIALS_CLIENT_ID --password $AZURE_CREDENTIALS_CLIENT_SECRET --tenant $AZURE_CREDENTIALS_TENANT_ID", 'Azure login failed')
                    }
                }
            }
        }
        // Leveraging Jenkins, I dynamically provision an EKS cluster on AWS using Terraform, ensuring infrastructure as code.
        stage('Provision AKS cluster') {
            steps {
                script {
                    dir('terraform') {
                        executeCommand('terraform init', 'Terraform initialization failed')
                        executeCommand('terraform delete --auto-approve', 'Terraform delete failed')
                    }
                }
            }
        }
        // Istio, a powerful service mesh, is seamlessly installed and configured to enhance service communication and observability.
        stage('Install and Configure Istio') {
            steps {
                script {
                    dir('kubenetes-files') {
                        executeCommand("az aks get-credentials --resource-group my-demo-rg --name my-demo-cluster --admin --overwrite-existing", 'Azure AKS get credentials failed')
                    }
                    executeCommand("curl -L https://istio.io/downloadIstio | ISTIO_VERSION=${ISTIO_VERSION} sh -", 'Istio download failed')
                    dir("istio-1.20.0") {
                        executeCommand('export PATH="$PATH:/var/lib/jenkins/workspace/profile-project/istio-1.20.0/bin"', 'Setting Istio PATH failed')
                        executeCommand('${ISTIO_PATH}/istioctl install --set profile=demo -y', 'Istio installation failed')
                        executeCommand('kubectl label namespace default istio-injection=enabled', 'Setting Istio label failed')
                    }
                }
            }
        

        stage('Deploy App on EKS') {
            steps {
                script {
                    dir('kubenetes-files') {
                        executeCommand('kubectl apply -f .', 'App deployment failed')
                        // Add wait statements if needed
                    }
                }
            }
        }
        // Istio-specific analysis is performed to ensure optimal service mesh functionality and performance.
        stage('Istio Analyze') {
            steps {
                script {
                    dir("istio-1.20.0") {
                        executeCommand('${ISTIO_PATH}/istioctl analyze', 'Istio analysis failed')
                        executeCommand('kubectl apply -f samples/addons', 'Applying Istio addons failed')
                        executeCommand('kubectl rollout status deployment/kiali -n istio-system', 'Waiting for Kiali rollout failed')

                        // CLEAN UP
                        // executeCommand('kubectl delete -f samples/addons', 'Deleting Istio addons failed')
                        // executeCommand('${ISTIO_PATH}/istioctl uninstall -y --purge', 'Istio uninstallation failed')
                        // executeCommand('kubectl delete namespace istio-system', 'Deleting Istio namespace failed')
                        // executeCommand('kubectl label namespace default istio-injection-', 'Removing Istio label failed')
                    }
                }
            }
        }
    }
    // Finally, upon successful deployment and analysis, automated notifications are sent to Slack, keeping the team informed in real-time.
    post {
        always {
            echo 'Slack Notification.'
            slackSend channel: '#devops-cicd-pipeline',
                color: COLOR_MAP[currentBuild.currentResult],
                message: "*${currentBuild.currentResult}:* Job ${env.JOB_NAME} build ${env.BUILD_NUMBER} \n More info at: ${env.BUILD_URL}"
        }
    }
}

def executeCommand(command, errorMessage) {
    script {
        def result = sh(script: command, returnStatus: true)
        if (result != 0) {
            currentBuild.result = 'FAILURE'
            echo "${errorMessage} (Exit code: ${result})"
        }
    }
}
