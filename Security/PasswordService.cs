using System.Security.Cryptography;

namespace TheMorisakiBookshop.Security
{
    // Passwords are never stored. We store "iterations.salt.hash" (PBKDF2, built into .NET, no package).
    public class PasswordService
    {
        private const int SaltSize = 16;
        private const int HashSize = 32;
        private const int Iterations = 100000;

        public string Hash(string password)
        {
            byte[] salt = RandomNumberGenerator.GetBytes(SaltSize);
            byte[] hash = Rfc2898DeriveBytes.Pbkdf2(password, salt, Iterations, HashAlgorithmName.SHA256, HashSize);

            return Iterations + "." + Convert.ToBase64String(salt) + "." + Convert.ToBase64String(hash);
        }

        public bool Verify(string password, string storedHash)
        {
            string[] parts = storedHash.Split('.');

            if (parts.Length != 3)
            {
                return false;
            }

            int iterations = int.Parse(parts[0]);
            byte[] salt = Convert.FromBase64String(parts[1]);
            byte[] expectedHash = Convert.FromBase64String(parts[2]);

            byte[] actualHash = Rfc2898DeriveBytes.Pbkdf2(password, salt, iterations, HashAlgorithmName.SHA256, expectedHash.Length);

            // Fixed-time compare, so response time does not leak how many bytes matched.
            return CryptographicOperations.FixedTimeEquals(actualHash, expectedHash);
        }
    }
}
