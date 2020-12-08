{ pkgs ? import <nixpkgs> {} }:

with pkgs;
let
  jenkins-server = callPackage ./jenkins-server.nix {};
#  jre = "${pkgs.jre_minimal}";
  jre = "${pkgs.jre8}";
#  jre = pkgs.jre_minimal.override {
#    modules = [
#      # The modules used by 'something' and 'other' combined:
#      "java.base"
#      "java.logging"
#    ];
#  };
#  jre = pkgs.jre;
  plugins = import ./plugins.nix { inherit (pkgs) fetchurl stdenv; };
  jenkins_home = "/var/lib/jenkins";
  entrypoint = 
    let replacePlugins =
        let pluginCmds = lib.attrsets.mapAttrsToList
              (n: v: "cp ${v} ${jenkins_home}/plugins/${n}.jpi")
              plugins;
        in ''
          rm -r ${jenkins_home}/plugins || true
          mkdir -p ${jenkins_home}/plugins
          ${lib.strings.concatStringsSep "\n" pluginCmds}
        '';
    in writeScript "entrypoint.sh" ''
    #!${stdenv.shell}
    set -e
    ${replacePlugins}
    mkdir -p /var/lib/jenkins/tmp
    exec ${jre}/bin/java \
      -Djava.awt.headless=true \
      -Djava.io.tmpdir=/var/lib/jenkins/tmp \
      -Djenkins.install.runSetupWizard=false \
      -jar ${jenkins-server.out}/webapps/jenkins.war
  '';
in

dockerTools.buildImage {
  name = "jenkins-server";
  tag = "${jenkins-server.version}";
  runAsRoot = ''
      #!${stdenv.shell}
      ${dockerTools.shadowSetup}
      groupadd -r jenkins
      useradd -r -g jenkins -d /var/lib/jenkins -M jenkins
      mkdir -p /var/lib/jenkins
      mkdir /var/lib/jenkins/tmp
      mkdir /tmp
      mkdir /var/lib/jenkins/.ssh
      echo "github.com ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ==" >> /var/lib/jenkins/.ssh/known_hosts
      chown -R jenkins:jenkins /var/lib/jenkins
  '';

  contents = [ jenkins-server ] ++ (with pkgs; [
    bash
    coreutils
    gawk
    git
    openssh
    cacert
  ]);

  config = {
    User = "jenkins";
    Cmd = [ "jenkins-server" ];
    Entrypoint = [ entrypoint ];
    Env = [
      "JENKINS_HOME=/var/lib/jenkins"
      "GIT_SSL_CAINFO=${cacert}/etc/ssl/certs/ca-bundle.crt"
      "SSL_CERT_FILE=${cacert}/etc/ssl/certs/ca-bundle.crt"
    ];
    ExposedPorts = {
      "8080/tcp" = {};
    };
    WorkingDir = "/var/lib/jenkins";
    Volumes = {
      "/var/lib/jenkins" = {};
    };
  };
}
