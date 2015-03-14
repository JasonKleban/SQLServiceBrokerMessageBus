using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data.SqlClient;
using System.Linq;
using System.Runtime.Serialization;
using System.Text;
using System.Threading.Tasks;
using System.Transactions;

namespace SSBMBSample
{
    // Connection problems can be handled 
    // gracefully but are not in this sample

    class Program
    {
        static void Main(string[] args)
        {
            var connStr = ConfigurationManager.ConnectionStrings["conn"].ConnectionString;

            Console.Clear();
            Console.WriteLine("SQL Service Broker Message Bus - Sample Utility");
            Console.WriteLine();
            Console.WriteLine("Using connection string (as set in the AppConfig):");
            Console.WriteLine("\t{0}", connStr);
            Console.WriteLine();
            Console.WriteLine("Prerequisite: Install and configure a \"TestChannel\" channel and a \"TestTopic\" topic.");
            Console.WriteLine();

            Console.WriteLine("Run as which mode? [1, 2, 3, or 4]");
            Console.WriteLine(" (1) TestChannel Sender");
            Console.WriteLine(" (2) TestChannel Receiver");
            Console.WriteLine(" (3) TestTopic Announcer");
            Console.WriteLine(" (4) TestTopic Subscribe & Listen");

            char selection;

            while (!(new[] { '1', '2', '3', '4' }.Contains((selection = Console.ReadKey(true).KeyChar)))) { }

            Console.Clear();
            Console.WriteLine("SQL Service Broker Message Bus - Sample Utility");
            Console.WriteLine();

            try
            {
                switch (selection)
                {
                    case '1': Task.Run(() => TestChannelSender(connStr)).Wait(); break;
                    case '2': Task.Run(() => TestChannelReceiver(connStr)).Wait(); break;
                    case '3': Task.Run(() => TestChannelAnnouncer(connStr)).Wait(); break;
                    case '4': Task.Run(() => TestChannelSubscribeAndListen(connStr)).Wait(); break;
                }
            }
            catch (Exception ex)
            {
                var temp = Console.ForegroundColor;
                Console.ForegroundColor = ConsoleColor.Red;
                Console.WriteLine(ex.ToString());
                Console.ForegroundColor = temp;
                throw;
            }

            while (Console.KeyAvailable) Console.ReadKey(true);
            Console.WriteLine("Press any key to quit");
            Console.ReadKey(true);
        }

        static async Task TestChannelSender(string connStr)
        {
            Console.WriteLine("TestChannel Sender");
            Console.WriteLine("Type a message per line to send.");
            Console.WriteLine();

            while (true)
            {
                using (var conn = new SqlConnection(connStr))
                using (var scope = new TransactionScope(TransactionScopeAsyncFlowOption.Enabled))
                {
                    conn.Open();

                    var message = Console.ReadLine();

                    await ChannelClient.Send(
                        conn,
                        "TestChannel",
                        new MyPayload(message));

                    scope.Complete();
                }
            }
        }

        static async Task TestChannelReceiver(string connStr)
        {
            Console.WriteLine("TestChannel Receiver");
            Console.WriteLine("Receiving ...");
            Console.WriteLine();

            while (true)
            {
                using (var conn = new SqlConnection(connStr))
                using (var scope = new TransactionScope(TransactionScopeAsyncFlowOption.Enabled))
                {
                    conn.Open();

                    var received = await ChannelClient.Receive<MyPayload>(
                        conn,
                        "TestChannel",
                        new System.Threading.CancellationTokenSource().Token);

                    if (received != null)
                    {
                        Console.WriteLine("Received: {0}", received);
                    }
                    else
                    {
                        Console.WriteLine("...");
                    }

                    Console.Write("    Fake Processing Message ");
                    for (var x = 0; x < 5; x++)
                    {
                        await Task.Delay(TimeSpan.FromSeconds(1));
                        Console.Write(".");
                    }
                    Console.WriteLine();

                    scope.Complete();
                }
            }
        }

        static async Task TestChannelAnnouncer(string connStr)
        {
            Console.WriteLine("TestTopic Announcer");
            Console.WriteLine("Type a message per line to send.");
            Console.WriteLine();

            while (true)
            {
                using (var conn = new SqlConnection(connStr))
                using (var scope = new TransactionScope(TransactionScopeAsyncFlowOption.Enabled))
                {
                    conn.Open();

                    var message = Console.ReadLine();

                    await TopicClient.Announce(
                        conn,
                        "TestTopic",
                        new MyPayload(message /* ... */));

                    scope.Complete();
                }
            }
        }

        static void TestChannelSubscribeAndListen(string connStr)
        {
            Console.WriteLine("TestTopic Subscribe & Listen");
            Console.WriteLine();

            var sqlConnBuilder = new SqlConnectionStringBuilder(connStr);
            sqlConnBuilder.Pooling = false;
            sqlConnBuilder.MultipleActiveResultSets = true;

            var newConnStr = sqlConnBuilder.ToString();

            foreach (var received in SubscriptionClient.Listen<MyPayload>(
                () => new SqlConnection(newConnStr),
                "TestTopic",
                new System.Threading.CancellationTokenSource().Token))
            {
                if (received != null)
                {
                    Console.WriteLine("Received: {0}", received);
                }
                else
                {
                    Console.WriteLine("...");
                }
            }
        }
    }

    [DataContract]
    class MyPayload
    {
        [DataMember]
        string something;
        // ... and any additional fields

        public string Something { get { return something; } }

        public MyPayload(string something) { this.something = something; }

        public override string ToString() { return string.Format("MyPayload {{ something = \"{0}\" }}", something); }
    }
}
