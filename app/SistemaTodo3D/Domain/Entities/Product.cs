using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Domain.Entities
{
    public class Product
    {
        public int ProductID { get; set; }
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }
        public bool Active { get; set; } = true;
        public int? CategoryID { get; set; }
        public decimal? UnitPrice { get; set; } = 0m;
        public decimal? UnitCost { get; set; } = 0m;
        public int? Stock { get; set; } = 0;
        public bool Discontinued { get; set; } = false;

        // Navigation property
        public Category? Category { get; set; }

        // Computed properties for business logic
        public decimal? ProfitMargin => UnitPrice.HasValue && UnitCost.HasValue && UnitPrice.Value > 0
            ? ((UnitPrice.Value - UnitCost.Value) / UnitPrice.Value) * 100
            : null;

        public bool IsAvailable => Active && !Discontinued && (Stock.GetValueOrDefault(0) > 0);

        //public void LoadFromDataReader(SqlDataReader reader)
        //{
        //    ProductID = reader.GetInt32(reader.GetOrdinal("ProductID"));
        //    Name = reader.GetString(reader.GetOrdinal("Name"));
        //    Description = reader.IsDBNull(reader.GetOrdinal("Description"))
        //        ? null
        //        : reader.GetString(reader.GetOrdinal("Description"));
        //    Active = reader.GetBoolean(reader.GetOrdinal("Active"));
        //    CategoryID = reader.IsDBNull(reader.GetOrdinal("CategoryID"))
        //        ? (int?)null
        //        : reader.GetInt32(reader.GetOrdinal("CategoryID"));
        //    UnitPrice = reader.IsDBNull(reader.GetOrdinal("UnitPrice"))
        //        ? (decimal?)null
        //        : reader.GetDecimal(reader.GetOrdinal("UnitPrice"));
        //    UnitCost = reader.IsDBNull(reader.GetOrdinal("UnitCost"))
        //        ? (decimal?)null
        //        : reader.GetDecimal(reader.GetOrdinal("UnitCost"));
        //    Stock = reader.IsDBNull(reader.GetOrdinal("Stock"))
        //        ? (int?)null
        //        : reader.GetInt32(reader.GetOrdinal("Stock"));
        //    Discontinued = reader.GetBoolean(reader.GetOrdinal("Discontinued"));
        //}
    }
}
