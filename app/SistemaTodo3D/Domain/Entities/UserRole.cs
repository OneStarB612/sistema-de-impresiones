using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Domain.Entities
{
    public class UserRole
    {
        public int UserId { get; set; }
        public int RoleId { get; set; }

        // Navigation properties
        public virtual User User { get; set; } = null!;
        public virtual Role Role { get; set; } = null!;
    }

    public class Claim
    {
        public int ClaimId { get; set; }
        public string ClaimType { get; set; } = string.Empty;
        public string ClaimValue { get; set; } = string.Empty;

        // Navigation properties
        public virtual ICollection<RoleClaim> RoleClaims { get; set; } = new List<RoleClaim>();
        public virtual ICollection<UserClaim> UserClaims { get; set; } = new List<UserClaim>();
    }

}
