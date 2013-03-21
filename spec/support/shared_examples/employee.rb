shared_examples "an employee" do
  let(:logger) { double("Logger").as_null_object }
  let(:employee) { described_class.new(logger) }
  let(:completing_job_class) do
    Class.new do
      def id
        1
      end

      def perform
        sleep 0.2
      end
    end
  end
  let(:completing_job) { completing_job_class.new}
  let(:failing_job_class) do
    Class.new do
      def id
        2
      end

      def perform
        sleep 0.2
        raise "Oops"
      end
    end
  end
  let(:failing_job) { failing_job_class.new}
  let(:job) { double("Job", id: 3) }

  describe "#initialize" do
    it "sets the logger" do
      employee = described_class.new(logger)
      employee.logger.should eq(logger)
    end
  end

  describe "#work" do
    it "rejects a job while its already working on one" do
      employee.should_receive(:free?).and_return(false)
      expect { employee.work(job) }.to raise_error(Employer::Errors::EmployeeBusy)
    end

    it "executes before fork hooks" do
      hook1 = lambda { "hook 1" }
      hook1.should_receive(:call)

      hook2 = lambda { "hook 2" }
      hook2.should_receive(:call)

      described_class.before_fork(&hook1)
      described_class.before_fork(&hook2)
      employee.work(job)
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

  describe "#stop_working" do
    it "stops job immediately" do
      employee.work(completing_job)
      employee.should_receive(:force_work_stop).and_call_original
      employee.stop_working
      employee.work_in_progress?.should be_false
      employee.free?.should be_false
    end

    it "just returns if the job just completed" do
      employee.work(completing_job)
      employee.wait_for_completion
      employee.should_receive(:force_work_stop).never
      employee.stop_working
    end

    it "just returns if the job just failed" do
      employee.work(failing_job)
      employee.wait_for_completion
      employee.should_receive(:force_work_stop).never
      employee.stop_working
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
