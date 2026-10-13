using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TheMorisakiBookshop.Models;
using TheMorisakiBookshop.Models.Dto;
using TheMorisakiBookshop.Repositories;
using TheMorisakiBookshop.Security;

namespace TheMorisakiBookshop.Controllers.Shop
{
    public class AuthController : BaseController
    {
        private readonly UsersRepository _usersRepository;
        private readonly OtpCodesRepository _otpCodesRepository;
        private readonly OtpService _otpService;
        private readonly SmsSender _smsSender;
        private readonly PasswordService _passwordService;
        private readonly JwtTokenService _jwtTokenService;
        private readonly bool _showCodeInResponse;

        public AuthController(
            UsersRepository usersRepository,
            OtpCodesRepository otpCodesRepository,
            OtpService otpService,
            SmsSender smsSender,
            PasswordService passwordService,
            JwtTokenService jwtTokenService,
            IConfiguration configuration)
        {
            _usersRepository = usersRepository;
            _otpCodesRepository = otpCodesRepository;
            _otpService = otpService;
            _smsSender = smsSender;
            _passwordService = passwordService;
            _jwtTokenService = jwtTokenService;
            _showCodeInResponse = configuration.GetValue<bool>("Sms:ShowCodeInResponse");
        }

        // Step 1 of OTP login (also used to start a password reset): sends a 6-digit code by SMS.
        [HttpPost]
        public async Task<IActionResult> RequestOtp([FromBody] RequestOtpRequestModel request, CancellationToken cancellationToken)
        {
            string code = _otpService.GenerateCode();
            string codeHash = _otpService.HashCode(request.Mobile, code);

            string status = await _otpCodesRepository.CreateAsync(request.Mobile, codeHash, OtpService.ExpiryMinutes, cancellationToken);

            if (status == "TooSoon")
            {
                return Ok(new CustomActionResult { IsSuccess = false, Message = "Please wait one minute before asking for a new code." });
            }

            if (status == "TooMany")
            {
                return Ok(new CustomActionResult { IsSuccess = false, Message = "Too many codes requested. Try again in an hour." });
            }

            await _smsSender.SendAsync(request.Mobile, "Your Morisaki Bookshop code: " + code, cancellationToken);

            // Local testing only (Program.cs refuses to start with this on outside Development).
            if (_showCodeInResponse)
            {
                return Ok(new CustomActionResult { IsSuccess = true, Message = "DEV ONLY - your code is " + code });
            }

            return Ok(new CustomActionResult { IsSuccess = true });
        }

        // Step 2 of OTP login: right code = token. A new mobile number creates the account.
        [HttpPost]
        public async Task<IActionResult> VerifyOtp([FromBody] VerifyOtpRequestModel request, CancellationToken cancellationToken)
        {
            string codeHash = _otpService.HashCode(request.Mobile, request.Code);

            string status = await _otpCodesRepository.VerifyAsync(request.Mobile, codeHash, cancellationToken);

            if (status != "Ok")
            {
                return Ok(new CustomActionResult<AuthTokenOutputModel> { IsSuccess = false, Message = GetOtpFailureMessage(status) });
            }

            UserModel user = await _usersRepository.GetOrCreateByMobileAsync(request.Mobile, cancellationToken);
            AuthTokenOutputModel token = _jwtTokenService.CreateToken(user);

            return Ok(new CustomActionResult<AuthTokenOutputModel> { IsSuccess = true, Data = token });
        }

        [HttpPost]
        public async Task<IActionResult> LoginWithPassword([FromBody] PasswordLoginRequestModel request, CancellationToken cancellationToken)
        {
            UserModel? user = await _usersRepository.GetByEmailAsync(request.Email, cancellationToken);

            // Same message for "no such email" and "wrong password", so nobody can probe which emails exist.
            bool passwordIsRight = user != null
                && user.PasswordHash != null
                && _passwordService.Verify(request.Password, user.PasswordHash);

            if (user == null || passwordIsRight == false)
            {
                return Ok(new CustomActionResult<AuthTokenOutputModel> { IsSuccess = false, Message = "Email or password is wrong." });
            }

            AuthTokenOutputModel token = _jwtTokenService.CreateToken(user);

            return Ok(new CustomActionResult<AuthTokenOutputModel> { IsSuccess = true, Data = token });
        }

        // Logged-in user adds (or changes) email + password for the second login method.
        [Authorize]
        [HttpPost]
        public async Task<IActionResult> SetCredentials([FromBody] SetCredentialsRequestModel request, CancellationToken cancellationToken)
        {
            int userId = GetCurrentUserId();
            string passwordHash = _passwordService.Hash(request.Password);

            string status = await _usersRepository.SetCredentialsAsync(userId, request.Email, passwordHash, cancellationToken);

            if (status == "EmailTaken")
            {
                return Ok(new CustomActionResult { IsSuccess = false, Message = "This email is already used by another account." });
            }

            return Ok(new CustomActionResult { IsSuccess = true });
        }

        // Forgot password: needs a fresh SMS code of the account's mobile (RequestOtp first).
        [HttpPost]
        public async Task<IActionResult> ResetPassword([FromBody] ResetPasswordRequestModel request, CancellationToken cancellationToken)
        {
            string codeHash = _otpService.HashCode(request.Mobile, request.Code);

            string status = await _otpCodesRepository.VerifyAsync(request.Mobile, codeHash, cancellationToken);

            if (status != "Ok")
            {
                return Ok(new CustomActionResult { IsSuccess = false, Message = GetOtpFailureMessage(status) });
            }

            string passwordHash = _passwordService.Hash(request.NewPassword);
            bool changed = await _usersRepository.ResetPasswordAsync(request.Mobile, passwordHash, cancellationToken);

            if (changed == false)
            {
                return Ok(new CustomActionResult { IsSuccess = false, Message = "This account has no email and password yet." });
            }

            return Ok(new CustomActionResult { IsSuccess = true });
        }

        [Authorize]
        [HttpGet]
        public async Task<IActionResult> GetMe(CancellationToken cancellationToken)
        {
            int userId = GetCurrentUserId();

            UserModel? user = await _usersRepository.GetByIdAsync(userId, cancellationToken);

            if (user == null)
            {
                return Ok(new CustomActionResult<UserOutputModel> { IsSuccess = false, Message = "User not found." });
            }

            return Ok(new CustomActionResult<UserOutputModel>
            {
                IsSuccess = true,
                Data = _jwtTokenService.ToOutputModel(user)
            });
        }

        private int GetCurrentUserId()
        {
            string idText = User.FindFirstValue(ClaimTypes.NameIdentifier) ?? "0";

            return int.Parse(idText);
        }

        private string GetOtpFailureMessage(string status)
        {
            if (status == "Locked")
            {
                return "Too many wrong codes. Ask for a new code.";
            }

            if (status == "Invalid")
            {
                return "The code is wrong.";
            }

            return "The code has expired. Ask for a new code.";
        }
    }
}
