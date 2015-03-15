# SQL Service Broker Message Bus

This is a message bus implemented *natively* on SQL Server 2008+ and SQL Service Broker.  

It doesn't offer any new monitoring features, it just is a message bus with good properties:

 * Easily usable over ADO for sending/receiving on Channels or announcing/subscribing/listening on Topics - even works in raw SQL Management Studio!  (Stuff you probably didn't even know that results pane could even do!)
 * Transactional
 * Durable
 * Fairly simple
 * No polling
 * In-use locking
 * Introduces no additional dependencies, does not require new server components, does not use SQL CLR stuff to do its magic
 * Ephemeral, self-registering, self-cleaning subscriptions
 * Can co-exist in your existing database (or a dedicated one) and defaults to be in a non-DBO schema.
 * Runtime operations can be performed by PUBLIC (the default) or only by some specific SQL Role without granting new permissions to the Role.
 * If you don't have the necessary permissions on *all* of the target environments, don't dispair; the SSBMBManager can script out (SQL script) an existing SSBMB deployment (from a dev machine, say) including installation, configuration of Channels, Topics, and permanent Subscriptions, tear-down of said configuration, and the uninstallation of the SSBMB instance ALL IN ONE SCRIPT for easy submission to the production DBAs.
 * Free & open source
 * Great performance & throughput (??? I don't know, but I *expect* it to be - help me benchmark it!)

Supports Windows Azure-style message bus concepts of Channels (Azure's "Queues", but I didn't want to confuse the terminology with SQL SSB primatives) and Topics/Subscriptions broadcasted messages for both permanent and ephemeral Subscribers.

Once deployed, your custom message bus configuration runs entirely on SQL Server and its Service Broker **without employing any SQL CLR assemblies**.  SSBMB merely auto-generates the very complicated, native SQL & SSB primitives which provide desirable Message Bus behaviors.

## Parts

These two projects are only used in the deployment of SSBMB:
  * `SSBMB` is the .NET library of template SQL scripts and .NET wrappers for the installation, configuration, uninstallation, and emission of a single deployment script (including uninstall) matching a prototype deployment.
  * `SSBMBManager` a .NET executable which provides a good-enough GUI wrapper for the `SSBMB` library.

This project illustrates example code on how to Send, Receive, Announce, and Listen for messages in an SSBMB deployment.  It contains reusable code which *could* be wrapped up in a library, but that would be overkill for the abstract audience but perhaps putting it in your own library would be perfectly reasonable for your particular situation:
  * `SSBMBSample` is the example program with four demo modes which demonstrates the ADO calls to an existing and pre-configured SSBMB.  The idea is that you can run multiple of these executables simultaneously in different modes (i.e. two as "TestChannel Sender" and two as "TestChannel Receiver") to play around with the features.

It does not turn off native poison messaging handling because one scenario I need it for is on a SQL 2008 R0 server with no poison message handling override and I didn't feel like parameterizing that yet.  Adding that to each CREATE QUEUE statement throughout is all you'd need to do.

## Deployment Guide

  1. Choose an existing database or create a new one.  You'll need to be an Admin or at least very priviledged to deploy SSBMB, but not to *use* the deployment.
  2. Ensure that Service Broker is enabled for that database.  (For your convenience, here's what you need to do to enable it.  If you don't, you might not get any errors but nothing will happen)

        ALTER DATABASE TargetDatabase SET RESTRICTED_USER WITH ROLLBACK IMMEDIATE
        ALTER DATABASE TargetDatabase SET ENABLE_BROKER
        ALTER DATABASE TargetDatabase SET MULTI_USER WITH ROLLBACK IMMEDIATE

  3. Run the `SSBMBManager.exe`
  4. Update the connection string to point to the right server and database
  5. Press Refresh to examine the database
  6. Press Install to install the basic environment (the "SSBMB" schema, some tables, contracts, message type)
  7. Add Channels, Topics, or Subscriptions as desired.  (You might not need to create any Subscriptions explicitly, so skip that.  To play around, merely create `TestChannel` and `TestTopic` - you can create and destroy these at will, as long as they're no in use - in which case they'd be locked)

    ![SSBMBManager Screenshot](/../screenshot/SSBMBManagerScreenshot.png)

  8. Optionally "Script Configuration" to put a complete script in your Windows copy & paste Clipboard
  9. To test it out, run several instances of `SSBMBSample.exe` simultaneously after creating `TestChannel` and `TestTopic`. Run as both "Sender" and "Receiver" to start out.  How about multiple Receivers?  Then compare that behavior to the "Announce"  "Subscribe & Listen" modes.
  10. You can even run the included `.sql` "Test Scripts" in the `SSBMB` project in individual SQL Management Studio windows!

## Other
    
This project is not offered by, endorsed by, nor related to Microsoft which probably owns the trademarks on many of the words in this document.  This software is available to use at your own risk.
