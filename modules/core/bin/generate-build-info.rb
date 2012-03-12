#!/usr/bin/env ruby

require 'java'
require 'rexml/document'

class BuildInfo
  def initialize()
    @versions = Hash.new { |hash, key| hash[key] = { } }
  end

  def determine_asjs_versions
    version = from_system_property( "version.asjs" )
    version = 'unknown' if version.nil? || version.empty?

    build_revision = `git rev-parse HEAD`.strip
    git_output = `git status -s`.lines
    build_revision << ' +modifications' if git_output.any? {|line| line =~ /^ M/ }

    @versions['ASjs'] = {
      'version' => version,
      'build.revision' => build_revision,
      'build.user' => ENV['USER'],
      'build.number' => ENV['BUILD_NUMBER']
    }
  end

  def m2_repo
    ENV['M2_REPO'] || (ENV['HOME'] + '/.m2/repository')
  end

  def determine_component_versions
    #it would be nice to include mod_cluster as well
    @versions["JBossAS"]["version"] = from_system_property( "version.jbossas" )
    @versions["DynJS"]["version"] = from_system_property( "version.dynjs" )
  end

  def dump_versions
    path = File.dirname( __FILE__ ) + '/../target/classes/org/projectodd/asjs/asjs.properties'
    File.open( path, 'w' ) do |out|
      @versions.each do |component, data|
        data.each do |key, value|
          out.write("#{component}.#{key}=#{value}\n")
        end
      end
    end
  end

  def from_system_property(selector)
    java.lang.System.getProperty( selector )
  end

  def from_polyglot_properties(name)
    unless @polyglot_props
      pg_version = from_system_property( "version.polyglot" )
      require File.join( m2_repo, "org/projectodd/polyglot-core/#{pg_version}/polyglot-core-#{pg_version}.jar" )
      @polyglot_props = java.util.Properties.new
      @polyglot_props.load( org.projectodd.polyglot.core.ProjectInfo.java_class.class_loader.getResourceAsStream( "org/projectodd/polyglot/polyglot.properties" ) )
      end
    @polyglot_props.get_property( name )
  end

  def go!()
    determine_asjs_versions
    determine_component_versions
    dump_versions
  end
end

BuildInfo.new.go!
