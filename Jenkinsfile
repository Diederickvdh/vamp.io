#!groovy​
node("mesos-slave-vamp.io") {
  checkout scm
  // determine which version to build and deploy
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
          // replace running container
          resp = sh script: '''
          curl -s --data-binary @config/blueprint-staging.yaml http://10.20.0.100:8080/api/v1/deployments -H 'Content-type: application/x-yaml'
          ''', returnStdout: true
        } else {
          resp = sh script: '''
          curl -s -d "$(sed s/VERSION/$VAMP_VERSION/g config/blueprint-production.yaml)" http://10.20.0.100:8080/api/v1/deployments -H 'Content-type: application/x-yaml'
          ''', returnStatus: true
        }
        if (resp.contains("Error")) { error "Deployment failed! Error: " + resp }
      }
    }
  }
}
