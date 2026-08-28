---
layout: post
title:  "How to Log Off a Network Resource in Windows Using CMD"
author: krzysiek
categories: [ windows, tips ]
image: assets/images/post20260827.png
featured: true
hidden: false
comments: false
---

Windows can stubbornly hold on to active connections to network shares, mapped drives, and file servers. When you need to quickly disconnect a resource, clear a session, or remove cached credentials, the command line is the most reliable way to do it.

This guide shows how to properly "log off" from a network resource using the `net use` and `cmdkey` commands, and what to do when the system still insists on keeping the connection alive.

## When You Should Disconnect a Network Resource

Disconnecting a network share connection is useful when:

- the password for the server or share has changed,
- Windows keeps trying to use outdated login credentials,
- you need to unmap a drive without restarting the computer,
- access to the resource has been blocked due to a broken session,
- File Explorer keeps automatically reconnecting with invalid credentials.

## Disconnecting a Specific Resource

If you only want to disconnect one connection, you can target either a specific mapped drive or a direct UNC path.

### Mapped Drive

```cmd
net use Z: /delete
```

This command removes the active connection for drive `Z:`.

### UNC Path

```cmd
net use \\server\share /delete
```

This version works when the resource wasn't mapped to a drive letter but was opened directly as a network share.

## Disconnecting All Resources

If you need to close all active network connections in the current session, use:

```cmd
net use * /delete
```

Windows will usually ask for confirmation. To skip the prompt, add the `/y` parameter:

```cmd
net use * /delete /y
```

This is a good method when you're not sure which connection is still keeping a session open to the server.

## Removing Saved Credentials

Simply disconnecting a resource isn't always enough. Windows may still store login credentials in Credential Manager, causing the next connection to be re-established with the same username and password.

### Listing Saved Entries

```cmd
cmdkey /list
```

This command displays saved credentials that Windows may use when reconnecting to network resources.

### Removing a Specific Entry

```cmd
cmdkey /delete:ResourceName
```

Examples:

```cmd
cmdkey /delete:192.168.1.10
cmdkey /delete:Domain:target=Server01
```

After removing the relevant entry, Windows will stop automatically using the saved credentials for that resource.

## What to Do If the Connection Keeps Coming Back

Sometimes, even after using `net use`, the system still keeps a session running in the background. In that case, try restarting the Workstation service.

```cmd
net stop lanmanworkstation /y
net start lanmanworkstation
```

Treat this as a fallback option, especially when a normal disconnect doesn't do the trick.

## Extra Tip for File Explorer

After running these commands, it's a good idea to close any open File Explorer windows using the given share and refresh the view. This prevents Windows from immediately trying to re-establish the connection in the background.

## Quick Reference

| Goal | Command |
|---|---|
| Disconnect a mapped drive | `net use Z: /delete` |
| Disconnect a UNC share | `net use \\server\share /delete` |
| Disconnect all connections | `net use * /delete /y` |
| View saved credentials | `cmdkey /list` |
| Remove a credential | `cmdkey /delete:ResourceName` |
| Restart Workstation service | `net stop lanmanworkstation /y` and `net start lanmanworkstation` |

## Summary

For disconnecting network resources in Windows, `net use` is the go-to tool, while `cmdkey` is essential for fully removing saved login credentials. Combining both lets you effectively cut an active session and prepare the system to log in again with the correct credentials.