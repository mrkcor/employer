require_relative "pipeline/invalid_backend"
require_relative "pipeline/backend_required"

module Employer
  class Pipeline
    def backend=(backend)
      raise InvalidBackend if [:enqueue, :dequeue, :complete, :reset, :fail].find { |message| !backend.respond_to?(message) }
      @backend = backend
    end

    def backend
      @backend
    end

    def enqueue(job)
      raise BackendRequired if backend.nil?
      serialized_job = job.serialize
      backend.enqueue(serialized_job)
    end

    def dequeue
      raise BackendRequired if backend.nil?
      if serialized_job = backend.dequeue
        job_class = constantize(serialized_job[:class])
        dequeued_job = job_class.deserialize(serialized_job)
        dequeued_job.pipeline = self
        dequeued_job
      end
    end

    def complete(job)
      raise BackendRequired if backend.nil?
      backend.complete(job)
    end

    def reset(job)
      raise BackendRequired if backend.nil?
      backend.reset(job)
    end

    def fail(job)
      raise BackendRequired if backend.nil?
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
