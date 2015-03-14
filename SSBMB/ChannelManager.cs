using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Transactions;
using SSBMB.Properties;

namespace SSBMB
{
    // TODO: type-qualify names of channels, topics, and subscriptions; topic-qualify subscriptions to avoid name conflicts
    public static class ChannelManager
    {
        public static List<string> ListChannels(SqlConnection conn)
        {
            List<string> channelNames = new List<string>();

            var cmd = conn.CreateCommand();

            cmd.CommandType = System.Data.CommandType.Text;
            cmd.CommandText = string.Format(Resources.ListChannels, InstanceManager.SchemaName, InstanceManager.AuthorizedRole);

            using (var reader = cmd.ExecuteReader())
            {
                while (reader.Read())
                {
                    channelNames.Add((string)reader["ChannelName"]);
                }
            }

            return channelNames;
        }

        // Creates all the SQL/SSB primatives necessary to support the Channel
        public static void CreateChannel(SqlConnection conn, string channelName)
        {
            var cmd = conn.CreateCommand();

            cmd.CommandType = System.Data.CommandType.Text;
            cmd.CommandText = string.Format(Resources.CreateChannel, InstanceManager.SchemaName, InstanceManager.AuthorizedRole);
            cmd.Parameters.Add(new SqlParameter("@ChannelName", channelName));
            cmd.ExecuteNonQuery();
        }

        public static void DestroyChannel(SqlConnection conn, string channelName)
        {
            var cmd = conn.CreateCommand();

            cmd.CommandType = System.Data.CommandType.Text;
            cmd.CommandText = string.Format(Resources.DestroyChannel, InstanceManager.SchemaName, InstanceManager.AuthorizedRole);
            cmd.Parameters.Add(new SqlParameter("@ChannelName", channelName));
            cmd.ExecuteNonQuery();
        }
    }
}
