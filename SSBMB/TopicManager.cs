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
    public static class TopicManager
    {
        public static List<string> ListTopics(SqlConnection conn)
        {
            List<string> topics = new List<string>();

            var cmd = conn.CreateCommand();

            cmd.CommandType = System.Data.CommandType.Text;
            cmd.CommandText = string.Format(Resources.ListTopics, InstanceManager.SchemaName, InstanceManager.AuthorizedRole);

            using (var reader = cmd.ExecuteReader())
            {
                while (reader.Read())
                {
                    topics.Add((string)reader["TopicName"]);
                }
            }

            return topics;
        }

        // Creates all the SQL/SSB primatives necessary to support the Topic
        public static void CreateTopic(SqlConnection conn, string topicName)
        {
            var cmd = conn.CreateCommand();

            cmd.CommandType = System.Data.CommandType.Text;
            cmd.CommandText = string.Format(Resources.CreateTopic, InstanceManager.SchemaName, InstanceManager.AuthorizedRole);
            cmd.Parameters.Add(new SqlParameter("@TopicName", topicName));
            cmd.ExecuteNonQuery();
        }

        public static void DestroyTopic(SqlConnection conn, string topicName)
        {
            var cmd = conn.CreateCommand();

            cmd.CommandType = System.Data.CommandType.Text;
            cmd.CommandText = string.Format(Resources.DestroyTopic, InstanceManager.SchemaName, InstanceManager.AuthorizedRole);
            cmd.Parameters.Add(new SqlParameter("@TopicName", topicName));
            cmd.ExecuteNonQuery();
        }
    }
}