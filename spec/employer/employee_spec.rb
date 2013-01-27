require "employer/employee"

describe Employer::Employee do
  let(:employee) { Employer::Employee.new }
  let(:job) { double("Job", perform: nil, try_again?: nil, reset: nil, fail: nil, complete: nil) }

  describe "#work" do
    it "performs the job and marks it as complete" do
      job.should_receive(:perform)
      job.should_receive(:complete)
      employee.work(job)
    end

    it "rejects invalid jobs" do
      expect { employee.work(double) }.to raise_error(Employer::Employee::InvalidJob)
    end

    it "rejects a job while its already working on one" do
      employee.should_receive(:free?).and_return(false)
      expect { employee.work(job) }.to raise_error(Employer::Employee::Busy)
    end

    it "jobs that raise an error and may be tried again are reset" do
      job.should_receive(:perform).and_raise("oh no!")
      job.should_receive(:try_again?).and_return(true)
      job.should_receive(:reset)
      employee.work(job)
    end

    it "jobs that raise an error and may not be tried again are marked as failed" do
      job.should_receive(:perform).and_raise("oh no!")
      job.should_receive(:try_again?).and_return(false)
      job.should_receive(:fail)
      employee.work(job)
    end
  end
end
