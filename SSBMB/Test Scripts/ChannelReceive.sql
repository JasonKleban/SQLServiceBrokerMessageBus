
--
-- SQL Service Broken must be enabled and Channel must be previously configured
--

BEGIN TRAN

EXEC [SSBMB].[TestChannel_Receive]

COMMIT