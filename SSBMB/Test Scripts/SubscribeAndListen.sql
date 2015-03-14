
--
-- SQL Service Broken must be enabled and Topic must be previously configured
-- Locks are held for the duration of the session (connection) and a wrapping transaction is not permitted
-- Further, ADO.NET Connection Pooling mut be disabled for a connection dealing with subscriptions

EXECUTE [SSBMB].[Subscribe] @TopicName = 'TestTopic', @SubscriptionName = NULL

-- Run the above, then as part of the same sql connection (but, of course, as it's own batch) call the Listen on the generated subscription ...

EXECUTE [SSBMB].[????????-????-????-????-????????????_Listen]

