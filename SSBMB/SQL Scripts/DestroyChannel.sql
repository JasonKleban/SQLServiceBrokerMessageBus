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

-- AppLock on the string of the QueueName for the remainder of this connection session
EXEC @LockStatus = sp_getapplock @Resource = @ChannelName, @LockMode = 'EXCLUSIVE', @LockTimeout = 0, @LockOwner = 'Session'
SELECT @LastError = @@ERROR

IF (0 < @LastError OR @LockStatus < 0) BEGIN -- Channel is in use and should not be deleted
    SELECT @Message = 'Lock on ' + @ChannelName + ' unsuccessful: ' +
        (CASE
            WHEN 0 < @LastError   THEN '(Statement Error) ' + (SELECT [text] FROM sys.messages WHERE message_id = @LastError)
            WHEN @LockStatus = -1 THEN 'TIMEOUT (Channel is in use and should not be deleted)'
            WHEN @LockStatus = -2 THEN 'CANCELED'
            WHEN @LockStatus = -3 THEN 'DEADLOCK'
            ELSE 'OTHER' END)
    EXEC sp_releaseapplock @Resource = 'SSBMB', @LockOwner = 'Session'
    RAISERROR (@Message, 11, 1)
    RETURN
END

DECLARE @IssuingServiceName SYSNAME = @ChannelName + '_IssuingService'
DECLARE @ReceivingServiceName SYSNAME = @ChannelName + '_ReceivingService'
DECLARE @PrimaryQueueName SYSNAME = @ChannelName + '_PrimaryQueue'
DECLARE @ControlQueueName SYSNAME = @ChannelName + '_ControlQueue'
DECLARE @ControlHandlerName SYSNAME = @ChannelName + '_ControlReceiveHandler'
DECLARE @ReceiveName SYSNAME = @ChannelName + '_Receive'
DECLARE @SendName SYSNAME = @ChannelName + '_Send'

-- Services
IF EXISTS (SELECT name FROM sys.services WHERE name = @IssuingServiceName) BEGIN
    PRINT 'Dropping ' + @IssuingServiceName + ' ...';
    EXEC ('DROP SERVICE [' + @IssuingServiceName + ']')
    IF (0 < @@ERROR) BEGIN
        EXEC sp_releaseapplock @Resource = @ChannelName, @LockOwner = 'Session'
        EXEC sp_releaseapplock @Resource = 'SSBMB', @LockOwner = 'Session'
        RAISERROR ('Dropping IssuingService', 11, 1)
        RETURN
    END
END
IF EXISTS (SELECT name FROM sys.services WHERE name = @ReceivingServiceName) BEGIN
    PRINT 'Dropping ' + @ReceivingServiceName + ' ...';
    EXEC ('DROP SERVICE [' + @ReceivingServiceName + ']')
    IF (0 < @@ERROR) BEGIN
        EXEC sp_releaseapplock @Resource = @ChannelName, @LockOwner = 'Session'
        EXEC sp_releaseapplock @Resource = 'SSBMB', @LockOwner = 'Session'
        RAISERROR ('Dropping ReceivingService', 11, 1)
        RETURN
    END
END

-- Queues
IF EXISTS (SELECT name FROM sys.service_queues WHERE name = @PrimaryQueueName) BEGIN
    PRINT 'Dropping ' + @PrimaryQueueName + ' ...';
    EXEC ('DROP QUEUE [{0}].[' + @PrimaryQueueName + ']')
    IF (0 < @@ERROR) BEGIN
        EXEC sp_releaseapplock @Resource = @ChannelName, @LockOwner = 'Session'
        EXEC sp_releaseapplock @Resource = 'SSBMB', @LockOwner = 'Session'
        RAISERROR ('Dropping PrimaryQueue', 11, 1)
        RETURN
    END
END
IF EXISTS (SELECT name FROM sys.service_queues WHERE name = @ControlQueueName) BEGIN
    PRINT 'Dropping ' + @ControlQueueName + ' ...';
    EXEC ('DROP QUEUE [{0}].[' + @ControlQueueName + ']')
    IF (0 < @@ERROR) BEGIN
        EXEC sp_releaseapplock @Resource = @ChannelName, @LockOwner = 'Session'
        EXEC sp_releaseapplock @Resource = 'SSBMB', @LockOwner = 'Session'
        RAISERROR ('Dropping ControlQueue', 11, 1)
        RETURN
    END
END

-- Activation Procedure (For Ending Conversations)
IF EXISTS (SELECT name FROM sys.procedures WHERE name = @ControlHandlerName) BEGIN
    PRINT 'Dropping ' + @ControlHandlerName + ' ...';
    EXEC ('DROP PROCEDURE [{0}].[' + @ControlHandlerName + ']')
    IF (0 < @@ERROR) BEGIN
        EXEC sp_releaseapplock @Resource = @ChannelName, @LockOwner = 'Session'
        EXEC sp_releaseapplock @Resource = 'SSBMB', @LockOwner = 'Session'
        RAISERROR ('Dropping ControlReceiveHandler', 11, 1)
        RETURN
    END
END

-- Send & Receive Procs
IF EXISTS (SELECT name FROM sys.procedures WHERE name = @SendName) BEGIN
    PRINT 'Dropping ' + @SendName + ' ...';
    EXEC ('DROP PROCEDURE [{0}].[' + @SendName + ']')
    IF (0 < @@ERROR) BEGIN
        EXEC sp_releaseapplock @Resource = @ChannelName, @LockOwner = 'Session'
        EXEC sp_releaseapplock @Resource = 'SSBMB', @LockOwner = 'Session'
        RAISERROR ('Dropping SendProc', 11, 1)
        RETURN
    END
END

IF EXISTS (SELECT name FROM sys.procedures WHERE name = @ReceiveName) BEGIN
    PRINT 'Dropping ' + @ReceiveName + ' ...';
    EXEC ('DROP PROCEDURE [{0}].[' + @ReceiveName + ']')
    IF (0 < @@ERROR) BEGIN
        EXEC sp_releaseapplock @Resource = @ChannelName, @LockOwner = 'Session'
        EXEC sp_releaseapplock @Resource = 'SSBMB', @LockOwner = 'Session'
        RAISERROR ('Dropping ReceiveProc', 11, 1)
        RETURN
    END
END

DELETE FROM [{0}].Channels WHERE ChannelName = @ChannelName

EXEC sp_releaseapplock @Resource = @ChannelName, @LockOwner = 'Session'
EXEC sp_releaseapplock @Resource = 'SSBMB', @LockOwner = 'Session'