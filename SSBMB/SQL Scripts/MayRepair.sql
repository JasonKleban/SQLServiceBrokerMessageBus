SET NOCOUNT ON

DECLARE @LastError INT,
        @Message NVARCHAR(1024),
        @LockStatus INT,
        @MayRepair BIT = 1

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

;WITH MustExists ([Name]) AS
(
    SELECT 'ChannelContract' FROM (SELECT 1 AS D) AS Dummy WHERE NOT EXISTS (SELECT name FROM sys.service_contracts WHERE name = 'ChannelContract') UNION ALL
    SELECT 'TopicContract' FROM (SELECT 1 AS D) AS Dummy WHERE NOT EXISTS (SELECT name FROM sys.service_contracts WHERE name = 'TopicContract') UNION ALL
    SELECT 'SubscriptionContract' FROM (SELECT 1 AS D) AS Dummy WHERE NOT EXISTS (SELECT name FROM sys.service_contracts WHERE name = 'SubscriptionContract') UNION ALL
    SELECT 'SerializedMessage' FROM (SELECT 1 AS D) AS Dummy WHERE NOT EXISTS (SELECT name FROM sys.service_message_types WHERE name = 'SerializedMessage') UNION ALL
    SELECT 'Channels' AS name FROM (SELECT 1 AS D) AS Dummy WHERE OBJECT_ID('[{0}].Channels', 'U') IS NULL UNION ALL
    SELECT 'Topics' AS name FROM (SELECT 1 AS D) AS Dummy WHERE OBJECT_ID('[{0}].Topics', 'U') IS NULL UNION ALL
    SELECT 'Subscriptions' AS name FROM (SELECT 1 AS D) AS Dummy WHERE OBJECT_ID('[{0}].Subscriptions', 'U') IS NULL UNION ALL
    SELECT '{0}' FROM (SELECT 1 AS D) AS Dummy WHERE NOT EXISTS (SELECT name FROM sys.schemas WHERE name = '{0}')
)
SELECT @MayRepair = CASE WHEN (@MayRepair = 1) AND (COUNT(0) = 8) THEN 1 ELSE 0 END
FROM MustExists

EXEC sp_releaseapplock @Resource = 'SSBMB', @LockOwner = 'Session'

SELECT @MayRepair AS MayRepair