# -*- mode: ruby -*-
# vi: set ft=ruby :

GROUPS = {
  'database-servers' => {
    'mysql' => { 'ip' => '10.10.10.2', 'memory' => 768 }
  },
  'backend-servers' => {
    'backend1' => { 'ip' => '10.10.10.3'},
    'backend2' => { 'ip' => '10.10.10.4'}
  },
  'frontend-servers' => {
    'frontend' => { 'ip' => '10.10.10.5', 'forwarded_port' => [80, 8080] } # [guest_port, host_port]
  }
}
# How much memory in MB should be used for each box by default
BOX_MEMORY_DEFAULT = 512

begin
  require 'serverspec'
rescue LoadError
  warn "NOTE: Acceptance tests disabled. Run " \
      "`vagrant plugin install vagrant-serverspec' to enable."
end

Vagrant.configure 2 do |configuration|
  GROUPS.each do |group, servers|
    servers.each do |server, options|
      configuration.vm.define server do |box|
        box.vm.hostname = server.gsub '_', '-'
        # box.vm.network "private_network", type: "dhcp"
        if options['forwarded_port']
          box.vm.network "forwarded_port",
              guest: options['forwarded_port'].first,
              host: options['forwarded_port'].last
        end
        box.vm.network "private_network", ip: options['ip']
        box.vm.provision :hosts do |provisioner|
          provisioner.autoconfigure = true
          provisioner.sync_hosts = true
        end
        # Create /app symlink and install puppet
        box.vm.provision :shell, inline: "
          set -ex
          if ! test -s /app; then
            ln -sf /vagrant /app;
          fi
          if ! type puppet > /dev/null 2>&1; then
            cd /tmp
            wget --quiet --continue https://apt.puppetlabs.com/puppet6-release-xenial.deb
            dpkg -i puppet6-release-xenial.deb
            apt-get -qq update
            apt-get -qqy install puppet-agent
          fi
        "
        box.vm.provider "virtualbox" do |virtualbox, override|
          virtualbox.linked_clone = true
          # Customize the amount of memory on the VM:
          virtualbox.memory = BOX_MEMORY_DEFAULT
          override.vm.box = 'ubuntu/xenial64' # Ubuntu 16.04 LTS
          override.vm.box_check_update = false # too slow
        end

        box.vm.provision :puppet, run: :always do |puppet|
          # puppet.options = "--verbose"
          puppet.manifests_path = 'puppet/manifests'
          puppet.module_path = 'puppet/modules'
        end

        # This section only runs if serverspec plugin is installed
        begin
          require 'serverspec'
          box.vm.provision :serverspec, run: :always do |spec|
            spec.pattern = ["spec/common/*_spec.rb", "spec/#{group}/*_spec.rb"]
          end
        rescue LoadError
        end
      end
    end
  end
end
