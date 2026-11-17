# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require 'puppet_x/zettarepl/config_file'

describe PuppetX::Zettarepl::ConfigFile do
  let(:tmpdir) { Dir.mktmpdir }
  let(:path) { File.join(tmpdir, 'zettarepl.yaml') }

  before(:each) do
    allow(described_class).to receive(:path).and_return(path)
  end

  after(:each) do
    FileUtils.remove_entry(tmpdir)
  end

  describe '.read' do
    it 'returns an empty hash if the file is missing' do
      expect(described_class.read).to eq({})
    end

    it 'returns an empty hash if the file is empty' do
      File.write(path, '')
      expect(described_class.read).to eq({})
    end

    it 'returns the parsed definition' do
      File.write(path, "---\ntimezone: UTC\n")
      expect(described_class.read).to eq('timezone' => 'UTC')
    end

    it 'resolves YAML aliases' do
      File.write(path, "---\nschedule: &hourly\n  minute: '0'\nother: *hourly\n")
      expect(described_class.read['other']).to eq('minute' => '0')
    end

    it 'fails on invalid YAML' do
      File.write(path, "---\ntimezone: [UTC\n")
      expect { described_class.read }.to raise_error(Puppet::Error, %r{Unable to parse})
    end

    it 'fails if the content is not a hash' do
      File.write(path, "---\n- UTC\n")
      expect { described_class.read }.to raise_error(Puppet::Error, %r{content is not a hash})
    end
  end

  describe '.sections' do
    it 'returns the sections holding named entries' do
      expect(described_class.sections).to eq(['periodic-snapshot-tasks', 'replication-tasks', 'transports'])
    end
  end

  describe '.write' do
    it 'writes hash keys sorted recursively' do
      described_class.write('transports' => { 'b' => {}, 'a' => { 'z' => 1, 'y' => [2, 1] } }, 'timezone' => 'UTC')
      expect(File.read(path)).to eq("---\ntimezone: UTC\ntransports:\n  a:\n    y:\n    - 2\n    - 1\n    z: 1\n  b: {}\n")
    end

    it 'creates a new file with mode 0600' do
      described_class.write({})
      expect(File.stat(path).mode & 0o777).to eq(0o600)
    end

    it 'keeps the mode of an existing file' do
      File.write(path, "--- {}\n")
      File.chmod(0o640, path)
      described_class.write('timezone' => 'UTC')
      expect(File.stat(path).mode & 0o777).to eq(0o640)
    end
  end
end
