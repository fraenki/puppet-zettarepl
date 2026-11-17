# frozen_string_literal: true

require 'spec_helper'

describe Puppet::Type.type(:zettarepl_transport) do
  let(:resource) { described_class.new(name: 'example', config: { 'key' => 'value' }) }

  it 'uses name as the only namevar' do
    expect(described_class.key_attributes).to eq([:name])
  end

  it 'defaults ensure to present' do
    expect(resource[:ensure]).to eq(:present)
  end

  it 'accepts a config hash' do
    expect(resource[:config]).to eq('key' => 'value')
  end

  it 'rejects a config that is not a hash' do
    expect {
      described_class.new(name: 'example', config: 'value')
    }.to raise_error(Puppet::ResourceError, %r{config must be a Hash})
  end

  it 'marks config as sensitive' do
    expect(resource.property(:config).sensitive).to be true
  end

  it 'rejects an empty name' do
    expect {
      described_class.new(name: '')
    }.to raise_error(Puppet::ResourceError, %r{name must be a non-empty string})
  end
end
