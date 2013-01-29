require "employer/employees/forking_employee"
require "support/shared_examples/employee"

describe Employer::Employees::ForkingEmployee do
  it_behaves_like "an employee"
  let(:employee) { Employer::Employees::ForkingEmployee.new }
  let(:job) { double("Job") }

  describe "#work" do
    it "forks to perform job, and becomes busy" do
      employee.free?.should be_true
      employee.job.should be_nil
      employee.should_receive(:fork)
      employee.work(job)
      employee.free?.should be_false
      employee.job.should eq(job)
    end
  end
end
