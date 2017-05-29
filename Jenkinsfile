#!groovy​
properties([
  [ $class  : 'jenkins.model.BuildDiscarderProperty', strategy: [ $class: 'LogRotator', numToKeepStr: '20' ] ],
  pipelineTriggers([
    [ $class: 'hudson.triggers.TimerTrigger', spec  : "H/5 * * * *" ]
  ]),
  parameters([
    string(name: 'VAMP_API_ENDPOINT', defaultValue: '10.20.0.100:8080', description: 'The VAMP API endpoint'),
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
            echo 'Deploying revision ' + targetGitShortHash
            withEnv(["NEW_VERSION=${targetGitShortHash}"]){
              // create new blueprint
              String payload = sh script: 'sed s/VERSION/${NEW_VERSION}/g config/blueprint-staging.yaml', returnStdout: true
              VampAPICall('blueprints', 'POST', payload)
              // merge to deployment
              payload = 'name: vamp.io:staging:${NEW_VERSION}'
              VampAPICall('deployments/vamp.io:staging', 'PUT', payload)
              if (currentGitShortHash) {
                withEnv(["OLD_VERSION=${currentGitShortHash}"]){
                  // switch traffic to new version
                  payload = 'sed -e s/OLD_VERSION/${OLD_VERSION}/g -e s/NEW_VERSION/${NEW_VERSION}/g config/internal-gateway.yaml'
                  VampAPICall('gateways/vamp.io:staging/site/webport', 'PUT', payload)
                  // remove old blueprint from deployment
                  payload = 'name: vamp.io:staging:${OLD_VERSION}'
                  VampAPICall('deployments/vamp.io:staging', 'DELETE', payload)
                  // delete old blueprint
                  VampAPICall('blueprints/vamp.io:staging:${OLD_VERSION}', 'DELETE')
                  // delete old breed
                  VampAPICall('breeds/site:${OLD_VERSION}', 'DELETE')
                }
              }
            }
          } else {
            // create new blueprint
            String payload = sh script: 'sed s/VERSION/${TARGET_VERSION}/g config/blueprint-production.yaml', returnStdout: true
            VampAPICall('blueprints', 'POST', payload)
            // merge to existing deployment
            payload = 'name: vamp.io:prod:${TARGET_VERSION}'
            VampAPICall('deployments/vamp.io:prod', 'PUT', payload)
          }
        }
      }
    }
  }
}

String getTargetVersion() {
  String version = 'nightly'
  String gitTag = sh(returnStdout: true, script: 'git describe --tag --abbrev=0')
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

def VampAPICall(String path, String method = 'GET', String payload = '') {
  String script = "curl -X${method} -s http://${params.VAMP_API_ENDPOINT}/api/v1/${path}"
  if (payload) {
      script += ' -H "Content-type: application/x-yaml" --data-binary "' + payload + '"'
  }
  String res = sh(script: script, returnStdout: true)
  echo res
  if (res.contains("Error")) { error "Deployment failed! Error: " + res }
}

String getDeployedStagingVersion() {
  def res = httpRequest url:"http://${params.VAMP_API_ENDPOINT}/deployments/vamp.io:staging", acceptType: "APPLICATION_JSON", validResponseCodes: "100:404"
  String version = '';

  if (res.status == 404) {
    return version;
  }

  String props = readJSON text: res.content
  String currentVersion = props.clusters.site.services[0].breed.name;
  version = (currentVersion) ? currentVersion.split(':')[1] : ''
  return version
}
