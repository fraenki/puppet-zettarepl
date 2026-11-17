# frozen_string_literal: true

require 'spec_helper'
require 'puppet_x/zettarepl/config_file'

describe Puppet::Type.type(:zettarepl_periodic_snapshot_task).provider(:ruby) do
  let(:type_class) { Puppet::Type.type(:zettarepl_periodic_snapshot_task) }
  let(:config_file) { PuppetX::Zettarepl::ConfigFile }
  let(:hourly) { { 'dataset' => 'tank/data', 'recursive' => true } }
  let(:data) do
    {
      'periodic-snapshot-tasks' => { 'hourly' => hourly },
      'timezone' => 'UTC',
    }
  end

  before(:each) do
    allow(config_file).to receive(:read).and_return(data)
  end

  it 'manages the periodic-snapshot-tasks section' do
    expect(described_class.section).to eq('periodic-snapshot-tasks')
  end

  describe '.instances' do
    it 'returns one provider per task' do
      instances = described_class.instances
      expect(instances.map(&:name)).to eq(['hourly'])
      expect(instances.first.config).to eq(hourly)
      expect(instances.first.exists?).to be true
    end

    it 'returns no providers if the section is missing' do
      allow(config_file).to receive(:read).and_return({})
      expect(described_class.instances).to eq([])
    end
  end

  describe '.prefetch' do
    it 'assigns the provider of an existing task to its resource' do
      hourly_resource = type_class.new(name: 'hourly', config: hourly)
      daily_resource = type_class.new(name: 'daily', config: hourly)
      described_class.prefetch('hourly' => hourly_resource, 'daily' => daily_resource)
      expect(hourly_resource.provider.exists?).to be true
      expect(hourly_resource.provider.config).to eq(hourly)
      expect(daily_resource.provider.exists?).to be false
    end
  end

  describe '#create' do
    it 'adds the task and keeps all other content' do
      resource = type_class.new(name: 'daily', config: { 'dataset' => 'tank/other' })
      expect(config_file).to receive(:write).with(
        'periodic-snapshot-tasks' => { 'hourly' => hourly, 'daily' => { 'dataset' => 'tank/other' } },
        'timezone' => 'UTC',
      )
      resource.provider.create
    end

    it 'fails without config' do
      resource = type_class.new(name: 'daily')
      expect { resource.provider.create }.to raise_error(Puppet::Error, %r{config is required})
    end
  end

  describe '#config=' do
    it 'replaces the whole task' do
      resource = type_class.new(name: 'hourly', config: { 'dataset' => 'tank/new' })
      expect(config_file).to receive(:write).with(
        'periodic-snapshot-tasks' => { 'hourly' => { 'dataset' => 'tank/new' } },
        'timezone' => 'UTC',
      )
      resource.provider.config = { 'dataset' => 'tank/new' }
    end
  end

  describe '#destroy' do
    it 'removes the task and the empty section' do
      resource = type_class.new(name: 'hourly', ensure: 'absent')
      expect(config_file).to receive(:write).with('timezone' => 'UTC')
      resource.provider.destroy
    end

    it 'removes a task with a numeric name' do
      allow(config_file).to receive(:read).and_return('periodic-snapshot-tasks' => { 1 => hourly, 'hourly' => hourly })
      resource = type_class.new(name: '1', ensure: 'absent')
      expect(config_file).to receive(:write).with('periodic-snapshot-tasks' => { 'hourly' => hourly })
      resource.provider.destroy
    end
  end
end
