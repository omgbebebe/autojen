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
      chown -R jenkins:jenkins /var/lib/jenkins
  '';

  contents = [ jenkins-server ] ++ (with pkgs; [
    bash
    coreutils
    gawk
    git
  ]);

  config = {
    Cmd = [ "jenkins-server" ];
    Entrypoint = [ entrypoint ];
    Env = [
      "JENKINS_HOME=/var/lib/jenkins"
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
