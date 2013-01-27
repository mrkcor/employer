require_relative "boss/invalid_pipeline"
require_relative "boss/invalid_employee"
require_relative "boss/no_employee_free"

module Employer
  class Boss
    attr_reader :pipelines, :employees

    def initialize
      @pipelines = []
      @employees = []
    end

    def allocate_pipeline(pipeline)
      raise InvalidPipeline unless pipeline.respond_to?(:dequeue)
      pipelines << pipeline
    end

    def allocate_employee(employee)
      raise InvalidEmployee unless employee.respond_to?(:work) && employee.respond_to?(:free?)
      employees << employee
    end

    def manage
      while employee_free? && job = find_work
        delegate(job)
      end
    end

    def wait_on_employees
      busy_employees.each(&:join)
    end

    def delegate(job)
      raise NoEmployeeFree unless employee = free_employee
      employee.work(job)
    end

    def busy_employees
      employees.select { |employee| !employee.free? }
    end

    def free_employee
      employees.find(&:free?)
    end

    def employee_free?
      free_employee
    end

    def find_work
      job = nil
      pipelines.find { |pipeline| job = pipeline.dequeue }
      job
    end
  end
end
