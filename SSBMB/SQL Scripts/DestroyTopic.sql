SET NOCOUNT ON

IF (@@TRANCOUNT <> 0) BEGIN
    RAISERROR ('AMBIENT TRANSACTION NOT ALLOWED', 11, 1)
    RETURN
END

DECLARE @LastError INT,
        @Message NVARCHAR(1024),
        @LockStatus INT

-- AppLock on the string 'SSBMB' for the remainder of this connection session
EXEC @LockStatus = sp_getapplock @Resource = 'SSBMB', @LockMode = 'SHARED', @LockTimeout = 0, @LockOwner = 'Session'
SELECT @LastError = @@ERROR

IF (0 < @LastError OR @LockStatus < 0) BEGIN -- SSBMB is in use and should not be deleted
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

-- AppLock on the string of the Topic for the remainder of this connection session
EXEC @LockStatus = sp_getapplock @Resource = @TopicName, @LockMode = 'SHARED', @LockTimeout = 0, @LockOwner = 'Session'
SELECT @LastError = @@ERROR

IF (0 < @LastError OR @LockStatus < 0) BEGIN -- Topic is in use
    SELECT @Message = 'Lock on ' + @TopicName + ' unsuccessful: ' +
        (CASE
            WHEN 0 < @LastError   THEN '(Statement Error) ' + (SELECT [text] FROM sys.messages WHERE message_id = @LastError)
            WHEN @LockStatus = -1 THEN 'TIMEOUT (Topic is exclusively locked)'
            WHEN @LockStatus = -2 THEN 'CANCELED'
            WHEN @LockStatus = -3 THEN 'DEADLOCK'
            ELSE 'OTHER' END)
    EXEC sp_releaseapplock @Resource = 'SSBMB', @LockOwner = 'Session'
    RAISERROR (@Message, 11, 1)
    RETURN
END

BEGIN TRAN

IF (NOT EXISTS (SELECT 1 FROM [{0}].[Topics] WHERE TopicName = @TopicName)) BEGIN
    EXEC sp_releaseapplock @Resource = @TopicName, @LockOwner = 'Session'
    EXEC sp_releaseapplock @Resource = 'SSBMB', @LockOwner = 'Session'
    RAISERROR ('Topic not found', 11, 1)
    ROLLBACK
    RETURN
END

IF (EXISTS (SELECT 1 FROM [{0}].[Subscriptions] WHERE TopicName = @TopicName)) BEGIN
    EXEC sp_releaseapplock @Resource = @TopicName, @LockOwner = 'Session'
    EXEC sp_releaseapplock @Resource = 'SSBMB', @LockOwner = 'Session'
    RAISERROR ('Cannot destroy Topic while Subscriptions exist', 11, 1)
    ROLLBACK
    RETURN
END

DECLARE @AnnouncingServiceName SYSNAME = @TopicName + '_AnnouncingService'
DECLARE @BroadcastingServiceName SYSNAME = @TopicName + '_BroadcastingService'
DECLARE @PrimaryQueueName SYSNAME = @TopicName + '_PrimaryQueue'
DECLARE @ControlQueueName SYSNAME = @TopicName + '_ControlQueue'
DECLARE @ControlHandlerName SYSNAME = @TopicName + '_ControlReceiveHandler'
DECLARE @BroadcastHandlerName SYSNAME = @TopicName + '_BroadcastHandler'
DECLARE @AnnounceName SYSNAME = @TopicName + '_Announce'

-- Services
IF EXISTS (SELECT name FROM sys.services WHERE name = @AnnouncingServiceName) BEGIN
    PRINT 'Dropping ' + @AnnouncingServiceName + ' ...';
    EXEC ('DROP SERVICE [' + @AnnouncingServiceName + ']')
    IF (0 < @@ERROR) BEGIN
        EXEC sp_releaseapplock @Resource = @TopicName, @LockOwner = 'Session'
        EXEC sp_releaseapplock @Resource = 'SSBMB', @LockOwner = 'Session'
        RAISERROR ('Dropping AnnouncingService', 11, 1)
        RETURN
    END
END
IF EXISTS (SELECT name FROM sys.services WHERE name = @BroadcastingServiceName) BEGIN
    PRINT 'Dropping ' + @BroadcastingServiceName + ' ...';
    EXEC ('DROP SERVICE [' + @BroadcastingServiceName + ']')
    IF (0 < @@ERROR) BEGIN
        EXEC sp_releaseapplock @Resource = @TopicName, @LockOwner = 'Session'
        EXEC sp_releaseapplock @Resource = 'SSBMB', @LockOwner = 'Session'
        RAISERROR ('Dropping BroadcastingService', 11, 1)
        RETURN
    END
END

-- Queues
IF EXISTS (SELECT name FROM sys.service_queues WHERE name = @PrimaryQueueName) BEGIN
    PRINT 'Dropping ' + @PrimaryQueueName + ' ...';
    EXEC ('DROP QUEUE [{0}].[' + @PrimaryQueueName + ']')
    IF (0 < @@ERROR) BEGIN
        EXEC sp_releaseapplock @Resource = @TopicName, @LockOwner = 'Session'
        EXEC sp_releaseapplock @Resource = 'SSBMB', @LockOwner = 'Session'
        RAISERROR ('Dropping PrimaryQueue', 11, 1)
        RETURN
    END
END
IF EXISTS (SELECT name FROM sys.service_queues WHERE name = @ControlQueueName) BEGIN
    PRINT 'Dropping ' + @ControlQueueName + ' ...';
    EXEC ('DROP QUEUE [{0}].[' + @ControlQueueName + ']')
    IF (0 < @@ERROR) BEGIN
        EXEC sp_releaseapplock @Resource = @TopicName, @LockOwner = 'Session'
        EXEC sp_releaseapplock @Resource = 'SSBMB', @LockOwner = 'Session'
        RAISERROR ('Dropping ControlQueue', 11, 1)
        RETURN
    END
END

-- Activation Procedure (For Ending Conversations)
IF EXISTS (SELECT name FROM sys.procedures WHERE name = @BroadcastHandlerName) BEGIN
    PRINT 'Dropping ' + @BroadcastHandlerName + ' ...';
    EXEC ('DROP PROCEDURE [{0}].[' + @BroadcastHandlerName + ']')
    IF (0 < @@ERROR) BEGIN
        EXEC sp_releaseapplock @Resource = @TopicName, @LockOwner = 'Session'
        EXEC sp_releaseapplock @Resource = 'SSBMB', @LockOwner = 'Session'
        RAISERROR ('Dropping BroadcastHandler', 11, 1)
        RETURN
    END
END

IF EXISTS (SELECT name FROM sys.procedures WHERE name = @ControlHandlerName) BEGIN
    PRINT 'Dropping ' + @ControlHandlerName + ' ...';
    EXEC ('DROP PROCEDURE [{0}].[' + @ControlHandlerName + ']')
    IF (0 < @@ERROR) BEGIN
        EXEC sp_releaseapplock @Resource = @TopicName, @LockOwner = 'Session'
        EXEC sp_releaseapplock @Resource = 'SSBMB', @LockOwner = 'Session'
        RAISERROR ('Dropping ControlHandler', 11, 1)
        RETURN
    END
END

-- Announce Proc
IF EXISTS (SELECT name FROM sys.procedures WHERE name = @AnnounceName) BEGIN
    PRINT 'Dropping ' + @AnnounceName + ' ...';
    EXEC ('DROP PROCEDURE [{0}].[' + @AnnounceName + ']')
    IF (0 < @@ERROR) BEGIN
        EXEC sp_releaseapplock @Resource = @TopicName, @LockOwner = 'Session'
        EXEC sp_releaseapplock @Resource = 'SSBMB', @LockOwner = 'Session'
        RAISERROR ('Dropping Announce', 11, 1)
        RETURN
    END
END

DELETE FROM [{0}].Topics WHERE TopicName = @TopicName

COMMIT

EXEC sp_releaseapplock @Resource = @TopicName, @LockOwner = 'Session'
EXEC sp_releaseapplock @Resource = 'SSBMB', @LockOwner = 'Session'