
--
-- SQL Service Broken must be enabled and Topic must be previously configured
-- 

BEGIN TRAN

EXEC [SSBMB].[TestTopic_Announce] @MessageBody = "Hello World!"

COMMIT

-- Messages through topics are broadcast to each registered 
-- permanent or ephemeral subscription.  Announced messages 
-- are not intended to be handled transationally but will 
-- be delivered at least once to each subscriber.