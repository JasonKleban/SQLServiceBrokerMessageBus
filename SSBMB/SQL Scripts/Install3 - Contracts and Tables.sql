
IF (NOT EXISTS (SELECT 1 FROM sys.service_message_types WHERE name = 'SerializedMessage')) BEGIN
    CREATE MESSAGE TYPE [SerializedMessage]
        AUTHORIZATION [dbo]
        VALIDATION = NONE
END

IF (NOT EXISTS (SELECT 1 FROM sys.service_contracts WHERE name = 'ChannelContract')) BEGIN
    CREATE CONTRACT [ChannelContract]
        AUTHORIZATION [dbo]
    (
        [SerializedMessage] SENT BY ANY
    )
END

IF (NOT EXISTS (SELECT 1 FROM sys.service_contracts WHERE name = 'TopicContract')) BEGIN
    CREATE CONTRACT [TopicContract]
        AUTHORIZATION [dbo]
    (
        [SerializedMessage] SENT BY INITIATOR
    )
END

IF (NOT EXISTS (SELECT 1 FROM sys.service_contracts WHERE name = 'SubscriptionContract')) BEGIN
    CREATE CONTRACT [SubscriptionContract]
        AUTHORIZATION [dbo]
    (
        [SerializedMessage] SENT BY INITIATOR
    )
END

IF OBJECT_ID('[{0}].Channels', 'U') IS NULL BEGIN
    CREATE TABLE [{0}].Channels
    (
        ChannelName SYSNAME CONSTRAINT PK_Channels PRIMARY KEY
    )
END

IF OBJECT_ID('[{0}].Topics', 'U') IS NULL BEGIN
    CREATE TABLE [{0}].Topics
    (
        TopicName SYSNAME CONSTRAINT PK_Topics PRIMARY KEY,
        [InitiatorDialogID] UNIQUEIDENTIFIER NOT NULL
    )
END

IF OBJECT_ID('[{0}].Subscriptions', 'U') IS NULL BEGIN
    CREATE TABLE [{0}].Subscriptions
    (
        TopicName SYSNAME NOT NULL CONSTRAINT FK_Subscriptions_Topics_TopicName FOREIGN KEY (TopicName) REFERENCES [{0}].Topics(TopicName),
        SubscriptionName SYSNAME NOT NULL,
        Fixed BIT NOT NULL DEFAULT(0),
        [InitiatorDialogID] UNIQUEIDENTIFIER NOT NULL,
        CONSTRAINT PK_Subscriptions PRIMARY KEY (TopicName, SubscriptionName, Fixed)
    )
END

IF OBJECT_ID('[{0}].CleanUpEphemeralSubscriptions', 'P') IS NULL BEGIN
    EXEC ('CREATE PROCEDURE [{0}].[CleanUpEphemeralSubscriptions] AS BEGIN SET NOCOUNT ON; END')
    EXEC ('GRANT EXECUTE ON [{0}].[CleanUpEphemeralSubscriptions] TO [{1}]')
END

IF OBJECT_ID('[{0}].Subscribe', 'P') IS NULL BEGIN
    EXEC ('CREATE PROCEDURE [{0}].[Subscribe] AS BEGIN SET NOCOUNT ON; END')
    EXEC ('GRANT EXECUTE ON [{0}].[Subscribe] TO [{1}]')
END

IF OBJECT_ID('[{0}].Unsubscribe', 'P') IS NULL BEGIN
    EXEC ('CREATE PROCEDURE [{0}].[Unsubscribe] AS BEGIN SET NOCOUNT ON; END')
    EXEC ('GRANT EXECUTE ON [{0}].[Unsubscribe] TO [{1}]')
END