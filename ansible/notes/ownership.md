Ansible ownership
Your final Ansible responsibilities are:

Linux package installation
users and groups
SSH configuration
Vault SSH CA trust
Tailscale installation
Docker/container runtime installation
K3s server installation
K3s agent installation
K3s configuration
systemd services
host-level hardening
OS updates

Do not commit passwords or tokens inside group_vars or host_vars. Those files contain only ordinary configuration and Vault paths.


The log is still in the apt install phase. Let me jump to the end of the trace to find the actual error.


Found the root cause. There are two separate issues that will keep causing failures:
Issue 1: The job is still running on the old commit (checkout 747e584f)
The job log shows Checking out 747e584f — that's the commit before my fix. The -mount=kv fix was committed to main but this job ran against the old SHA. This is expected — the fix will take effect on the next pipeline run triggered after the commit.
Issue 2: terraform init will fail even with the token — wrong Terraform version
Look at versions.tf:



required_version = "~> 1.15.0"

But cloud.tf uses HCP Terraform (terraform { cloud { ... } }). The cloud block requires Terraform 1.1.0+. However, your CI installs terraform=1.15.8-* — Terraform 1.15.8 does not exist. The latest stable is 1.12.x. HashiCorp versioning jumped from 1.x to 2.x. This install will either fail or install the wrong version.
Let me verify what's actually available:


Now I have the full picture. Here are all the issues in one place:
Issue 1: Terraform version 1.15.8 doesn't exist
The CI installs terraform=1.15.8-* but Terraform's latest 1.x is 1.12.x. HashiCorp skipped to 2.x after that. The apt package terraform=1.15.8-* likely resolves to Terraform 2.x (rebranded), which conflicts with required_version = "~> 1.15.0" in versions.tf.
Issue 2: versions.tf requires ~> 1.15.0 but that version doesn't exist either
The lock file was generated with a real Terraform version. The required_version needs to match what's actually installed.
Issue 3: The -mount=kv fix hasn't taken effect yet
The job ran on commit 747e584f (before the fix). This will self-resolve on the next run.
Here's the fix — update both versions.tf and the CI to use a real, consistent Terraform version:

