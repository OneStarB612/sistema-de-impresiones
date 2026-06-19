using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Domain.Entities
{
    public class AppClaim
    {

        public int ClaimID { get; set; }
        public string ClaimType { get; set; }
        public string ClaimValue { get; set; }

    }
}
