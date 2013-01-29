require_relative "employee/busy"

module Employer
  class Employee
    attr_reader :job

    def initialize
      @free = true
    end

    def work(job)
      raise Busy unless free?
      @job = job

      @job_pid = fork do
        state = nil

        begin
          job.perform
          state = 0
        ensure
          state = 1 if state.nil?
          exit(state)
        end
      end
    end

    def wait_for_completion
      work_state(true)
    end

    def free?
      @job.nil?
    end

    def work_in_progress?
      true if work_state == :busy
    end

    def work_completed?
      true if work_state == :complete
    end

    def work_failed?
      true if work_state == :failed
    end

    def free
      return unless work_completed? || work_failed?
      @work_state = nil
      @job_pid = nil
      @job = nil
    end

    private

    def work_state(wait = false)
      return @work_state if [:complete, :failed].include?(@work_state)

      @work_state = :busy

      flags = wait == false ? Process::WNOHANG : 0
      pid, status = Process.waitpid2(@job_pid, flags)
      if pid
        if status.exitstatus == 0
          @work_state = :complete
        else
          @work_state = :failed
        end
      end

      @work_state
    end
  end
end
