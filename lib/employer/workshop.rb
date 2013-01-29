require_relative "errors"

module Employer
  class Workshop
    def self.setup(&block)
      boss = Employer::Boss.new
      pipeline = Employer::Pipeline.new
      boss.pipeline = pipeline
      workshop = new(boss, &block)
    end

    def run
      @boss.manage
    end

    def pipeline
      @boss.pipeline
    end

    private

    def forking_employees(number)
      @forking_employees = number
    end

    def threading_employees(number)
      @threading_employees = number
    end

    def pipeline_backend(backend)
      @boss.pipeline.backend = backend
    end

    def initialize(boss, &block)
      @boss = boss
      @forking_employees = 0
      @threading_employees = 0

      instance_exec(&block)

      @forking_employees.times do
        @boss.allocate_employee(Employer::Employees::ForkingEmployee.new)
      end

      @threading_employees.times do
        @boss.allocate_employee(Employer::Employees::ThreadingEmployee.new)
      end
    end
  end
end
