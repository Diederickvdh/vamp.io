#!groovy​
node("mesos-slave-vamp.io") {
  checkout scm
  // determine which version to build and deploy
  gitShortHash = sh(returnStdout: true, script: 'git rev-parse --short HEAD').trim();
  gitTag = sh(returnStdout: true, script: 'git describe --tag --abbrev=0').trim()
  gitTagDirty = sh(returnStdout: true, script: 'git describe --tag').trim()
  version = (gitTag == gitTagDirty) ? gitTag : 'nightly'

  withEnv(["VAMP_VERSION=${version}"]) {
    stage('Build') {
      script = 'npm install && gulp build:site && gulp build'
      script += (version == 'nightly')? ' --env=staging': ' --env=production'
      sh script: script
      docker.build 'magnetic.azurecr.io/vamp.io:$VAMP_VERSION', '.'
    }

    stage('Test') {
      docker.image('magnetic.azurecr.io/vamp.io:$VAMP_VERSION').withRun ('-p 8080:8080', '-conf Caddyfile') {c ->
          // check if the base url is set properly
          resp = sh( script: 'curl -s http://localhost:8080', returnStdout: true ).trim()
          assert !resp.contains("localhost:8080")
          // check if the aliases are set properly
          resp = sh script: "curl -Ls http://localhost:8080/documentation/", returnStdout: true
          assert resp =~ /url=.*\/documentation\/how-vamp-works\/v\d.\d.\d\/architecture-and-components/
      }
    }

    stage('Publish') {
      if (currentBuild.result == null || currentBuild.result == 'SUCCESS') {
        withDockerRegistry([credentialsId: 'registry', url: 'https://magnetic.azurecr.io']) {
            def site = docker.image('magnetic.azurecr.io/vamp.io:$VAMP_VERSION')
            site.push(version)
        }
      }
    }

    stage('Deploy') {
      if (currentBuild.result == null || currentBuild.result == 'SUCCESS') {
        def resp = ''
        if (version == 'nightly') {
          currentVersion = getCurrentNightlyVersion();
          currentGitShortHash = currentVersion ? currentVersion.split(':')[1] : "";
          if (currentGitShortHash != gitShortHash) {
            withEnv(["OLD_VERSION=${currentGitShortHash}", "NEW_VERSION=${gitShortHash}"]){
              // add latest version to deployment
              resp = sh script: '''
              curl -s -d "$(sed s/VERSION/$NEW_VERSION/g config/blueprint-staging.yaml)" http://10.20.0.100:8080/api/v1/deployments -H 'Content-type: application/x-yaml'
              ''', returnStdout: true
              if (resp.contains("Error")) { error "Deployment failed! Error: " + resp }
              if (currentVersion) {
                // delete old version
                resp = sh script: '''
                curl -s -X DELETE -d "$(sed s/VERSION/$OLD_VERSION/g config/blueprint-staging.yaml)" http://10.20.0.100:8080/api/v1/deployments -H 'Content-type: application/x-yaml'
                ''', returnStdout: true
                if (resp.contains("Error")) { error "Deployment failed! Error: " + resp }
              }
            }
          }
        } else {
          resp = sh script: '''
          curl -s -d "$(sed s/VERSION/$VAMP_VERSION/g config/blueprint-production.yaml)" http://10.20.0.100:8080/api/v1/deployments -H 'Content-type: application/x-yaml'
          ''', returnStatus: true
          if (resp.contains("Error")) { error "Deployment failed! Error: " + resp }
        }
      }
    }
  }
}

def getCurrentNightlyVersion() {
  def response = httpRequest url:"http://10.20.0.100:8080/api/v1/deployments/vamp.io-staging", acceptType: "APPLICATION_JSON", validResponseCodes: "100:404"

  if (response.status == 404) {
    return "";
  }

  def props = readJSON text: response.content
  return props.clusters.site.services[0].breed.name;
}
