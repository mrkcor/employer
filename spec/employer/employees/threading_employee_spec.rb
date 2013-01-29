require "employer/employees/threading_employee"
require "support/shared_examples/employee"

describe Employer::Employees::ThreadingEmployee do
  it_behaves_like "an employee"
  let(:employee) { Employer::Employees::ThreadingEmployee.new }
  let(:job) { double("Job") }

  describe "#work" do
    it "starts new thread to perform job, and becomes busy" do
      employee.free?.should be_true
      employee.job.should be_nil
      Thread.should_receive(:new)
      employee.work(job)
      employee.free?.should be_false
      employee.job.should eq(job)
    end
  end
end
