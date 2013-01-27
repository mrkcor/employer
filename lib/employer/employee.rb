require_relative "employee/invalid_job"

module Employer
  class Employee
    def work(job)
      raise InvalidJob if [:perform, :try_again?, :complete, :reset, :fail].find { |message| !job.respond_to?(message) }
      begin
        job.perform
        job.complete
      rescue => exception
        if job.try_again?
          job.reset
        else
          job.fail
        end
      end
    end
  end
end
