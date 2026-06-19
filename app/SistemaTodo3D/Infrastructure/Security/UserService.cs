using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using BCrypt.Net;
namespace Infrastructure.Security
{
    public class UserService
    {
        public string HashPassword(string password)
        {
            // Genera hash con salt automático
            // workFactor: 10 es el valor recomendado (balance entre seguridad y rendimiento)
            string hash = BCrypt.Net.BCrypt.HashPassword(password, workFactor: 10); // Fully qualify the method call
            return hash;
        }

        public bool VerifyPassword(string password, string storedHash)
        {
            try
            {
                return BCrypt.Net.BCrypt.Verify(password, storedHash); // Fully qualify the method call
            }
            catch (SaltParseException ex)
            {
                // Esto solo debería ocurrir si el hash no tiene el formato correcto
                throw new InvalidOperationException("El hash almacenado no tiene el formato BCrypt válido", ex);
            }
        }
    }
}
