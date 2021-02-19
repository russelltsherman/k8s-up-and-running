# One Vagrantfile to rule them all!
#
# This is a generic Vagrantfile that can be used without modification in
# a variety of situations. Hosts and their properties are specified in
# `vagrant-hosts.yml`. Provisioning is done by an Ansible playbook,
# `ansible/site.yml`.
#
# See https://github.com/bertvv/ansible-skeleton/ for details

require 'rbconfig'
require 'securerandom'
require 'yaml'

# set default LC_ALL for all BOXES
ENV["LC_ALL"] = "en_US.UTF-8"

# Set your default base box here
# DEFAULT_BASE_BOX = 'ubuntu/bionic64'
DEFAULT_BASE_BOX = "bento/ubuntu-18.04"
DOMAIN = "k8s.local"

# When set to `true`, Ansible will be forced to be run locally on the VM
# instead of from the host machine (provided Ansible is installed).
FORCE_LOCAL_RUN = false

#
# No changes needed below this point
#
ENV['VAGRANT_NO_PARALLEL'] = 'yes'

VAGRANTFILE_API_VERSION = '2'
PROJECT_NAME = '/' + File.basename(Dir.getwd)

# set custom vagrant-hosts file
vagrant_hosts = './vagrant/hosts.yml'
HOSTS = YAML.load_file(File.join(__dir__, vagrant_hosts))

ALL_HOSTS = ""
CTRL_HOSTS = ""
ETCD_HOSTS = ""
LB_HOSTS = ""
WORK_HOSTS = ""
LB_IP = ""

HOSTS.each do |h|
  if h['networks'] 
    h['networks'].each do |n|
      if n['type'] === 'private_network'
        ALL_HOSTS += " #{h['name']}:#{n['attributes']['ip']}"

        if h['group'] === 'loadbalancers'
          LB_HOSTS += " #{h['name']}:#{n['attributes']['ip']}"
          LB_IP = "#{n['attributes']['ip']}"
        end

        if h['group'] === 'controllers'
          ETCD_HOSTS += " #{h['name']}:#{n['attributes']['ip']}"
          CTRL_HOSTS += " #{h['name']}:#{n['attributes']['ip']}"
        end

        if h['group'] === 'workers'
          WORK_HOSTS += " #{h['name']}:#{n['attributes']['ip']}"
        end
      end
    end
  end
end

vagrant_groups = './vagrant/groups.yml'
GROUPS = YAML.load_file(File.join(__dir__, vagrant_groups))

# generate random hash for root password
# outputs: 5b5cd0da3121fc53b4bc84d0c8af2e81 (i.e. 32 chars of 0..9, a..f)
# ROOTPASSWORD = SecureRandom.hex # random is good but sacrifices idempotency
ROOTPASSWORD = "qm)MNTDZjoXqGQUcsxqzT4MQM2N8ALq6"

CLUSTER_NAME = "k8s-the-hard-way"
CFG_DIR = "/etc/kubernetes"
PKI_DIR = "/etc/kubernetes/pki"

# {{{ Helper functions

def run_locally?
  windows_host? || FORCE_LOCAL_RUN
end

def windows_host?
  Vagrant::Util::Platform.windows?
end

# Set options for the network interface configuration. All values are
# optional, and can include:
# - ip (default = DHCP)
# - netmask (default value = 255.255.255.0
# - mac
# - auto_config (if false, Vagrant will not configure this network interface
# - intnet (if true, an internal network adapter will be created instead of a
#   host-only adapter)
def network_options(network)
  options = {}

  if network.has_key?('ip')
    options[:ip] = network['ip']
    options[:netmask] = network['netmask'] ||= '255.255.255.0'
  else
    options[:type] = 'dhcp'
  end

  options[:mac] = network['mac'].gsub(/[-:]/, '') if network.has_key?('mac')
  options[:auto_config] = honetworkst['auto_config'] if network.has_key?('auto_config')
  options[:virtualbox__intnet] = true if network.has_key?('intnet') && network['intnet']
  options
end

def custom_synced_folders(vm, host)
  return unless host.has_key?('synced_folders')
  folders = host['synced_folders']

  folders.each do |folder|
    vm.synced_folder folder['src'], folder['dest'], folder['options']
  end
end

# }}}

# Set options for shell provisioners to be run always. If you choose to include
# it you have to add a cmd variable with the command as data.
#
# Use case: start symfony dev-server
#
# example:
# shell_always:
#   - cmd: php /srv/google-dev/bin/console server:start 192.168.52.25:8080 --force
def shell_provisioners_always(vm, host)
  if host.has_key?('shell_always')
    scripts = host['shell_always']

    scripts.each do |script|
      vm.provision "shell", inline: script['cmd'], run: "always"
    end
  end
end

# }}}

# Adds forwarded ports to your Vagrant machine
#
# example:
#  forwarded_ports:
#    - guest: 88
#      host: 8080
def forwarded_ports(vm, host)
  if host.has_key?('forwarded_ports')
    ports = host['forwarded_ports']

    ports.each do |port|
      vm.network "forwarded_port", guest: port['guest'], host: port['host']
    end
  end
end

# }}}

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.provision :shell, path: "./vagrant/role/common/dirs.sh", 
  env:  { CFG_DIR: CFG_DIR, PKI_DIR: PKI_DIR } 
  config.vm.provision :shell, path: "./vagrant/role/common/hosts.sh", 
    env:  { DOMAIN: DOMAIN, ALL_HOSTS: ALL_HOSTS }
  config.vm.provision :shell, path: "./vagrant/role/common/resolved_configure.sh"
  config.vm.provision :shell, path: "./vagrant/role/common/root_user.sh", 
    env:  { ROOTPASSWORD: ROOTPASSWORD}
  config.vm.provision :shell, path: "./vagrant/role/common/swap_disable.sh"
  config.vm.provision :shell, path: "./vagrant/role/common/vagrant_user.sh"

  HOSTS.each do |host|
    config.vm.define host['name'] do |node|
      node.vm.box = host['box'] ||= DEFAULT_BASE_BOX
      node.vm.box_url = host['box_url'] if host.has_key? 'box_url'

      node.vm.hostname = host['name']
      node.vm.provider :virtualbox do |vb|
        vb.memory = host['memory'] ||= 2048
        vb.cpus = host['cpus'] ||= 2
        # WARNING: this fails if host name matches directory name
        vb.customize ['modifyvm', :id, '--groups', PROJECT_NAME]
      end

      if host.has_key?('networks')
        host['networks'].each do |network|
          node.vm.network network['type'], network_options(network['attributes'])
        end
      end

      # copy local ssh public key to the node
      node.vm.provision "shell" do |s|
        ssh_pub_key = File.readlines("#{Dir.home}/.ssh/id_rsa.pub").first.strip
        s.inline = <<-SHELL
          mkdir -p /home/vagrant/.ssh/
          echo #{ssh_pub_key} >> /home/vagrant/.ssh/authorized_keys
          mkdir -p /root/.ssh/
          echo #{ssh_pub_key} >> /root/.ssh/authorized_keys
        SHELL
      end
      
      # synced folders as defined in hosts.yml
      custom_synced_folders(node.vm, host)

      # run provisioning as defined in hosts.yml
      shell_provisioners_always(node.vm, host)

      # assign port forwarding as defined in hosts.yml
      forwarded_ports(node.vm, host)

      if host['group'] === 'ca'
        node.vm.provision :shell, path: "./vagrant/role/ca/certs.sh", env: { 
          CTRL_HOSTS: CTRL_HOSTS,
          ETCD_HOSTS: ETCD_HOSTS,
          LB_HOSTS: LB_HOSTS,
          WORK_HOSTS: WORK_HOSTS,
          PKI_DIR: PKI_DIR,
          BITSIZE: "2048",
          DAYS: "1000"
        }
      end

      if host['group'] === 'loadbalancers'
        node.vm.provision :shell, path: "./vagrant/role/lb/install.sh"
        node.vm.provision :shell, path: "./vagrant/role/lb/configure.sh", env: { 
          CTRL_HOSTS: CTRL_HOSTS, LB_HOSTS: LB_HOSTS,
        }
        node.vm.provision :shell, path: "./vagrant/role/lb/systemd.sh"
      end

      if host['group'] === 'controllers'
        node.vm.provision :shell, path: "./vagrant/role/controller/install.sh"
        node.vm.provision :shell, path: "./vagrant/role/controller/certs_copy.sh", env: { 
          PKI_DIR: PKI_DIR,
          ROOTPASSWORD: ROOTPASSWORD
        }

        if host['name'] === 'k8s-m1' # primary controller
          node.vm.provision :shell, path: "./vagrant/role/controller/encryption_config.sh", env: { 
            CFG_DIR: CFG_DIR
          }  
          node.vm.provision :shell, path: "./vagrant/role/controller/kubeconfig.sh", env: { 
            CFG_DIR: CFG_DIR, 
            CLUSTER_NAME: CLUSTER_NAME,
            LB_IP: LB_IP,
            WORK_HOSTS: WORK_HOSTS
          }
        else # backup controller
          # copy encryption_config and kubeconfig from primary controller
          node.vm.provision :shell, path: "./vagrant/role/controller/config_copy.sh", env: { 
            CFG_DIR: CFG_DIR,
            ROOTPASSWORD: ROOTPASSWORD
          }  
        end

        node.vm.provision :shell, path: "./vagrant/role/controller/systemd.sh", env: { 
          CFG_DIR: CFG_DIR, 
          ETCD_HOSTS: ETCD_HOSTS,
          PKI_DIR: PKI_DIR
        }  
        node.vm.provision :shell, path: "./vagrant/role/controller/certs_verify.sh", env: { 
          CFG_DIR: CFG_DIR, 
          LB_IP: LB_IP,
          PKI_DIR: PKI_DIR
        }
        # node.vm.provision :shell, path: "./vagrant/role/controller/systemd_after.sh", env: { 
        #   CFG_DIR: CFG_DIR
        # }
      end
  
      if host['group'] === 'workers'
        node.vm.provision :shell, path: "./vagrant/role/worker/certs_copy.sh", env: { 
          CFG_DIR: CFG_DIR, 
          PKI_DIR: PKI_DIR,
          ROOTPASSWORD: ROOTPASSWORD  
        }
        node.vm.provision :shell, path: "./vagrant/role/worker/install.sh"
        node.vm.provision :shell, path: "./vagrant/role/worker/configure.sh", env: { 
          CFG_DIR: CFG_DIR
        }
        node.vm.provision :shell, path: "./vagrant/role/worker/systemd.sh", env: { 
          CFG_DIR: CFG_DIR, 
          PKI_DIR: PKI_DIR
        }  
        node.vm.provision :shell, path: "./vagrant/role/controller/certs_verify.sh", env: { 
          CFG_DIR: CFG_DIR, 
          LB_IP: LB_IP,
          PKI_DIR: PKI_DIR
        }
      end
  
      # run provision scripts defined in hosts.yml
      if host.has_key?('provision')
        host['provision'].each do |p|
          if p['inline']
            node.vm.provision :shell, inline: eval(p['inline'])
          elsif p['path']
            node.vm.provision :shell, path: p['path'], env: { 
              CTRL_HOSTS: CTRL_HOSTS,
              ETCD_HOSTS: ETCD_HOSTS,
              LB_HOSTS: LB_HOSTS,
              WORK_HOSTS: WORK_HOSTS,
              ROOTPASSWORD: ROOTPASSWORD  
            }
          end
        end
      end

      # Ansible provision
      if host.has_key?('playbook')
        ansible_mode = run_locally? ? 'ansible_local' : 'ansible'
        node.vm.provision ansible_mode do |ansible|
          ansible.compatibility_mode = '2.0'
          if ! GROUPS.nil?
            ansible.groups = GROUPS
          end
          ansible.playbook = host.has_key?('playbook') ?
              "ansible/#{host['playbook']}" :
              "ansible/site.yml"
          ansible.become = true
        end
      end
    end
  end
end

# -*- mode: ruby -*-
# vi: ft=ruby :
