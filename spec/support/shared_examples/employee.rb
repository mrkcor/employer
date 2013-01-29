shared_examples "an employee" do
  let(:employee) { described_class.new }
  let(:completing_job_class) do
    Class.new do
      def perform
        sleep 0.2
      end
    end
  end
  let(:completing_job) { completing_job_class.new}
  let(:failing_job_class) do
    Class.new do
      def perform
        sleep 0.2
        raise "Oops"
      end
    end
  end
  let(:failing_job) { failing_job_class.new}
  let(:job) { double("Job") }

  describe "#work" do
    it "rejects a job while its already working on one" do
      employee.should_receive(:free?).and_return(false)
      expect { employee.work(job) }.to raise_error(Employer::Errors::EmployeeBusy)
    end
  end

  describe "#work_in_progress?" do
    it "is true while a job is running" do
      employee.work(completing_job)
      employee.work_in_progress?.should be_true
      sleep 0.3
      employee.work_in_progress?.should be_false
    end
  end

  describe "#work_completed?" do
    it "is true when a job completes" do
      employee.work(completing_job)
      employee.work_completed?.should be_false
      sleep 0.3
      employee.work_completed?.should be_true
    end

    it "is false when a job fails" do
      employee.work(failing_job)
      employee.work_completed?.should be_false
      sleep 0.3
      employee.work_completed?.should be_false
    end
  end

  describe "#work_failed?" do
    it "is true when a job fails" do
      employee.work(failing_job)
      employee.work_failed?.should be_false
      sleep 0.3
      employee.work_failed?.should be_true
    end

    it "is false when a job completes" do
      employee.work(completing_job)
      employee.work_failed?.should be_false
      sleep 0.3
      employee.work_failed?.should be_false
    end
  end

  describe "#wait_for_completion" do
    it "waits for the job to complete" do
      employee.work(completing_job)
      employee.wait_for_completion
      employee.work_in_progress?.should be_false
      employee.work_completed?.should be_true
      employee.free?.should be_false
    end
  end

  describe "#free" do
    before(:each) do
      employee.work(job)
    end

    it "clears job state after its completed a job, allowing for a new job to be worked on" do
      employee.should_receive(:work_completed?).and_return(true)
      employee.free
      employee.free?.should be_true
      employee.job.should be_nil
    end

    it "clears job state after it failed a job, allowing for a new job to be worked on" do
      employee.should_receive(:work_completed?).and_return(false)
      employee.should_receive(:work_failed?).and_return(true)
      employee.free
      employee.free?.should be_true
      employee.job.should be_nil
    end

    it "does not clear job state while it is still busy" do
      employee.should_receive(:work_completed?).and_return(false)
      employee.should_receive(:work_failed?).and_return(false)
      employee.free
      employee.free?.should be_false
      employee.job.should eq(job)
    end
  end
end
