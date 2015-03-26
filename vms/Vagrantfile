# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"

# Grab local IP address for the proxy
def local_ip
  @local_ip ||= begin
    orig, Socket.do_not_reverse_lookup = Socket.do_not_reverse_lookup, true

    UDPSocket.open do |s|
      s.connect "64.233.187.99", 1
      s.addr.last
    end
  ensure
    Socket.do_not_reverse_lookup = orig
  end
end

Vagrant.configure(VAGRANTFILE_API_VERSION) do |cluster|
  cluster.vm.box = "chef/centos-6.5"

  cluster.ssh.forward_agent = true

  cluster.vm.provider "virtualbox" do |v|
    v.memory = 4086
    v.cpus = 4
  end

  # Wire up the proxy
  if Vagrant.has_plugin?("vagrant-proxyconf")
    begin
      TCPSocket.open('localhost', 8123) do |s|
        s.select()
      end
    rescue Exception=> e
       abort("proxy enabled, and expected by VM, but not running")
    end
    begin
        cluster.proxy.http     = "http://#{local_ip}:8123/"
        cluster.proxy.https    = "http://#{local_ip}:8123/"
        cluster.proxy.no_proxy = "localhost,127.0.0.1"
     rescue Exception=> e
       print("could not determine local ip for proxy")
    end
  end

  index = 1
  cluster.vm.define "riak-0#{index}" do |machine|
    machine.vm.hostname = "riak-0#{index}"
    machine.vm.network "private_network", ip: "10.42.0.21"

    puts machine.vm.hostname + ": Forwarding ports to local host" 
    machine.vm.network "forwarded_port", guest: 8087, host: 18087 
    machine.vm.network "forwarded_port", guest: 8098, host: 18098 

    machine.vm.provision "ansible" do |ansible|
        ansible.playbook = "./provision.yml"
        #ansible.playbook = "./copy-local-ansible.yml"
        ansible.inventory_path = "./hosts"
        ansible.raw_arguments = [ "--timeout=120" ]
        ansible.extra_vars = {
            riak_iface: "eth1",
        }

        ansible.verbose = "vvvv"
        ansible.limit = "all"
    end
  end
end
