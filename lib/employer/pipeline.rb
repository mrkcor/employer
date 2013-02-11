require_relative "errors"

module Employer
  class Pipeline
    attr_reader :logger

    def initialize(logger)
      @logger = logger
    end

    def backend=(backend)
      @backend = backend
    end

    def backend
      @backend
    end

    def enqueue(job)
      raise Employer::Errors::PipelineBackendRequired if backend.nil?
      serialized_job = job.serialize
      backend.enqueue(serialized_job)
    end

    def dequeue
      raise Employer::Errors::PipelineBackendRequired if backend.nil?
      if serialized_job = backend.dequeue
        job_class = constantize(serialized_job[:class])
        job_class.deserialize(serialized_job)
      end
    end

    def clear
      raise Employer::Errors::PipelineBackendRequired if backend.nil?
      logger.info("Clearing pipeline of all jobs!")
      backend.clear
    end

    def complete(job)
      raise Employer::Errors::PipelineBackendRequired if backend.nil?
      logger.info("Marking job #{job.id} as complete")
      backend.complete(job)
    end

    def reset(job)
      raise Employer::Errors::PipelineBackendRequired if backend.nil?
      logger.info("Resetting job #{job.id}")
      backend.reset(job)
    end

    def fail(job)
      raise Employer::Errors::PipelineBackendRequired if backend.nil?
      logger.info("Marking job #{job.id} as failed")
      backend.fail(job)
    end

    private

    def constantize(camel_cased_word)
      names = camel_cased_word.split('::')
      names.shift if names.empty? || names.first.empty?

      constant = Object
      names.each do |name|
        constant = constant.const_defined?(name, false) ? constant.const_get(name) : constant.const_missing(name)
      end
      constant
    end
  end
end
