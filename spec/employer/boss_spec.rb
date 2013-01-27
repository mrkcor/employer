require "employer/boss"

describe Employer::Boss do
  let(:pipeline) { double("Pipeline", dequeue: nil) }
  let(:employee) { double("Employee", work: nil, free?: true) }
  let(:boss) { Employer::Boss.new }

  describe "#allocate_pipeline" do
    it "can be allocated pipelines" do
      boss.allocate_pipeline(pipeline)
      boss.pipelines.should eq([pipeline])
    end

    it "rejects invalid pipelines" do
      expect { boss.allocate_pipeline(double) }.to raise_error(Employer::Boss::InvalidPipeline)
    end
  end

  describe "#allocate_employee" do
    it "can be allocated employees" do
      boss.allocate_employee(employee)
      boss.employees.should eq([employee])
    end

    it "rejects invalid employees" do
      expect { boss.allocate_employee(double) }.to raise_error(Employer::Boss::InvalidEmployee)
    end
  end

  describe "#manage" do
    let(:job1) { double("Job 1") }
    let(:job2) { double("Job 2") }
    let(:pipeline) { double("Pipeline") }
    let(:employee1) { double("Employee 1", free?: true, work: nil) }
    let(:employee2) { double("Employee 2", free?: true, work: nil) }
    let(:employee3) { double("Employee 3", free?: true, work: nil) }

    before(:each) do
      pipeline.stub(:dequeue).and_return(job1, job2, nil, nil)
      boss.allocate_pipeline(pipeline)
    end

    it "puts free employees to work while work is available" do
      employee1_free = true
      employee2_free = true
      employee1.stub(:free?) { employee1_free }
      employee2.stub(:free?) { employee2_free }
      employee1.should_receive(:work).with(job1) { employee1_free = false }
      employee2.should_receive(:work).with(job2) { employee2_free = false }
      employee3.should_receive(:work).never
      boss.allocate_employee(employee1)
      boss.allocate_employee(employee2)
      boss.allocate_employee(employee3)
      boss.manage
    end

    it "puts free employees to work" do
      employee1_free = true
      employee1.stub(:free?) { employee1_free }
      employee1.should_receive(:work).with(job1) { employee1_free = false }
      boss.allocate_employee(employee1)
      boss.manage

      employee1_free = true
      employee1.should_receive(:work).with(job2) { employee1_free = false }
      boss.manage

      employee1_free = true
      employee1.should_receive(:work).never
      boss.manage
    end
  end

  describe "#wait_on_employees" do
    it "waits for all employees to finish their work" do
      employee_free = false
      employee.stub(:free?) { employee_free }
      employee.should_receive(:join) { employee_free = true }
      boss.allocate_employee(employee)
      boss.wait_on_employees
    end
  end

  describe "#delegate" do
    let(:job) { double("Job") }

    it "will put a free employee to work on a job" do
      boss.allocate_employee(employee)
      employee.should_receive(:work).with(job)
      boss.delegate(job)
    end

    it "will raise when there is no free employee" do
      expect { boss.delegate(job) }.to raise_error(Employer::Boss::NoEmployeeFree)
    end
  end

  describe "#employee_free?" do
    it "true if there is atleast one employee free" do
      boss.allocate_employee(employee)
      boss.employee_free?.should be_true
    end

    it "false if there is no free employee" do
      employee.should_receive(:free?).and_return(false)
      boss.allocate_employee(employee)
      boss.employee_free?.should be_false
    end
  end

  describe "#busy_employees" do
    let(:free_employee) { double("Employee", work: nil, free?: true) }
    let(:busy_employee) { double("Employee", work: nil, free?: false) }

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
    let(:free_employee) { double("Employee", work: nil, free?: true) }
    let(:busy_employee) { double("Employee", work: nil, free?: false) }

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

  describe "#find_work" do
    let(:pipeline1) { double("Pipeline 1", dequeue: nil) }
    let(:pipeline2) { double("Pipeline 2", dequeue: nil) }

    before(:each) do
      boss.allocate_pipeline(pipeline1)
      boss.allocate_pipeline(pipeline2)
    end

    it "dequeues a job from the first pipeline that yields one" do
      job = double("Job")
      pipeline2.should_receive(:dequeue).and_return(job)
      boss.find_work.should eq(job)
    end

    it "returns nil when there is nothing in the pipelines" do
      boss.find_work.should eq(nil)
    end
  end
end
