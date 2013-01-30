require "thor"
require "fileutils"

module Employer
  class CLI < Thor
    default_task :process

    desc "process", "Process jobs"
    option :config, default: "config/employer.rb", desc: "Configuration file to setup Employer"
    def process
      unless File.exists?(options[:config])
        STDERR.puts "#{options[:config]} does not exist."
        exit 1
      end

      workshop = Employer::Workshop.setup { load(options[:config]) }
      Signal.trap("INT") { workshop.stop }
      workshop.run
    end

    desc "configure", "Generate configuration file"
    option :config, default: "config/employer.rb", desc: "Path to configuration file"
    def configure
      if File.exists?(options[:config])
        STDERR.puts "#{options[:config]} already exists."
        exit 1
      end

      FileUtils.mkdir("config")

      File.open(options[:config], "w") do |file|
        file.write <<CONFIG
require "employer-mongoid"

# Setup the backend for the pipeline, this is where the boss gets the jobs to
# process. See the documentation for details on writing your own pipeline
# backend.
pipeline_backend Employer::Pipeline::Backend::Mongoid.new

# Use employees that fork subprocesses to perform jobs.
forking_employees 4

# Use employees that run their jobs in threads.
# threading_employees 4
CONFIG
      end
    end
  end
end
