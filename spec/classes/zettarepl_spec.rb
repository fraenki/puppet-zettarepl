# frozen_string_literal: true

require 'spec_helper'

purged_types = ['zettarepl_periodic_snapshot_task', 'zettarepl_replication_task', 'zettarepl_transport']

describe 'zettarepl' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      context 'with default parameters' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('zettarepl') }
        it { is_expected.to contain_class('zettarepl::install').that_comes_before('Class[zettarepl::config]') }
        it { is_expected.to contain_class('zettarepl::config').that_notifies('Class[zettarepl::service]') }
        it { is_expected.to contain_class('zettarepl::service') }
        it { is_expected.to contain_package('py312-zettarepl').with_ensure('installed') }
        it { is_expected.to contain_service('zettarepl').with(ensure: 'running', enable: true) }
        it { is_expected.to contain_file('/usr/local/etc/zettarepl.yaml').with(ensure: 'file', owner: 'root', group: 'wheel', mode: '0600') }
        it { is_expected.to contain_file('/usr/local/etc/zettarepl.yaml').with(content: "--- {}\n", replace: false) }
        it { is_expected.to contain_zettarepl_settings('zettarepl').with_config({}) }
        it { is_expected.not_to contain_resources('zettarepl_transport') }
      end

      context 'with tasks, transports and settings' do
        let(:params) do
          {
            periodic_snapshot_tasks: {
              'hourly' => { 'config' => { 'dataset' => 'tank/data' } },
            },
            replication_tasks: {
              'offsite' => { 'ensure' => 'absent' },
            },
            settings: { 'timezone' => 'UTC' },
            transports: {
              'backup' => { 'config' => { 'type' => 'local' } },
            },
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_zettarepl_periodic_snapshot_task('hourly').with(ensure: 'present', config: { 'dataset' => 'tank/data' }) }
        it { is_expected.to contain_zettarepl_replication_task('offsite').with_ensure('absent') }
        it { is_expected.to contain_zettarepl_settings('zettarepl').with_config('timezone' => 'UTC') }
        it { is_expected.to contain_zettarepl_transport('backup').with(ensure: 'present', config: { 'type' => 'local' }) }
      end

      context 'with purge enabled' do
        let(:params) { { purge: true } }

        it { is_expected.to compile.with_all_deps }

        purged_types.each do |type|
          it { is_expected.to contain_resources(type).with(purge: true, notify: 'Class[zettarepl::service]') }
        end
      end

      context 'with the service stopped and disabled' do
        let(:params) { { service_enable: false, service_ensure: 'stopped' } }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_service('zettarepl').with(ensure: 'stopped', enable: false) }
      end

      context 'with a custom package' do
        let(:params) { { package_ensure: 'latest', package_name: 'py311-zettarepl' } }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_package('py311-zettarepl').with_ensure('latest') }
      end

      context 'with package and service management disabled' do
        let(:params) { { package_manage: false, service_manage: false } }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.not_to contain_package('py312-zettarepl') }
        it { is_expected.not_to contain_service('zettarepl') }
      end
    end
  end
end
