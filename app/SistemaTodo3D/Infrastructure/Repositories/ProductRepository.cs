using Domain.Entities;
using Infrastructure.Data;
using Microsoft.Data.SqlClient;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Infrastructure.Repositories
{
    public class ProductRepository
    {
        private readonly SqlConnectionFactory _factory;

        public ProductRepository(SqlConnectionFactory factory)
        {
            _factory = factory;
        }

        public List<Product> ObtenerTodos()
        {
            List<Product> productos = new();

            using SqlConnection cn = _factory.Create();

            cn.Open();

            string sql =
                @"SELECT ProductID,
                     Name,
                     Description,
                     UnitPrice,
                     Stock
              FROM Product";

            using SqlCommand cmd =
                new SqlCommand(sql, cn);

            using SqlDataReader dr =
            cmd.ExecuteReader();

            while (dr.Read())
            {
                productos.Add(new Product
                {
                    ProductID = dr.GetInt32(dr.GetOrdinal("ProductID")),
                    Name = dr.GetString(dr.GetOrdinal("Name")),
                    Description = dr.IsDBNull(dr.GetOrdinal("Description")) ? null : dr.GetString(dr.GetOrdinal("Description")),
                    UnitPrice = dr.GetDecimal(dr.GetOrdinal("UnitPrice")),
                    Stock = dr.GetInt32(dr.GetOrdinal("Stock"))
                });
            }

            return productos;
        }
    }
}
