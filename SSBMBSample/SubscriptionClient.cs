using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Diagnostics;
using System.Linq;
using System.Text;
using System.Threading;
using System.Threading.Tasks;

namespace SSBMBSample
{
    static class SubscriptionClient
    {
        public static IEnumerable<T> Listen<T>(Func<SqlConnection> conn, string topicName, CancellationToken ct, params Type[] otherTypes)
        {
            string subscriptionName;

            var currentConn = conn();
            currentConn.Open();

            using (var cmd = currentConn.CreateCommand())
            {
                cmd.CommandType = System.Data.CommandType.StoredProcedure;
                cmd.CommandText = "[SSBMB].Subscribe";
                cmd.Parameters.Add(new SqlParameter("@TopicName", topicName));
                cmd.Parameters.Add(new SqlParameter("@SubscriptionName", DBNull.Value));

                subscriptionName = (string)cmd.ExecuteScalar();

                Trace.TraceInformation("New subscription created: {0}", subscriptionName);
            }

            // Repeatedly open a new connection and attempt to reconnect to the same subscription
            while (!ct.IsCancellationRequested)
            {
                using (var cmd = currentConn.CreateCommand())
                {
                    cmd.CommandTimeout = 0;
                    cmd.CommandType = System.Data.CommandType.StoredProcedure;
                    cmd.CommandText = "[SSBMB]." + subscriptionName + "_Listen";
                    var firstResultSet = true;

                    SqlDataReader reader;

                    try
                    {
                        reader = cmd.ExecuteReader();
                    }
                    catch (SqlException) // Assumes subscription is missing
                    {
                        currentConn.Close();
                        yield break; 
                        // if the Subscription was cleaned up between reconnects, we 
                        // must re-Subscribe with a new name and let the Subscriber know that 
                        // we may have missed some messages, so they need to reset their caches
                        // which are based on this stream
                    }

                    using (reader)
                    {
                        while (!ct.IsCancellationRequested)
                        {
                            string messageBody;
                            T message = default(T);
                            bool abandon = false;

                            try
                            {
                                if (reader.Read() || (!firstResultSet && reader.NextResult() && reader.Read()))
                                {
                                    messageBody = (string)reader["MessageBody"];
                                    message = SSBSerializationHelpers.Deserialize<T>(messageBody, otherTypes);
                                }
                                else
                                {
                                    continue;
                                }
                            }
                            catch (SqlException) // Assumes connection was terminated
                            {
                                currentConn.Close();

                                try
                                {
                                    currentConn = conn(); // Attempt to reconnect on same subscription
                                    currentConn.Open(); // takes effect on close
                                    break; // resume listening
                                }
                                catch
                                {
                                    currentConn.Close();
                                    abandon = true;
                                }
                            }
                            catch // Something else went wrong, like Deserialization so abandon this subscription
                            {
                                currentConn.Close();
                                abandon = true;
                            }
                            finally
                            {
                                firstResultSet = false; // after the first result, clear this, no matter what
                            }

                            // can't put yield return in try catch or finally blocks, making the code a little awkward.
                            if (abandon)
                            {
                                yield break; // end the Enumeration
                            }
                            else
                            {
                                yield return message;
                            }

                            try
                            {
                                if (!reader.NextResult()) // no more result sets??  this is not expected
                                {
                                    throw new Exception("No next result set");
                                }
                            }
                            catch // Assumes connection was terminated
                            {
                                currentConn.Close();

                                try
                                {
                                    currentConn = conn(); // Attempt to reconnect on same subscription
                                    currentConn.Open();
                                    break; // resume listening
                                }
                                catch
                                {
                                    currentConn.Close();
                                    abandon = true;
                                }
                            }

                            if (abandon)
                            {
                                yield break; // end the Enumeration
                            }
                        }
                    }
                }
            }

            currentConn.Close();
        }
    }
}
