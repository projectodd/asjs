/*
 * Copyright 2008-2012 Red Hat, Inc, and individual contributors.
 * 
 * This is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as
 * published by the Free Software Foundation; either version 2.1 of
 * the License, or (at your option) any later version.
 * 
 * This software is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public
 * License along with this software; if not, write to the Free
 * Software Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
 * 02110-1301 USA, or see the FSF site: http://www.fsf.org.
 */

package org.projectodd.asjs.core.as;

import static org.jboss.as.controller.descriptions.ModelDescriptionConstants.ADD;
import static org.jboss.as.controller.descriptions.ModelDescriptionConstants.OP;
import static org.jboss.as.controller.descriptions.ModelDescriptionConstants.OP_ADDR;
import static org.projectodd.polyglot.core.processors.RootedDeploymentProcessor.rootSafe;

import java.util.List;

import org.jboss.as.controller.AbstractBoottimeAddStepHandler;
import org.jboss.as.controller.OperationContext;
import org.jboss.as.controller.OperationFailedException;
import org.jboss.as.controller.ServiceVerificationHandler;
import org.jboss.as.server.DeploymentProcessorTarget;
import org.jboss.as.server.deployment.Phase;
import org.jboss.dmr.ModelNode;
import org.jboss.logging.Logger;
import org.jboss.msc.service.ServiceController;
import org.projectodd.polyglot.core.processors.ApplicationExploder;
import org.projectodd.polyglot.core.processors.ArchiveDirectoryMountingProcessor;
import org.projectodd.polyglot.core.processors.ArchiveStructureProcessor;

class CoreSubsystemAdd extends AbstractBoottimeAddStepHandler {

    @Override
    protected void populateModel(ModelNode operation, ModelNode model) {
        model.get( "injector" ).setEmptyObject();
    }

    @Override
    protected void performBoottime(OperationContext context, ModelNode operation, ModelNode model,
            ServiceVerificationHandler verificationHandler,
            List<ServiceController<?>> newControllers) throws OperationFailedException {

        try {
            addCoreServices( context, verificationHandler, newControllers );
        } catch (Exception e) {
            throw new OperationFailedException( e, null );
        }

    }

    protected void addDeploymentProcessors(final DeploymentProcessorTarget processorTarget) {

        processorTarget.addDeploymentProcessor( Phase.STRUCTURE, 0, new ArchiveStructureProcessor( ".jsar" ) );

        processorTarget.addDeploymentProcessor( Phase.PARSE, 100, new ApplicationExploder() );

        processorTarget.addDeploymentProcessor( Phase.DEPENDENCIES, 0, rootSafe( new CoreDependenciesProcessor() ) );
        processorTarget.addDeploymentProcessor( Phase.POST_MODULE, 100, new ArchiveDirectoryMountingProcessor() );
    }

    protected void addCoreServices(final OperationContext context, ServiceVerificationHandler verificationHandler, List<ServiceController<?>> newControllers) throws Exception {
    }

    static ModelNode createOperation(ModelNode address) {
        final ModelNode subsystem = new ModelNode();
        subsystem.get( OP ).set( ADD );
        subsystem.get( OP_ADDR ).set( address );
        return subsystem;
    }

    public CoreSubsystemAdd() {
    }

    static final CoreSubsystemAdd ADD_INSTANCE = new CoreSubsystemAdd();
    static final Logger log = Logger.getLogger( "org.projectodd.asjs.core.as" );

}
