---
layout: post
title: "Resetting a Forgotten Ubuntu Linux Password on WSL"
author: krzysiek
categories: [proxmox, linux, docker]
image: "https://getwud.github.io/wud/assets/wud-arch.png"
featured: false
hidden: true
---

🌟 Quick Tip for Resetting a Forgotten Ubuntu Linux Password on WSL! 🌟

Did you know you can easily log in to the Ubuntu root account in Windows PowerShell and reset a forgotten password? 

Here’s a step-by-step guide:

1.Open Windows PowerShell:
Use the shortcut Win+X, then select i and tap Enter.
Log in to the Ubuntu root account:
𝙬𝙨𝙡 --𝙪𝙨𝙚𝙧 𝙧𝙤𝙤𝙩
2.Change the password:
For the current user (root):
𝙥𝙖𝙨𝙨𝙬𝙙
For another user:
𝙥𝙖𝙨𝙨𝙬𝙙 𝙪𝙨𝙚𝙧𝙣𝙖𝙢𝙚
This command will interactively ask you for a new password (twice). Note: Windows admin privileges are not required!

3.Manage multiple WSL distributions:
List the names of installed distributions:
𝙬𝙨𝙡 -𝙡
Specify the distribution to log into, for example, Ubuntu 20.04:
𝙬𝙨𝙡 -𝙙 𝙐𝙗𝙪𝙣𝙩𝙪-20.04 --𝙪𝙨𝙚𝙧 𝙧𝙤𝙤𝙩

Simplify your workflow and reset forgotten passwords with these handy commands! 🚀 