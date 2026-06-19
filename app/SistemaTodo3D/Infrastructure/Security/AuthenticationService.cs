using Domain.Entities;
using Infrastructure.Data;
using Microsoft.Data.SqlClient;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Security.Claims;
using Infrastructure.Repositories;
using BCrypt.Net;
using Microsoft.AspNetCore.Authentication.Cookies;

namespace Infrastructure.Security
{
    public class AuthenticationService : IAuthenticationService
    {

        private readonly UserRepository _repo;


        public AuthenticationService(
            UserRepository repo)
        {
            _repo = repo;
        }


        public async Task<ClaimsPrincipal?> AuthenticateAsync(string username, string password)
        {
            var user = await _repo.GetByUsernameAsync(username);

            // Debug - check the hash format
            Console.WriteLine($"Hash: {user.PasswordHash}");
            Console.WriteLine($"Length: {user.PasswordHash?.Length}");
            Console.WriteLine($"Starts with $2: {user.PasswordHash?.StartsWith("$2")}");

            if (user == null)
                return null;


            if (!user.IsActive)
                return null;

            bool ok = BCrypt.Net.BCrypt.Verify(password,user.PasswordHash);

            if (!ok)
                return null;

            var roles = await _repo.GetRolesAsync(user.UserId);

            var claims = await _repo.GetClaimsAsync(user.UserId);

            List<System.Security.Claims.Claim> identityClaims =
                [
                    new System.Security.Claims.Claim(
                        ClaimTypes.Name,
                        user.Username
                    )
,
                    new System.Security.Claims.Claim(
                        ClaimTypes.NameIdentifier,
                        user.UserId.ToString()
                    )
,
                ];



            foreach (var role in roles)
            {

                identityClaims.Add(

                    new System.Security.Claims.Claim(

                        ClaimTypes.Role,

                        role.Name
                    ));
            }



            foreach (var c in claims)
            {

                identityClaims.Add(

                    new System.Security.Claims.Claim(

                        c.ClaimType,

                        c.ClaimValue
                    ));
            }




            var identity =

                new ClaimsIdentity(

                    identityClaims,

                    CookieAuthenticationDefaults.AuthenticationScheme
                );




            return new ClaimsPrincipal(identity);


        }


    }
}
