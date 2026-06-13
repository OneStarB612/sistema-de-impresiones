using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Domain.Entities
{
    public class Supplier
    {
        public int SupplierID { get; set; }
        public string Name { get; set; } = string.Empty;
        public string? ContactEmail { get; set; }
        public bool Active { get; set; } = true;

        // For ADO.NET mapping
        //public void LoadFromDataReader(SqlDataReader reader)
        //{
        //    SupplierID = reader.GetInt32(reader.GetOrdinal("SupplierID"));
        //    Name = reader.GetString(reader.GetOrdinal("Name"));
        //    ContactEmail = reader.IsDBNull(reader.GetOrdinal("ContactEmail"))
        //        ? null
        //        : reader.GetString(reader.GetOrdinal("ContactEmail"));
        //    Active = reader.GetBoolean(reader.GetOrdinal("Active"));
        //}
    }
}
