# frozen_string_literal: true

require_relative '../../../puppet_x/zettarepl/provider_base'

Puppet::Type.type(:zettarepl_transport).provide(:ruby) do
  desc 'Manages transports in the zettarepl definition file.'

  include PuppetX::Zettarepl::ProviderBase

  def self.section
    'transports'
  end
end
