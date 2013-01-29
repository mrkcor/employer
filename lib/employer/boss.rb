require_relative "errors"

module Employer
  class Boss
    attr_reader :pipeline, :employees

    def initialize
      @pipeline = nil
      @employees = []
    end

    def pipeline=(pipeline)
      @pipeline = pipeline
    end

    def allocate_employee(employee)
      employees << employee
    end

    def stop_managing
      @keep_going = false
    end

    def manage
      @keep_going = true

      while @keep_going
        delegate_work
        progress_update
        sleep 0.1
      end

      wait_on_employees
    end

    def delegate_work
      while free_employee? && job = pipeline.dequeue
        delegate_job(job)
      end
    end

    def progress_update
      busy_employees.each do |employee|
        update_job_status(employee)
      end
    end

    def update_job_status(employee)
      return if employee.work_in_progress?

      job = employee.job

      if employee.work_completed?
        pipeline.complete(job)
      elsif employee.work_failed?
        if job.try_again?
          pipeline.reset(job)
        else
          pipeline.fail(job)
        end
      end

      employee.free
    end

    def wait_on_employees
      busy_employees.each do |employee|
        employee.wait_for_completion
        update_job_status(employee)
      end
    end

    def delegate_job(job)
      raise Employer::Errors::NoEmployeeFree unless employee = free_employee
      employee.work(job)
    end

    def busy_employees
      employees.select { |employee| !employee.free? }
    end

    def free_employee
      employees.find(&:free?)
    end

    def free_employee?
      free_employee
    end
  end
end
