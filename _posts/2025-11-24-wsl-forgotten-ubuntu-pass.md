---
layout: post
title: "Resetting a Forgotten Ubuntu Linux Password on WSL"
author: krzysiek
categories: [proxmox, linux, docker]
image: assets/images/post20260115.png
featured: true
hidden: false
comments: false
---

# Forgot your **Ubuntu account password in WSL**?  
No need to reinstall the distribution — just run a few quick commands in **Windows PowerShell**.
---

### Open Windows PowerShell
Use the shortcut **Win + X**, select **i**, and press **Enter**.

---
### Log in as root
```bash
wsl --user root
```
---

### Change the password

For the current user (root):

```bash
passwd
```

For another user:

```bash
passwd username
```

💬 The system will ask you to enter the new password twice — and you're all set!
---

## Manage multiple WSL distributions

List the installed distributions:

```bash
wsl -l
```
Log in to a specific distribution (for example, **Ubuntu 20.04**):

```bash
wsl -d Ubuntu-20.04 --user root
```
---

💡 **Tip:** You don't need Windows admin privileges to reset a WSL password!

Simplify your workflow and recover access to Ubuntu in seconds 🚀
---
