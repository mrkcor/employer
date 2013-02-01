require_relative "abstract_employee"

module Employer
  module Employees
    class ForkingEmployee < AbstractEmployee
      def work(job)
        super

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

      def free
        super
        @job_pid = nil
      end

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

      def force_work_stop
        return if free?
        Process.kill("KILL", @job_pid)
        work_state(true)
      end
    end
  end
end
