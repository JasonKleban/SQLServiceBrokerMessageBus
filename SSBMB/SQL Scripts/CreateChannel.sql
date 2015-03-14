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

-- AppLock on the string of the QueueName for the remainder of this connection session
EXEC @LockStatus = sp_getapplock @Resource = @ChannelName, @LockMode = 'EXCLUSIVE', @LockTimeout = 0, @LockOwner = 'Session'
SELECT @LastError = @@ERROR

IF (0 < @LastError OR @LockStatus < 0) BEGIN -- Channel is exclusively locked
    SELECT @Message = 'Lock on ' + @ChannelName + ' unsuccessful: ' +
        (CASE
            WHEN 0 < @LastError   THEN '(Statement Error) ' + (SELECT [text] FROM sys.messages WHERE message_id = @LastError)
            WHEN @LockStatus = -1 THEN 'TIMEOUT (Channel is already locked)'
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

        IF (0 < @@rowcount AND @MessageTypeName = ''http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog'') BEGIN
           END CONVERSATION @ConversationHandle;
        END

        COMMIT
    END';

DECLARE @ReceiveName SYSNAME = @ChannelName + '_Receive'
DECLARE @Receive NVARCHAR(MAX) = CAST('' AS NVARCHAR(MAX)) + '
CREATE PROCEDURE [{0}].[' + @ReceiveName + ']
WITH EXECUTE AS OWNER
AS
    SET NOCOUNT ON

    IF (@@TRANCOUNT = 0) BEGIN
        RAISERROR (''AMBIENT TRANSACTION REQUIRED'', 11, 1)
        RETURN
    END

    DECLARE
            @ChannelName NVARCHAR(128) = ''' + @ChannelName + ''',
            @LastError INT,
            @Message NVARCHAR(1024),
            @LockStatus INT

    -- AppLock on the string ''SSBMB'' for the remainder of this connection session
    EXEC @LockStatus = sp_getapplock @Resource = ''SSBMB'', @LockMode = ''SHARED'', @LockTimeout = 0, @LockOwner = ''Transaction''
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

    -- AppLock on the string of the QueueName for the remainder of this connection session
    EXEC @LockStatus = sp_getapplock @Resource = @ChannelName, @LockMode = ''SHARED'', @LockTimeout = 0, @LockOwner = ''Transaction''
    SELECT @LastError = @@ERROR

    IF (0 < @LastError OR @LockStatus < 0) BEGIN -- Channel is exclusively locked
        SELECT @Message = ''Lock on '' + @ChannelName + '' unsuccessful: '' +
            (CASE
                WHEN 0 < @LastError   THEN ''(Statement Error) '' + (SELECT [text] FROM sys.messages WHERE message_id = @LastError)
                WHEN @LockStatus = -1 THEN ''TIMEOUT (Channel is exclusively locked)''
                WHEN @LockStatus = -2 THEN ''CANCELED''
                WHEN @LockStatus = -3 THEN ''DEADLOCK''
                ELSE ''OTHER'' END)
        RAISERROR (@Message, 11, 1)
        RETURN
    END

    RAISERROR (''FLUSH'', 1, 1) WITH NOWAIT

    ;DECLARE
        @ConversationHandle UNIQUEIDENTIFIER,
        @MessageTypeName SYSNAME,
        @MessageBody NVARCHAR(MAX)

    ;WAITFOR(
        RECEIVE TOP (1) @ConversationHandle = conversation_handle, @MessageTypeName = message_type_name, @MessageBody = message_body
        FROM [{0}].[' + @PrimaryQueueName + ']
    ), TIMEOUT 15000

    IF (@MessageTypeName = ''SerializedMessage'') BEGIN
        SELECT
             @MessageBody AS MessageBody
            ,@ConversationHandle AS ConversationHandle

        ;END CONVERSATION @ConversationHandle
    END ELSE IF (@MessageTypeName = ''http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog'') BEGIN
        END CONVERSATION @ConversationHandle
    END

    IF (0 < @@ERROR) BEGIN
        SELECT @Message = ''Error receiving message of type '' + @MessageTypeName + '': '' + CAST(@MessageBody AS VARCHAR(MAX))
        RAISERROR (@Message, 11, 1)
        RETURN
    END';

DECLARE @SendName SYSNAME = @ChannelName + '_Send'
DECLARE @Send NVARCHAR(MAX) = CAST('' AS NVARCHAR(MAX)) + '
CREATE PROCEDURE [{0}].[' + @SendName + '] (@MessageBody NVARCHAR(MAX))
WITH EXECUTE AS OWNER
AS
    SET NOCOUNT ON

    IF (@@TRANCOUNT = 0) BEGIN
        RAISERROR (''AMBIENT TRANSACTION REQUIRED'', 11, 1)
        RETURN
    END

    DECLARE
            @ChannelName NVARCHAR(128) = ''' + @ChannelName + ''',
            @LastError INT,
            @Message NVARCHAR(1024),
            @LockStatus INT

    -- AppLock on the string ''SSBMB'' for the remainder of this connection session
    EXEC @LockStatus = sp_getapplock @Resource = ''SSBMB'', @LockMode = ''SHARED'', @LockTimeout = 0, @LockOwner = ''Transaction''
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

    -- AppLock on the string of the QueueName for the remainder of this connection session
    EXEC @LockStatus = sp_getapplock @Resource = @ChannelName, @LockMode = ''SHARED'', @LockTimeout = 0, @LockOwner = ''Transaction''
    SELECT @LastError = @@ERROR

    IF (0 < @LastError OR @LockStatus < 0) BEGIN -- Channel is exclusively locked
        SELECT @Message = ''Lock on '' + @ChannelName + '' unsuccessful: '' +
            (CASE
                WHEN 0 < @LastError   THEN ''(Statement Error) '' + (SELECT [text] FROM sys.messages WHERE message_id = @LastError)
                WHEN @LockStatus = -1 THEN ''TIMEOUT (Channel is exclusively locked)''
                WHEN @LockStatus = -2 THEN ''CANCELED''
                WHEN @LockStatus = -3 THEN ''DEADLOCK''
                ELSE ''OTHER'' END)
        RAISERROR (@Message, 11, 1)
        RETURN
    END

    DECLARE @SendingServiceName SYSNAME = ''' + @IssuingServiceName + '''
    DECLARE @ReceivingServiceName SYSNAME = ''' + @ReceivingServiceName + '''

    DECLARE @InitiatorDialogID UNIQUEIDENTIFIER
    BEGIN DIALOG CONVERSATION @InitiatorDialogID
    FROM SERVICE @SendingServiceName
    TO SERVICE @ReceivingServiceName
    ON CONTRACT [ChannelContract]
    WITH ENCRYPTION = OFF

    ;SEND ON CONVERSATION @InitiatorDialogID
    MESSAGE TYPE [SerializedMessage] (@MessageBody)';

SELECT @Message = NULL

;WITH FailIfExists ([Name]) AS
(
    SELECT ChannelName  AS Name FROM [{0}].Channels WHERE ChannelName = @ChannelName UNION ALL
    SELECT name         AS Name FROM sys.services WHERE name = @IssuingServiceName UNION ALL
    SELECT name         AS Name FROM sys.services WHERE name = @ReceivingServiceName UNION ALL
    SELECT name         AS Name FROM sys.service_queues WHERE name = @PrimaryQueueName UNION ALL
    SELECT name         AS Name FROM sys.service_queues WHERE name = @ControlQueueName UNION ALL
    SELECT name         AS Name FROM sys.procedures WHERE name = @ControlHandlerName UNION ALL
    SELECT name         AS Name FROM sys.procedures WHERE name = @ReceiveName UNION ALL
    SELECT name         AS Name FROM sys.procedures WHERE name = @SendName
)
SELECT @Message = COALESCE(@Message + ', ', 'These items already exist: ') + Name -- could get truncated, but that's OK
FROM FailIfExists

IF (@Message IS NOT NULL) BEGIN
    EXEC sp_releaseapplock @Resource = @ChannelName, @LockOwner = 'Session'
    EXEC sp_releaseapplock @Resource = 'SSBMB', @LockOwner = 'Session'
    RAISERROR (@Message, 11, 1)
    RETURN
END

EXEC (@ControlHandler)
IF (0 < @@ERROR) BEGIN
    EXEC sp_releaseapplock @Resource = @ChannelName, @LockOwner = 'Session'
    EXEC sp_releaseapplock @Resource = 'SSBMB', @LockOwner = 'Session'
    RAISERROR ('ControlReceiveHandler Setup', 11, 1)
    RETURN
END

EXEC (@Receive)
IF (0 < @@ERROR) BEGIN
    EXEC ('DROP PROCEDURE [{0}].[' + @ControlHandlerName + ']')
    EXEC sp_releaseapplock @Resource = @ChannelName, @LockOwner = 'Session'
    EXEC sp_releaseapplock @Resource = 'SSBMB', @LockOwner = 'Session'
    RAISERROR ('ReceiveProc Setup', 11, 1)
    RETURN
END

EXEC (@Send)
IF (0 < @@ERROR) BEGIN
    EXEC ('DROP PROCEDURE [{0}].[' + @ControlHandlerName + ']')
    EXEC ('DROP PROCEDURE [{0}].[' + @ReceiveName + ']')
    EXEC sp_releaseapplock @Resource = @ChannelName, @LockOwner = 'Session'
    EXEC sp_releaseapplock @Resource = 'SSBMB', @LockOwner = 'Session'
    RAISERROR ('SendProc Setup', 11, 1)
    RETURN
END

EXEC ('CREATE QUEUE [{0}].[' + @PrimaryQueueName + ']')
IF (0 < @@ERROR) BEGIN
    EXEC ('DROP PROCEDURE [{0}].[' + @ControlHandlerName + ']')
    EXEC ('DROP PROCEDURE [{0}].[' + @ReceiveName + ']')
    EXEC ('DROP PROCEDURE [{0}].[' + @SendName + ']')
    EXEC sp_releaseapplock @Resource = @ChannelName, @LockOwner = 'Session'
    EXEC sp_releaseapplock @Resource = 'SSBMB', @LockOwner = 'Session'
    RAISERROR ('PrimaryQueue Setup', 11, 1)
    RETURN
END

EXEC ('CREATE QUEUE [{0}].[' + @ControlQueueName + '] WITH ACTIVATION (STATUS = ON, PROCEDURE_NAME = [{0}].[' + @ControlHandlerName + '], EXECUTE AS OWNER, MAX_QUEUE_READERS = 1)')
IF (0 < @@ERROR) BEGIN
    EXEC ('DROP QUEUE [{0}].[' + @PrimaryQueueName + ']')
    EXEC ('DROP PROCEDURE [{0}].[' + @ControlHandlerName + ']')
    EXEC ('DROP PROCEDURE [{0}].[' + @ReceiveName + ']')
    EXEC ('DROP PROCEDURE [{0}].[' + @SendName + ']')
    EXEC sp_releaseapplock @Resource = @ChannelName, @LockOwner = 'Session'
    EXEC sp_releaseapplock @Resource = 'SSBMB', @LockOwner = 'Session'
    RAISERROR ('ControlQueue Setup', 11, 1)
    RETURN
END

EXEC ('CREATE SERVICE [' + @IssuingServiceName + '] AUTHORIZATION [dbo] ON QUEUE [{0}].[' + @ControlQueueName + '] (ChannelContract)')
IF (0 < @@ERROR) BEGIN
    EXEC ('DROP QUEUE [{0}].[' + @ControlQueueName + ']')
    EXEC ('DROP QUEUE [{0}].[' + @PrimaryQueueName + ']')
    EXEC ('DROP PROCEDURE [{0}].[' + @ControlHandlerName + ']')
    EXEC ('DROP PROCEDURE [{0}].[' + @ReceiveName + ']')
    EXEC ('DROP PROCEDURE [{0}].[' + @SendName + ']')
    EXEC sp_releaseapplock @Resource = @ChannelName, @LockOwner = 'Session'
    EXEC sp_releaseapplock @Resource = 'SSBMB', @LockOwner = 'Session'
    RAISERROR ('IssuingService Setup', 11, 1)
    RETURN
END

EXEC ('CREATE SERVICE [' + @ReceivingServiceName + '] AUTHORIZATION [dbo] ON QUEUE [{0}].[' + @PrimaryQueueName + '] (ChannelContract)')
IF (0 < @@ERROR) BEGIN
    EXEC ('DROP SERVICE [' + @IssuingServiceName + ']')
    EXEC ('DROP QUEUE [{0}].[' + @ControlQueueName + ']')
    EXEC ('DROP QUEUE [{0}].[' + @PrimaryQueueName + ']')
    EXEC ('DROP PROCEDURE [{0}].[' + @ControlHandlerName + ']')
    EXEC ('DROP PROCEDURE [{0}].[' + @ReceiveName + ']')
    EXEC ('DROP PROCEDURE [{0}].[' + @SendName + ']')
    EXEC sp_releaseapplock @Resource = @ChannelName, @LockOwner = 'Session'
    EXEC sp_releaseapplock @Resource = 'SSBMB', @LockOwner = 'Session'
    RAISERROR ('ReceivingService Setup', 11, 1)
    RETURN
END

INSERT INTO [{0}].Channels
SELECT @ChannelName AS ChannelName

EXEC ('GRANT EXECUTE ON [{0}].[' + @ReceiveName + '] TO [{1}]')
EXEC ('GRANT EXECUTE ON [{0}].[' + @SendName + '] TO [{1}]')

EXEC sp_releaseapplock @Resource = @ChannelName, @LockOwner = 'Session'
EXEC sp_releaseapplock @Resource = 'SSBMB', @LockOwner = 'Session'