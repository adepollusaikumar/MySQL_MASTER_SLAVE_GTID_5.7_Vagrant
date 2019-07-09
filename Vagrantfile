Vagrant.configure("2") do |config|
       config.vm.box = "bento/centos-7"
       config.ssh.insert_key = false
       config.vm.provision :hostmanager
       config.vm.synced_folder ".", "/vagrant", type: "virtualbox"
       config.vm.provider "virtualbox" do |vb|
     vb.customize ["modifyvm", :id, "--memory", "512"]
  end

  (  ["master"] + ["slave"] ).each_with_index do |role, i|
    name = "%s"     % [role, i]
    addr = "10.0.5.%d" % (100 + i)
    config.vm.define name do |node|
      node.vm.hostname = name
      node.vm.network "private_network", ip: addr
      node.vm.provision "shell", path: "provision.sh", args: "#{name}"
    
    end
  end
end
