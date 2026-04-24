# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|

  config.vm.boot_timeout = 1800
  config.vm.synced_folder ".", "/vagrant", disabled: true

  config.vm.box_check_update = true

  # config.vm.post_up_message = ""
  config.vm.boot_timeout = 1800
  # config.vm.box_download_checksum = true
  config.vm.boot_timeout = 1800
  # config.vm.box_download_checksum_type = "sha256"

  # config.vm.provision "shell", run: "always", inline: <<-SHELL
  # SHELL

  # Adding a second CPU and increasing the RAM to 2048MB will speed
  # things up considerably should you decide to do anything with this box.
  config.vm.provider :hyperv do |v, override|
    v.maxmemory = 2048
    v.memory = 2048
    v.cpus = 2
  end

  ["vmware_fusion", "vmware_workstation", "vmware_desktop"].each do |provider|
    config.vm.provider provider do |v, override|
      v.whitelist_verified = true
      v.gui = false
      v.vmx["cpuid.coresPerSocket"] = "1"
      v.vmx["memsize"] = "2048"
      v.vmx["numvcpus"] = "2"
    end
  end

end
