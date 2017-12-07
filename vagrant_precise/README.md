# Vagrant Setup

To run an instance of both Get-IT and 52N's SOS app on a localhost, the following Vagrant files can be used.  The VM details are set in `Vagrantfile`, while the provisioning of the VM is carried out by `bootstrap.sh`.  The host port used to map to the VM's port 80 is arbitrary, however the VM's port 8080 must be mapped to the host's port 8080 - this is due to Get-IT's assumption that the SOS will be found at :8080/observations.

The VM can be created by executing in this folder

`vagrant up`

Once the VM has been provisioned, you must enter the VM and execute a set of commands:

`vagrant ssh`

`sk collectstatic` - (you will be prompted to enter 'yes')

`sudo reboot now`

When the VM comes back up you will now have to navigate in your browser to:

`127.0.0.1:8080/observations`

Once there you must finish the 52N SOS setup tasks.  Once this is done, navigating to the localhost address of the port mapped to the VM's port 80, the Get-IT site is available to use.