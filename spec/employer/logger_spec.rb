require "employer/logger"

describe Employer::Logger do
  let(:logger) { Employer::Logger.new }
  let(:stdout_logger) { double("STDOUT Logger") }
  let(:file_logger) { double("File Logger") }
  let(:message) { "log me, please" }
  let(:block) { lambda { "log me please" } }

  describe "#append_to" do
    it "accepts other loggers to write to" do
      logger.append_to(stdout_logger)
      logger.append_to(file_logger)
      logger.loggers.should include(stdout_logger)
      logger.loggers.should include(file_logger)
    end
  end

  context "with loggers assigned" do
    before(:each) do
      logger.append_to(stdout_logger)
      logger.append_to(file_logger)
    end

    describe "#debug" do
      it "passes string messages to its loggers" do
        stdout_logger.should_receive(:debug).with(message)
        file_logger.should_receive(:debug).with(message)
        logger.debug(message)
      end

      it "passes block messages to its loggers" do
        stdout_logger.should_receive(:debug).with(&block)
        file_logger.should_receive(:debug).with(&block)
        logger.debug(&block)
      end
    end

    describe "#error" do
      it "passes string messages to its loggers" do
        stdout_logger.should_receive(:error).with(message)
        file_logger.should_receive(:error).with(message)
        logger.error(message)
      end

      it "passes block messages to its loggers" do
        stdout_logger.should_receive(:error).with(&block)
        file_logger.should_receive(:error).with(&block)
        logger.error(&block)
      end
    end

    describe "#warn" do
      it "passes string messages to its loggers" do
        stdout_logger.should_receive(:warn).with(message)
        file_logger.should_receive(:warn).with(message)
        logger.warn(message)
      end

      it "passes block messages to its loggers" do
        stdout_logger.should_receive(:warn).with(&block)
        file_logger.should_receive(:warn).with(&block)
        logger.warn(&block)
      end
    end

    describe "#info" do
      it "passes string messages to its loggers" do
        stdout_logger.should_receive(:info).with(message)
        file_logger.should_receive(:info).with(message)
        logger.info(message)
      end

      it "passes block messages to its loggers" do
        stdout_logger.should_receive(:info).with(&block)
        file_logger.should_receive(:info).with(&block)
        logger.info(&block)
      end
    end

    describe "#fatal" do
      it "passes string messages to its loggers" do
        stdout_logger.should_receive(:fatal).with(message)
        file_logger.should_receive(:fatal).with(message)
        logger.fatal(message)
      end

      it "passes block messages to its loggers" do
        stdout_logger.should_receive(:fatal).with(&block)
        file_logger.should_receive(:fatal).with(&block)
        logger.fatal(&block)
      end
    end
  end
end
