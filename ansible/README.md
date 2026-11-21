# `ansible/` — Jenkins server configuration

> Turns the freshly created Jenkins EC2 into a working CI server: Java 21, Jenkins, Docker, Git,
> AWS CLI and Trivy — installed declaratively through roles, with the target discovered dynamically
> from AWS.

## Contents

| File | Purpose |
|------|---------|
| `ansible.cfg` | Inventory file, remote user `ubuntu`, private key `/home/3bdel/ivolve-key.pem`, host-key checking disabled |
| `aws_ec2.yml` | Dynamic inventory plugin `amazon.aws.aws_ec2`: region `us-east-1`, filters `tag:Name=jenkins-server` and `instance-state-name=running`, hostname = public IP |
| `playbook.yml` | Single play `hosts: all`, `become: true`, roles in order: `java` → `jenkins` → `tools` |
| [roles/](roles/README.md) | [java](roles/java/README.md) · [jenkins](roles/jenkins/README.md) · [tools](roles/tools/README.md) |

## How discovery works

```
AWS EC2 API ──(tag Name=jenkins-server, running)──> aws_ec2.yml ──> ansible-inventory --graph
                                                        │
                                                        └──> playbook.yml (hosts: all)
```

The `jenkins-server` tag is set by the [Terraform server module](../terraform/modules/server/README.md).
Every destroy/apply cycle gives the server a new public IP — the dynamic inventory always finds the
current one, so no hard-coded host address is needed.

## Usage

```bash
# 1. set private_key_file in ansible.cfg to your .pem path
# 2. make sure boto3 and the amazon.aws collection are installed:
#    pip install boto3
#    ansible-galaxy collection install amazon.aws

cd ansible
ansible-inventory --graph
ansible-playbook playbook.yml
```

A successful run ends with `unreachable=0  failed=0` in the `PLAY RECAP`.

Afterwards:

```bash
ssh -i ~/ivolve-key.pem ubuntu@<JENKINS_PUBLIC_IP> \
  "sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
```

Open `http://<JENKINS_PUBLIC_IP>:8080` and continue with the
[Jenkins web-UI setup](../README.md#step-7--configure-jenkins-in-the-web-ui).

## Related

- [Root README](../README.md)
- [Terraform server module](../terraform/modules/server/README.md)
- [Jenkins pipelines](../jenkins/README.md)
