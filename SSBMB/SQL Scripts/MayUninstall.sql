SET NOCOUNT ON

DECLARE @LastError INT,
        @Message NVARCHAR(1024),
        @LockStatus INT,
        @MayUninstall BIT = 1,
        @NumSubscriptions INT = 0,
        @NumTopics INT = 0,
        @NumChannels INT = 0

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
    SELECT @MayUninstall = 0
END

;WITH MightExists ([Name]) AS
(
    SELECT name FROM sys.service_contracts WHERE name = 'ChannelContract' UNION ALL
    SELECT name FROM sys.service_contracts WHERE name = 'TopicContract' UNION ALL
    SELECT name FROM sys.service_contracts WHERE name = 'SubscriptionContract' UNION ALL
    SELECT name FROM sys.service_message_types WHERE name = 'SerializedMessage' UNION ALL
    SELECT 'Channels' AS name FROM (SELECT 1 AS D) AS Dummy WHERE OBJECT_ID('[{0}].Channels', 'U') IS NOT NULL UNION ALL
    SELECT 'Topics' AS name FROM (SELECT 1 AS D) AS Dummy WHERE OBJECT_ID('[{0}].Topics', 'U') IS NOT NULL UNION ALL
    SELECT 'Subscriptions' AS name FROM (SELECT 1 AS D) AS Dummy WHERE OBJECT_ID('[{0}].Subscriptions', 'U') IS NOT NULL UNION ALL
    SELECT 'CleanUpEphemeralSubscriptions' AS name FROM (SELECT 1 AS D) AS Dummy WHERE OBJECT_ID('[{0}].CleanUpEphemeralSubscriptions', 'P') IS NOT NULL UNION ALL
    SELECT 'Subscribe' AS name FROM (SELECT 1 AS D) AS Dummy WHERE OBJECT_ID('[{0}].Subscribe', 'P') IS NOT NULL UNION ALL
    SELECT 'Unsubscribe' AS name FROM (SELECT 1 AS D) AS Dummy WHERE OBJECT_ID('[{0}].Unsubscribe', 'P') IS NOT NULL UNION ALL
    SELECT name FROM sys.schemas WHERE name = '{0}'
)
SELECT @MayUninstall = CASE WHEN (@MayUninstall = 1) AND (0 < COUNT(0)) THEN 1 ELSE 0 END
FROM MightExists

IF (@MayUninstall = 1 AND OBJECT_ID('[{0}].Subscriptions', 'U') IS NOT NULL) BEGIN
    EXEC sp_executesql N'SELECT @NumSubscriptions = COUNT(0) FROM [{0}].Subscriptions', N'@NumSubscriptions INT OUTPUT', @NumSubscriptions OUTPUT;
    SELECT @MayUninstall = CASE WHEN @NumSubscriptions = 0 THEN 1 ELSE 0 END
END

IF (@MayUninstall = 1 AND OBJECT_ID('[{0}].Topics', 'U') IS NOT NULL) BEGIN
    EXEC sp_executesql N'SELECT @NumTopics = COUNT(0) FROM [{0}].Topics', N'@NumTopics INT OUTPUT', @NumTopics OUTPUT;
    SELECT @MayUninstall = CASE WHEN @NumTopics = 0 THEN 1 ELSE 0 END
END

IF (@MayUninstall = 1 AND OBJECT_ID('[{0}].Channels', 'U') IS NOT NULL) BEGIN
    EXEC sp_executesql N'SELECT @NumChannels = COUNT(0) FROM [{0}].Channels', N'@NumChannels INT OUTPUT', @NumChannels OUTPUT;
    SELECT @MayUninstall = CASE WHEN @NumChannels = 0 THEN 1 ELSE 0 END
END

EXEC sp_releaseapplock @Resource = 'SSBMB', @LockOwner = 'Session'

SELECT @MayUninstall AS MayUninstall