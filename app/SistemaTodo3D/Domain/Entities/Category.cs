using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Domain.Entities
{
    public class Category
    {
        public int CategoryID { get; set; }
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }
        public bool Active { get; set; } = false; // Default 0

        //public void LoadFromDataReader(SqlDataReader reader)
        //{
        //    CategoryID = reader.GetInt32(reader.GetOrdinal("CategoryID"));
        //    Name = reader.GetString(reader.GetOrdinal("Name"));
        //    Description = reader.IsDBNull(reader.GetOrdinal("Description"))
        //        ? null
        //        : reader.GetString(reader.GetOrdinal("Description"));
        //    Active = reader.GetBoolean(reader.GetOrdinal("Active"));
        //}
    }

}
