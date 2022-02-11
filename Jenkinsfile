#!groovy

def image
def podman
def podman_keep
def gitCommit
def gitBranch
pipeline {
    // Right now we assume all nodes can checkout and run jenkins-debian-glue scripts
    agent none
    stages {
        stage('checkout') {
            agent any
            steps {
                // Clean workspace
                sh "rm -rf ./*"
                // Checkout into source subdir
                dir('source') {
                    script {
                        info = checkout(scm)
                        gitCommit = info.GIT_COMMIT
                        gitBranch = info.GIT_BRNACH
                    }
                }

            }
        }
        stage('build debian source') {
            agent any
            // Work-around that pipelines don't use the same git plugin as expected
            // by generate-git-snapshot.
            steps {
                sh "SOURCE_DIRECTORY=source GIT_BRANCH=${gitBranch} GIT_COMMIT=${gitCommit} /usr/bin/generate-git-snapshot"
                sh "mkdir -p report"
                sh "/usr/bin/lintian-junit-report *.dsc > report/lintian.xml"
                stash name: 'debian_source', includes: '*.gz,*.bz2,*.xz,*.deb,*.dsc,*.changes,lintian.txt'
                junit '**/lintian.xml'
            }
        }
        stage('build debian package') {
            agent any
            // @TODO: Build package in container?
            steps {
                unstash name: 'debian_source'
                sh "BUILD_ONLY=yes /usr/bin/build-and-provide-package"
                stash name: 'debian_packages', includes: '*.gz,*.bz2,*.xz,*.deb,*.dsc,*.changes'
            }
        }
        // Matrices are only available within a declarative pipeline (eg. inside pipeline {})
        // In a matrix, the code is checked out clean by the looks of it, so we don't need
        // to use source/ subdir that we checked out initially.
        stage('setup matrix') {
            matrix {
                agent {
                    label 'PODMAN'
                }
                axes {
                    axis {
                        name 'DISTRIBUTION'
                        values 'stretch', 'buster', 'bullseye', 'bookworm', 'sid'
                        // We expect 'bullseye', 'bookworm', and 'sid' to fail at this
                        // point. How do we communicate that to jenkins?
                    }
                }
                stages {
                    stage('setup variables') {
                        steps {
                            script {
                                image = "alternc-${DISTRIBUTION}"
                                // If sudo is required to run podman on the node
                                // podman = "sudo ${podman}"
                                if (env.NODE_LABELS ==~ /.*PODMAN_SUDO.*/) {
                                    podman = "sudo /usr/bin/podman run --rm -v \$(pwd):/target:ro"
                                    podman_keep = "sudo /usr/bin/podman run -v \$(pwd):/target:ro"
                                }
                                else {
                                    podman = "podman run --rm -v \$(pwd):/target:ro"
                                    podman_keep = "podman run -v \$(pwd):/target:ro"
                                }
                            }
                            echo "${env.NODE_LABELS}"
                            echo "${podman}"
                            echo "${podman_keep}"
                            echo "${image}"
                        }
                    }
                    stage('build test images') {
                        steps {
                            script {
                                containerfile = "tests/containers/${DISTRIBUTION}"
                                if (env.NODE_LABELS ==~ /.*PODMAN_SUDO.*/) {
                                    sh "sudo /usr/bin/podman build -f ${containerfile} -t ${image}"
                                }
                                else {
                                    sh "podman build -f ${containerfile} -t ${image}"
                                }
                            }
                        }
                    }
                    stage('shellcheck') {
                        steps {
                            // Don't block at this time
                            catchError(buildResult: 'UNSTABLE', stageResult: 'FAILURE') {
                                sh "${podman} ${image} tests/shellcheck.sh > shellcheck.xml"
                            }
                            sh 'cat shellcheck.xml'
                            // This fails if the file isn't produced for some reason.
                            junit 'shellcheck.xml'
                        }
                    }
                    stage('phpcs') {
                        // Don't block at this time
                        steps {
                            catchError(buildResult: 'UNSTABLE', stageResult: 'FAILURE') {
                                sh "${podman} ${image} phpcs --report=checkstyle /target > phpcs.xml"
                            }
                            sh 'cat phpcs.xml'
                            junit 'phpcs.xml'
                        }
                    }
                    stage('phpunit') {
                        // Don't block at this time
                        steps {
                            catchError(buildResult: 'UNSTABLE', stageResult: 'FAILURE') {
                                script {
                                    sh "mkdir -p report"
                                    log_file="/output/phpunit.xml"
                                    coverage_file="/output/clover.xml"
                                    sh "${podman} -v \$(pwd)/report:/output --env CLOVER=${coverage_file} --env JUNIT=${log_file} ${image} tests/phpunit.sh"
                                }
                            }
                            sh 'cat report/phpunit.xml'
                            junit 'report/phpunit.xml'
                            sh 'cat report/clover.xml'
                            junit 'report/clover.xml'
                        }
                    }
                    stage('install from package') {
                        steps {
                            catchError(buildResult: 'UNSTABLE', stageResult: 'FAILURE') {
                                unstash name: 'debian_packages'
                                sh "${podman_keep} ${image} apt-get install -y /target/alternc_*.deb"
                                //sh "${podman} ${image} integration_tests"
                            }
                        }
                    }
                }
            }
        }
        stage('push package to unstable') {
            agent any
            // Only when it's our unstable branch "pu"
            when {
                branch 'pu'
            }
            steps {
                // @TODO: Build package in container?
                unstash name: 'debian_packages'
                sh "PROVIDE_ONLY=yes /usr/bin/build-and-provide-package"
                archiveArtifacts artifacts: '*.gz,*.bz2,*.xz,*.deb,*.dsc,*.changes', fingerprint: true
            }
        }
        stage('report') {
            agent any
            // Is this necessary, if the other stages did their own reports?
            steps {
                sh "exit 0"
            }
        }
    }
    post {
        always {
            cleanWs()
        }
    }
}
