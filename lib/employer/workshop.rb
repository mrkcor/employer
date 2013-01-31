require_relative "errors"

module Employer
  class Workshop
    def self.setup(config_code, skip_employees = false)
      boss = Employer::Boss.new
      pipeline = Employer::Pipeline.new
      boss.pipeline = pipeline
      workshop = new(boss, config_code, skip_employees)
    end

    def self.pipeline(filename)
      workshop = setup(File.read(filename), true)
      workshop.pipeline
    end

    def run
      @boss.manage
    end

    def stop
      @boss.stop_managing
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

    def initialize(boss, config_code, skip_employees)
      @boss = boss
      @forking_employees = 0
      @threading_employees = 0

      instance_eval(config_code)

      unless skip_employees
        @forking_employees.times do
          @boss.allocate_employee(Employer::Employees::ForkingEmployee.new)
        end

        @threading_employees.times do
          @boss.allocate_employee(Employer::Employees::ThreadingEmployee.new)
        end
      end
    end
  end
end
