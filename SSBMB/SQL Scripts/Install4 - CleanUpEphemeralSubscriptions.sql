ALTER PROCEDURE [{0}].[CleanUpEphemeralSubscriptions] (@TopicName SYSNAME = NULL)
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
    
    BEGIN TRAN

    DECLARE @LockedTopics TABLE (
        TopicName SYSNAME
    )

    DECLARE @LockedSubscriptions TABLE (
        TopicName SYSNAME,
        SubscriptionName SYSNAME
    )

    DECLARE @AbandonedSubscriptionTopicName SYSNAME, @AbandonedSubscriptionName SYSNAME, @LocksFailed BIT = 0, @RemovalIncomplete BIT = 0
    DECLARE AbandonedSubscriptionTopicsCursor CURSOR STATIC FOR
        SELECT TopicName FROM [{0}].[Topics] WITH (NOLOCK)
        
    OPEN AbandonedSubscriptionTopicsCursor
    FETCH NEXT FROM AbandonedSubscriptionTopicsCursor INTO @AbandonedSubscriptionTopicName
    WHILE @LocksFailed= 0 AND @@FETCH_STATUS = 0 BEGIN
        PRINT 'Locking on topic for abandoned ' + @AbandonedSubscriptionName
        EXEC @LockStatus = sp_getapplock @Resource = @AbandonedSubscriptionTopicName, @LockMode = 'SHARED', @LockTimeout = 0

        IF (0 < @@ERROR) BEGIN
            SELECT @LocksFailed = 1
        END

        IF (@LockStatus <> -1 AND (@TopicName IS NULL OR @AbandonedSubscriptionTopicName = @TopicName)) BEGIN -- <> TIMEOUT (Abandoned)
            INSERT INTO @LockedTopics
            SELECT TopicName = @AbandonedSubscriptionTopicName
        END
    
        FETCH NEXT FROM AbandonedSubscriptionTopicsCursor INTO @AbandonedSubscriptionTopicName
    END

    CLOSE AbandonedSubscriptionTopicsCursor

    IF @LocksFailed = 0 BEGIN
        DECLARE AbandonedSubscriptionNameCursor CURSOR STATIC FOR
            SELECT 
                Subscriptions.TopicName,
                Subscriptions.SubscriptionName 
            FROM [{0}].[Subscriptions] WITH (NOLOCK)
            JOIN @LockedTopics LockedTopic ON LockedTopic.TopicName = Subscriptions.TopicName
            WHERE 
                Fixed = 0

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

        IF @LocksFailed = 0 BEGIN
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
        END -- Inner/Second LocksFailed = 0 for Subscriptions
        
        OPEN LockedSubscriptionNameCursor -- Reset
        FETCH NEXT FROM LockedSubscriptionNameCursor INTO @AbandonedSubscriptionTopicName, @AbandonedSubscriptionName

        WHILE @@FETCH_STATUS = 0 BEGIN
            EXEC sp_releaseapplock @Resource = @AbandonedSubscriptionName
            FETCH NEXT FROM LockedSubscriptionNameCursor INTO @AbandonedSubscriptionTopicName, @AbandonedSubscriptionName
        END

        CLOSE LockedSubscriptionNameCursor
        DEALLOCATE LockedSubscriptionNameCursor
    END -- Outer/First LocksFailed = 0 for Topics
        
    OPEN AbandonedSubscriptionTopicsCursor -- Reset
    FETCH NEXT FROM AbandonedSubscriptionTopicsCursor INTO @AbandonedSubscriptionTopicName

    WHILE @@FETCH_STATUS = 0 BEGIN
        EXEC sp_releaseapplock @Resource = @AbandonedSubscriptionTopicName
        FETCH NEXT FROM AbandonedSubscriptionTopicsCursor INTO @AbandonedSubscriptionTopicName
    END

    CLOSE AbandonedSubscriptionTopicsCursor
    DEALLOCATE AbandonedSubscriptionTopicsCursor

    IF @LocksFailed != 0 OR @RemovalIncomplete != 0 BEGIN
        RAISERROR ('Cleanup Attempts Failed', 11, 1)
        COMMIT
        EXEC sp_releaseapplock @Resource = 'SSBMB', @LockOwner = 'Session'
        RETURN
    END

    COMMIT
    EXEC sp_releaseapplock @Resource = 'SSBMB', @LockOwner = 'Session'