require "thor"
require "fileutils"

module Employer
  class CLI < Thor
    default_task :work

    desc "work", "Process jobs"
    option :config, default: "config/employer.rb", desc: "Config file to use"
    def work
      unless File.exists?(options[:config])
        STDERR.puts "#{options[:config]} does not exist."
        exit 1
      end

      int_count = 0
      workshop = Employer::Workshop.new(File.read(options[:config]))

      Signal.trap("INT") do
        int_count += 1
        if int_count == 1
          workshop.stop
        else
          workshop.stop_now
        end
      end

      workshop.run
    end

    desc "clear", "Clear jobs"
    option :config, default: "config/employer.rb", desc: "Config file to use"
    def clear
      unless File.exists?(options[:config])
        STDERR.puts "#{options[:config]} does not exist."
        exit 1
      end

      Employer::Workshop.pipeline(options[:config]).clear
    end

    desc "config", "Generate config file"
    option :config, default: "config/employer.rb", desc: "Path to config file"
    def config
      if File.exists?(options[:config])
        STDERR.puts "#{options[:config]} already exists."
        exit 1
      end

      FileUtils.mkdir("config") unless File.directory?("config")

      File.open(options[:config], "w") do |file|
        file.write <<CONFIG
# If you're using Rails the below line requires config/environment to setup the
# Rails environment. If you're not using Rails you'll want to require something
# here that sets up Employer's environment appropriately (making available the
# classes that your jobs need to do their work, providing the connection to
# your database, etc.)
# require "./config/environment"

require "employer-mongoid"

# Setup the backend for the pipeline, this is where the boss gets the jobs to
# process. See the documentation for details on writing your own pipeline
# backend.
pipeline_backend Employer::Mongoid::Pipeline.new

# Use employees that fork subprocesses to perform jobs. You cannot use these
# with JRuby, because JRuby doesn't support Process#fork.
forking_employees 4

# Use employees that run their jobs in threads, you can use these when using
# JRuby. While threaded employees also work with MRI they are limited by the
# GIL (this may or may not be a problem depending on the type of work your jobs
# need to do).
# threading_employees 4
CONFIG
      end
    end
  end
end
