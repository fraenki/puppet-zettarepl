# frozen_string_literal: true

require 'spec_helper'
require 'puppet_x/zettarepl/config_file'

describe Puppet::Type.type(:zettarepl_transport).provider(:ruby) do
  let(:type_class) { Puppet::Type.type(:zettarepl_transport) }
  let(:config_file) { PuppetX::Zettarepl::ConfigFile }
  let(:entry) { { 'type' => 'local' } }

  before(:each) do
    allow(config_file).to receive(:read).and_return('transports' => { 'example' => entry })
  end

  it 'manages the transports section' do
    expect(described_class.section).to eq('transports')
  end

  it 'returns one provider per entry' do
    instances = described_class.instances
    expect(instances.map(&:name)).to eq(['example'])
    expect(instances.first.config).to eq(entry)
  end

  it 'writes a new entry to its section' do
    resource = type_class.new(name: 'other', config: entry)
    expect(config_file).to receive(:write).with({ 'transports' => { 'example' => entry, 'other' => entry } })
    resource.provider.create
  end
end
