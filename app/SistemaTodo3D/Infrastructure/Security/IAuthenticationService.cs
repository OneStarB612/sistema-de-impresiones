using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Security.Claims;
namespace Infrastructure.Security
{

    public interface IAuthenticationService
    {
        Task<ClaimsPrincipal?> AuthenticateAsync(
            string username,
            string password);
    }
}
