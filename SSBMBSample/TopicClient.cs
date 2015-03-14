using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SSBMBSample
{
    static class TopicClient
    {
        public static async Task Announce<T>(SqlConnection conn, string topicName, T message, params Type[] otherTypes)
        {
            using (var cmd = conn.CreateCommand())
            {
                cmd.CommandType = System.Data.CommandType.StoredProcedure;
                cmd.CommandText = "[SSBMB]." + topicName + "_Announce";
                cmd.Parameters.Add(new SqlParameter("@MessageBody", SSBSerializationHelpers.Serialize(message, otherTypes) ?? (object)DBNull.Value));

                await cmd.ExecuteNonQueryAsync();
            }
        }
    }
}
