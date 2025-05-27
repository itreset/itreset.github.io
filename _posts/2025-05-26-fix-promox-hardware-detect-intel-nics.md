---
layout: post
title:  "How To Fix Proxmox Detected Hardware Unit Hang On Intel NICs"
author: krzysiek
categories: [ proxmox, tutorial, tips ]
image: assets/images/post20250526.png
featured: true
hidden: true
---

Sometimes, Intel NICs can cause a server’s network card to freeze with the error message Proxmox How To Fix Proxmox Detected Hardware Unit Hang. This affects several NIC models. The problem appears to occur when the network is under load. On a Proxmox network, this can be particularly problematic when you are running backups. The NIC adapter will freeze but the server is still online, it’s just unresponsive. A Proxmox Detected Hardware Unit Hang will appear in the syslog files.

## Log Files
In your /var/log/syslog file, you may notice lines like this;

```html
---
Mar 14 14:17:10 server91 kernel: [6045453.108633] e1000e 0000:00:1f.6 eno1: Detected Hardware Unit Hang:
Mar 14 14:17:10 server91 kernel: [6045453.108633] TDH <0>
Mar 14 14:17:10 server91 kernel: [6045453.108633] TDT <1>
Mar 14 14:17:10 server91 kernel: [6045453.108633] next_to_use <1>
Mar 14 14:17:10 server91 kernel: [6045453.108633] next_to_clean <0>
Mar 14 14:17:10 server91 kernel: [6045453.108633] buffer_info[next_to_clean]:
Mar 14 14:17:10 server91 kernel: [6045453.108633] time_stamp <15a14b4cb>
Mar 14 14:17:10 server91 kernel: [6045453.108633] next_to_watch <0>
Mar 14 14:17:10 server91 kernel: [6045453.108633] jiffies <15a14b8b8>
Mar 14 14:17:10 server91 kernel: [6045453.108633] next_to_watch.status <0>
Mar 14 14:17:10 server91 kernel: [6045453.108633] MAC Status <40080083>
Mar 14 14:17:10 server91 kernel: [6045453.108633] PHY Status <796d>
Mar 14 14:17:10 server91 kernel: [6045453.108633] PHY 1000BASE-T Status <3800>
Mar 14 14:17:10 server91 kernel: [6045453.108633] PHY Extended Status <3000>
Mar 14 14:17:10 server91 kernel: [6045453.108633] PCI Status <10>
Mar 14 14:17:11 server91 kernel: [6045454.164399] e1000e 0000:00:1f.6 eno1: Reset adapter unexpectedly
Mar 14 14:17:11 server91 kernel: [6045454.164439] vmbr0: port 1(eno1) entered disabled state
Mar 14 14:17:18 server91 kernel: [6045461.092765] e1000e: eno1 NIC Link is Up 1000 Mbps Full Duplex, Flow Control: Rx/Tx
Mar 14 14:17:18 server91 kernel: [6045461.092810] vmbr0: port 1(eno1) entered blocking state
Mar 14 14:17:18 server91 kernel: [6045461.092812] vmbr0: port 1(eno1) entered forwarding state
---
```

This indicates you are running one of the Intel NICs affected by this problem. A fix was issued but this did not resolve the problem and Intel do not expect to fix the issue. A Bugzilla for this appears at <a target="_blank" href="https://bugzilla.kernel.org/show_bug.cgi?id=47331/">https://bugzilla.kernel.org/show_bug.cgi?id=47331</a>.

## Known NIC Adapters Affected
So you can check your NIC model by issuing the below command in a console where you have root privileges. This doesn’t just happen on Proxmox servers. The error can appear at random and does not always happen.

```html
---
lspci -v | grep Ethernet
---
```
We have confirmed the error on these network adapters.

```html
---
Ethernet Connection (6) I219-V
Ethernet Connection (6) I219-LM
Ethernet Connection (7) I219-LM

User Reported NICs

Intel Corporation 82579LM Gigabit Network Connection (Lewisville) (rev 04)
---
```

## Fix Proxmox Detected Hardware Unit Hang
The only way to resolve this is to disable features on your NIC adapter. This is not the preferable way but it’s better than your whole server being knocked offline. To temporarily implement this fix, issue the following command.

```html
---
apt-get install ethtool -y
ethtool -K eno1 tso off gso off
---
```

This fix will only work until you reboot the server. To make it permanent, you must add a post-up command to your interfaces file. Just add the last line to your /etc/network/interfaces file.
```html
---
auto eno1
iface eno1 inet static
  address 5.5.5.555
  netmask 255.255.255.224
  gateway 5.5.5.55
  post-up /sbin/ethtool -K eno1 tso off gso off
---
```  

If you have found a NIC that we haven’t listed but the fix described worked for you, let us know in the comments so we can update our article.

