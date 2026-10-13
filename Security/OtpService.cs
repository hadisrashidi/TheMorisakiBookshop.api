using System.Security.Cryptography;
using System.Text;

namespace TheMorisakiBookshop.Security
{
    public class OtpService
    {
        public const int ExpiryMinutes = 2;

        public string GenerateCode()
        {
            int number = RandomNumberGenerator.GetInt32(0, 1000000);

            return number.ToString("D6");
        }

        // The database stores only this hash. The mobile is part of it, so the same code
        // for two numbers gives two different hashes.
        public string HashCode(string mobile, string code)
        {
            byte[] bytes = SHA256.HashData(Encoding.UTF8.GetBytes(mobile + ":" + code));

            return Convert.ToHexString(bytes);
        }
    }
}
