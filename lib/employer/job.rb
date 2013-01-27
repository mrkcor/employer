require_relative "job/class_mismatch"
require_relative "job/invalid_pipeline"
require_relative "job/no_pipeline"

module Employer
  module Job
    attr_accessor :id
    attr_reader :pipeline

    module ClassMethods
      def attribute(name)
        name = name.to_sym
        unless attribute_names.include?(name)
          attribute_names << name
          attr_accessor name
        end
      end

      def attribute_names
        @attribute_names ||= []
      end

      def deserialize(serialized_job)
        raise ClassMismatch unless serialized_job[:class] == self.name
        job = new
        job.id = serialized_job[:id]
        serialized_job[:attributes].each_pair do |attribute, value|
          job.public_send("#{attribute}=", value)
        end
        job
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
    end

    def attribute_names
      self.class.attribute_names
    end

    def pipeline=(pipeline)
      raise InvalidPipeline unless pipeline.respond_to?(:complete) && pipeline.respond_to?(:reset)
      @pipeline = pipeline
    end

    def complete
      raise NoPipeline if pipeline.nil?
      pipeline.complete(self)
    end

    def fail
      raise NoPipeline if pipeline.nil?
      pipeline.fail(self)
    end

    def reset
      raise NoPipeline if pipeline.nil?
      pipeline.reset(self)
    end

    def try_again?
      false
    end

    def serialize
      {
        id: id,
        class: self.class.name,
        attributes: Hash[
          attribute_names.
            reject { |name| self.send(name).nil? }.
            map { |name| [name, self.send(name)] }
        ]
      }.reject { |key, value| value.nil? }
    end
  end
end
