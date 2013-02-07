require "employer"

describe Employer::Workshop do
  before(:each) do
    stub_const("TestPipelineBackend", Class.new)
  end

  let(:config_code) { "pipeline_backend TestPipelineBackend.new" }

  describe "#initialize" do
    let(:workshop) { Employer::Workshop.new(config_code) }

    after(:each) do
      workshop
    end

    it "sets up a logger" do
      workshop.logger.should be_instance_of(Employer::Logger)
    end

    it "sets up a boss" do
      logger = double("Logger")
      Employer::Logger.should_receive(:new).and_return(logger)
      Employer::Boss.should_receive(:new).with(logger).and_call_original
    end

    it "sets the defined pipeline backend" do
      boss = double("Boss")
      Employer::Boss.should_receive(:new).and_return(boss)
      boss.should_receive(:pipeline_backend=).with(instance_of(TestPipelineBackend))
    end

    context "with loggers" do
      before(:each) do
        stub_const("MyFirstLogger", Class.new)
        stub_const("MySecondLogger", Class.new)
      end

      let(:config_code) { "log_to MyFirstLogger.new\nlog_to MySecondLogger.new" }

      it "tells the logger to append to the given logger" do
        workshop_logger = double("Logger")
        Employer::Logger.should_receive(:new).and_return(workshop_logger)
        workshop_logger.should_receive(:append_to).with(instance_of(MyFirstLogger))
        workshop_logger.should_receive(:append_to).with(instance_of(MySecondLogger))
      end
    end

    context "with only forking employees" do
      let(:config_code) { "forking_employees 3" }

      it "allocates forking employees" do
        Employer::Employees::ForkingEmployee.should_receive(:new).with(instance_of(Employer::Logger)).exactly(3).times.and_call_original
        Employer::Boss.any_instance.should_receive(:allocate_employee).with(instance_of(Employer::Employees::ForkingEmployee)).exactly(3).times
      end

      it "does not instantiate threading employees" do
        Employer::Employees::ThreadingEmployee.should_receive(:new).never
      end
    end

    context "with only threading employees" do
      let(:config_code) { "threading_employees 2" }

      it "allocates threading employees" do
        Employer::Employees::ThreadingEmployee.should_receive(:new).with(instance_of(Employer::Logger)).exactly(2).times.and_call_original
        Employer::Boss.any_instance.should_receive(:allocate_employee).with(instance_of(Employer::Employees::ThreadingEmployee)).exactly(2).times
      end

      it "does not instantiate forking employees" do
        Employer::Employees::ForkingEmployee.should_receive(:new).never
      end
    end
  end

  describe ".pipeline" do
    it "returns a pipeline to feed the workshop" do
      Employer::Pipeline.should_receive(:new).and_call_original
      Employer::Pipeline.any_instance.should_receive(:backend=).with(instance_of(TestPipelineBackend)).and_call_original
      File.should_receive(:read).with("config/employee.rb").and_return(config_code)
      workshop_pipeline = Employer::Workshop.pipeline("config/employee.rb")
      workshop_pipeline.should be_instance_of(Employer::Pipeline)
    end
  end

  context "with initialized workshop" do
    let(:workshop) { Employer::Workshop.new(config_code) }
    let(:boss) { Employer::Boss.any_instance }

    describe "#logger" do
      it "returns the logger" do
        workshop.logger.should be_instance_of(Employer::Logger)
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

    describe "#stop_now" do
      it "should call stop_managing and stop_employees on the boss" do
        boss.should_receive(:stop_managing)
        boss.should_receive(:stop_employees)
        workshop.stop_now
      end
    end

    describe "#pipeline" do
      it "returns the pipeline" do
        workshop.pipeline.should be_instance_of(Employer::Pipeline)
      end
    end
  end
end
