# Use the standard Ubuntu 22.04 LTS base
FROM ubuntu:22.04

# Prevent interactive prompts during apt installations
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Amsterdam
ENV PATH=$PATH:/usr/local/go/bin:/root/bin

# 1. Install core system utilities, Python, and Libvirt
RUN apt-get update -yqq && apt-get install -yqq --no-install-recommends \
    curl wget jq unzip git openssh-client gnupg software-properties-common \
    python3 python3-pip python3-venv \
    libvirt-clients virtinst qemu-utils \
    apt-transport-https lsb-release \
    && rm -rf /var/lib/apt/lists/*

# 2. Add External Repositories (HashiCorp, Tailscale, Azure)
RUN mkdir -p --mode=0755 /usr/share/keyrings \
    # HashiCorp (Terraform & Vault)
    && curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list \
    # Tailscale
    && curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/jammy.noarmor.gpg | tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null \
    && echo "deb [signed-by=/usr/share/keyrings/tailscale-archive-keyring.gpg] https://pkgs.tailscale.com/stable/ubuntu jammy main" | tee /etc/apt/sources.list.d/tailscale.list \
    # Azure CLI
    && curl -sLS https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /usr/share/keyrings/microsoft.gpg \
    && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/azure-cli.list

# 3. Install Cloud CLIs, Vault, Terraform, and Tailscale via APT
RUN apt-get update -yqq && apt-get install -yqq --no-install-recommends \
    terraform=1.16.0-* vault tailscale azure-cli \
    && rm -rf /var/lib/apt/lists/*

# 4. Install AWS CLI v2 (Standalone binary to prevent Python conflicts)
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip -q awscliv2.zip \
    && ./aws/install \
    && rm -rf awscliv2.zip ./aws    

# 5. Install Ansible and OCI CLI via Python PIP (Cleanest method for OCI)
RUN pip3 install --no-cache-dir --upgrade pip \
    && pip3 install --no-cache-dir ansible oci-cli

# 6. Install Go (Golang) for health-ingester compilation
RUN curl -fsSL https://go.dev/dl/go1.22.1.linux-amd64.tar.gz -o go.tar.gz \
    && tar -C /usr/local -xzf go.tar.gz \
    && rm go.tar.gz

# 7. Set working directory
WORKDIR /workspace

# Default command keeps the container alive if run interactively
CMD ["/bin/bash"]