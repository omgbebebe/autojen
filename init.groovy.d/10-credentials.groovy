import com.cloudbees.plugins.credentials.impl.*
import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.domains.*
import com.cloudbees.jenkins.plugins.sshcredentials.impl.*
import org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl
import hudson.util.Secret
import groovy.json.JsonSlurper


def credsFile = new File('./secrets/creds.json')
def creds = new JsonSlurper().parse(credsFile)
assert creds instanceof Map
creds.each { entry ->
  switch(entry.key) {
  case "ssh":
    println("processing SSH credentials");
    entry.value.each { e -> 
      println("create: " + e.id);
      def source = new BasicSSHUserPrivateKey.DirectEntryPrivateKeySource(e.key)
      def ck = new BasicSSHUserPrivateKey(CredentialsScope.GLOBAL,e.id, e.username, source, "", e.description)
      SystemCredentialsProvider.getInstance().getStore().addCredentials(Domain.global(), ck)
    }
    break;
  case "secret":
    println("processing Single secrets");
    entry.value.each { e -> 
      println("create: " + e.id);
      def st = new StringCredentialsImpl(CredentialsScope.GLOBAL, e.id, e.description, Secret.fromString(e.secret))
      SystemCredentialsProvider.getInstance().getStore().addCredentials(Domain.global(), st)
    }
    break;
  case "userpassword":
    println("processing User/Password pairs");
    entry.value.each { e -> 
      println("create: " + e.id);
      Credentials c = (Credentials) new UsernamePasswordCredentialsImpl(CredentialsScope.GLOBAL,e.id, e.description, e.user, e.password)
      SystemCredentialsProvider.getInstance().getStore().addCredentials(Domain.global(), c)
    }
    break;
  default:
    println("skip unknown creedntials type: " + entry.key);
    break;
  }
}
