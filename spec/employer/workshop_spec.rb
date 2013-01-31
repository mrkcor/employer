require "employer/workshop"

describe Employer::Workshop do
  before(:each) do
    stub_const("Employer::Boss", Class.new)
    stub_const("Employer::Pipeline", Class.new)
    stub_const("Employer::Employees::ForkingEmployee", Class.new)
    stub_const("Employer::Employees::ThreadingEmployee", Class.new)
    stub_const("TestPipelineBackend", Class.new)
  end

  let(:boss) { double("Boss").as_null_object }
  let(:config_code) do
    <<CONFIG
    pipeline_backend TestPipelineBackend.new
    forking_employees 2
CONFIG
  end
  let(:workshop) do
    Employer::Boss.should_receive(:new).and_return(boss)
    Employer::Workshop.setup(config_code)
  end

  describe ".setup" do
    it "sets up a workshop" do
      pipeline_backend = double("Pipeline backend")
      TestPipelineBackend.should_receive(:new).and_return(pipeline_backend)
      boss = double("Boss")
      pipeline = double("Pipeline")
      forking_employee1 = double("Forking Employee 1")
      forking_employee2 = double("Forking Employee 2")
      forking_employee3 = double("Forking Employee 3")
      threading_employee1 = double("Threading Employee 1")
      threading_employee2 = double("Threading Employee 2")

      Employer::Boss.should_receive(:new).and_return(boss)
      Employer::Pipeline.should_receive(:new).and_return(pipeline)
      boss.should_receive(:pipeline=).with(pipeline)
      boss.should_receive(:pipeline).and_return(pipeline)
      pipeline.should_receive(:backend=).with(pipeline_backend)
      Employer::Employees::ForkingEmployee.should_receive(:new).and_return(forking_employee1, forking_employee2, forking_employee3)
      Employer::Employees::ThreadingEmployee.should_receive(:new).and_return(threading_employee1, threading_employee2)
      boss.should_receive(:allocate_employee).with(forking_employee1)
      boss.should_receive(:allocate_employee).with(forking_employee2)
      boss.should_receive(:allocate_employee).with(forking_employee3)
      boss.should_receive(:allocate_employee).with(threading_employee1)
      boss.should_receive(:allocate_employee).with(threading_employee2)

      config_code = <<CONFIG
      pipeline_backend TestPipelineBackend.new
      forking_employees 3
      threading_employees 2
CONFIG

      workshop = Employer::Workshop.setup(config_code)
      workshop.should be_instance_of(Employer::Workshop)
    end
  end

  describe ".pipeline" do
    it "sets up a pipeline to feed the workshop" do
      boss = double("Boss").as_null_object
      Employer::Boss.should_receive(:new).and_return(boss)
      pipeline = double("Pipeline").as_null_object
      boss.stub(:pipeline).and_return(pipeline)
      Employer::Pipeline.should_receive(:new).and_return(pipeline)
      pipeline_backend = double("Pipeline backend")
      TestPipelineBackend.should_receive(:new).and_return(pipeline_backend)

      workshop_pipeline = Employer::Workshop.pipeline(config_code)
      workshop_pipeline.should eq(pipeline)
    end
  end

  describe "#run" do
    it "should call manage on the boss" do
      boss.should_receive(:manage)
      workshop.run
    end
  end

  describe "#stop" do
    it "should call stop_managing on the boss" do
      boss.should_receive(:stop_managing)
      workshop.stop
    end
  end

  describe "#pipeline" do
    it "returns the pipeline" do
      pipeline = double("Pipeline").as_null_object
      boss.stub(:pipeline).and_return(pipeline)
      workshop.pipeline.should eq(pipeline)
    end
  end
end
