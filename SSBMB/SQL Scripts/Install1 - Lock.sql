SET NOCOUNT ON

IF (@@TRANCOUNT <> 0) BEGIN
    RAISERROR ('AMBIENT TRANSACTION NOT ALLOWED', 11, 1)
    RETURN
END

DECLARE @LastError INT,
        @Message NVARCHAR(1024),
        @LockStatus INT

-- AppLock on the string 'SSBMB' for the remainder of this connection session
EXEC @LockStatus = sp_getapplock @Resource = 'SSBMB', @LockMode = 'EXCLUSIVE', @LockTimeout = 0, @LockOwner = 'Session'
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

SELECT @Message = NULL

IF (@Repairing = 0) BEGIN
    ;WITH FailIfExists ([Name]) AS
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
        SELECT name FROM sys.schemas WHERE name = '{0}' -- {0}
    )
    SELECT @Message = COALESCE(@Message + ', ', 'These items already exist: ') + Name -- could get truncated, but that's OK
    FROM FailIfExists

    IF (@Message IS NOT NULL) BEGIN
        EXEC sp_releaseapplock @Resource = 'SSBMB', @LockOwner = 'Session'
        RAISERROR (@Message, 11, 1)
        RETURN
    END
END ELSE BEGIN
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
    SELECT @Message = COALESCE(@Message + ', ', 'These required items are missing: ') + Name -- could get truncated, but that's OK
    FROM MustExists

    IF (@Message IS NOT NULL) BEGIN
        EXEC sp_releaseapplock @Resource = 'SSBMB', @LockOwner = 'Session'
        RAISERROR (@Message, 11, 1)
        RETURN
    END
END

SELECT @Message = NULL

;WITH RequiredPermissions AS
(
    SELECT Name = 'CREATE TABLE' UNION ALL
    SELECT Name = 'CREATE PROCEDURE' UNION ALL
    SELECT Name = 'CREATE SCHEMA' UNION ALL
    SELECT Name = 'CREATE MESSAGE TYPE' UNION ALL
    SELECT Name = 'CREATE SERVICE' UNION ALL
    SELECT Name = 'CREATE CONTRACT' UNION ALL
    SELECT Name = 'CREATE QUEUE'
)
SELECT 
    @Message = COALESCE(@Message + ', ', 'You are missing these required permissions: ') + RequiredPermission.Name
FROM fn_my_permissions (NULL, 'DATABASE')
LEFT JOIN RequiredPermissions AS RequiredPermission ON permission_name = RequiredPermission.Name
WHERE entity_name IS NULL

IF (@Message IS NOT NULL) BEGIN
    EXEC sp_releaseapplock @Resource = 'SSBMB', @LockOwner = 'Session'
    RAISERROR (@Message, 11, 1)
    RETURN
END