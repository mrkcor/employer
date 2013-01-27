require_relative "employee/invalid_job"
require_relative "employee/busy"

module Employer
  class Employee
    def initialize
      @free = true
    end

    def work(job)
      raise InvalidJob if [:perform, :try_again?, :complete, :reset, :fail].find { |message| !job.respond_to?(message) }
      raise Busy unless free?
      @free = false
      begin
        job.perform
        job.complete
      rescue => exception
        if job.try_again?
          job.reset
        else
          job.fail
        end
      ensure
        @free = true
      end
    end

    def free?
      @free
    end
  end
end
