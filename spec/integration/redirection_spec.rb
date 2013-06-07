require 'puma'
require 'support/integration_helper'
require 'chef/knife/list_essentials'

describe 'redirection' do
  extend IntegrationSupport
  include KnifeSupport

  when_the_chef_server 'has a role' do
    role 'x', {}

    context 'and another server redirects to it with 302' do
      before :each do
        @real_chef_server_url = Chef::Config.chef_server_url
        Chef::Config.chef_server_url = "http://127.0.0.1:9018"
        app = lambda do |env|
          [302, {'Content-Type' => 'text','Location' => "#{@real_chef_server_url}#{env['PATH_INFO']}" }, ['302 found'] ]
        end
        @redirector_server = Puma::Server.new(app, Puma::Events.new(STDERR, STDOUT))
        @redirector_server.add_tcp_listener("127.0.0.1", 9018)
        @redirector_server.run
        Timeout::timeout(5) do
          until @redirector_server.running
            sleep(0.01)
          end
          raise @server_error if @server_error
        end
      end

      after :each do
        Chef::Config.chef_server_url = @real_chef_server_url
        @redirector_server.stop(true)
      end

      it 'knife list /roles returns the role' do
        knife('list /roles').should_succeed "/roles/x.json\n"
      end
    end
  end
end
