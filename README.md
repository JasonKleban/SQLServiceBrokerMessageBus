# SQL Service Broker Message Bus

This is a robust message bus implemented *natively* on SQL Server 2008+ and SQL Service Broker.

Supports Windows Azure-style messaging with both Channels (Azure's "queues") and Topics/Subscriptions broadcasted messages for both permanent and ad hoc subscribers.

The .NET Windows Forms application merely assists with installation, configuration, uninstallation, and emission of sql scripts thereof.  Once installed and configured, your custom message bus configuration runs entirely on SQL Server.

Easily usable over ADO for sending/receiving on Channels or announcing/subscribing/listening on Topics.

This project is not offered by or related to Microsoft, who probably owns the trademarks on many of the words in this document.  This software is available to use at your own risk.
