ALTER PROCEDURE [{0}].[Unsubscribe] (
    @TopicName SYSNAME, 
    @SubscriptionName SYSNAME
)
WITH EXECUTE AS OWNER
AS
    SET NOCOUNT ON

    IF (@@TRANCOUNT <> 0) BEGIN
        RAISERROR ('AMBIENT TRANSACTION NOT ALLOWED', 11, 1)
        RETURN
    END

    DECLARE
        @LastError INT,
        @Message NVARCHAR(1024),
        @LockStatus INT

    -- AppLock on the string 'SSBMB' for the remainder of this connection session
    EXEC @LockStatus = sp_getapplock @Resource = 'SSBMB', @LockMode = 'SHARED', @LockTimeout = 0, @LockOwner = 'Session'
    SELECT @LastError = @@ERROR

    IF (0 < @LastError OR @LockStatus < 0) BEGIN -- SSBMB is in use
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

    -- AppLock on the string of the Subscription name for the remainder of this connection session
    EXEC @LockStatus = sp_getapplock @Resource = @SubscriptionName, @LockMode = 'EXCLUSIVE', @LockTimeout = 0, @LockOwner = 'Session'
    SELECT @LastError = @@ERROR

    IF (0 < @LastError OR @LockStatus < 0) BEGIN -- Subscription is in use
        SELECT @Message = 'Lock on ' + @SubscriptionName + ' unsuccessful: ' +
            (CASE
                WHEN 0 < @LastError   THEN '(Statement Error) ' + (SELECT [text] FROM sys.messages WHERE message_id = @LastError)
                WHEN @LockStatus = -1 THEN 'TIMEOUT (Subscription is already locked)'
                WHEN @LockStatus = -2 THEN 'CANCELED'
                WHEN @LockStatus = -3 THEN 'DEADLOCK'
                ELSE 'OTHER' END)
        EXEC sp_releaseapplock @Resource = @TopicName, @LockOwner = 'Session'
        EXEC sp_releaseapplock @Resource = 'SSBMB', @LockOwner = 'Session'
        RAISERROR (@Message, 11, 1)
        RETURN
    END

    BEGIN TRAN

    IF (NOT EXISTS (SELECT 1 FROM [{0}].[Subscriptions] WHERE Fixed = 1 AND TopicName = @TopicName AND SubscriptionName = @SubscriptionName)) BEGIN
        EXEC sp_releaseapplock @Resource = @SubscriptionName, @LockOwner = 'Session'
        EXEC sp_releaseapplock @Resource = @TopicName, @LockOwner = 'Session'
        EXEC sp_releaseapplock @Resource = 'SSBMB', @LockOwner = 'Session'
        RAISERROR ('Subscription not found', 11, 1)
        ROLLBACK
        RETURN
    END
    
    DECLARE @SubscribedServiceName SYSNAME = @SubscriptionName + '_SubscribedService'
    DECLARE @PrimaryQueueName SYSNAME = @SubscriptionName + '_PrimaryQueue'
    DECLARE @ControlQueueName SYSNAME = @SubscriptionName + '_ControlQueue'
    DECLARE @ControlHandlerName SYSNAME = @SubscriptionName + '_ControlHandler'
    DECLARE @ListenName SYSNAME = @SubscriptionName + '_Listen'

    -- Services
    IF EXISTS (SELECT name FROM sys.services WHERE name = @SubscribedServiceName) BEGIN
        PRINT 'Dropping ' + @SubscribedServiceName + ' ...';
        EXEC ('DROP SERVICE [' + @SubscribedServiceName + ']')
        IF (0 < @@ERROR) BEGIN
            EXEC sp_releaseapplock @Resource = @SubscriptionName, @LockOwner = 'Session'
            EXEC sp_releaseapplock @Resource = @TopicName, @LockOwner = 'Session'
            EXEC sp_releaseapplock @Resource = 'SSBMB', @LockOwner = 'Session'
            RAISERROR ('Dropping SubscribedService', 11, 1)
            RETURN
        END
    END

    -- Queues
    IF EXISTS (SELECT name FROM sys.service_queues WHERE name = @PrimaryQueueName) BEGIN
        PRINT 'Dropping ' + @PrimaryQueueName + ' ...';
        EXEC ('DROP QUEUE [{0}].[' + @PrimaryQueueName + ']')
        IF (0 < @@ERROR) BEGIN
            EXEC sp_releaseapplock @Resource = @SubscriptionName, @LockOwner = 'Session'
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
            EXEC sp_releaseapplock @Resource = @SubscriptionName, @LockOwner = 'Session'
            EXEC sp_releaseapplock @Resource = @TopicName, @LockOwner = 'Session'
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
            EXEC sp_releaseapplock @Resource = @SubscriptionName, @LockOwner = 'Session'
            EXEC sp_releaseapplock @Resource = @TopicName, @LockOwner = 'Session'
            EXEC sp_releaseapplock @Resource = 'SSBMB', @LockOwner = 'Session'
            RAISERROR ('Dropping ControlReceiveHandler', 11, 1)
            RETURN
        END
    END

    -- Procs
    IF EXISTS (SELECT name FROM sys.procedures WHERE name = @ListenName) BEGIN
        PRINT 'Dropping ' + @ListenName + ' ...';
        EXEC ('DROP PROCEDURE [{0}].[' + @ListenName + ']')
        IF (0 < @@ERROR) BEGIN
            EXEC sp_releaseapplock @Resource = @SubscriptionName, @LockOwner = 'Session'
            EXEC sp_releaseapplock @Resource = @TopicName, @LockOwner = 'Session'
            EXEC sp_releaseapplock @Resource = 'SSBMB', @LockOwner = 'Session'
            RAISERROR ('Dropping Listen', 11, 1)
            RETURN
        END
    END

    DELETE FROM [{0}].Subscriptions WHERE Fixed = 1 AND TopicName = @TopicName AND SubscriptionName = @SubscriptionName

    COMMIT
    
    EXEC sp_releaseapplock @Resource = @SubscriptionName, @LockOwner = 'Session'
    EXEC sp_releaseapplock @Resource = @TopicName, @LockOwner = 'Session'
    EXEC sp_releaseapplock @Resource = 'SSBMB', @LockOwner = 'Session'