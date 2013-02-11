require_relative "errors"

module Employer
  class Workshop
    attr_reader :logger

    def self.pipeline(filename)
      new(File.read(filename), true).pipeline
    end

    def initialize(config_code, skip_employees = false)
      @logger = Employer::Logger.new
      @boss = Employer::Boss.new(logger)
      @forking_employees = 0
      @threading_employees = 0

      instance_eval(config_code)

      unless skip_employees
        @forking_employees.times do
          @boss.allocate_employee(Employer::Employees::ForkingEmployee.new(logger))
        end

        @threading_employees.times do
          @boss.allocate_employee(Employer::Employees::ThreadingEmployee.new(logger))
        end
      end
    end

    def run
      @boss.manage
    end

    def stop
      @boss.stop_managing
    end

    def stop_now
      @boss.stop_managing
      @boss.stop_employees
    end

    def pipeline
      @boss.pipeline
    end

    def log_to(log_to_logger)
      logger.append_to(log_to_logger)
    end

    private

    def forking_employees(number)
      @forking_employees = number
    end

    def threading_employees(number)
      @threading_employees = number
    end

    def pipeline_backend(backend)
      @boss.pipeline_backend = backend
    end
  end
end
