require "employer/boss"

describe Employer::Boss do
  let(:pipeline) { double("Pipeline") }
  let(:employee) { double("Employee") }
  let(:free_employee) { double("Free employee", free?: true) }
  let(:busy_employee) { double("Busy employee", free?: false) }
  let(:boss) { Employer::Boss.new }

  it "can be given a pipeline" do
    boss.pipeline = pipeline
    boss.pipeline.should eq(pipeline)
  end

  it "can be given employees" do
    john = double
    jane = double
    boss.allocate_employee(john)
    boss.allocate_employee(jane)
    boss.employees.should eq([john, jane])
  end

  describe "#delegate_work" do
    let(:job1) { double("Job 1") }
    let(:job2) { double("Job 2") }
    let(:employee1) { double("Employee 1") }
    let(:employee2) { double("Employee 2") }
    let(:employee3) { double("Employee 3") }

    before(:each) do
      pipeline.stub(:dequeue).and_return(job1, job2, nil, nil)
      boss.pipeline = pipeline
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

  describe "#update_job_status" do
    before(:each) do
      boss.pipeline = pipeline
    end

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
