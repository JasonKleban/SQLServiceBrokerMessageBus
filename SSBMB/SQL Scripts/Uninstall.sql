SET NOCOUNT ON

IF (@@TRANCOUNT <> 0) BEGIN
    RAISERROR ('AMBIENT TRANSACTION NOT ALLOWED', 11, 1)
    RETURN
END

DECLARE @LastError INT,
        @Message NVARCHAR(1024),
        @LockStatus INT,
        @NumSubscriptions INT = 0,
        @NumTopics INT = 0,
        @NumChannels INT = 0

-- AppLock on the string 'SSBMB' for the remainder of this connection session
EXEC @LockStatus = sp_getapplock @Resource = 'SSBMB', @LockMode = 'EXCLUSIVE', @LockTimeout = 0, @LockOwner = 'Session'
SELECT @LastError = @@ERROR

IF (0 < @LastError OR @LockStatus < 0) BEGIN -- Channel is in use and should not be deleted
    SELECT @Message = 'Lock on SSBMB unsuccessful: ' +
        (CASE
            WHEN 0 < @LastError   THEN '(Statement Error) ' + (SELECT [text] FROM sys.messages WHERE message_id = @LastError)
            WHEN @LockStatus = -1 THEN 'TIMEOUT (SSBMB is in use)'
            WHEN @LockStatus = -2 THEN 'CANCELED'
            WHEN @LockStatus = -3 THEN 'DEADLOCK'
            ELSE 'OTHER' END)
    RAISERROR (@Message, 11, 1)
    RETURN
END

IF OBJECT_ID('[{0}].Channels', 'U') IS NOT NULL BEGIN
    EXEC sp_executesql N'SELECT @NumChannels = COUNT(0) FROM [{0}].Channels', N'@NumChannels INT OUTPUT', @NumChannels OUTPUT;
    IF (0 < @NumChannels) BEGIN
        EXEC sp_releaseapplock @Resource = 'SSBMB', @LockOwner = 'Session'
        RAISERROR ('Cannot Uninstall while Channels remain', 11, 1)
        RETURN
    END
END

IF OBJECT_ID('[{0}].Subscriptions', 'U') IS NOT NULL BEGIN
    EXEC sp_executesql N'SELECT @NumSubscriptions = COUNT(0) FROM [{0}].Subscriptions', N'@NumSubscriptions INT OUTPUT', @NumSubscriptions OUTPUT;
    IF (0 < @NumSubscriptions) BEGIN
        EXEC sp_releaseapplock @Resource = 'SSBMB', @LockOwner = 'Session'
        RAISERROR ('Cannot Uninstall while Subscriptions remain', 11, 1)
        RETURN
    END
END

IF OBJECT_ID('[{0}].Topics', 'U') IS NOT NULL BEGIN
    EXEC sp_executesql N'SELECT @NumTopics = COUNT(0) FROM [{0}].Topics', N'@NumTopics INT OUTPUT', @NumTopics OUTPUT;
    IF (0 < @NumTopics) BEGIN
        EXEC sp_releaseapplock @Resource = 'SSBMB', @LockOwner = 'Session'
        RAISERROR ('Cannot Uninstall while Topics remain', 11, 1)
        RETURN
    END
END

IF OBJECT_ID('[{0}].CleanUpEphemeralSubscriptions', 'P') IS NOT NULL BEGIN
    PRINT 'Dropping CleanUpEphemeralSubscriptions ...';
    DROP PROCEDURE [{0}].CleanUpEphemeralSubscriptions
    IF (0 < @@ERROR) BEGIN
        EXEC sp_releaseapplock @Resource = 'SSBMB', @LockOwner = 'Session'
        RAISERROR ('Dropping CleanUpEphemeralSubscriptions', 11, 1)
        RETURN
    END
END

IF OBJECT_ID('[{0}].Subscribe', 'P') IS NOT NULL BEGIN
    PRINT 'Dropping Subscribe ...';
    DROP PROCEDURE [{0}].Subscribe
    IF (0 < @@ERROR) BEGIN
        EXEC sp_releaseapplock @Resource = 'SSBMB', @LockOwner = 'Session'
        RAISERROR ('Dropping Subscribe', 11, 1)
        RETURN
    END
END

IF OBJECT_ID('[{0}].Unsubscribe', 'P') IS NOT NULL BEGIN
    PRINT 'Dropping Unsubscribe ...';
    DROP PROCEDURE [{0}].Unsubscribe
    IF (0 < @@ERROR) BEGIN
        EXEC sp_releaseapplock @Resource = 'SSBMB', @LockOwner = 'Session'
        RAISERROR ('Dropping Unsubscribe', 11, 1)
        RETURN
    END
END

IF EXISTS (SELECT name FROM sys.service_contracts WHERE name = 'ChannelContract') BEGIN
    PRINT 'Dropping ChannelContract ...';
    DROP CONTRACT ChannelContract
    IF (0 < @@ERROR) BEGIN
        EXEC sp_releaseapplock @Resource = 'SSBMB', @LockOwner = 'Session'
        RAISERROR ('Dropping ChannelContract', 11, 1)
        RETURN
    END
END

IF EXISTS (SELECT name FROM sys.service_contracts WHERE name = 'TopicContract') BEGIN
    PRINT 'Dropping TopicContract ...';
    DROP CONTRACT TopicContract
    IF (0 < @@ERROR) BEGIN
        EXEC sp_releaseapplock @Resource = 'SSBMB', @LockOwner = 'Session'
        RAISERROR ('Dropping TopicContract', 11, 1)
        RETURN
    END
END

IF EXISTS (SELECT name FROM sys.service_contracts WHERE name = 'SubscriptionContract') BEGIN
    PRINT 'Dropping SubscriptionContract ...';
    DROP CONTRACT SubscriptionContract
    IF (0 < @@ERROR) BEGIN
        EXEC sp_releaseapplock @Resource = 'SSBMB', @LockOwner = 'Session'
        RAISERROR ('Dropping SubscriptionContract', 11, 1)
        RETURN
    END
END

IF EXISTS (SELECT name FROM sys.service_message_types WHERE name = 'SerializedMessage') BEGIN
    PRINT 'Dropping SerializedMessage ...';
    DROP MESSAGE TYPE SerializedMessage
    IF (0 < @@ERROR) BEGIN
        EXEC sp_releaseapplock @Resource = 'SSBMB', @LockOwner = 'Session'
        RAISERROR ('Dropping SerializedMessage', 11, 1)
        RETURN
    END
END

IF OBJECT_ID('[{0}].Subscriptions', 'U') IS NOT NULL BEGIN
    PRINT 'Dropping Subscriptions ...';
    DROP TABLE [{0}].Subscriptions
    IF (0 < @@ERROR) BEGIN
        EXEC sp_releaseapplock @Resource = 'SSBMB', @LockOwner = 'Session'
        RAISERROR ('Dropping Subscriptions', 11, 1)
        RETURN
    END
END

IF OBJECT_ID('[{0}].Topics', 'U') IS NOT NULL BEGIN
    PRINT 'Dropping Topics ...';
    DROP TABLE [{0}].Topics
    IF (0 < @@ERROR) BEGIN
        EXEC sp_releaseapplock @Resource = 'SSBMB', @LockOwner = 'Session'
        RAISERROR ('Dropping Topics', 11, 1)
        RETURN
    END
END

IF OBJECT_ID('[{0}].Channels', 'U') IS NOT NULL BEGIN
    PRINT 'Dropping Channels ...';
    DROP TABLE [{0}].Channels
    IF (0 < @@ERROR) BEGIN
        EXEC sp_releaseapplock @Resource = 'SSBMB', @LockOwner = 'Session'
        RAISERROR ('Dropping Channels', 11, 1)
        RETURN
    END
END

IF EXISTS (SELECT name FROM sys.schemas WHERE name = '{0}') BEGIN
    PRINT 'Dropping {0} ...';
    DROP SCHEMA [{0}]
    IF (0 < @@ERROR) BEGIN
        EXEC sp_releaseapplock @Resource = 'SSBMB', @LockOwner = 'Session'
        RAISERROR ('Dropping {0}', 11, 1)
        RETURN
    END
END

EXEC sp_releaseapplock @Resource = 'SSBMB', @LockOwner = 'Session'