using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using SSBMB.Properties;
using System.Transactions;

namespace SSBMB
{
    // TODO: type-qualify names of channels, topics, and subscriptions; topic-qualify subscriptions to avoid name conflicts
    public static class SubscriptionManager
    {
        public static List<SubscriptionDescription> ListSubscriptions(SqlConnection conn)
        {
            var subscriptions = new List<SubscriptionDescription>();

            var cmd = conn.CreateCommand();

            cmd.CommandType = System.Data.CommandType.Text;
            cmd.CommandText = string.Format(Resources.ListSubscriptions, InstanceManager.SchemaName, InstanceManager.AuthorizedRole);

            using (var reader = cmd.ExecuteReader())
            {
                while (reader.Read())
                {
                    subscriptions.Add(new SubscriptionDescription((string)reader["SubscriptionName"], (string)reader["TopicName"], (bool)reader["Fixed"]));
                }
            }

            return subscriptions;
        }

        public static void CleanupSubscriptions(SqlConnection conn, string topicName)
        {
            var cmd = conn.CreateCommand();

            cmd.CommandType = System.Data.CommandType.StoredProcedure;
            cmd.CommandText = string.Format("[{0}].CleanUpEphemeralSubscriptions", InstanceManager.SchemaName, InstanceManager.AuthorizedRole);
            cmd.Parameters.Add(new SqlParameter("@TopicName", topicName ?? (object)DBNull.Value));

            cmd.ExecuteNonQuery();
        }

        public static string Subscribe(SqlConnection conn, string topicName, string subscriptionName)
        {
            var cmd = conn.CreateCommand();

            cmd.CommandType = System.Data.CommandType.StoredProcedure;
            cmd.CommandText = string.Format("[{0}].[Subscribe]", InstanceManager.SchemaName, InstanceManager.AuthorizedRole);
            cmd.Parameters.Add(new SqlParameter("@TopicName", topicName));
            cmd.Parameters.Add(new SqlParameter("@SubscriptionName", subscriptionName ?? (object)DBNull.Value));
            return (string)cmd.ExecuteScalar();
        }

        public static void Unsubscribe(SqlConnection conn, string topicName, string subscriptionName)
        {
            var cmd = conn.CreateCommand();

            cmd.CommandType = System.Data.CommandType.StoredProcedure;
            cmd.CommandText = string.Format("[{0}].[Unsubscribe]", InstanceManager.SchemaName, InstanceManager.AuthorizedRole);
            cmd.Parameters.Add(new SqlParameter("@TopicName", topicName));
            cmd.Parameters.Add(new SqlParameter("@SubscriptionName", subscriptionName));
            cmd.ExecuteNonQuery();
        }

        public static IEnumerable<string> Listen(Func<SqlConnection> conn, string topicName, string subscriptionName)
        {
            var isFixed = subscriptionName == null;

            if (!isFixed)
            {
                subscriptionName = Subscribe(conn(), topicName, subscriptionName);
            }

            while (true)
            {
                var cmd = conn().CreateCommand();

                cmd.CommandType = System.Data.CommandType.Text;
                // @SubscriptionName cannot be parameterized in this script
                cmd.CommandText = string.Format("[{0}].{2}_Listen", InstanceManager.SchemaName, InstanceManager.AuthorizedRole, subscriptionName);

                using (var reader = cmd.ExecuteReader())
                {
                    do
                    {
                        while (reader.Read())
                        {
                            yield return (string)reader[0];
                        }
                    } while (reader.NextResult());
                }
            }
        }

        public static IEnumerable<string> Listen(Func<SqlConnection> conn, string topicName)
        {
            return Listen(conn, topicName, null);
        }
    }

    public class SubscriptionDescription
    {
        public string Name { get; private set; }
        public string Topic { get; private set; }
        public bool Fixed { get; private set; }

        public SubscriptionDescription(string name, string topic, bool @fixed)
        {
            this.Name = name;
            this.Topic = topic;
            this.Fixed = @fixed;
        }

        public override string ToString()
        {
            return string.Format("{0} on {1} ({2})",
                        Name,
                        Topic,
                        Fixed ? "Permanent" : "Ephemeral");
        }
    }
}
