require "employer/job"

describe Employer::Job do
  let(:job_class) do
    Class.new do
      include Employer::Job

      attribute :name
      attribute :shape
    end
  end
  let(:job) { job_class.new }
  let(:pipeline) { double("Pipeline", complete: nil, reset: nil) }

  before(:each) do
    stub_const("Namespaced::TestJob", job_class)
  end

  it "adds id attribute" do
    job.id.should be_nil
    job.id = 1
    job.id.should eq(1)
  end

  it "can reference a pipeline" do
    job.pipeline.should be_nil
    job.pipeline = pipeline
    job.pipeline.should eq(pipeline)
  end

  it "rejects invalid an pipeline" do
    pipeline = double("Pipeline")
    expect { job.pipeline = double }.to raise_error(Employer::Job::InvalidPipeline)
  end

  describe "#complete" do
    it "informs the pipeline the job is complete" do
      pipeline.should_receive(:complete).with(job)
      job.pipeline = pipeline
      job.complete
    end

    it "raises when there is no pipeline set" do
      expect { job.complete }.to raise_error(Employer::Job::NoPipeline)
    end
  end

  describe ".attribute" do
    it "adds attribute accessors" do
      job.name.should be_nil
      job.name = "Block"
      job.name.should eq("Block")

      job.shape.should be_nil
      job.shape = :square
      job.shape.should eq(:square)
    end

    it "registers attribute names" do
      job_class.attribute_names.should eq([:name, :shape])
      job.attribute_names.should eq([:name, :shape])
    end
  end

  describe "#serialize" do
    it "builds a Hash of id, class name and attributes" do
      job = Namespaced::TestJob.new
      job.id = 1
      job.name = "Ball"
      job.shape = :circle

      job.serialize.should eq({id: 1, class: "Namespaced::TestJob", attributes: {name: "Ball", shape: :circle}})
    end

    it "leaves out id if it is nil" do
      job = Namespaced::TestJob.new
      job.name = "Ball"
      job.shape = :circle

      job.serialize.should eq({class: "Namespaced::TestJob", attributes: {name: "Ball", shape: :circle}})
    end

    it "leaves out attributes with a nil value" do
      job = Namespaced::TestJob.new
      job.id = 1
      job.name = "Ball"

      job.serialize.should eq({id: 1, class: "Namespaced::TestJob", attributes: {name: "Ball"}})
    end
  end

  describe ".deserialize" do
    it "sets the id and attributes" do
      serialized_job = {id: 1, class: "Namespaced::TestJob", attributes: {name: "Ball", shape: :circle}}
      job = Namespaced::TestJob.deserialize(serialized_job)
      job.should be_instance_of(Namespaced::TestJob)
      job.id.should eq(1)
      job.name.should eq("Ball")
      job.shape.should eq(:circle)
    end

    it "must have the right class name" do
      serialized_job = {id: 1, class: "TestJob", attributes: {name: "Ball", shape: :circle}}
      expect { Namespaced::TestJob.deserialize(serialized_job) }.to raise_error(Employer::Job::ClassMismatch)
    end
  end
end
