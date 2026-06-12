using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Domain.Entities
{
    public class RoleClaim
    {
        public int RoleClaimId { get; set; }
        public int RoleId { get; set; }
        public int ClaimId { get; set; }

        // Navigation properties
        public virtual Role Role { get; set; } = null!;
        public virtual Claim Claim { get; set; } = null!;
    }
}
