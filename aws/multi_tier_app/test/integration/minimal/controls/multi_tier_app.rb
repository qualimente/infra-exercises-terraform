require 'awspec'
require 'awsecrets'
require 'json'

require_relative 'spec_helper'

# note: Awsecrets is required when running tests by themselves, e.g. `make verify`
Awsecrets.load()


#require 'pry'; binding.pry; #uncomment to jump into the debugger

# retrieve outputs from Terraform state via kitchen-aws attribute helper
# starter_instance_id = attribute 'starter.instance_id', {}
# starter_instance_arn = attribute 'starter.instance_arn', {}
name = attribute 'multi_tier_app.name', {}
app_asg_name = attribute 'multi_tier_app.app.asg.name', {}

expect_owner = name
expect_env = 'training'

control 'multi_tier_app' do

  # imagine 'starter' were a resource in AWS such as an RDS database, we could use
  # awspec to test it like so:
  #
  # For supported AWS resource types, see: https://github.com/k1LoW/awspec/blob/master/doc/resource_types.md
  # 
  # describe "starter #{starter_instance_id}" do
  #   subject { starter(starter_instance_id) } # 'starter' is a made-up resource type; must be replaced
  #
  #   it { should exist }
  #
  #   it { should have_tag('Environment').value(expect_env) }
  #   it { should have_tag('Owner').value(expect_owner) }
  #   it { should have_tag('Application').value(expect_app) }
  #   it { should have_tag('ManagedBy').value('Terraform') }
  # end
  #
  describe "App Autoscaling Group #{app_asg_name}" do
    subject { autoscaling_group(app_asg_name) }

    it { should exist }

    it { should have_tag('Name').value("exercise-#{name}") }
    it { should have_tag('Owner').value(expect_owner) }
    it { should have_tag('Environment').value(expect_env) }
    it { should have_tag('WorkloadType').value('CuteButNamelessCow') }

  end
  
end
