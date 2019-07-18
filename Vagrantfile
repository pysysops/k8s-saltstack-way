# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'yaml'

NODES = YAML.load_file('vagrant_nodes.yaml')['nodes']
VAGRANTFILE_API_VERSION = '2'

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = 'ubuntu/bionic64'

  NODES.each do |node|
    node_name = node[0]
    node_config = node[1]

    config.vm.define node_name do |this_config|
      # Configure port forward to access things on localhost:<<port>>
      ports = node_config['ports']
      unless ports.nil?
        ports.each do |port|
          this_config.vm.network :forwarded_port,
            host:  port['host'],
            guest: port['guest'],
            id:    port['id']
        end
      end

      this_config.vm.hostname = node_name
      this_config.vm.network :private_network, ip: node_config['ip']
      this_config.vm.synced_folder 'saltstack', '/opt/saltstack'

      this_config.vm.provider :virtualbox do |vb|
        vb.customize ['modifyvm', :id, '--memory', node_config['memory']]
        vb.customize ['modifyvm', :id, '--name', node_name]

        # Manage extra HDD (simulate Block Storage volume)
        unless node_config['storage'].nil?
          # Create a HDD file if one doesn't exist
          unless File.exist?(".vagrant/#{node_name}.vdi")
            vb.customize ['createhd', '--filename', ".vagrant/#{node_name}.vdi",
              '--size', (node_config['disk'] || 1) * 1024]
          end
          # Attach the HDD file
          vb.customize ['storageattach', :id, '--storagectl', 'IDE Controller',
            '--port', 1, '--device', 0, '--type', 'hdd',
            '--medium', ".vagrant/#{node_name}.vdi"]
        end
      end

      # Pre-requisites (set minion_id, mount block starage if exists)
      this_config.vm.provision :shell do |sh|
        sh.inline = <<-EOF
          mkdir -p /etc/salt && echo #{node_name} > /etc/salt/minion_id

          # Handle storage
          if [ -b "/dev/sdb" ]
          then
            if [ ! -b "/dev/sdb1" ]
            then
              mkdir /dev/disk/by-label
              parted /dev/sdb mklabel msdos
              parted /dev/sdb mkpart primary 512 100%
              partprobe
              mkfs.xfs /dev/sdb1
              ln -s /dev/sdb1 /dev/disk/by-label/data
            else
              mkdir -p /dev/disk/by-label || true
              ln -s /dev/sdb1 /dev/disk/by-label/data || true
            fi
          fi
        EOF
      end

      # Bootstrap / Provision VM using SaltStack
      this_config.vm.provision :salt do |salt|
        salt.masterless = true
        salt.minion_id = node_name
        salt.minion_config = "saltstack/minion"
        salt.run_highstate = true
        salt.verbose = true
        salt.log_level = "warning"
        salt.colorize = true
        salt.salt_call_args = ["--output-diff", "pillar='{local: True}'"]
      end
    end
  end
end
