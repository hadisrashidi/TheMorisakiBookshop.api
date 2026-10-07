# Learned concepts (her cheat sheet)
- Generic `CustomActionResult<T>` = TypeScript `ApiResponse<T>`; `<T>` is filled in at the use site (`CustomActionResult<List<Books>>`).
- `IActionResult` + `Ok(x)` = controller returns "HTTP 200 with JSON body x"; like returning a value from an Angular service, but the framework turns it into the response.
- Object initializer `new X { A = 1 }` = TypeScript object literal `{ a: 1 }` typed as class X.
- `ConfigureApiBehaviorOptions` in `Program.cs` = a global setting for `[ApiController]` behaviour; here it makes validation errors (400) use our envelope — like an Angular `HttpInterceptor` shaping errors in one place.
- `app.UseExceptionHandler` = global error handler middleware, like Angular `ErrorHandler` — any unhandled exception ends up here and becomes the 500 envelope.
- `?` after a type (`string?`, `Books?`) = may be `null`, like `string | null` in TypeScript (`Nullable` is enabled in the csproj).
- Middleware order in `Program.cs` matters (exception handler → Swagger → HTTPS → CORS → authorization → controllers), like the order of Angular interceptors.
