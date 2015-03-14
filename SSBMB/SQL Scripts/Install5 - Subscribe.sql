ALTER PROCEDURE [{0}].[Subscribe] (
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
        @Fixed BIT = CASE WHEN @SubscriptionName IS NULL THEN 0 ELSE 1 END,
        @LastError INT,
        @Message NVARCHAR(1024),
        @LockStatus INT

    SELECT @SubscriptionName = COALESCE(@SubscriptionName, CAST(NEWID() AS SYSNAME))

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

    IF @Fixed = 0 BEGIN -- CLEANUP
        DECLARE @LockedSubscriptions TABLE (
            TopicName SYSNAME,
            SubscriptionName SYSNAME
        )

        DECLARE @AbandonedSubscriptionTopicName SYSNAME, @AbandonedSubscriptionName SYSNAME, @LocksFailed BIT = 0, @RemovalIncomplete BIT = 0
        DECLARE AbandonedSubscriptionNameCursor CURSOR STATIC FOR
            SELECT 
                TopicName,
                SubscriptionName 
            FROM [{0}].[Subscriptions] WITH (NOLOCK)
            WHERE 
                Fixed = 0 AND 
                TopicName = @TopicName AND
                SubscriptionName != @SubscriptionName

        OPEN AbandonedSubscriptionNameCursor
        FETCH NEXT FROM AbandonedSubscriptionNameCursor INTO @AbandonedSubscriptionTopicName, @AbandonedSubscriptionName

        WHILE @LocksFailed= 0 AND @@FETCH_STATUS = 0 BEGIN
            PRINT 'Locking on abandoned ' + @AbandonedSubscriptionName
            EXEC @LockStatus = sp_getapplock @Resource = @AbandonedSubscriptionName, @LockMode = 'EXCLUSIVE', @LockTimeout = 0

            IF (0 < @@ERROR) BEGIN
                SELECT @LocksFailed = 1
            END

            IF (@LockStatus <> -1) BEGIN -- <> TIMEOUT (Abandoned)
                INSERT INTO @LockedSubscriptions
                SELECT TopicName = @AbandonedSubscriptionTopicName, SubscriptionName = @AbandonedSubscriptionName
            END

            FETCH NEXT FROM AbandonedSubscriptionNameCursor INTO @AbandonedSubscriptionTopicName, @AbandonedSubscriptionName
        END

        CLOSE AbandonedSubscriptionNameCursor
        DEALLOCATE AbandonedSubscriptionNameCursor

        DECLARE LockedSubscriptionNameCursor CURSOR FOR
            SELECT 
                TopicName,
                SubscriptionName 
            FROM @LockedSubscriptions

        IF @LocksFailed= 0 BEGIN
            OPEN LockedSubscriptionNameCursor
            FETCH NEXT FROM LockedSubscriptionNameCursor INTO @AbandonedSubscriptionTopicName, @AbandonedSubscriptionName

            WHILE @@FETCH_STATUS = 0 BEGIN
                -- Services
                IF EXISTS (SELECT name FROM sys.services WHERE name = @AbandonedSubscriptionName + '_SubscribedService') BEGIN
                    PRINT 'Dropping abandoned ' + @AbandonedSubscriptionName + '_SubscribedService ...';
                    EXEC ('DROP SERVICE [' + @AbandonedSubscriptionName + '_SubscribedService]')
                    IF (0 < @@ERROR) BEGIN SELECT @RemovalIncomplete = 1; PRINT 'An error occurred' END ELSE PRINT 'OK'
                END

                -- Queues
                IF EXISTS (SELECT name FROM sys.service_queues WHERE name = @AbandonedSubscriptionName + '_PrimaryQueue') BEGIN
                    PRINT 'Dropping abandoned ' + @AbandonedSubscriptionName + '_PrimaryQueue ...';
                    EXEC ('DROP QUEUE [{0}].[' + @AbandonedSubscriptionName + '_PrimaryQueue]')
                    IF (0 < @@ERROR) BEGIN SELECT @RemovalIncomplete = 1; PRINT 'An error occurred' END ELSE PRINT 'OK'
                END

                IF EXISTS (SELECT name FROM sys.service_queues WHERE name = @AbandonedSubscriptionName + '_ControlQueue') BEGIN
                    PRINT 'Dropping abandoned ' + @AbandonedSubscriptionName + '_ControlQueue ...';
                    EXEC ('DROP QUEUE [{0}].[' + @AbandonedSubscriptionName + '_ControlQueue]')
                    IF (0 < @@ERROR) BEGIN SELECT @RemovalIncomplete = 1; PRINT 'An error occurred' END ELSE PRINT 'OK'
                END

                -- Activation Procedure (For Ending Conversations)
                IF EXISTS (SELECT name FROM sys.procedures WHERE name = @AbandonedSubscriptionName + '_ControlHandler') BEGIN
                    PRINT 'Dropping abandoned ' + @AbandonedSubscriptionName + '_ControlHandler ...';
                    EXEC ('DROP PROCEDURE [{0}].[' + @AbandonedSubscriptionName + '_ControlHandler]')
                    IF (0 < @@ERROR) BEGIN SELECT @RemovalIncomplete = 1; PRINT 'An error occurred' END ELSE PRINT 'OK'
                END

                IF EXISTS (SELECT name FROM sys.procedures WHERE name = @AbandonedSubscriptionName + '_Listen') BEGIN
                    PRINT 'Dropping abandoned ' + @AbandonedSubscriptionName + '_Listen ...';
                    EXEC ('DROP PROCEDURE [{0}].[' + @AbandonedSubscriptionName + '_Listen]')
                    IF (0 < @@ERROR) BEGIN SELECT @RemovalIncomplete = 1; PRINT 'An error occurred' END ELSE PRINT 'OK'
                END

                IF @RemovalIncomplete = 0 BEGIN
                    PRINT 'Deleting subscription ' + @AbandonedSubscriptionName + ' ...';
                    DELETE FROM [{0}].[Subscriptions] WHERE TopicName = @AbandonedSubscriptionTopicName AND Fixed = 0 AND SubscriptionName = @AbandonedSubscriptionName
                    IF (@@ROWCOUNT = 0) BEGIN SELECT @RemovalIncomplete = 1; PRINT 'An error occurred' END ELSE PRINT 'OK'
                END

                FETCH NEXT FROM LockedSubscriptionNameCursor INTO @AbandonedSubscriptionTopicName, @AbandonedSubscriptionName
            END

            CLOSE LockedSubscriptionNameCursor
        END -- LocksFailed = 0
        
        OPEN LockedSubscriptionNameCursor -- Reset
        FETCH NEXT FROM LockedSubscriptionNameCursor INTO @AbandonedSubscriptionTopicName, @AbandonedSubscriptionName

        WHILE @@FETCH_STATUS = 0 BEGIN
            EXEC sp_releaseapplock @Resource = @AbandonedSubscriptionName
            FETCH NEXT FROM LockedSubscriptionNameCursor INTO @AbandonedSubscriptionTopicName, @AbandonedSubscriptionName
        END

        CLOSE LockedSubscriptionNameCursor
        DEALLOCATE LockedSubscriptionNameCursor

        IF @LocksFailed != 0 OR @RemovalIncomplete != 0 BEGIN
            RAISERROR ('Cleanup Attempts Failed', 11, 1)
            COMMIT
            EXEC sp_releaseapplock @Resource = 'SSBMB', @LockOwner = 'Session'
            RETURN
        END

    END -- CLEANUP

    --
    -- Set up new queue mechanisms if it is not just being reacquired from a temporary disconnection
    --

    IF (EXISTS (SELECT 1 FROM [{0}].[Subscriptions] WHERE SubscriptionName = @SubscriptionName)) BEGIN
        EXEC sp_releaseapplock @Resource = @SubscriptionName, @LockOwner = 'Session'
        EXEC sp_releaseapplock @Resource = @TopicName, @LockOwner = 'Session'
        EXEC sp_releaseapplock @Resource = 'SSBMB', @LockOwner = 'Session'
        RAISERROR ('Subscription already exists', 11, 1)
        COMMIT
        RETURN
    END
    
    DECLARE @BroadcastingServiceName SYSNAME = @TopicName + '_BroadcastingService' -- Created with the Topic
    DECLARE @SubscribedServiceName SYSNAME = @SubscriptionName + '_SubscribedService'
    DECLARE @PrimaryQueueName SYSNAME = @SubscriptionName + '_PrimaryQueue'
    DECLARE @ControlQueueName SYSNAME = @SubscriptionName + '_ControlQueue'
    DECLARE @ControlHandlerName SYSNAME = @SubscriptionName + '_ControlHandler'
    DECLARE @ListenName SYSNAME = @SubscriptionName + '_Listen'

    DECLARE @ControlHandler NVARCHAR(MAX) = CAST('' AS NVARCHAR(MAX)) + '
CREATE PROCEDURE [{0}].[' + @ControlHandlerName + '] AS
    DECLARE @ConversationHandle UNIQUEIDENTIFIER, @MessageTypeName NVARCHAR(256);

    WHILE (1=1) BEGIN
        WAITFOR (RECEIVE TOP (1)
            @ConversationHandle = conversation_handle, @MessageTypeName = message_type_name
        FROM [{0}].[' + @ControlQueueName + ']), TIMEOUT 15000

        IF (0 < @@ROWCOUNT AND @MessageTypeName = ''http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog'') BEGIN
            END CONVERSATION @ConversationHandle;
        END
    END';

    DECLARE @Listen NVARCHAR(MAX) = CAST('' AS NVARCHAR(MAX)) + '
CREATE PROCEDURE [{0}].[' + @ListenName + ']
    WITH EXECUTE AS OWNER
    AS
    SET NOCOUNT ON

    IF (@@TRANCOUNT <> 0) BEGIN
        RAISERROR (''AMBIENT TRANSACTION NOT ALLOWED'', 11, 1)
        RETURN
    END

    DECLARE
        @TopicName SYSNAME = ''' + @TopicName + ''',
        @SubscriptionName SYSNAME = ''' + @SubscriptionName + ''',
        @LastError INT,
        @Message NVARCHAR(1024),
        @LockStatus INT

    -- AppLock on the string ''SSBMB''
    EXEC @LockStatus = sp_getapplock @Resource = ''SSBMB'', @LockMode = ''SHARED'', @LockTimeout = 0, @LockOwner = ''Session''
    SELECT @LastError = @@ERROR

    IF (0 < @LastError OR @LockStatus < 0) BEGIN -- SSBMB is exclusively locked
        SELECT @Message = ''Lock on SSBMB unsuccessful: '' +
            (CASE
                WHEN 0 < @LastError   THEN ''(Statement Error) '' + (SELECT [text] FROM sys.messages WHERE message_id = @LastError)
                WHEN @LockStatus = -1 THEN ''TIMEOUT (SSBMB is in use)''
                WHEN @LockStatus = -2 THEN ''CANCELED''
                WHEN @LockStatus = -3 THEN ''DEADLOCK''
                ELSE ''OTHER'' END)
        RAISERROR (@Message, 11, 1)
        RETURN
    END

    -- AppLock on the string of the Topic
    EXEC @LockStatus = sp_getapplock @Resource = @TopicName, @LockMode = ''SHARED'', @LockTimeout = 0, @LockOwner = ''Session''
    SELECT @LastError = @@ERROR

    IF (0 < @LastError OR @LockStatus < 0) BEGIN -- Topic is exclusively locked
        SELECT @Message = ''Lock on '' + @TopicName + '' unsuccessful: '' +
            (CASE
                WHEN 0 < @LastError   THEN ''(Statement Error) '' + (SELECT [text] FROM sys.messages WHERE message_id = @LastError)
                WHEN @LockStatus = -1 THEN ''TIMEOUT (Topic is exclusively locked)''
                WHEN @LockStatus = -2 THEN ''CANCELED''
                WHEN @LockStatus = -3 THEN ''DEADLOCK''
                ELSE ''OTHER'' END)
        EXEC sp_releaseapplock @Resource = ''SSBMB'', @LockOwner = ''Session''
        RAISERROR (@Message, 11, 1)
        RETURN
    END

    -- AppLock on the string of the Subscription name
    EXEC @LockStatus = sp_getapplock @Resource = @SubscriptionName, @LockMode = ''EXCLUSIVE'', @LockTimeout = 0, @LockOwner = ''Session''
    SELECT @LastError = @@ERROR

    IF (0 < @LastError OR @LockStatus < 0) BEGIN -- Subscription is in use
        SELECT @Message = ''Lock on '' + @SubscriptionName + '' unsuccessful: '' +
            (CASE
                WHEN 0 < @LastError   THEN ''(Statement Error) '' + (SELECT [text] FROM sys.messages WHERE message_id = @LastError)
                WHEN @LockStatus = -1 THEN ''TIMEOUT (Subscription is already locked)''
                WHEN @LockStatus = -2 THEN ''CANCELED''
                WHEN @LockStatus = -3 THEN ''DEADLOCK''
                ELSE ''OTHER'' END)
        EXEC sp_releaseapplock @Resource = @TopicName, @LockOwner = ''Session''
        EXEC sp_releaseapplock @Resource = ''SSBMB'', @LockOwner = ''Session''
        RAISERROR (@Message, 11, 1)
        RETURN
    END

    SELECT TOP 0 1

    -- Loop to listen for events
    WHILE (1=1) BEGIN

        RAISERROR (''FLUSH'', 1, 1) WITH NOWAIT

        ;DECLARE
            @ConversationHandle UNIQUEIDENTIFIER,
            @MessageTypeName SYSNAME,
            @MessageBody NVARCHAR(MAX)

        ;WAITFOR(
            RECEIVE TOP (1) @ConversationHandle = conversation_handle, @MessageTypeName = message_type_name, @MessageBody = message_body
            FROM [{0}].[' + @PrimaryQueueName + ']
        ), TIMEOUT 15000

        IF (0 < @@ROWCOUNT) BEGIN
            IF (@MessageTypeName = ''SerializedMessage'') BEGIN
                SELECT @MessageBody AS MessageBody
            END ELSE IF (@MessageTypeName = ''http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog'') BEGIN
                END CONVERSATION @ConversationHandle
                SELECT @Message = ''Conversation Terminated'' -- Not Expected
                RAISERROR (@Message, 11, 1)
                RETURN
            END ELSE BEGIN
                SELECT ''Unknown'' AS EventType
            END

            IF (0 < @@ERROR) BEGIN
                SELECT @Message = ''Error processing message of type '' + @MessageTypeName + '': '' + CAST(@MessageBody AS VARCHAR(MAX))
                RAISERROR (@Message, 11, 1)
                RETURN
            END
        END ELSE BEGIN
            SELECT TOP 0 1; -- Allow the blocking call to spin anyway
        END
    END

    ;END CONVERSATION @ConversationHandle -- This will never be reached.  But if it were, this is what should be done';

    SELECT @Message = NULL

    ;WITH FailIfExists ([Name]) AS
    (
        SELECT SubscriptionName AS Name FROM [{0}].Subscriptions WHERE SubscriptionName = @SubscriptionName UNION ALL
        SELECT name             AS Name FROM sys.services WHERE name = @SubscribedServiceName UNION ALL
        SELECT name             AS Name FROM sys.services WHERE name = @SubscribedServiceName UNION ALL
        SELECT name             AS Name FROM sys.service_queues WHERE name = @PrimaryQueueName UNION ALL
        SELECT name             AS Name FROM sys.service_queues WHERE name = @ControlQueueName UNION ALL
        SELECT name             AS Name FROM sys.procedures WHERE name = @ControlHandlerName UNION ALL
        SELECT name             AS Name FROM sys.procedures WHERE name = @ListenName
    )
    SELECT @Message = COALESCE(@Message + ', ', 'These items already exist: ') + Name -- could get truncated, but that's OK
    FROM FailIfExists

    IF (@Message IS NOT NULL) BEGIN
        COMMIT
        EXEC sp_releaseapplock @Resource = @TopicName, @LockOwner = 'Session'
        EXEC sp_releaseapplock @Resource = 'SSBMB', @LockOwner = 'Session'
        RAISERROR (@Message, 11, 1)
        RETURN
    END

    EXEC (@ControlHandler)
    IF (0 < @@ERROR) BEGIN
        COMMIT
        EXEC sp_releaseapplock @Resource = @TopicName, @LockOwner = 'Session'
        EXEC sp_releaseapplock @Resource = 'SSBMB', @LockOwner = 'Session'
        RAISERROR ('ControlHandler Setup', 11, 1)
        RETURN
    END

    EXEC (@Listen)
    IF (0 < @@ERROR) BEGIN
        COMMIT
        EXEC ('DROP PROCEDURE [{0}].[' + @ControlHandlerName + ']')
        EXEC sp_releaseapplock @Resource = @TopicName, @LockOwner = 'Session'
        EXEC sp_releaseapplock @Resource = 'SSBMB', @LockOwner = 'Session'
        RAISERROR ('Listen Setup', 11, 1)
        RETURN
    END

    EXEC ('GRANT EXECUTE ON [{0}].[' + @ListenName + '] TO [{1}]')
    IF (0 < @@ERROR) BEGIN
        COMMIT
        EXEC ('DROP PROCEDURE [{0}].[' + @ControlHandlerName + ']')
        EXEC ('DROP PROCEDURE [{0}].[' + @ListenName + ']')
        EXEC sp_releaseapplock @Resource = @TopicName, @LockOwner = 'Session'
        EXEC sp_releaseapplock @Resource = 'SSBMB', @LockOwner = 'Session'
        RAISERROR ('Listen Permissions', 11, 1)
        RETURN
    END

    -- EXEC ('CREATE QUEUE [{0}].[' + @PrimaryQueueName + '] WITH POISON_MESSAGE_HANDLING (STATUS = OFF)')  -- SQL 2008R2+ ONLY
    EXEC ('CREATE QUEUE [{0}].[' + @PrimaryQueueName + ']') -- SQL 2008- ONLY
    IF (0 < @@ERROR) BEGIN
        COMMIT
        EXEC ('DROP PROCEDURE [{0}].[' + @ControlHandlerName + ']')
        EXEC ('DROP PROCEDURE [{0}].[' + @ListenName + ']')
        EXEC sp_releaseapplock @Resource = @TopicName, @LockOwner = 'Session'
        EXEC sp_releaseapplock @Resource = 'SSBMB', @LockOwner = 'Session'
        RAISERROR ('PrimaryQueue Setup', 11, 1)
        RETURN
    END
    -- EXEC ('CREATE QUEUE [{0}].[' + @ControlQueueName + '] WITH ACTIVATION (STATUS = ON, PROCEDURE_NAME = [{0}].[' + @ControlHandlerName + '], EXECUTE AS OWNER, MAX_QUEUE_READERS = 1), POISON_MESSAGE_HANDLING (STATUS = OFF)')  -- SQL 2008R2+ ONLY
    EXEC ('CREATE QUEUE [{0}].[' + @ControlQueueName + '] WITH ACTIVATION (STATUS = ON, PROCEDURE_NAME = [{0}].[' + @ControlHandlerName + '], EXECUTE AS OWNER, MAX_QUEUE_READERS = 1)') -- SQL 2008- ONLY
    IF (0 < @@ERROR) BEGIN
        COMMIT
        EXEC ('DROP QUEUE [{0}].[' + @PrimaryQueueName + ']')
        EXEC ('DROP PROCEDURE [{0}].[' + @ControlHandlerName + ']')
        EXEC ('DROP PROCEDURE [{0}].[' + @ListenName + ']')
        EXEC sp_releaseapplock @Resource = @TopicName, @LockOwner = 'Session'
        EXEC sp_releaseapplock @Resource = 'SSBMB', @LockOwner = 'Session'
        RAISERROR ('ControlQueue Setup', 11, 1)
        RETURN
    END

    EXEC ('CREATE SERVICE [' + @SubscribedServiceName + '] AUTHORIZATION [dbo] ON QUEUE [{0}].[' + @PrimaryQueueName + '] (SubscriptionContract)')
    IF (0 < @@ERROR) BEGIN
        COMMIT
        EXEC ('DROP QUEUE [{0}].[' + @ControlQueueName + ']')
        EXEC ('DROP QUEUE [{0}].[' + @PrimaryQueueName + ']')
        EXEC ('DROP PROCEDURE [{0}].[' + @ControlHandlerName + ']')
        EXEC ('DROP PROCEDURE [{0}].[' + @ListenName + ']')
        EXEC sp_releaseapplock @Resource = @TopicName, @LockOwner = 'Session'
        EXEC sp_releaseapplock @Resource = 'SSBMB', @LockOwner = 'Session'
        RAISERROR ('SubscribedService Setup', 11, 1)
        RETURN
    END

    DECLARE @InitiatorDialogID UNIQUEIDENTIFIER
    BEGIN DIALOG CONVERSATION @InitiatorDialogID
    FROM SERVICE @BroadcastingServiceName
    TO SERVICE @SubscribedServiceName
    ON CONTRACT [SubscriptionContract]
    WITH ENCRYPTION = OFF

    --
    -- Add Queue name to table to eventual cleanup
    --

    INSERT INTO [{0}].[Subscriptions]
    SELECT
        @TopicName AS TopicName,
        @SubscriptionName AS SubscriptionName,
        @Fixed AS Fixed,
        @InitiatorDialogID AS InitiatorDialogID

    --
    -- Commit the transaction - This does not rollback the creation of services and queues, but it ensures that the operations on {0}.Subscriptions are consistent
    --

    COMMIT
    
    -- DO NOT release these session locks
    --EXEC sp_releaseapplock @Resource = @SubscriptionName, @LockOwner = 'Session'
    --EXEC sp_releaseapplock @Resource = @TopicName, @LockOwner = 'Session'
    --EXEC sp_releaseapplock @Resource = 'SSBMB', @LockOwner = 'Session'

    SELECT @SubscriptionName