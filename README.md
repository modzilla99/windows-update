# Ansible Windows Patchmanagement

This playbook aims to provide a Patchmanagment workflow for Windows machines on a vSphere Cluster. It works by creating a Snapshot first and when it's done with patching, it will send a E-Mail or Teams-Message and revert to the snapshot if patching failed and `update_autorollback` is turned on.

## Prerequesites

### Windows

On the Windows machines you need to have either winrm or ssh enabled and be accessible from the Ansible node. The quickest way to do that would be using `winrm quickconfig`, but when you have an ActiveDirectory I strongly recommend you to create a policy that will do that automatically on any machine.

### vSphere

In order for this playbook to work, you need a user with access to the vSphere API that is able to see all virtual machines and create, delete or revert snapshots.

This can be achieved by creating a custom role that is restricted to the aforementioned permissions. This user + role then needs to either be mapped globally or on a Datacenter-level with inheritance enabled.

![Ansible vSphere Role](https://raw.githubusercontent.com/modzilla99/windows-update/main/img/vsphere_role.png)

![Ansible vSphere global RoleMapping](https://raw.githubusercontent.com/modzilla99/windows-update/main/img/vsphere_permission_map.png)

In addition to that Ansible will build a dynamic inventory based on vSphere Tags. So make sure to create to category called `ansible` with the tag `windows.patchmgmt=true`.

![Ansible vSphere Tags](https://raw.githubusercontent.com/modzilla99/windows-update/main/img/vsphere_tags.png)

### Ansible

All changes have to be made to the `group_vars/all/override.yml` and `inventory.vmware.yml` files. Copy the sample inventory to `inventory.vmware.yml` and make the necessary changes to it. You can create the ansible-vault encoded string as follows:

```bash
$ export HISTFILE=/dev/null # disables bash history for this session
$ echo "myvaultpassword" > password_file.txt
$ ansible-vault encrypt_string --name "password" 'myvspherepassword' --vault-password-file password_file.txt
password: !vault |
          $ANSIBLE_VAULT;1.1;AES256
          33613738666638376663653237643037373162353531323463636234633636373035376562613331
          3836366466626334643933633332363562343365306637320a363234633264343530393036393530
          66623063326232313337353737366639653730373864346565653639363830326537316432343532
          6663393235633565340a643934623637323766376439323334626535343035336435363130323465
          64323730363364316161393136383632646561653239626532653963633961383035
Encryption successful
```

At least the `vcenter` and `ansible` variables have to be changed in the `group_vars/all/override.yml` file to same credentials in the `inventory.vmware.yml`. Changes made to `override.yml` will overwrite the defaults found in `group_vars/all/main.yml`.

```yaml
# group_vars/all/override.yml
---
# Credentials for taking Snapshots
vcenter_username: svac-ansible@vsphere.local
vcenter_datacenter: VSPHERE
vcenter_hostname: vsphere.local
vcenter_password: !vault |
          $ANSIBLE_VAULT;1.1;AES256
          33613738666638376663653237643037373162353531323463636234633636373035376562613331
          3836366466626334643933633332363562343365306637320a363234633264343530393036393530
          66623063326232313337353737366639653730373864346565653639363830326537316432343532
          6663393235633565340a643934623637323766376439323334626535343035336435363130323465
          64323730363364316161393136383632646561653239626532653963633961383035

# Username and password to connect to nodes
ansible_user: svac-ansible
ansible_password: !vault |
          $ANSIBLE_VAULT;1.1;AES256
          33613738666638376663653237643037373162353531323463636234633636373035376562613331
          3836366466626334643933633332363562343365306637320a363234633264343530393036393530
          66623063326232313337353737366639653730373864346565653639363830326537316432343532
          6663393235633565340a643934623637323766376439323334626535343035336435363130323465
          64323730363364316161393136383632646561653239626532653963633961383035
```

The username and password can be overwritten on a host basis in the `host_vars` folder. Take a look into the [ansible docs](https://docs.ansible.com/ansible/latest/user_guide/playbooks_variables.html#understanding-variable-precedence) for more info. Alternatively you can create another tag in vSphere and use overwrite the variable with `group_vars`. If you for example add a tag called `ansible.user=locl-adm` the hosts with this tag attached will automatically end up in the group `vm_tag_ansible_user_locl_adm`. Create a folder in `group_vars` with that name and set the required variables in there.

## Execution

To check whether the dynamic inventory plugin works as intended, issue the `ansible-inventory` command:

```
ansible-inventory -i inventory.vmware.yml --vault-password-file password_file.txt --list 
```


Now run this playbook like any other with the following command:

```
ansible-playbook -i inventory.vmware.yml --vault-password-file password_file.txt main.yml [--limit somehost,another_group_based_on_tags]
```