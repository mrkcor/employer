require "employer/employees/threading_employee"
require "support/shared_examples/employee"

describe Employer::Employees::ThreadingEmployee do
  it_behaves_like "an employee"
end
