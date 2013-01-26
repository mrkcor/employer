require_relative "employee/invalid_job"

module Employer
  class Employee
    def work(job)
      raise InvalidJob unless job.respond_to?(:perform)
      job.perform
    end
  end
end
