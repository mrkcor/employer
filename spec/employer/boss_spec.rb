require "employer/boss"

describe Employer::Boss do
  before(:each) do
    stub_const("Employer::Pipeline", Class.new)
    Employer::Pipeline.stub(:new).and_return(pipeline)
  end

  let(:pipeline) { double("Pipeline") }
  let(:employee) { double("Employee") }
  let(:free_employee) { double("Free employee", free?: true) }
  let(:busy_employee) { double("Busy employee", free?: false) }
  let(:logger) { double("Logger").as_null_object }
  let(:boss) { Employer::Boss.new(logger) }

  describe "#initialize" do
    let(:logger) { double("Logger") }

    it "sets the logger" do
      boss = Employer::Boss.new(logger)
      boss.logger.should eq(logger)
    end

    it "sets a pipeline with the logger" do
      Employer::Pipeline.should_receive(:new).with(logger).and_return(pipeline)
      boss = Employer::Boss.new(logger)
      boss.pipeline.should eq(pipeline)
    end
  end

  describe "#pipeline_backend=" do
    it "sets the pipeline backend" do
      backend = double("Backend")
      boss.pipeline.should_receive(:backend=).with(backend)
      boss.pipeline_backend = backend
    end
  end

  describe "#allocate_employee" do
    it "can be given employees" do
      john = double
      jane = double
      boss.allocate_employee(john)
      boss.allocate_employee(jane)
      boss.employees.should eq([john, jane])
    end
  end

  describe "#manage" do
    it "delegates work and collects progress updates until stopped, and then wait on employees" do
      boss.should_receive(:keep_going).and_return(true, true, false)
      boss.should_receive(:delegate_work).twice
      boss.should_receive(:progress_update).twice
      boss.should_receive(:wait_on_employees)
      boss.manage
    end
  end

  describe "#stop_managing" do
    it "sets keep_going to false" do
      boss.keep_going.should eq(nil)
      boss.stop_managing
      boss.keep_going.should eq(false)
    end
  end

  describe "#delegate_work" do
    let(:job1) { double("Job 1") }
    let(:job2) { double("Job 2") }
    let(:employee1) { double("Employee 1") }
    let(:employee2) { double("Employee 2") }
    let(:employee3) { double("Employee 3") }

    before(:each) do
      boss.stub(:get_work).and_return(job1, job2, nil, nil)
    end

    it "puts free employees to work while work is available" do
      employee1_free = true
      employee2_free = true
      employee1.stub(:free?) { employee1_free }
      employee2.stub(:free?) { employee2_free }
      employee3.stub(:free?).and_return(false)
      employee1.should_receive(:work).with(job1) { employee1_free = false }
      employee2.should_receive(:work).with(job2) { employee2_free = false }
      employee3.should_receive(:work).never
      boss.allocate_employee(employee1)
      boss.allocate_employee(employee2)
      boss.allocate_employee(employee3)
      boss.delegate_work
    end

    it "puts free employees to work" do
      employee1_free = true
      employee1.stub(:free?) { employee1_free }
      employee1.should_receive(:work).with(job1) { employee1_free = false }
      boss.allocate_employee(employee1)
      boss.delegate_work

      employee1_free = true
      employee1.should_receive(:work).with(job2) { employee1_free = false }
      boss.delegate_work

      employee1_free = true
      employee1.should_receive(:work).never
      boss.delegate_work
    end
  end

  describe "#get_work" do
    before(:each) do
      pipeline.stub(:dequeue).and_return(nil)
    end

    it "increases sleep time each time it gets no job" do
      boss.should_receive(:sleep).with(0.5).ordered
      boss.get_work.should be_nil
      boss.should_receive(:sleep).with(1).ordered
      boss.get_work.should be_nil
      boss.should_receive(:sleep).with(2.5).ordered
      boss.get_work.should be_nil
      boss.should_receive(:sleep).with(5).ordered
      boss.get_work.should be_nil
      boss.should_receive(:sleep).with(5).ordered
      boss.get_work.should be_nil
    end

    it "increases resets sleep time when it gets a job" do
      job = double("Job")
      pipeline.stub(:dequeue).and_return(nil, nil, job, job)
      boss.should_receive(:sleep).with(0.5).ordered
      boss.get_work.should be_nil
      boss.should_receive(:sleep).with(1).ordered
      boss.get_work.should be_nil
      boss.should_receive(:sleep).with(0.1).ordered
      boss.get_work.should eq(job)
      boss.should_receive(:sleep).with(0.1).ordered
      boss.get_work.should eq(job)
    end
  end

  describe "#update_job_status" do
    let(:job) { double("Job") }
    let(:employee) { employee = double("Employee", job: job) }

    it "completes the job and frees the employee if employee reports job completed" do
      employee.should_receive(:work_in_progress?).and_return(false)
      employee.should_receive(:work_completed?).and_return(true)
      employee.should_receive(:free)
      pipeline.should_receive(:complete).with(job)
      boss.update_job_status(employee)
    end

    it "fails the job and frees the employee if employee reports job failed, and the job may not be retried" do
      employee.should_receive(:work_in_progress?).and_return(false)
      employee.should_receive(:work_completed?).and_return(false)
      employee.should_receive(:work_failed?).and_return(true)
      employee.should_receive(:free)
      job.should_receive(:try_again?).and_return(false)
      pipeline.should_receive(:fail).with(job)
      boss.update_job_status(employee)
    end

    it "resets the job and frees the employee if employee reports job failed, and the job may be retried" do
      employee.should_receive(:work_in_progress?).and_return(false)
      employee.should_receive(:work_completed?).and_return(false)
      employee.should_receive(:work_failed?).and_return(true)
      employee.should_receive(:free)
      job.should_receive(:try_again?).and_return(true)
      pipeline.should_receive(:reset).with(job)
      boss.update_job_status(employee)
    end

    it "does nothing when the work is still in progress" do
      employee.should_receive(:work_in_progress?).and_return(true)
      boss.update_job_status(employee)
    end
  end

  describe "#progess_update" do
    it "gets progress updates from busy employees with #update_job_status" do
      busy_employee = double("Busy employee", free?: false)
      free_employee = double("Free employee", free?: true)
      boss.allocate_employee(free_employee)
      boss.allocate_employee(busy_employee)
      boss.should_receive(:update_job_status).with(busy_employee)
      boss.should_receive(:update_job_status).with(free_employee).never
      boss.progress_update
    end
  end

  describe "#wait_on_employees" do
    it "will wait for all busy employees to complete their work, then perform a progress update" do
      busy_employee = double("Busy employee", free?: false)
      free_employee = double("Free employee", free?: true)
      boss.allocate_employee(free_employee)
      boss.allocate_employee(busy_employee)
      busy_employee.should_receive(:wait_for_completion)
      free_employee.should_receive(:wait_for_completion).never
      boss.should_receive(:update_job_status).with(busy_employee)
      boss.wait_on_employees
    end
  end

  describe "#stop_employees" do
    it "will force all employees to stop their work" do
      busy_employee = double("Busy employee", free?: false).as_null_object
      free_employee = double("Free employee", free?: true)
      boss.allocate_employee(free_employee)
      boss.allocate_employee(busy_employee)
      busy_employee.should_receive(:stop_working)
      busy_employee.should_receive(:free)
      free_employee.should_receive(:stop_working).never
      free_employee.should_receive(:free).never
      boss.should_receive(:update_job_status).with(busy_employee)
      boss.stop_employees
    end
  end

  describe "#delegate_job" do
    let(:job) { double("Job") }

    it "will put a free employee to work on a job" do
      employee.should_receive(:free?).and_return(true)
      boss.allocate_employee(employee)
      employee.should_receive(:work).with(job)
      boss.delegate_job(job)
    end

    it "will raise when there is no free employee" do
      expect { boss.delegate_job(job) }.to raise_error(Employer::Errors::NoEmployeeFree)
    end
  end

  describe "#free_employee?" do
    it "true if there is atleast one employee free" do
      employee.should_receive(:free?).and_return(true)
      boss.allocate_employee(employee)
      boss.free_employee?.should be_true
    end

    it "false if there is no free employee" do
      employee.should_receive(:free?).and_return(false)
      boss.allocate_employee(employee)
      boss.free_employee?.should be_false
    end
  end

  describe "#busy_employees" do
    it "returns the busy employees" do
      boss.allocate_employee(busy_employee)
      boss.allocate_employee(free_employee)
      boss.busy_employees.should eq([busy_employee])
    end

    it "returns [] when there is are no busy employees" do
      boss.allocate_employee(free_employee)
      boss.busy_employees.should eq([])
    end
  end

  describe "#free_employee" do
    it "returns the first free employee" do
      boss.allocate_employee(busy_employee)
      boss.allocate_employee(free_employee)
      boss.free_employee.should eq(free_employee)
    end

    it "returns nil when there is no free employee" do
      boss.allocate_employee(busy_employee)
      boss.free_employee.should be_nil
    end
  end
end
