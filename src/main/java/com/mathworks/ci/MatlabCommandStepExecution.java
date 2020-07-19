package com.mathworks.ci;

import java.io.IOException;
import org.jenkinsci.plugins.workflow.steps.StepContext;
import org.jenkinsci.plugins.workflow.steps.StepExecution;
import hudson.EnvVars;
import hudson.FilePath;
import hudson.Launcher;
import hudson.Launcher.ProcStarter;
import hudson.model.Result;
import hudson.model.TaskListener;

public class MatlabCommandStepExecution extends StepExecution implements MatlabBuild {
    
    private static final long serialVersionUID = 1957239693658914450L;
    
    private String command;
    private EnvVars env;


    public MatlabCommandStepExecution(StepContext context, String command) {
        super(context);
        this.command = command;
    }

    private String getCommand() {
        return this.env == null ? this.command : this.env.expand(this.command );
    }
    
    private void setEnv(EnvVars env) {
        this.env = env;
    }

    @Override
    public boolean start() throws Exception {
        final Launcher launcher = getContext().get(Launcher.class);
        final FilePath workspace = getContext().get(FilePath.class);
        final TaskListener listener = getContext().get(TaskListener.class);
        final EnvVars env = getContext().get(EnvVars.class);
        setEnv(env);
        
        //Make sure the Workspace exists before run
        
        workspace.mkdirs();
        
        int res = execMatlabCommand(workspace, launcher, listener, env);

        getContext().setResult((res == 0) ? Result.SUCCESS : Result.FAILURE);
        
        getContext().onSuccess(true);
        
        //return false represents the asynchronous run. 
        return false;
    }

    @Override
    public void stop(Throwable cause) throws Exception {
        getContext().onFailure(cause);
    }
    
    private synchronized int execMatlabCommand(FilePath workspace, Launcher launcher,
            TaskListener listener, EnvVars envVars) throws IOException, InterruptedException {
        final String uniqueTmpFldrName = getUniqueNameForRunnerFile();
        final String uniqueCommandFile =
                "command_" + getUniqueNameForRunnerFile().replaceAll("-", "_");
        final FilePath uniqeTmpFolderPath =
                getFilePathForUniqueFolder(launcher, uniqueTmpFldrName, workspace);

        // Create MATLAB script
        createMatlabScriptByName(uniqeTmpFolderPath, uniqueCommandFile, workspace, listener);
        ProcStarter matlabLauncher;

        try {
            matlabLauncher = getProcessToRunMatlabCommand(workspace, launcher, listener, envVars,
                    uniqueCommandFile, uniqueTmpFldrName);
            launcher.launch().pwd(uniqeTmpFolderPath).envs(envVars);
            listener.getLogger()
                    .println("#################### Starting command output ####################");
            return matlabLauncher.pwd(uniqeTmpFolderPath).join();

        } catch (Exception e) {
            listener.getLogger().println(e.getMessage());
            return 1;
        } finally {
            // Cleanup the tmp directory
            if (uniqeTmpFolderPath.exists()) {
                uniqeTmpFolderPath.deleteRecursive();
            }
        }
    }
    
    private void createMatlabScriptByName(FilePath uniqeTmpFolderPath, String uniqueScriptName, FilePath workspace, TaskListener listener) throws IOException, InterruptedException {
        
        // Create a new command runner script in the temp folder.
        final FilePath matlabCommandFile =
                new FilePath(uniqeTmpFolderPath, uniqueScriptName + ".m");
        final String matlabCommandFileContent =
                "cd '" + workspace.getRemote().replaceAll("'", "''") + "';\n" + getCommand();

        // Display the commands on console output for users reference
        listener.getLogger()
                .println("Generating MATLAB script with content:\n" + getCommand() + "\n");

        matlabCommandFile.write(matlabCommandFileContent, "UTF-8");
    }
}