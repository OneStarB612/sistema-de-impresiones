using Domain.Entities;
using Infrastructure.Data;
using Microsoft.Data.SqlClient;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Claims;
using System.Text;
using System.Threading.Tasks;

namespace Infrastructure.Repositories
{
    public class UserRepository
    {
        private readonly SqlConnectionFactory _factory;

        public UserRepository(SqlConnectionFactory factory)
        {
            _factory = factory;
        }

        public async Task<User> GetByUsernameAsync(string username)
        {
            User user = new();

            using SqlConnection cn = _factory.Create();

            await cn.OpenAsync(); // Use asynchronous method to open the connection

            string sql =
                @"SELECT UserID,
                     UserName,
                     Email,
                     PasswordHash,
                     Active,
                     CreatedAt   
                   FROM [User]
                   WHERE UserName = @username";

            using SqlCommand cmd = new SqlCommand(sql, cn);
            cmd.Parameters.AddWithValue("@username", username); // Add parameter to avoid IDE0060

            using SqlDataReader dr = await cmd.ExecuteReaderAsync(); // Use asynchronous method to execute reader

            while (await dr.ReadAsync()) // Use asynchronous method to read data
            {

                user.UserId = dr.GetInt32(dr.GetOrdinal("UserID"));
                user.Username = dr.GetString(dr.GetOrdinal("UserName"));
                user.PasswordHash = dr.GetString(dr.GetOrdinal("PasswordHash"));
                user.IsActive = dr.GetBoolean(dr.GetOrdinal("Active"));
                user.CreatedAt = dr.GetDateTime(dr.GetOrdinal("CreatedAt"));

            }

            return user;
        }

        public async Task<List<Role>> GetRolesAsync(int userid)
        {
            List<Role> roles = new();

            using SqlConnection cn = _factory.Create();

            await cn.OpenAsync();

            string sql =
                @"SELECT r.RoleID,
                     r.[Name],
                     r.[Description]
                  FROM Roles r
                  INNER JOIN UserRoles ur ON r.RoleID = ur.RoleID
                  WHERE ur.UserID = @userid";

            using SqlCommand cmd = new SqlCommand(sql, cn);
            cmd.Parameters.AddWithValue("@userid", userid); // Add parameter to avoid IDE0060

            using SqlDataReader dr = await cmd.ExecuteReaderAsync(); // Use asynchronous method to execute reader

            while (await dr.ReadAsync()) // Use asynchronous method to read data
            {
                roles.Add(new Role
                {
                    RoleId = dr.GetInt32(dr.GetOrdinal("RoleID")),
                    Name = dr.GetString(dr.GetOrdinal("Name")),
                    Description = dr.IsDBNull(dr.GetOrdinal("Description")) ? null : dr.GetString(dr.GetOrdinal("Description"))
                });
            }

            return roles;
        }

        public async Task<List<AppClaim>> GetClaimsAsync(int userid)
        {
            List<AppClaim> claims = new();

            using SqlConnection cn = _factory.Create();

            await cn.OpenAsync();

            string sql =
                @"SELECT c.ClaimType,
                     c.ClaimValue
                  FROM [Claim] c
                  INNER JOIN [UserClaim] uc ON c.ClaimID = uc.ClaimID
                  WHERE uc.UserID = @userid";

            using SqlCommand cmd = new SqlCommand(sql, cn);
            cmd.Parameters.AddWithValue("@userid", userid); // Add parameter to avoid IDE0060

            using SqlDataReader dr = await cmd.ExecuteReaderAsync(); // Use asynchronous method to execute reader

            while (await dr.ReadAsync()) // Use asynchronous method to read data
            {
                claims.Add(new AppClaim
                {
                    ClaimType = dr.GetString(dr.GetOrdinal("ClaimType")),
                    ClaimValue = dr.GetString(dr.GetOrdinal("ClaimValue"))
                });
            }

            return claims;
        }
    }
}
