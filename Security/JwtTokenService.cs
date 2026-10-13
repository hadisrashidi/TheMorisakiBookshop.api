using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.IdentityModel.Tokens;
using TheMorisakiBookshop.Models;

namespace TheMorisakiBookshop.Security
{
    public class JwtTokenService
    {
        private readonly IConfiguration _configuration;

        public JwtTokenService(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        public AuthTokenOutputModel CreateToken(UserModel user)
        {
            string key = _configuration["Jwt:Key"] ?? "";
            int expiresMinutes = int.Parse(_configuration["Jwt:ExpiresMinutes"] ?? "60");
            DateTime expiresAt = DateTime.UtcNow.AddMinutes(expiresMinutes);

            List<Claim> claims = new List<Claim>();
            claims.Add(new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()));
            claims.Add(new Claim(ClaimTypes.Role, user.Role));

            SymmetricSecurityKey securityKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(key));
            SigningCredentials credentials = new SigningCredentials(securityKey, SecurityAlgorithms.HmacSha256);

            JwtSecurityToken token = new JwtSecurityToken(
                issuer: _configuration["Jwt:Issuer"],
                audience: _configuration["Jwt:Audience"],
                claims: claims,
                expires: expiresAt,
                signingCredentials: credentials);

            AuthTokenOutputModel result = new AuthTokenOutputModel();
            result.Token = new JwtSecurityTokenHandler().WriteToken(token);
            result.ExpiresAt = expiresAt;
            result.User = ToOutputModel(user);

            return result;
        }

        public UserOutputModel ToOutputModel(UserModel user)
        {
            UserOutputModel output = new UserOutputModel();
            output.Id = user.Id;
            output.Mobile = user.Mobile;
            output.Email = user.Email;
            output.HasPassword = user.PasswordHash != null;
            output.Role = user.Role;

            return output;
        }
    }
}
