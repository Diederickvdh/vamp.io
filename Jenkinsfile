#!groovy​
properties([
  parameters([
    string(name: 'VAMP_API_ENDPOINT', defaultValue: '10.20.0.100:8080', description: 'The VAMP API endpoint')
    choice(name: 'TARGET_ENV', choices: ['staging', 'production'].join('\n'), description: 'The target environment')
   ])
])

node("mesos-slave-vamp.io") {
  checkout scm
  // determine which version to build and deploy
  String version = getTargetVersion()

  withEnv(["TARGET_VERSION=${version}"]) {
    stage('Build') {
      script = 'npm install && gulp build:site && gulp build'
      script += (version == 'nightly')? ' --env=staging': ' --env=production'
      sh script: script
      docker.build 'magnetic.azurecr.io/vamp.io:$TARGET_VERSION', '.'
    }

    stage('Test') {
      docker.image('magnetic.azurecr.io/vamp.io:$TARGET_VERSION').withRun ('-p 8080:8080', '-conf Caddyfile') {c ->
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
            def site = docker.image('magnetic.azurecr.io/vamp.io:$TARGET_VERSION')
            site.push(version)
        }
      }
    }

    stage('Deploy') {
      if (currentBuild.result == null || currentBuild.result == 'SUCCESS') {
        if (version == 'nightly') {
          String targetGitShortHash = sh(returnStdout: true, script: 'git rev-parse --short HEAD').trim();
          String currentGitShortHash = getDeployedStagingVersion();
          if (currentGitShortHash != targetGitShortHash) {
            withEnv(["OLD_VERSION=${currentGitShortHash}", "NEW_VERSION=${targetGitShortHash}"]){
              // create new blueprint
              String script = '''
              curl -s -d "$(sed s/VERSION/$NEW_VERSION/g config/blueprint-staging.yaml)" http://${VAMP_API_ENDPOINT}/blueprints -H 'Content-type: application/x-yaml'
              '''
              VampAPICall(script)
              // merge to deployment
              script = '''
              curl -s -d "name: vamp.io:staging:${NEW_VERSION}" -XPUT http://${VAMP_API_ENDPOINT}/deployments/vamp.io:staging -H 'Content-type: application/x-yaml'
              '''
              VampAPICall(script)
              if (currentGitShortHash) {
                // switch traffic to new version
                script = '''
                curl -s -d "$(sed -e s/OLD_VERSION/$OLD_VERSION/g -e s/NEW_VERSION/$NEW_VERSION/g config/internal-gateway.yaml)"  -XPUT http://${VAMP_API_ENDPOINT}/gateways/vamp.io:staging/site/webport -H 'Content-type: application/x-yaml'
                '''
                VampAPICall(script)
                // remove old blueprint from deployment
                script = '''
                curl -s -d "name: vamp.io:staging:${OLD_VERSION}" -XDELETE http://${VAMP_API_ENDPOINT}/deployments/vamp.io:staging -H 'Content-type: application/x-yaml'
                '''
                VampAPICall(script)
                // delete old blueprint
                script = '''
                curl -s -XDELETE http://${VAMP_API_ENDPOINT}/blueprints/vamp.io:staging:${OLD_VERSION} -H 'Content-type: application/x-yaml'
                '''
                VampAPICall(script)
                // delete old breed
                script = '''
                curl -s -XDELETE http://${VAMP_API_ENDPOINT}/breeds/site:${OLD_VERSION} -H 'Content-type: application/x-yaml'
                '''
                VampAPICall(script)
              }
            }
          } else {
            // create new blueprint
            def script = '''
            curl -s -d "$(sed s/VERSION/$TARGET_VERSION/g config/blueprint-production.yaml)" http://${VAMP_API_ENDPOINT}/blueprints -H 'Content-type: application/x-yaml'
            '''
            VampAPICall(script)
            // merge to existing deployment
            script = '''
            curl -s -d "name: vamp.io:prod:${TARGET_VERSION}" -XPUT http://${VAMP_API_ENDPOINT}/deployments/vamp.io:prod -H 'Content-type: application/x-yaml'
            '''
            VampAPICall(script)
          }
        }
      }
    }
  }
}

String getTargetVersion() {
  String version = 'nightly'
  String gitTagDirty = sh(returnStdout: true, script: 'git describe --tag').trim()

  if (isUserTriggered() && params.TARGET_ENV == 'production') {
    version = (params.TARGET_ENV == 'production') ? gitTag : 'nightly'
  } else {
    // build triggered automatically
    version = (gitTag == gitTagDirty) ? gitTag : 'nightly'
  }

  return version
}

@NonCPS
Boolean isUserTriggered() {
    def causes = currentBuild.rawBuild.getCauses()
    return (causes.last() instanceof hudson.model.Cause$UserIdCause)
}

def VampAPICall(String script) {
  String res = sh script: script, returnStdout: true
  if (res.contains("Error")) { error "Deployment failed! Error: " + res }
}

String getDeployedStagingVersion() {
  String res = httpRequest url:"http://${VAMP_API_ENDPOINT}/deployments/vamp.io:staging", acceptType: "APPLICATION_JSON", validResponseCodes: "100:404"

  if (res.status == 404) {
    return "";
  }

  String props = readJSON text: res.content
  String currentVersion = props.clusters.site.services[0].breed.name;
  return (currentVersion) ? currentVersion.split(':')[1] : ""
}
