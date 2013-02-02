require "employer/employees/forking_employee"
require "support/shared_examples/employee"

describe Employer::Employees::ForkingEmployee, unless: RUBY_PLATFORM =~ /java/ do
  it_behaves_like "an employee"
end
