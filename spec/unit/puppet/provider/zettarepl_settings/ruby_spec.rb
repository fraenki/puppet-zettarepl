# frozen_string_literal: true

require 'spec_helper'
require 'puppet_x/zettarepl/config_file'

describe Puppet::Type.type(:zettarepl_settings).provider(:ruby) do
  let(:type_class) { Puppet::Type.type(:zettarepl_settings) }
  let(:config_file) { PuppetX::Zettarepl::ConfigFile }
  let(:sections) do
    {
      'periodic-snapshot-tasks' => { 'hourly' => { 'dataset' => 'tank/data' } },
      'replication-tasks' => { 'offsite' => { 'direction' => 'push' } },
      'transports' => { 'backup' => { 'type' => 'local' } },
    }
  end

  before(:each) do
    allow(config_file).to receive(:read).and_return(sections.merge('timezone' => 'UTC', 'use-removal-dates' => true))
  end

  it 'returns a single instance' do
    expect(described_class.instances.map(&:name)).to eq(['zettarepl'])
  end

  it 'returns all top-level keys except the sections' do
    resource = type_class.new(name: 'zettarepl')
    expect(resource.provider.config).to eq('timezone' => 'UTC', 'use-removal-dates' => true)
  end

  it 'returns an empty hash without settings' do
    allow(config_file).to receive(:read).and_return(sections)
    resource = type_class.new(name: 'zettarepl')
    expect(resource.provider.config).to eq({})
  end

  it 'replaces all settings and keeps the sections' do
    resource = type_class.new(name: 'zettarepl')
    expect(config_file).to receive(:write).with(sections.merge('max-parallel-replication-tasks' => 2))
    resource.provider.config = { 'max-parallel-replication-tasks' => 2 }
  end
end
