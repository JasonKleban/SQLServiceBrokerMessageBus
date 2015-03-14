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
    public static class InstanceManager
    {
        public static string SchemaName { get; set; }
        public static string AuthorizedRole { get; set; }

        static InstanceManager() { SchemaName = "SSBMB"; AuthorizedRole = "PUBLIC"; }

        public static bool IsInstalled(SqlConnection conn)
        {
            var cmd = conn.CreateCommand();

            cmd.CommandType = System.Data.CommandType.Text;
            cmd.CommandText = string.Format(Resources.IsInstalled, InstanceManager.SchemaName, InstanceManager.AuthorizedRole);
            return (bool)cmd.ExecuteScalar();
        }

        public static bool MayUninstall(SqlConnection conn)
        {
            var cmd = conn.CreateCommand();

            cmd.CommandType = System.Data.CommandType.Text;
            cmd.CommandText = string.Format(Resources.MayUninstall, InstanceManager.SchemaName, InstanceManager.AuthorizedRole);
            return (bool)cmd.ExecuteScalar();
        }

        public static bool MayRepair(SqlConnection conn)
        {
            var cmd = conn.CreateCommand();

            cmd.CommandType = System.Data.CommandType.Text;
            cmd.CommandText = string.Format(Resources.MayRepair, InstanceManager.SchemaName, InstanceManager.AuthorizedRole);
            return (bool)cmd.ExecuteScalar();
        }

        public static void Install(SqlConnection conn)
        {
            {
                var cmd = conn.CreateCommand();

                cmd.CommandType = System.Data.CommandType.Text;
                cmd.CommandText = string.Format(Resources.Install1___Lock, InstanceManager.SchemaName, InstanceManager.AuthorizedRole);
                cmd.Parameters.Add(new SqlParameter("@Repairing", false));
                cmd.ExecuteScalar();
            }

            {
                var cmd = conn.CreateCommand();

                cmd.CommandType = System.Data.CommandType.Text;
                cmd.CommandText = string.Format(Resources.Install2___Schema, InstanceManager.SchemaName, InstanceManager.AuthorizedRole);
                cmd.ExecuteScalar();
            }

            {
                var cmd = conn.CreateCommand();

                cmd.CommandType = System.Data.CommandType.Text;
                cmd.CommandText = string.Format(Resources.Install3___Contracts_and_Tables, InstanceManager.SchemaName, InstanceManager.AuthorizedRole);
                cmd.ExecuteScalar();
            }

            {
                var cmd = conn.CreateCommand();

                cmd.CommandType = System.Data.CommandType.Text;
                cmd.CommandText = string.Format(Resources.Install4___CleanUpEphemeralSubscriptions, InstanceManager.SchemaName, InstanceManager.AuthorizedRole);
                cmd.ExecuteScalar();
            }

            {
                var cmd = conn.CreateCommand();

                cmd.CommandType = System.Data.CommandType.Text;
                cmd.CommandText = string.Format(Resources.Install5___Subscribe, InstanceManager.SchemaName, InstanceManager.AuthorizedRole);
                cmd.ExecuteScalar();
            }

            {
                var cmd = conn.CreateCommand();

                cmd.CommandType = System.Data.CommandType.Text;
                cmd.CommandText = string.Format(Resources.Install6___Unsubscribe, InstanceManager.SchemaName, InstanceManager.AuthorizedRole);
                cmd.ExecuteScalar();
            }

            {
                var cmd = conn.CreateCommand();

                cmd.CommandType = System.Data.CommandType.Text;
                cmd.CommandText = string.Format(Resources.Install7___Release, InstanceManager.SchemaName, InstanceManager.AuthorizedRole);
                cmd.ExecuteScalar();
            }
        }

        public static void Repair(SqlConnection conn)
        {
            {
                var cmd = conn.CreateCommand();

                cmd.CommandType = System.Data.CommandType.Text;
                cmd.CommandText = string.Format(Resources.Install1___Lock, InstanceManager.SchemaName, InstanceManager.AuthorizedRole);
                cmd.Parameters.Add(new SqlParameter("@Repairing", true));
                cmd.ExecuteScalar();
            }

            {
                var cmd = conn.CreateCommand();

                cmd.CommandType = System.Data.CommandType.Text;
                cmd.CommandText = string.Format(Resources.Install3___Contracts_and_Tables, InstanceManager.SchemaName, InstanceManager.AuthorizedRole);
                cmd.ExecuteScalar();
            }

            {
                var cmd = conn.CreateCommand();

                cmd.CommandType = System.Data.CommandType.Text;
                cmd.CommandText = string.Format(Resources.Install4___CleanUpEphemeralSubscriptions, InstanceManager.SchemaName, InstanceManager.AuthorizedRole);
                cmd.ExecuteScalar();
            }

            {
                var cmd = conn.CreateCommand();

                cmd.CommandType = System.Data.CommandType.Text;
                cmd.CommandText = string.Format(Resources.Install5___Subscribe, InstanceManager.SchemaName, InstanceManager.AuthorizedRole);
                cmd.ExecuteScalar();
            }

            {
                var cmd = conn.CreateCommand();

                cmd.CommandType = System.Data.CommandType.Text;
                cmd.CommandText = string.Format(Resources.Install6___Unsubscribe, InstanceManager.SchemaName, InstanceManager.AuthorizedRole);
                cmd.ExecuteScalar();
            }

            {
                var cmd = conn.CreateCommand();

                cmd.CommandType = System.Data.CommandType.Text;
                cmd.CommandText = string.Format(Resources.Install7___Release, InstanceManager.SchemaName, InstanceManager.AuthorizedRole);
                cmd.ExecuteScalar();
            }
        }

        public static void Uninstall(SqlConnection conn)
        {
            var cmd = conn.CreateCommand();

            cmd.CommandType = System.Data.CommandType.Text;
            cmd.CommandText = string.Format(Resources.Uninstall, InstanceManager.SchemaName, InstanceManager.AuthorizedRole);
            cmd.ExecuteScalar();
        }

        public static string ScriptAll(SqlConnection conn)
        {
            StringBuilder sb = new StringBuilder();

            sb.AppendLine("/*");
            sb.AppendLine(ScriptInstall());
            sb.AppendLine("*/");
            sb.AppendLine(ScriptConfiguration(conn));
            sb.AppendLine("/*");
            sb.AppendLine(ScriptConfigurationDestruction(conn));
            sb.AppendLine();
            sb.AppendLine(ScriptUninstall());
            sb.AppendLine("*/");

            return sb.ToString();
        }

        public static string ScriptInstall()
        {
            StringBuilder sb = new StringBuilder();

            sb.AppendLine();
            sb.AppendLine("------------------------");
            sb.AppendLine("-- BEGIN INSTALLATION --");
            sb.AppendLine("------------------------");
            sb.AppendLine();
            sb.AppendLine("DECLARE @Repairing BIT = 0");
            sb.AppendLine(string.Format(Resources.Install1___Lock, InstanceManager.SchemaName, InstanceManager.AuthorizedRole));
            sb.AppendLine();
            sb.AppendLine("GO");
            sb.AppendLine();
            sb.AppendLine(string.Format(Resources.Install2___Schema, InstanceManager.SchemaName, InstanceManager.AuthorizedRole));
            sb.AppendLine();
            sb.AppendLine("GO");
            sb.AppendLine();
            sb.AppendLine(string.Format(Resources.Install3___Contracts_and_Tables, InstanceManager.SchemaName, InstanceManager.AuthorizedRole));
            sb.AppendLine();
            sb.AppendLine("GO");
            sb.AppendLine();
            sb.AppendLine(string.Format(Resources.Install4___CleanUpEphemeralSubscriptions, InstanceManager.SchemaName, InstanceManager.AuthorizedRole));
            sb.AppendLine();
            sb.AppendLine("GO");
            sb.AppendLine();
            sb.AppendLine(string.Format(Resources.Install5___Subscribe, InstanceManager.SchemaName, InstanceManager.AuthorizedRole));
            sb.AppendLine();
            sb.AppendLine("GO");
            sb.AppendLine();
            sb.AppendLine(string.Format(Resources.Install6___Unsubscribe, InstanceManager.SchemaName, InstanceManager.AuthorizedRole));
            sb.AppendLine();
            sb.AppendLine("GO");
            sb.AppendLine();
            sb.AppendLine(string.Format(Resources.Install7___Release, InstanceManager.SchemaName, InstanceManager.AuthorizedRole));
            sb.AppendLine();
            sb.AppendLine("GO");

            sb.AppendLine("----------------------");
            sb.AppendLine("-- END INSTALLATION --");
            sb.AppendLine("----------------------");

            return sb.ToString();
        }

        public static string ScriptConfiguration(SqlConnection conn)
        {
            StringBuilder sb = new StringBuilder();

            sb.AppendLine("-------------------------");
            sb.AppendLine("-- BEGIN CONFIGURATION --");
            sb.AppendLine("-------------------------");

            if (!IsInstalled(conn))
            {
                return "-- Not installed or installation is corrupted.";
            }

            foreach (var channelName in ChannelManager.ListChannels(conn))
            {
                sb.AppendLine();
                sb.AppendLine("-- " + channelName);
                sb.AppendLine();
                sb.AppendLine("DECLARE @ChannelName SYSNAME = '" + channelName + "'");
                sb.AppendLine(string.Format(Resources.CreateChannel, InstanceManager.SchemaName, InstanceManager.AuthorizedRole));
                sb.AppendLine();
                sb.AppendLine("GO");
                sb.AppendLine();
            }

            foreach (var topicName in TopicManager.ListTopics(conn))
            {
                sb.AppendLine();
                sb.AppendLine("-- " + topicName);
                sb.AppendLine();
                sb.AppendLine("DECLARE @TopicName SYSNAME = '" + topicName + "'");
                sb.AppendLine(string.Format(Resources.CreateTopic, InstanceManager.SchemaName, InstanceManager.AuthorizedRole));
                sb.AppendLine();
                sb.AppendLine("GO");
                sb.AppendLine();
            }

            foreach (var subscription in SubscriptionManager.ListSubscriptions(conn).Where(s => s.Fixed).ToArray())
            {
                sb.AppendLine();
                sb.AppendLine("-- " + subscription.Name + " on " + subscription.Topic);
                sb.AppendLine();
                sb.AppendLine(string.Format("EXEC {0}.Subscribe @TopicName = '{2}', @SubscriptionName = '{3}'", InstanceManager.SchemaName, InstanceManager.AuthorizedRole, subscription.Topic, subscription.Name));
                sb.AppendLine();
                sb.AppendLine("GO");
                sb.AppendLine();
            }

            sb.AppendLine("-----------------------");
            sb.AppendLine("-- END CONFIGURATION --");
            sb.AppendLine("-----------------------");

            return sb.ToString();
        }

        public static string ScriptConfigurationDestruction(SqlConnection conn)
        {
            StringBuilder sb = new StringBuilder();

            sb.AppendLine("----------------------");
            sb.AppendLine("-- BEGIN TEAR DOWN --");
            sb.AppendLine("---------------------");

            if (!IsInstalled(conn))
            {
                return "-- Not installed or installation is corrupted.";
            }

            foreach (var channelName in ChannelManager.ListChannels(conn))
            {
                sb.AppendLine();
                sb.AppendLine("-- " + channelName);
                sb.AppendLine();
                sb.AppendLine("DECLARE @ChannelName SYSNAME = '" + channelName + "'");
                sb.AppendLine(string.Format(Resources.DestroyChannel, InstanceManager.SchemaName, InstanceManager.AuthorizedRole));
                sb.AppendLine();
                sb.AppendLine("GO");
                sb.AppendLine();
            }

            sb.AppendLine(string.Format("EXEC {0}.CleanupEphemeralSubscriptions @TopicName = NULL", InstanceManager.SchemaName, InstanceManager.AuthorizedRole));

            foreach (var subscription in SubscriptionManager.ListSubscriptions(conn).Where(s => s.Fixed).ToArray())
            {
                sb.AppendLine();
                sb.AppendLine("-- " + subscription.Name + " on " + subscription.Topic);
                sb.AppendLine();
                sb.AppendLine(string.Format("EXEC {0}.Unsubscribe @TopicName = '{2}', @SubscriptionName = '{3}'", InstanceManager.SchemaName, InstanceManager.AuthorizedRole, subscription.Topic, subscription.Name));
                sb.AppendLine();
                sb.AppendLine("GO");
                sb.AppendLine();
            }

            foreach (var topicName in TopicManager.ListTopics(conn))
            {
                sb.AppendLine();
                sb.AppendLine("-- " + topicName);
                sb.AppendLine();
                sb.AppendLine("DECLARE @TopicName SYSNAME = '" + topicName + "'");
                sb.AppendLine(string.Format(Resources.DestroyTopic, InstanceManager.SchemaName, InstanceManager.AuthorizedRole));
                sb.AppendLine();
                sb.AppendLine("GO");
                sb.AppendLine();
            }

            sb.AppendLine("-------------------");
            sb.AppendLine("-- END TEAR DOWN --");
            sb.AppendLine("-------------------");

            return sb.ToString();
        }

        public static string ScriptUninstall()
        {
            StringBuilder sb = new StringBuilder();

            sb.AppendLine();
            sb.AppendLine("--------------------------");
            sb.AppendLine("-- BEGIN UNINSTALLATION --");
            sb.AppendLine("--------------------------");
            sb.AppendLine();
            sb.AppendLine(string.Format(Resources.Uninstall, InstanceManager.SchemaName, InstanceManager.AuthorizedRole));
            sb.AppendLine();
            sb.AppendLine("GO");
            sb.AppendLine();
            sb.AppendLine("------------------------");
            sb.AppendLine("-- END UNINSTALLATION --");
            sb.AppendLine("------------------------");

            return sb.ToString();
        }
    }
}
