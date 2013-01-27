require "employer/employee"

describe Employer::Employee do
  let(:employee) { Employer::Employee.new }
  let(:job) { double("Job", perform: nil) }

  describe "#work" do
    it "performs the job and marks it as complete" do
      job.should_receive(:perform)
      job.should_receive(:complete)
      employee.work(job)
    end

    it "rejects invalid jobs" do
      expect { employee.work(double) }.to raise_error(Employer::Employee::InvalidJob)
    end
  end
end
