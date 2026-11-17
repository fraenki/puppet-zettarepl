# frozen_string_literal: true

require 'spec_helper'

describe Puppet::Type.type(:zettarepl_settings) do
  let(:resource) { described_class.new(name: 'zettarepl', config: { 'timezone' => 'UTC' }) }

  it 'uses name as the only namevar' do
    expect(described_class.key_attributes).to eq([:name])
  end

  it 'is not ensurable' do
    expect(described_class.validproperty?(:ensure)).to be false
  end

  it 'accepts a config hash' do
    expect(resource[:config]).to eq('timezone' => 'UTC')
  end

  it 'rejects a config that is not a hash' do
    expect {
      described_class.new(name: 'zettarepl', config: 'UTC')
    }.to raise_error(Puppet::ResourceError, %r{config must be a Hash})
  end

  it 'rejects an empty name' do
    expect {
      described_class.new(name: '')
    }.to raise_error(Puppet::ResourceError, %r{name must be a non-empty string})
  end

  it 'rejects sections in config' do
    expect {
      described_class.new(name: 'zettarepl', config: { 'transports' => {} })
    }.to raise_error(Puppet::ResourceError, %r{must not contain the sections transports})
  end
end
