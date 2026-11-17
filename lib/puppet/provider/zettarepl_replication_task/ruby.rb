# frozen_string_literal: true

require_relative '../../../puppet_x/zettarepl/provider_base'

Puppet::Type.type(:zettarepl_replication_task).provide(:ruby) do
  desc 'Manages replication tasks in the zettarepl definition file.'

  include PuppetX::Zettarepl::ProviderBase

  def self.section
    'replication-tasks'
  end
end
