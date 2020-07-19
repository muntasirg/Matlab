package com.mathworks.ci;

/**
 * Copyright 2020 The MathWorks, Inc.
 *  
 */

import java.util.Set;
import org.jenkinsci.plugins.workflow.steps.Step;
import org.jenkinsci.plugins.workflow.steps.StepContext;
import org.jenkinsci.plugins.workflow.steps.StepDescriptor;
import org.jenkinsci.plugins.workflow.steps.StepExecution;
import org.kohsuke.stapler.DataBoundConstructor;
import com.google.common.collect.ImmutableSet;
import hudson.EnvVars;
import hudson.Extension;
import hudson.FilePath;
import hudson.Launcher;
import hudson.model.Run;
import hudson.model.TaskListener;

public class RunMatlabCommandStep extends Step {

    
    private String command;

    @DataBoundConstructor
    public RunMatlabCommandStep(String command) {
        this.command = command;
    }


    public String getCommand() {
        return this.command;
    }

    @Override
    public StepExecution start(StepContext context) throws Exception {
        return new MatlabCommandStepExecution(context, getCommand());
    }

    @Extension
    public static class CommandStepDescriptor extends StepDescriptor {

        @Override
        public Set<? extends Class<?>> getRequiredContext() {
            return ImmutableSet.of(TaskListener.class, FilePath.class, Launcher.class,
                    EnvVars.class, Run.class);
        }

        @Override
        public String getFunctionName() {
            return Message.getValue("matlab.command.build.step.name");
        }
        
        @Override
        public String getDisplayName() {
            return Message.getValue("matlab.command.step.display.name");
        }
    }
}


