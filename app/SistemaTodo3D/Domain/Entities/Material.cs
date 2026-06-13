using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Domain.Entities
{
    public class Material
    {
        public int MaterialID { get; set; }
        public string SKU { get; set; } = string.Empty;
        public string MaterialName { get; set; } = string.Empty;
        public decimal MinimumStockLevel { get; set; } = 0m;
        public DateTime CreatedAt { get; set; }

        //public void LoadFromDataReader(SqlDataReader reader)
        //{
        //    MaterialID = reader.GetInt32(reader.GetOrdinal("MaterialID"));
        //    SKU = reader.GetString(reader.GetOrdinal("SKU"));
        //    MaterialName = reader.GetString(reader.GetOrdinal("MaterialName"));
        //    MinimumStockLevel = reader.GetDecimal(reader.GetOrdinal("MinimumStockLevel"));
        //    CreatedAt = reader.GetDateTime(reader.GetOrdinal("CreatedAt"));
        //}
    }
}
