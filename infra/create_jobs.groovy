pipelineJob('Deploy-Backend') {
    definition {
        cpsScm {
            scm {
                git {
                    remote {
                        url('https://github.com/gyadav456/Cloud-Resume.git')
                    }
                    branch('main')
                }
            }
            scriptPath('Jenkinsfile.backend')
        }
    }
}

pipelineJob('Deploy-Frontend') {
    definition {
        cpsScm {
            scm {
                git {
                    remote {
                        url('https://github.com/gyadav456/Cloud-Resume.git')
                    }
                    branch('main')
                }
            }
            scriptPath('Jenkinsfile.frontend')
        }
    }
}
