require 'spec_helper'

describe 'mysql-replication::default' do
  describe 'Mater configuration' do
    sql_command = 'mysql -S /var/run/mysql-default/mysqld.sock -pchange_me'

    context 'creates config' do
      describe file('/etc/mysql-default/conf.d/master.cnf') do
        it { should be_file }
        it { should be_owned_by 'mysql' }
        it { should be_mode 640 }
        its(:content) { should match(/binlog-do-db = test[1-2]/) }
        its(:content) { should match(/log-bin = mysql-bin/) }
        its(:content) { should match(/binlog_format = MIXED/) }
      end
    end

    context 'configures master' do
      describe command("echo 'show slave hosts;' | #{sql_command}") do
        its(:stdout) { should match %r{123} }
      end

      describe command("echo \"show variables like '%log%';\"| #{sql_command}") do
        its(:stdout) { should match %r{log_bin[\s]+ON} }
        its(:stdout) { should match %r{binlog_format[\s]+MIXED} }
      end
    end
  end

  describe 'Slave configuration' do
    sql_command = 'mysql -S /var/run/mysql-slave/mysqld.sock -pchange_me'

    context 'creates config' do
      describe file('/etc/mysql-slave/conf.d/slave.cnf') do
        it { should be_file }
        it { should be_owned_by 'mysql' }
        it { should be_mode 640 }
        its(:content) { should match(/replicate-ignore-db = mysql/) }
        its(:content) { should match(/server-id = 123/) }
      end
    end

    context 'configures master' do
      describe command("echo 'show slave status\\G' | #{sql_command}") do
        its(:stdout) { should match %r{Slave_IO_Running: Yes} }
        its(:stdout) { should match %r{Slave_SQL_Running: Yes} }
        its(:stdout) { should match %r{Master_Host: 127.0.0.1} }
        its(:stdout) { should match %r{Replicate_Ignore_DB: mysql} }
      end
    end

    context 'Dump file' do
      describe file('/tmp/kitchen/cache/slave-dump.sql') do
        it { should_not exist }
      end
    end
  end
end
