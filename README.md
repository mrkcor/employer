# Employer

There comes a time in the life of an application that async job processing
becomes a requirement. If you want something flexible that you can easily adapt
to fit in with your application's infrastucture, then Employer may be what you
are looking for.

## Installation

Add this line to your application's Gemfile:

    gem 'employer'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install employer

## Usage

To use Employer to run jobs you need to do the following:

- Define your jobs as classes that include the Employer::Job module
- Hook up Employer with a backend to manage the jobs

### Defining your own jobs

Implementing your own jobs is simple, here's a silly example:

```ruby
class NamePutsJob
  include Employer::Job

  attribute :first_name
  attribute :last_name
  attribute :tries

  def initialize
    tries ||= 0 
  end

  def try_again?
    true if tries < 3
  end

  def perform
    puts "#{first_name} #{last_name}"
  end
end
```

The attribute class method will define an attr_accessor and will ensure that the
attribute is part of the serialized data that is sent to the backend when a job
is enqueued.

The perform method is what will get executed when Employer picks up a job for
processing.

If a job fails the try_again? method will determine whether or not the job gets
tried again, if this method returns false the job will be marked as failed and
won't be attempted again.

### Hooking up a backend

Employer manages its jobs through its pipeline, in order to feed jobs into the
pipeline and to get jobs out of the pipeline you need to connect a backend to
it. You can either use a backend that someone has built already (if you're using
Mongoid 3 you can use the employer-mongoid gem), or implement your own. A valid
pipeline backend must implement the methods shown in the below code snippet:

```ruby
class CustomPipelineBackend
  # job_hash is a Hash with the following keys:
  # - class: The class of the Job object
  # - attributes: A Hash with attribute values set on the Job object
  def enqueue(job_hash)
  end

  # dequeue must return a job_hash in the same format as is passed into 
  # enqueue, except that it must add the key id with the Job's unique 
  # identifier (such as a record id)
  def dequeue
  end

  # clear must clear the backend of all its jobs
  def clear
  end

  # complete accepts a Job object, using its id the pipeline backend should
  # mark the job as complete
  def complete(job)
  end

  # fail accepts a Job object, using its id the pipeline backend should
  # mark the job as failed
  def fail(job)
  end

  # reset accepts a Job object, using its id the pipeline backend should
  # reset the job by marking it as free
  def reset(job)
  end
end
```

To hook up the backend to Employer you must generate and edit a config file by
running `employer config` (or more likely `bundle exec employer config`). If you
don't specify a custom path (with -c /path/to/employer\_config.rb) this will
generate config/employer.rb, the file will look something like this:

```ruby
# If you're using Rails the below line requires config/environment to setup the
# Rails environment. If you're not using Rails you'll want to require something
# here that sets up Employer's environment appropriately (making available the
# classes that your jobs need to do their work, providing the connection to
# your database, etc.)
# require "./config/environment"

require "employer-mongoid"

# Setup the backend for the pipeline, this is where the boss gets the jobs to
# process. See the documentation for details on writing your own pipeline
# backend.
pipeline_backend Employer::Mongoid::Pipeline.new

# Use employees that fork subprocesses to perform jobs. You cannot use these
# with JRuby, because JRuby doesn't support Process#fork.
forking_employees 4

# Use employees that run their jobs in threads, you can use these when using
# JRuby. While threaded employees also work with MRI they are limited by the
# GIL (this may or may not be a problem depending on the type of work your jobs
# need to do).
# threading_employees 4
```

The comments in the file pretty much explain how you should edit it.

When setup properly you can start processing jobs by running `employer` (or
`employer -c /path/to/employer\_config.rb`, likely prepended with `bundle exec`)

In your application code you can obtain a pipeline to enqueue jobs with like so:

```ruby
# Obtain the pipeline
pipeline = Employer::Workshop.enqueue("/path/to/employer\_config.rb")

# Enqueue a job
job = NamePutsJob.new
job.first_name = "Mark"
job.last_name = "Kremer"
pipeline.enqueue(job)
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
