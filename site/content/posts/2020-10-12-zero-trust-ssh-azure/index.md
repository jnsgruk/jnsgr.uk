---
title: Zero-Trust SSH on Microsoft Azure
summary: |
  (Repost) Building a zero-trust, serverless authentication system for SSH on Microsoft Azure, complete with custom ssh-agent and serverless certificate authority.
tags:
  - Azure
  - Go
  - Security
  - Serverless
  - SSH
  - Zero-Trust
layout: post
---

> This post was originally posted [on LinkedIn](https://www.linkedin.com/pulse/zero-trust-ssh-microsoft-azure-jon-seager/) on 12 October 2020. I've posted it to my blog retrospectively, but the article is unchanged. SSHizzle was released as open source software back in 2020, but has not received any maintenance since I left Thales. I do not recommend deploying SSHizzle, but the article will hopefully remain interesting for the background and principles behind the project.

## Introduction

Since its introduction, Secure Shell (ssh) has become the defacto solution for remotely managing Linux and Unix based systems, and has become only more prolific with the increasing popularity of the cloud. I can't think of a cloud provider that supplies access to Linux machines for whom SSH is not the default, and likely most active way for their customers to manage their resources. The same applies in large enterprise networks, with OpenSSH Server and Client packages even available in Windows 10 and Windows Server 2019 in more recent releases.

A key challenge with SSH is managing the authentication of trusted users at scale. OpenSSH supports three options by default, including password authentication, key authentication and certificate authentication. All of these methods pose varying challenges both to operations and security.

## Hello, SSHizzle

Today, I'm delighted to release [SSHizzle](https://github.com/thalesgroup/sshizzle) on behalf of Thales Secure Communications & Information Systems UK, a tool designed to illustrate the simplified management of SSH users and authentication both for administrators and users using commodity cloud resources. SSHizzle was inspired by the work of Jeremy Stott ([@stoggi](https://github.com/stoggi)) and the [sshrimp](https://github.com/stoggi/sshrimp) project which implements a similar solution for AWS.

SSHizzle strives to be as simple to configure, use and run as possible. It benefits from tight integration with Microsoft Azure Active Directory, Azure Key Vault and works seamlessly with almost all existing workflows. SShizzle simplifies the adoption and management of SSH Certificates.

In summary, SSHizzle aims to:

- Reduce the complexity of on-boarding new users into environments
- Provide a good user experience to engineers and developers
- Increase the observability of SSH credentials
- Eliminate the need to distribute many public keys in production
- Reduce the need to manage the lifecycle of SSH keys in production
- Be compatible with existing SSH-based workflows
- Require minimal configuration of hosts and servers

SSHizzle comprises of two key components:

- A serverless SSH Certificate Authority (CA)
- An SSH Agent for client machines

## SSHizzle's Serverless Certificate Authority

SSHizzle's SSH Certificate Authority (CA) stores its key in an Azure Key Vault and operates from a serverless function operated by Azure Functions. Azure Key Vault is a managed service provided by Microsoft that enables the secure storage and management of secrets, keys and certificates. In the case of SSHizzle, the Azure Key Vault stores the private key for the CA.

A serverless function is, generally, a programmatic function whose execution is triggered and run ephemerally on managed infrastructure. This means there is no dedicated server consistently running or listening for connections as with traditional server deployments. In the case of SSHizzle, the serverless function is triggered by an HTTP listener, which when called by an authenticated user triggers the Azure Functions backend to run the function on any available, suitable infrastructure. Once the function has run and returned, the context that executed the function (perhaps a container or a VM in the underlying implementation) is destroyed. This has numerous benefits including more granular billing (serverless functions are often billed by the minute for execution), but also a reduced attack surface as the authentication and frontend to the function are all controlled by Microsoft Azure.

SSHizzle's backend function can only be invoked by a user authenticated against its parent Azure Active Directory tenant. Once a user has authenticated, it takes a randomly generated SSH public key, signs it using the key stored in the Azure Key Vault, and returns an SSH certificate to the agent that invoked the function.

The SSH certificate has a number of key advantages over traditional SSH keys:

- **Expiry Time**: SSHizzle only issues credentials valid for 2 minutes, eliminating the need to manage the lifecycle of SSH user credentials.

- **Access Limitations**: SSHizzle will issue credentials that are only valid for use from the IP address that requested them. Should the credential be intercepted on the way back to the agent, it will be invalid for use unless the connection is from the original IP.

- **Forced Commands**: SSHizzle does not yet implement a UI to manage this feature but with minor modifications, SSH certificates can be issued that are only valid for specific command executions. This allows the issuance of single-purpose, scope limited credentials; essentially a light form of Privileged Access Management.

- **Feature Restriction**: SSH certificates have the ability to enable or disable certain SSH session functionality such as Agent Forwarding, Port Forwarding, X11 Forwarding etc.

- **Observable ID**: The ID of each certificate (which appears in auth logs and system logs) contains key information to track how and when each credential was issued - making forensic investigation easier.

## SSHizzle's SSH Agent

An SSH agent performs the function of a key manager for SSH. In a typical setup, a user might store their SSH keys in their home directory. The SSH agent is a background process that is invoked when the user attempts to SSH into a remote host. Its job is to sign challenges with the user's private keys in order to authenticate with a remote host. An SSH Agent cannot perform any function other than signing messages; it does not write key material to disk and it does not permit the export of private keys.

Where the default SSH Agent reads its private keys from the user's home directory, SSHizzle's agent behaves quite differently because it needs to have a public key signed by the key stored in the Azure Key Vault. If a user's SSH config invokes the SSHizzle Agent to authenticate with a host, the following process occurs:

1. The agent generates a new SSH public/private key pair.
2. The agent checks if it is authenticated with Azure Active Directory. If required, the agent opens a browser and asks the user to authenticate.
3. The agent invokes the serverless function, passing it the generated public key.
4. The serverless function signs the public key and returns an SSH certificate to the agent.
5. The agent uses the newly acquired certificate to authenticate with the host.

## Benefits

Using this approach, SSHizzle is able to meet its goals:

Onboarding complexity is reduced; irrespective of the class of user (administrator, developer, analyst, etc.), if a user exists in the Azure Active Directory tenant, and possess the relevant roles, they can authenticate using SSHizzle.

The user experience is slick; users are prompted to authenticate with Azure AD in the same way they are to interact with Microsoft 365 and any other services available through the tenant. Additionally, they can use the same frictionless multi-factor authentication methods such as the Microsoft Authenticator app with no additional setup. This not only provides a consistent UX, but increases the security of the solution.

Credential issuance is more observable; the certificate IDs are verbose and easy to identify in system logs. There is detailed audit information available about specific serverless function invocations through the Azure Portal.

There is no need to distribute many keys to SSH hosts; servers must simply be configured to trust a single user certificate authority.

Credential lifecycle management complexity is reduced; because credentials are only valid for 2 minutes by default, there is no need to revoke credentials. There is little chance that a valid SSH certificate will leak. Off-boarding users is as simple as disabling/removing their account in Azure Active Directory.

The SSHizzle Agent is compatible with existing workflows; provided the user's local SSH config is configured such that all hosts requiring SSHizzle authentication invoke the agent, then other applications like scp, rsync and Visual Studio Code Remote Development work seamlessly. This configuration is particularly simple when combined with wildcard host matching - i.e. configure all SSH connections to \*.your-corp-domain.org to invoke the agent.

SSHizzle is trivial to configure; servers require the inclusion of a single CA public key file, and single line of config in the sshd_config file. On client machines, the SSHizzle Agent is a single binary that can be started in the background.

SSHizzle is extremely cost effective to deploy and run. Azure Functions are free for the first 1,000,000 invocations per month, and the corresponding storage and key vault operations aren't likely to total more than a a few tens of dollars per month with moderate usage.

## Limitations and Possible Extensions

As previously alluded to, the released version of SSHizzle is a proof-of-concept. It demonstrates the concept of utilising a serverless function performing the role of an SSH Certificate Authority, combined with a strong identity provider to simplify the adoption and management of SSH Certificates across an enterprise.

Currently, it lacks a few features one might consider useful for widespread adoption:

Per-user policy for ForceCommands and session features (port forwarding, etc.)

Ability to check if the user authenticating should be interacting with the specified host over SSH, currently if the user is valid in the tenant, a certificate is issued. Their actual access to the end host is governed by whether or not an account exists with their username on the server.

Provisioning of a Host Certificate Authority to avoid host key warnings and prompts

Exercise caution before deploying into production, but do experiment, and perhaps even submit a pull request...

## Try it out!

The code for SSHizzle is available [on Github](https://github.com/thalesgroup/sshizzle), complete with Terraform automation to deploy demonstration resources on Microsoft Azure.
