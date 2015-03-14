using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.IO;
using System.Linq;
using System.Runtime.Serialization;
using System.Text;
using System.Threading;
using System.Threading.Tasks;

namespace SSBMBSample
{
    public static class ChannelClient
    {
        public static async Task<T> Receive<T>(SqlConnection conn, string channelName, CancellationToken ct, params Type[] otherTypes)
        {
            using (var cmd = conn.CreateCommand())
            {
                cmd.CommandTimeout = 0;
                cmd.CommandType = System.Data.CommandType.StoredProcedure;
                cmd.CommandText = "[SSBMB]." + channelName + "_Receive";

                using (var reader = await cmd.ExecuteReaderAsync(ct))
                {
                    if (!ct.IsCancellationRequested && await reader.ReadAsync(ct))
                    {
                        return SSBSerializationHelpers.Deserialize<T>((string)reader["MessageBody"], otherTypes);
                    }
                    else
                    {
                        return default(T);
                    }
                }
            }
        }

        public static async Task Send<T>(SqlConnection conn, string channelName, T message, params Type[] otherTypes)
        {
            using (var cmd = conn.CreateCommand())
            {
                cmd.CommandType = System.Data.CommandType.StoredProcedure;
                cmd.CommandText = "[SSBMB]." + channelName + "_Send";
                var serializedMessage = SSBSerializationHelpers.Serialize(message, otherTypes);
                cmd.Parameters.Add(new SqlParameter("@MessageBody", serializedMessage ?? (object)DBNull.Value));

                await cmd.ExecuteNonQueryAsync();
            }
        }
    }
}
