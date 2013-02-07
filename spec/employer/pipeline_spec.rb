require "employer/pipeline"

describe Employer::Pipeline do
  let(:logger) { double("Logger").as_null_object }
  let(:pipeline) { Employer::Pipeline.new(logger) }
  let(:backend) { double("Pipeline backend") }
  let(:job) { double("Job") }

  describe "#initialize" do
    let(:logger) { double("Logger") }

    it "sets the logger" do
      pipeline = Employer::Pipeline.new(logger)
      pipeline.logger.should eq(logger)
    end
  end

  it "has a pluggable backend" do
    pipeline.backend = backend
    pipeline.backend.should eq(backend)
  end

  describe "#enqueue" do
    it "serializes and then enqueues jobs using its backend" do
      job_id = 1
      serialized_job = {class: "TestJob"}

      job.should_receive(:serialize).and_return(serialized_job)
      backend.should_receive(:enqueue).with(serialized_job).and_return(job_id)

      pipeline.backend = backend
      pipeline.enqueue(job).should eq(job_id)
    end

    it "fails when no backend is set" do
      expect { pipeline.enqueue(job) }.to raise_error(Employer::Errors::PipelineBackendRequired)
    end
  end

  describe "#dequeue" do
    it "dequeues job using its backend and properly instantiates it" do
      stub_const("TestJob", Class.new)
      job_id = 1
      job.stub(:id).and_return(job_id)
      serialized_job = {id: job_id, class: "TestJob"}

      backend.should_receive(:dequeue).and_return(serialized_job)
      TestJob.should_receive(:deserialize).and_return(job)

      pipeline.backend = backend
      dequeued_job = pipeline.dequeue
      dequeued_job.should eq(job)
      dequeued_job.id.should eq(job_id)
    end

    it "returns nil when there is no job in the backend's queue" do
      backend.should_receive(:dequeue).and_return(nil)
      pipeline.backend = backend
      pipeline.dequeue.should be_nil
    end

    it "fails when no backend is set" do
      expect { pipeline.dequeue }.to raise_error(Employer::Errors::PipelineBackendRequired)
    end
  end

  describe "#clear" do
    it "clears all jobs using its backend" do
      backend.should_receive(:clear)
      pipeline.backend = backend
      pipeline.clear
    end

    it "fails when no backend is set" do
      expect { pipeline.clear }.to raise_error(Employer::Errors::PipelineBackendRequired)
    end
  end

  describe "#complete" do
    it "completes job using its backend" do
      backend.should_receive(:complete).with(job)
      pipeline.backend = backend
      pipeline.complete(job)
    end

    it "fails when no backend is set" do
      expect { pipeline.complete(double) }.to raise_error(Employer::Errors::PipelineBackendRequired)
    end
  end

  describe "#reset" do
    it "resets the job using its backend" do
      backend.should_receive(:reset).with(job)
      pipeline.backend = backend
      pipeline.reset(job)
    end

    it "fails when no backend is set" do
      expect { pipeline.reset(double) }.to raise_error(Employer::Errors::PipelineBackendRequired)
    end
  end

  describe "#fail" do
    it "fails the job using its backend" do
      backend.should_receive(:fail).with(job)
      pipeline.backend = backend
      pipeline.fail(job)
    end

    it "fails when no backend is set" do
      expect { pipeline.fail(double) }.to raise_error(Employer::Errors::PipelineBackendRequired)
    end
  end
end
