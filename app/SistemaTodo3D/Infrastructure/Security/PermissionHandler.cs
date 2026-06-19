using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;

namespace Infrastructure.Security
{
    public class PermissionHandler : AuthorizationHandler<PermissionRequirement>
    {
        protected override Task HandleRequirementAsync(
            AuthorizationHandlerContext context,
            PermissionRequirement requirement)
        {
            bool exists = context.User.HasClaim(
                "urn:action:permission",
                requirement.Permission
            );

            if (exists)
            {
                context.Succeed((Microsoft.AspNetCore.Authorization.IAuthorizationRequirement)requirement);
            }

            return Task.CompletedTask;
        }
    }
}
