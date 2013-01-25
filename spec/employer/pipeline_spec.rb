require "employer/pipeline"

describe Employer::Pipeline do
  let(:pipeline) { Employer::Pipeline.new }
  let(:backend) { stub(enqueue: nil, dequeue: nil) }

  describe "configurable backend" do
    it "accepts a compatible backend" do
      pipeline.backend = backend
      pipeline.backend.should eq(backend)
    end

    it "rejects an incompatible backend" do
      expect { pipeline.backend = stub }.to raise_error(Employer::Pipeline::InvalidBackend)
      expect { pipeline.backend = stub(enqueue: nil) }.to raise_error(Employer::Pipeline::InvalidBackend)
      expect { pipeline.backend = stub(dequeue: nil) }.to raise_error(Employer::Pipeline::InvalidBackend)
    end
  end

  describe "#enqueue" do
    let(:job) { stub }

    it "serializes and then enqueues jobs using its backend" do
      job_id = 1
      serialized_job = {}

      job.should_receive(:serialize).and_return(serialized_job)
      backend.should_receive(:enqueue).with(serialized_job).and_return(job_id)

      pipeline.backend = backend
      pipeline.enqueue(job).should eq(job_id)
    end

    it "fails when no backend is set" do
      expect { pipeline.enqueue(job) }.to raise_error(Employer::Pipeline::BackendRequired)
    end
  end

  describe "#dequeue" do
    it "dequeues job using its backend and properly instantiates it" do
      stub_const("TestJob", Class.new)
      job_id = 1
      job = stub(id: job_id)
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
      expect { pipeline.dequeue }.to raise_error(Employer::Pipeline::BackendRequired)
    end
  end
end
