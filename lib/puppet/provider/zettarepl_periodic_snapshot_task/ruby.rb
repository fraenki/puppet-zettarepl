# frozen_string_literal: true

require 'puppet_x/zettarepl/provider_base'

Puppet::Type.type(:zettarepl_periodic_snapshot_task).provide(:ruby) do
  desc 'Manages periodic snapshot tasks in the zettarepl definition file.'

  include PuppetX::Zettarepl::ProviderBase

  def self.section
    'periodic-snapshot-tasks'
  end
end
