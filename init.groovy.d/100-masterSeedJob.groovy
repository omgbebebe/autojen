import jenkins.model.Jenkins;
import hudson.model.FreeStyleProject;
import hudson.plugins.git.GitSCM;
import hudson.tasks.Shell;
import javaposse.jobdsl.plugin.*;

def url = "https://github.com/omgbebebe/autojen.git";

job = Jenkins.instance.createProject(FreeStyleProject, 'masterSeed')
def gitScm = new GitSCM(url);
gitScm.branches = [new hudson.plugins.git.BranchSpec("*/master")];
job.scm = gitScm;
job.getBuildersList().clear();

jdsl = new ExecuteDslScripts()

jdsl.setTargets("jobs/maintenance/security_seed.groovy");

job.buildersList.add(jdsl);
job.buildersList.add(new Shell('echo hello world'))
job.save()
build = job.scheduleBuild2(5, new hudson.model.Cause.UserIdCause())
build.get() // Block until the build finishes
//generatedJobs = build.getAction(javaposse.jobdsl.plugin.actions.GeneratedJobsBuildAction).getItems()
// FIXME skip .scheduleBuild2() on Folder jobs
//generatedJobs.each { j -> j.scheduleBuild2(5, new hudson.model.Cause.UserIdCause()) }
