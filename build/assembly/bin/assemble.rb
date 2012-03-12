#!/usr/bin/env ruby

$: << File.dirname( __FILE__ ) + '/../lib'

require 'java'
require 'assembly_tool'
require 'fileutils'
require 'rexml/document'
require 'rbconfig'

java_import java.lang.System

class Assembler 

  attr_accessor :tool
  attr_accessor :jboss_zip

  attr_accessor :asjs_version
  attr_accessor :jboss_version
  attr_accessor :polyglot_version

  attr_accessor :m2_repo
  attr_accessor :config_stash
  
  def initialize() 
    @tool = AssemblyTool.new(:deployment_timeout => 1200, :enable_welcome_root => false)
    determine_versions

    @m2_repo   = @tool.m2_repo

    puts "Maven repo: #{@m2_repo}"
    @jboss_zip = @m2_repo + "/org/jboss/as/jboss-as-dist/#{@jboss_version}/jboss-as-dist-#{@jboss_version}.zip"

    @config_stash = File.dirname(__FILE__) + '/../target'
  end

  def determine_versions
    @asjs_version = System.getProperty( "version.asjs" )
    @jboss_version     = System.getProperty( "version.jbossas" )
    @polyglot_version  = System.getProperty( "version.polyglot" )
    puts "AS.js.... #{@asjs_version}"
    puts "JBoss........ #{@jboss_version}"
    puts "Polyglot..... #{@polyglot_version}"
  end

  def clean()
    FileUtils.rm_rf   tool.build_dir
  end

  def prepare()
    FileUtils.mkdir_p tool.asjs_dir
  end

  def lay_down_jboss
    if File.exist?( tool.jboss_dir ) 
      #puts "JBoss already laid down"
    else
      puts "Laying down JBoss"
      Dir.chdir( File.dirname( tool.jboss_dir ) ) do
        tool.unzip( jboss_zip )
        original_dir= File.expand_path( Dir[ 'jboss-*' ].first )
        FileUtils.mv original_dir, tool.jboss_dir
      end
    end
  end

  def polyglot_modules
    @polyglot_modules ||= ['hasingleton']
  end
  
  def install_modules
    modules = Dir[ tool.base_dir + '/../../modules/*/target/*-module' ].map do |module_dir|
      [ File.basename( module_dir, '-module' ).gsub( /asjs-/, '' ), module_dir ]
    end

    # Ensure core module is first-ish
    modules.unshift( modules.assoc( "core" ) ).uniq!

    modules.each do |module_name, module_dir|
      tool.install_module( module_name, module_dir )
    end

    polyglot_modules.each do |name|
      tool.install_polyglot_module( name, polyglot_version )
    end
  end

  def stash_stock_configs
    FileUtils.cp( tool.jboss_dir + '/standalone/configuration/standalone-full.xml',
                  config_stash + '/standalone-full.xml' ) unless File.exist?( config_stash + '/standalone-full.xml' )
    FileUtils.cp( tool.jboss_dir + '/standalone/configuration/standalone-full-ha.xml',
                  config_stash + '/standalone-full-ha.xml' ) unless File.exist?( config_stash + '/standalone-full-ha.xml' )
    FileUtils.cp( tool.jboss_dir + '/domain/configuration/domain.xml',
                  config_stash + '/domain.xml' )     unless File.exist?( config_stash + '/domain.xml' )
  end

  def stash_stock_host_config
    FileUtils.cp( tool.jboss_dir + '/domain/configuration/host.xml',
                  config_stash + '/host.xml' ) unless File.exist?( config_stash + '/host.xml' )
  end

  def trash_stock_host_config
    FileUtils.rm_f( tool.jboss_dir + '/domain/configuration/host.xml' )
  end

  def trash_stock_configs
    FileUtils.rm_f( Dir[ tool.jboss_dir + '/standalone/configuration/standalone*.xml' ] )
    FileUtils.rm_f( Dir[ tool.jboss_dir + '/domain/configuration/domain*.xml' ] )
  end

  def transform_configs
    stash_stock_configs
    trash_stock_configs
    polyglot_mods = polyglot_modules.map { |name| ["projectodd", "polyglot", name]}
    tool.transform_config(config_stash + '/standalone-full.xml',
                          'standalone/configuration/standalone-full.xml',
                          :extra_modules => polyglot_mods)
    tool.transform_config(config_stash + '/standalone-full-ha.xml',
                          'standalone/configuration/standalone-full-ha.xml',
                          :extra_modules => polyglot_mods,
                          :ha => true )
    tool.transform_config(config_stash + '/domain.xml',
                          'domain/configuration/domain.xml',
                          :extra_modules => polyglot_mods,
                          :domain => true,
                          :ha => true )
  end

  def transform_host_config
    stash_stock_host_config
    trash_stock_host_config
    tool.transform_host_config( config_stash + '/host.xml', 'domain/configuration/host.xml' )
  end

  def transform_standalone_confs
    tool.transform_standalone_conf
    tool.transform_standalone_conf_bat
  end

  def assemble()
    #clean
    prepare
    lay_down_jboss
    install_modules
    transform_configs
    transform_host_config
    transform_standalone_confs
    Dir.chdir( tool.jboss_dir ) do
      FileUtils.cp( 'standalone/configuration/standalone-full.xml', 'standalone/configuration/standalone.xml' )
      FileUtils.cp( 'standalone/configuration/standalone-full-ha.xml', 'standalone/configuration/standalone-ha.xml' )
    end
  end
end

if __FILE__ == $0 || '-e' == $0 # -e == called from mvn
  Assembler.new.assemble
end

