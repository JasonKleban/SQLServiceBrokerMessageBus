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
EXEC @LockStatus = sp_getapplock @Resource = @TopicName, @LockMode = 'EXCLUSIVE', @LockTimeout = 0, @LockOwner = 'Session'
SELECT @LastError = @@ERROR

IF (0 < @LastError OR @LockStatus < 0) BEGIN -- Topic is in use
    SELECT @Message = 'Lock on ' + @TopicName + ' unsuccessful: ' +
        (CASE
            WHEN 0 < @LastError   THEN '(Statement Error) ' + (SELECT [text] FROM sys.messages WHERE message_id = @LastError)
            WHEN @LockStatus = -1 THEN 'TIMEOUT (Topic is already locked)'
            WHEN @LockStatus = -2 THEN 'CANCELED'
            WHEN @LockStatus = -3 THEN 'DEADLOCK'
            ELSE 'OTHER' END)
    EXEC sp_releaseapplock @Resource = 'SSBMB', @LockOwner = 'Session'
    RAISERROR (@Message, 11, 1)
    RETURN
END

DECLARE @AnnouncingServiceName SYSNAME = @TopicName + '_AnnouncingService'
DECLARE @BroadcastingServiceName SYSNAME = @TopicName + '_BroadcastingService'
DECLARE @PrimaryQueueName SYSNAME = @TopicName + '_PrimaryQueue'
DECLARE @ControlQueueName SYSNAME = @TopicName + '_ControlQueue'

DECLARE @ControlHandlerName SYSNAME = @TopicName + '_ControlReceiveHandler'
DECLARE @ControlHandler NVARCHAR(MAX) = CAST('' AS NVARCHAR(MAX)) + '
CREATE PROCEDURE [{0}].[' + @ControlHandlerName + ']
WITH EXECUTE AS OWNER
AS
    DECLARE @ConversationHandle UNIQUEIDENTIFIER, @MessageTypeName NVARCHAR(256), @MessageBody NVARCHAR(MAX);

    WHILE (1=1) BEGIN
        BEGIN TRAN

        ;WAITFOR(
            RECEIVE TOP (1)
                @ConversationHandle = conversation_handle, @MessageTypeName = message_type_name, @MessageBody = message_body
            FROM [{0}].[' + @ControlQueueName + ']
        ), TIMEOUT 15000

        IF (0 < @@ROWCOUNT AND @MessageTypeName = ''http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog'') BEGIN
           END CONVERSATION @ConversationHandle;
        END

        COMMIT
    END';

DECLARE @BroadcastHandlerName SYSNAME = @TopicName + '_BroadcastHandler'
DECLARE @BroadcastHandler NVARCHAR(MAX) = CAST('' AS NVARCHAR(MAX)) + '
CREATE PROCEDURE [{0}].[' + @BroadcastHandlerName + '] AS
    DECLARE @ConversationHandle UNIQUEIDENTIFIER, @MessageTypeName NVARCHAR(256), @MessageBody NVARCHAR(MAX);

    WHILE (1=1) BEGIN
        BEGIN TRAN

        ;WAITFOR(
            RECEIVE TOP (1)
                @ConversationHandle = conversation_handle, @MessageTypeName = message_type_name, @MessageBody = message_body
            FROM [{0}].[' + @PrimaryQueueName + ']
        ), TIMEOUT 15000

        IF (0 < @@ROWCOUNT) BEGIN
            IF (@MessageTypeName = ''http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog'') BEGIN
                END CONVERSATION @ConversationHandle;
            END ELSE IF (@MessageTypeName = ''SerializedMessage'') BEGIN
                -- Broadcast this message to each registered subscription
                DECLARE @SubscriptionName NVARCHAR(36), @InitiatorDialogID UNIQUEIDENTIFIER
                DECLARE SubscriptionCursor CURSOR STATIC FOR
                SELECT SubscriptionName, [InitiatorDialogID] FROM [{0}].[Subscriptions] WHERE TopicName = ''' + @TopicName + '''

                OPEN SubscriptionCursor
                FETCH NEXT FROM SubscriptionCursor INTO @SubscriptionName, @InitiatorDialogID

                WHILE @@FETCH_STATUS = 0 BEGIN
                    ;SEND ON CONVERSATION @InitiatorDialogID
                    MESSAGE TYPE [SerializedMessage] (@MessageBody)

                    FETCH NEXT FROM SubscriptionCursor INTO @SubscriptionName, @InitiatorDialogID
                END

                CLOSE SubscriptionCursor
                DEALLOCATE SubscriptionCursor
            END
        END

        COMMIT
    END';

DECLARE @AnnounceName SYSNAME = @TopicName + '_Announce'
DECLARE @Announce NVARCHAR(MAX) = CAST('' AS NVARCHAR(MAX)) + '
CREATE PROCEDURE [{0}].[' + @AnnounceName + '] (@MessageBody NVARCHAR(MAX))
WITH EXECUTE AS OWNER
AS
    SET NOCOUNT ON

    IF (@@TRANCOUNT = 0) BEGIN
        RAISERROR (''AMBIENT TRANSACTION REQUIRED'', 11, 1)
        RETURN
    END

    DECLARE
            @TopicName SYSNAME = ''' + @TopicName + ''',
            @LastError INT,
            @Message NVARCHAR(1024),
            @LockStatus INT

    -- AppLock on the string ''SSBMB'' for the remainder of this connection session
    EXEC @LockStatus = sp_getapplock @Resource = ''SSBMB'', @LockMode = ''SHARED'', @LockTimeout = 0, @LockOwner = ''Transaction''
    SELECT @LastError = @@ERROR

    IF (0 < @LastError OR @LockStatus < 0) BEGIN -- SSBMB is in use
        SELECT @Message = ''Lock on SSBMB unsuccessful: '' +
            (CASE
                WHEN 0 < @LastError   THEN ''(Statement Error) '' + (SELECT [text] FROM sys.messages WHERE message_id = @LastError)
                WHEN @LockStatus = -1 THEN ''TIMEOUT (SSBMB is exclusively locked)''
                WHEN @LockStatus = -2 THEN ''CANCELED''
                WHEN @LockStatus = -3 THEN ''DEADLOCK''
                ELSE ''OTHER'' END)
        RAISERROR (@Message, 11, 1)
        RETURN
    END

    -- AppLock on the string of the Topic for the remainder of this connection session
    EXEC @LockStatus = sp_getapplock @Resource = @TopicName, @LockMode = ''SHARED'', @LockTimeout = 0, @LockOwner = ''Transaction''
    SELECT @LastError = @@ERROR

    IF (0 < @LastError OR @LockStatus < 0) BEGIN -- Topic is in use
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

    DECLARE @InitiatorDialogID UNIQUEIDENTIFIER
    SELECT @InitiatorDialogID = InitiatorDialogID FROM {0}.Topics WHERE TopicName = @TopicName

    ;SEND ON CONVERSATION @InitiatorDialogID
    MESSAGE TYPE [SerializedMessage] (@MessageBody)';

SELECT @Message = NULL

;WITH FailIfExists ([Name]) AS
(
    SELECT TopicName  AS Name FROM [{0}].Topics WHERE TopicName = @TopicName UNION ALL
    SELECT name         AS Name FROM sys.services WHERE name = @AnnouncingServiceName UNION ALL
    SELECT name         AS Name FROM sys.services WHERE name = @BroadcastingServiceName UNION ALL
    SELECT name         AS Name FROM sys.service_queues WHERE name = @PrimaryQueueName UNION ALL
    SELECT name         AS Name FROM sys.service_queues WHERE name = @ControlQueueName UNION ALL
    SELECT name         AS Name FROM sys.procedures WHERE name = @ControlHandlerName UNION ALL
    SELECT name         AS Name FROM sys.procedures WHERE name = @AnnounceName
)
SELECT @Message = COALESCE(@Message + ', ', 'These items already exist: ') + Name -- could get truncated, but that's OK
FROM FailIfExists

IF (@Message IS NOT NULL) BEGIN
    EXEC sp_releaseapplock @Resource = @TopicName, @LockOwner = 'Session'
    EXEC sp_releaseapplock @Resource = 'SSBMB', @LockOwner = 'Session'
    RAISERROR (@Message, 11, 1)
    RETURN
END

EXEC (@ControlHandler)
IF (0 < @@ERROR) BEGIN
    EXEC sp_releaseapplock @Resource = @TopicName, @LockOwner = 'Session'
    EXEC sp_releaseapplock @Resource = 'SSBMB', @LockOwner = 'Session'
    RAISERROR ('ControlReceiveHandler Setup', 11, 1)
    RETURN
END

EXEC (@BroadcastHandler)
IF (0 < @@ERROR) BEGIN
    EXEC ('DROP PROCEDURE [{0}].[' + @ControlHandlerName + ']')
    EXEC sp_releaseapplock @Resource = @TopicName, @LockOwner = 'Session'
    EXEC sp_releaseapplock @Resource = 'SSBMB', @LockOwner = 'Session'
    RAISERROR ('BroadcastHandler Setup', 11, 1)
    RETURN
END

EXEC (@Announce)
IF (0 < @@ERROR) BEGIN
    EXEC ('DROP PROCEDURE [{0}].[' + @BroadcastHandler + ']')
    EXEC ('DROP PROCEDURE [{0}].[' + @ControlHandlerName + ']')
    EXEC sp_releaseapplock @Resource = @TopicName, @LockOwner = 'Session'
    EXEC sp_releaseapplock @Resource = 'SSBMB', @LockOwner = 'Session'
    RAISERROR ('Announce Setup', 11, 1)
    RETURN
END

EXEC ('CREATE QUEUE [{0}].[' + @PrimaryQueueName + '] WITH ACTIVATION (STATUS = ON, PROCEDURE_NAME = [{0}].[' + @BroadcastHandlerName + '], EXECUTE AS OWNER, MAX_QUEUE_READERS = 1)')
IF (0 < @@ERROR) BEGIN
    EXEC ('DROP PROCEDURE [{0}].[' + @AnnounceName + ']')
    EXEC ('DROP PROCEDURE [{0}].[' + @BroadcastHandlerName + ']')
    EXEC ('DROP PROCEDURE [{0}].[' + @ControlHandlerName + ']')
    EXEC sp_releaseapplock @Resource = @TopicName, @LockOwner = 'Session'
    EXEC sp_releaseapplock @Resource = 'SSBMB', @LockOwner = 'Session'
    RAISERROR ('PrimaryQueue Setup', 11, 1)
    RETURN
END

EXEC ('CREATE QUEUE [{0}].[' + @ControlQueueName + '] WITH ACTIVATION (STATUS = ON, PROCEDURE_NAME = [{0}].[' + @ControlHandlerName + '], EXECUTE AS OWNER, MAX_QUEUE_READERS = 1)')
IF (0 < @@ERROR) BEGIN
    EXEC ('DROP QUEUE [{0}].[' + @PrimaryQueueName + ']')
    EXEC ('DROP PROCEDURE [{0}].[' + @AnnounceName + ']')
    EXEC ('DROP PROCEDURE [{0}].[' + @BroadcastHandlerName + ']')
    EXEC ('DROP PROCEDURE [{0}].[' + @ControlHandlerName + ']')
    EXEC sp_releaseapplock @Resource = @TopicName, @LockOwner = 'Session'
    EXEC sp_releaseapplock @Resource = 'SSBMB', @LockOwner = 'Session'
    RAISERROR ('ControlQueue Setup', 11, 1)
    RETURN
END

EXEC ('CREATE SERVICE [' + @BroadcastingServiceName + '] AUTHORIZATION [dbo] ON QUEUE [{0}].[' + @PrimaryQueueName + '] (TopicContract)')
IF (0 < @@ERROR) BEGIN
    EXEC ('DROP QUEUE [{0}].[' + @ControlQueueName + ']')
    EXEC ('DROP QUEUE [{0}].[' + @PrimaryQueueName + ']')
    EXEC ('DROP PROCEDURE [{0}].[' + @AnnounceName + ']')
    EXEC ('DROP PROCEDURE [{0}].[' + @BroadcastHandlerName + ']')
    EXEC sp_releaseapplock @Resource = @TopicName, @LockOwner = 'Session'
    EXEC sp_releaseapplock @Resource = 'SSBMB', @LockOwner = 'Session'
    RAISERROR ('BroadcastingService Setup', 11, 1)
    RETURN
END

EXEC ('CREATE SERVICE [' + @AnnouncingServiceName + '] AUTHORIZATION [dbo] ON QUEUE [{0}].[' + @ControlQueueName + '] (TopicContract)')
IF (0 < @@ERROR) BEGIN
    EXEC ('DROP SERVICE [' + @BroadcastingServiceName + ']')
    EXEC ('DROP QUEUE [{0}].[' + @ControlQueueName + ']')
    EXEC ('DROP QUEUE [{0}].[' + @PrimaryQueueName + ']')
    EXEC ('DROP PROCEDURE [{0}].[' + @AnnounceName + ']')
    EXEC ('DROP PROCEDURE [{0}].[' + @BroadcastHandlerName + ']')
    EXEC sp_releaseapplock @Resource = @TopicName, @LockOwner = 'Session'
    EXEC sp_releaseapplock @Resource = 'SSBMB', @LockOwner = 'Session'
    RAISERROR ('AnnouncingService Setup', 11, 1)
    RETURN
END

DECLARE @InitiatorDialogID UNIQUEIDENTIFIER
BEGIN DIALOG CONVERSATION @InitiatorDialogID
FROM SERVICE @AnnouncingServiceName
TO SERVICE @BroadcastingServiceName
ON CONTRACT [TopicContract]
WITH ENCRYPTION = OFF

INSERT INTO [{0}].Topics
SELECT 
    @TopicName AS TopicName,
    @InitiatorDialogID AS InitiatorDialogID

EXEC ('GRANT EXECUTE ON [{0}].[' + @AnnounceName + '] TO [{1}]')

EXEC sp_releaseapplock @Resource = @TopicName, @LockOwner = 'Session'
EXEC sp_releaseapplock @Resource = 'SSBMB', @LockOwner = 'Session'