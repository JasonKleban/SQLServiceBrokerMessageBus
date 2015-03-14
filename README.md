# SQL Service Broker Message Bus

This is a message bus implemented *natively* on SQL Server 2008+ and SQL Service Broker.  

It doesn't offer any new monitoring features, it just is a message bus with good properties:

  * Transactional
  * Durable
  * Fairly simple
  * Introduces no additional dependencies, does not require new server components, does not use SQL CLR stuff to do its magic.
  * Ephemeral, self-registering, self-cleaning subscriptions
  * Can co-exist in your existing database (or a dedicated one) and defaults to be in a non-DBO schema.
  * Runtime operations can be performed by PUBLIC (the default) or only by some specific SQL Role without granting new permissions to the Role.
  * Free & open source

Supports Windows Azure-style messaging with both Channels (Azure's "Queues", but I didn't want to confuse the terminology with SQL SSB primatives) and Topics/Subscriptions broadcasted messages for both permanent and ephemeral subscribers.

Once deployed, your custom message bus configuration runs entirely on SQL Server and its Service Broker **without employing any SQL CLR assemblies**.  SSBMB merely auto-generates the very complicated, native SQL & SSB primitives which provide desirable Message Bus behaviors.

Easily usable over ADO for sending/receiving on Channels or announcing/subscribing/listening on Topics.

This project is not offered by, endorsed by, nor related to Microsoft which probably owns the trademarks on many of the words in this document.  This software is available to use at your own risk.

Make sure SQL Service Broker is enabled or not much will happen, but you might not get any errors.  For your convenience, here's what you need to do to enable it:

    ALTER DATABASE TargetDatabase SET RESTRICTED_USER WITH ROLLBACK IMMEDIATE
    ALTER DATABASE TargetDatabase SET ENABLE_BROKER
    ALTER DATABASE TargetDatabase SET MULTI_USER WITH ROLLBACK IMMEDIATE

These two projects are only used in the deployment of SSBMB:
  * `SSBMB` is the .NET library of template SQL scripts and .NET wrappers for the installation, configuration, uninstallation, and emission of a single deployment script (including uninstall) matching a prototype deployment.
  * `SSBMBManager` a .NET executable which provides a good-enough GUI wrapper for the `SSBMB` library.

This project illustrates example code on how to Send, Receive, Announce, and Listen for messages in an SSBMB deployment.  It contains reusable code which *could* be wrapped up in a library, but that would be overkill for the abstract audience but perhaps putting it in your own library would be perfectly reasonable for your particular situation:
  * `SSBMBSample` is the example program with four demo modes which demonstrates the ADO calls to an existing and pre-configured SSBMB.  The idea is that you can run multiple of these executables simultaneously in different modes (i.e. two as "TestChannel Sender" and two as "TestChannel Receiver") to play around with the features.

It does not turn off native poison messaging handling because one scenario I need it for is on a SQL 2008 R0 server with no poison message handling override and I didn't feel like parameterizing that yet.  Adding that to each CREATE QUEUE statement throughout is all you'd need to do.
