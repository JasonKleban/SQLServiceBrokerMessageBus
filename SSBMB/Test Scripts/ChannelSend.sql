
--
-- SQL Service Broken must be enabled and Channel must be previously configured
--

BEGIN TRAN

EXEC [SSBMB].[TestChannel_Send] @MessageBody = "Hello World!"

COMMIT

-- Messages through channels are delivered and handled transactionally 
-- by ONE receiver.  There can be mutliple senders and multiple receivers
-- on the channel, but only one pair of sender and receiver per message
-- in a successful receiving transaction.  Processing by a receiver can 
-- be safely conducted completely within the transaction.  If the 
-- transaction is rolled back, another receiver is may then accept the 
-- message and a waiting receiver will receive it immediately.