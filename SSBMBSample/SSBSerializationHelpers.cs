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
    public static class SSBSerializationHelpers
    {
        public static string Serialize<T>(T objectToSerialize, params Type[] otherTypes)
        {
            using (var memStm = new MemoryStream())
            {
                var serializer = new System.Runtime.Serialization.DataContractSerializer(typeof(T), otherTypes ?? Type.EmptyTypes);
                serializer.WriteObject(memStm, objectToSerialize);

                memStm.Seek(0, SeekOrigin.Begin);

                using (var streamReader = new StreamReader(memStm))
                {
                    string result = streamReader.ReadToEnd();
                    return result;
                }
            }
        }

        public static T Deserialize<T>(string serialized, params Type[] otherTypes)
        {
            DataContractSerializer deserializer = new DataContractSerializer(typeof(T), otherTypes ?? Type.EmptyTypes, 100, true, false, null, new TypeCloneResolver(typeof(T), otherTypes));

            using (Stream ms = new MemoryStream(Encoding.UTF8.GetBytes(serialized)))
            {
                return (T)deserializer.ReadObject(ms);
            }
        }

        class TypeCloneResolver : DataContractResolver
        {
            Type[] clonedTypes;
            public TypeCloneResolver(Type clonedType, params Type[] otherClonedTypes)
            {
                this.clonedTypes = (new Type[] { clonedType }).Concat(otherClonedTypes).ToArray();
            }

            public override Type ResolveName(string typeName, string typeNamespace, Type declaredType, DataContractResolver knownTypeResolver)
            {
                var resolved = clonedTypes.SingleOrDefault(t => string.Equals(t.Name, typeName, StringComparison.Ordinal));

                return resolved ?? knownTypeResolver.ResolveName(typeName, typeNamespace, declaredType, knownTypeResolver);
            }

            public override bool TryResolveType(Type type, Type declaredType, DataContractResolver knownTypeResolver, out System.Xml.XmlDictionaryString typeName, out System.Xml.XmlDictionaryString typeNamespace)
            {
                throw new NotImplementedException();
            }
        }
    }
}
