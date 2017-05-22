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
          currentVersion = getDeployedStagingVersion();
          currentGitShortHash = currentVersion ? currentVersion.split(':')[1] : "";
          if (currentGitShortHash != gitShortHash) {
            withEnv(["OLD_VERSION=${currentGitShortHash}", "NEW_VERSION=${gitShortHash}"]){
              // create new blueprint
              resp = sh script: '''
              curl -s -d "$(sed s/VERSION/$NEW_VERSION/g config/blueprint-staging.yaml)" http://10.20.0.100:8080/api/v1/blueprints -H 'Content-type: application/x-yaml'
              ''', returnStdout: true
              if (resp.contains("Error")) { error "Deployment failed! Error: " + resp }
              // merge to deployment
              resp = sh script: '''
              curl -s -d "name: vamp.io:staging:${NEW_VERSION}" -XPUT http://10.20.0.100:8080/api/v1/deployments/vamp.io:staging -H 'Content-type: application/x-yaml'
              ''', returnStatus: true
              if (resp.contains("Error")) { error "Deployment failed! Error: " + resp }
              if (currentVersion) {
                // switch traffic to new version
                resp = sh script: '''
                curl -s -d "$(sed -e s/OLD_VERSION/$OLD_VERSION/g -e s/NEW_VERSION/$NEW_VERSION/g config/internal-gateway.yaml)" http://10.20.0.100:8080/api/v1/gateways/vamp.io:staging/site/webport -H 'Content-type: application/x-yaml'
                ''', returnStdout: true
                if (resp.contains("Error")) { error "Deployment failed! Error: " + resp }
                // remove old blueprint from deployment
                resp = sh script: '''
                curl -s -d "name: vamp.io.:staging:${OLD_VERSION}" -XDELETE http://10.20.0.100:8080/api/v1/deployments/vamp.io:staging -H 'Content-type: application/x-yaml'
                ''', returnStdout: true
                if (resp.contains("Error")) { error "Deployment failed! Error: " + resp }
                // delete old blueprint
                resp = sh script: '''
                curl -s -XDELETE http://10.20.0.100:8080/api/v1/blueprints/vamp.io.:staging:${OLD_VERSION} -H 'Content-type: application/x-yaml'
                ''', returnStdout: true
                if (resp.contains("Error")) { error "Deployment failed! Error: " + resp }
              }
            }
          }
        } else {
          // create new blueprint
          resp = sh script: '''
          curl -s -d "$(sed s/VERSION/$VAMP_VERSION/g config/blueprint-production.yaml)" http://10.20.0.100:8080/api/v1/blueprints -H 'Content-type: application/x-yaml'
          ''', returnStatus: true
          if (resp.contains("Error")) { error "Deployment failed! Error: " + resp }
          // merge to existing deployment
          resp = sh script: '''
          curl -s -d "name: vamp.io:prod:${VERSION}" -XPUT http://10.20.0.100:8080/api/v1/deployments/vamp.io:prod -H 'Content-type: application/x-yaml'
          ''', returnStatus: true
          if (resp.contains("Error")) { error "Deployment failed! Error: " + resp }
        }
      }
    }
  }
}

def getDeployedStagingVersion() {
  def response = httpRequest url:"http://10.20.0.100:8080/api/v1/deployments/vamp.io:staging", acceptType: "APPLICATION_JSON", validResponseCodes: "100:404"

  if (response.status == 404) {
    return "";
  }

  def props = readJSON text: response.content
  return props.clusters.site.services[0].breed.name;
}
