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

package org.projectodd.asjs;

import java.io.IOException;
import java.util.List;

import org.jboss.logging.Logger;
import org.jboss.msc.service.Service;
import org.jboss.msc.service.StartContext;
import org.jboss.msc.service.StartException;
import org.jboss.msc.service.StopContext;
import org.projectodd.polyglot.core.ProjectInfo;

/**
 * Primary marker and build/version information provider.
 * 
 * @author Toby Crawley
 * @author Bob McWhirter
 */
public class AsJs extends ProjectInfo implements AsJsMBean, Service<AsJs> {

    /**
     * Construct.
     * 
     * @throws IOException
     *             if an error occurs while reading the underlying properties
     *             file.
     */
    public AsJs() throws IOException {
        super( "ASjs", "org/projectodd/asjs/asjs.properties" );
    }

    @Override
    public AsJs getValue() throws IllegalStateException, IllegalArgumentException {
        return this;
    }

    @Override
    public void start(StartContext context) throws StartException {
    }

    public void printVersionInfo(Logger log) {
        log.info( "Welcome to AS.js - http://asjs.projectodd.org/" );
        log.info( formatOutput( "version", getVersion() ) );
        String buildNo = getBuildNumber();
        if (buildNo != null && !buildNo.trim().equals( "" )) {
            log.info( formatOutput( "build", getBuildNumber() ) );
        } else if (getVersion().contains( "SNAPSHOT" )) {
            log.info( formatOutput( "build", "development (" + getBuildUser() + ")" ) );
        } else {
            log.info( formatOutput( "build", "official" ) );
        }
        log.info( formatOutput( "revision", getRevision() ) );

        List<String> otherCompoments = getBuildInfo().getComponentNames();
        otherCompoments.remove( "ASjs" );
        log.info( "  built with:" );
        for (String name : otherCompoments) {
            String version = getBuildInfo().get( name, "version" );
            if (version != null) {
                log.info( formatOutput( "  " + name, version ) );
            }
        }

    }

    public void verifyDynJsVersion(Logger log) {
        String dynJs = getBuildInfo().get( "DynJS", "version" );
        /*
        String jarVersion = JRubyConstants.getVersion();
    
        if (!jarVersion.equals( jrubyVersion )) {
            log.warn( "WARNING: TorqueBox was built and tested with JRuby " + 
                      jrubyVersion + " and you are running JRuby " + 
                      jarVersion + ". You may experience unexpected results. Side effects may include: itching, sleeplessness, and irritability." );
        }
        */
    }
    
    @Override
    public void stop(StopContext context) {

    }

}
