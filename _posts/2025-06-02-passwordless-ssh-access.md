---
layout: post
title: "Passwordless SSH Access from Windows to a Linux Device"
date: 2024-05-24 10:00:00 +0100
author: krzysiek
categories: [windows, powershell, linux, ssh,]
image: /assets/images/ssh.png
featured: true
---

The OpenSSH client in Windows 10 does not include the ssh-copy-id command that is commonly available in Linux systems. However, with a simple one-liner in PowerShell, we can replicate the functionality and copy the SSH public key to a remote Linux device — enabling passwordless login.

1. ## Generating an SSH Key

> **Skip this step if you already have a working SSH key pair.**
Open **PowerShell** (not Command Prompt!) and run:

```
ssh-keygen
```

By default, the keys will be saved in the directory:
```
%USERPROFILE%\.ssh\
```

The public key file we are interested in is:
```
id_rsa.pub
```


Example output:

```
C:\Users\kadamczak/.ssh/id_rsa already exists.
Overwrite (y/n)? y
Enter passphrase (empty for no passphrase):
Enter same passphrase again:
Your identification has been saved in C:\Users\kadamczak/.ssh/id_rsa
Your public key has been saved in C:\Users\kadamczak/.ssh/id_rsa.pub
The key fingerprint is:
SHA256:kXlQ1VNzGN+yytspx5i9BAUHlXg9y34pGIgEIqaKkc8 stordis\kadamczak@NB-TECH17
The key's randomart image is:
+---[RSA 3072]----+
| o . .. ....+=+Bo|
|o.. . . + .o*o=|
|+ . = o .+.=|
|o+ . + . . = |
|o E S + o .|
| o + o.|
| o=o .|
| +++. |
| .o+. |
+----[SHA256]-----+
PS C:\Users\kadamczak>
```

2. ## Copying the SSH Key to a Remote Linux Device
To copy your public key to the remote Linux device, use the following one-liner in PowerShell:

```
type $env:USERPROFILE\.ssh\id_rsa.pub | ssh user@REMOTE_IP "cat >> ~/.ssh/authorized_keys"
```

Replace user and REMOTE_IP with your actual Linux username and the IP address or FQDN of the remote machine.

Example:

```
type $env:USERPROFILE\.ssh\id_rsa.pub | ssh krzysiek@192.168.196.200 "cat >> ~/.ssh/authorized_keys"
```

You'll be asked for your password once. After successful execution, the key will be saved on the remote server.

3. ## Testing Passwordless SSH Access
Now test the connection:

```
ssh krzysiek@192.168.196.200
```

Example session:
```
PS C:\Users\admin> ssh krzysiek@192.168.196.200
Linux srvoffice-rpi 6.1.21-v7+ #1642 SMP Mon Apr 3 17:20:52 BST 2023 armv7l

Last login: Wed May 22 13:44:05 2024 from 10.10.169.3

krzysiek@srv-rpi:~ $
```

Notice that no password was required — the setup was successful.


## References
This guide was heavily inspired by a blog post written by [Christopher Hart](https://chrisjhart.com/Windows-10-ssh-copy-id/#copy-ssh-key-to-remote-linux-device)
