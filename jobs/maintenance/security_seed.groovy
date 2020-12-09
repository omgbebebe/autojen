freeStyleJob('configure_security') {
    scm {
        github('omgbebebe/autojen', 'master')
    }
    steps {
        shell('echo placeholder')
    }
}
