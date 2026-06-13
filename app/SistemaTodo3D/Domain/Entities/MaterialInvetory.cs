using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Domain.Entities
{
    public class MaterialInventory
    {
        public int InventoryID { get; set; }
        public int MaterialID { get; set; }
        public decimal PackageCapacity { get; set; }
        public int ClosedPackageCount { get; set; } = 0;
        public int OpenPackageCount { get; set; } = 0;
        public decimal RemainingPercentage { get; set; } = 100.00m;
        public DateTime UpdatedAt { get; set; }

        // Computed column - read-only, calculated by database
        public decimal CurrentUsableStock { get; set; } // Populated from DB computed column

        // Navigation property (for manual joins)
        public Material? Material { get; set; }

        //public void LoadFromDataReader(SqlDataReader reader)
        //{
        //    InventoryID = reader.GetInt32(reader.GetOrdinal("InventoryID"));
        //    MaterialID = reader.GetInt32(reader.GetOrdinal("MaterialID"));
        //    PackageCapacity = reader.GetDecimal(reader.GetOrdinal("PackageCapacity"));
        //    ClosedPackageCount = reader.GetInt32(reader.GetOrdinal("ClosedPackageCount"));
        //    OpenPackageCount = reader.GetInt32(reader.GetOrdinal("OpenPackageCount"));
        //    RemainingPercentage = reader.GetDecimal(reader.GetOrdinal("RemainingPercentage"));
        //    UpdatedAt = reader.GetDateTime(reader.GetOrdinal("UpdatedAt"));
        //    CurrentUsableStock = reader.GetDecimal(reader.GetOrdinal("CurrentUsableStock"));
        //}
    }
}
