require 'chef/knife'

module Knife
  class MysqlScp < Chef::Knife

    deps do
      require 'etc'
      require 'net/ssh'
      require 'net/scp'
      require 'ruby-progressbar'
      require 'securerandom'
      require 'fileutils'
      require 'chef/search/query'
    end

    banner 'knife mysql scp SOURCE DESTINATION (options)'

    option :databases,
      :short => "-B database_1,database_2",
      :long => "--databases database_1,database_2",
      :description => "SCP several databases",
      :proc => Proc.new { |names| names.split(',') },
      :default => false

    option :all_databases,
      :short => '-A',
      :long => '--all-databases',
      :description => 'SCP all databases',
      :boolean => true,
      :default => true

    option :ssh_user,
      :short => '-x USERNAME',
      :long => '--ssh-user USERNAME',
      :description => 'The ssh username',
      :default => Etc.getlogin

    option :user,
      :short => '-u USERNAME',
      :long => '--user USERNAME',
      :description => 'The MySQL username',
      :default => 'root'

    def run
      ensure_required_args
      source_query = Chef::Search::Query.new
      source_query.search 'node', name_args[0] do |source_node|
        dumpfile = mysqldump source_node, config
        download source_node, dumpfile

        destination_query = Chef::Search::Query.new
        destination_query.search 'node', name_args[1] do |destination_node|
          puts destination_node
          upload destination_node, dumpfile
          mysqlrestore destination_node, dumpfile, config
          delete_remote destination_node, dumpfile
        end

        delete dumpfile
      end
    end

    private
    def ensure_required_args
      unless name_args.size == 2
        puts 'Both a source query and a destination query are required.'
        show_usage
        exit 1
      end
    end

    private
    def mysqldump(node, config)
      Net::SSH.start node.fqdn, config[:ssh_user] do |ssh|
        source_password = ui.ask_question "[#{node.name}] MySQL password (#{config[:user]}): "
        dumpfile = "knife-mysql-scp-#{SecureRandom.uuid}.sql"
        command = "mysqldump --single-transaction -u #{config[:user]} -p#{source_password} #{databases_to_arg(config)} > #{dumpfile}"
        ssh.open_channel do |channel|
          ui.info "[#{node.name}] Running #{command}"
          channel.exec command do |ch, success|
            unless success
              ui.error "[#{node.name}] [mysqldump] An error occurred."
              abort
            end

            channel.on_request 'exit-status' do |ch, data|
              ui.info "[#{node.name}] [mysqldump] Finished!"
            end
          end
        end
        ssh.loop
        return dumpfile
      end
    end

    private
    def mysqlrestore(node, dumpfile, config)
      Net::SSH.start node.fqdn, config[:ssh_user] do |ssh|
        source_password = ui.ask_question "MySQL password (#{config[:user]})"
        command = "mysql -u #{config[:user]} -p#{source_password} < #{dumpfile}"
        ssh.open_channel do |channel|
          ui.info "[#{node.name}] Running #{command}"
          channel.exec command do |ch, success|
            unless success
              ui.error "[#{node.name}] [mysql] An error occurred."
              abort
            end

            channel.on_request 'exit-status' do |ch, data|
              ui.info "[#{node.name}] [mysql] Finished!"
            end
          end
        end
        ssh.loop
      end
    end

    private
    def download(node, filename)
      Net::SCP.start node.fqdn, config[:ssh_user] do |scp|
        ui.info "[#{node.name}] [scp] Downloading #{filename}..."
        progress = ProgressBar.create :title => filename, :format => '%a %B %p%% %t'
        scp.download! filename, filename do |ch, name, sent, total|
          progress.total = total
          progress.progress = sent
        end
        progress.finish
        ui.info "[#{node.name}] [scp] Finished!"
      end
    end

    def upload(node, filename)
      Net::SCP.start node.fqdn, config[:ssh_user] do |scp|
        ui.info "[#{node.name}] [scp] Uploading #{filename}..."
        progress = ProgressBar.create :title => filename, :format => '%a %B %p%% %t'
        scp.upload! filename, filename do |ch, name, sent, total|
          progress.total = total
          progress.progress = sent
        end
        progress.finish
        ui.info "[#{node.name}] [scp] Finished!"
      end
    end

    def delete(filename)
      ui.info "Deleting #{filename}..."
      FileUtils.rm(filename)
      ui.info "Finished!"
    end

    def delete_remote(node, filename)
      Net::SSH.start node.fqdn, config[:ssh_user] do |ssh|
        ui.info "[#{node.name}] Deleting #{filename}..."
        command = "rm #{filename}"
        ssh.open_channel do |channel|
          channel.exec command do |ch, success|
            unless success
              ui.info "[#{node.name}] Failed to delete #{filename}!"
              abort
            end

            channel.on_request 'exit-status' do |ch, data|
              ui.info "[#{node.name}] Finished!"
            end
          end
        end
        ssh.loop
      end
    end

    private
    def databases_to_arg(config)
      databases = config[:databases] || []
      if config[:all_databases]
        '--all-databases'
      else
        "--databases #{databases.join(' ')}"
      end
    end

  end
end
