require 'json'
require 'rspec/expectations'

require_relative 'spec_helper'

#require 'pry'; binding.pry; #uncomment to jump into the debugger

# retrieve outputs from Terraform state via kitchen-aws attribute helper
tf_state_json = json(attribute 'terraform_state', {})
testing_suffix_hex = attribute 'testing_suffix_hex', {}
lb_web_dns_name = attribute 'multi_tier_app.lb.web.dns_name', {}
app_asg_name = attribute 'multi_tier_app.app.asg.name', {}

#starter_instance_arn = attribute 'starter.instance_arn', {}

puts "testing_suffix_hex: #{testing_suffix_hex}"

name = "minimal-it-#{testing_suffix_hex}"

control 'terraform_state' do
  describe 'the Terraform state file' do
    subject { tf_state_json.terraform_version }

    it('is accessible') { is_expected.to match(/\d+\.\d+\.\d+/) }
  end


  describe 'the Terraform state file' do
    #require 'pry'; binding.pry; #uncomment to jump into the debugger

    # describe outputs
    describe 'outputs' do
      describe('Multi-Tier App Resource Identifiers') do
        describe('Load Balancer DNS Name') do
          subject { lb_web_dns_name }
          # example: exercise-minimal-itf076f1b1-1222039069.us-west-2.elb.amazonaws.com
          it { is_expected.to match(/exercise-#{name}-[\d]+\.[\w-]+\.elb\.amazonaws\.com/) }
        end
        describe('App ASG Name') do
          subject { app_asg_name }
          # example: exercise-minimal-it-f076f1b1-20181216072417711700000002
          it { is_expected.to match(/exercise-#{name}-[\d]+$/) }
        end
        # describe('arn') do
        #   subject { starter_instance_arn }
        #   # example: arn:aws:starter:us-west-2::starter-mJ6Vsw
        #   it { is_expected.to match(/arn:aws:starter:[-\w]+::#{name}-[\w]+/) }
        # end
      end
    end
  end

end
