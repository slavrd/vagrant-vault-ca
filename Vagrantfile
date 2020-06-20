Vagrant.configure("2") do |config|
    config.vm.box = "slavrd/vault"
    config.vm.hostname = "vault"

    config.vm.provider "virtualbox" do |v|
        v.memory = 1024
        v.cpus = 2
    end

    config.vm.provision "shell", inline: "/etc/vault.d/scripts/vault_init.sh"
    config.vm.provision "shell", inline: "/etc/vault.d/scripts/vault_unseal.sh", run: "always"
    config.vm.provision "shell", path: "scripts/provision.sh", privileged: false
    config.vm.provision "shell", path: "scripts/setup_vault_pki.sh", privileged: false
end
