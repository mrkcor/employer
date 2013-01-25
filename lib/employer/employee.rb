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
      job_process_state(true)
    end

    def free?
      @job.nil?
    end

    def work_in_progress?
      true if job_process_state == :busy
    end

    def work_completed?
      true if job_process_state == :complete
    end

    def work_failed?
      true if job_process_state == :failed
    end

    def free
      return unless work_completed? || work_failed?
      @job_process_state = nil
      @job_pid = nil
      @job = nil
    end

    private

    def job_process_state(wait = false)
      return @job_process_state if [:complete, :failed].include?(@job_process_state)

      @job_process_state = :busy

      flags = wait == false ? Process::WNOHANG : 0
      pid, status = Process.waitpid2(@job_pid, flags)
      if pid
        if status.exitstatus == 0
          @job_process_state = :complete
        else
          @job_process_state = :failed
        end
      end

      @job_process_state
    end
  end
end
