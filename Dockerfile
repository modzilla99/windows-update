FROM quay.io/ansible/awx-ee:0.6.0
RUN ansible-galaxy collection install community.general:==4.2.0 ansible.windows:==1.9.0 community.vmware:==2.0.0
