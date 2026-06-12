using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Domain.Entities
{
    public class UserClaim
    {
        public int UserClaimId { get; set; }
        public int UserId { get; set; }
        public int ClaimId { get; set; }

        // Navigation properties
        public virtual User User { get; set; } = null!;
        public virtual Claim Claim { get; set; } = null!;
    }
}
